/// Modelos de datos para el Directorio de Proveedores (CU12).
library;

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

/// Entidad Proveedor devuelta por GET /api/proveedores/
class Proveedor {
  final int idProveedor;
  final String nit;
  final String razonSocial;
  final String? contacto;
  final String? telefono;
  final String? correo;
  final String? direccion;
  final DateTime? createdAt;

  const Proveedor({
    required this.idProveedor,
    required this.nit,
    required this.razonSocial,
    this.contacto,
    this.telefono,
    this.correo,
    this.direccion,
    this.createdAt,
  });

  factory Proveedor.fromJson(Map<String, dynamic> json) => Proveedor(
        idProveedor: _toInt(json['id_proveedor']),
        nit: (json['nit'] ?? '').toString(),
        razonSocial: (json['razon_social'] ?? '').toString(),
        contacto: json['contacto'] as String?,
        telefono: json['telefono'] as String?,
        correo: json['correo'] as String?,
        direccion: json['direccion'] as String?,
        createdAt: _toDate(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id_proveedor': idProveedor,
        'nit': nit,
        'razon_social': razonSocial,
        if (contacto != null) 'contacto': contacto,
        if (telefono != null) 'telefono': telefono,
        if (correo != null) 'correo': correo,
        if (direccion != null) 'direccion': direccion,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}
