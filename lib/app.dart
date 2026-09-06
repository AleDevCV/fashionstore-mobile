import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'features/splash/splash_screen.dart';

/// Raíz de la aplicación móvil de FashionStore.
///
/// El arranque pasa por una pantalla de bienvenida ([SplashScreen]) y, de ahí,
/// al inicio de sesión o a la vitrina del catálogo público (CU14).
class FashionStoreApp extends StatelessWidget {
  const FashionStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FashionStore',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const SplashScreen(),
    );
  }
}
