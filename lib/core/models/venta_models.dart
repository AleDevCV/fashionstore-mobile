/// Ítem almacenado en el carrito de compras móvil.
class CarritoItem {
  final int idVariantePrenda;
  final String? skuVariante;
  final String prendaNombre;
  final String? talla;
  final String? color;
  final double precioUnitario;
  int cantidad;

  CarritoItem({
    required this.idVariantePrenda,
    this.skuVariante,
    required this.prendaNombre,
    this.talla,
    this.color,
    required this.precioUnitario,
    this.cantidad = 1,
  });

  double get subtotal => precioUnitario * cantidad;

  factory CarritoItem.fromJson(Map<String, dynamic> json) {
    return CarritoItem(
      idVariantePrenda: json['id_variante_prenda'] as int,
      skuVariante: json['sku_variante'] as String?,
      prendaNombre: json['prenda_nombre'] as String? ?? 'Prenda',
      talla: json['talla'] as String?,
      color: json['color'] as String?,
      precioUnitario: (json['precio_unitario'] as num).toDouble(),
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_variante_prenda': idVariantePrenda,
      'sku_variante': skuVariante,
      'prenda_nombre': prendaNombre,
      'talla': talla,
      'color': color,
      'precio_unitario': precioUnitario,
      'cantidad': cantidad,
    };
  }
}

/// Petición para crear una reserva desde el carrito móvil.
class ReservaPeticion {
  final int idCliente;
  final int idSucursal;
  final List<DetalleReservaItem> items;

