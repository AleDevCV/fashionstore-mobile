/// Modelos de datos para el Vestidor Virtual Fotorealista con IA (Fase 2 / Try-On).
///
/// Mapean 1:1 el contrato del endpoint POST /api/ia/try-on del backend FastAPI.
library;

/// Parámetros enviados para la composición fotorealista de la prenda.
class TryOnPeticion {
  /// Fotografía del usuario en formato Base64 (con o sin encabezado data:image/...;base64,).
  final String fotoUsuario;

  /// Identificador numérico de la prenda en catálogo.
  final int? idPrenda;

  /// URL o Base64 opcional de la prenda con transparencia PNG.
  final String? urlPrenda;

  /// Habilitar refinamiento con IA generativa (Gemini Vision) o motor híbrido local.
  final bool usarIaGenerativa;

  /// Factor de entalle u holgura (1.0 estándar, <1 ajustado, >1 holgado).
  final double ajusteHolgura;

  /// Identificador opcional de variante específica de la prenda.
  final int? idVariantePrenda;

  const TryOnPeticion({
    required this.fotoUsuario,
    this.idPrenda,
    this.urlPrenda,
    this.usarIaGenerativa = true,
    this.ajusteHolgura = 1.0,
    this.idVariantePrenda,
  });

  /// Serializa la petición a JSON para la API.
  Map<String, dynamic> toJson() {
    return {
      'foto_usuario': fotoUsuario,
      if (idPrenda != null) 'id_prenda': idPrenda,
      if (urlPrenda != null) 'url_prenda': urlPrenda,
      'usar_ia_generativa': usarIaGenerativa,
      'ajuste_holgura': ajusteHolgura,
      if (idVariantePrenda != null) 'id_variante_prenda': idVariantePrenda,
    };
  }
}

Map<String, dynamic> _toMap(dynamic val) {
  if (val is Map) {
    return val.map((k, v) => MapEntry(k.toString(), v));
  }
  return const {};
}

/// Telemetría y métricas de ajuste anatómico y balance lumínico.
class MetadatosCalce {
  final String metodo;
  final String? metodoUsado;
  final Map<String, dynamic> anclajeTorso;
  final Map<String, dynamic> ajusteLuz;
  final int? prendaId;
  final bool esFallback;
  final double tiempoProcesamientoMs;

  const MetadatosCalce({
    this.metodo = 'hibrido',
    this.metodoUsado,
    this.anclajeTorso = const {},
    this.ajusteLuz = const {},
    this.prendaId,
    this.esFallback = false,
    this.tiempoProcesamientoMs = 0.0,
  });

  factory MetadatosCalce.fromJson(Map<String, dynamic> json) {
    return MetadatosCalce(
      metodo: json['metodo'] as String? ?? 'hibrido',
      metodoUsado: json['metodo_usado'] as String? ?? json['metodo'] as String?,
      anclajeTorso: _toMap(json['anclaje_torso']),
      ajusteLuz: _toMap(json['ajuste_luz']),
      prendaId: (json['prenda_id'] as num?)?.toInt(),
      esFallback: json['es_fallback'] as bool? ?? false,
      tiempoProcesamientoMs:
          (json['tiempo_procesamiento_ms'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metodo': metodo,
      if (metodoUsado != null) 'metodo_usado': metodoUsado,
      'anclaje_torso': anclajeTorso,
      'ajuste_luz': ajusteLuz,
      if (prendaId != null) 'prenda_id': prendaId,
      'es_fallback': esFallback,
      'tiempo_procesamiento_ms': tiempoProcesamientoMs,
    };
  }
}

/// Respuesta devuelta por POST /api/ia/try-on.
class TryOnRespuesta {
  final String estado;

  /// Imagen resultante en formato Data URI Base64 (data:image/jpeg;base64,...).
  final String imagenResultado;

  /// Tiempo de ejecución en milisegundos.
  final double tiempoProcesamientoMs;

  /// Métricas de calce anatómico.
  final MetadatosCalce? metadatosCalce;

  /// Mensaje descriptivo o recomendación de calce.
  final String mensaje;

  /// Si fue generado o refinado por IA generativa.
  final bool esGenerativo;

  /// Método efectivamente ejecutado ('gemini_multimodal_tryon' u 'opencv_homography_warp').
  final String? metodoUsado;

  /// Alias de la imagen en Base64.
  final String? imagenResultadoB64;

  const TryOnRespuesta({
    this.estado = 'exito',
    required this.imagenResultado,
    required this.tiempoProcesamientoMs,
    this.metadatosCalce,
    this.mensaje = 'Composición completada exitosamente',
    this.esGenerativo = false,
    this.metodoUsado,
    this.imagenResultadoB64,
  });

  factory TryOnRespuesta.fromJson(Map<String, dynamic> json) {
    MetadatosCalce? calce;
    if (json['metadatos_calce'] is Map) {
      calce = MetadatosCalce.fromJson(
        _toMap(json['metadatos_calce']),
      );
    }

    final imgRes = json['imagen_resultado'] as String? ?? '';
    final imgB64 = json['imagen_resultado_b64'] as String? ?? imgRes;

    return TryOnRespuesta(
      estado: json['estado'] as String? ?? 'exito',
      imagenResultado: imgRes,
      tiempoProcesamientoMs:
          (json['tiempo_procesamiento_ms'] as num?)?.toDouble() ?? 0.0,
      metadatosCalce: calce,
      mensaje: json['mensaje'] as String? ?? 'Composición completada exitosamente',
      esGenerativo: json['es_generativo'] as bool? ?? false,
      metodoUsado: json['metodo_usado'] as String? ??
          (calce?.metodoUsado ?? 'opencv_homography_warp'),
      imagenResultadoB64: imgB64,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estado': estado,
      'imagen_resultado': imagenResultado,
      if (imagenResultadoB64 != null) 'imagen_resultado_b64': imagenResultadoB64,
      if (metodoUsado != null) 'metodo_usado': metodoUsado,
      'tiempo_procesamiento_ms': tiempoProcesamientoMs,
      if (metadatosCalce != null) 'metadatos_calce': metadatosCalce!.toJson(),
      'mensaje': mensaje,
      'es_generativo': esGenerativo,
    };
  }
}
