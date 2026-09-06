import '../core/api_client.dart';
import '../core/config.dart';
import '../core/models/catalogo_models.dart';

/// Servicio del catálogo público (CU14).
///
/// Consume los endpoints abiertos de FastAPI (sin token) para listar la
/// vitrina, obtener los filtros disponibles y abrir la ficha de una prenda
/// con su disponibilidad desglosada por sucursal.
class CatalogoService {
  final ApiClient _api = ApiClient(baseUrl: apiBaseUrl);

  /// Opciones para construir la barra de filtros (categorías, tallas…).
  Future<FiltrosDisponibles> obtenerFiltros() async {
    final data = await _api.get('/api/catalogo/filtros');
    return FiltrosDisponibles.fromJson(data as Map<String, dynamic>);
  }

  /// Consulta una página del catálogo aplicando los filtros del CU14.
  Future<RespuestaCatalogo> consultar({
    String? busqueda,
    int? idCategoria,
    String? genero,
    int? idTalla,
    int? idColor,
    double? precioMin,
    double? precioMax,
    int limite = 24,
    int desplazamiento = 0,
  }) async {
    final query = <String, String>{};
    if (busqueda != null && busqueda.isNotEmpty) query['busqueda'] = busqueda;
    if (idCategoria != null) query['id_categoria'] = '$idCategoria';
    if (genero != null && genero.isNotEmpty) query['genero'] = genero;
    if (idTalla != null) query['id_talla'] = '$idTalla';
    if (idColor != null) query['id_color'] = '$idColor';
    if (precioMin != null) query['precio_min'] = precioMin.toString();
    if (precioMax != null) query['precio_max'] = precioMax.toString();
    query['limite'] = '$limite';
    query['desplazamiento'] = '$desplazamiento';

    final data = await _api.get('/api/catalogo/', query: query);
    return RespuestaCatalogo.fromJson(data as Map<String, dynamic>);
  }

  /// Ficha de una prenda con su stock por sucursal.
  Future<PrendaCatalogo> obtenerFicha(int idPrenda) async {
    final data = await _api.get('/api/catalogo/$idPrenda');
    return PrendaCatalogo.fromJson(data as Map<String, dynamic>);
  }
}
