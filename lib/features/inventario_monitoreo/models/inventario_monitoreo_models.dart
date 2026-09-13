import 'package:flutter/material.dart';

import '../../../core/theme.dart';

int _toInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

double _toDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Representa el resumen de KPIs globales de inventario devueltos por
/// el endpoint `/api/inventario/resumen` (CU10).
class ResumenInventario {
  final int totalStock;
  final int totalPrendas;
  final int totalVariantes;
  final int totalOptimo;
  final int totalBajo;
  final int totalAgotado;
  final List<ResumenSucursalInventario> sucursales;

  const ResumenInventario({
    required this.totalStock,
    required this.totalPrendas,
    required this.totalVariantes,
    required this.totalOptimo,
    required this.totalBajo,
    required this.totalAgotado,
    required this.sucursales,
  });

  factory ResumenInventario.fromJson(Map<String, dynamic> json) {
    final sucursalesRaw = (json['sucursales'] ?? json['por_sucursal']) as List? ?? [];
    final listaSucursales = sucursalesRaw
        .whereType<Map<String, dynamic>>()
        .map((s) => ResumenSucursalInventario.fromJson(s))
        .toList();

    return ResumenInventario(
      totalStock: _toInt(json['total_stock_global'] ?? json['total_stock']),
      totalPrendas: _toInt(json['total_prendas_distintas'] ?? json['total_prendas']),
      totalVariantes: _toInt(json['total_variantes']),
      totalOptimo: _toInt(json['variantes_optimo'] ?? json['total_optimo']),
      totalBajo: _toInt(json['variantes_bajo_stock'] ?? json['variantes_bajo'] ?? json['total_bajo']),
      totalAgotado: _toInt(json['variantes_agotadas'] ?? json['variantes_agotado'] ?? json['total_agotado']),
      sucursales: listaSucursales,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_stock': totalStock,
        'total_stock_global': totalStock,
        'total_prendas': totalPrendas,
        'total_prendas_distintas': totalPrendas,
        'total_variantes': totalVariantes,
        'total_optimo': totalOptimo,
        'variantes_optimo': totalOptimo,
        'total_bajo': totalBajo,
        'variantes_bajo_stock': totalBajo,
        'total_agotado': totalAgotado,
        'variantes_agotadas': totalAgotado,
        'sucursales': sucursales.map((s) => s.toJson()).toList(),
      };
}

/// Métricas de inventario agrupadas por sucursal física individual.
class ResumenSucursalInventario {
  final int idSucursal;
  final String sucursal;
  final String ciudad;
  final int totalStock;
  final int totalVariantes;
  final int totalOptimo;
  final int totalBajo;
  final int totalAgotado;

  const ResumenSucursalInventario({
    required this.idSucursal,
    required this.sucursal,
    required this.ciudad,
    required this.totalStock,
    this.totalVariantes = 0,
    this.totalOptimo = 0,
    this.totalBajo = 0,
    this.totalAgotado = 0,
  });

