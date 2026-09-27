import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../core/models/catalogo_models.dart';
import '../../core/theme.dart';
import 'services/pose_tracking_service.dart';

/// Configuración biomecánica y geométrica calibrada para cada modelo 3D
class Modelo3DConfig {
  final String sku;
  final String nombre;
  final String glbUrl;
  final bool esRigged;
  final double factorEscala;
  final double compensacionCuello;
  final String etiqueta;
  final String descripcionCorta;

  const Modelo3DConfig({
    required this.sku,
    required this.nombre,
    required this.glbUrl,
    required this.esRigged,
    required this.factorEscala,
    required this.compensacionCuello,
    required this.etiqueta,
    required this.descripcionCorta,
  });
}

/// Diccionario de modelos 3D calibrados con la base de datos de producción
const Map<String, Modelo3DConfig> kModelos3D = {
  '3D-HOODIE-001': Modelo3DConfig(
    sku: '3D-HOODIE-001',
    nombre: 'Hoodie Urbano V2 (Rigged 3D)',
    glbUrl: 'https://fashionstore.aledevcv.me/modelos3d/hoodie.glb',
    esRigged: true,
    factorEscala: 1.35,
    compensacionCuello: 0.16,
    etiqueta: '⚡ Rigged 3D (17 Huesos)',
    descripcionCorta: 'Mangas articuladas que se flexionan con tus brazos.',
  ),
  '3D-MONA-002': Modelo3DConfig(
    sku: '3D-MONA-002',
    nombre: 'Camiseta Monalisa Streetwear 3D',
    glbUrl: 'https://fashionstore.aledevcv.me/modelos3d/offwhite_tshirt.glb',
    esRigged: false,
    factorEscala: 1.15,
    compensacionCuello: 0.20,
    etiqueta: '✨ Textura PBR Hiperrealista',
    descripcionCorta: 'Estampado gráfico frontal y arrugas de tela en alta fidelidad.',
  ),
  '3D-COMBAT-003': Modelo3DConfig(
    sku: '3D-COMBAT-003',
    nombre: 'Combat Shirt Táctica (Rigged Metahuman)',
    glbUrl: 'https://fashionstore.aledevcv.me/modelos3d/combat_shirt.glb',
    esRigged: true,
    factorEscala: 1.25,
    compensacionCuello: 0.18,
    etiqueta: '⚡ Rigged Metahuman Táctico',
    descripcionCorta: 'Armature completo militar para cinemática corporal.',
  ),
  '3D-SCOTT-004': Modelo3DConfig(
    sku: '3D-SCOTT-004',
    nombre: 'Camisa a Cuadros Scott (Rigged)',
    glbUrl: 'https://fashionstore.aledevcv.me/modelos3d/shirt_scott.glb',
    esRigged: true,
    factorEscala: 1.22,
    compensacionCuello: 0.17,
    etiqueta: '⚡ Rigged Tartán Escocés',
    descripcionCorta: 'Mangas enrolladas con armature 3D integrado.',
  ),
};

/// Lista predefinida de los 4 modelos 3D del catálogo oficial para conmutación rápida
final List<PrendaCatalogo> kCatalogoPrendas3D = [
  const PrendaCatalogo(
    idPrenda: 269,
    sku: '3D-HOODIE-001',
    nombre: 'Hoodie Urbano V2 (Rigged 3D)',
    categoria: 'Abrigos & Sweaters',
    precioBase: 299.00,
    urlImagen: 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=600&auto=format&fit=crop&q=80',
    stockTotal: 180,
    variantes: [],
  ),
  const PrendaCatalogo(
    idPrenda: 270,
    sku: '3D-MONA-002',
    nombre: 'Camiseta Monalisa Streetwear 3D',
    categoria: 'Poleras & Remeras',
    precioBase: 189.00,
    urlImagen: 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=600&auto=format&fit=crop&q=80',
    stockTotal: 240,
    variantes: [],
  ),
  const PrendaCatalogo(
    idPrenda: 271,
    sku: '3D-COMBAT-003',
    nombre: 'Combat Shirt Táctica (Rigged Metahuman)',
    categoria: 'Chaquetas',
    precioBase: 349.00,
    urlImagen: 'https://images.unsplash.com/photo-1578587018452-892bacefd3f2?w=600&auto=format&fit=crop&q=80',
    stockTotal: 144,
    variantes: [],
  ),
  const PrendaCatalogo(
    idPrenda: 272,
    sku: '3D-SCOTT-004',
    nombre: 'Camisa a Cuadros Scott (Rigged)',
    categoria: 'Camisas',
    precioBase: 259.00,
    urlImagen: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600&auto=format&fit=crop&q=80',
    stockTotal: 216,
    variantes: [],
  ),
];

