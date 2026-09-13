import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../services/movimiento_service.dart';
import 'models/movimiento_models.dart';

/// Formulario para el Registro Manual de Movimientos de Inventario (CU11).
///
/// Incluye selector dinámico de sucursal y variante, consulta en tiempo real
/// del stock físico disponible, validación interactiva ante salidas excesivas y
/// captura de la excepción del trigger PL/pgSQL (HTTP 400).
class RegistrarMovimientoScreen extends StatefulWidget {
  final MovimientoService? servicio;

  const RegistrarMovimientoScreen({super.key, this.servicio});

  @override
  State<RegistrarMovimientoScreen> createState() =>
      _RegistrarMovimientoScreenState();
}

class _RegistrarMovimientoScreenState extends State<RegistrarMovimientoScreen> {
  late final MovimientoService _servicio;
  final _formKey = GlobalKey<FormState>();

  final _cantidadCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();

  List<SucursalOpcion> _sucursales = [];
  List<VarianteOpcion> _variantes = [];

  int? _idSucursalSeleccionada;
  int? _idVarianteSeleccionada;
  String _tipoSeleccionado = 'Entrada';

  int? _stockActual;
  bool _consultandoStock = false;
  bool _cargandoInicial = true;
  bool _enviando = false;

  String? _errorServidor;
  String? _advertenciaStock;

  final List<String> _tiposMovimiento = ['Entrada', 'Salida', 'Traspaso'];

  @override
  void initState() {
    super.initState();
    _servicio = widget.servicio ?? MovimientoService();
    _cargarDatosIniciales();
    _cantidadCtrl.addListener(_validarStockInteractivo);
  }

