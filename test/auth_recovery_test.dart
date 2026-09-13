import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fashionstore_mobile/core/api_client.dart';
import 'package:fashionstore_mobile/core/models/auth_models.dart';
import 'package:fashionstore_mobile/features/auth/screens/nueva_password_screen.dart';
import 'package:fashionstore_mobile/features/auth/screens/recuperar_password_screen.dart';
import 'package:fashionstore_mobile/features/login/login_screen.dart';
import 'package:fashionstore_mobile/services/auth_service.dart';

/// Cliente simulado para validar llamadas HTTP sin red externa
class MockApiClient extends ApiClient {
  String? lastPath;
  Object? lastBody;
  dynamic mockResponse;
  int? throwStatusCode;
  String? throwMessage;

  MockApiClient() : super(baseUrl: 'http://test-server:8000');

  @override
  Future<dynamic> post(String path, {Object? body}) async {
    lastPath = path;
    lastBody = body;
    if (throwStatusCode != null) {
      throw ApiException(throwStatusCode!, throwMessage ?? 'Error simulado');
    }
    return mockResponse;
  }
}

void main() {
  group('CU04 - Request / Response Serialization', () {
    test('SolicitudRecuperarPassword serializa correctamente a JSON', () {
      const solicitud = SolicitudRecuperarPassword(correo: 'usuario@fashionstore.com');
      final json = solicitud.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['correo'], equals('usuario@fashionstore.com'));
    });

    test('RespuestaRecuperarPassword deserializa correctamente desde JSON', () {
      final json = {
        'mensaje': 'Si el correo existe en el sistema, se ha enviado un enlace de recuperación.',
      };
      final respuesta = RespuestaRecuperarPassword.fromJson(json);

      expect(respuesta.mensaje, contains('enlace de recuperación'));
    });

    test('SolicitudVerificarToken serializa correctamente a JSON', () {
      const solicitud = SolicitudVerificarToken(token: 'token_seguro_xyz_123');
      final json = solicitud.toJson();

      expect(json['token'], equals('token_seguro_xyz_123'));
    });

    test('RespuestaVerificarToken deserializa token válido y correo ofuscado', () {
      final json = {
        'valido': true,
        'correo': 'ad***@fashionstore.com',
      };
      final respuesta = RespuestaVerificarToken.fromJson(json);

      expect(respuesta.valido, isTrue);
      expect(respuesta.correo, equals('ad***@fashionstore.com'));
    });

    test('RespuestaVerificarToken maneja valores por defecto cuando no vienen campos', () {
      final json = <String, dynamic>{};
      final respuesta = RespuestaVerificarToken.fromJson(json);

      expect(respuesta.valido, isFalse);
      expect(respuesta.correo, isNull);
    });

    test('SolicitudRestablecerPassword serializa token y nueva_password', () {
      const solicitud = SolicitudRestablecerPassword(
        token: 'token_prueba_abc',
        nuevaPassword: 'PasswordSegura2026!',
      );
      final json = solicitud.toJson();

      expect(json['token'], equals('token_prueba_abc'));
      expect(json['nueva_password'], equals('PasswordSegura2026!'));
    });

    test('RespuestaRestablecerPassword deserializa confirmación', () {
      final json = {
        'mensaje': 'Contraseña restablecida exitosamente.',
      };
      final respuesta = RespuestaRestablecerPassword.fromJson(json);

      expect(respuesta.mensaje, equals('Contraseña restablecida exitosamente.'));
    });
  });

  group('CU04 - AuthService Endpoints & API Integration', () {
    late MockApiClient mockApi;
    late AuthService authService;

    setUp(() {
      mockApi = MockApiClient();
      authService = AuthService(api: mockApi);
    });

    test('solicitarRecuperacionPassword llama a POST /api/auth/recuperar-password', () async {
      mockApi.mockResponse = {
        'mensaje': 'Correo de recuperación enviado.',
      };

      final respuesta = await authService.solicitarRecuperacionPassword('cliente@fashionstore.com');

      expect(mockApi.lastPath, equals('/api/auth/recuperar-password'));
      expect(mockApi.lastBody, isA<Map<String, dynamic>>());
      final body = mockApi.lastBody as Map<String, dynamic>;
      expect(body['correo'], equals('cliente@fashionstore.com'));
      expect(respuesta.mensaje, equals('Correo de recuperación enviado.'));
    });

    test('verificarTokenRecuperacion llama a POST /api/auth/verificar-token-recuperacion', () async {
      mockApi.mockResponse = {
        'valido': true,
        'correo': 'cl***@fashionstore.com',
      };

      final respuesta = await authService.verificarTokenRecuperacion('token_valido_7788');

      expect(mockApi.lastPath, equals('/api/auth/verificar-token-recuperacion'));
      final body = mockApi.lastBody as Map<String, dynamic>;
      expect(body['token'], equals('token_valido_7788'));
      expect(respuesta.valido, isTrue);
      expect(respuesta.correo, equals('cl***@fashionstore.com'));
    });

    test('restablecerPassword llama a POST /api/auth/restablecer-password', () async {
      mockApi.mockResponse = {
        'mensaje': 'Contraseña restablecida exitosamente.',
      };

      final respuesta = await authService.restablecerPassword(
        'token_para_cambio',
        'NuevaClave2026#',
      );

      expect(mockApi.lastPath, equals('/api/auth/restablecer-password'));
      final body = mockApi.lastBody as Map<String, dynamic>;
      expect(body['token'], equals('token_para_cambio'));
      expect(body['nueva_password'], equals('NuevaClave2026#'));
      expect(respuesta.mensaje, equals('Contraseña restablecida exitosamente.'));
    });

    test('solicitarRecuperacionPassword propaga ApiException en error 400/404', () async {
      mockApi.throwStatusCode = 400;
      mockApi.throwMessage = 'Formato de correo no válido';

      expect(
        () => authService.solicitarRecuperacionPassword('correo_invalido'),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          400,
        )),
      );
    });

    test('restablecerPassword propaga ApiException si token expiró (401)', () async {
      mockApi.throwStatusCode = 401;
      mockApi.throwMessage = 'Token expirado o no encontrado';

      expect(
        () => authService.restablecerPassword('token_expirado', 'Clave123'),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          401,
        )),
      );
    });
  });

  group('CU04 - Validation Logic Tests', () {
    test('Validación de formato de correo', () {
      String? validarCorreo(String? val) {
        final v = val?.trim() ?? '';
        if (v.isEmpty) return 'Ingrese su correo electrónico.';
        if (!v.contains('@')) return 'Ingrese un correo válido.';
        return null;
      }

      expect(validarCorreo(''), equals('Ingrese su correo electrónico.'));
      expect(validarCorreo('   '), equals('Ingrese su correo electrónico.'));
      expect(validarCorreo('sin_arroba'), equals('Ingrese un correo válido.'));
      expect(validarCorreo('admin@fashionstore.com'), isNull);
    });

    test('Validación de fortaleza y longitud de contraseña', () {
      String? validarPassword(String? val) {
        if (val == null || val.isEmpty) return 'Ingrese la nueva contraseña.';
        if (val.length < 6) return 'La contraseña debe tener al menos 6 caracteres.';
        return null;
      }

      expect(validarPassword(null), equals('Ingrese la nueva contraseña.'));
      expect(validarPassword(''), equals('Ingrese la nueva contraseña.'));
      expect(validarPassword('12345'), equals('La contraseña debe tener al menos 6 caracteres.'));
      expect(validarPassword('123456'), isNull);
      expect(validarPassword('MiPasswordRobusta2026!'), isNull);
    });

    test('Validación de coincidencia de confirmación de contraseña', () {
      String? validarConfirmacion(String? pass, String? confirm) {
        if (confirm == null || confirm.isEmpty) return 'Confirme la nueva contraseña.';
        if (confirm != pass) return 'Las contraseñas no coinciden.';
        return null;
      }

      expect(validarConfirmacion('clave123', ''), equals('Confirme la nueva contraseña.'));
      expect(validarConfirmacion('clave123', 'clave456'), equals('Las contraseñas no coinciden.'));
      expect(validarConfirmacion('clave123', 'clave123'), isNull);
    });
  });

  group('CU04 - UI Widget Navigation & Form Rendering', () {
    testWidgets('LoginScreen muestra botón de recuperación de contraseña', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      expect(find.text('¿Olvidó su contraseña?'), findsOneWidget);
    });

    testWidgets('RecuperarPasswordScreen renderiza formulario de correo y botones', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RecuperarPasswordScreen(),
        ),
      );

      expect(find.text('Recuperar Contraseña'), findsOneWidget);
      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('ENVIAR ENLACE DE RECUPERACIÓN'), findsOneWidget);
      expect(find.text('¿Ya tiene un código o token? Ingrese aquí'), findsOneWidget);
    });

    testWidgets('NuevaPasswordScreen renderiza campos de token, clave y confirmación', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NuevaPasswordScreen(initialToken: 'token_prueba_123'),
        ),
      );

      expect(find.text('Nueva Contraseña'), findsNWidgets(2));
      expect(find.text('Token o código de recuperación'), findsOneWidget);
      expect(find.text('token_prueba_123'), findsOneWidget);
      expect(find.text('Confirmar Contraseña'), findsOneWidget);
      expect(find.text('CAMBIAR CONTRASEÑA'), findsOneWidget);
    });
  });
}
