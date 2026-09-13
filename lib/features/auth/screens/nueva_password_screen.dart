import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../services/auth_service.dart';
import '../../login/login_screen.dart';

/// Pantalla para ingresar el token y definir la nueva contraseña (CU04).
class NuevaPasswordScreen extends StatefulWidget {
  final String? initialToken;

  const NuevaPasswordScreen({super.key, this.initialToken});

  @override
  State<NuevaPasswordScreen> createState() => _NuevaPasswordScreenState();
}

class _NuevaPasswordScreenState extends State<NuevaPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tokenCtrl;
  final _passwordCtrl = TextEditingController();
  final _confirmarPasswordCtrl = TextEditingController();
  final AuthService _auth = AuthService();

  bool _cargando = false;
  bool _ocultarPassword = true;
  bool _ocultarConfirmacion = true;
  String? _error;
  String? _exito;

  @override
  void initState() {
    super.initState();
    _tokenCtrl = TextEditingController(text: widget.initialToken ?? '');
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmarPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _restablecerPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _cargando = true;
      _error = null;
      _exito = null;
    });

    try {
      final respuesta = await _auth.restablecerPassword(
        _tokenCtrl.text.trim(),
        _passwordCtrl.text,
      );

      if (!mounted) return;
      setState(() {
        _exito = respuesta.mensaje;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta.mensaje.isNotEmpty
              ? respuesta.mensaje
              : 'Contraseña restablecida exitosamente.'),
          backgroundColor: fsEmerald,
        ),
      );

      // Redirige al Login descartando rutas anteriores
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error =
          'No se pudo conectar con el servidor. Verifique su conexión.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nueva Contraseña',
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
                      'Restablecer Acceso',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: fsInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ingrese el código o token de recuperación recibido por correo junto con su nueva contraseña.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: fsInkSoft, height: 1.4),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _tokenCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Token o código de recuperación',
                        hintText: 'Pegue el token recibido',
                        prefixIcon: Icon(Icons.key_outlined, size: 20),
                      ),
                      validator: (v) {
                        final val = v?.trim() ?? '';
                        if (val.isEmpty) return 'Ingrese el token de recuperación.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _ocultarPassword,
                      decoration: InputDecoration(
                        labelText: 'Nueva Contraseña',
                        hintText: 'Mínimo 6 caracteres',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _ocultarPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _ocultarPassword = !_ocultarPassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Ingrese la nueva contraseña.';
                        }
                        if (v.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmarPasswordCtrl,
                      obscureText: _ocultarConfirmacion,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Contraseña',
                        hintText: 'Repita la nueva contraseña',
                        prefixIcon: const Icon(Icons.lock_reset_outlined, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _ocultarConfirmacion
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                              () => _ocultarConfirmacion = !_ocultarConfirmacion),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Confirme la nueva contraseña.';
                        }
                        if (v != _passwordCtrl.text) {
                          return 'Las contraseñas no coinciden.';
                        }
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
                    if (_exito != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: fsEmerald, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_exito!,
                                  style: const TextStyle(color: fsEmerald, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _cargando ? null : _restablecerPassword,
                      child: _cargando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: fsInk,
                              ),
                            )
                          : const Text('CAMBIAR CONTRASEÑA'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      child: const Text('Cancelar y volver al inicio de sesión'),
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
