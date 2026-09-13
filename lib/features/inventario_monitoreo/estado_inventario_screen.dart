import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../services/inventario_monitoreo_service.dart';
import 'models/inventario_monitoreo_models.dart';

/// Pantalla de Monitoreo de Inventario y Existencias Multisucursal (CU10).
///
/// Ofrece búsqueda instantánea por SKU o modelo con debouncing de 350ms,
/// tarjetas resumen de KPIs, filtros rápidos por sucursal física y estado de stock,
/// tarjetas de variantes con badge cromático de 3 estados (Óptimo, Bajo, Agotado)
/// y desglose expandible o modal por sucursal física.
class EstadoInventarioScreen extends StatefulWidget {
  final InventarioMonitoreoService? servicio;

  const EstadoInventarioScreen({super.key, this.servicio});

  @override
  State<EstadoInventarioScreen> createState() => _EstadoInventarioScreenState();
}

class _EstadoInventarioScreenState extends State<EstadoInventarioScreen> {
  late final InventarioMonitoreoService _servicio;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  bool _cargando = true;
  String? _error;

  ResumenInventario? _resumen;
  List<VarianteAgrupadaInventario> _variantesAgrupadas = [];
  List<ResumenSucursalInventario> _sucursales = [];

  // Filtros activos
  int? _idSucursalSeleccionada;
  String? _estadoStockSeleccionado; // null o 'Todos', 'Optimo', 'Bajo', 'Agotado'
  int? _idCategoriaSeleccionada;
  int? _idTemporadaSeleccionada;

  // Listados para filtros avanzados
  List<Map<String, dynamic>> _categoriasDisponibles = [];
  List<Map<String, dynamic>> _temporadasDisponibles = [];

