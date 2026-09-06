import '../core/api_client.dart';
import '../core/config.dart';
import '../core/models/auth_models.dart';

/// Servicio de autenticación (CU01).
///
/// Mantiene el token JWT en memoria durante la vida de la app. El backend no
/// guarda estado de sesión: "cerrar sesión" consiste en descartar el token
/// local, tal como hace el frontend Angular.
class AuthService {
  AuthService._();

  /// Instancia única compartida: así el token que guarda el login queda
  /// disponible en cualquier pantalla que consulte la sesión.
  static final AuthService instance = AuthService._();
  factory AuthService() => instance;

  final ApiClient _api = ApiClient(baseUrl: apiBaseUrl);

  String? _token;

  String? get token => _token;
  bool get autenticado => _token != null;

  /// Inicia sesión contra POST /api/login/ y conserva el token resultante.
  Future<RespuestaToken> login(String correo, String password) async {
    final data = await _api.post(
      '/api/login/',
      body: SolicitudLogin(correo: correo, password: password).toJson(),
    );
    final respuesta = RespuestaToken.fromJson(data as Map<String, dynamic>);
    _token = respuesta.accessToken;
    return respuesta;
  }

  /// Cierra la sesión destruyendo el token en memoria.
  void logout() => _token = null;
}
