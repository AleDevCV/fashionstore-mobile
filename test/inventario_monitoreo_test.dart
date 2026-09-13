import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fashionstore_mobile/core/api_client.dart';
import 'package:fashionstore_mobile/core/theme.dart';
import 'package:fashionstore_mobile/features/catalogo/catalogo_screen.dart';
import 'package:fashionstore_mobile/features/inventario_monitoreo/estado_inventario_screen.dart';
import 'package:fashionstore_mobile/features/inventario_monitoreo/models/inventario_monitoreo_models.dart';
import 'package:fashionstore_mobile/services/auth_service.dart';
import 'package:fashionstore_mobile/services/inventario_monitoreo_service.dart';

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
  group('CU10 - Models & Serialization', () {
    test('ResumenInventario deserializa y maneja alias de compatibilidad', () {
      final json = {
        'total_stock_global': 120,
        'total_prendas_distintas': 15,
        'total_variantes': 28,
        'variantes_optimo': 18,
        'variantes_bajo_stock': 7,
        'variantes_agotadas': 3,
        'sucursales': [
          {
            'id_sucursal': 1,
            'nombre_sucursal': 'Sucursal Equipetrol',
            'ciudad': 'Santa Cruz',
            'total_stock': 65,
            'variantes_optimo': 10,
            'variantes_bajo': 4,
            'variantes_agotadas': 1,
          },
          {
            'id_sucursal': 2,
            'sucursal': 'Sucursal Centro',
            'ciudad': 'Santa Cruz',
            'total_stock': 55,
            'total_optimo': 8,
            'total_bajo': 3,
            'total_agotado': 2,
          }
        ]
      };

      final resumen = ResumenInventario.fromJson(json);
      expect(resumen.totalStock, equals(120));
      expect(resumen.totalPrendas, equals(15));
      expect(resumen.totalVariantes, equals(28));
      expect(resumen.totalOptimo, equals(18));
      expect(resumen.totalBajo, equals(7));
      expect(resumen.totalAgotado, equals(3));
      expect(resumen.sucursales.length, equals(2));

      final suc1 = resumen.sucursales[0];
      expect(suc1.idSucursal, equals(1));
      expect(suc1.sucursal, equals('Sucursal Equipetrol'));
      expect(suc1.ciudad, equals('Santa Cruz'));
      expect(suc1.totalStock, equals(65));
      expect(suc1.totalOptimo, equals(10));
      expect(suc1.totalBajo, equals(4));
      expect(suc1.totalAgotado, equals(1));

      final suc2 = resumen.sucursales[1];
      expect(suc2.idSucursal, equals(2));
      expect(suc2.sucursal, equals('Sucursal Centro'));
      expect(suc2.totalStock, equals(55));

      final serializado = resumen.toJson();
      expect(serializado['total_stock'], equals(120));
      expect(serializado['sucursales'], isA<List>());
    });

    test('MonitoreoItem deserializa fila y calcula estados de stock por defecto', () {
      final json = {
        'id_inventario': 42,
        'id_sucursal': 1,
        'nombre_sucursal': 'Sucursal Equipetrol',
        'ciudad': 'Santa Cruz',
        'id_prenda': 5,
        'sku_prenda': 'VES-PRI-001',
        'nombre_prenda': 'Vestido Seda Floral',
        'id_categoria': 2,
        'nombre_categoria': 'Vestidos',
        'id_temporada': 1,
        'nombre_temporada': 'Primavera 2026',
        'id_variante_prenda': 14,
        'sku_variante': 'VES-PRI-001-S-ROJ',
        'talla': 'S',
        'color': 'Rojo',
        'codigo_hex': '#FF0000',
        'precio': 250.0,
        'stock': 8,
      };

      final item = MonitoreoItem.fromJson(json);
      expect(item.idInventario, equals(42));
      expect(item.idSucursal, equals(1));
      expect(item.sucursal, equals('Sucursal Equipetrol'));
      expect(item.idPrenda, equals(5));
      expect(item.skuPrenda, equals('VES-PRI-001'));
      expect(item.nombrePrenda, equals('Vestido Seda Floral'));
      expect(item.idCategoria, equals(2));
      expect(item.categoria, equals('Vestidos'));
      expect(item.idTemporada, equals(1));
      expect(item.temporada, equals('Primavera 2026'));
      expect(item.idVariantePrenda, equals(14));
      expect(item.skuVariante, equals('VES-PRI-001-S-ROJ'));
      expect(item.talla, equals('S'));
      expect(item.color, equals('Rojo'));
      expect(item.codigoHex, equals('#FF0000'));
      expect(item.precio, equals(250.0));
      expect(item.stock, equals(8));
      expect(item.estadoStock, equals('Optimo'));
      expect(item.colorBadge, equals('verde'));
    });

    test('VarianteAgrupadaInventario.agrupar consolida existencias por variante', () {
      final items = [
        const MonitoreoItem(
          idSucursal: 1,
          sucursal: 'Sucursal Equipetrol',
          ciudad: 'Santa Cruz',
          idPrenda: 10,
          skuPrenda: 'CAM-LINO-001',
          nombrePrenda: 'Camisa Lino Premium',
          idVariantePrenda: 30,
          skuVariante: 'CAM-LINO-001-M-BLA',
          talla: 'M',
          color: 'Blanco',
          precio: 180.0,
          stock: 3,
          estadoStock: 'Bajo',
          colorBadge: 'amarillo',
        ),
        const MonitoreoItem(
          idSucursal: 2,
          sucursal: 'Sucursal Centro',
          ciudad: 'Santa Cruz',
          idPrenda: 10,
          skuPrenda: 'CAM-LINO-001',
          nombrePrenda: 'Camisa Lino Premium',
          idVariantePrenda: 30,
          skuVariante: 'CAM-LINO-001-M-BLA',
          talla: 'M',
          color: 'Blanco',
          precio: 180.0,
          stock: 4,
          estadoStock: 'Bajo',
          colorBadge: 'amarillo',
        ),
      ];

      final agrupadas = VarianteAgrupadaInventario.agrupar(items);
      expect(agrupadas.length, equals(1));

      final v = agrupadas.first;
      expect(v.idVariantePrenda, equals(30));
      expect(v.skuVariante, equals('CAM-LINO-001-M-BLA'));
      expect(v.nombrePrenda, equals('Camisa Lino Premium'));
      expect(v.stockTotal, equals(7)); // 3 + 4 = 7
      expect(v.estadoStock, equals('Optimo')); // >= 5 es Óptimo
      expect(v.desgloseSucursales.length, equals(2));
      expect(v.desgloseSucursales[0].nombreSucursal, equals('Sucursal Equipetrol'));
      expect(v.desgloseSucursales[0].stock, equals(3));
      expect(v.desgloseSucursales[1].nombreSucursal, equals('Sucursal Centro'));
      expect(v.desgloseSucursales[1].stock, equals(4));
    });

    test('BadgeStockStyle clasifica correctamente los 3 estados cromáticos', () {
      // Óptimo: >= 5 unidades
      final optimo = BadgeStockStyle.fromStock(5);
      expect(optimo.textColor, equals(fsEmerald));
      expect(optimo.label, equals('Óptimo'));

      final optimoMayor = BadgeStockStyle.fromStock(20);
      expect(optimoMayor.textColor, equals(fsEmerald));

      // Bajo: 1 a 4 unidades
      final bajo1 = BadgeStockStyle.fromStock(1);
      expect(bajo1.textColor, equals(const Color(0xFFB45309)));
      expect(bajo1.label, equals('Bajo Stock'));

      final bajo4 = BadgeStockStyle.fromStock(4);
      expect(bajo4.textColor, equals(const Color(0xFFB45309)));

      // Agotado: 0 unidades
      final agotado = BadgeStockStyle.fromStock(0);
      expect(agotado.textColor, equals(fsDanger));
      expect(agotado.label, equals('Agotado'));
    });
  });

  group('CU10 - InventarioMonitoreoService API Integration', () {
    test('obtenerResumen envía parámetros y mapea respuesta', () async {
      final mock = MockApiClient();
      mock.mockGetResponse = {
        'total_stock_global': 95,
        'total_prendas_distintas': 12,
        'total_variantes': 20,
        'variantes_optimo': 14,
        'variantes_bajo_stock': 4,
        'variantes_agotadas': 2,
        'sucursales': [],
      };

      final servicio = InventarioMonitoreoService(api: mock);
      final resumen = await servicio.obtenerResumen(
        idSucursal: 1,
        idCategoria: 3,
        idTemporada: 2,
        busqueda: 'vestido',
      );

      expect(resumen.totalStock, equals(95));
      expect(mock.lastGetPath, equals('/api/inventario/resumen'));
      expect(mock.lastGetQuery?['id_sucursal'], equals('1'));
      expect(mock.lastGetQuery?['id_categoria'], equals('3'));
      expect(mock.lastGetQuery?['id_temporada'], equals('2'));
      expect(mock.lastGetQuery?['busqueda'], equals('vestido'));
    });

    test('obtenerMonitoreo envía filtros de texto y estado de stock', () async {
      final mock = MockApiClient();
      mock.mockGetResponse = [
        {
          'id_sucursal': 1,
          'nombre_sucursal': 'Sucursal Equipetrol',
          'ciudad': 'Santa Cruz',
          'id_prenda': 1,
          'prenda_sku': 'VES-01',
          'prenda_nombre': 'Vestido Casual',
          'id_variante_prenda': 10,
          'sku_variante': 'VES-01-S',
          'precio': 150.0,
          'stock': 2,
          'estado_stock': 'Bajo',
          'color_badge': 'amarillo',
        }
      ];

      final servicio = InventarioMonitoreoService(api: mock);
      final items = await servicio.obtenerMonitoreo(
        idSucursal: 1,
        busqueda: 'VES-01',
        estadoStock: 'Bajo',
      );

      expect(items.length, equals(1));
      expect(items.first.skuVariante, equals('VES-01-S'));
      expect(mock.lastGetPath, equals('/api/inventario/monitoreo'));
      expect(mock.lastGetQuery?['id_sucursal'], equals('1'));
      expect(mock.lastGetQuery?['busqueda'], equals('VES-01'));
      expect(mock.lastGetQuery?['estado_stock'], equals('Bajo'));
    });

    test('obtenerSucursales obtiene listado físico de sucursales', () async {
      final mock = MockApiClient();
      mock.mockGetResponse = [
        {'id_sucursal': 1, 'nombre': 'Sucursal Equipetrol', 'ciudad': 'Santa Cruz'},
        {'id_sucursal': 2, 'nombre': 'Sucursal Centro', 'ciudad': 'Santa Cruz'},
      ];

      final servicio = InventarioMonitoreoService(api: mock);
      final sucursales = await servicio.obtenerSucursales();

      expect(sucursales.length, equals(2));
      expect(sucursales[0].sucursal, equals('Sucursal Equipetrol'));
      expect(sucursales[1].sucursal, equals('Sucursal Centro'));
      expect(mock.lastGetPath, equals('/api/sucursales'));
    });
  });

  group('CU10 - EstadoInventarioScreen UI & Widgets', () {
    late MockApiClient mockApi;
    late InventarioMonitoreoService mockServicio;

    final mockResumenJson = {
      'total_stock_global': 50,
      'total_prendas_distintas': 3,
      'total_variantes': 3,
      'variantes_optimo': 1,
      'variantes_bajo_stock': 1,
      'variantes_agotadas': 1,
      'sucursales': [
        {
          'id_sucursal': 1,
          'nombre_sucursal': 'Sucursal Equipetrol',
          'ciudad': 'Santa Cruz',
          'total_stock': 30,
        },
        {
          'id_sucursal': 2,
          'nombre_sucursal': 'Sucursal Centro',
          'ciudad': 'Santa Cruz',
          'total_stock': 20,
        },
      ],
    };

    final mockItemsJson = [
      {
        'id_inventario': 1,
        'id_sucursal': 1,
        'nombre_sucursal': 'Sucursal Equipetrol',
        'ciudad': 'Santa Cruz',
        'id_prenda': 101,
        'sku_prenda': 'BLU-OPT-01',
        'nombre_prenda': 'Blusa de Seda',
        'categoria': 'Blusas',
        'temporada': 'Primavera 2026',
        'id_variante_prenda': 201,
        'sku_variante': 'BLU-OPT-01-S-AZU',
        'talla': 'S',
        'color': 'Azul',
        'precio': 120.0,
        'stock': 8, // Óptimo (>= 5)
        'estado_stock': 'Optimo',
        'color_badge': 'verde',
      },
      {
        'id_inventario': 2,
        'id_sucursal': 1,
        'nombre_sucursal': 'Sucursal Equipetrol',
        'ciudad': 'Santa Cruz',
        'id_prenda': 102,
        'sku_prenda': 'PAN-BAJ-02',
        'nombre_prenda': 'Pantalón Lino',
        'categoria': 'Pantalones',
        'temporada': 'Verano 2026',
        'id_variante_prenda': 202,
        'sku_variante': 'PAN-BAJ-02-32-BEI',
        'talla': '32',
        'color': 'Beige',
        'precio': 200.0,
        'stock': 3, // Bajo (1-4)
        'estado_stock': 'Bajo',
        'color_badge': 'amarillo',
      },
      {
        'id_inventario': 3,
        'id_sucursal': 1,
        'nombre_sucursal': 'Sucursal Equipetrol',
        'ciudad': 'Santa Cruz',
        'id_prenda': 103,
        'sku_prenda': 'SAC-AGO-03',
        'nombre_prenda': 'Saco Lana Invierno',
        'categoria': 'Abrigos',
        'temporada': 'Otoño 2026',
        'id_variante_prenda': 203,
        'sku_variante': 'SAC-AGO-03-M-NEG',
        'talla': 'M',
        'color': 'Negro',
        'precio': 350.0,
        'stock': 0, // Agotado (0)
        'estado_stock': 'Agotado',
        'color_badge': 'rojo',
      },
    ];

    setUp(() {
      mockApi = MockApiClient();
      mockApi.pathResponses['/api/sucursales'] = [
        {'id_sucursal': 1, 'nombre': 'Sucursal Equipetrol', 'ciudad': 'Santa Cruz'},
        {'id_sucursal': 2, 'nombre': 'Sucursal Centro', 'ciudad': 'Santa Cruz'},
      ];
      mockApi.pathResponses['/api/categorias/'] = [
        {'id_categoria': 1, 'nombre': 'Blusas'},
        {'id_categoria': 2, 'nombre': 'Pantalones'},
      ];
      mockApi.pathResponses['/api/temporadas/'] = [
        {'id_temporada': 1, 'nombre': 'Primavera 2026'},
      ];
      mockApi.pathResponses['/api/inventario/resumen'] = mockResumenJson;
      mockApi.pathResponses['/api/inventario/monitoreo'] = mockItemsJson;

      mockServicio = InventarioMonitoreoService(api: mockApi);
    });

    testWidgets('renderiza cabecera, buscador, KPIs y badges de 3 estados', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EstadoInventarioScreen(servicio: mockServicio),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar Título AppBar
      expect(find.text('Estado de Inventario'), findsOneWidget);

      // Verificar Buscador
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Buscar por SKU, modelo o prenda...'), findsOneWidget);

      // Verificar Tarjetas KPI en Header
      expect(find.text('Total Existencias'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('Bajo Stock'), findsWidgets); // En KPI y badge
      expect(find.text('Agotadas'), findsOneWidget); // En KPI

      // Verificar Chips de Sucursales
      expect(find.text('Todas las sucursales'), findsOneWidget);
      expect(find.text('Sucursal Equipetrol'), findsWidgets);

      // Verificar Variantes renderizadas
      expect(find.text('Blusa de Seda'), findsOneWidget);
      expect(find.text('SKU: BLU-OPT-01-S-AZU'), findsOneWidget);
      expect(find.text('Pantalón Lino'), findsOneWidget);
      expect(find.text('SKU: PAN-BAJ-02-32-BEI'), findsOneWidget);
      expect(find.text('Saco Lana Invierno'), findsOneWidget);
      expect(find.text('SKU: SAC-AGO-03-M-NEG'), findsOneWidget);

      // Verificar Badges Cromáticos de los 3 estados
      expect(find.text('Óptimo (8 u.)'), findsOneWidget); // Verde
      expect(find.text('Bajo Stock (3 u.)'), findsOneWidget); // Ámbar
      expect(find.text('Agotado (0 u.)'), findsOneWidget); // Rojo
    });

    testWidgets('buscador ejecuta debounce y envía parámetro busqueda a la API', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EstadoInventarioScreen(servicio: mockServicio),
        ),
      );

      await tester.pumpAndSettle();

      // Ingresar término en buscador
      await tester.enterText(find.byType(TextField), 'BLU-OPT');
      await tester.pump();

      // Esperar que el debounce de 350ms se complete
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Comprobar que la llamada a la API incluyó la búsqueda
      expect(mockApi.lastGetPath, equals('/api/inventario/monitoreo'));
      expect(mockApi.lastGetQuery?['busqueda'], equals('BLU-OPT'));
    });

    testWidgets('chips de sucursal filtran existencias por id_sucursal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EstadoInventarioScreen(servicio: mockServicio),
        ),
      );

      await tester.pumpAndSettle();

      // Seleccionar chip 'Sucursal Equipetrol'
      await tester.tap(find.widgetWithText(FilterChip, 'Sucursal Equipetrol'));
      await tester.pumpAndSettle();

      expect(mockApi.lastGetPath, equals('/api/inventario/monitoreo'));
      expect(mockApi.lastGetQuery?['id_sucursal'], equals('1'));
    });

    testWidgets('despliega desglose físico expandible y en bottom sheet modal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EstadoInventarioScreen(servicio: mockServicio),
        ),
      );

      await tester.pumpAndSettle();

      // Expandir la tarjeta de la primera variante
      await tester.tap(find.text('Blusa de Seda'));
      await tester.pumpAndSettle();

      // Comprobar que aparece el desglose por sucursal física
      expect(find.text('Desglose por Sucursal Física'), findsOneWidget);
      expect(find.text('Ver detalle'), findsOneWidget);
      expect(find.text('8 u.'), findsWidgets);

      // Abrir modal de detalle en bottom sheet
      await tester.tap(find.text('Ver detalle'));
      await tester.pumpAndSettle();

      // Comprobar contenido del bottom sheet modal
      expect(find.text('DISPONIBILIDAD POR SUCURSAL FÍSICA'), findsOneWidget);
      expect(find.text('Total disponible: 8 unidades'), findsOneWidget);

      // Cerrar modal
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('DISPONIBILIDAD POR SUCURSAL FÍSICA'), findsNothing);
    });

    testWidgets('muestra vista vacía con botón para limpiar filtros cuando no hay resultados', (tester) async {
      mockApi.pathResponses['/api/inventario/monitoreo'] = [];
      mockApi.pathResponses['/api/inventario/resumen'] = {
        'total_stock': 0,
        'total_prendas': 0,
        'total_variantes': 0,
        'total_optimo': 0,
        'total_bajo': 0,
        'total_agotado': 0,
        'sucursales': [],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: EstadoInventarioScreen(servicio: mockServicio),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No se encontraron existencias'), findsOneWidget);
      expect(find.text('Limpiar todos los filtros'), findsOneWidget);

      // Al pulsar limpiar filtros, restablece estado y recarga
      await tester.tap(find.text('Limpiar todos los filtros'));
      await tester.pumpAndSettle();
    });

    testWidgets('muestra pantalla de error y permite reintentar ante fallo de API', (tester) async {
      mockApi.pathResponses.remove('/api/inventario/monitoreo');
      mockApi.throwStatusCode = 500;
      mockApi.throwMessage = 'Fallo de conexión en el servidor central.';

      await tester.pumpWidget(
        MaterialApp(
          home: EstadoInventarioScreen(servicio: mockServicio),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Error al cargar monitoreo'), findsOneWidget);
      expect(find.text('Fallo de conexión en el servidor central.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);

      // Corregir y reintentar
      mockApi.throwStatusCode = null;
      mockApi.pathResponses['/api/inventario/monitoreo'] = mockItemsJson;
      mockApi.pathResponses['/api/inventario/resumen'] = mockResumenJson;

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Blusa de Seda'), findsOneWidget);
    });
  });

  group('CU10 - Navigation Integration in CatalogoScreen', () {
    testWidgets('Drawer incluye Estado de Inventario para personal de almacén y navega', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mock = MockApiClient();
      mock.mockPostResponse = {
        'access_token':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZF91c3VhcmlvIjoxLCJjb3JyZW8iOiJhbG1hY2VuQGZhc2hpb25zdG9yZS5jb20iLCJub21icmUiOiJKdWFuIEFsZ3VubyIsInJvbCI6IkVuY2FyZ2FkbyBkZSBTdWN1cnNhbCJ9.test',
        'token_type': 'bearer',
      };

      final auth = AuthService.instance;
      auth.api = mock;
      await auth.login('almacen@fashionstore.com', 'Clave123!');
      expect(auth.autenticado, isTrue);

      await tester.pumpWidget(
        const MaterialApp(
          home: CatalogoScreen(),
        ),
      );

      await tester.pump();

      // Abrir drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Verificar que 'GESTIÓN DE ALMACÉN' aparece
      expect(find.text('GESTIÓN DE ALMACÉN'), findsOneWidget);

      final itemFinder = find.text('Estado de Inventario');
      await tester.ensureVisible(itemFinder);
      await tester.pumpAndSettle();

      expect(itemFinder, findsOneWidget);
      expect(find.text('Monitoreo multisucursal y existencias (CU10)'), findsOneWidget);

      // Pulsar 'Estado de Inventario' y verificar navegación a EstadoInventarioScreen
      await tester.tap(itemFinder);
      await tester.pumpAndSettle();

      expect(find.byType(EstadoInventarioScreen), findsOneWidget);

      auth.logout();
    });
  });
}