  @override
  void initState() {
    super.initState();
    _servicio = widget.servicio ?? InventarioMonitoreoService();
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final sucursalesFuture = _servicio.obtenerSucursales();
      final categoriasFuture = _servicio.obtenerCategorias();
      final temporadasFuture = _servicio.obtenerTemporadas();

      final resultados = await Future.wait([
        sucursalesFuture,
        categoriasFuture,
        temporadasFuture,
      ]);

      _sucursales = resultados[0] as List<ResumenSucursalInventario>;
      _categoriasDisponibles = resultados[1] as List<Map<String, dynamic>>;
      _temporadasDisponibles = resultados[2] as List<Map<String, dynamic>>;

      await _cargarDatos(actualizarCargando: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e is ApiException ? e.message : 'Error al conectar con el servidor.';
      });
    }
  }

  Future<void> _cargarDatos({bool actualizarCargando = true}) async {
    if (actualizarCargando) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final textoBusqueda = _searchController.text.trim();

      final resumenFuture = _servicio.obtenerResumen(
        idSucursal: _idSucursalSeleccionada,
        idCategoria: _idCategoriaSeleccionada,
        idTemporada: _idTemporadaSeleccionada,
        busqueda: textoBusqueda.isNotEmpty ? textoBusqueda : null,
      );

      final monitoreoFuture = _servicio.obtenerMonitoreo(
        idSucursal: _idSucursalSeleccionada,
        idCategoria: _idCategoriaSeleccionada,
        idTemporada: _idTemporadaSeleccionada,
        busqueda: textoBusqueda.isNotEmpty ? textoBusqueda : null,
        estadoStock: _estadoStockSeleccionado != 'Todos' ? _estadoStockSeleccionado : null,
      );

      final resultados = await Future.wait([resumenFuture, monitoreoFuture]);
      final resumen = resultados[0] as ResumenInventario;
      final items = resultados[1] as List<MonitoreoItem>;

      // Si las sucursales estaban vacías, poblar desde el resumen
      if (_sucursales.isEmpty && resumen.sucursales.isNotEmpty) {
        _sucursales = resumen.sucursales;
      }

      if (!mounted) return;
      setState(() {
        _resumen = resumen;
        _variantesAgrupadas = VarianteAgrupadaInventario.agrupar(items);
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e is ApiException ? e.message : 'Error al cargar existencias de inventario.';
      });
    }
  }

  void _onSearchChanged(String valor) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _cargarDatos();
    });
  }

  void _limpiarFiltros() {
    setState(() {
      _searchController.clear();
      _idSucursalSeleccionada = null;
      _estadoStockSeleccionado = null;
      _idCategoriaSeleccionada = null;
      _idTemporadaSeleccionada = null;
    });
    _cargarDatos();
  }

  void _mostrarFiltrosAvanzados() {
    int? tempCategoria = _idCategoriaSeleccionada;
    int? tempTemporada = _idTemporadaSeleccionada;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: fsSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtros Avanzados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: fsInk,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: fsInkMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    initialValue: tempCategoria,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Todas las categorías')),
                      ..._categoriasDisponibles.map((c) {
                        final id = c['id_categoria'] is num
                            ? (c['id_categoria'] as num).toInt()
                            : int.tryParse(c['id_categoria']?.toString() ?? '0');
                        final nombre = (c['nombre'] ?? c['nombre_categoria'] ?? 'Sin nombre').toString();
                        return DropdownMenuItem<int?>(value: id, child: Text(nombre));
                      }),
                    ],
                    onChanged: (v) => setModalState(() => tempCategoria = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    initialValue: tempTemporada,
                    decoration: const InputDecoration(labelText: 'Temporada / Colección'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Todas las temporadas')),
                      ..._temporadasDisponibles.map((t) {
                        final id = t['id_temporada'] is num
                            ? (t['id_temporada'] as num).toInt()
                            : int.tryParse(t['id_temporada']?.toString() ?? '0');
                        final nombre = (t['nombre'] ?? t['nombre_temporada'] ?? 'Sin nombre').toString();
                        return DropdownMenuItem<int?>(value: id, child: Text(nombre));
                      }),
                    ],
                    onChanged: (v) => setModalState(() => tempTemporada = v),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              tempCategoria = null;
                              tempTemporada = null;
                            });
                          },
                          child: const Text('Restablecer'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _idCategoriaSeleccionada = tempCategoria;
                              _idTemporadaSeleccionada = tempTemporada;
                            });
                            _cargarDatos();
                          },
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarDesgloseModal(BuildContext context, VarianteAgrupadaInventario variante) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: fsSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          variante.nombrePrenda,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: fsInk,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SKU: ${variante.skuVariante}',
                          style: const TextStyle(
                            fontSize: 12,
                            letterSpacing: 1.1,
                            color: fsInkMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: fsInkMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  badgeEstadoInventario(variante.stockTotal, estado: variante.estadoStock),
                  const SizedBox(width: 10),
                  Text(
                    'Total disponible: ${variante.stockTotal} unidades',
                    style: const TextStyle(fontSize: 13, color: fsInkSoft),
                  ),
                ],
              ),
              const Divider(height: 28, color: fsBorder),
              const Text(
                'DISPONIBILIDAD POR SUCURSAL FÍSICA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: fsInkMuted,
                ),
              ),
              const SizedBox(height: 12),
              if (variante.desgloseSucursales.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Sin datos de sucursales registrados.'),
                )
              else
                ...variante.desgloseSucursales.map((d) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: fsSurfaceAlt,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: fsBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_outlined, size: 20, color: fsInk),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.nombreSucursal,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: fsInk,
                                ),
                              ),
                              if (d.ciudad.isNotEmpty)
                                Text(
                                  d.ciudad,
                                  style: const TextStyle(fontSize: 11, color: fsInkMuted),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${d.stock} u.',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: fsInk,
                          ),
                        ),
                        const SizedBox(width: 8),
                        badgeEstadoInventario(d.stock, estado: d.estadoStock, mostrarUnidades: false),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Estado de Inventario',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Filtros avanzados',
            icon: Icon(
              Icons.tune,
              color: (_idCategoriaSeleccionada != null || _idTemporadaSeleccionada != null)
                  ? fsGoldDeep
                  : fsInk,
            ),
            onPressed: _mostrarFiltrosAvanzados,
          ),
          IconButton(
            tooltip: 'Actualizar existencias',
            icon: const Icon(Icons.refresh),
            onPressed: () => _cargarDatos(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        color: fsGold,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _construirBuscador(),
                    const SizedBox(height: 12),
                    _construirKpisHeader(),
                    const SizedBox(height: 12),
                    _construirChipsSucursales(),
                    const SizedBox(height: 8),
                    _construirChipsEstadoStock(),
                  ],
                ),
              ),
            ),
            if (_cargando)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: fsGold),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _construirVistaError(_error!),
              )
            else if (_variantesAgrupadas.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _construirVistaVacia(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final variante = _variantesAgrupadas[index];
                      return _construirTarjetaVariante(variante);
                    },
                    childCount: _variantesAgrupadas.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _construirBuscador() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Buscar por SKU, modelo o prenda...',
        prefixIcon: const Icon(Icons.search, color: fsInkMuted),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: fsInkMuted),
                onPressed: () {
                  _searchController.clear();
                  _cargarDatos();
                },
              )
            : null,
      ),
    );
  }

  Widget _construirKpisHeader() {
    final totalStock = _resumen?.totalStock ??
        _variantesAgrupadas.fold<int>(0, (sum, v) => sum + v.stockTotal);
    final bajoStock = _resumen?.totalBajo ??
        _variantesAgrupadas.where((v) => v.estadoStock == 'Bajo').length;
    final agotadas = _resumen?.totalAgotado ??
        _variantesAgrupadas.where((v) => v.estadoStock == 'Agotado').length;

    return Row(
      children: [
        Expanded(
          child: _tarjetaKpi(
            titulo: 'Total Existencias',
            valor: '$totalStock',
            icono: Icons.inventory_2_outlined,
            colorTexto: fsInk,
            colorFondo: fsSurface,
            colorBorde: fsBorder,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _tarjetaKpi(
            titulo: 'Bajo Stock',
            valor: '$bajoStock',
            icono: Icons.warning_amber_rounded,
            colorTexto: const Color(0xFFB45309),
            colorFondo: const Color(0xFFFEF3C7),
            colorBorde: const Color(0xFFFDE68A),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _tarjetaKpi(
            titulo: 'Agotadas',
            valor: '$agotadas',
            icono: Icons.remove_circle_outline,
            colorTexto: fsDanger,
            colorFondo: fsDangerWash,
            colorBorde: const Color(0xFFEBD8D8),
          ),
        ),
      ],
    );
  }

  Widget _tarjetaKpi({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color colorTexto,
    required Color colorFondo,
    required Color colorBorde,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorBorde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icono, size: 16, color: colorTexto),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorTexto,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: fsInkMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirChipsSucursales() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('Todas las sucursales'),
            selected: _idSucursalSeleccionada == null,
            selectedColor: fsGoldWash,
            checkmarkColor: fsGoldDeep,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: _idSucursalSeleccionada == null ? FontWeight.w700 : FontWeight.w500,
              color: _idSucursalSeleccionada == null ? fsInk : fsInkSoft,
            ),
            onSelected: (sel) {
              if (_idSucursalSeleccionada != null) {
                setState(() => _idSucursalSeleccionada = null);
                _cargarDatos();
              }
            },
          ),
          const SizedBox(width: 8),
          ..._sucursales.map((suc) {
            final seleccionada = _idSucursalSeleccionada == suc.idSucursal;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(suc.sucursal),
                selected: seleccionada,
                selectedColor: fsGoldWash,
                checkmarkColor: fsGoldDeep,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: seleccionada ? FontWeight.w700 : FontWeight.w500,
                  color: seleccionada ? fsInk : fsInkSoft,
                ),
                onSelected: (sel) {
                  setState(() {
                    _idSucursalSeleccionada = sel ? suc.idSucursal : null;
                  });
                  _cargarDatos();
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _construirChipsEstadoStock() {
    final estados = [
      {'clave': 'Todos', 'label': 'Todos'},
      {'clave': 'Optimo', 'label': 'Óptimo (≥5)'},
      {'clave': 'Bajo', 'label': 'Bajo (1-4)'},
      {'clave': 'Agotado', 'label': 'Agotado (0)'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: estados.map((e) {
          final clave = e['clave']!;
          final label = e['label']!;
          final seleccionada = (_estadoStockSeleccionado == null && clave == 'Todos') ||
              _estadoStockSeleccionado == clave;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: seleccionada,
              selectedColor: fsGoldWash,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: seleccionada ? FontWeight.w700 : FontWeight.w500,
                color: seleccionada ? fsInk : fsInkSoft,
              ),
              onSelected: (sel) {
                if (sel) {
                  setState(() {
                    _estadoStockSeleccionado = clave == 'Todos' ? null : clave;
                  });
                  _cargarDatos();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _construirTarjetaVariante(VarianteAgrupadaInventario variante) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fsBorder),
      ),
      child: Material(
        color: fsSurface,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
          key: PageStorageKey('variante_${variante.idVariantePrenda}'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variante.nombrePrenda,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: fsInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SKU: ${variante.skuVariante}',
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: fsInkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              badgeEstadoInventario(variante.stockTotal, estado: variante.estadoStock),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (variante.categoria != null && variante.categoria!.isNotEmpty)
                  _chipMetadato(variante.categoria!, Icons.label_outline),
                if (variante.temporada != null && variante.temporada!.isNotEmpty)
                  _chipMetadato(variante.temporada!, Icons.wb_sunny_outlined),
                if (variante.talla != null && variante.talla!.isNotEmpty)
                  _chipMetadato('Talla: ${variante.talla}', Icons.straighten_outlined),
                if (variante.color != null && variante.color!.isNotEmpty)
                  _chipMetadato('Color: ${variante.color}', Icons.palette_outlined),
              ],
            ),
          ),
          children: [
            const Divider(height: 16, color: fsBorder),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Desglose por Sucursal Física',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: fsInkMuted,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Ver detalle', style: TextStyle(fontSize: 11)),
                  onPressed: () => _mostrarDesgloseModal(context, variante),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...variante.desgloseSucursales.map((d) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: fsSurfaceAlt,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: fsBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront_outlined, size: 16, color: fsInkSoft),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        d.ciudad.isNotEmpty
                            ? '${d.nombreSucursal} (${d.ciudad})'
                            : d.nombreSucursal,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${d.stock} u.',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: fsInk,
                      ),
                    ),
                    const SizedBox(width: 8),
                    badgeEstadoInventario(d.stock, estado: d.estadoStock, mostrarUnidades: false),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ),
  );
}

  Widget _chipMetadato(String texto, IconData icono) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: fsSurfaceAlt,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: fsBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 11, color: fsInkMuted),
          const SizedBox(width: 4),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: fsInkSoft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirVistaVacia() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: fsInkMuted),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron existencias',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: fsInk,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No hay registros que coincidan con los filtros o el término de búsqueda ingresado.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: fsInkSoft),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _limpiarFiltros,
              child: const Text('Limpiar todos los filtros'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirVistaError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: fsDanger),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar monitoreo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: fsDanger,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: fsInkSoft),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              onPressed: () => _cargarDatos(),
            ),
          ],
        ),
      ),
    );
  }
}
