import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../services/compra_service.dart';
import 'models/compra_models.dart';

/// Ficha de detalle para una Compra / Recepción de Lote (CU13).
///
/// Desglosa los ítems recibidos por variante de prenda, cantidad, costo unitario
/// y el cálculo impositivo del 13% de IVA boliviano.
class CompraDetalleScreen extends StatefulWidget {
  final int idCompra;
  final CompraService? servicio;

  const CompraDetalleScreen({
    super.key,
    required this.idCompra,
    this.servicio,
  });

  @override
  State<CompraDetalleScreen> createState() => _CompraDetalleScreenState();
}

class _CompraDetalleScreenState extends State<CompraDetalleScreen> {
  late final CompraService _servicio;

  Compra? _compra;
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
      final detalle = await _servicio.obtener(widget.idCompra);
      if (!mounted) return;
      setState(() {
        _compra = detalle;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Error de conexión al cargar detalle de compra.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compra #${widget.idCompra}'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 40, color: fsDanger),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _consultar,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _compra == null
                  ? const Center(child: Text('Compra no encontrada.'))
                  : RefreshIndicator(
                      onRefresh: _consultar,
                      color: fsGold,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _cabeceraCard(_compra!),
                            const SizedBox(height: 16),
                            const Text(
                              'ÍTEMS DEL LOTE INGRESADO',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: fsInkMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._compra!.items.map(_itemCard),
                            const SizedBox(height: 16),
                            _resumenFinancieroCard(_compra!),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _cabeceraCard(Compra c) {
    final fechaStr =
        '${c.fecha.day.toString().padLeft(2, '0')}/${c.fecha.month.toString().padLeft(2, '0')}/${c.fecha.year} ${c.fecha.hour.toString().padLeft(2, '0')}:${c.fecha.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: fsBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: fsGoldWash,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: fsGold),
                  ),
                  child: Text(
                    'LOTE INGRESADO #${c.idCompra}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: fsGoldDeep,
                    ),
                  ),
                ),
                Text(fechaStr,
                    style: const TextStyle(fontSize: 12, color: fsInkMuted)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              c.proveedorRazonSocial ?? 'Proveedor #${c.idProveedor}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: fsInk,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.storefront_outlined,
                    size: 16, color: fsInkSoft),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sucursal de destino: ${c.sucursalNombre ?? "#${c.idSucursal}"}',
                    style: const TextStyle(fontSize: 13, color: fsInkSoft),
                  ),
                ),
              ],
            ),
            if (c.usuarioNombre != null && c.usuarioNombre!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: fsInkSoft),
                  const SizedBox(width: 8),
                  Text(
                    'Receptor: ${c.usuarioNombre}',
                    style: const TextStyle(fontSize: 13, color: fsInkSoft),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _itemCard(DetalleCompraItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.prendaNombre ??
                        'Variante #${item.idVariantePrenda}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: fsInk,
                    ),
                  ),
                ),
                Text(
                  '${item.cantidad} uds.',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: fsEmerald,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (item.skuVariante != null) ...[
                  Text(
                    'SKU: ${item.skuVariante}',
                    style: const TextStyle(fontSize: 12, color: fsInkMuted),
                  ),
                  const SizedBox(width: 8),
                ],
                if (item.talla != null && item.talla!.isNotEmpty) ...[
                  Text('Talla: ${item.talla}',
                      style: const TextStyle(fontSize: 12, color: fsInkSoft)),
                  const SizedBox(width: 8),
                ],
                if (item.color != null && item.color!.isNotEmpty) ...[
                  Text('Color: ${item.color}',
                      style: const TextStyle(fontSize: 12, color: fsInkSoft)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: fsBorder, height: 1),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Costo unitario: Bs ${item.costoUnitario.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: fsInkSoft),
                ),
                Text(
                  'Subtotal: Bs ${item.subtotalItem.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fsInk,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumenFinancieroCard(Compra c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fsSurfaceAlt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fsBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal neto:',
                  style: TextStyle(fontSize: 13, color: fsInkSoft)),
              Text('Bs ${c.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: fsInk)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('IVA (13%):',
                  style: TextStyle(fontSize: 13, color: fsInkSoft)),
              Text('Bs ${c.iva.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: fsEmerald)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: fsBorder),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL FACTURADO:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: fsInk,
                ),
              ),
              Text(
                'Bs ${c.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: fsInk,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
