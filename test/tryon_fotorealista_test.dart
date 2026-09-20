import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fashionstore_mobile/core/api_client.dart';
import 'package:fashionstore_mobile/core/models/catalogo_models.dart';
import 'package:fashionstore_mobile/features/detalle/prenda_detalle_screen.dart';
import 'package:fashionstore_mobile/features/ia/models/tryon_model.dart';
import 'package:fashionstore_mobile/features/ia/services/ia_service.dart';

/// 1x1 transparent PNG bytes for safe image rendering in widget tests
final Uint8List kTestImageBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

const String kTestImageDataUri =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

/// Mock ApiClient para pruebas del servicio de IA
class MockApiClient extends ApiClient {
  String? lastPostPath;
  Object? lastPostBody;
  dynamic mockPostResponse;
  int? throwStatusCode;
  String? throwMessage;

  MockApiClient() : super(baseUrl: 'http://test-server:8000');

  @override
  Future<dynamic> post(String path, {Object? body}) async {
    lastPostPath = path;
    lastPostBody = body;
    if (throwStatusCode != null) {
      throw ApiException(throwStatusCode!, throwMessage ?? 'Error simulado');
    }
    return mockPostResponse;
  }
}

/// Mock ImagePicker para simular cámara y galería
class MockImagePicker extends ImagePicker {
  XFile? mockFile;
  ImageSource? lastSource;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    lastSource = source;
    return mockFile;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Prenda de prueba
  const prendaTest = PrendaCatalogo(
    idPrenda: 10,
    sku: 'PRD-CHAQ-001',
    nombre: 'Chaqueta de Cuero Oxford',
    descripcion: 'Chaqueta de cuero genuino con forro térmico y corte entallado.',
    precioBase: 450.0,
    marca: 'FashionStore Couture',
    categoria: 'Abrigos',
    genero: 'Unisex',
    urlImagen: 'https://example.com/prenda.png',
    stockTotal: 5,
    variantes: [
      VarianteCatalogo(
        idVariantePrenda: 101,
        idTalla: 1,
        talla: 'M',
        idColor: 1,
        color: 'Negro',
        precio: 450.0,
        stockTotal: 5,
        disponibilidad: [
          StockSucursal(
            idSucursal: 1,
            sucursal: 'Sucursal Central',
            ciudad: 'La Paz',
            stock: 3,
          ),
        ],
      ),
    ],
  );

  group('Try-On Models & Serialization', () {
    test('TryOnPeticion serializa correctamente a JSON con todos los parámetros', () {
      const peticion = TryOnPeticion(
        idPrenda: 15,
        fotoUsuario: kTestImageDataUri,
        urlPrenda: 'https://example.com/item.png',
        usarIaGenerativa: true,
        ajusteHolgura: 1.1,
        idVariantePrenda: 25,
      );

      final json = peticion.toJson();
      expect(json['id_prenda'], 15);
      expect(json['foto_usuario'], kTestImageDataUri);
      expect(json['url_prenda'], 'https://example.com/item.png');
      expect(json['usar_ia_generativa'], isTrue);
      expect(json['ajuste_holgura'], 1.1);
      expect(json['id_variante_prenda'], 25);
    });

    test('TryOnPeticion omite campos opcionales nulos en JSON', () {
      const peticion = TryOnPeticion(
        fotoUsuario: kTestImageDataUri,
      );

      final json = peticion.toJson();
      expect(json['foto_usuario'], kTestImageDataUri);
      expect(json.containsKey('id_prenda'), isFalse);
      expect(json.containsKey('url_prenda'), isFalse);
      expect(json.containsKey('id_variante_prenda'), isFalse);
      expect(json['usar_ia_generativa'], isTrue);
      expect(json['ajuste_holgura'], 1.0);
    });

    test('MetadatosCalce deserializa y serializa correctamente', () {
      final json = {
        'metodo': 'gemini_vision',
        'anclaje_torso': {'hombro_izq': [100, 200], 'hombro_der': [250, 200]},
        'ajuste_luz': {'delta_v': 12, 'delta_s': -5},
        'prenda_id': 10,
        'es_fallback': false,
        'tiempo_procesamiento_ms': 1420.5,
      };

      final metadatos = MetadatosCalce.fromJson(json);
      expect(metadatos.metodo, 'gemini_vision');
      expect(metadatos.prendaId, 10);
      expect(metadatos.esFallback, isFalse);
      expect(metadatos.tiempoProcesamientoMs, 1420.5);
      expect(metadatos.anclajeTorso['hombro_izq'], [100, 200]);

      final backToJson = metadatos.toJson();
      expect(backToJson['metodo'], 'gemini_vision');
      expect(backToJson['prenda_id'], 10);
      expect(backToJson['tiempo_procesamiento_ms'], 1420.5);
    });

    test('TryOnRespuesta deserializa respuesta exitosa del backend FastAPI', () {
      final json = {
        'estado': 'exito',
        'imagen_resultado': kTestImageDataUri,
        'tiempo_procesamiento_ms': 1850.0,
        'mensaje': 'Composición generativa exitosa',
        'es_generativo': true,
        'metadatos_calce': {
          'metodo': 'gemini_vision',
          'anclaje_torso': {},
          'ajuste_luz': {},
          'prenda_id': 10,
          'es_fallback': false,
          'tiempo_procesamiento_ms': 1850.0,
        },
      };

      final respuesta = TryOnRespuesta.fromJson(json);
      expect(respuesta.estado, 'exito');
      expect(respuesta.imagenResultado, kTestImageDataUri);
      expect(respuesta.tiempoProcesamientoMs, 1850.0);
      expect(respuesta.mensaje, 'Composición generativa exitosa');
      expect(respuesta.esGenerativo, isTrue);
      expect(respuesta.metadatosCalce, isNotNull);
      expect(respuesta.metadatosCalce!.metodo, 'gemini_vision');
    });

    test('TryOnRespuesta maneja valores por defecto si backend omite campos', () {
      final json = {
        'imagen_resultado': kTestImageDataUri,
        'tiempo_procesamiento_ms': 950,
      };

      final respuesta = TryOnRespuesta.fromJson(json);
      expect(respuesta.estado, 'exito');
      expect(respuesta.imagenResultado, kTestImageDataUri);
      expect(respuesta.tiempoProcesamientoMs, 950.0);
      expect(respuesta.metadatosCalce, isNull);
      expect(respuesta.mensaje, 'Composición completada exitosamente');
      expect(respuesta.esGenerativo, isFalse);
    });
  });

