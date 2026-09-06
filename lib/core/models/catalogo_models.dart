/// Modelos de datos del catálogo público (CU14).
///
/// Reflejan los esquemas Pydantic del backend. El precio viaja como cadena
/// (Decimal serializado), por lo que se convierte a `double` aquí.
library;

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

class CategoriaOption {
  final int idCategoria;
  final String nombre;

  const CategoriaOption({required this.idCategoria, required this.nombre});

  factory CategoriaOption.fromJson(Map<String, dynamic> json) =>
      CategoriaOption(
        idCategoria: _toInt(json['id_categoria']),
        nombre: (json['nombre'] ?? '').toString(),
      );
}

class TallaOption {
  final int idTalla;
  final String nombre;

  const TallaOption({required this.idTalla, required this.nombre});

  factory TallaOption.fromJson(Map<String, dynamic> json) => TallaOption(
        idTalla: _toInt(json['id_talla']),
        nombre: (json['nombre'] ?? '').toString(),
      );
}

class ColorOption {
  final int idColor;
  final String nombre;
  final String? codigoHex;

  const ColorOption({
    required this.idColor,
    required this.nombre,
    this.codigoHex,
  });

  factory ColorOption.fromJson(Map<String, dynamic> json) => ColorOption(
        idColor: _toInt(json['id_color']),
        nombre: (json['nombre'] ?? '').toString(),
        codigoHex: json['codigo_hex'] as String?,
      );
}

class FiltrosDisponibles {
  final List<CategoriaOption> categorias;
  final List<TallaOption> tallas;
  final List<ColorOption> colores;
  final List<String> generos;
  final double precioMinimo;
  final double precioMaximo;

  const FiltrosDisponibles({
    required this.categorias,
    required this.tallas,
    required this.colores,
    required this.generos,
    required this.precioMinimo,
    required this.precioMaximo,
  });

  factory FiltrosDisponibles.fromJson(Map<String, dynamic> json) =>
      FiltrosDisponibles(
        categorias: (json['categorias'] as List? ?? [])
            .map((e) => CategoriaOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        tallas: (json['tallas'] as List? ?? [])
            .map((e) => TallaOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        colores: (json['colores'] as List? ?? [])
            .map((e) => ColorOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        generos: (json['generos'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        precioMinimo: _toDouble(json['precio_minimo']),
        precioMaximo: _toDouble(json['precio_maximo']),
      );
}

class StockSucursal {
  final int idSucursal;
  final String sucursal;
  final String? ciudad;
  final String? direccion;
  final int stock;

  const StockSucursal({
    required this.idSucursal,
    required this.sucursal,
    this.ciudad,
    this.direccion,
    required this.stock,
  });

  factory StockSucursal.fromJson(Map<String, dynamic> json) => StockSucursal(
        idSucursal: _toInt(json['id_sucursal']),
        sucursal: (json['sucursal'] ?? '').toString(),
        ciudad: json['ciudad'] as String?,
        direccion: json['direccion'] as String?,
        stock: _toInt(json['stock']),
      );
}

class VarianteCatalogo {
  final int idVariantePrenda;
  final int idTalla;
  final String? talla;
  final int idColor;
  final String? color;
  final String? codigoHex;
  final double precio;
  final int stockTotal;
  final List<StockSucursal> disponibilidad;

  const VarianteCatalogo({
    required this.idVariantePrenda,
    required this.idTalla,
    this.talla,
    required this.idColor,
    this.color,
    this.codigoHex,
    required this.precio,
    required this.stockTotal,
    required this.disponibilidad,
  });

  factory VarianteCatalogo.fromJson(Map<String, dynamic> json) =>
      VarianteCatalogo(
        idVariantePrenda: _toInt(json['id_variante_prenda']),
        idTalla: _toInt(json['id_talla']),
        talla: json['talla'] as String?,
        idColor: _toInt(json['id_color']),
        color: json['color'] as String?,
        codigoHex: json['codigo_hex'] as String?,
        precio: _toDouble(json['precio']),
        stockTotal: _toInt(json['stock_total']),
        disponibilidad: (json['disponibilidad'] as List? ?? [])
            .map((e) => StockSucursal.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PrendaCatalogo {
  final int idPrenda;
  final String sku;
  final String nombre;
  final String? descripcion;
  final String? marca;
  final String? genero;
  final double precioBase;
  final int? idCategoria;
  final String? categoria;
  final String? urlImagen;
  final int stockTotal;
  final List<VarianteCatalogo> variantes;

  const PrendaCatalogo({
    required this.idPrenda,
    required this.sku,
    required this.nombre,
    this.descripcion,
    this.marca,
    this.genero,
    required this.precioBase,
    this.idCategoria,
    this.categoria,
    this.urlImagen,
    required this.stockTotal,
    required this.variantes,
  });

  factory PrendaCatalogo.fromJson(Map<String, dynamic> json) => PrendaCatalogo(
        idPrenda: _toInt(json['id_prenda']),
        sku: (json['sku'] ?? '').toString(),
        nombre: (json['nombre'] ?? '').toString(),
        descripcion: json['descripcion'] as String?,
        marca: json['marca'] as String?,
        genero: json['genero'] as String?,
        precioBase: _toDouble(json['precio_base']),
        idCategoria: json['id_categoria'] as int?,
        categoria: json['categoria'] as String?,
        urlImagen: json['url_imagen'] as String?,
        stockTotal: _toInt(json['stock_total']),
        variantes: (json['variantes'] as List? ?? [])
            .map((e) => VarianteCatalogo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class RespuestaCatalogo {
  final int total;
  final int limite;
  final int desplazamiento;
  final List<PrendaCatalogo> prendas;

  const RespuestaCatalogo({
    required this.total,
    required this.limite,
    required this.desplazamiento,
    required this.prendas,
  });

  factory RespuestaCatalogo.fromJson(Map<String, dynamic> json) =>
      RespuestaCatalogo(
        total: _toInt(json['total']),
        limite: _toInt(json['limite']),
        desplazamiento: _toInt(json['desplazamiento']),
        prendas: (json['prendas'] as List? ?? [])
            .map((e) => PrendaCatalogo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
