import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../login/login_screen.dart';

/// Pantalla de bienvenida: muestra la marca y, tras una pausa breve, lleva al
/// inicio de sesión (CU01) o, desde ahí, a la vitrina pública (CU14).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'FashionStore',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                letterSpacing: 4,
                color: fsInk,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Catálogo y disponibilidad',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 2,
                color: fsInkMuted,
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
