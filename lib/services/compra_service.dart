import '../core/api_client.dart';
import '../core/config.dart';
import '../features/compras/models/compra_models.dart';
import 'auth_service.dart';

/// Servicio para Consulta de Compras y Recepción de Lotes (CU13).
///
/// Consume los endpoints protegidos con token Bearer de FastAPI para listar
/// comprobantes de compra y consultar el desglose de productos ingresados con 13% IVA.
class CompraService {
  final ApiClient _api;

  CompraService({ApiClient? api})
      : _api = api ??
            ApiClient(
              baseUrl: apiBaseUrl,
              tokenProvider: () => AuthService.instance.token,
            );

  /// Lista las compras y lotes ingresados con filtros opcionales.
  Future<List<Compra>> listar({
    int? idProveedor,
    int? idSucursal,
    int skip = 0,
    int limit = 50,
  }) async {
    final query = <String, String>{
      'skip': '$skip',
      'limit': '$limit',
    };
    if (idProveedor != null) query['id_proveedor'] = '$idProveedor';
    if (idSucursal != null) query['id_sucursal'] = '$idSucursal';

    final data = await _api.get('/api/compras/', query: query);
    if (data is List) {
      return data
          .map((e) => Compra.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Consulta la ficha detallada de una compra con todos sus ítems físicos ingresados.
  Future<Compra> obtener(int idCompra) async {
    final data = await _api.get('/api/compras/$idCompra');
    return Compra.fromJson(data as Map<String, dynamic>);
  }
}
