import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/models/catalogo_models.dart';
import '../../core/models/venta_models.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/auth_service.dart';
import '../../services/carrito_service.dart';
import '../../services/catalogo_service.dart';
import '../../services/venta_service.dart';
import '../ar/vestidor_virtual_screen.dart';
import '../carrito/carrito_screen.dart';
import '../ia/models/tryon_model.dart';
import '../ia/services/ia_service.dart';
import '../reservas/ticket_reserva_screen.dart';

/// Ficha de una prenda con su disponibilidad por sucursal (CU14).
///
/// Consume GET /api/catalogo/{id}, que ya incluye el desglose de stock por
/// sucursal para cada combinación de talla y color.
class PrendaDetalleScreen extends StatefulWidget {
  final int idPrenda;
  final ImagePicker? imagePicker;
  final IAService? iaService;

  const PrendaDetalleScreen({
    super.key,
    required this.idPrenda,
    this.imagePicker,
    this.iaService,
  });

  @override
  State<PrendaDetalleScreen> createState() => _PrendaDetalleScreenState();
}

class _PrendaDetalleScreenState extends State<PrendaDetalleScreen> {
  final CatalogoService _servicio = CatalogoService();
  late final ImagePicker _picker = widget.imagePicker ?? ImagePicker();
  late final IAService _iaService = widget.iaService ?? IAService();

