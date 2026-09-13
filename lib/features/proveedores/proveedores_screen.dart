import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../services/proveedor_service.dart';
import 'models/proveedor_models.dart';

/// Directorio de Proveedores para el personal de almacén y tienda (CU12).
///
/// Permite la búsqueda ágil y consulta de fichas comerciales de proveedores
/// por NIT o Razón Social.
class ProveedoresScreen extends StatefulWidget {
  final ProveedorService? servicio;

  const ProveedoresScreen({super.key, this.servicio});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  late final ProveedorService _servicio;
  final _busquedaCtrl = TextEditingController();

  List<Proveedor> _proveedores = [];
  bool _cargando = true;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _servicio = widget.servicio ?? ProveedorService();
    _consultar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _consultar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final busqueda = _busquedaCtrl.text.trim();
      final lista = await _servicio.listar(
        busqueda: busqueda.isEmpty ? null : busqueda,
      );
      if (!mounted) return;
      setState(() {
        _proveedores = lista;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Error de conexión al cargar proveedores.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _alBuscar(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _consultar();
    });
  }

  void _mostrarDetalle(Proveedor p) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: fsSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      p.razonSocial,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: fsInk,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: fsGoldWash,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: fsGold),
                    ),
                    child: Text(
                      'NIT: ${p.nit}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: fsGoldDeep,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: fsBorder),
              const SizedBox(height: 12),
              _filaDetalle(Icons.person_outline, 'Contacto',
                  p.contacto ?? 'No especificado'),
              const SizedBox(height: 12),
              _filaDetalle(Icons.phone_outlined, 'Teléfono',
                  p.telefono ?? 'No registrado'),
              const SizedBox(height: 12),
              _filaDetalle(Icons.email_outlined, 'Correo electrónico',
                  p.correo ?? 'No registrado'),
              const SizedBox(height: 12),
              _filaDetalle(Icons.location_on_outlined, 'Dirección',
                  p.direccion ?? 'Sin dirección registrada'),
              if (p.createdAt != null) ...[
                const SizedBox(height: 12),
                _filaDetalle(
                  Icons.calendar_today_outlined,
                  'Fecha de registro',
                  '${p.createdAt!.day.toString().padLeft(2, '0')}/${p.createdAt!.month.toString().padLeft(2, '0')}/${p.createdAt!.year}',
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filaDetalle(IconData icono, String etiqueta, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 20, color: fsInkSoft),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: const TextStyle(
                  fontSize: 11,
                  color: fsInkMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: fsInk,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directorio de Proveedores'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _busquedaCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por NIT o Razón Social…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busquedaCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _busquedaCtrl.clear();
                          _consultar();
                        },
                      )
                    : null,
              ),
              onChanged: _alBuscar,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
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
                      child: Text(
                        _error!,
                        style: const TextStyle(color: fsDanger, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: _consultar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _consultar,
              color: fsGold,
              child: _contenido(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenido() {
    if (_cargando && _proveedores.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_proveedores.isEmpty && _error == null) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Icon(Icons.business_outlined, size: 48, color: fsInkMuted),
                SizedBox(height: 12),
                Text(
                  'No se encontraron proveedores registrados.',
                  style: TextStyle(color: fsInkMuted, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _proveedores.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final p = _proveedores[i];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: fsBorder),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _mostrarDetalle(p),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          p.razonSocial,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: fsInk,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: fsGoldWash,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: fsGold),
                        ),
                        child: Text(
                          'NIT ${p.nit}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: fsGoldDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (p.contacto != null && p.contacto!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 14, color: fsInkMuted),
                        const SizedBox(width: 6),
                        Text(
                          p.contacto!,
                          style:
                              const TextStyle(fontSize: 13, color: fsInkSoft),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      if (p.telefono != null && p.telefono!.isNotEmpty) ...[
                        const Icon(Icons.phone_outlined,
                            size: 14, color: fsInkMuted),
                        const SizedBox(width: 6),
                        Text(
                          p.telefono!,
                          style:
                              const TextStyle(fontSize: 13, color: fsInkSoft),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (p.correo != null && p.correo!.isNotEmpty) ...[
                        const Icon(Icons.email_outlined,
                            size: 14, color: fsInkMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            p.correo!,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontSize: 13, color: fsInkSoft),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (p.direccion != null && p.direccion!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: fsInkMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            p.direccion!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontSize: 12, color: fsInkMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
