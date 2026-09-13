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

/// Contratos para Recuperación de Contraseña (CU04).

class SolicitudRecuperarPassword {
  final String correo;

  const SolicitudRecuperarPassword({required this.correo});

  Map<String, dynamic> toJson() => {'correo': correo};
}

class RespuestaRecuperarPassword {
  final String mensaje;

  const RespuestaRecuperarPassword({required this.mensaje});

  factory RespuestaRecuperarPassword.fromJson(Map<String, dynamic> json) =>
      RespuestaRecuperarPassword(
        mensaje: (json['mensaje'] ?? '') as String,
      );
}

class SolicitudVerificarToken {
  final String token;

  const SolicitudVerificarToken({required this.token});

  Map<String, dynamic> toJson() => {'token': token};
}

class RespuestaVerificarToken {
  final bool valido;
  final String? correo;

  const RespuestaVerificarToken({required this.valido, this.correo});

  factory RespuestaVerificarToken.fromJson(Map<String, dynamic> json) =>
      RespuestaVerificarToken(
        valido: (json['valido'] ?? false) as bool,
        correo: json['correo'] as String?,
      );
}

class SolicitudRestablecerPassword {
  final String token;
  final String nuevaPassword;

  const SolicitudRestablecerPassword({
    required this.token,
    required this.nuevaPassword,
  });

  Map<String, dynamic> toJson() => {
        'token': token,
        'nueva_password': nuevaPassword,
      };
}

class RespuestaRestablecerPassword {
  final String mensaje;

  const RespuestaRestablecerPassword({required this.mensaje});

  factory RespuestaRestablecerPassword.fromJson(Map<String, dynamic> json) =>
      RespuestaRestablecerPassword(
        mensaje: (json['mensaje'] ?? '') as String,
      );
}