  PrendaCatalogo? _prenda;
  VarianteCatalogo? _varianteSeleccionada;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final prenda = await _servicio.obtenerFicha(widget.idPrenda);
      if (!mounted) return;
      setState(() {
        _prenda = prenda;
        if (prenda.variantes.isNotEmpty) {
          _varianteSeleccionada = prenda.variantes.first;
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo contactar con el servidor.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_prenda?.nombre ?? 'Detalle de prenda'),
        actions: [
          AnimatedBuilder(
            animation: CarritoService.instance,
            builder: (context, _) {
              final cant = CarritoService.instance.totalItems;
              return IconButton(
                icon: Badge(
                  isLabelVisible: cant > 0,
                  label: Text('$cant'),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CarritoScreen()),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _contenido(),
    );
  }

  Widget _contenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: fsDanger, size: 32),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: fsDanger),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final p = _prenda!;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        AspectRatio(aspectRatio: 4 / 3, child: redImagen(p.urlImagen)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${p.categoria ?? 'Sin categoría'} · ${p.genero ?? '—'}',
                style: const TextStyle(fontSize: 11, letterSpacing: 1.4, color: fsInkMuted),
              ),
              const SizedBox(height: 6),
              Text(
                p.nombre,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (p.marca != null && p.marca!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(p.marca!, style: const TextStyle(color: fsInkSoft)),
              ],
              const SizedBox(height: 8),
              Text(
                formatearPrecio(p.precioBase),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              if (p.descripcion != null && p.descripcion!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  p.descripcion!,
                  style: const TextStyle(color: fsInkSoft, height: 1.5),
                ),
              ],
              if (p.sku.startsWith('3D-') || (p.descripcion != null && p.descripcion!.contains('[3D:'))) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B4B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF6366F1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.view_in_ar_rounded, color: Color(0xFF818CF8), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        p.descripcion?.contains('RIGGED: true') ?? false
                            ? 'Malla 3D Articulada Rigged (Con Huesos)'
                            : 'Modelo 3D Texturizado Real PBR',
                        style: const TextStyle(
                          color: Color(0xFFC7D2FE),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('btn_tryon_fotorealista'),
                  icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                  label: const Text(
                    'Generar Try-On Fotorealista (IA)',
                    style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: fsInk,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _mostrarSelectorOrigenFoto(p),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.view_in_ar_rounded, color: Colors.white, size: 20),
                  label: Text(
                    p.sku.startsWith('3D-')
                        ? 'Probar Modelo 3D en Vestidor (AR)'
                        : 'Probar en Vestidor Virtual (AR)',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.sku.startsWith('3D-') ? const Color(0xFF4F46E5) : fsEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VestidorVirtualScreen(prenda: p),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // --- SELECTOR DE VARIANTE (TALLA Y COLOR) ---
              if (p.variantes.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  initialValue: _varianteSeleccionada?.idVariantePrenda ?? p.variantes.first.idVariantePrenda,
                  decoration: InputDecoration(
                    labelText: 'Seleccionar Talla y Color',
                    labelStyle: const TextStyle(fontSize: 13, color: fsInkMuted),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: fsBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: fsBorder),
                    ),
                  ),
                  items: p.variantes.map((v) {
                    final stock = v.stockTotal;
                    final stockTxt = stock > 0 ? '($stock disp.)' : '(Agotado)';
                    return DropdownMenuItem<int>(
                      value: v.idVariantePrenda,
                      child: Text(
                        '${v.talla ?? 'U'} / ${v.color ?? 'Color'} - ${formatearPrecio(v.precio)} $stockTxt',
                        style: TextStyle(
                          fontSize: 13,
                          color: stock > 0 ? fsInk : fsInkMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _varianteSeleccionada = p.variantes.firstWhere((v) => v.idVariantePrenda == val);
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
              // --- BOTÓN PRINCIPAL: AGREGAR AL CARRITO DE COMPRAS ---
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('btn_agregar_carrito_detalle'),
                  icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 20),
                  label: Text(
                    p.stockTotal > 0 ? 'Agregar al Carrito de Compras' : 'Prenda Agotada',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.3),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: p.stockTotal > 0 ? fsGold : fsInkMuted,
                    foregroundColor: fsInk,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: p.stockTotal <= 0
                      ? null
                      : () {
                          final v = _varianteSeleccionada ?? (p.variantes.isNotEmpty ? p.variantes.first : null);
                          if (v == null) return;

                          CarritoService.instance.agregarItem(
                            CarritoItem(
                              idVariantePrenda: v.idVariantePrenda,
                              skuVariante: p.sku,
                              prendaNombre: p.nombre,
                              talla: v.talla,
                              color: v.color,
                              precioUnitario: (v.precio as num).toDouble(),
                            ),
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: fsInk,
                              content: Text(
                                '¡${p.nombre} (${v.talla ?? 'U'} / ${v.color ?? 'U'}) agregado al carrito!',
                                style: const TextStyle(color: Colors.white),
                              ),
                              duration: const Duration(seconds: 3),
                              action: SnackBarAction(
                                label: 'VER CARRITO',
                                textColor: fsGold,
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const CarritoScreen()),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: fsBorder),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DISPONIBILIDAD POR SUCURSAL',
                style: TextStyle(fontSize: 11, letterSpacing: 1.4, color: fsInkMuted),
              ),
              const SizedBox(height: 12),
              if (p.variantes.isEmpty)
                const Text(
                  'Esta prenda no tiene variantes registradas.',
                  style: TextStyle(color: fsInkSoft),
                )
              else
                ...p.variantes.map(_varianteCard),
            ],
          ),
        ),
      ],
    );
  }

  Widget _varianteCard(VarianteCatalogo v) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: fsBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${v.talla ?? '—'} / ${v.color ?? '—'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  formatearPrecio(v.precio),
                  style: const TextStyle(color: fsInkSoft, fontSize: 13),
                ),
                const SizedBox(width: 10),
                badgeStock(v.stockTotal),
              ],
            ),
            const SizedBox(height: 10),
            if (v.disponibilidad.isEmpty)
              const Text(
                'Sin stock en ninguna sucursal.',
                style: TextStyle(color: fsInkMuted, fontSize: 13),
              )
            else
              ...v.disponibilidad.map((s) => _filaSucursal(v, s)),
          ],
        ),
      ),
    );
  }

  Widget _filaSucursal(VarianteCatalogo v, StockSucursal s) {
    final tieneStock = s.stock > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.storefront_outlined, size: 18, color: fsInkMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.sucursal, style: const TextStyle(fontWeight: FontWeight.w500)),
                if (s.ciudad != null && s.ciudad!.isNotEmpty)
                  Text(s.ciudad!, style: const TextStyle(fontSize: 12, color: fsInkMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${s.stock} u. disponibles',
                style: TextStyle(
                  color: tieneStock ? fsEmerald : fsInkMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              if (tieneStock) ...[
                const SizedBox(height: 4),
                SizedBox(
                  height: 26,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.door_front_door_outlined, size: 12),
                    label: const Text('Probar en tienda', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                    style: FilledButton.styleFrom(
                      backgroundColor: fsInk,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    onPressed: () => _confirmarReservaProbador(v, s),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _confirmarReservaProbador(VarianteCatalogo v, StockSucursal s) {
    final p = _prenda;
    if (p == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        bool enviando = false;
        String? errorModal;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reserva para Probador (CU16)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Se separará 1 unidad de "${p.nombre}" en la sucursal seleccionada por 2 horas para que te la pruebes físicamente.',
                    style: const TextStyle(color: fsInkSoft, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: fsSurfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: fsBorder),
                    ),
                    child: Column(
                      children: [
                        _filaDetalleModal('Prenda:', p.nombre),
                        const SizedBox(height: 4),
                        _filaDetalleModal('Talla / Color:', '${v.talla ?? 'U'} / ${v.color ?? 'U'}'),
                        const SizedBox(height: 4),
                        _filaDetalleModal('Sucursal:', s.sucursal),
                        const SizedBox(height: 4),
                        _filaDetalleModal('Precio:', formatearPrecio(v.precio)),
                        const SizedBox(height: 4),
                        _filaDetalleModal('Vigencia:', '2 horas tras confirmar'),
                      ],
                    ),
                  ),
                  if (errorModal != null) ...[
                    const SizedBox(height: 12),
                    Text(errorModal!, style: const TextStyle(color: fsDanger, fontSize: 12)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 46,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: fsInk,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: enviando
                          ? null
                          : () async {
                              setModalState(() {
                                enviando = true;
                                errorModal = null;
                              });

                              try {
                                final claims = AuthService.instance.tokenClaims;
                                int idCliente = 61;
                                if (claims != null) {
                                  if (claims['id_cliente'] != null) {
                                    idCliente = (claims['id_cliente'] as num).toInt();
                                  } else if (claims['id_usuario'] != null) {
                                    idCliente = (claims['id_usuario'] as num).toInt();
                                  }
                                }

                                final ticket = await VentaService().crearReservaProbador(
                                  ReservaProbadorPeticion(
                                    idCliente: idCliente,
                                    idSucursal: s.idSucursal,
                                    horasVigencia: 2,
                                    items: [
                                      DetalleReservaItem(
                                        idVariantePrenda: v.idVariantePrenda,
                                        cantidad: 1,
                                        precioUnitario: (v.precio as num).toDouble(),
                                      ),
                                    ],
                                  ),
                                );

                                if (!ctx.mounted) return;
                                Navigator.of(ctx).pop();

                                if (!mounted) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TicketReservaScreen(ticketInicial: ticket),
                                  ),
                                );
                              } catch (err) {
                                setModalState(() {
                                  enviando = false;
                                  errorModal = err.toString();
                                });
                              }
                            },
                      child: enviando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Confirmar Reserva de Probador →'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _filaDetalleModal(String etiqueta, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(etiqueta, style: const TextStyle(fontSize: 12, color: fsInkSoft)),
        Text(valor, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // =========================================================================
  // FLUJO DE VESTIDOR VIRTUAL FOTOREALISTA CON IA (FASE 2)
  // =========================================================================

  void _mostrarSelectorOrigenFoto(PrendaCatalogo prenda) {
    showModalBottomSheet(
      context: context,
      backgroundColor: fsSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: fsGoldDeep, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Probador Fotorealista (IA)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  IconButton(
                    key: const Key('btn_cerrar_selector_foto'),
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Captura una fotografía de tu torso con buena luz o elígela de tu galería para probarte la prenda.',
                style: TextStyle(color: fsInkSoft, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ListTile(
                key: const Key('tile_origen_camara'),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: fsGoldWash,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: fsGoldDeep),
                ),
                title: const Text('Tomar fotografía', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Usa la cámara del dispositivo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _procesarCaptura(prenda, ImageSource.camera);
                },
              ),
              const Divider(height: 1),
              ListTile(
                key: const Key('tile_origen_galeria'),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: fsSurfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: fsInk),
                ),
                title: const Text('Elegir de la galería', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Selecciona una imagen guardada'),
                onTap: () {
                  Navigator.pop(ctx);
                  _procesarCaptura(prenda, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _procesarCaptura(PrendaCatalogo prenda, ImageSource origen) async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: origen,
        maxWidth: 1200,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (foto == null) return;
      if (!mounted) return;

      final bytesOriginales = await foto.readAsBytes();
      final fotoBase64 = base64Encode(bytesOriginales);
      final fotoUsuarioDataUri = 'data:image/jpeg;base64,$fotoBase64';

      if (!mounted) return;

      // Diálogo de progreso multi-etapa
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const DialogoProgresoTryOn(),
      );

      try {
        final respuesta = await _iaService.generarTryOn(
          TryOnPeticion(
            idPrenda: prenda.idPrenda,
            fotoUsuario: fotoUsuarioDataUri,
            usarIaGenerativa: true,
          ),
        );

        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();

        final raw = respuesta.imagenResultado.contains(',')
            ? respuesta.imagenResultado.split(',').last
            : respuesta.imagenResultado;
        final bytesResultado = base64Decode(raw.trim());

        if (!mounted) return;

        showDialog(
          context: context,
          useSafeArea: false,
          builder: (_) => TryOnVisorModal(
            imagenBytes: bytesResultado,
            fotoOriginalBytes: bytesOriginales,
            prenda: prenda,
            tiempoMs: respuesta.tiempoProcesamientoMs,
            mensaje: respuesta.mensaje,
            onReservar: _iniciarReservaDesdeTryOn,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();

        final mensajeError = e is ApiException
            ? e.message
            : 'Error al procesar el Try-On con IA: $e';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeError),
            backgroundColor: fsDanger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al capturar la imagen: $e'),
          backgroundColor: fsDanger,
        ),
      );
    }
  }

  void _iniciarReservaDesdeTryOn() {
    final p = _prenda;
    if (p == null) return;

    VarianteCatalogo? varianteConStock;
    StockSucursal? sucursalConStock;

    for (final v in p.variantes) {
      for (final s in v.disponibilidad) {
        if (s.stock > 0) {
          varianteConStock = v;
          sucursalConStock = s;
          break;
        }
      }
      if (varianteConStock != null) break;
    }

    if (varianteConStock != null && sucursalConStock != null) {
      _confirmarReservaProbador(varianteConStock, sucursalConStock);
    } else if (p.variantes.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay stock disponible en tiendas físicas para esta prenda actualmente.'),
          backgroundColor: fsInk,
        ),
      );
    }
  }
}

// =============================================================================
// COMPONENTES AUXILIARES DEL TRY-ON FOTOREALISTA
// =============================================================================

/// Diálogo con fases dinámicas que informan el avance del pipeline fotorealista.
class DialogoProgresoTryOn extends StatefulWidget {
  const DialogoProgresoTryOn({super.key});

  @override
  State<DialogoProgresoTryOn> createState() => _DialogoProgresoTryOnState();
}

class _DialogoProgresoTryOnState extends State<DialogoProgresoTryOn> {
  static const List<String> _fases = [
    'Detectando silueta...',
    'Adaptando tejido y caída...',
    'Componiendo sombras realistas...',
    'Refinando detalles y balance de luz...',
  ];

  int _faseIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      if (!mounted) return;
      setState(() {
        _faseIndex = (_faseIndex + 1) % _fases.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: fsSurface,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: fsGoldWash,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(fsGoldDeep),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Vestidor Fotorealista con IA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: fsInk,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _fases[_faseIndex],
                  key: ValueKey<int>(_faseIndex),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fsEmerald,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ajuste afín y balance de iluminación en curso...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: fsInkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modos de visualización del visor interactivo Try-On.
enum ModoVistaTryOn { tryOn, original, comparativaLadoALado }

/// Visor modal interactivo de alta resolución con soporte nativo de InteractiveViewer
/// para zoom táctil, paneo fluido y comparativa antes/después.
class TryOnVisorModal extends StatefulWidget {
  final Uint8List imagenBytes;
  final Uint8List? fotoOriginalBytes;
  final PrendaCatalogo prenda;
  final double tiempoMs;
  final String? mensaje;
  final VoidCallback? onReservar;

  const TryOnVisorModal({
    super.key,
    required this.imagenBytes,
    this.fotoOriginalBytes,
    required this.prenda,
    required this.tiempoMs,
    this.mensaje,
    this.onReservar,
  });

  @override
  State<TryOnVisorModal> createState() => _TryOnVisorModalState();
}

class _TryOnVisorModalState extends State<TryOnVisorModal> {
  final TransformationController _transformController = TransformationController();
  ModoVistaTryOn _modoVista = ModoVistaTryOn.tryOn;

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.prenda.nombre,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.mensaje ?? 'Vestidor Fotorealista (IA)',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          actions: [
            if (widget.fotoOriginalBytes != null) ...[
              IconButton(
                key: const Key('btn_toggle_vista'),
                tooltip: _modoVista == ModoVistaTryOn.tryOn
                    ? 'Ver foto original'
                    : 'Ver resultado Try-On',
                icon: Icon(
                  _modoVista == ModoVistaTryOn.tryOn
                      ? Icons.person_outline
                      : Icons.auto_awesome,
                  color: fsGold,
                ),
                onPressed: () {
                  setState(() {
                    if (_modoVista == ModoVistaTryOn.tryOn) {
                      _modoVista = ModoVistaTryOn.original;
                    } else {
                      _modoVista = ModoVistaTryOn.tryOn;
                    }
                  });
                },
              ),
              IconButton(
                key: const Key('btn_vista_lado_a_lado'),
                tooltip: _modoVista == ModoVistaTryOn.comparativaLadoALado
                    ? 'Vista individual'
                    : 'Comparativa lado a lado',
                icon: Icon(
                  _modoVista == ModoVistaTryOn.comparativaLadoALado
                      ? Icons.fullscreen
                      : Icons.compare,
                  color: _modoVista == ModoVistaTryOn.comparativaLadoALado
                      ? fsGold
                      : Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    if (_modoVista == ModoVistaTryOn.comparativaLadoALado) {
                      _modoVista = ModoVistaTryOn.tryOn;
                    } else {
                      _modoVista = ModoVistaTryOn.comparativaLadoALado;
                    }
                  });
                },
              ),
            ],
            IconButton(
              key: const Key('btn_reset_zoom'),
              icon: const Icon(Icons.zoom_out_map, color: Colors.white70),
              tooltip: 'Restablecer zoom',
              onPressed: _resetZoom,
            ),
            IconButton(
              key: const Key('btn_cerrar_visor'),
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Cerrar',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: _construirLienzo(),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(180),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: fsEmerald.withAlpha(180)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, color: fsEmerald, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      'IA Generativa: ${(widget.tiempoMs / 1000).toStringAsFixed(2)}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.fotoOriginalBytes != null &&
                _modoVista != ModoVistaTryOn.comparativaLadoALado)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(180),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: fsGold.withAlpha(180)),
                  ),
                  child: Text(
                    _modoVista == ModoVistaTryOn.tryOn ? 'Try-On IA' : 'Original',
                    style: const TextStyle(
                      color: fsGold,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withAlpha(220),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('btn_reservar_desde_tryon'),
                        icon: const Icon(Icons.event_seat_outlined, size: 18),
                        label: const Text('Reservar en Tienda (CU16)'),
                        style: FilledButton.styleFrom(
                          backgroundColor: fsGold,
                          foregroundColor: fsInk,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onReservar?.call();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirLienzo() {
    if (_modoVista == ModoVistaTryOn.comparativaLadoALado &&
        widget.fotoOriginalBytes != null) {
      return Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  width: double.infinity,
                  child: const Center(
                    child: Text(
                      'Foto Original',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.5,
                    child: Center(
                      child: Image.memory(
                        widget.fotoOriginalBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1.5, color: fsBorder.withAlpha(100)),
          Expanded(
            child: Column(
              children: [
                Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  width: double.infinity,
                  child: const Center(
                    child: Text(
                      'Try-On Fotorealista (IA)',
                      style: TextStyle(
                        color: fsGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 0.5,
                    maxScale: 4.5,
                    child: Center(
                      child: Image.memory(
                        widget.imagenBytes,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final Uint8List imagenActual = (_modoVista == ModoVistaTryOn.original &&
            widget.fotoOriginalBytes != null)
        ? widget.fotoOriginalBytes!
        : widget.imagenBytes;

    return InteractiveViewer(
      transformationController: _transformController,
      minScale: 0.5,
      maxScale: 5.0,
      boundaryMargin: const EdgeInsets.all(32),
      child: Center(
        child: Image.memory(
          imagenActual,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