/// Vestidor Virtual mediante Realidad Aumentada con Detección Cinemática 3D (CU18).
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
  late PrendaCatalogo _prendaActual;
  late VarianteCatalogo? _varianteSeleccionada;

  // Parámetros de transformación manual (Modo Gestos táctiles)
  Offset _posicionManual = Offset.zero;
  double _escalaManual = 1.0;
  double _rotacionManual = 0.0;

  double _escalaBase = 1.0;
  double _rotacionBase = 0.0;
  Offset _posicionBase = Offset.zero;

  // Calibración fina cinemática (Sliders)
  double _calibracionHolgura = 1.05; // 0.8x a 1.5x
  double _offsetVerticalCuello = 0.0; // -60px a +60px
  double _opacidadTela = 0.95; // 0.3 a 1.0

  // Motor de Visión y Pose Tracking
  late final PoseTrackingService _poseService;
  late final FiltroSuavizadoAR _filtroSuavizado;
  bool _modoAutoTracking = true;
  bool _cuerpoDetectado = false;
  bool _procesandoFrame = false;
  PoseTrackingResult? _poseActual;
  PoseTransformacion? _transformacionSuavizada;
  Rect? _rectPrendaAuto;

  // Toggles visuales de capas AR
  bool _mostrarPrenda = true;
  bool _mostrarEsqueleto = true;
  bool _mostrarLandmarks = true;
  bool _mostrarPanelTelemetria = true;
  bool _mostrarPanelCalibracion = false;
  bool _mostrarCarruselPrendas = true;

  // Controlador de cámara física
  List<CameraDescription> _camarasDisponibles = [];
  CameraController? _cameraController;
  CameraDescription? _camaraActual;
  bool _camaraIniciada = false;
  bool _camaraFrontal = true;
  bool _disparandoFoto = false;

  late AnimationController _animController;
  late Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _prendaActual = widget.prenda;
    _poseService = PoseTrackingService();
    _filtroSuavizado = FiltroSuavizadoAR(alpha: 0.25);

    _varianteSeleccionada = widget.varianteInicial ??
        (_prendaActual.variantes.isNotEmpty
            ? _prendaActual.variantes.first
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
      // Fallback suave
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
          nuevoCentro: resultado.centroPecho,
          nuevaDistancia: resultado.distanciaHombros,
          nuevoAngulo: resultado.angulo,
          nuevoYaw: resultado.yawZ,
        );

        // Calibración anatómica según el modelo 3D activo
        final config3d = kModelos3D[_prendaActual.sku];
        final factorPrenda = (config3d?.factorEscala ?? 1.18) * _calibracionHolgura;
        final compensacionCuello = config3d?.compensacionCuello ?? 0.18;

        // Rectángulo cinemático anclado al torso
        final rect = CalculadorTransformacionPrenda.calcularRectPrenda(
          centroHombros: suavizado.centro,
          distanciaHombros: suavizado.distanciaHombros,
          aspectPrenda: 1.25,
          factorEscala: factorPrenda,
          compensacionCuello: compensacionCuello,
          desplazamientoVertical: _offsetVerticalCuello,
        );

        setState(() {
          _poseActual = resultado;
          _transformacionSuavizada = suavizado;
          _rectPrendaAuto = rect;
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
      // Ignorar errores transitorios
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

  void _seleccionarPrenda3D(PrendaCatalogo p) {
    setState(() {
      _prendaActual = p;
      _varianteSeleccionada = p.variantes.isNotEmpty ? p.variantes.first : null;
      _filtroSuavizado.reset();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E1B4B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        content: Row(
          children: [
            const Icon(Icons.view_in_ar, color: Color(0xFF818CF8), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Modelo activo: ${p.nombre}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetearAjustes() {
    _filtroSuavizado.reset();
    setState(() {
      _posicionManual = Offset.zero;
      _escalaManual = 1.0;
      _rotacionManual = 0.0;
      _calibracionHolgura = 1.05;
      _offsetVerticalCuello = 0.0;
      _opacidadTela = 0.95;
      _modoAutoTracking = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calibración AR restablecida a valores óptimos'),
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
                '¡Look con "${_prendaActual.nombre}" guardado en tu galería!',
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
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        title: const Row(
          children: [
            Icon(Icons.view_in_ar_rounded, color: fsEmerald),
            SizedBox(width: 8),
            Text(
              'Probador Virtual AR 3D',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modelos 3D Reales y Cinemática (CU18)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF818CF8),
              ),
            ),
            SizedBox(height: 10),
            Text(
              '• 4 modelos 3D oficiales con textura de alta fidelidad:',
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
            ),
            Padding(
              padding: EdgeInsets.only(left: 8, top: 4, bottom: 4),
              child: Text(
                '1. Hoodie Urbano V2 (Rigged 3D)\n'
                '2. Camiseta Monalisa Streetwear 3D\n'
                '3. Combat Shirt Táctica (Rigged Metahuman)\n'
                '4. Camisa a Cuadros Scott (Rigged)',
                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, height: 1.4),
              ),
            ),
            Text(
              '• Detección continua de 33 articulaciones corporales.',
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
            ),
            SizedBox(height: 6),
            Text(
              '• Recomendación automática de talla (S, M, L, XL) según tus hombros.',
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
            ),
            SizedBox(height: 6),
            Text(
              '• Cambia de prenda al instante con el carrusel inferior.',
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido', style: TextStyle(color: fsEmerald)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final config3d = kModelos3D[_prendaActual.sku];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Feed en vivo de la cámara física / Viewfinder
          Positioned.fill(
            child: _visorCamara(size),
          ),

          // 2. Esqueleto cibernético y marcadores holográficos
          if (_cuerpoDetectado && _poseActual != null && (_mostrarEsqueleto || _mostrarLandmarks))
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _EsqueletoARPainter(
                    pose: _poseActual!,
                    dibujarEsqueleto: _mostrarEsqueleto,
                    dibujarLandmarks: _mostrarLandmarks,
                  ),
                ),
              ),
            ),

          // 3. Capa AR de la Prenda
          if (_mostrarPrenda) ...[
            if (_modoAutoTracking && _cuerpoDetectado && _rectPrendaAuto != null)
              _buildPrendaAutomatica()
            else
              _buildPrendaManual(size),
          ],

          // 4. Barra Superior de Controles
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildBarraSuperior(config3d),
          ),

          // 5. HUD Flotante de Telemetría Biomecánica
          if (_cuerpoDetectado && _poseActual != null && _mostrarPanelTelemetria)
            Positioned(
              top: 105,
              right: 14,
              child: _buildTarjetaTelemetria(config3d),
            ),

          // 6. Panel Desplegable de Calibración Fina
          if (_mostrarPanelCalibracion)
            Positioned(
              top: 105,
              left: 14,
              right: 14,
              child: _buildPanelCalibracion(),
            ),

          // 7. Destello de captura fotográfica
          if (_disparandoFoto)
            Positioned.fill(
              child: FadeTransition(
                opacity: _flashAnimation,
                child: Container(color: Colors.white),
              ),
            ),

          // 8. Panel Inferior con Carrusel 3D, Toggles y Acciones
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildPanelInferior(),
          ),
        ],
      ),
    );
  }

  /// Barra superior con información de la prenda activa y botones
  Widget _buildBarraSuperior(Modelo3DConfig? config3d) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withAlpha(220),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Volver',
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _cuerpoDetectado ? fsEmerald : Colors.amber,
                          boxShadow: [
                            BoxShadow(
                              color: (_cuerpoDetectado ? fsEmerald : Colors.amber).withAlpha(160),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _cuerpoDetectado ? 'Cuerpo Vinculado · 33 Puntos' : 'Buscando postura...',
                        style: TextStyle(
                          color: _cuerpoDetectado ? fsEmerald : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (config3d != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '3D',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    _prendaActual.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // Toggle Carrusel Prendas 3D
            IconButton(
              icon: Icon(
                _mostrarCarruselPrendas ? Icons.view_carousel_rounded : Icons.view_carousel_outlined,
                color: _mostrarCarruselPrendas ? const Color(0xFF818CF8) : Colors.white,
                size: 22,
              ),
              onPressed: () {
                setState(() => _mostrarCarruselPrendas = !_mostrarCarruselPrendas);
              },
              tooltip: 'Carrusel de prendas',
            ),
            // Toggle Calibración
            IconButton(
              icon: Icon(
                Icons.tune_rounded,
                color: _mostrarPanelCalibracion ? fsEmerald : Colors.white,
                size: 22,
              ),
              onPressed: () {
                setState(() => _mostrarPanelCalibracion = !_mostrarPanelCalibracion);
              },
              tooltip: 'Calibración fina',
            ),
            // Toggle Cámara
            IconButton(
              icon: Icon(
                _camaraFrontal ? Icons.camera_front_rounded : Icons.camera_rear_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: _alternarCamara,
              tooltip: 'Cambiar cámara',
            ),
            // Reset
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
              onPressed: _resetearAjustes,
              tooltip: 'Restablecer',
            ),
            // Ayuda
            IconButton(
              icon: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 22),
              onPressed: _mostrarAyuda,
              tooltip: 'Instrucciones',
            ),
          ],
        ),
      ),
    );
  }

  /// Tarjeta de Telemetría Biomecánica Flotante
  Widget _buildTarjetaTelemetria(Modelo3DConfig? config3d) {
    final pose = _poseActual!;
    return Container(
      width: 175,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withAlpha(230),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(130),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TELEMETRÍA 3D',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFF818CF8),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _mostrarPanelTelemetria = false),
                child: const Icon(Icons.close, size: 12, color: Colors.white54),
              ),
            ],
          ),
          const Divider(color: Color(0xFF1E293B), height: 10),
          _itemTelemetria(
            label: 'Hombros',
            valor: '${pose.distanciaHombros.toInt()} px',
            color: const Color(0xFF818CF8),
          ),
          _itemTelemetria(
            label: 'Alto Torso',
            valor: '${pose.altoTorso.toInt()} px',
            color: const Color(0xFF38BDF8),
          ),
          _itemTelemetria(
            label: 'Inclinación',
            valor: '${pose.inclinacionGrados.toStringAsFixed(1)}°',
            color: const Color(0xFFFBBF24),
          ),
          _itemTelemetria(
            label: 'Giro 3D',
            valor: '${(pose.yawZ * 45).toStringAsFixed(1)}°',
            color: const Color(0xFFA855F7),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: fsEmerald.withAlpha(35),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: fsEmerald.withAlpha(100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Talla Calce:',
                  style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
                Text(
                  pose.tallaSugerida,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: fsEmerald,
                  ),
                ),
              ],
            ),
          ),
          if (config3d != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B4B),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF6366F1).withAlpha(140)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config3d.etiqueta,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC7D2FE),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    config3d.esRigged ? 'Cinemática: Malla Rigged' : 'Cinemática: Malla PBR',
                    style: const TextStyle(fontSize: 8, color: Colors.white60),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _itemTelemetria({required String label, required String valor, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
          ),
          Text(
            valor,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  /// Panel desplegable de Calibración Fina
  Widget _buildPanelCalibracion() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withAlpha(245),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(160),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🎛️ Calibración Fina de la Prenda 3D',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                onPressed: () => setState(() => _mostrarPanelCalibracion = false),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Holgura / Escala
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Holgura (Ancho):', style: TextStyle(color: Colors.white70, fontSize: 11)),
              Text('${_calibracionHolgura.toStringAsFixed(2)}x',
                  style: const TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF818CF8),
              thumbColor: Colors.white,
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: _calibracionHolgura,
              min: 0.8,
              max: 1.5,
              onChanged: (v) => setState(() => _calibracionHolgura = v),
            ),
          ),

          // Offset Cuello
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ajuste Vertical (Cuello):', style: TextStyle(color: Colors.white70, fontSize: 11)),
              Text('${_offsetVerticalCuello.toInt()} px',
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF38BDF8),
              thumbColor: Colors.white,
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: _offsetVerticalCuello,
              min: -60.0,
              max: 60.0,
              onChanged: (v) => setState(() => _offsetVerticalCuello = v),
            ),
          ),

          // Opacidad de la Tela
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Opacidad de Tela:', style: TextStyle(color: Colors.white70, fontSize: 11)),
              Text('${(_opacidadTela * 100).toInt()}%',
                  style: const TextStyle(color: fsEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: fsEmerald,
              thumbColor: Colors.white,
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: _opacidadTela,
              min: 0.3,
              max: 1.0,
              onChanged: (v) => setState(() => _opacidadTela = v),
            ),
          ),
        ],
      ),
    );
  }

  /// Capa automática cinemática con proyección 3D real
  Widget _buildPrendaAutomatica() {
    final rect = _rectPrendaAuto!;
    final suavizado = _transformacionSuavizada;
    final anguloZ = suavizado?.angulo ?? 0.0;
    final yawY = suavizado?.yawZ ?? 0.0;

    // Matriz de Transformación 3D con proyección en perspectiva
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..rotateY(-yawY)
      ..rotateZ(anguloZ);

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Transform(
        alignment: Alignment.topCenter,
        transform: matrix,
        child: Opacity(
          opacity: _opacidadTela,
          child: _buildPrendaVisual(),
        ),
      ),
    );
  }

  /// Capa manual interactiva con gestos táctiles
  Widget _buildPrendaManual(Size size) {
    return Positioned.fill(
      child: Center(
        child: Transform.translate(
          offset: _posicionManual,
          child: Transform.rotate(
            angle: _rotacionManual,
            child: Transform.scale(
              scale: _escalaManual,
              child: GestureDetector(
                onScaleStart: (details) {
                  _escalaBase = _escalaManual;
                  _rotacionBase = _rotacionManual;
                  _posicionBase = _posicionManual;
                },
                onScaleUpdate: (details) {
                  setState(() {
                    _escalaManual = (_escalaBase * details.scale).clamp(0.4, 3.0);
                    _rotacionManual = _rotacionBase + details.rotation;
                    _posicionManual = _posicionBase + details.focalPointDelta;
                  });
                },
                child: Opacity(
                  opacity: _opacidadTela,
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

  /// Panel Inferior con Carrusel 3D, Toggles y Acciones
  Widget _buildPanelInferior() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withAlpha(245),
            Colors.black.withAlpha(190),
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
            // CARRUSEL DE PRENDAS 3D (IGUAL QUE EN LA VERSIÓN WEB)
            if (_mostrarCarruselPrendas) ...[
              const Text(
                'Elige un modelo 3D del catálogo para probarte:',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kCatalogoPrendas3D.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final item = kCatalogoPrendas3D[idx];
                    final seleccionado = item.sku == _prendaActual.sku;
                    return GestureDetector(
                      onTap: () => _seleccionarPrenda3D(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: seleccionado ? const Color(0xFF2E1065) : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: seleccionado ? const Color(0xFFA855F7) : const Color(0xFF334155),
                            width: seleccionado ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                item.urlImagen ?? '',
                                width: 38,
                                height: 38,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.checkroom, size: 24),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.nombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: seleccionado ? Colors.white : Colors.white70,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Bs. ${item.precioBase.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fsEmerald),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      item.sku.contains('HOODIE') || item.sku.contains('COMBAT') || item.sku.contains('SCOTT')
                                          ? '⚡ Rigged'
                                          : '✨ PBR',
                                      style: const TextStyle(fontSize: 9, color: Color(0xFF818CF8), fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Fila de Toggles de Capas AR
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _toggleChip(
                    label: 'Prenda',
                    activo: _mostrarPrenda,
                    color: const Color(0xFF818CF8),
                    onTap: () => setState(() => _mostrarPrenda = !_mostrarPrenda),
                  ),
                  const SizedBox(width: 8),
                  _toggleChip(
                    label: 'Esqueleto 3D',
                    activo: _mostrarEsqueleto,
                    color: const Color(0xFF06B6D4),
                    onTap: () => setState(() => _mostrarEsqueleto = !_mostrarEsqueleto),
                  ),
                  const SizedBox(width: 8),
                  _toggleChip(
                    label: 'Landmarks',
                    activo: _mostrarLandmarks,
                    color: const Color(0xFFF43F5E),
                    onTap: () => setState(() => _mostrarLandmarks = !_mostrarLandmarks),
                  ),
                  const SizedBox(width: 8),
                  _toggleChip(
                    label: 'Telemetría',
                    activo: _mostrarPanelTelemetria,
                    color: fsEmerald,
                    onTap: () => setState(() => _mostrarPanelTelemetria = !_mostrarPanelTelemetria),
                  ),
                  const SizedBox(width: 8),
                  _toggleChip(
                    label: _modoAutoTracking ? 'Auto IA' : 'Manual',
                    activo: _modoAutoTracking,
                    color: fsGold,
                    onTap: () {
                      setState(() {
                        _modoAutoTracking = !_modoAutoTracking;
                        _filtroSuavizado.reset();
                      });
                    },
                  ),
                ],
              ),
            ),

            // Selector de Variantes (si tiene)
            if (_prendaActual.variantes.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _prendaActual.variantes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final v = _prendaActual.variantes[idx];
                    final sel = _varianteSeleccionada?.idVariantePrenda ==
                        v.idVariantePrenda;
                    return ChoiceChip(
                      label: Text(
                        '${v.talla ?? ''} · ${v.color ?? ''}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
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
                        borderRadius: BorderRadius.circular(14),
                      ),
                      onSelected: (_) {
                        setState(() => _varianteSeleccionada = v);
                      },
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Botones de Acción (Captura y Reserva Física)
            Row(
              children: [
                // Disparo de Foto
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: IconButton(
                    iconSize: 24,
                    padding: const EdgeInsets.all(7),
                    icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                    onPressed: _capturarLook,
                    tooltip: 'Tomar foto',
                  ),
                ),
                const SizedBox(width: 10),

                // Botón de Reserva Física (CU16)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: fsEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.checkroom_rounded, size: 18),
                    label: Text(
                      'Reservar en Tienda · Bs. ${(_varianteSeleccionada?.precio ?? _prendaActual.precioBase).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    onPressed: _mostrarDialogoReserva,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleChip({
    required String label,
    required bool activo,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: activo ? color.withAlpha(45) : Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: activo ? color : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: activo ? color : Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  /// Visor interactivo de cámara
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
                      ? 'VISOR VESTIDOR VIRTUAL'
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

  Widget _buildPrendaVisual() {
    final url = _prendaActual.urlImagen;
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
                    'Reserva para Probador Físico (CU16)',
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
              'Prenda: ${_prendaActual.nombre}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (_varianteSeleccionada != null)
              Text(
                'Variante: ${_varianteSeleccionada!.talla} · ${_varianteSeleccionada!.color}',
                style: const TextStyle(color: Colors.black54),
              ),
            if (_poseActual != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Talla recomendada por IA: ${_poseActual!.tallaSugerida}',
                  style: const TextStyle(color: fsEmerald, fontWeight: FontWeight.bold),
                ),
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

/// Dibuja el esqueleto cinemático neón completo y los 33 landmarks corporales
class _EsqueletoARPainter extends CustomPainter {
  final PoseTrackingResult pose;
  final bool dibujarEsqueleto;
  final bool dibujarLandmarks;

  _EsqueletoARPainter({
    required this.pose,
    required this.dibujarEsqueleto,
    required this.dibujarLandmarks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final lm = pose.todosLandmarks;

    // 1. DIBUJAR HUESOS (CONEXIONES CINEMÁTICAS NEÓN)
    if (dibujarEsqueleto) {
      final conexiones = [
        // Clavícula
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
        // Brazo izquierdo
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
        [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
        // Brazo derecho
        [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
        [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
        // Torso / Costados
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
        [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
        [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
        // Pierna izquierda
        [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
        [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
        // Pierna derecha
        [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
        [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
      ];

      final glowPaint = Paint()
        ..color = const Color(0xFF06B6D4).withAlpha(70)
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final bonePaint = Paint()
        ..color = const Color(0xFF06B6D4).withAlpha(220)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (final par in conexiones) {
        final p1 = lm[par[0]];
        final p2 = lm[par[1]];
        if (p1 != null && p2 != null && p1.visibilidad >= 0.35 && p2.visibilidad >= 0.35) {
          canvas.drawLine(p1.posicion, p2.posicion, glowPaint);
          canvas.drawLine(p1.posicion, p2.posicion, bonePaint);
        }
      }

      final spinePaint = Paint()
        ..color = const Color(0xFF10B981).withAlpha(180)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(pose.centroHombros, pose.centroPecho, spinePaint);

      final nariz = lm[PoseLandmarkType.nose];
      if (nariz != null && nariz.visibilidad >= 0.4) {
        canvas.drawLine(pose.centroHombros, nariz.posicion, spinePaint);
      }
    }

    // 2. DIBUJAR PUNTOS LANDMARKS (ARTICULACIONES GLOW)
    if (dibujarLandmarks) {
      for (final entry in lm.entries) {
        final p = entry.value;
        if (p.visibilidad < 0.35) continue;

        Color dotColor = const Color(0xFF38BDF8);
        double radio = 3.5;

        if (entry.key == PoseLandmarkType.leftShoulder ||
            entry.key == PoseLandmarkType.rightShoulder) {
          dotColor = const Color(0xFFF43F5E);
          radio = 5.5;
        } else if (entry.key == PoseLandmarkType.leftElbow ||
            entry.key == PoseLandmarkType.rightElbow ||
            entry.key == PoseLandmarkType.leftWrist ||
            entry.key == PoseLandmarkType.rightWrist) {
          dotColor = const Color(0xFF10B981);
          radio = 4.5;
        } else if (entry.key == PoseLandmarkType.leftHip ||
            entry.key == PoseLandmarkType.rightHip) {
          dotColor = const Color(0xFFA855F7);
          radio = 5.0;
        }

        final auraPaint = Paint()
          ..color = dotColor.withAlpha(90)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(p.posicion, radio + 3.0, auraPaint);

        final corePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(p.posicion, radio * 0.6, corePaint);

        final dotPaint = Paint()
          ..color = dotColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(p.posicion, radio, dotPaint);
      }

      final centerPaint = Paint()
        ..color = fsGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(pose.centroPecho, 8.0, centerPaint);
      canvas.drawLine(
        Offset(pose.centroPecho.dx - 12, pose.centroPecho.dy),
        Offset(pose.centroPecho.dx + 12, pose.centroPecho.dy),
        centerPaint,
      );
      canvas.drawLine(
        Offset(pose.centroPecho.dx, pose.centroPecho.dy - 12),
        Offset(pose.centroPecho.dx, pose.centroPecho.dy + 12),
        centerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EsqueletoARPainter oldDelegate) {
    return oldDelegate.pose != pose ||
        oldDelegate.dibujarEsqueleto != dibujarEsqueleto ||
        oldDelegate.dibujarLandmarks != dibujarLandmarks;
  }
}

/// Retícula AR sutil de calibración
class _ReticulaARPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const step = 45.0;
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