  group('IAService Try-On Integration', () {
    late MockApiClient mockApi;
    late IAService iaService;

    setUp(() {
      mockApi = MockApiClient();
      iaService = IAService(api: mockApi);
    });

    test('generarTryOn invoca POST /api/ia/try-on y retorna TryOnRespuesta', () async {
      mockApi.mockPostResponse = {
        'estado': 'exito',
        'imagen_resultado': kTestImageDataUri,
        'tiempo_procesamiento_ms': 1230.5,
        'mensaje': 'Ajuste completado',
        'es_generativo': true,
        'metadatos_calce': {
          'metodo': 'hibrido',
          'tiempo_procesamiento_ms': 1230.5,
        },
      };

      const peticion = TryOnPeticion(
        idPrenda: 10,
        fotoUsuario: kTestImageDataUri,
        usarIaGenerativa: true,
      );

      final resultado = await iaService.generarTryOn(peticion);

      expect(mockApi.lastPostPath, '/api/ia/try-on');
      expect(mockApi.lastPostBody, isA<Map<String, dynamic>>());
      final bodyMap = mockApi.lastPostBody as Map<String, dynamic>;
      expect(bodyMap['id_prenda'], 10);
      expect(bodyMap['usar_ia_generativa'], isTrue);

      expect(resultado.estado, 'exito');
      expect(resultado.imagenResultado, kTestImageDataUri);
      expect(resultado.tiempoProcesamientoMs, 1230.5);
      expect(resultado.mensaje, 'Ajuste completado');
    });

    test('generarTryOn propaga ApiException en caso de error HTTP del backend', () async {
      mockApi.throwStatusCode = 400;
      mockApi.throwMessage = 'No se detectaron hombros en la fotografía';

      const peticion = TryOnPeticion(
        idPrenda: 10,
        fotoUsuario: kTestImageDataUri,
      );

      expect(
        () => iaService.generarTryOn(peticion),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('No se detectaron hombros'),
          ),
        ),
      );
    });

