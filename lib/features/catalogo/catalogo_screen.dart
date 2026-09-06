import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/models/catalogo_models.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/auth_service.dart';
import '../../services/catalogo_service.dart';
import '../detalle/prenda_detalle_screen.dart';

/// Vitrina pública del catálogo (CU14).
///
/// Muestra la cuadrícula de prendas activas con búsqueda reactiva (antirrebote)
/// y un panel de filtros por categoría, género, talla, color y rango de precio.
/// Al pulsar una tarjeta se abre la ficha con la disponibilidad por sucursal.
class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  final CatalogoService _servicio = CatalogoService();
  final AuthService _auth = AuthService();
  final _busquedaCtrl = TextEditingController();

  static const int _limite = 20;

  FiltrosDisponibles? _filtros;
  List<PrendaCatalogo> _prendas = [];
  int _total = 0;
  int _desplazamiento = 0;

  bool _cargando = true;
  String? _error;

  // Filtros activos
  int? _idCategoria;
  String? _genero;
  int? _idTalla;
  int? _idColor;
  double? _precioMin;
  double? _precioMax;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _cargarFiltros();
    _consultar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarFiltros() async {
    try {
      final filtros = await _servicio.obtenerFiltros();
      if (!mounted) return;
      setState(() => _filtros = filtros);
    } catch (_) {
      // Los filtros son auxiliares: si fallan, la vitrina sigue funcionando.
    }
  }

  Future<void> _consultar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final busqueda = _busquedaCtrl.text.trim();
      final respuesta = await _servicio.consultar(
        busqueda: busqueda.isEmpty ? null : busqueda,
        idCategoria: _idCategoria,
        genero: _genero,
        idTalla: _idTalla,
        idColor: _idColor,
        precioMin: _precioMin,
        precioMax: _precioMax,
        limite: _limite,
        desplazamiento: _desplazamiento,
      );
      if (!mounted) return;
      setState(() {
        _prendas = _desplazamiento == 0
            ? respuesta.prendas
            : [..._prendas, ...respuesta.prendas];
        _total = respuesta.total;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo contactar con el servidor.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _alBuscar(String valor) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _desplazamiento = 0;
      _consultar();
    });
  }

  void _cargarMas() {
    _desplazamiento += _limite;
    _consultar();
  }

  void _reintentar() {
    _desplazamiento = 0;
    _consultar();
  }

  void _cerrarSesion() {
    _auth.logout();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión cerrada.')),
    );
  }

  void _abrirDetalle(int idPrenda) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PrendaDetalleScreen(idPrenda: idPrenda)),
    );
  }

  Future<void> _abrirFiltros() async {
    final f = _filtros;
    if (f == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Filtros no disponibles en este momento.')),
      );
      return;
    }

    int? tmpCategoria = _idCategoria;
    String? tmpGenero = _genero;
    int? tmpTalla = _idTalla;
    int? tmpColor = _idColor;
    final minCtrl = TextEditingController(text: _precioMin?.toString() ?? '');
    final maxCtrl = TextEditingController(text: _precioMax?.toString() ?? '');

    final aplicar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Filtros', style: Theme.of(ctx).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int?>(
                      value: tmpCategoria,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
                        ...f.categorias.map(
                          (c) => DropdownMenuItem<int?>(
                            value: c.idCategoria,
                            child: Text(c.nombre),
                          ),
                        ),
                      ],
                      onChanged: (v) => setModal(() => tmpCategoria = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: tmpGenero,
                      decoration: const InputDecoration(labelText: 'Género'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                        ...f.generos.map(
                          (g) => DropdownMenuItem<String?>(value: g, child: Text(g)),
                        ),
                      ],
                      onChanged: (v) => setModal(() => tmpGenero = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      value: tmpTalla,
                      decoration: const InputDecoration(labelText: 'Talla'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
                        ...f.tallas.map(
                          (t) => DropdownMenuItem<int?>(
                            value: t.idTalla,
                            child: Text(t.nombre),
                          ),
                        ),
                      ],
                      onChanged: (v) => setModal(() => tmpTalla = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      value: tmpColor,
                      decoration: const InputDecoration(labelText: 'Color'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                        ...f.colores.map(
                          (c) => DropdownMenuItem<int?>(
                            value: c.idColor,
                            child: Text(c.nombre),
                          ),
                        ),
                      ],
                      onChanged: (v) => setModal(() => tmpColor = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Precio mín (Bs)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: maxCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Precio máx (Bs)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setModal(() {
                              tmpCategoria = null;
                              tmpGenero = null;
                              tmpTalla = null;
                              tmpColor = null;
                              minCtrl.clear();
                              maxCtrl.clear();
                            }),
                            child: const Text('Limpiar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Aplicar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (aplicar == true) {
      setState(() {
        _idCategoria = tmpCategoria;
        _genero = tmpGenero;
        _idTalla = tmpTalla;
        _idColor = tmpColor;
        _precioMin = double.tryParse(minCtrl.text.trim());
        _precioMax = double.tryParse(maxCtrl.text.trim());
        _desplazamiento = 0;
      });
      _consultar();
    }

    minCtrl.dispose();
    maxCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FashionStore'),
        actions: [
          if (_auth.autenticado)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: _cerrarSesion,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _busquedaCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Buscar prenda, SKU o marca…',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _alBuscar,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _abrirFiltros,
                  icon: const Icon(Icons.tune),
                  label: const Text('Filtros'),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _bannerError(_error!),
            ),
          Expanded(child: _contenido()),
        ],
      ),
    );
  }

  Widget _contenido() {
    if (_cargando && _prendas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_prendas.isEmpty && _error == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No hay prendas que coincidan con los filtros elegidos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: fsInkMuted),
          ),
        ),
      );
    }

    final hayMas = _desplazamiento + _limite < _total;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '$_total prenda(s) disponibles',
          style: const TextStyle(fontSize: 12, letterSpacing: 1.2, color: fsInkMuted),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.6,
          children: _prendas.map(_tarjeta).toList(),
        ),
        const SizedBox(height: 8),
        if (_cargando)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (hayMas)
          OutlinedButton(
            onPressed: _cargarMas,
            child: const Text('Cargar más'),
          ),
      ],
    );
  }

  Widget _tarjeta(PrendaCatalogo p) {
    return GestureDetector(
      onTap: () => _abrirDetalle(p.idPrenda),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: fsBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(aspectRatio: 3 / 4, child: redImagen(p.urlImagen)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.categoria ?? 'Sin categoría',
                      style: const TextStyle(fontSize: 10, letterSpacing: 1.2, color: fsInkMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatearPrecio(p.precioBase),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        badgeStock(p.stockTotal),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bannerError(String mensaje) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fsDangerWash,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFEBD8D8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: fsDanger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(mensaje, style: const TextStyle(color: fsDanger, fontSize: 13)),
          ),
          TextButton(onPressed: _reintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
