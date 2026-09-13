import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fashionstore_mobile/core/api_client.dart';
import 'package:fashionstore_mobile/features/catalogo/catalogo_screen.dart';
import 'package:fashionstore_mobile/features/compras/compra_detalle_screen.dart';
import 'package:fashionstore_mobile/features/compras/compras_screen.dart';
import 'package:fashionstore_mobile/features/compras/models/compra_models.dart';
import 'package:fashionstore_mobile/features/movimientos/models/movimiento_models.dart';
import 'package:fashionstore_mobile/features/movimientos/movimientos_screen.dart';
import 'package:fashionstore_mobile/features/movimientos/registrar_movimiento_screen.dart';
import 'package:fashionstore_mobile/features/proveedores/models/proveedor_models.dart';
import 'package:fashionstore_mobile/features/proveedores/proveedores_screen.dart';
import 'package:fashionstore_mobile/services/auth_service.dart';
import 'package:fashionstore_mobile/services/compra_service.dart';
import 'package:fashionstore_mobile/services/movimiento_service.dart';
import 'package:fashionstore_mobile/services/proveedor_service.dart';

/// Cliente simulado para validar llamadas HTTP sin red externa
class MockApiClient extends ApiClient {
  String? lastGetPath;
  Map<String, String>? lastGetQuery;
  String? lastPostPath;
  Object? lastPostBody;

  dynamic mockGetResponse;
  dynamic mockPostResponse;

  int? throwStatusCode;
  String? throwMessage;

  final Map<String, dynamic> pathResponses = {};

  MockApiClient() : super(baseUrl: 'http://test-server:8000');

  @override
  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    lastGetPath = path;
    lastGetQuery = query;
    if (pathResponses.containsKey(path)) {
      return pathResponses[path];
    }
    if (throwStatusCode != null) {
      throw ApiException(throwStatusCode!, throwMessage ?? 'Error simulado');
    }
    return mockGetResponse;
  }

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

