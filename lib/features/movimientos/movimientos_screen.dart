import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../services/movimiento_service.dart';
import 'models/movimiento_models.dart';
import 'registrar_movimiento_screen.dart';

/// Pantalla de Historial de Movimientos de Inventario (CU11).
///
/// Permite al personal de almacén y tienda auditar las entradas, salidas
/// y traspasos con filtros por tipo de movimiento.
class MovimientosScreen extends StatefulWidget {
  final MovimientoService? servicio;

  const MovimientosScreen({super.key, this.servicio});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  late final MovimientoService _servicio;

  List<MovimientoInventario> _movimientos = [];
  bool _cargando = true;
  String? _error;
  String _filtroTipo = 'Todos';

  final List<String> _tiposFiltro = ['Todos', 'Entrada', 'Salida', 'Traspaso'];

  @override
  void initState() {
    super.initState();
    _servicio = widget.servicio ?? MovimientoService();
    _consultar();
  }

  Future<void> _consultar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final lista = await _servicio.listar(
        tipo: _filtroTipo == 'Todos' ? null : _filtroTipo,
      );
      if (!mounted) return;
      setState(() {
        _movimientos = lista;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Error de conexión al cargar movimientos.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _cambiarFiltro(String tipo) {
    if (_filtroTipo == tipo) return;
    setState(() => _filtroTipo = tipo);
    _consultar();
  }

  Future<void> _abrirFormularioRegistro() async {
    final registrado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RegistrarMovimientoScreen(servicio: _servicio),
      ),
    );
    if (registrado == true && mounted) {
      _consultar();
    }
  }

  Color _colorTipo(String tipo) {
    switch (tipo) {
      case 'Entrada':
        return fsEmerald;
      case 'Salida':
        return fsDanger;
      case 'Traspaso':
        return fsGoldDeep;
      default:
        return fsInkSoft;
    }
  }

  Color _fondoTipo(String tipo) {
    switch (tipo) {
      case 'Entrada':
        return const Color(0xFFE9F1EC);
      case 'Salida':
        return fsDangerWash;
      case 'Traspaso':
        return fsGoldWash;
      default:
        return fsSurfaceAlt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos de Inventario'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormularioRegistro,
        backgroundColor: fsInk,
        foregroundColor: fsSurface,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Movimiento'),
      ),
      body: Column(
        children: [
          // Barra de filtros por tipo
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: _tiposFiltro.map((tipo) {
                final activo = _filtroTipo == tipo;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(tipo),
                    selected: activo,
                    selectedColor: fsGoldWash,
                    checkmarkColor: fsGoldDeep,
                    labelStyle: TextStyle(
                      color: activo ? fsGoldDeep : fsInkSoft,
                      fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: activo ? fsGold : fsBorder,
                    ),
                    onSelected: (_) => _cambiarFiltro(tipo),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
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
                      child: Text(
                        _error!,
                        style: const TextStyle(color: fsDanger, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: _consultar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _consultar,
              color: fsGold,
              child: _contenido(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenido() {
    if (_cargando && _movimientos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_movimientos.isEmpty && _error == null) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined, size: 48, color: fsInkMuted),
                SizedBox(height: 12),
                Text(
                  'No se registraron movimientos con el filtro seleccionado.',
                  style: TextStyle(color: fsInkMuted, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _movimientos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final m = _movimientos[i];
        final signo = m.tipo == 'Entrada' ? '+' : '-';
        final color = _colorTipo(m.tipo);
        final fondo = _fondoTipo(m.tipo);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: fsBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: fondo,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: color.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        m.tipo.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: color,
                        ),
                      ),
                    ),
                    Text(
                      '$signo${m.cantidad} uds.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  m.prendaNombre ?? 'Prenda #${m.idVariantePrenda}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: fsInk,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (m.skuVariante != null) ...[
                      Text(
                        'SKU: ${m.skuVariante}',
                        style: const TextStyle(fontSize: 12, color: fsInkMuted),
                      ),
                      const SizedBox(width: 8),
                      const Text('•',
                          style: TextStyle(fontSize: 12, color: fsInkMuted)),
                      const SizedBox(width: 8),
                    ],
                    if (m.talla != null && m.talla!.isNotEmpty) ...[
                      Text(
                        'Talla: ${m.talla}',
                        style: const TextStyle(fontSize: 12, color: fsInkSoft),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (m.color != null && m.color!.isNotEmpty) ...[
                      Text(
                        'Color: ${m.color}',
                        style: const TextStyle(fontSize: 12, color: fsInkSoft),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: fsBorder, height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.storefront_outlined,
                        size: 14, color: fsInkMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        m.sucursalNombre ?? 'Sucursal #${m.idSucursal}',
                        style: const TextStyle(fontSize: 12, color: fsInkSoft),
                      ),
                    ),
                    const Icon(Icons.access_time, size: 14, color: fsInkMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${m.fecha.day.toString().padLeft(2, '0')}/${m.fecha.month.toString().padLeft(2, '0')}/${m.fecha.year} ${m.fecha.hour.toString().padLeft(2, '0')}:${m.fecha.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 11, color: fsInkMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.comment_outlined,
                        size: 14, color: fsInkMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Motivo: ${m.motivo}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: fsInkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
                if (m.usuarioNombre != null &&
                    m.usuarioNombre!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 14, color: fsInkMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Registrado por: ${m.usuarioNombre}',
                        style: const TextStyle(fontSize: 11, color: fsInkMuted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
