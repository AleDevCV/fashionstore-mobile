import '../core/api_client.dart';
import '../core/config.dart';
import '../features/movimientos/models/movimiento_models.dart';
import 'auth_service.dart';

/// Servicio para Registro y Consulta de Movimientos de Inventario (CU11).
///
/// Consume los endpoints protegidos con token JWT para administrar el kardex
/// físico y validar existencias disponibles antes de confirmar salidas.
class MovimientoService {
  final ApiClient _api;

  MovimientoService({ApiClient? api})
      : _api = api ??
            ApiClient(
              baseUrl: apiBaseUrl,
              tokenProvider: () => AuthService.instance.token,
            );

  /// Consulta el historial cronológico de movimientos con filtros opcionales.
  Future<List<MovimientoInventario>> listar({
    int? idSucursal,
    int? idVariantePrenda,
    String? tipo,
    int skip = 0,
    int limit = 50,
  }) async {
    final query = <String, String>{
      'skip': '$skip',
      'limit': '$limit',
    };
    if (idSucursal != null) query['id_sucursal'] = '$idSucursal';
    if (idVariantePrenda != null) {
      query['id_variante_prenda'] = '$idVariantePrenda';
    }
    if (tipo != null && tipo.isNotEmpty && tipo != 'Todos') {
      query['tipo'] = tipo;
    }

    final data = await _api.get('/api/movimientos-inventario/', query: query);
    if (data is List) {
      return data
          .map((e) => MovimientoInventario.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Registra una operación de almacén (Entrada, Salida o Traspaso).
  ///
  /// Si el stock es insuficiente para una Salida o Traspaso, el backend
  /// (mediante el trigger PL/pgSQL) aborta la transacción y lanza HTTP 400.
  Future<MovimientoInventario> registrar(MovimientoCrear movimiento) async {
    final data = await _api.post(
      '/api/movimientos-inventario/',
      body: movimiento.toJson(),
    );
    return MovimientoInventario.fromJson(data as Map<String, dynamic>);
  }

  /// Consulta el stock físico disponible en tiempo real para una variante en sucursal.
  Future<int> consultarStock({
    required int idSucursal,
    required int idVariantePrenda,
  }) async {
    try {
      final data = await _api.get(
        '/api/movimientos-inventario/stock',
        query: {
          'id_sucursal': '$idSucursal',
          'id_variante_prenda': '$idVariantePrenda',
        },
      );
      if (data is Map<String, dynamic>) {
        final resp = StockRespuesta.fromJson(data);
        return resp.stock;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Lista las sucursales físicas activas para los selectores de movimiento.
  Future<List<SucursalOpcion>> listarSucursales() async {
    final data = await _api.get('/api/sucursales');
    if (data is List) {
      return data
          .map((e) => SucursalOpcion.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Consulta las variantes de prendas disponibles en el catálogo para el selector.
  Future<List<VarianteOpcion>> listarVariantesCatalogo() async {
    final data = await _api.get('/api/catalogo/', query: {'limite': '100'});
    final resultado = <VarianteOpcion>[];

    if (data is Map<String, dynamic> && data['prendas'] is List) {
      final prendas = data['prendas'] as List;
      for (final p in prendas) {
        if (p is Map<String, dynamic>) {
          final prendaNombre = (p['nombre'] ?? '').toString();
          final skuPrenda = (p['sku'] ?? '').toString();
          final variantes = p['variantes'] as List? ?? [];
          for (final v in variantes) {
            if (v is Map<String, dynamic>) {
              final idVar = (v['id_variante_prenda'] is num)
                  ? (v['id_variante_prenda'] as num).toInt()
                  : int.tryParse(v['id_variante_prenda']?.toString() ?? '') ?? 0;
              final talla = v['talla']?.toString();
              final color = v['color']?.toString();
              if (idVar > 0) {
                resultado.add(
                  VarianteOpcion(
                    idVariantePrenda: idVar,
                    skuVariante: skuPrenda,
                    prendaNombre: prendaNombre,
                    talla: talla,
                    color: color,
                  ),
                );
              }
            }
          }
        }
      }
    }
    return resultado;
  }
}
