import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Punto espacial normalizado y proyectado a la pantalla con profundidad y visibilidad
class LandmarkPunto {
  final Offset posicion;
  final double z;
  final double visibilidad;

  const LandmarkPunto({
    required this.posicion,
    required this.z,
    required this.visibilidad,
  });
}

/// Datos cinemáticos y anatómicos completos detectados por Google ML Kit (MediaPipe 33 Landmarks)
class PoseTrackingResult {
  // Puntos anatómicos principales
  final Offset hombroIzquierdo;
  final Offset hombroDerecho;
  final Offset? codoIzquierdo;
  final Offset? codoDerecho;
  final Offset? munecaIzquierda;
  final Offset? munecaDerecha;
  final Offset? caderaIzquierda;
  final Offset? caderaDerecha;
  final Offset? rodillaIzquierda;
  final Offset? rodillaDerecha;
  final Offset? tobilloIzquierdo;
  final Offset? tobilloDerecho;
  final Offset? nariz;

  // Diccionario completo de landmarks disponibles
  final Map<PoseLandmarkType, LandmarkPunto> todosLandmarks;

  // Métricas biomecánicas en píxeles y grados (Telemetría idéntica a la versión Web)
  final double distanciaHombros;
  final double altoTorso;
  final double angulo; // Roll en radianes
  final double inclinacionGrados; // Roll en grados (-180° a 180°)
  final double yawZ; // Diferencia de profundidad z (rotación en Y)
  final Offset centroHombros;
  final Offset centroPecho;
  final String tallaSugerida; // S, M, L, XL
  final double confianza;

  const PoseTrackingResult({
    required this.hombroIzquierdo,
    required this.hombroDerecho,
    this.codoIzquierdo,
    this.codoDerecho,
    this.munecaIzquierda,
    this.munecaDerecha,
    this.caderaIzquierda,
    this.caderaDerecha,
    this.rodillaIzquierda,
    this.rodillaDerecha,
    this.tobilloIzquierdo,
    this.tobilloDerecho,
    this.nariz,
    required this.todosLandmarks,
    required this.distanciaHombros,
    required this.altoTorso,
    required this.angulo,
    required this.inclinacionGrados,
    required this.yawZ,
    required this.centroHombros,
    required this.centroPecho,
    required this.tallaSugerida,
    required this.confianza,
  });
}

/// Transformación calculada para superponer la prenda con suavizado anti-vibración
class PoseTransformacion {
  final Offset centro;
  final double distanciaHombros;
  final double angulo;
  final double yawZ;

  const PoseTransformacion({
    required this.centro,
    required this.distanciaHombros,
    required this.angulo,
    this.yawZ = 0.0,
  });
}

/// Filtro de Suavizado Temporal (Exponential Moving Average - EMA)
/// Elimina las micro-vibraciones y saltos bruscos entre cuadros consecutivos (30-60 FPS)
class FiltroSuavizadoAR {
  final double alpha;
  Offset? _centroAnterior;
  double? _distanciaAnterior;
  double? _anguloAnterior;
  double? _yawAnterior;

  FiltroSuavizadoAR({this.alpha = 0.22});

  PoseTransformacion suavizar({
    required Offset nuevoCentro,
    required double nuevaDistancia,
    required double nuevoAngulo,
    double nuevoYaw = 0.0,
  }) {
    if (_centroAnterior == null) {
      _centroAnterior = nuevoCentro;
      _distanciaAnterior = nuevaDistancia;
      _anguloAnterior = nuevoAngulo;
      _yawAnterior = nuevoYaw;
      return PoseTransformacion(
        centro: nuevoCentro,
        distanciaHombros: nuevaDistancia,
        angulo: nuevoAngulo,
        yawZ: nuevoYaw,
      );
    }

    _centroAnterior = Offset(
      _centroAnterior!.dx * (1 - alpha) + nuevoCentro.dx * alpha,
      _centroAnterior!.dy * (1 - alpha) + nuevoCentro.dy * alpha,
    );
    _distanciaAnterior =
        _distanciaAnterior! * (1 - alpha) + nuevaDistancia * alpha;
    _anguloAnterior =
        _anguloAnterior! * (1 - alpha) + nuevoAngulo * alpha;
    _yawAnterior =
        (_yawAnterior ?? 0.0) * (1 - alpha) + nuevoYaw * alpha;

    return PoseTransformacion(
      centro: _centroAnterior!,
      distanciaHombros: _distanciaAnterior!,
      angulo: _anguloAnterior!,
      yawZ: _yawAnterior!,
    );
  }

