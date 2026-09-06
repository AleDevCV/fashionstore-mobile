import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

/// Excepción con el mensaje ya traducido del backend (equivalente móvil del
/// `api-error.ts` del frontend Angular).
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Cliente HTTP delgado: centraliza la URL base, las cabeceras y la traducción
/// de errores de FastAPI a mensajes legibles.
class ApiClient {
  final String baseUrl;

  /// Provee el token JWT actual, si existe. Los endpoints públicos lo ignoran.
  final String? Function()? tokenProvider;

  ApiClient({required this.baseUrl, this.tokenProvider});

  Map<String, String> get _headers {
    final token = tokenProvider?.call();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Petición GET. [query] son parámetros de consulta ya filtrados.
  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    var uri = Uri.parse('$baseUrl$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    final resp = await http.get(uri, headers: _headers);
    return _decodificar(resp);
  }

  /// Petición POST con cuerpo JSON.
  Future<dynamic> post(String path, {Object? body}) async {
    final resp = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: body == null ? null : jsonEncode(body),
    );
    return _decodificar(resp);
  }

  dynamic _decodificar(http.Response resp) {
    dynamic data;
    if (resp.body.isNotEmpty) {
      try {
        data = jsonDecode(resp.body);
      } catch (_) {
        data = resp.body;
      }
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return data;
    }

    // Traducción de errores: prioriza la clave `detail` de FastAPI.
    String message = 'Ocurrió un error inesperado. Intente nuevamente.';
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        message = detail;
      } else if (detail is List && detail.isNotEmpty && detail.first is Map) {
        final primero = detail.first as Map;
        message = (primero['msg'] ?? 'Datos no válidos').toString();
      } else if (detail != null) {
        message = detail.toString();
      }
    }

    throw ApiException(resp.statusCode, message);
  }
}
