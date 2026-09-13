import '../core/api_client.dart';
import '../core/config.dart';
import '../features/proveedores/models/proveedor_models.dart';
import 'auth_service.dart';

/// Servicio para el Directorio y Consulta de Proveedores (CU12).
///
/// Consume los endpoints protegidos por JWT (/api/proveedores/) utilizando
/// el token de autenticación del usuario actual.
class ProveedorService {
  final ApiClient _api;

  ProveedorService({ApiClient? api})
      : _api = api ??
            ApiClient(
              baseUrl: apiBaseUrl,
              tokenProvider: () => AuthService.instance.token,
            );

  /// Consulta la lista de proveedores con filtro opcional por NIT o Razón Social.
  Future<List<Proveedor>> listar({
    String? busqueda,
    int skip = 0,
    int limit = 50,
  }) async {
    final query = <String, String>{
      'skip': '$skip',
      'limit': '$limit',
    };
    if (busqueda != null && busqueda.trim().isNotEmpty) {
      query['busqueda'] = busqueda.trim();
    }

    final data = await _api.get('/api/proveedores/', query: query);
    if (data is List) {
      return data
          .map((e) => Proveedor.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Obtiene la ficha completa de un proveedor por su ID.
  Future<Proveedor> obtener(int idProveedor) async {
    final data = await _api.get('/api/proveedores/$idProveedor');
    return Proveedor.fromJson(data as Map<String, dynamic>);
  }
}