  void reset() {
    _centroAnterior = null;
    _distanciaAnterior = null;
    _anguloAnterior = null;
    _yawAnterior = null;
  }
}

/// Fórmulas matemáticas de cinemática corporal y anclaje textil
class CalculadorTransformacionPrenda {
  /// Distancia euclidiana entre ambos hombros
  static double calcularDistanciaHombros(Offset izq, Offset der) {
    final dx = der.dx - izq.dx;
    final dy = der.dy - izq.dy;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Inclinación postural en radianes (atan2)
  static double calcularAnguloHombros(Offset izq, Offset der) {
    return math.atan2(der.dy - izq.dy, der.dx - izq.dx);
  }

  /// Dimensiones y posición de anclaje de la prenda para ajuste AR.
  /// La compensación eleva la apertura del cuello de la prenda para que coincida exactamente
  /// con la base del cuello / horquilla esternal detectada.
  static Rect calcularRectPrenda({
    required Offset centroHombros,
    required double distanciaHombros,
    required double aspectPrenda,
    double factorEscala = 1.15,
    double compensacionCuello = 0.14,
    double desplazamientoVertical = 0.0,
  }) {
    final anchoPrenda = distanciaHombros * 1.65 * factorEscala;
    final altoPrenda = anchoPrenda * aspectPrenda;

    final left = centroHombros.dx - (anchoPrenda / 2.0);
    final top = centroHombros.dy -
        (altoPrenda * compensacionCuello) +
        desplazamientoVertical;

    return Rect.fromLTWH(left, top, anchoPrenda, altoPrenda);
  }
}

/// Servicio On-Device para procesamiento de cuadros de video y detección corporal
class PoseTrackingService {
  late final PoseDetector _poseDetector;