  ReservaPeticion({
    required this.idCliente,
    required this.idSucursal,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_cliente': idCliente,
      'id_sucursal': idSucursal,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class DetalleReservaItem {
  final int idVariantePrenda;
  final int cantidad;
  final double precioUnitario;

  DetalleReservaItem({
    required this.idVariantePrenda,
    required this.cantidad,
    required this.precioUnitario,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_variante_prenda': idVariantePrenda,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
    };
  }
}

double _parseNum(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

/// Respuesta de reserva creada.
class ReservaRespuesta {
  final int idReserva;
  final int idCliente;
  final int idSucursal;
  final String? sucursalNombre;
  final String fechaReserva;
  final String fechaLimite;
  final String estado;
  final double total;

  ReservaRespuesta({
    required this.idReserva,
    required this.idCliente,
    required this.idSucursal,
    this.sucursalNombre,
    required this.fechaReserva,
    required this.fechaLimite,
    required this.estado,
    required this.total,
  });

  factory ReservaRespuesta.fromJson(Map<String, dynamic> json) {
    return ReservaRespuesta(
      idReserva: json['id_reserva'] as int,
      idCliente: json['id_cliente'] as int,
      idSucursal: json['id_sucursal'] as int,
      sucursalNombre: json['sucursal_nombre'] as String?,
      fechaReserva: json['fecha_reserva'] as String,
      fechaLimite: json['fecha_limite'] as String,
      estado: json['estado'] as String,
      total: _parseNum(json['total']),
    );
  }
}

/// Respuesta de sesión creada en Stripe Checkout (CU20).
class StripeCheckoutRespuesta {
  final String urlPago;
  final String sessionId;
  final int idReserva;
  final double monto;

  StripeCheckoutRespuesta({
    required this.urlPago,
    required this.sessionId,
    required this.idReserva,
    required this.monto,
  });

  factory StripeCheckoutRespuesta.fromJson(Map<String, dynamic> json) {
    return StripeCheckoutRespuesta(
      urlPago: json['url_pago'] as String,
      sessionId: json['session_id'] as String,
      idReserva: json['id_reserva'] as int,
      monto: _parseNum(json['monto']),
    );
  }
}

/// Petición para generar un código QR de pago boliviano.
class QRGenerarPeticion {
  final int idReserva;
  final int idCliente;
  final double monto;
  final String concepto;

  QRGenerarPeticion({
    required this.idReserva,
    required this.idCliente,
    required this.monto,
    this.concepto = 'Pago FashionStore Móvil',
  });

  Map<String, dynamic> toJson() {
    return {
      'id_reserva': idReserva,
      'id_cliente': idCliente,
      'monto': monto,
      'concepto': concepto,
    };
  }
}

/// Respuesta con el código QR en base64.
class QRGenerarRespuesta {
  final String qrBase64;
  final String referencia;
  final double monto;
  final int idReserva;
  final int expiraEnMinutos;

  QRGenerarRespuesta({
    required this.qrBase64,
    required this.referencia,
    required this.monto,
    required this.idReserva,
    required this.expiraEnMinutos,
  });

  factory QRGenerarRespuesta.fromJson(Map<String, dynamic> json) {
    return QRGenerarRespuesta(
      qrBase64: json['qr_base64'] as String,
      referencia: json['referencia'] as String,
      monto: _parseNum(json['monto']),
      idReserva: json['id_reserva'] as int,
      expiraEnMinutos: (json['expira_en_minutos'] as num?)?.toInt() ?? 15,
    );
  }
}

/// Petición para confirmar el pago QR.
class QRConfirmarPeticion {
  final String referencia;
  final int idReserva;
  final int idCliente;
  final int idSucursal;

  QRConfirmarPeticion({
    required this.referencia,
    required this.idReserva,
    required this.idCliente,
    required this.idSucursal,
  });

  Map<String, dynamic> toJson() {
    return {
      'referencia': referencia,
      'id_reserva': idReserva,
      'id_cliente': idCliente,
      'id_sucursal': idSucursal,
    };
  }
}

/// Comprobante fiscal digital (PDF).
class ComprobanteRespuesta {
  final int idComprobante;
  final int idVenta;
  final String numeroComprobante;
  final String nitCi;
  final String razonSocial;
  final String fechaEmision;
  final String? urlPdf;

  ComprobanteRespuesta({
    required this.idComprobante,
    required this.idVenta,
    required this.numeroComprobante,
    required this.nitCi,
    required this.razonSocial,
    required this.fechaEmision,
    this.urlPdf,
  });

  factory ComprobanteRespuesta.fromJson(Map<String, dynamic> json) {
    return ComprobanteRespuesta(
      idComprobante: json['id_comprobante'] as int,
      idVenta: json['id_venta'] as int,
      numeroComprobante: json['numero_comprobante'] as String,
      nitCi: json['nit_ci'] as String,
      razonSocial: json['razon_social'] as String,
      fechaEmision: json['fecha_emision'] as String,
      urlPdf: json['url_pdf'] as String?,
    );
  }
}

/// Petición para crear una reserva de prendas para probar en sucursal (CU16).
class ReservaProbadorPeticion {
  final int idCliente;
  final int idSucursal;
  final int horasVigencia;
  final List<DetalleReservaItem> items;

  ReservaProbadorPeticion({
    required this.idCliente,
    required this.idSucursal,
    this.horasVigencia = 2,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_cliente': idCliente,
      'id_sucursal': idSucursal,
      'horas_vigencia': horasVigencia,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

/// Ítem desglosado dentro del ticket de reserva.
class DetalleTicketItem {
  final int idVariantePrenda;
  final String? skuVariante;
  final String prendaNombre;
  final String? talla;
  final String? color;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  DetalleTicketItem({
    required this.idVariantePrenda,
    this.skuVariante,
    required this.prendaNombre,
    this.talla,
    this.color,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory DetalleTicketItem.fromJson(Map<String, dynamic> json) {
    return DetalleTicketItem(
      idVariantePrenda: json['id_variante_prenda'] as int,
      skuVariante: json['sku_variante'] as String?,
      prendaNombre: json['prenda_nombre'] as String? ?? 'Prenda',
      talla: json['talla'] as String?,
      color: json['color'] as String?,
      cantidad: (json['cantidad'] as num).toInt(),
      precioUnitario: (json['precio_unitario'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }
}

/// Ticket digital omnicanal con código QR para atención en tienda (CU16, CU17).
class TicketReservaRespuesta {
  final int idReserva;
  final String codigoTicket;
  final String qrBase64;
  final int idCliente;
  final String? clienteNombre;
  final int idSucursal;
  final String? sucursalNombre;
  final String fechaReserva;
  final String fechaLimite;
  final String estado;
  final double total;
  final List<DetalleTicketItem> items;

  TicketReservaRespuesta({
    required this.idReserva,
    required this.codigoTicket,
    required this.qrBase64,
    required this.idCliente,
    this.clienteNombre,
    required this.idSucursal,
    this.sucursalNombre,
    required this.fechaReserva,
    required this.fechaLimite,
    required this.estado,
    required this.total,
    required this.items,
  });

  factory TicketReservaRespuesta.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return TicketReservaRespuesta(
      idReserva: json['id_reserva'] as int,
      codigoTicket: json['codigo_ticket'] as String? ?? 'TKT-${json['id_reserva']}',
      qrBase64: json['qr_base64'] as String? ?? '',
      idCliente: json['id_cliente'] as int,
      clienteNombre: json['cliente_nombre'] as String?,
      idSucursal: json['id_sucursal'] as int,
      sucursalNombre: json['sucursal_nombre'] as String?,
      fechaReserva: json['fecha_reserva'] as String,
      fechaLimite: json['fecha_limite'] as String,
      estado: json['estado'] as String,
      total: (json['total'] as num).toDouble(),
      items: rawItems
          .map((e) => DetalleTicketItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

