/// Servicio de comunicacion con los endpoints de IA del backend FastAPI (CU22).
library;

import '../../../core/api_client.dart';
import '../../../core/config.dart';
import '../../../services/auth_service.dart';
import '../models/recomendacion_ia_model.dart';
import '../models/tryon_model.dart';

/// Encapsula las llamadas al modulo /api/ia/ del backend.
///
/// Reutiliza el mismo [ApiClient] que el resto de servicios de la app,
/// inyectando el token JWT del usuario autenticado cuando esta disponible.
class IAService {
  late final ApiClient _api;

  IAService({ApiClient? api}) {
    _api = api ??
        ApiClient(
          baseUrl: apiBaseUrl,
          tokenProvider: () => AuthService().token,
        );
  }

  /// Llama a POST /api/ia/recomendar/ y devuelve la respuesta del estilista IA.
  ///
  /// Lanza [ApiException] si el backend responde con un error HTTP, o una
  /// excepcion generica si no hay conexion.
  Future<RespuestaRecomendacionIA> recomendar(
    RecomendacionIAPeticion peticion,
  ) async {
    final data = await _api.post(
      '/api/ia/recomendar/',
      body: peticion.toJson(),
    );

    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'Respuesta inesperada del servidor de IA.',
      );
    }

    return RespuestaRecomendacionIA.fromJson(data);
  }

  /// Llama a POST /api/ia/try-on y devuelve la composición fotorealista generada.
  ///
  /// Lanza [ApiException] si el backend responde con un código de error HTTP, o
  /// [FormatException] si la estructura devuelta no es la esperada.
  Future<TryOnRespuesta> generarTryOn(TryOnPeticion peticion) async {
    final data = await _api.post(
      '/api/ia/try-on',
      body: peticion.toJson(),
    );

    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'Respuesta inesperada del motor de Try-On fotorealista.',
      );
    }

    return TryOnRespuesta.fromJson(data);
  }
}
