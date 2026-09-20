import 'dart:convert';
import 'package:flutter/material.dart';

import '../../core/models/venta_models.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/carrito_service.dart';
import '../../services/venta_service.dart';

/// Pantalla móvil de Checkout digital, Pasarela de Pagos QR y Facturación (CU15, CU20, CU21).
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _ventaService = VentaService();
  final _nitCtrl = TextEditingController();
  final _razonCtrl = TextEditingController();

  int _paso = 1;
  bool _cargando = false;
  String? _error;

  ReservaRespuesta? _reserva;
  QRGenerarRespuesta? _qr;
  ComprobanteRespuesta? _comprobante;
  int? _idVentaConfirmada;

  @override
  void initState() {
    super.initState();
    final auth = AuthService.instance;
    if (auth.nombreUsuario != null) {
      _razonCtrl.text = auth.nombreUsuario!;
    }
  }

  @override
  void dispose() {
    _nitCtrl.dispose();
    _razonCtrl.dispose();
    super.dispose();
  }

  int _obtenerIdCliente() {
    final claims = AuthService.instance.tokenClaims;
    if (claims != null) {
      if (claims['id_cliente'] != null) {
        return (claims['id_cliente'] as num).toInt();
      }
      if (claims['id_usuario'] != null) {
        return (claims['id_usuario'] as num).toInt();
      }
    }
    return 61; // fallback desarrollo
  }

  Future<void> _crearReservaYGenerarQR() async {
    final nit = _nitCtrl.text.trim();
    final razon = _razonCtrl.text.trim();
    if (nit.isEmpty || razon.isEmpty) {
      setState(() => _error = 'Por favor completa tu NIT/CI y Razón Social.');
      return;
    }

    final carrito = CarritoService.instance;
    if (carrito.estaVacio) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final idCliente = _obtenerIdCliente();

      // 1. Crear Reserva (CU15)
      final reserva = await _ventaService.crearReserva(
        ReservaPeticion(
          idCliente: idCliente,
          idSucursal: 1, // Central
          items: carrito.items
              .map(
                (i) => DetalleReservaItem(
                  idVariantePrenda: i.idVariantePrenda,
                  cantidad: i.cantidad,
                  precioUnitario: i.precioUnitario,
                ),
              )
              .toList(),
        ),
      );

      // 2. Generar QR Bolivia (CU20)
      final qr = await _ventaService.generarQR(
        QRGenerarPeticion(
          idReserva: reserva.idReserva,
          idCliente: idCliente,
          monto: reserva.total,
          concepto: 'Pedido FashionStore #${reserva.idReserva}',
        ),
      );

      if (!mounted) return;
      setState(() {
        _reserva = reserva;
        _qr = qr;
        _paso = 2;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  Future<void> _confirmarPagoQR() async {
    final qr = _qr;
    final reserva = _reserva;
    if (qr == null || reserva == null) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final idCliente = _obtenerIdCliente();

      // 3. Confirmar pago QR y consolidar venta (CU20)
      final ventaRes = await _ventaService.confirmarQR(
        QRConfirmarPeticion(
          referencia: qr.referencia,
          idReserva: reserva.idReserva,
          idCliente: idCliente,
          idSucursal: 1,
        ),
      );

      final idVenta = ventaRes['id_venta'] as int? ?? reserva.idReserva;

      // 4. Generar comprobante digital (CU21)
      ComprobanteRespuesta? comp;
      try {
        comp = await _ventaService.generarComprobante(
          idVenta: idVenta,
          nitCi: _nitCtrl.text.trim(),
          razonSocial: _razonCtrl.text.trim(),
          enviarEmail: true,
        );
      } catch (_) {
        // comprobante no bloquea la venta
      }

      // Vaciar carrito
      CarritoService.instance.vaciarCarrito();

      if (!mounted) return;
      setState(() {
        _idVentaConfirmada = idVenta;
        _comprobante = comp;
        _paso = 3;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Digital'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: fsDangerWash,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: fsDanger.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: fsDanger, fontSize: 13),
                ),
              ),

            // ── PASO 1: DATOS FISCALES ─────────────────────────────────────
            if (_paso == 1) ...[
              const Text(
                'Datos de Facturación (CU21)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ingresa tus datos para la emisión del comprobante digital con QR fiscal.',
                style: TextStyle(color: fsInkSoft, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nitCtrl,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'NIT / Cédula de Identidad',
                  hintText: 'Ej: 8493021',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _razonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Razón Social / Nombre Completo',
                  hintText: 'Ej: María René Ortiz',
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: fsSurfaceAlt,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: fsBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total a pagar:', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      'Bs ${CarritoService.instance.totalMonto.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _cargando ? null : _crearReservaYGenerarQR,
                  style: FilledButton.styleFrom(
                    backgroundColor: fsInk,
                    foregroundColor: Colors.white,
                  ),
                  child: _cargando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Continuar al Pago con QR →'),
                ),
              ),
            ],

            // ── PASO 2: PAGO QR BOLIVIA (CU20) ─────────────────────────────
            if (_paso == 2 && _qr != null) ...[
              const Text(
                'Pago Electrónico QR Simple (CU20)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Escanea el código QR desde tu aplicación bancaria móvil para pagar Bs ${_qr!.monto.toStringAsFixed(2)}.',
                style: const TextStyle(color: fsInkSoft, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: fsBorder, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Image.memory(
                    base64Decode(_qr!.qrBase64),
                    width: 220,
                    height: 220,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Referencia: ${_qr!.referencia}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  '⏱ Válido por 15 minutos',
                  style: TextStyle(color: fsInkMuted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _cargando ? null : _confirmarPagoQR,
                  style: FilledButton.styleFrom(
                    backgroundColor: fsEmerald,
                    foregroundColor: Colors.white,
                  ),
                  child: _cargando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          '✅ Ya realicé el pago (Confirmar)',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],

            // ── PASO 3: CONFIRMACIÓN Y COMPROBANTE (CU21) ───────────────────
            if (_paso == 3) ...[
              const SizedBox(height: 20),
              const Center(
                child: Icon(Icons.check_circle_outline, color: fsEmerald, size: 72),
              ),
              const SizedBox(height: 16),
              const Text(
                '¡Pago Confirmado con Éxito!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu pedido ha sido procesado e inventariado correctamente.',
                style: TextStyle(color: fsInkSoft, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: fsSurfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: fsBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Venta: #$_idVentaConfirmada', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('NIT / CI: ${_nitCtrl.text}'),
                    const SizedBox(height: 4),
                    Text('Razón Social: ${_razonCtrl.text}'),
                    if (_comprobante != null) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 4),
                      Text(
                        'Comprobante: ${_comprobante!.numeroComprobante}',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: fsEmerald),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: fsInk,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Volver al Catálogo'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
