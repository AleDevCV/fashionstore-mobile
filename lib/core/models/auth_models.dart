/// Contratos de datos del módulo de autenticación (CU01).
library;

class SolicitudLogin {
  final String correo;
  final String password;

  const SolicitudLogin({required this.correo, required this.password});

  Map<String, dynamic> toJson() => {'correo': correo, 'password': password};
}

class RespuestaToken {
  final String accessToken;
  final String tokenType;

  const RespuestaToken({required this.accessToken, required this.tokenType});

  factory RespuestaToken.fromJson(Map<String, dynamic> json) => RespuestaToken(
        accessToken: json['access_token'] as String,
        tokenType: (json['token_type'] ?? 'bearer') as String,
      );
}
