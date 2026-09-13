import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../services/auth_service.dart';
import 'nueva_password_screen.dart';

/// Pantalla para solicitar la recuperación de contraseña por correo (CU04).
class RecuperarPasswordScreen extends StatefulWidget {
  const RecuperarPasswordScreen({super.key});

  @override
  State<RecuperarPasswordScreen> createState() => _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  final AuthService _auth = AuthService();

  bool _cargando = false;
  String? _error;
  String? _mensajeExito;

  @override
  void dispose() {
    _correoCtrl.dispose();
    super.dispose();
  }

  Future<void> _solicitarRecuperacion() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _cargando = true;
      _error = null;
      _mensajeExito = null;
    });

    try {
      final respuesta = await _auth.solicitarRecuperacionPassword(
        _correoCtrl.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _mensajeExito = respuesta.mensaje.isNotEmpty
            ? respuesta.mensaje
            : 'Si el correo está registrado en el sistema, se ha enviado un enlace y código de recuperación.';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error =
          'No se pudo conectar con el servidor. Verifique su conexión a internet.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _irANuevaPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NuevaPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recuperar Contraseña',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'FashionStore',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4,
                        color: fsInk,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '¿Olvidó su contraseña?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                        color: fsInkSoft,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ingrese su correo electrónico registrado. Le enviaremos un enlace y código para que pueda restablecer su clave de acceso.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: fsInkMuted, height: 1.4),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _correoCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        hintText: 'ejemplo@fashionstore.com',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                      validator: (v) {
                        final val = v?.trim() ?? '';
                        if (val.isEmpty) return 'Ingrese su correo electrónico.';
                        if (!val.contains('@')) return 'Ingrese un correo válido.';
                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: fsDangerWash,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFEBD8D8)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: fsDanger, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(color: fsDanger, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_mensajeExito != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    color: fsEmerald, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Solicitud Procesada',
                                    style: TextStyle(
                                      color: fsEmerald,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _mensajeExito!,
                              style: const TextStyle(
                                color: fsInkSoft,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: _irANuevaPassword,
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: const Text('INGRESAR CÓDIGO O TOKEN'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: fsEmerald,
                                side: const BorderSide(color: fsEmerald),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _cargando ? null : _solicitarRecuperacion,
                      child: _cargando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: fsInk,
                              ),
                            )
                          : const Text('ENVIAR ENLACE DE RECUPERACIÓN'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _irANuevaPassword,
                      child: const Text('¿Ya tiene un código o token? Ingrese aquí'),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Volver al inicio de sesión'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
