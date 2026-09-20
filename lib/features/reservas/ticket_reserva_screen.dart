import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import '../../core/models/venta_models.dart';
import '../../core/theme.dart';
import '../../services/venta_service.dart';

/// Pantalla del Ticket Digital Omnicanal para Prueba Física (CU16).
class TicketReservaScreen extends StatefulWidget {
  final TicketReservaRespuesta ticketInicial;

  const TicketReservaScreen({super.key, required this.ticketInicial});

  @override
  State<TicketReservaScreen> createState() => _TicketReservaScreenState();
}

class _TicketReservaScreenState extends State<TicketReservaScreen> {
  late TicketReservaRespuesta _ticket;
  final _ventaService = VentaService();
  Timer? _timer;
  Duration _tiempoRestante = Duration.zero;
  bool _actualizando = false;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticketInicial;
    _calcularTiempoRestante();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calcularTiempoRestante());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calcularTiempoRestante() {
    try {
      final fechaLimite = DateTime.parse(_ticket.fechaLimite);
      final ahora = DateTime.now();
      final diff = fechaLimite.difference(ahora);
      if (mounted) {
        setState(() {
          _tiempoRestante = diff.isNegative ? Duration.zero : diff;
        });
      }
    } catch (_) {
      _tiempoRestante = Duration.zero;
    }
  }

  Future<void> _refrescarTicket() async {
    setState(() => _actualizando = true);
    try {
      final t = await _ventaService.obtenerTicketReserva(_ticket.codigoTicket);
      if (mounted) {
        setState(() {
          _ticket = t;
          _actualizando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _actualizando = false);
    }
  }

  String _formatearCuentaRegresiva(Duration d) {
    if (d == Duration.zero) return 'Expirado';
    final horas = d.inHours;
    final minutos = d.inMinutes.remainder(60);
    final segundos = d.inSeconds.remainder(60);
    if (horas > 0) {
      return '${horas}h ${minutos.toString().padLeft(2, '0')}m ${segundos.toString().padLeft(2, '0')}s';
    }
    return '${minutos}m ${segundos.toString().padLeft(2, '0')}s';
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Pendiente':
        return const Color(0xFFD97706);
      case 'Preparado':
        return const Color(0xFFEA580C);
      case 'Atendido':
        return fsEmerald;
      case 'Cancelado':
        return fsDanger;
      default:
        return fsInkSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _ticket;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket de Probador'),
        actions: [
          IconButton(
            icon: _actualizando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Actualizar estado',
            onPressed: _actualizando ? null : _refrescarTicket,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── TARJETA PRINCIPAL DEL TICKET ────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: fsSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: fsBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Cabecera del ticket
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: fsInk,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FASHIONSTORE · PROBADOR',
                              style: TextStyle(
                                color: fsGold,
                                fontSize: 10,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t.codigoTicket,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _colorEstado(t.estado).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _colorEstado(t.estado)),
                          ),
                          child: Text(
                            t.estado == 'Preparado' ? 'En Probador' : t.estado,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Código QR
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (t.qrBase64.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: fsBorder),
                            ),
                            child: Image.memory(
                              base64Decode(t.qrBase64),
                              width: 190,
                              height: 190,
                              fit: BoxFit.contain,
                            ),
                          )
                        else
                          const Icon(Icons.qr_code, size: 120, color: fsInkMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'Muestra este código al llegar a la tienda',
                          style: TextStyle(color: fsInkSoft, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Separador tipo ticket recortado
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: fsBg,
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(14)),
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Flex(
                              direction: Axis.horizontal,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              mainAxisSize: MainAxisSize.max,
                              children: List.generate(
                                (constraints.constrainWidth() / 10).floor(),
                                (_) => const SizedBox(
                                  width: 5,
                                  height: 1.5,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(color: fsBorder),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        width: 14,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: fsBg,
                          borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
                        ),
                      ),
                    ],
                  ),

                  // Temporizador de vigencia
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: fsSurfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: fsGoldDeep, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tiempo restante para prueba:',
                                  style: TextStyle(fontSize: 11, color: fsInkMuted),
                                ),
                                Text(
                                  _formatearCuentaRegresiva(_tiempoRestante),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: fsInk,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Datos de la sucursal
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: [
                        _filaInfo('Sucursal de prueba:', t.sucursalNombre ?? 'Sucursal #${t.idSucursal}'),
                        const SizedBox(height: 6),
                        _filaInfo('Cliente:', t.clienteNombre ?? 'Cliente #${t.idCliente}'),
                        const SizedBox(height: 6),
                        _filaInfo('Total prendas:', '${t.items.length} prenda(s)'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── LISTA DE PRENDAS RESERVADAS ────────────────────────────────
            const Text(
              'Prendas Separadas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            ...t.items.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: fsSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: fsBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: fsSurfaceAlt,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.checkroom, color: fsGoldDeep, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.prendaNombre,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Talla: ${item.talla ?? 'U'} · Color: ${item.color ?? 'U'} · Cant: ${item.cantidad}',
                            style: const TextStyle(fontSize: 12, color: fsInkMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Bs ${item.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            FilledButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              style: FilledButton.styleFrom(
                backgroundColor: fsInk,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Volver al Catálogo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaInfo(String etiqueta, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(etiqueta, style: const TextStyle(fontSize: 12, color: fsInkSoft)),
        Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
