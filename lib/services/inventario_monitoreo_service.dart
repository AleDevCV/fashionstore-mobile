import '../core/api_client.dart';
import '../core/config.dart';
import '../features/inventario_monitoreo/models/inventario_monitoreo_models.dart';
import 'auth_service.dart';

/// Servicio para Monitoreo de Inventario y Existencias Multisucursal (CU10).
///
/// Consume los endpoints analíticos `/api/inventario/resumen` y
/// `/api/inventario/monitoreo` de FastAPI, permitiendo consultar KPIs globales,
/// existencias por sucursal física y realizar búsquedas reactivas con debounce.
class InventarioMonitoreoService {
  final ApiClient _api;

  InventarioMonitoreoService({ApiClient? api})
      : _api = api ??
            ApiClient(
              baseUrl: apiBaseUrl,
              tokenProvider: () => AuthService.instance.token,
            );

  /// Consulta el resumen de KPIs globales o filtrados por sucursal, categoría o temporada.
  Future<ResumenInventario> obtenerResumen({
    int? idSucursal,
    int? idCategoria,
    int? idTemporada,
    String? busqueda,
  }) async {
    final query = <String, String>{};
    if (idSucursal != null) query['id_sucursal'] = '$idSucursal';
    if (idCategoria != null) query['id_categoria'] = '$idCategoria';
    if (idTemporada != null) query['id_temporada'] = '$idTemporada';
    if (busqueda != null && busqueda.trim().isNotEmpty) {
      query['busqueda'] = busqueda.trim();
    }

    final data = await _api.get('/api/inventario/resumen', query: query);
    if (data is Map<String, dynamic>) {
      return ResumenInventario.fromJson(data);
    }
    return const ResumenInventario(
      totalStock: 0,
      totalPrendas: 0,
      totalVariantes: 0,
      totalOptimo: 0,
      totalBajo: 0,
      totalAgotado: 0,
      sucursales: [],
    );
  }

  /// Consulta el listado detallado de existencias con filtros y clasificación de stock.
  Future<List<MonitoreoItem>> obtenerMonitoreo({
    int? idSucursal,
    int? idCategoria,
    int? idTemporada,
    String? busqueda,
    String? estadoStock,
    int limit = 100,
    int skip = 0,
  }) async {
    final query = <String, String>{
      'limit': '$limit',
      'skip': '$skip',
    };
    if (idSucursal != null) query['id_sucursal'] = '$idSucursal';
    if (idCategoria != null) query['id_categoria'] = '$idCategoria';
    if (idTemporada != null) query['id_temporada'] = '$idTemporada';
    if (busqueda != null && busqueda.trim().isNotEmpty) {
      query['busqueda'] = busqueda.trim();
    }
    if (estadoStock != null &&
        estadoStock.isNotEmpty &&
        estadoStock != 'Todos') {
      query['estado_stock'] = estadoStock;
    }

    final data = await _api.get('/api/inventario/monitoreo', query: query);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((item) => MonitoreoItem.fromJson(item))
          .toList();
    }
    return [];
  }

  /// Consulta las sucursales físicas activas para los chips de filtro.
  Future<List<ResumenSucursalInventario>> obtenerSucursales() async {
    final data = await _api.get('/api/sucursales');
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((s) => ResumenSucursalInventario(
                idSucursal: s['id_sucursal'] is num
                    ? (s['id_sucursal'] as num).toInt()
                    : int.tryParse(s['id_sucursal']?.toString() ?? '0') ?? 0,
                sucursal: (s['nombre'] ?? s['sucursal'] ?? s['nombre_sucursal'] ?? '').toString(),
                ciudad: (s['ciudad'] ?? '').toString(),
                totalStock: s['total_stock'] is num ? (s['total_stock'] as num).toInt() : 0,
              ))
          .toList();
    }
    return [];
  }

  /// Consulta las categorías activas para filtros avanzados.
  Future<List<Map<String, dynamic>>> obtenerCategorias() async {
    try {
      final data = await _api.get('/api/categorias/');
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Consulta las temporadas para filtros avanzados.
  Future<List<Map<String, dynamic>>> obtenerTemporadas() async {
    try {
      final data = await _api.get('/api/temporadas/');
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
