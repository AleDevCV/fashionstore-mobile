import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../catalogo/catalogo_screen.dart';

/// Pantalla de inicio de sesión (CU01).
///
/// El error del backend (401/403) llega traducido por [ApiException] y se
/// muestra en el propio formulario sin cerrar la vista.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final AuthService _auth = AuthService();

  bool _cargando = false;
  bool _ocultarPassword = true;
  String? _error;

  @override
  void dispose() {
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await _auth.login(_correoCtrl.text.trim(), _passwordCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bienvenido a FashionStore.')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CatalogoScreen()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo contactar con el servidor. Verifique la conexión.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _irComoInvitado() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CatalogoScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
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
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4,
                        color: fsInk,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Iniciar sesión',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, letterSpacing: 2, color: fsInkMuted),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _correoCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        hintText: 'nombre@fashionstore.com',
                      ),
                      validator: (v) {
                        final valor = v?.trim() ?? '';
                        if (valor.isEmpty) return 'Ingrese su correo electrónico.';
                        if (!valor.contains('@')) return 'Ingrese un correo válido.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _ocultarPassword,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _ocultarPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(() => _ocultarPassword = !_ocultarPassword),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Ingrese su contraseña.' : null,
                      onFieldSubmitted: (_) => _iniciarSesion(),
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
                              child: Text(_error!, style: const TextStyle(color: fsDanger, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _cargando ? null : _iniciarSesion,
                      child: _cargando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: fsInk),
                            )
                          : const Text('INICIAR SESIÓN'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _irComoInvitado,
                      child: const Text('Explorar catálogo sin cuenta'),
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
