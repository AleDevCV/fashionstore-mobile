import 'dart:convert';

import '../core/api_client.dart';
import '../core/config.dart';
import '../core/models/auth_models.dart';

/// Servicio de autenticación (CU01).
///
/// Mantiene el token JWT en memoria durante la vida de la app. El backend no
/// guarda estado de sesión: "cerrar sesión" consiste en descartar el token
/// local, tal como hace el frontend Angular.
class AuthService {
  AuthService._({ApiClient? api}) : api = api ?? ApiClient(baseUrl: apiBaseUrl);

  /// Instancia única compartida: así el token que guarda el login queda
  /// disponible en cualquier pantalla que consulte la sesión.
  static final AuthService instance = AuthService._();
  factory AuthService({ApiClient? api}) {
    if (api != null) {
      return AuthService._(api: api);
    }
    return instance;
  }

  ApiClient api;

  String? _token;

  String? get token => _token;
  bool get autenticado => _token != null;

  /// Claims decodificados del token JWT en memoria.
  Map<String, dynamic>? get tokenClaims {
    final t = _token;
    if (t == null || t.isEmpty) return null;
    try {
      final partes = t.split('.');
      if (partes.length < 2) return null;
      var normalizado = base64Url.normalize(partes[1]);
      final payloadString = utf8.decode(base64Url.decode(normalizado));
      final decodificado = jsonDecode(payloadString);
      if (decodificado is Map<String, dynamic>) {
        return decodificado;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Rol asignado al usuario actual según el claim 'rol'.
  String? get rol => tokenClaims?['rol'] as String?;

  /// Nombre completo del usuario según el claim 'nombre'.
  String? get nombreUsuario => tokenClaims?['nombre'] as String?;

  /// Correo electrónico del usuario según el claim 'correo'.
  String? get correoUsuario => tokenClaims?['correo'] as String?;

  /// ID del usuario según el claim 'id_usuario' o 'sub'.
  int? get idUsuario {
    final val = tokenClaims?['id_usuario'] ?? tokenClaims?['sub'];
    if (val is int) return val;
    if (val != null) return int.tryParse(val.toString());
    return null;
  }

  /// Indica si el usuario pertenece al personal operativo o administrativo.
  bool get esPersonalAlmacen {
    if (!autenticado) return false;
    final r = rol?.toLowerCase().trim() ?? '';
    // Cualquier usuario con rol de administración, sucursal, almacén o staff
    // tiene habilitadas las pantallas de almacén.
    if (r.isEmpty || r == 'cliente') return false;
    return true;
  }

  /// Inicia sesión contra POST /api/login/ y conserva el token resultante.
  Future<RespuestaToken> login(String correo, String password) async {
    final data = await api.post(
      '/api/login/',
      body: SolicitudLogin(correo: correo, password: password).toJson(),
    );
    final respuesta = RespuestaToken.fromJson(data as Map<String, dynamic>);
    _token = respuesta.accessToken;
    return respuesta;
  }

  /// Solicita el envío de un enlace/token de recuperación (CU04).
  /// Llama a POST /api/auth/recuperar-password
  Future<RespuestaRecuperarPassword> solicitarRecuperacionPassword(String correo) async {
    final data = await api.post(
      '/api/auth/recuperar-password',
      body: SolicitudRecuperarPassword(correo: correo).toJson(),
    );
    if (data is Map<String, dynamic>) {
      return RespuestaRecuperarPassword.fromJson(data);
    }
    return const RespuestaRecuperarPassword(
      mensaje: 'Si el correo existe en el sistema, se ha enviado un enlace de recuperación.',
    );
  }

  /// Verifica si el token de recuperación es válido y vigente (CU04).
  /// Llama a POST /api/auth/verificar-token-recuperacion
  Future<RespuestaVerificarToken> verificarTokenRecuperacion(String token) async {
    final data = await api.post(
      '/api/auth/verificar-token-recuperacion',
      body: SolicitudVerificarToken(token: token).toJson(),
    );
    if (data is Map<String, dynamic>) {
      return RespuestaVerificarToken.fromJson(data);
    }
    return const RespuestaVerificarToken(valido: true);
  }

  /// Restablece la contraseña utilizando el token recibido (CU04).
  /// Llama a POST /api/auth/restablecer-password
  Future<RespuestaRestablecerPassword> restablecerPassword(
    String token,
    String nuevaPassword,
  ) async {
    final data = await api.post(
      '/api/auth/restablecer-password',
      body: SolicitudRestablecerPassword(
        token: token,
        nuevaPassword: nuevaPassword,
      ).toJson(),
    );
    if (data is Map<String, dynamic>) {
      return RespuestaRestablecerPassword.fromJson(data);
    }
    return const RespuestaRestablecerPassword(
      mensaje: 'Contraseña restablecida exitosamente.',
    );
  }

  /// Cierra la sesión destruyendo el token en memoria.
  void logout() => _token = null;
}

