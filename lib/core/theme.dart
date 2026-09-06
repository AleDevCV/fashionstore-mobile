import 'package:flutter/material.dart';

/// Tokens de marca de FashionStore, replicados del sistema de diseño del
/// frontend Angular para mantener coherencia visual en la app móvil.
library;

const Color fsInk = Color(0xFF111111);
const Color fsInkSoft = Color(0xFF565656);
const Color fsInkMuted = Color(0xFF8A8A8A);
const Color fsBg = Color(0xFFFAFAFA);
const Color fsSurface = Color(0xFFFFFFFF);
const Color fsSurfaceAlt = Color(0xFFF4F3F1);
const Color fsBorder = Color(0xFFE5E5E5);
const Color fsGold = Color(0xFFC5A880);
const Color fsGoldDeep = Color(0xFFB08F63);
const Color fsGoldWash = Color(0xFFF2EBE0);
const Color fsEmerald = Color(0xFF0D5C3A);
const Color fsDanger = Color(0xFF8B2B2B);
const Color fsDangerWash = Color(0xFFFBF5F5);

/// Construye el tema global: sobrio, con el dorado champán de la marca como
/// acento primario y bordes finos en lugar de sombras.
ThemeData buildAppTheme() {
  const colorScheme = ColorScheme.light(
    primary: fsGold,
    onPrimary: fsInk,
    secondary: fsGoldDeep,
    onSecondary: Colors.white,
    error: fsDanger,
    surface: fsSurface,
    onSurface: fsInk,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);

  return base.copyWith(
    scaffoldBackgroundColor: fsBg,
    textTheme: base.textTheme.apply(
      bodyColor: fsInk,
      displayColor: fsInk,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: fsSurface,
      foregroundColor: fsInk,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fsSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      labelStyle: const TextStyle(fontSize: 11, letterSpacing: 1.4, color: fsInkMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: fsBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: fsBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: fsInk),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: fsGold,
        foregroundColor: fsInk,
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: fsInk,
        side: const BorderSide(color: fsBorder),
        textStyle: const TextStyle(fontSize: 13, letterSpacing: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: fsInkSoft),
    ),
  );
}

/// Formatea un precio (double) con dos decimales y el prefijo de moneda.
String formatearPrecio(double valor) => 'Bs ${valor.toStringAsFixed(2)}';
