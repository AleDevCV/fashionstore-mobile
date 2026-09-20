import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Datos estructurados de la pose detectada normalizada a la pantalla
class PoseTrackingResult {
  final Offset hombroIzquierdo;
  final Offset hombroDerecho;
  final Offset? caderaIzquierda;
  final Offset? caderaDerecha;
  final double distanciaHombros;
  final double angulo;
  final Offset centroHombros;
  final double confianza;

  const PoseTrackingResult({
    required this.hombroIzquierdo,
    required this.hombroDerecho,
    this.caderaIzquierda,
    this.caderaDerecha,
    required this.distanciaHombros,
    required this.angulo,
    required this.centroHombros,
    required this.confianza,
  });
}

/// Transformación calculada para superponer la prenda con suavizado
class PoseTransformacion {
  final Offset centro;
  final double distanciaHombros;
  final double angulo;

  const PoseTransformacion({
    required this.centro,
    required this.distanciaHombros,
    required this.angulo,
  });
}

/// Filtro de Suavizado Temporal (Exponential Moving Average - EMA)
/// Elimina las micro-vibraciones y saltos bruscos entre cuadros consecutivos (30-60 FPS)
class FiltroSuavizadoAR {
  final double alpha;
  Offset? _centroAnterior;
  double? _distanciaAnterior;
  double? _anguloAnterior;

  FiltroSuavizadoAR({this.alpha = 0.22});

  PoseTransformacion suavizar({
    required Offset nuevoCentro,
    required double nuevaDistancia,
    required double nuevoAngulo,
  }) {
    if (_centroAnterior == null) {
      _centroAnterior = nuevoCentro;
      _distanciaAnterior = nuevaDistancia;
      _anguloAnterior = nuevoAngulo;
      return PoseTransformacion(
        centro: nuevoCentro,
        distanciaHombros: nuevaDistancia,
        angulo: nuevoAngulo,
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

    return PoseTransformacion(
      centro: _centroAnterior!,
      distanciaHombros: _distanciaAnterior!,
      angulo: _anguloAnterior!,
    );
  }

  void reset() {
    _centroAnterior = null;
    _distanciaAnterior = null;
    _anguloAnterior = null;
  }
}

/// Fórmulas matemáticas adaptadas desde Yashikashrivastava30/Virtual-Try-On-Model
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

  /// Dimensiones y posición de anclaje de la prenda para ajuste AR de prendas transparentes PNG.
  /// Ancho = distancia_hombros * 1.6 * factorEscala (cubre hombros y sisa)
  /// Alto = Ancho * aspectPrenda
  /// Y = centro_hombros.y - (alto * compensacionCuello) + desplazamientoVertical
  /// La compensación eleva la apertura del cuello de la prenda para que coincida exactamente
  /// con la base del cuello / horquilla esternal del usuario detectado por MediaPipe.
  static Rect calcularRectPrenda({
    required Offset centroHombros,
    required double distanciaHombros,
    required double aspectPrenda,
    double factorEscala = 1.15,
    double compensacionCuello = 0.12,
    double desplazamientoVertical = 0.0,
  }) {
    final anchoPrenda = distanciaHombros * 1.6 * factorEscala;
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

    // Verificar visibilidad / confianza mínima
    if (lmIzq.likelihood < 0.45 || lmDer.likelihood < 0.45) return null;

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

    Offset proyectar(PoseLandmark lm) {
      double px = lm.x * escalaX;
      double py = lm.y * escalaY;

      // Si es cámara frontal, invertir horizontalmente por efecto espejo
      if (esFrontal) {
        px = tamanoPantalla.width - px;
      }
      return Offset(px, py);
    }

    final pIzq = proyectar(lmIzq);
    final pDer = proyectar(lmDer);

    final distancia =
        CalculadorTransformacionPrenda.calcularDistanciaHombros(pIzq, pDer);
    if (distancia < 20.0) return null; // Filtrar detecciones espurias

    final angulo =
        CalculadorTransformacionPrenda.calcularAnguloHombros(pIzq, pDer);

    final centro = Offset(
      (pIzq.dx + pDer.dx) / 2.0,
      (pIzq.dy + pDer.dy) / 2.0,
    );

    // Caderas opcionales para referencias de largo
    Offset? cIzq;
    Offset? cDer;
    final cadIzq = pose.landmarks[PoseLandmarkType.leftHip];
    final cadDer = pose.landmarks[PoseLandmarkType.rightHip];
    if (cadIzq != null && cadIzq.likelihood >= 0.40) {
      cIzq = proyectar(cadIzq);
    }
    if (cadDer != null && cadDer.likelihood >= 0.40) {
      cDer = proyectar(cadDer);
    }

    final confianzaPromedio = (lmIzq.likelihood + lmDer.likelihood) / 2.0;

    return PoseTrackingResult(
      hombroIzquierdo: pIzq,
      hombroDerecho: pDer,
      caderaIzquierda: cIzq,
      caderaDerecha: cDer,
      distanciaHombros: distancia,
      angulo: angulo,
      centroHombros: centro,
      confianza: confianzaPromedio,
    );
  }

  void dispose() {
    _poseDetector.close();
  }
}
