import '../core/api_client.dart';
import '../core/config.dart';
import '../core/models/venta_models.dart';
import 'auth_service.dart';

/// Servicio de ventas, pagos y facturación para el cliente móvil (CU15, CU20, CU21).
class VentaService {
  final ApiClient _api;

  VentaService({ApiClient? api})
      : _api = api ??
            ApiClient(
              baseUrl: apiBaseUrl,
              tokenProvider: () => AuthService.instance.token,
            );

  /// Crea una reserva que bloquea el stock de los productos (CU15).
  Future<ReservaRespuesta> crearReserva(ReservaPeticion peticion) async {
    final res = await _api.post('/api/ventas/reserva', body: peticion.toJson());
    return ReservaRespuesta.fromJson(res as Map<String, dynamic>);
  }

  /// Genera un código QR boliviano de pago (CU20).
  Future<QRGenerarRespuesta> generarQR(QRGenerarPeticion peticion) async {
    final res = await _api.post('/api/pagos/qr/generar', body: peticion.toJson());
    return QRGenerarRespuesta.fromJson(res as Map<String, dynamic>);
  }

  /// Confirma el pago QR y consolida la venta descontando el stock (CU20).
  Future<Map<String, dynamic>> confirmarQR(QRConfirmarPeticion peticion) async {
    final res = await _api.post('/api/pagos/qr/confirmar', body: peticion.toJson());
    return res as Map<String, dynamic>;
  }

  /// Genera el comprobante fiscal PDF con QR (CU21).
  Future<ComprobanteRespuesta> generarComprobante({
    required int idVenta,
    required String nitCi,
    required String razonSocial,
    bool enviarEmail = true,
  }) async {
    final res = await _api.post(
      '/api/comprobantes/generar',
      body: {
        'id_venta': idVenta,
        'nit_ci': nitCi,
        'razon_social': razonSocial,
        'enviar_email': enviarEmail,
      },
    );
    return ComprobanteRespuesta.fromJson(res as Map<String, dynamic>);
  }

  /// Consulta el comprobante de una venta (CU21).
  Future<ComprobanteRespuesta> obtenerComprobante(int idVenta) async {
    final res = await _api.get('/api/comprobantes/venta/$idVenta');
    return ComprobanteRespuesta.fromJson(res as Map<String, dynamic>);
  }
}