  PoseTrackingService() {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base,
      ),
    );
  }

  /// Convierte un CameraImage a InputImage de ML Kit respetando orientación del sensor
  InputImage? convertirCameraImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    final sensorOrientation = camera.sensorOrientation;
    final rotation =
        InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (image.planes.isEmpty) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  /// Procesa el frame de la cámara y retorna las coordenadas proyectadas al tamaño de la pantalla
  Future<PoseTrackingResult?> procesarFrame({
    required CameraImage image,
    required CameraDescription camera,
    required Size tamanoPantalla,
  }) async {
    final inputImage = convertirCameraImage(image, camera);
    if (inputImage == null) return null;

    final poses = await _poseDetector.processImage(inputImage);
    if (poses.isEmpty) return null;

    final pose = poses.first;
    final lmIzq = pose.landmarks[PoseLandmarkType.leftShoulder];
    final lmDer = pose.landmarks[PoseLandmarkType.rightShoulder];

    if (lmIzq == null || lmDer == null) return null;

    // Verificar visibilidad / confianza mínima en hombros
    if (lmIzq.likelihood < 0.40 || lmDer.likelihood < 0.40) return null;

    // Mapeo de coordenadas de la imagen a la pantalla
    final sensorOrientation = camera.sensorOrientation;
    final esRotado =
        sensorOrientation == 90 || sensorOrientation == 270;
    final anchoFrame =
        esRotado ? image.height.toDouble() : image.width.toDouble();
    final altoFrame =
        esRotado ? image.width.toDouble() : image.height.toDouble();

    final escalaX = tamanoPantalla.width / anchoFrame;
    final escalaY = tamanoPantalla.height / altoFrame;
    final esFrontal = camera.lensDirection == CameraLensDirection.front;

    LandmarkPunto proyectar(PoseLandmark lm) {
      double px = lm.x * escalaX;
      double py = lm.y * escalaY;

      // Si es cámara frontal, invertir horizontalmente por efecto espejo
      if (esFrontal) {
        px = tamanoPantalla.width - px;
      }
      return LandmarkPunto(
        posicion: Offset(px, py),
        z: lm.z,
        visibilidad: lm.likelihood,
      );
    }

    // Proyectar todos los landmarks disponibles de la postura
    final Map<PoseLandmarkType, LandmarkPunto> todosMap = {};
    for (final entry in pose.landmarks.entries) {
      todosMap[entry.key] = proyectar(entry.value);
    }

    final pIzq = todosMap[PoseLandmarkType.leftShoulder]!.posicion;
    final pDer = todosMap[PoseLandmarkType.rightShoulder]!.posicion;

    final distanciaHombros =
        CalculadorTransformacionPrenda.calcularDistanciaHombros(pIzq, pDer);
    if (distanciaHombros < 25.0) return null; // Filtrar detecciones erráticas

    final angulo =
        CalculadorTransformacionPrenda.calcularAnguloHombros(pIzq, pDer);
    final inclinacionGrados = (angulo * 180.0) / math.pi;

    // Diferencia Z para estimación de rotación Yaw 3D (giro del cuerpo)
    final zIzq = lmIzq.z;
    final zDer = lmDer.z;
    // Si es cámara frontal invertida, el yaw acompaña la perspectiva
    final yawZ = ((zDer - zIzq) / 120.0).clamp(-0.45, 0.45);

    final centroHombros = Offset(
      (pIzq.dx + pDer.dx) / 2.0,
      (pIzq.dy + pDer.dy) / 2.0,
    );

    // Caderas para cálculo del alto del torso
    final cadIzq = todosMap[PoseLandmarkType.leftHip];
    final cadDer = todosMap[PoseLandmarkType.rightHip];

    double altoTorso = distanciaHombros * 1.25; // Proporción estimada por defecto
    Offset centroCaderas = Offset(centroHombros.dx, centroHombros.dy + altoTorso);

    if (cadIzq != null && cadDer != null && cadIzq.visibilidad >= 0.35 && cadDer.visibilidad >= 0.35) {
      centroCaderas = Offset(
        (cadIzq.posicion.dx + cadDer.posicion.dx) / 2.0,
        (cadIzq.posicion.dy + cadDer.posicion.dy) / 2.0,
      );
      final dxTorso = centroCaderas.dx - centroHombros.dx;
      final dyTorso = centroCaderas.dy - centroHombros.dy;
      altoTorso = math.sqrt(dxTorso * dxTorso + dyTorso * dyTorso);
    }

    // Centro del pecho / esternón (anclaje de ropa como en Three.js web)
    final centroPecho = Offset(
      (centroHombros.dx * 2.0 + centroCaderas.dx) / 3.0,
      (centroHombros.dy * 2.0 + centroCaderas.dy) / 3.0,
    );

    // Estimación de talla recomendada según proporciones anatómicas
    String talla = 'M';
    final ratioAncho = distanciaHombros / tamanoPantalla.width;
    if (ratioAncho < 0.30) {
      talla = 'S';
    } else if (ratioAncho > 0.52) {
      talla = 'XL';
    } else if (ratioAncho > 0.42) {
      talla = 'L';
    } else {
      talla = 'M';
    }

    final confianzaPromedio = (lmIzq.likelihood + lmDer.likelihood) / 2.0;

    return PoseTrackingResult(
      hombroIzquierdo: pIzq,
      hombroDerecho: pDer,
      codoIzquierdo: todosMap[PoseLandmarkType.leftElbow]?.posicion,
      codoDerecho: todosMap[PoseLandmarkType.rightElbow]?.posicion,
      munecaIzquierda: todosMap[PoseLandmarkType.leftWrist]?.posicion,
      munecaDerecha: todosMap[PoseLandmarkType.rightWrist]?.posicion,
      caderaIzquierda: cadIzq?.posicion,
      caderaDerecha: cadDer?.posicion,
      rodillaIzquierda: todosMap[PoseLandmarkType.leftKnee]?.posicion,
      rodillaDerecha: todosMap[PoseLandmarkType.rightKnee]?.posicion,
      tobilloIzquierdo: todosMap[PoseLandmarkType.leftAnkle]?.posicion,
      tobilloDerecho: todosMap[PoseLandmarkType.rightAnkle]?.posicion,
      nariz: todosMap[PoseLandmarkType.nose]?.posicion,
      todosLandmarks: todosMap,
      distanciaHombros: distanciaHombros,
      altoTorso: altoTorso,
      angulo: angulo,
      inclinacionGrados: inclinacionGrados,
      yawZ: yawZ,
      centroHombros: centroHombros,
      centroPecho: centroPecho,
      tallaSugerida: talla,
      confianza: confianzaPromedio,
    );
  }

  void dispose() {
    _poseDetector.close();
  }
}
