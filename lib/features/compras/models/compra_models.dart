/// Modelos de datos para Recepción de Compras e Historial de Lotes (CU13).
library;

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

DateTime _toDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString()) ?? DateTime.now();
}

/// Detalle individual de producto ingresado en el lote de compra.
class DetalleCompraItem {
  final int idVariantePrenda;
  final String? skuVariante;
  final String? prendaNombre;
  final String? talla;
  final String? color;
  final int cantidad;
  final double costoUnitario;
  final double subtotalItem;

  const DetalleCompraItem({
    required this.idVariantePrenda,
    this.skuVariante,
    this.prendaNombre,
    this.talla,
    this.color,
    required this.cantidad,
    required this.costoUnitario,
    required this.subtotalItem,
  });

  factory DetalleCompraItem.fromJson(Map<String, dynamic> json) =>
      DetalleCompraItem(
        idVariantePrenda: _toInt(json['id_variante_prenda']),
        skuVariante: json['sku_variante'] as String?,
        prendaNombre: json['prenda_nombre'] as String?,
        talla: json['talla'] as String?,
        color: json['color'] as String?,
        cantidad: _toInt(json['cantidad']),
        costoUnitario: _toDouble(json['costo_unitario']),
        subtotalItem: _toDouble(json['subtotal_item']),
      );

  Map<String, dynamic> toJson() => {
        'id_variante_prenda': idVariantePrenda,
        if (skuVariante != null) 'sku_variante': skuVariante,
        if (prendaNombre != null) 'prenda_nombre': prendaNombre,
        if (talla != null) 'talla': talla,
        if (color != null) 'color': color,
        'cantidad': cantidad,
        'costo_unitario': costoUnitario,
        'subtotal_item': subtotalItem,
      };
}

/// Cabecera de compra y recepción devuelta por GET /api/compras/
class Compra {
  final int idCompra;
  final int idProveedor;
  final String? proveedorRazonSocial;
  final int idSucursal;
  final String? sucursalNombre;
  final DateTime fecha;
  final double subtotal;
  final double iva; // 13% IVA Bolivia
  final double total;
  final int? idUsuario;
  final String? usuarioNombre;
  final int totalItems;
  final List<DetalleCompraItem> items;

  const Compra({
    required this.idCompra,
    required this.idProveedor,
    this.proveedorRazonSocial,
    required this.idSucursal,
    this.sucursalNombre,
    required this.fecha,
    required this.subtotal,
    required this.iva,
    required this.total,
    this.idUsuario,
    this.usuarioNombre,
    required this.totalItems,
    this.items = const [],
  });

  factory Compra.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? (json['detalles'] as List?) ?? [];
    final itemsList = rawItems
        .map((e) => DetalleCompraItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final tot = _toDouble(json['total']);
    // Si subtotal e iva no vienen calculados explícitamente en el payload resumen:
    final sub = json['subtotal'] != null
        ? _toDouble(json['subtotal'])
        : (tot > 0 ? (tot / 1.13) : 0.0);
    final tax = json['iva'] != null
        ? _toDouble(json['iva'])
        : (tot - sub);

    return Compra(
      idCompra: _toInt(json['id_compra']),
      idProveedor: _toInt(json['id_proveedor']),
      proveedorRazonSocial: json['proveedor_razon_social'] as String?,
      idSucursal: _toInt(json['id_sucursal']),
      sucursalNombre: json['sucursal_nombre'] as String?,
      fecha: _toDate(json['fecha']),
      subtotal: sub,
      iva: tax,
      total: tot,
      idUsuario: json['id_usuario'] != null ? _toInt(json['id_usuario']) : null,
      usuarioNombre: json['usuario_nombre'] as String?,
      totalItems: json['total_items'] != null
          ? _toInt(json['total_items'])
          : itemsList.length,
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_compra': idCompra,
        'id_proveedor': idProveedor,
        if (proveedorRazonSocial != null)
          'proveedor_razon_social': proveedorRazonSocial,
        'id_sucursal': idSucursal,
        if (sucursalNombre != null) 'sucursal_nombre': sucursalNombre,
        'fecha': fecha.toIso8601String(),
        'subtotal': subtotal,
        'iva': iva,
        'total': total,
        if (idUsuario != null) 'id_usuario': idUsuario,
        if (usuarioNombre != null) 'usuario_nombre': usuarioNombre,
        'total_items': totalItems,
        'items': items.map((e) => e.toJson()).toList(),
      };
}
