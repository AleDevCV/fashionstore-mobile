/// Modelos de datos para el Registro y Consulta de Movimientos de Inventario (CU11).
library;

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

DateTime _toDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString()) ?? DateTime.now();
}

/// Registro histórico de un movimiento devuelto por GET /api/movimientos-inventario/
class MovimientoInventario {
  final int idMovimiento;
  final int idSucursal;
  final String? sucursalNombre;
  final int idVariantePrenda;
  final String? skuVariante;
  final String? prendaNombre;
  final String? talla;
  final String? color;
  final String tipo; // 'Entrada', 'Salida', 'Traspaso'
  final int cantidad;
  final String motivo;
  final int? idUsuario;
  final String? usuarioNombre;
  final DateTime fecha;
  final int? stockActual;

  const MovimientoInventario({
    required this.idMovimiento,
    required this.idSucursal,
    this.sucursalNombre,
    required this.idVariantePrenda,
    this.skuVariante,
    this.prendaNombre,
    this.talla,
    this.color,
    required this.tipo,
    required this.cantidad,
    required this.motivo,
    this.idUsuario,
    this.usuarioNombre,
    required this.fecha,
    this.stockActual,
  });

  factory MovimientoInventario.fromJson(Map<String, dynamic> json) =>
      MovimientoInventario(
        idMovimiento: _toInt(json['id_movimiento']),
        idSucursal: _toInt(json['id_sucursal']),
        sucursalNombre: json['sucursal_nombre'] as String?,
        idVariantePrenda: _toInt(json['id_variante_prenda']),
        skuVariante: json['sku_variante'] as String?,
        prendaNombre: json['prenda_nombre'] as String?,
        talla: json['talla'] as String?,
        color: json['color'] as String?,
        tipo: (json['tipo'] ?? 'Entrada').toString(),
        cantidad: _toInt(json['cantidad']),
        motivo: (json['motivo'] ?? '').toString(),
        idUsuario: json['id_usuario'] != null ? _toInt(json['id_usuario']) : null,
        usuarioNombre: json['usuario_nombre'] as String?,
        fecha: _toDate(json['fecha']),
        stockActual: json['stock_actual'] != null
            ? _toInt(json['stock_actual'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id_movimiento': idMovimiento,
        'id_sucursal': idSucursal,
        if (sucursalNombre != null) 'sucursal_nombre': sucursalNombre,
        'id_variante_prenda': idVariantePrenda,
        if (skuVariante != null) 'sku_variante': skuVariante,
        if (prendaNombre != null) 'prenda_nombre': prendaNombre,
        if (talla != null) 'talla': talla,
        if (color != null) 'color': color,
        'tipo': tipo,
        'cantidad': cantidad,
        'motivo': motivo,
        if (idUsuario != null) 'id_usuario': idUsuario,
        if (usuarioNombre != null) 'usuario_nombre': usuarioNombre,
        'fecha': fecha.toIso8601String(),
        if (stockActual != null) 'stock_actual': stockActual,
      };
}

/// Payload para enviar a POST /api/movimientos-inventario/
class MovimientoCrear {
  final int idSucursal;
  final int idVariantePrenda;
  final String tipo; // 'Entrada', 'Salida', 'Traspaso'
  final int cantidad;
  final String motivo;

  const MovimientoCrear({
    required this.idSucursal,
    required this.idVariantePrenda,
    required this.tipo,
    required this.cantidad,
    required this.motivo,
  });

  Map<String, dynamic> toJson() => {
        'id_sucursal': idSucursal,
        'id_variante_prenda': idVariantePrenda,
        'tipo': tipo,
        'cantidad': cantidad,
        'motivo': motivo,
      };
}

/// Consulta de existencias físicas devuelta por GET /api/movimientos-inventario/stock
class StockRespuesta {
  final int idSucursal;
  final int idVariantePrenda;
  final int stock;

  const StockRespuesta({
    required this.idSucursal,
    required this.idVariantePrenda,
    required this.stock,
  });

  factory StockRespuesta.fromJson(Map<String, dynamic> json) => StockRespuesta(
        idSucursal: _toInt(json['id_sucursal']),
        idVariantePrenda: _toInt(json['id_variante_prenda']),
        stock: _toInt(json['stock']),
      );
}

/// Ficha de sucursal física para selectores de formulario
class SucursalOpcion {
  final int idSucursal;
  final String nombre;
  final String? ciudad;
  final String? direccion;

  const SucursalOpcion({
    required this.idSucursal,
    required this.nombre,
    this.ciudad,
    this.direccion,
  });

  factory SucursalOpcion.fromJson(Map<String, dynamic> json) => SucursalOpcion(
        idSucursal: _toInt(json['id_sucursal']),
        nombre: (json['nombre'] ?? '').toString(),
        ciudad: json['ciudad'] as String?,
        direccion: json['direccion'] as String?,
      );
}

/// Ficha de variante de prenda para selectores de inventario
class VarianteOpcion {
  final int idVariantePrenda;
  final String skuVariante;
  final String prendaNombre;
  final String? talla;
  final String? color;

  const VarianteOpcion({
    required this.idVariantePrenda,
    required this.skuVariante,
    required this.prendaNombre,
    this.talla,
    this.color,
  });

  String get etiquetaCompleta {
    final detalle = [
      if (talla != null && talla!.isNotEmpty) 'Talla $talla',
      if (color != null && color!.isNotEmpty) color,
    ].join(', ');
    return '$prendaNombre (${skuVariante.isNotEmpty ? skuVariante : "ID $idVariantePrenda"})'
        '${detalle.isNotEmpty ? " - $detalle" : ""}';
  }
}
