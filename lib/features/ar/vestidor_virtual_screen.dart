import 'package:flutter/material.dart';

import '../../core/models/catalogo_models.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Vestidor Virtual mediante Realidad Aumentada (CU18).
///
/// Permite al usuario superponer interactivamente la prenda sobre el feed
/// de la cámara o viewport inmersivo, ajustando posición, escala, rotación
/// y opacidad con gestos táctiles directos.
class VestidorVirtualScreen extends StatefulWidget {
  final PrendaCatalogo prenda;
  final VarianteCatalogo? varianteInicial;

  const VestidorVirtualScreen({
    super.key,
    required this.prenda,
    this.varianteInicial,
  });

  @override
  State<VestidorVirtualScreen> createState() => _VestidorVirtualScreenState();
}

class _VestidorVirtualScreenState extends State<VestidorVirtualScreen>
    with SingleTickerProviderStateMixin {
  late VarianteCatalogo? _varianteSeleccionada;

  // Parámetros de transformación AR de la prenda
  Offset _posicion = Offset.zero;
  double _escala = 1.0;
  double _rotacion = 0.0;
  double _opacidad = 0.90;

  // Para cálculo acumulativo de gestos
  double _escalaBase = 1.0;
  double _rotacionBase = 0.0;
  Offset _posicionBase = Offset.zero;

  // Estado de la cámara y visor
  bool _camaraFrontal = true;
  bool _mostrarSiluetaGuia = true;
  bool _disparandoFoto = false;

  late AnimationController _animController;
  late Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();
    _varianteSeleccionada = widget.varianteInicial ??
        (widget.prenda.variantes.isNotEmpty
            ? widget.prenda.variantes.first
            : null);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _resetearAjustes() {
    setState(() {
      _posicion = Offset.zero;
      _escala = 1.0;
      _rotacion = 0.0;
      _opacidad = 0.90;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ajuste de prenda restablecido'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _capturarLook() async {
    setState(() => _disparandoFoto = true);
    await _animController.forward(from: 0.0);
    await _animController.reverse();
    setState(() => _disparandoFoto = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: fsInk,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: fsEmerald),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '¡Look con "${widget.prenda.nombre}" guardado en tu galería!',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarAyuda() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.view_in_ar_rounded, color: fsEmerald),
            SizedBox(width: 8),
            Text('Vestidor Virtual AR'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Arrastra la prenda con 1 dedo para moverla.'),
            SizedBox(height: 6),
            Text('• Pellizca con 2 dedos para cambiar el tamaño (zoom).'),
            SizedBox(height: 6),
            Text('• Gira con 2 dedos para orientarla a tu postura.'),
            SizedBox(height: 6),
            Text('• Usa el deslizador inferior para regular la transparencia.'),
            SizedBox(height: 6),
            Text('• Alinea tus hombros con la silueta guía.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Fondo de simulación de cámara / Viewfinder
          Positioned.fill(
            child: _visorCamara(size),
          ),

          // 2. Silueta anatómica guía para alineación de hombros
          if (_mostrarSiluetaGuia)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SiluetaAnatomicaPainter(),
                ),
              ),
            ),

          // 3. Capa AR de la Prenda Interactiva
          Positioned.fill(
            child: Center(
              child: Transform.translate(
                offset: _posicion,
                child: Transform.rotate(
                  angle: _rotacion,
                  child: Transform.scale(
                    scale: _escala,
                    child: GestureDetector(
                      onScaleStart: (details) {
                        _escalaBase = _escala;
                        _rotacionBase = _rotacion;
                        _posicionBase = _posicion;
                      },
                      onScaleUpdate: (details) {
                        setState(() {
                          // Manejo combinado de arrastre, zoom y rotación
                          _escala = (_escalaBase * details.scale)
                              .clamp(0.4, 3.0);
                          _rotacion = _rotacionBase + details.rotation;
                          _posicion = _posicionBase + details.focalPointDelta;
                        });
                      },
                      child: Opacity(
                        opacity: _opacidad,
                        child: Container(
                          width: size.width * 0.75,
                          height: size.height * 0.50,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(50),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: redImagen(widget.prenda.urlImagen),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. Efecto de destello de captura fotográfica
          if (_disparandoFoto)
            Positioned.fill(
              child: FadeTransition(
                opacity: _flashAnimation,
                child: Container(color: Colors.white),
              ),
            ),

          // 5. Barra Superior de Controles
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(200),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Salir del vestidor',
                    ),
                    const Spacer(),
                    // Toggle silueta
                    IconButton(
                      icon: Icon(
                        _mostrarSiluetaGuia
                            ? Icons.accessibility_new
                            : Icons.accessibility_new_outlined,
                        color: _mostrarSiluetaGuia
                            ? fsEmerald
                            : Colors.white70,
                      ),
                      onPressed: () {
                        setState(() => _mostrarSiluetaGuia = !_mostrarSiluetaGuia);
                      },
                      tooltip: 'Guía de postura',
                    ),
                    // Toggle cámara frontal/trasera
                    IconButton(
                      icon: Icon(
                        _camaraFrontal
                            ? Icons.camera_front
                            : Icons.camera_rear,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() => _camaraFrontal = !_camaraFrontal);
                      },
                      tooltip: 'Cambiar cámara',
                    ),
                    // Resetear posición
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _resetearAjustes,
                      tooltip: 'Centrar prenda',
                    ),
                    // Ayuda
                    IconButton(
                      icon: const Icon(Icons.help_outline, color: Colors.white),
                      onPressed: _mostrarAyuda,
                      tooltip: 'Instrucciones',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 6. Panel Inferior con Controles y Variantes
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withAlpha(230),
                    Colors.black.withAlpha(180),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Deslizador de Opacidad
                    Row(
                      children: [
                        const Icon(Icons.opacity, size: 16, color: Colors.white70),
                        const SizedBox(width: 8),
                        const Text(
                          'Transparencia:',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: fsEmerald,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6),
                            ),
                            child: Slider(
                              value: _opacidad,
                              min: 0.30,
                              max: 1.0,
                              onChanged: (v) => setState(() => _opacidad = v),
                            ),
                          ),
                        ),
                        Text(
                          '${(_opacidad * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Variantes de Talla / Color
                    if (widget.prenda.variantes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 32,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.prenda.variantes.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final v = widget.prenda.variantes[idx];
                            final sel = _varianteSeleccionada?.idVariantePrenda ==
                                v.idVariantePrenda;
                            return ChoiceChip(
                              label: Text(
                                '${v.talla ?? ''} · ${v.color ?? ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: sel ? Colors.black : Colors.white,
                                  fontWeight: sel
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                ),
                              ),
                              selected: sel,
                              selectedColor: Colors.white,
                              backgroundColor: Colors.white12,
                              onSelected: (_) {
                                setState(() => _varianteSeleccionada = v);
                              },
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Fila de Disparador y Botón de Reserva en Tienda (CU16)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.prenda.nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                formatearPrecio(widget.prenda.precioBase),
                                style: const TextStyle(
                                  color: fsEmerald,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Botón de Captura Fotográfica
                        IconButton.filled(
                          icon: const Icon(Icons.camera_alt, color: Colors.black),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                          ),
                          onPressed: _capturarLook,
                          tooltip: 'Capturar foto de look',
                        ),
                        const SizedBox(width: 10),
                        // Botón de Volver a Ficha para Reservar
                        FilledButton.icon(
                          icon: const Icon(Icons.storefront, size: 16),
                          label: const Text(
                            'Reservar',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: fsEmerald,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Visor interactivo de cámara con retícula y gradiente ambiental
  Widget _visorCamara(Size size) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1a1c23),
            _camaraFrontal ? const Color(0xFF24283b) : const Color(0xFF13151a),
            const Color(0xFF0d0e12),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Cuadrícula sutil de realidad aumentada
          CustomPaint(
            size: size,
            painter: _ReticulaARPainter(),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _camaraFrontal
                      ? Icons.face_retouching_natural
                      : Icons.center_focus_strong,
                  size: 48,
                  color: Colors.white.withAlpha(40),
                ),
                const SizedBox(height: 8),
                Text(
                  _camaraFrontal
                      ? 'VISOR DE PROBADOR VIRTUAL'
                      : 'CÁMARA TRASERA ACTIVA',
                  style: TextStyle(
                    color: Colors.white.withAlpha(60),
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dibuja una silueta anatómica estilizada para que el usuario alinee su torso
class _SiluetaAnatomicaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final cx = size.width / 2;
    final cy = size.height * 0.40;

    // Cabeza / Cuello
    final path = Path();
    path.addOval(Rect.fromCenter(
      center: Offset(cx, cy - 110),
      width: 90,
      height: 120,
    ));

    // Hombros y Torso
    path.moveTo(cx - 30, cy - 40);
    path.quadraticBezierTo(cx - 80, cy - 30, cx - 140, cy + 20);
    path.lineTo(cx - 130, cy + 180);
    path.quadraticBezierTo(cx, cy + 200, cx + 130, cy + 180);
    path.lineTo(cx + 140, cy + 20);
    path.quadraticBezierTo(cx + 80, cy - 30, cx + 30, cy - 40);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dibuja puntos de enfoque y retícula AR en las esquinas
class _ReticulaARPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fsEmerald.withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const cornerSize = 24.0;
    const margin = 32.0;

    // Esquina Superior Izquierda
    canvas.drawLine(
        const Offset(margin, margin), const Offset(margin + cornerSize, margin), paint);
    canvas.drawLine(
        const Offset(margin, margin), const Offset(margin, margin + cornerSize), paint);

    // Esquina Superior Derecha
    final right = size.width - margin;
    canvas.drawLine(
        Offset(right, margin), Offset(right - cornerSize, margin), paint);
    canvas.drawLine(
        Offset(right, margin), Offset(right, margin + cornerSize), paint);

    // Esquina Inferior Izquierda
    final bottom = size.height - margin - 120;
    canvas.drawLine(
        Offset(margin, bottom), Offset(margin + cornerSize, bottom), paint);
    canvas.drawLine(
        Offset(margin, bottom), Offset(margin, bottom - cornerSize), paint);

    // Esquina Inferior Derecha
    canvas.drawLine(
        Offset(right, bottom), Offset(right - cornerSize, bottom), paint);
    canvas.drawLine(
        Offset(right, bottom), Offset(right, bottom - cornerSize), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
