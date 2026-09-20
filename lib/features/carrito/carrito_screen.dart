import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/carrito_service.dart';
import '../checkout/checkout_screen.dart';

/// Pantalla del carrito de compras móvil (CU15).
class CarritoScreen extends StatelessWidget {
  const CarritoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final carrito = CarritoService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito'),
        actions: [
          ListenableBuilder(
            listenable: carrito,
            builder: (context, _) {
              if (carrito.estaVacio) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Vaciar carrito',
                onPressed: () => _confirmarVaciar(context),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: carrito,
        builder: (context, _) {
          if (carrito.estaVacio) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 64, color: fsInkMuted),
                  const SizedBox(height: 16),
                  const Text(
                    'Tu carrito está vacío',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Explora nuestro catálogo para agregar prendas.',
                    style: TextStyle(color: fsInkSoft),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: fsInk,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Ir al Catálogo'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: carrito.items.length,
                  separatorBuilder: (_, __) => const Divider(color: fsBorder),
                  itemBuilder: (context, index) {
                    final item = carrito.items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 75,
                            decoration: BoxDecoration(
                              color: fsSurfaceAlt,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: fsBorder),
                            ),
                            child: const Icon(Icons.checkroom, color: fsGold, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.prendaNombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Talla: ${item.talla ?? 'Única'} · Color: ${item.color ?? 'Único'}',
                                  style: const TextStyle(fontSize: 12, color: fsInkMuted),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Bs ${item.precioUnitario.toStringAsFixed(2)} c/u',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: fsInkSoft,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Bs ${item.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                                    onPressed: () => carrito.cambiarCantidad(
                                      item.idVariantePrenda,
                                      item.cantidad - 1,
                                    ),
                                  ),
                                  Text(
                                    '${item.cantidad}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 20),
                                    onPressed: () => carrito.cambiarCantidad(
                                      item.idVariantePrenda,
                                      item.cantidad + 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: fsSurface,
                  border: Border(top: BorderSide(color: fsBorder)),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Estimado:',
                            style: TextStyle(fontSize: 16, color: fsInkSoft),
                          ),
                          Text(
                            'Bs ${carrito.totalMonto.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CheckoutScreen(),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: fsInk,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            'Proceder al Pago',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmarVaciar(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text('¿Estás seguro de que deseas eliminar todos los productos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              CarritoService.instance.vaciarCarrito();
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: fsDanger),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
  }
}