  @override
  void dispose() {
    _cantidadCtrl.removeListener(_validarStockInteractivo);
    _cantidadCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _cargandoInicial = true;
      _errorServidor = null;
    });

    try {
      final sucursales = await _servicio.listarSucursales();
      final variantes = await _servicio.listarVariantesCatalogo();

      if (!mounted) return;
      setState(() {
        _sucursales = sucursales;
        _variantes = variantes;
        if (_sucursales.isNotEmpty) {
          _idSucursalSeleccionada = _sucursales.first.idSucursal;
        }
        if (_variantes.isNotEmpty) {
          _idVarianteSeleccionada = _variantes.first.idVariantePrenda;
        }
      });

      if (_idSucursalSeleccionada != null && _idVarianteSeleccionada != null) {
        await _actualizarStockActual();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorServidor = 'No se pudieron cargar las sucursales o variantes.';
      });
    } finally {
      if (mounted) setState(() => _cargandoInicial = false);
    }
  }

  Future<void> _actualizarStockActual() async {
    final suc = _idSucursalSeleccionada;
    final varP = _idVarianteSeleccionada;
    if (suc == null || varP == null) return;

    setState(() => _consultandoStock = true);
    try {
      final stock = await _servicio.consultarStock(
        idSucursal: suc,
        idVariantePrenda: varP,
      );
      if (!mounted) return;
      setState(() {
        _stockActual = stock;
        _consultandoStock = false;
      });
      _validarStockInteractivo();
    } catch (_) {
      if (mounted) setState(() => _consultandoStock = false);
    }
  }

  void _validarStockInteractivo() {
    final cantTexto = _cantidadCtrl.text.trim();
    final cant = int.tryParse(cantTexto) ?? 0;
    final stock = _stockActual ?? 0;

    String? nuevaAdvertencia;
    if ((_tipoSeleccionado == 'Salida' || _tipoSeleccionado == 'Traspaso') &&
        cant > stock &&
        cant > 0) {
      nuevaAdvertencia =
          'Atención: La cantidad ingresada ($cant) supera el stock disponible ($stock) en la sucursal seleccionada.';
    }

    if (_advertenciaStock != nuevaAdvertencia) {
      setState(() => _advertenciaStock = nuevaAdvertencia);
    }
  }

  Future<void> _enviar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_idSucursalSeleccionada == null || _idVarianteSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Seleccione una sucursal y una variante de prenda.')),
      );
      return;
    }

    setState(() {
      _enviando = true;
      _errorServidor = null;
    });

    try {
      final payload = MovimientoCrear(
        idSucursal: _idSucursalSeleccionada!,
        idVariantePrenda: _idVarianteSeleccionada!,
        tipo: _tipoSeleccionado,
        cantidad: int.parse(_cantidadCtrl.text.trim()),
        motivo: _motivoCtrl.text.trim(),
      );

      await _servicio.registrar(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Movimiento de $_tipoSeleccionado registrado exitosamente.'),
          backgroundColor: fsEmerald,
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      // Captura y traducción de la excepción PL/pgSQL
      setState(() => _errorServidor = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorServidor =
          'Error al contactar con el servidor. Verifique la conexión.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Movimiento'),
      ),
      body: _cargandoInicial
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Banner de error o excepción PL/pgSQL
                    if (_errorServidor != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: fsDangerWash,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFEBD8D8)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline,
                                color: fsDanger, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Excepción de inventario',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: fsDanger,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _errorServidor!,
                                    style: const TextStyle(
                                        color: fsDanger, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Banner interactivo de advertencia preventiva de stock
                    if (_advertenciaStock != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: fsGoldWash,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: fsGold),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: fsGoldDeep, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _advertenciaStock!,
                                style: const TextStyle(
                                  color: fsGoldDeep,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Selector de Sucursal
                    DropdownButtonFormField<int>(
                      initialValue: _idSucursalSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Sucursal física',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                      items: _sucursales.map((s) {
                        return DropdownMenuItem<int>(
                          value: s.idSucursal,
                          child: Text(
                            s.nombre +
                                (s.ciudad != null ? ' (${s.ciudad})' : ''),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _idSucursalSeleccionada = val);
                        _actualizarStockActual();
                      },
                      validator: (v) =>
                          v == null ? 'Seleccione una sucursal.' : null,
                    ),
                    const SizedBox(height: 16),

                    // Selector de Variante de Prenda
                    DropdownButtonFormField<int>(
                      initialValue: _idVarianteSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Prenda y variante (SKU)',
                        prefixIcon: Icon(Icons.checkroom_outlined),
                      ),
                      items: _variantes.map((v) {
                        return DropdownMenuItem<int>(
                          value: v.idVariantePrenda,
                          child: Text(
                            v.etiquetaCompleta,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _idVarianteSeleccionada = val);
                        _actualizarStockActual();
                      },
                      validator: (v) =>
                          v == null ? 'Seleccione una variante.' : null,
                    ),
                    const SizedBox(height: 8),

                    // Indicador de Stock Físico Disponible
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: fsSurfaceAlt,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: fsBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory,
                              size: 16, color: fsInkSoft),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _consultandoStock
                                  ? 'Consultando stock disponible…'
                                  : 'Stock disponible en sucursal: ${_stockActual ?? 0} uds.',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: fsInkSoft,
                              ),
                            ),
                          ),
                          if (_consultandoStock)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selector de Tipo de Movimiento
                    DropdownButtonFormField<String>(
                      initialValue: _tipoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de movimiento',
                        prefixIcon: Icon(Icons.swap_horiz_outlined),
                      ),
                      items: _tiposMovimiento.map((t) {
                        return DropdownMenuItem<String>(
                          value: t,
                          child: Text(t),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _tipoSeleccionado = val);
                          _validarStockInteractivo();
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo de Cantidad
                    TextFormField(
                      controller: _cantidadCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad de unidades',
                        hintText: 'Ej. 25',
                        prefixIcon: Icon(Icons.numbers_outlined),
                      ),
                      validator: (v) {
                        final val = v?.trim() ?? '';
                        if (val.isEmpty) return 'Ingrese la cantidad.';
                        final numVal = int.tryParse(val);
                        if (numVal == null || numVal <= 0) {
                          return 'La cantidad debe ser un entero positivo mayor a cero.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo de Motivo
                    TextFormField(
                      controller: _motivoCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Motivo o justificación',
                        hintText:
                            'Ej. Ajuste de inventario físico, reposición, merma…',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      validator: (v) {
                        final val = v?.trim() ?? '';
                        if (val.isEmpty) return 'Ingrese el motivo.';
                        if (val.length < 3) {
                          return 'El motivo debe tener al menos 3 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Botón de Envío
                    FilledButton(
                      onPressed: _enviando ? null : _enviar,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _enviando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: fsSurface,
                              ),
                            )
                          : const Text(
                              'CONFIRMAR MOVIMIENTO',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
