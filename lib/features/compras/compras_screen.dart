import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../services/compra_service.dart';
import 'compra_detalle_screen.dart';
import 'models/compra_models.dart';

/// Pantalla de Recepción de Compras e Historial de Lotes (CU13).
///
/// Permite al personal de almacén consultar los comprobantes de compra
/// registrados, sucursales receptoras y montos consolidados con 13% IVA.
class ComprasScreen extends StatefulWidget {
  final CompraService? servicio;

  const ComprasScreen({super.key, this.servicio});

  @override
  State<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> {
  late final CompraService _servicio;

  List<Compra> _compras = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _servicio = widget.servicio ?? CompraService();
    _consultar();
  }

  Future<void> _consultar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final lista = await _servicio.listar();
      if (!mounted) return;
      setState(() {
        _compras = lista;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Error de conexión al cargar historial de compras.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _abrirDetalle(int idCompra) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompraDetalleScreen(
          idCompra: idCompra,
          servicio: _servicio,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recepción de Compras / Lotes'),
      ),
      body: Column(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
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
    if (_cargando && _compras.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_compras.isEmpty && _error == null) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 48, color: fsInkMuted),
                SizedBox(height: 12),
                Text(
                  'No hay compras o lotes registrados en el sistema.',
                  style: TextStyle(color: fsInkMuted, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _compras.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final c = _compras[i];
        final fechaStr =
            '${c.fecha.day.toString().padLeft(2, '0')}/${c.fecha.month.toString().padLeft(2, '0')}/${c.fecha.year}';

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: fsBorder),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _abrirDetalle(c.idCompra),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                          color: fsGoldWash,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: fsGold),
                        ),
                        child: Text(
                          'COMPRA #${c.idCompra}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: fsGoldDeep,
                          ),
                        ),
                      ),
                      Text(
                        fechaStr,
                        style: const TextStyle(fontSize: 12, color: fsInkMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    c.proveedorRazonSocial ?? 'Proveedor #${c.idProveedor}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: fsInk,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.storefront_outlined,
                          size: 14, color: fsInkMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          c.sucursalNombre ?? 'Sucursal #${c.idSucursal}',
                          style:
                              const TextStyle(fontSize: 13, color: fsInkSoft),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: fsBorder, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        c.totalItems > 0
                            ? '${c.totalItems} producto(s)'
                            : 'Lote ingresado',
                        style: const TextStyle(fontSize: 12, color: fsInkMuted),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Bs ${c.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: fsInk,
                            ),
                          ),
                          const Text(
                            'IVA 13% incluido',
                            style: TextStyle(
                              fontSize: 10,
                              color: fsEmerald,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
