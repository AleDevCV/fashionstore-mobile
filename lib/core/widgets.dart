import 'package:flutter/material.dart';

import 'theme.dart';

/// Imagen de red con placeholder de carga y respaldo ante error.
Widget redImagen(String? url) {
  if (url == null || url.isEmpty) {
    return const ColoredBox(
      color: fsSurfaceAlt,
      child: Center(
        child: Icon(Icons.image_not_supported_outlined, color: fsInkMuted),
      ),
    );
  }

  return Image.network(
    url,
    fit: BoxFit.cover,
    loadingBuilder: (context, child, progress) {
      if (progress == null) return child;
      return const ColoredBox(
        color: fsSurfaceAlt,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    },
    errorBuilder: (context, error, stack) => const ColoredBox(
      color: fsSurfaceAlt,
      child: Center(
        child: Icon(Icons.image_not_supported_outlined, color: fsInkMuted),
      ),
    ),
  );
}

/// Distintivo de disponibilidad (verde) o agotado (vino).
Widget badgeStock(int stock) {
  final activo = stock > 0;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: activo ? const Color(0xFFE9F1EC) : fsDangerWash,
      borderRadius: BorderRadius.circular(2),
      border: Border.all(
        color: activo ? const Color(0xFFCBE0D3) : const Color(0xFFEBD8D8),
      ),
    ),
    child: Text(
      activo ? 'Disponible' : 'Agotado',
      style: TextStyle(
        fontSize: 10,
        letterSpacing: 1,
        color: activo ? fsEmerald : fsDanger,
      ),
    ),
  );
}
