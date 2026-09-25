import 'package:flutter/foundation.dart';
import '../core/models/venta_models.dart';

/// Servicio y ViewModel de gestión del carrito de compras móvil (CU15).
///
/// Extiende [ChangeNotifier] siguiendo el patrón MVVM y la guía de
/// flutter-apply-architecture-best-practices. Mantiene los ítems seleccionados
/// y notifica reactivamente a las vistas interesadas.
class CarritoService extends ChangeNotifier {
  CarritoService._();
  static final CarritoService instance = CarritoService._();

  final List<CarritoItem> _items = [];

  List<CarritoItem> get items => List.unmodifiable(_items);

  int get totalItems => _items.fold(0, (acc, it) => acc + it.cantidad);

  double get totalMonto => _items.fold(0.0, (acc, it) => acc + it.subtotal);

  bool get estaVacio => _items.isEmpty;

  void agregarItem(CarritoItem nuevo) {
    final idx = _items.indexWhere((i) => i.idVariantePrenda == nuevo.idVariantePrenda);
    if (idx >= 0) {
      _items[idx].cantidad += nuevo.cantidad;
    } else {
      _items.add(nuevo);
    }
    notifyListeners();
  }

  void cambiarCantidad(int idVariantePrenda, int cantidad) {
    if (cantidad <= 0) {
      eliminarItem(idVariantePrenda);
      return;
    }
    final idx = _items.indexWhere((i) => i.idVariantePrenda == idVariantePrenda);
    if (idx >= 0) {
      _items[idx].cantidad = cantidad;
      notifyListeners();
    }
  }

  void eliminarItem(int idVariantePrenda) {
    _items.removeWhere((i) => i.idVariantePrenda == idVariantePrenda);
    notifyListeners();
  }

  void vaciarCarrito() {
    _items.clear();
    notifyListeners();
  }

  void limpiarComprados(List<dynamic> itemsComprados) {
    for (final item in itemsComprados) {
      final int idVariante = item is Map
          ? (item['id_variante_prenda'] as num).toInt()
          : (item.idVariantePrenda as num).toInt();
      final int cant = item is Map
          ? (item['cantidad'] as num).toInt()
          : (item.cantidad as num).toInt();
      final idx = _items.indexWhere((i) => i.idVariantePrenda == idVariante);
      if (idx >= 0) {
        if (_items[idx].cantidad <= cant) {
          _items.removeAt(idx);
        } else {
          _items[idx].cantidad -= cant;
        }
      }
    }
    notifyListeners();
  }
}