  factory ResumenSucursalInventario.fromJson(Map<String, dynamic> json) {
    return ResumenSucursalInventario(
      idSucursal: _toInt(json['id_sucursal']),
      sucursal: (json['nombre_sucursal'] ?? json['sucursal'] ?? '').toString(),
      ciudad: (json['ciudad'] ?? '').toString(),
      totalStock: _toInt(json['total_stock']),
      totalVariantes: _toInt(json['total_variantes']),
      totalOptimo: _toInt(json['variantes_optimo'] ?? json['total_optimo']),
      totalBajo: _toInt(json['variantes_bajo'] ?? json['total_bajo']),
      totalAgotado: _toInt(json['variantes_agotadas'] ?? json['total_agotado']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id_sucursal': idSucursal,
        'sucursal': sucursal,
        'nombre_sucursal': sucursal,
        'ciudad': ciudad,
        'total_stock': totalStock,
        'total_variantes': totalVariantes,
        'total_optimo': totalOptimo,
        'variantes_optimo': totalOptimo,
        'total_bajo': totalBajo,
        'variantes_bajo': totalBajo,
        'total_agotado': totalAgotado,
        'variantes_agotadas': totalAgotado,
      };
}

/// Representa una fila individual de existencias devuelta por `/api/inventario/monitoreo`.
class MonitoreoItem {
  final int? idInventario;
  final int idSucursal;
  final String sucursal;
  final String ciudad;
  final int idPrenda;
  final String skuPrenda;
  final String nombrePrenda;
  final int? idCategoria;
  final String? categoria;
  final int? idTemporada;
  final String? temporada;
  final int idVariantePrenda;
  final String skuVariante;
  final String? talla;
  final String? color;
  final String? codigoHex;
  final double precio;
  final int stock;
  final String estadoStock; // 'Optimo', 'Bajo', 'Agotado'
  final String colorBadge; // 'verde', 'amarillo', 'rojo'

  const MonitoreoItem({
    this.idInventario,
    required this.idSucursal,
    required this.sucursal,
    required this.ciudad,
    required this.idPrenda,
    required this.skuPrenda,
    required this.nombrePrenda,
    this.idCategoria,
    this.categoria,
    this.idTemporada,
    this.temporada,
    required this.idVariantePrenda,
    required this.skuVariante,
    this.talla,
    this.color,
    this.codigoHex,
    required this.precio,
    required this.stock,
    required this.estadoStock,
    required this.colorBadge,
  });

  factory MonitoreoItem.fromJson(Map<String, dynamic> json) {
    final stockVal = _toInt(json['stock']);

    // Clasificación de respaldo si el backend no envía el estado explícito
    String estado = (json['estado_stock'] ?? '').toString();
    if (estado.isEmpty) {
      if (stockVal >= 5) {
        estado = 'Optimo';
      } else if (stockVal > 0) {
        estado = 'Bajo';
      } else {
        estado = 'Agotado';
      }
    }

    String badge = (json['color_badge'] ?? '').toString();
    if (badge.isEmpty) {
      if (stockVal >= 5) {
        badge = 'verde';
      } else if (stockVal > 0) {
        badge = 'amarillo';
      } else {
        badge = 'rojo';
      }
    }

    final precioBase = _toDouble(json['precio_base']);
    final precioAdicional = _toDouble(json['precio_adicional']);
    final precioFinal = json['precio'] != null
        ? _toDouble(json['precio'])
        : (precioBase + precioAdicional);

    return MonitoreoItem(
      idInventario: json['id_inventario'] != null ? _toInt(json['id_inventario']) : null,
      idSucursal: _toInt(json['id_sucursal']),
      sucursal: (json['nombre_sucursal'] ?? json['sucursal'] ?? '').toString(),
      ciudad: (json['ciudad'] ?? '').toString(),
      idPrenda: _toInt(json['id_prenda']),
      skuPrenda: (json['sku_prenda'] ?? json['prenda_sku'] ?? '').toString(),
      nombrePrenda: (json['nombre_prenda'] ?? json['prenda_nombre'] ?? '').toString(),
      idCategoria: json['id_categoria'] != null ? _toInt(json['id_categoria']) : null,
      categoria: (json['nombre_categoria'] ?? json['categoria'])?.toString(),
      idTemporada: json['id_temporada'] != null ? _toInt(json['id_temporada']) : null,
      temporada: (json['nombre_temporada'] ?? json['temporada'])?.toString(),
      idVariantePrenda: _toInt(json['id_variante_prenda']),
      skuVariante: (json['sku_variante'] ?? json['sku'] ?? '').toString(),
      talla: json['talla']?.toString(),
      color: json['color']?.toString(),
      codigoHex: json['codigo_hex']?.toString(),
      precio: precioFinal,
      stock: stockVal,
      estadoStock: estado,
      colorBadge: badge,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_inventario': idInventario,
        'id_sucursal': idSucursal,
        'sucursal': sucursal,
        'nombre_sucursal': sucursal,
        'ciudad': ciudad,
        'id_prenda': idPrenda,
        'prenda_sku': skuPrenda,
        'sku_prenda': skuPrenda,
        'prenda_nombre': nombrePrenda,
        'nombre_prenda': nombrePrenda,
        'id_categoria': idCategoria,
        'categoria': categoria,
        'nombre_categoria': categoria,
        'id_temporada': idTemporada,
        'temporada': temporada,
        'nombre_temporada': temporada,
        'id_variante_prenda': idVariantePrenda,
        'sku_variante': skuVariante,
        'sku': skuVariante,
        'talla': talla,
        'color': color,
        'codigo_hex': codigoHex,
        'precio': precio,
        'stock': stock,
        'estado_stock': estadoStock,
        'color_badge': colorBadge,
      };
}

/// Existencia física en una sucursal para el desglose de una variante.
class DesgloseSucursal {
  final int idSucursal;
  final String nombreSucursal;
  final String ciudad;
  final int stock;
  final String estadoStock;

  const DesgloseSucursal({
    required this.idSucursal,
    required this.nombreSucursal,
    required this.ciudad,
    required this.stock,
    required this.estadoStock,
  });

  factory DesgloseSucursal.fromItem(MonitoreoItem item) {
    return DesgloseSucursal(
      idSucursal: item.idSucursal,
      nombreSucursal: item.sucursal,
      ciudad: item.ciudad,
      stock: item.stock,
      estadoStock: item.estadoStock,
    );
  }
}

/// Variante de prenda agrupada con el total acumulado de existencias y su desglose físico.
class VarianteAgrupadaInventario {
  final int idVariantePrenda;
  final String skuVariante;
  final int idPrenda;
  final String nombrePrenda;
  final String skuPrenda;
  final String? categoria;
  final String? temporada;
  final String? talla;
  final String? color;
  final String? codigoHex;
  final double precio;
  final int stockTotal;
  final String estadoStock; // 'Optimo', 'Bajo', 'Agotado'
  final List<DesgloseSucursal> desgloseSucursales;

  const VarianteAgrupadaInventario({
    required this.idVariantePrenda,
    required this.skuVariante,
    required this.idPrenda,
    required this.nombrePrenda,
    required this.skuPrenda,
    this.categoria,
    this.temporada,
    this.talla,
    this.color,
    this.codigoHex,
    required this.precio,
    required this.stockTotal,
    required this.estadoStock,
    required this.desgloseSucursales,
  });

  /// Agrupa una lista plana de [MonitoreoItem] por variante (`idVariantePrenda`).
  static List<VarianteAgrupadaInventario> agrupar(List<MonitoreoItem> items) {
    final mapa = <int, List<MonitoreoItem>>{};
    for (final item in items) {
      mapa.putIfAbsent(item.idVariantePrenda, () => []).add(item);
    }

    final resultado = <VarianteAgrupadaInventario>[];
    for (final entry in mapa.entries) {
      final subItems = entry.value;
      final primerItem = subItems.first;
      final sumaStock = subItems.fold<int>(0, (sum, it) => sum + it.stock);

      String estado;
      if (sumaStock >= 5) {
        estado = 'Optimo';
      } else if (sumaStock > 0) {
        estado = 'Bajo';
      } else {
        estado = 'Agotado';
      }

      final desgloses = subItems.map(DesgloseSucursal.fromItem).toList();

      resultado.add(
        VarianteAgrupadaInventario(
          idVariantePrenda: entry.key,
          skuVariante: primerItem.skuVariante,
          idPrenda: primerItem.idPrenda,
          nombrePrenda: primerItem.nombrePrenda,
          skuPrenda: primerItem.skuPrenda,
          categoria: primerItem.categoria,
          temporada: primerItem.temporada,
          talla: primerItem.talla,
          color: primerItem.color,
          codigoHex: primerItem.codigoHex,
          precio: primerItem.precio,
          stockTotal: sumaStock,
          estadoStock: estado,
          desgloseSucursales: desgloses,
        ),
      );
    }

    return resultado;
  }
}

/// Configuración de colores y estilos para el badge cromático de 3 estados:
/// - Óptimo (>= 5 u.): Verde esmeralda (fsEmerald)
/// - Bajo (1-4 u.): Ámbar oscuro (Color(0xFFB45309))
/// - Agotado (0 u.): Rojo vino (fsDanger)
class BadgeStockStyle {
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final String label;

  const BadgeStockStyle({
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.label,
  });

  factory BadgeStockStyle.fromStock(int stock, [String? estado]) {
    final est = (estado ?? '').toLowerCase();
    if (est.contains('optimo') || est.contains('óptimo') || stock >= 5) {
      return const BadgeStockStyle(
        textColor: fsEmerald,
        backgroundColor: Color(0xFFE9F1EC),
        borderColor: Color(0xFFCBE0D3),
        label: 'Óptimo',
      );
    } else if (est.contains('bajo') || (stock >= 1 && stock <= 4)) {
      return const BadgeStockStyle(
        textColor: Color(0xFFB45309),
        backgroundColor: Color(0xFFFEF3C7),
        borderColor: Color(0xFFFDE68A),
        label: 'Bajo Stock',
      );
    } else {
      return const BadgeStockStyle(
        textColor: fsDanger,
        backgroundColor: fsDangerWash,
        borderColor: Color(0xFFEBD8D8),
        label: 'Agotado',
      );
    }
  }
}

/// Widget reutilizable del badge cromático de 3 estados para monitoreo.
Widget badgeEstadoInventario(int stock, {String? estado, bool mostrarUnidades = true}) {
  final style = BadgeStockStyle.fromStock(stock, estado);
  final texto = mostrarUnidades ? '${style.label} ($stock u.)' : style.label;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: style.backgroundColor,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: style.borderColor),
    ),
    child: Text(
      texto,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: style.textColor,
      ),
    ),
  );
}