void main() {
  group('CU12 - Proveedores Serialization & Service Integration', () {
    test('Proveedor serializa y deserializa correctamente desde JSON', () {
      final json = {
        'id_proveedor': 10,
        'nit': '1029384756',
        'razon_social': 'Textiles Andinos S.R.L.',
        'contacto': 'Carlos Mamani',
        'telefono': '+591 71234567',
        'correo': 'ventas@textilesandinos.bo',
        'direccion': 'Av. Industrial #450, El Alto',
        'created_at': '2026-09-01T10:30:00.000Z',
      };

      final p = Proveedor.fromJson(json);
      expect(p.idProveedor, equals(10));
      expect(p.nit, equals('1029384756'));
      expect(p.razonSocial, equals('Textiles Andinos S.R.L.'));
      expect(p.contacto, equals('Carlos Mamani'));
      expect(p.telefono, equals('+591 71234567'));
      expect(p.correo, equals('ventas@textilesandinos.bo'));
      expect(p.direccion, contains('Av. Industrial'));
      expect(p.createdAt, isNotNull);

      final serializado = p.toJson();
      expect(serializado['id_proveedor'], equals(10));
      expect(serializado['nit'], equals('1029384756'));
    });

    test('Proveedor maneja valores nulos opcionales sin fallar', () {
      final json = {
        'id_proveedor': 11,
        'nit': '987654321',
        'razon_social': 'Confecciones del Valle',
      };

      final p = Proveedor.fromJson(json);
      expect(p.idProveedor, equals(11));
      expect(p.contacto, isNull);
      expect(p.telefono, isNull);
      expect(p.correo, isNull);
      expect(p.direccion, isNull);
      expect(p.createdAt, isNull);
    });

    test('ProveedorService.listar envía parámetros de búsqueda y paginación', () async {
      final mock = MockApiClient();
      mock.mockGetResponse = [
        {
          'id_proveedor': 1,
          'nit': '12345',
          'razon_social': 'Proveedor Test',
        }
      ];

      final servicio = ProveedorService(api: mock);
      final resultado = await servicio.listar(busqueda: 'Textiles', skip: 10, limit: 25);

      expect(mock.lastGetPath, equals('/api/proveedores/'));
      expect(mock.lastGetQuery?['busqueda'], equals('Textiles'));
      expect(mock.lastGetQuery?['skip'], equals('10'));
      expect(mock.lastGetQuery?['limit'], equals('25'));
      expect(resultado.length, equals(1));
      expect(resultado.first.razonSocial, equals('Proveedor Test'));
    });

    test('ProveedorService.obtener consulta por ID y propaga ApiException', () async {
      final mock = MockApiClient();
      mock.throwStatusCode = 404;
      mock.throwMessage = 'El proveedor solicitado no existe';

      final servicio = ProveedorService(api: mock);
      expect(
        () => servicio.obtener(999),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('no existe'))),
      );
    });
  });

  group('CU11 - Movimientos Serialization & Service Integration', () {
    test('MovimientoInventario y MovimientoCrear serializan correctamente', () {
      const crear = MovimientoCrear(
        idSucursal: 2,
        idVariantePrenda: 15,
        tipo: 'Entrada',
        cantidad: 50,
        motivo: 'Ajuste de inventario físico inicial',
      );

      final jsonCrear = crear.toJson();
      expect(jsonCrear['id_sucursal'], equals(2));
      expect(jsonCrear['id_variante_prenda'], equals(15));
      expect(jsonCrear['tipo'], equals('Entrada'));
      expect(jsonCrear['cantidad'], equals(50));
      expect(jsonCrear['motivo'], contains('Ajuste'));

      final jsonRespuesta = {
        'id_movimiento': 101,
        'id_sucursal': 2,
        'sucursal_nombre': 'Sucursal Central',
        'id_variante_prenda': 15,
        'sku_variante': 'VAR-CAM-01',
        'prenda_nombre': 'Camisa Lino',
        'talla': 'M',
        'color': 'Blanco',
        'tipo': 'Entrada',
        'cantidad': 50,
        'motivo': 'Ajuste inicial',
        'id_usuario': 1,
        'usuario_nombre': 'Admin User',
        'fecha': '2026-09-02T14:00:00Z',
        'stock_actual': 85,
      };

      final m = MovimientoInventario.fromJson(jsonRespuesta);
      expect(m.idMovimiento, equals(101));
      expect(m.sucursalNombre, equals('Sucursal Central'));
      expect(m.prendaNombre, equals('Camisa Lino'));
      expect(m.talla, equals('M'));
      expect(m.stockActual, equals(85));
    });

    test('MovimientoService.consultarStock y registrar ejecutan rutas correctas', () async {
      final mock = MockApiClient();
      mock.mockGetResponse = {
        'id_sucursal': 1,
        'id_variante_prenda': 5,
        'stock': 42,
      };

      final servicio = MovimientoService(api: mock);
      final stock = await servicio.consultarStock(idSucursal: 1, idVariantePrenda: 5);
      expect(stock, equals(42));
      expect(mock.lastGetPath, equals('/api/movimientos-inventario/stock'));
      expect(mock.lastGetQuery?['id_sucursal'], equals('1'));
      expect(mock.lastGetQuery?['id_variante_prenda'], equals('5'));

      mock.mockPostResponse = {
        'id_movimiento': 200,
        'id_sucursal': 1,
        'id_variante_prenda': 5,
        'tipo': 'Salida',
        'cantidad': 10,
        'motivo': 'Venta presencial',
        'fecha': '2026-09-03T10:00:00Z',
      };

      final mov = await servicio.registrar(
        const MovimientoCrear(
          idSucursal: 1,
          idVariantePrenda: 5,
          tipo: 'Salida',
          cantidad: 10,
          motivo: 'Venta presencial',
        ),
      );

      expect(mov.idMovimiento, equals(200));
      expect(mock.lastPostPath, equals('/api/movimientos-inventario/'));
    });
  });

  group('CU13 - Compras Serialization & 13% IVA Rule', () {
    test('Compra calcula o deserializa subtotal e IVA 13% correctamente', () {
      final json = {
        'id_compra': 50,
        'id_proveedor': 3,
        'proveedor_razon_social': 'Modas del Sur S.A.',
        'id_sucursal': 1,
        'sucursal_nombre': 'Sucursal Equipetrol',
        'fecha': '2026-09-04T12:00:00Z',
        'subtotal': 1000.0,
        'iva': 130.0,
        'total': 1130.0,
        'id_usuario': 2,
        'usuario_nombre': 'Encargado Almacén',
        'total_items': 2,
        'items': [
          {
            'id_variante_prenda': 10,
            'sku_variante': 'PANT-01',
            'prenda_nombre': 'Pantalón Denim',
            'talla': '32',
            'color': 'Azul',
            'cantidad': 10,
            'costo_unitario': 50.0,
            'subtotal_item': 500.0,
          },
          {
            'id_variante_prenda': 12,
            'sku_variante': 'PANT-02',
            'prenda_nombre': 'Pantalón Denim',
            'talla': '34',
            'color': 'Negro',
            'cantidad': 10,
            'costo_unitario': 50.0,
            'subtotal_item': 500.0,
          }
        ]
      };

      final c = Compra.fromJson(json);
      expect(c.idCompra, equals(50));
      expect(c.subtotal, equals(1000.0));
      expect(c.iva, equals(130.0));
      expect(c.total, equals(1130.0));
      expect(c.items.length, equals(2));
      expect(c.items.first.prendaNombre, equals('Pantalón Denim'));
      expect(c.items.first.subtotalItem, equals(500.0));
    });

    test('Compra deduce subtotal e IVA si el backend envía solo el total', () {
      final json = {
        'id_compra': 51,
        'id_proveedor': 3,
        'id_sucursal': 1,
        'fecha': '2026-09-04T12:00:00Z',
        'total': 1130.0,
      };

      final c = Compra.fromJson(json);
      expect(c.total, equals(1130.0));
      expect(c.subtotal, closeTo(1000.0, 0.01));
      expect(c.iva, closeTo(130.0, 0.01));
    });
  });

  group('UI Widget Tests - CU12 Directorio de Proveedores', () {
    testWidgets('ProveedoresScreen renderiza buscador y lista de proveedores con NIT', (tester) async {
      final mock = MockApiClient();
      mock.mockGetResponse = [
        {
          'id_proveedor': 1,
          'nit': '1029384756',
          'razon_social': 'Textiles Andinos S.R.L.',
          'contacto': 'Carlos Mamani',
          'telefono': '71234567',
          'correo': 'contacto@andinos.bo',
          'direccion': 'Av. Blanco Galindo',
        },
      ];

      final servicio = ProveedorService(api: mock);

      await tester.pumpWidget(
        MaterialApp(
          home: ProveedoresScreen(servicio: servicio),
        ),
      );

      // Progreso inicial
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Directorio de Proveedores'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Textiles Andinos S.R.L.'), findsOneWidget);
      expect(find.text('NIT 1029384756'), findsOneWidget);
      expect(find.text('Carlos Mamani'), findsOneWidget);

      // Tocar la tarjeta para abrir el BottomSheet de detalle
      await tester.tap(find.text('Textiles Andinos S.R.L.'));
      await tester.pumpAndSettle();

      expect(find.text('NIT: 1029384756'), findsOneWidget);
      expect(find.text('Av. Blanco Galindo'), findsWidgets);
      expect(find.text('Cerrar'), findsOneWidget);
    });
  });

  group('UI Widget Tests - CU11 Movimientos de Inventario', () {
    testWidgets('MovimientosScreen renderiza chips de filtro y tarjetas de movimientos', (tester) async {
      final mock = MockApiClient();
      mock.mockGetResponse = [
        {
          'id_movimiento': 1,
          'id_sucursal': 1,
          'sucursal_nombre': 'Central',
          'id_variante_prenda': 10,
          'sku_variante': 'SKU-01',
          'prenda_nombre': 'Vestido Seda',
          'talla': 'S',
          'color': 'Rojo',
          'tipo': 'Entrada',
          'cantidad': 30,
          'motivo': 'Recepción inicial',
          'fecha': '2026-09-05T09:00:00Z',
        },
      ];

      final servicio = MovimientoService(api: mock);

      await tester.pumpWidget(
        MaterialApp(
          home: MovimientosScreen(servicio: servicio),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Movimientos de Inventario'), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Entrada'), findsWidgets);
      expect(find.text('Salida'), findsOneWidget);
      expect(find.text('Traspaso'), findsOneWidget);
      expect(find.text('Vestido Seda'), findsOneWidget);
      expect(find.text('+30 uds.'), findsOneWidget);
      expect(find.text('Nuevo Movimiento'), findsOneWidget);
    });

    testWidgets('RegistrarMovimientoScreen valida campos obligatorios y cantidad > 0', (tester) async {
      final mock = MockApiClient();
      // Simulamos respuesta de sucursales y catálogo para selectores
      mock.mockGetResponse = [];

      final servicio = MovimientoService(api: mock);

      await tester.pumpWidget(
        MaterialApp(
          home: RegistrarMovimientoScreen(servicio: servicio),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Registrar Movimiento'), findsOneWidget);
      expect(find.text('CONFIRMAR MOVIMIENTO'), findsOneWidget);

      // Presionar confirmar sin llenar datos activa validaciones del formulario
      await tester.tap(find.text('CONFIRMAR MOVIMIENTO'));
      await tester.pumpAndSettle();

      expect(find.text('Ingrese la cantidad.'), findsOneWidget);
      expect(find.text('Ingrese el motivo.'), findsOneWidget);
    });
  });

  group('UI Widget Tests - CU13 Compras & Detalle', () {
    testWidgets('ComprasScreen lista lotes y abre CompraDetalleScreen con desglose de IVA', (tester) async {
      final mock = MockApiClient();
      mock.mockGetResponse = [
        {
          'id_compra': 77,
          'id_proveedor': 5,
          'proveedor_razon_social': 'Tejidos La Paz',
          'id_sucursal': 2,
          'sucursal_nombre': 'Sucursal Norte',
          'fecha': '2026-09-06T15:30:00Z',
          'total': 2260.0,
          'total_items': 1,
          'items': [
            {
              'id_variante_prenda': 20,
              'sku_variante': 'SACO-01',
              'prenda_nombre': 'Saco Lana',
              'talla': 'L',
              'color': 'Gris',
              'cantidad': 20,
              'costo_unitario': 100.0,
              'subtotal_item': 2000.0,
            }
          ]
        },
      ];

      final servicio = CompraService(api: mock);

      await tester.pumpWidget(
        MaterialApp(
          home: ComprasScreen(servicio: servicio),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Recepción de Compras / Lotes'), findsOneWidget);
      expect(find.text('COMPRA #77'), findsOneWidget);
      expect(find.text('Tejidos La Paz'), findsOneWidget);
      expect(find.text('Bs 2260.00'), findsOneWidget);
      expect(find.text('IVA 13% incluido'), findsOneWidget);

      // Abrir detalle directamente
      mock.mockGetResponse = (mock.mockGetResponse as List).first;
      await tester.pumpWidget(
        MaterialApp(
          home: CompraDetalleScreen(idCompra: 77, servicio: servicio),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Compra #77'), findsOneWidget);
      expect(find.text('LOTE INGRESADO #77'), findsOneWidget);
      expect(find.text('Saco Lana'), findsOneWidget);
      expect(find.text('TOTAL FACTURADO:'), findsOneWidget);
    });
  });

  group('UI Widget Tests - Navigation Drawer en CatalogoScreen', () {
    testWidgets('CatalogoScreen despliega Drawer con opciones de almacén si autenticado', (tester) async {
      final auth = AuthService.instance;
      auth.logout();

      await tester.pumpWidget(
        const MaterialApp(
          home: CatalogoScreen(),
        ),
      );

      await tester.pump();

      // Abrir drawer abriendo el Scaffold
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Como invitado
      expect(find.text('Modo Invitado'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Catálogo de Prendas'), findsOneWidget);
      expect(find.text('GESTIÓN DE ALMACÉN'), findsNothing);
    });

    testWidgets('CatalogoScreen con personal autenticado muestra opciones de almacén en Drawer', (tester) async {
      final mock = MockApiClient();
      // Generamos un JWT simulado: header.payload.signature
      // Payload con { id_usuario: 1, correo: "almacen@fashionstore.com", nombre: "Juan Almacenero", rol: "Encargado de Sucursal" }
      // eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZF91c3VhcmlvIjoxLCJjb3JyZW8iOiJhbG1hY2VuQGZhc2hpb25zdG9yZS5jb20iLCJub21icmUiOiJKdWFuIEFsbWFjZW5lcm8iLCJyb2wiOiJFbmNhcmdhZG8gZGUgU3VjdXJzYWwifQ.test
      mock.mockPostResponse = {
        'access_token':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZF91c3VhcmlvIjoxLCJjb3JyZW8iOiJhbG1hY2VuQGZhc2hpb25zdG9yZS5jb20iLCJub21icmUiOiJKdWFuIEFsbWFjZW5lcm8iLCJyb2wiOiJFbmNhcmdhZG8gZGUgU3VjdXJzYWwifQ.signature',
        'token_type': 'bearer',
      };

      final auth = AuthService.instance;
      auth.api = mock;
      await auth.login('almacen@fashionstore.com', 'Clave123!');
      expect(auth.autenticado, isTrue);
      expect(auth.rol, equals('Encargado de Sucursal'));
      expect(auth.nombreUsuario, equals('Juan Almacenero'));
      expect(auth.esPersonalAlmacen, isTrue);

      await tester.pumpWidget(
        const MaterialApp(
          home: CatalogoScreen(),
        ),
      );

      await tester.pump();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Juan Almacenero'), findsOneWidget);
      expect(find.text('ENCARGADO DE SUCURSAL'), findsOneWidget);
      expect(find.text('GESTIÓN DE ALMACÉN'), findsOneWidget);
      expect(find.text('Movimientos de Inventario'), findsOneWidget);
      expect(find.text('Directorio de Proveedores'), findsOneWidget);
      expect(find.text('Recepción de Compras'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.widgetWithText(ListTile, 'Cerrar sesión'),
        100,
        scrollable: find.descendant(of: find.byType(Drawer), matching: find.byType(Scrollable)),
      );
      expect(find.text('Cerrar sesión'), findsOneWidget);

      auth.logout();
    });
  });

  group('CU11 - Stock Exception and Validation Alerts', () {
    testWidgets('RegistrarMovimientoScreen captura ApiException de stock insuficiente y despliega banner', (tester) async {
      final mock = MockApiClient();
      mock.pathResponses['/api/sucursales'] = [
        {'id_sucursal': 1, 'nombre': 'Sucursal Central'}
      ];
      mock.pathResponses['/api/catalogo/'] = {
        'prendas': [
          {
            'id_prenda': 1,
            'sku': 'SKU-001',
            'nombre': 'Camisa Blanca',
            'variantes': [
              {
                'id_variante_prenda': 10,
                'talla': 'M',
                'color': 'Blanco',
              }
            ]
          }
        ]
      };
      mock.pathResponses['/api/movimientos-inventario/stock'] = {
        'id_sucursal': 1,
        'id_variante_prenda': 10,
        'stock': 50,
      };
      mock.throwStatusCode = 400;
      mock.throwMessage = 'Stock insuficiente en la sucursal para realizar este movimiento.';

      final servicio = MovimientoService(api: mock);

      await tester.pumpWidget(
        MaterialApp(
          home: RegistrarMovimientoScreen(servicio: servicio),
        ),
      );

      await tester.pumpAndSettle();

      // Ingresar cantidad y motivo válidos
      await tester.enterText(find.widgetWithText(TextFormField, 'Cantidad de unidades'), '999');
      await tester.enterText(find.widgetWithText(TextFormField, 'Motivo o justificación'), 'Ajuste forzado');
      await tester.pump();

      // Desplazarse hasta el botón si está fuera de pantalla
      await tester.ensureVisible(find.text('CONFIRMAR MOVIMIENTO'));
      await tester.pumpAndSettle();

      // Al pulsar confirmar, el backend simulado lanza 400 por trigger
      await tester.tap(find.text('CONFIRMAR MOVIMIENTO'));
      await tester.pumpAndSettle();

      expect(find.text('Excepción de inventario'), findsOneWidget);
      expect(find.text('Stock insuficiente en la sucursal para realizar este movimiento.'), findsOneWidget);
    });
  });
}
