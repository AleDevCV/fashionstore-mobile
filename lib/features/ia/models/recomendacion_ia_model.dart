/// Modelos de datos para el Asistente de Moda IA (CU22).
///
/// Mapean 1:1 el contrato del endpoint POST /api/ia/recomendar/ del backend
/// FastAPI, tanto en la peticion como en la respuesta.
library;

// -----------------------------------------------------------
// Peticion
// -----------------------------------------------------------

/// Parametros de preferencia que el usuario envia al estilista IA.
class RecomendacionIAPeticion {
  /// Estilo de moda deseado. Ej: "Casual", "Formal", "Deportivo", "Elegante".
  final String estilo;

  /// Ocasion de uso. Ej: "Trabajo", "Evento social", "Deporte".
  final String ocasion;

  /// Genero de la prenda. Ej: "Masculino", "Femenino", "Unisex".
  final String genero;

  /// Talla del usuario. Ej: "S", "M", "L", "XL".
  final String talla;

  /// Temporada o clima (campo libre, opcional).
  final String? temporada;

  /// Clima adicional, p.ej. "Frio", "Tropical" (opcional).
  final String? clima;

  /// Numero maximo de prendas a devolver (por defecto 5 en el backend).
  final int? limite;

  const RecomendacionIAPeticion({
    required this.estilo,
    required this.ocasion,
    required this.genero,
    required this.talla,
    this.temporada,
    this.clima,
    this.limite,
  });

  /// Serializa a un Map JSON listo para enviarse al backend.
  Map<String, dynamic> toJson() {
    return {
      'estilo': estilo,
      'ocasion': ocasion,
      'genero': genero,
      'talla': talla,
      if (temporada != null && temporada!.isNotEmpty) 'temporada': temporada,
      if (clima != null && clima!.isNotEmpty) 'clima': clima,
      if (limite != null) 'limite': limite,
    };
  }
}

// -----------------------------------------------------------
// Respuesta
// -----------------------------------------------------------

/// Una prenda individual dentro de la respuesta de recomendacion.
class PrendaRecomendada {
  final int idPrenda;
  final String nombre;
  final double precio;
  final int stockTotal;
  final String? imagenUrl;
  final String? categoria;

  /// Texto del estilista IA explicando por que recomienda esta prenda.
  final String justificacion;

  const PrendaRecomendada({
    required this.idPrenda,
    required this.nombre,
    required this.precio,
    required this.stockTotal,
    this.imagenUrl,
    this.categoria,
    required this.justificacion,
  });

  /// Construye desde el JSON que devuelve FastAPI.
  factory PrendaRecomendada.fromJson(Map<String, dynamic> json) {
    return PrendaRecomendada(
      idPrenda: (json['id_prenda'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
      stockTotal: (json['stock_total'] as num?)?.toInt() ?? 0,
      imagenUrl: json['imagen_url'] as String?,
      categoria: json['categoria'] as String?,
      justificacion: json['justificacion'] as String? ?? '',
    );
  }
}

/// Respuesta completa del endpoint POST /api/ia/recomendar/.
class RespuestaRecomendacionIA {
  /// Mensaje introductorio del estilista IA.
  final String mensajeEstilista;

  /// Lista de prendas recomendadas.
  final List<PrendaRecomendada> prendas;

  /// Indica si el backend uso un fallback (no encontro prendas ideales).
  final bool esFallback;

  const RespuestaRecomendacionIA({
    required this.mensajeEstilista,
    required this.prendas,
    required this.esFallback,
  });

  factory RespuestaRecomendacionIA.fromJson(Map<String, dynamic> json) {
    final prendasJson = json['prendas'] as List<dynamic>? ?? [];
    return RespuestaRecomendacionIA(
      mensajeEstilista: json['mensaje_estilista'] as String? ?? '',
      prendas: prendasJson
          .whereType<Map<String, dynamic>>()
          .map(PrendaRecomendada.fromJson)
          .toList(),
      esFallback: json['es_fallback'] as bool? ?? false,
    );
  }
}
