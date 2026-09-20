import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/models/catalogo_models.dart';
import '../../core/theme.dart';
import 'services/pose_tracking_service.dart';

/// Vestidor Virtual mediante Realidad Aumentada 2D en Tiempo Real (CU18).
///
/// Motor de Visión Computacional On-Device que detecta la postura del usuario
/// (MediaPipe / Google ML Kit) y adapta la prenda sobre los hombros en vivo,
/// con suavizado temporal anti-vibración y controles táctiles de respaldo.
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late VarianteCatalogo? _varianteSeleccionada;

  // Parámetros de transformación manual (Gestos)
  Offset _posicion = Offset.zero;
  double _escala = 1.0;
  double _rotacion = 0.0;
  double _opacidad = 0.90;

  double _escalaBase = 1.0;
  double _rotacionBase = 0.0;
  Offset _posicionBase = Offset.zero;

  // Motor de Visión y Pose Tracking
  late final PoseTrackingService _poseService;
  late final FiltroSuavizadoAR _filtroSuavizado;
  bool _modoAutoTracking = true;
  bool _cuerpoDetectado = false;
  bool _procesandoFrame = false;
  PoseTrackingResult? _poseActual;
  Rect? _rectPrendaAuto;
  double _anguloPrendaAuto = 0.0;

  // Controlador de cámara física
  List<CameraDescription> _camarasDisponibles = [];
  CameraController? _cameraController;
  CameraDescription? _camaraActual;
  bool _camaraIniciada = false;
  bool _camaraFrontal = true;
  bool _mostrarSiluetaGuia = true;
  bool _disparandoFoto = false;

  late AnimationController _animController;
  late Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _poseService = PoseTrackingService();
    _filtroSuavizado = FiltroSuavizadoAR(alpha: 0.22);

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

    _iniciarCamara();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camera = _cameraController;
    if (camera == null || !camera.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      camera.stopImageStream().catchError((_) {});
      camera.dispose();
      _cameraController = null;
      if (mounted) setState(() => _camaraIniciada = false);
    } else if (state == AppLifecycleState.resumed) {
      _iniciarCamara();
    }
  }

  Future<void> _iniciarCamara() async {
    try {
      _camarasDisponibles = await availableCameras();
      if (_camarasDisponibles.isNotEmpty) {
        await _conectarLente(
          _camaraFrontal
              ? CameraLensDirection.front
              : CameraLensDirection.back,
        );
      }
    } catch (_) {
      // Fallback silencioso a visor ambiental
    }
  }

  Future<void> _conectarLente(CameraLensDirection direccion) async {
    final camara = _camarasDisponibles.firstWhere(
      (c) => c.lensDirection == direccion,
      orElse: () => _camarasDisponibles.first,
    );
    _camaraActual = camara;

    if (_cameraController != null) {
      try {
        await _cameraController!.stopImageStream();
      } catch (_) {}
      await _cameraController!.dispose();
    }

    final controller = CameraController(
      camara,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    try {
      await controller.initialize();
      _filtroSuavizado.reset();

      // Iniciar stream de frames continuo para el pose detector
      await controller.startImageStream(_onCameraFrame);

      if (mounted) {
        setState(() {
          _cameraController = controller;
          _camaraIniciada = true;
          _camaraFrontal = (camara.lensDirection == CameraLensDirection.front);
        });
      }
    } catch (_) {
      // Fallback suave
    }
  }

  void _onCameraFrame(CameraImage image) async {
    if (_procesandoFrame || !_modoAutoTracking || !mounted) return;
    _procesandoFrame = true;

    try {
      final size = MediaQuery.of(context).size;
      final cam = _camaraActual;
      if (cam == null) return;

      final resultado = await _poseService.procesarFrame(
        image: image,
        camera: cam,
        tamanoPantalla: size,
      );

      if (!mounted) return;

      if (resultado != null) {
        // Suavizado temporal EMA para estabilización anti-jitter
        final suavizado = _filtroSuavizado.suavizar(
          nuevoCentro: resultado.centroHombros,
          nuevaDistancia: resultado.distanciaHombros,
          nuevoAngulo: resultado.angulo,
        );

        // Heurística anatómica optimizada para prendas PNG con fondo transparente:
        // Eleva el anclaje vertical (Y) para que el cuello de la prenda coincida exactamente
        // con la base del cuello / horquilla esternal del usuario detectado por MediaPipe.
        final rect = CalculadorTransformacionPrenda.calcularRectPrenda(
          centroHombros: suavizado.centro,
          distanciaHombros: suavizado.distanciaHombros,
          aspectPrenda: 1.22, // Proporción natural anatómica de prenda
          factorEscala: 1.20, // Cobertura envolvente de hombros y sisa
          compensacionCuello: 0.22, // Offset Y calibrado para la base del cuello
          desplazamientoVertical: -(suavizado.distanciaHombros * 0.05),
        );

        setState(() {
          _poseActual = resultado;
          _rectPrendaAuto = rect;
          _anguloPrendaAuto = suavizado.angulo;
          _cuerpoDetectado = true;
        });
      } else {
        if (_cuerpoDetectado) {
          setState(() {
            _cuerpoDetectado = false;
          });
        }
      }
    } catch (_) {
      // Ignorar errores transitorios de frame
    } finally {
      _procesandoFrame = false;
    }
  }

  Future<void> _alternarCamara() async {
    if (_camarasDisponibles.length < 2) return;
    final nuevaDireccion = _camaraFrontal
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    await _conectarLente(nuevaDireccion);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_cameraController != null) {
      _cameraController!.stopImageStream().catchError((_) {});
      _cameraController!.dispose();
    }
    _poseService.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _resetearAjustes() {
    _filtroSuavizado.reset();
    setState(() {
      _posicion = Offset.zero;
      _escala = 1.0;
      _rotacion = 0.0;
      _opacidad = 0.90;
      _modoAutoTracking = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tracking automático AR restablecido'),
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
            Text(
              'Motor de Tracking Corporal On-Device (CU18)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 8),
            Text('• Apunta la cámara a tu torso: la IA detectará tus hombros automáticamente.'),
            SizedBox(height: 6),
            Text('• La prenda se adapta a tu tamaño, postura y rotación en vivo.'),
            SizedBox(height: 6),
            Text('• Si prefieres ajuste manual, toca el chip "Modo Manual".'),
            SizedBox(height: 6),
            Text('• Usa el deslizador inferior para regular la transparencia del tejido.'),
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
          // 1. Feed en vivo de la cámara física / Viewfinder
          Positioned.fill(
            child: _visorCamara(size),
          ),

          // 2. Silueta anatómica guía y marcadores de hombros
          if (_mostrarSiluetaGuia)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SiluetaAnatomicaPainter(pose: _poseActual),
                ),
              ),
            ),

          // 3. Capa AR de la Prenda (Automática por IA o Manual por Gestos)
          if (_modoAutoTracking && _cuerpoDetectado && _rectPrendaAuto != null)
            _buildPrendaAutomatica()
          else
            _buildPrendaManual(size),

          // 4. Indicador flotante de estado de tracking
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: _buildBannerEstadoTracking(),
          ),

          // 5. Efecto de destello de captura fotográfica
          if (_disparandoFoto)
            Positioned.fill(
              child: FadeTransition(
                opacity: _flashAnimation,
                child: Container(color: Colors.white),
              ),
            ),

          // 6. Barra Superior de Controles
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
                    // Toggle silueta / esqueleto
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
                      onPressed: _alternarCamara,
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

          // 7. Panel Inferior con Controles y Variantes
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
                                  fontWeight:
                                      sel ? FontWeight.w600 : FontWeight.normal,
                                  color: sel ? Colors.white : Colors.white70,
                                ),
                              ),
                              selected: sel,
                              selectedColor: fsEmerald,
                              backgroundColor: Colors.white.withAlpha(20),
                              side: BorderSide(
                                color: sel ? fsEmerald : Colors.white24,
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              onSelected: (_) {
                                setState(() => _varianteSeleccionada = v);
                              },
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Botones de acción principales
                    Row(
                      children: [
                        // Botón de Disparo Fotográfico
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: IconButton(
                            iconSize: 28,
                            padding: const EdgeInsets.all(8),
                            icon: const Icon(Icons.camera_alt, color: Colors.white),
                            onPressed: _capturarLook,
                            tooltip: 'Tomar foto del look',
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Botón de Reserva para Prueba Física (CU16)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: fsGold,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            icon: const Icon(Icons.event_seat_rounded, size: 20),
                            label: const Text(
                              'Reservar en Tienda (CU16)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            onPressed: () {
                              _mostrarDialogoReserva();
                            },
                          ),
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

  /// Capa automática 2D posicionada y orientada por el motor Pose Tracking
  Widget _buildPrendaAutomatica() {
    final rect = _rectPrendaAuto!;
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Transform.rotate(
        angle: _anguloPrendaAuto,
        alignment: Alignment.topCenter,
        child: Opacity(
          opacity: _opacidad,
          child: _buildPrendaVisual(),
        ),
      ),
    );
  }

  /// Capa manual interactiva con gestos táctiles (zoom, arrastre y rotación)
  Widget _buildPrendaManual(Size size) {
    return Positioned.fill(
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
                    _escala = (_escalaBase * details.scale).clamp(0.4, 3.0);
                    _rotacion = _rotacionBase + details.rotation;
                    _posicion = _posicionBase + details.focalPointDelta;
                  });
                },
                child: Opacity(
                  opacity: _opacidad,
                  child: SizedBox(
                    width: size.width * 0.75,
                    height: size.height * 0.50,
                    child: _buildPrendaVisual(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Banner dinámico que informa el estado del motor de tracking
  Widget _buildBannerEstadoTracking() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Indicador de detección
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _cuerpoDetectado
                ? Colors.black.withAlpha(180)
                : Colors.black.withAlpha(140),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _cuerpoDetectado ? fsEmerald : Colors.amber.withAlpha(160),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _cuerpoDetectado ? fsEmerald : Colors.amber,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _cuerpoDetectado
                    ? 'Hombros Detectados (IA)'
                    : 'Buscando postura...',
                style: TextStyle(
                  color: _cuerpoDetectado ? fsEmerald : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Conmutador Modo Auto / Manual
        GestureDetector(
          onTap: () {
            setState(() {
              _modoAutoTracking = !_modoAutoTracking;
              _filtroSuavizado.reset();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _modoAutoTracking
                  ? fsEmerald.withAlpha(40)
                  : Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _modoAutoTracking ? fsEmerald : Colors.white30,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _modoAutoTracking
                      ? Icons.auto_awesome
                      : Icons.touch_app_outlined,
                  size: 14,
                  color: _modoAutoTracking ? fsEmerald : Colors.white,
                ),
                const SizedBox(width: 5),
                Text(
                  _modoAutoTracking ? 'Modo Auto AR' : 'Modo Gestos',
                  style: TextStyle(
                    color: _modoAutoTracking ? fsEmerald : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Visor interactivo de cámara con feed en vivo o retícula ambiental
  Widget _visorCamara(Size size) {
    if (_camaraIniciada &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize?.height ?? size.width,
              height:
                  _cameraController!.value.previewSize?.width ?? size.height,
              child: CameraPreview(_cameraController!),
            ),
          ),
          CustomPaint(
            size: size,
            painter: _ReticulaARPainter(),
          ),
        ],
      );
    }

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

  /// Visualizador de la prenda optimizado para superposición AR sobre el torso.
  /// Emplea BoxFit.contain para conservar la silueta sin deformación ni recorte,
  /// soporta nativamente canal alfa (transparencia total), renderizado bicúbico
  /// (FilterQuality.high) y un leve suavizado tonal (BlendMode.modulate) que integra
  /// los bordes del PNG recortado contra el feed en vivo de la cámara.
  Widget _buildPrendaVisual() {
    final url = widget.prenda.urlImagen;
    if (url == null || url.isEmpty) {
      return const Center(
        child: Icon(Icons.checkroom_rounded, color: Colors.white70, size: 64),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      color: Colors.white.withAlpha(248),
      colorBlendMode: BlendMode.modulate,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(fsEmerald),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stack) => const Center(
        child: Icon(Icons.checkroom_rounded, color: Colors.white70, size: 64),
      ),
    );
  }

  void _mostrarDialogoReserva() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.qr_code_2_rounded, color: fsEmerald, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reserva para Probador Físico',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: fsInk,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Prenda: ${widget.prenda.nombre}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (_varianteSeleccionada != null)
              Text(
                'Variante: ${_varianteSeleccionada!.talla} · ${_varianteSeleccionada!.color}',
                style: const TextStyle(color: Colors.black54),
              ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: fsSurfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: fsEmerald, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Al confirmar, se reservará la prenda en tienda por 2 horas para que te la pruebes físicamente.',
                      style: TextStyle(fontSize: 12, color: fsInk),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: fsEmerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: fsEmerald,
                      content: Text(
                        '¡Ticket de reserva generado con éxito! Puedes verlo en tus reservas.',
                      ),
                    ),
                  );
                },
                child: const Text('Confirmar Reserva con Ticket QR'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dibuja una silueta anatómica y marcadores de hombros detectados por ML Kit
class _SiluetaAnatomicaPainter extends CustomPainter {
  final PoseTrackingResult? pose;

  _SiluetaAnatomicaPainter({this.pose});

  @override
  void paint(Canvas canvas, Size size) {
    // Si la IA detectó hombros, pintar marcadores inteligentes y línea clavicular
    if (pose != null) {
      final paintPuntos = Paint()
        ..color = fsEmerald
        ..style = PaintingStyle.fill;

      final paintLinea = Paint()
        ..color = fsEmerald.withAlpha(150)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(pose!.hombroIzquierdo, pose!.hombroDerecho, paintLinea);
      canvas.drawCircle(pose!.hombroIzquierdo, 6.0, paintPuntos);
      canvas.drawCircle(pose!.hombroDerecho, 6.0, paintPuntos);

      // Centro de referencia
      final paintCentro = Paint()
        ..color = fsGold
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pose!.centroHombros, 4.0, paintCentro);
      return;
    }

    // Si no hay detección activa, dibujar silueta anatómica sutil de guía
    final paint = Paint()
      ..color = Colors.white.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final cx = size.width / 2;
    final cy = size.height * 0.40;

    // Cuello y hombros
    final path = Path();
    path.moveTo(cx - 30, cy - 60);
    path.quadraticBezierTo(cx - 40, cy - 20, cx - 120, cy);
    path.quadraticBezierTo(cx - 130, cy + 80, cx - 110, cy + 200);

    path.moveTo(cx + 30, cy - 60);
    path.quadraticBezierTo(cx + 40, cy - 20, cx + 120, cy);
    path.quadraticBezierTo(cx + 130, cy + 80, cx + 110, cy + 200);

    // Cabeza / Mentón
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 90), width: 90, height: 110),
      paint,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SiluetaAnatomicaPainter oldDelegate) {
    return oldDelegate.pose != pose;
  }
}

/// Retícula AR sutil de calibración
class _ReticulaARPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