    test('generarTryOn lanza FormatException si la respuesta no es un Map', () async {
      mockApi.mockPostResponse = 'Respuesta invalida en texto plano';

      const peticion = TryOnPeticion(
        idPrenda: 10,
        fotoUsuario: kTestImageDataUri,
      );

      expect(
        () => iaService.generarTryOn(peticion),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('UI Widget Tests: Try-On en PrendaDetalleScreen', () {
    testWidgets('PrendaDetalleScreen renderiza el botón "Generar Try-On Fotorealista (IA)"',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FilledButton.icon(
                key: const Key('btn_tryon_fotorealista'),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generar Try-On Fotorealista (IA)'),
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('btn_tryon_fotorealista')), findsOneWidget);
      expect(find.text('Generar Try-On Fotorealista (IA)'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('Selector de origen de foto muestra opciones de Cámara y Galería',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  child: const Text('Abrir Selector'),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Probador Fotorealista (IA)'),
                          ListTile(
                            key: const Key('tile_origen_camara'),
                            title: const Text('Tomar fotografía'),
                            onTap: () => Navigator.pop(ctx),
                          ),
                          ListTile(
                            key: const Key('tile_origen_galeria'),
                            title: const Text('Elegir de la galería'),
                            onTap: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Selector'));
      await tester.pumpAndSettle();

      expect(find.text('Probador Fotorealista (IA)'), findsOneWidget);
      expect(find.byKey(const Key('tile_origen_camara')), findsOneWidget);
      expect(find.byKey(const Key('tile_origen_galeria')), findsOneWidget);
      expect(find.text('Tomar fotografía'), findsOneWidget);
      expect(find.text('Elegir de la galería'), findsOneWidget);

      await tester.tap(find.byKey(const Key('tile_origen_camara')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tile_origen_camara')), findsNothing);
    });
  });

  group('UI Widget Tests: DialogoProgresoTryOn', () {
    testWidgets('DialogoProgresoTryOn renderiza indicador y etapas de procesamiento',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DialogoProgresoTryOn(),
          ),
        ),
      );

      expect(find.text('Vestidor Fotorealista con IA'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Detectando silueta...'), findsOneWidget);

      // Avanza el temporizador de fases
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text('Adaptando tejido y caída...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text('Componiendo sombras realistas...'), findsOneWidget);
    });
  });

  group('UI Widget Tests: TryOnVisorModal', () {
    testWidgets('TryOnVisorModal renderiza InteractiveViewer, badges y acciones',
        (tester) async {
      bool reservaClickeada = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TryOnVisorModal(
              imagenBytes: kTestImageBytes,
              fotoOriginalBytes: kTestImageBytes,
              prenda: prendaTest,
              tiempoMs: 1650.0,
              mensaje: 'Calce anatómico óptimo',
              onReservar: () {
                reservaClickeada = true;
              },
            ),
          ),
        ),
      );

      // Verifica título y mensaje
      expect(find.text('Chaqueta de Cuero Oxford'), findsOneWidget);
      expect(find.text('Calce anatómico óptimo'), findsOneWidget);

      // Verifica InteractiveViewer nativo
      expect(find.byType(InteractiveViewer), findsOneWidget);

      // Verifica badge de telemetría de procesamiento
      expect(find.text('IA Generativa: 1.65s'), findsOneWidget);
      expect(find.byIcon(Icons.bolt), findsOneWidget);

      // Verifica botones de control
      expect(find.byKey(const Key('btn_toggle_vista')), findsOneWidget);
      expect(find.byKey(const Key('btn_vista_lado_a_lado')), findsOneWidget);
      expect(find.byKey(const Key('btn_reset_zoom')), findsOneWidget);
      expect(find.byKey(const Key('btn_cerrar_visor')), findsOneWidget);
      expect(find.byKey(const Key('btn_reservar_desde_tryon')), findsOneWidget);

      // Alterna vista a foto original
      await tester.tap(find.byKey(const Key('btn_toggle_vista')));
      await tester.pump();
      expect(find.text('Original'), findsOneWidget);

      // Alterna de vuelta a Try-On
      await tester.tap(find.byKey(const Key('btn_toggle_vista')));
      await tester.pump();
      expect(find.text('Try-On IA'), findsOneWidget);

      // Alterna a modo comparativa lado a lado
      await tester.tap(find.byKey(const Key('btn_vista_lado_a_lado')));
      await tester.pump();
      expect(find.text('Foto Original'), findsOneWidget);
      expect(find.text('Try-On Fotorealista (IA)'), findsOneWidget);
      // En lado a lado hay 2 InteractiveViewer (izq y der)
      expect(find.byType(InteractiveViewer), findsNWidgets(2));

      // Resetea zoom
      await tester.tap(find.byKey(const Key('btn_reset_zoom')));
      await tester.pump();

      // Pulsa botón de reservar en tienda (CU16)
      await tester.tap(find.byKey(const Key('btn_reservar_desde_tryon')));
      await tester.pumpAndSettle();
      expect(reservaClickeada, isTrue);
    });

    testWidgets('TryOnVisorModal funciona correctamente sin foto original previa',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TryOnVisorModal(
              imagenBytes: kTestImageBytes,
              fotoOriginalBytes: null,
              prenda: prendaTest,
              tiempoMs: 820.0,
            ),
          ),
        ),
      );

      // Si no hay foto original previa, no renderiza botones de toggle comparativo
      expect(find.byKey(const Key('btn_toggle_vista')), findsNothing);
      expect(find.byKey(const Key('btn_vista_lado_a_lado')), findsNothing);

      // Pero sí mantiene InteractiveViewer y botón de reserva
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byKey(const Key('btn_reservar_desde_tryon')), findsOneWidget);
    });
  });
}
