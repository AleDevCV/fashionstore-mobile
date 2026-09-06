import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/models/catalogo_models.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/catalogo_service.dart';

/// Ficha de una prenda con su disponibilidad por sucursal (CU14).
///
/// Consume GET /api/catalogo/{id}, que ya incluye el desglose de stock por
/// sucursal para cada combinación de talla y color.
class PrendaDetalleScreen extends StatefulWidget {
  final int idPrenda;

  const PrendaDetalleScreen({super.key, required this.idPrenda});

  @override
  State<PrendaDetalleScreen> createState() => _PrendaDetalleScreenState();
}

class _PrendaDetalleScreenState extends State<PrendaDetalleScreen> {
  final CatalogoService _servicio = CatalogoService();

  PrendaCatalogo? _prenda;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final prenda = await _servicio.obtenerFicha(widget.idPrenda);
      if (!mounted) return;
      setState(() => _prenda = prenda);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_prenda?.nombre ?? 'Detalle de prenda')),
      body: _contenido(),
    );
  }

  Widget _contenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: fsDanger, size: 32),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: fsDanger),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final p = _prenda!;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        AspectRatio(aspectRatio: 4 / 3, child: redImagen(p.urlImagen)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${p.categoria ?? 'Sin categoría'} · ${p.genero ?? '—'}',
                style: const TextStyle(fontSize: 11, letterSpacing: 1.4, color: fsInkMuted),
              ),
              const SizedBox(height: 6),
              Text(
                p.nombre,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (p.marca != null && p.marca!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(p.marca!, style: const TextStyle(color: fsInkSoft)),
              ],
              const SizedBox(height: 8),
              Text(
                formatearPrecio(p.precioBase),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              if (p.descripcion != null && p.descripcion!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  p.descripcion!,
                  style: const TextStyle(color: fsInkSoft, height: 1.5),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1, color: fsBorder),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DISPONIBILIDAD POR SUCURSAL',
                style: TextStyle(fontSize: 11, letterSpacing: 1.4, color: fsInkMuted),
              ),
              const SizedBox(height: 12),
              if (p.variantes.isEmpty)
                const Text(
                  'Esta prenda no tiene variantes registradas.',
                  style: TextStyle(color: fsInkSoft),
                )
              else
                ...p.variantes.map(_varianteCard),
            ],
          ),
        ),
      ],
    );
  }

  Widget _varianteCard(VarianteCatalogo v) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: fsBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${v.talla ?? '—'} / ${v.color ?? '—'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  formatearPrecio(v.precio),
                  style: const TextStyle(color: fsInkSoft, fontSize: 13),
                ),
                const SizedBox(width: 10),
                badgeStock(v.stockTotal),
              ],
            ),
            const SizedBox(height: 10),
            if (v.disponibilidad.isEmpty)
              const Text(
                'Sin stock en ninguna sucursal.',
                style: TextStyle(color: fsInkMuted, fontSize: 13),
              )
            else
              ...v.disponibilidad.map(_filaSucursal),
          ],
        ),
      ),
    );
  }

  Widget _filaSucursal(StockSucursal s) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.storefront_outlined, size: 18, color: fsInkMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.sucursal, style: const TextStyle(fontWeight: FontWeight.w500)),
                if (s.ciudad != null && s.ciudad!.isNotEmpty)
                  Text(s.ciudad!, style: const TextStyle(fontSize: 12, color: fsInkMuted)),
              ],
            ),
          ),
          Text(
            '${s.stock} u. disponibles',
            style: const TextStyle(color: fsEmerald, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
