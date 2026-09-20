import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:fashionstore_mobile/features/ar/services/pose_tracking_service.dart';

void main() {
  group('CU18 - CalculadorTransformacionPrenda Math Tests', () {
    test('calcularDistanciaHombros calcula distancia euclidiana exacta', () {
      const pIzq = Offset(100, 200);
      const pDer = Offset(200, 200); // Diferencia horizontal de 100
      final dist =
          CalculadorTransformacionPrenda.calcularDistanciaHombros(pIzq, pDer);
      expect(dist, 100.0);

      // Triángulo 3-4-5
      const p1 = Offset(0, 0);
      const p2 = Offset(30, 40);
      final dist2 =
          CalculadorTransformacionPrenda.calcularDistanciaHombros(p1, p2);
      expect(dist2, 50.0);
    });

    test('calcularAnguloHombros retorna 0 para hombros horizontales', () {
      const pIzq = Offset(100, 200);
      const pDer = Offset(250, 200);
      final angulo =
          CalculadorTransformacionPrenda.calcularAnguloHombros(pIzq, pDer);
      expect(angulo, 0.0);
    });

    test('calcularAnguloHombros detecta inclinación a 45 grados', () {
      const pIzq = Offset(100, 100);
      const pDer = Offset(200, 200);
      final angulo =
          CalculadorTransformacionPrenda.calcularAnguloHombros(pIzq, pDer);
      expect(angulo, closeTo(math.pi / 4, 0.001));
    });

    test('calcularRectPrenda aplica proporción y compensación de cuello', () {
      const centro = Offset(200, 300);
      const distHombros = 100.0;
      const aspect = 1.2; // Alto = Ancho * 1.2
      const scaleFactor = 1.15;

      final rect = CalculadorTransformacionPrenda.calcularRectPrenda(
        centroHombros: centro,
        distanciaHombros: distHombros,
        aspectPrenda: aspect,
        factorEscala: scaleFactor,
        compensacionCuello: 0.12,
      );

      // Ancho esperado = 100 * 1.6 * 1.15 = 184.0
      expect(rect.width, 184.0);
      // Alto esperado = 184 * 1.2 = 220.8
      expect(rect.height, closeTo(220.8, 0.01));

      // Left esperado = 200 - (184 / 2) = 108.0
      expect(rect.left, 108.0);
      // Top esperado = 300 - (220.8 * 0.12) = 300 - 26.496 = 273.504
      expect(rect.top, closeTo(273.504, 0.01));
    });

    test('calcularRectPrenda con heurística calibrada eleva cuello a la base clavicular', () {
      const centro = Offset(200, 300);
      const distHombros = 100.0;
      const aspect = 1.22;
      const scaleFactor = 1.20;

      final rect = CalculadorTransformacionPrenda.calcularRectPrenda(
        centroHombros: centro,
        distanciaHombros: distHombros,
        aspectPrenda: aspect,
        factorEscala: scaleFactor,
        compensacionCuello: 0.22,
        desplazamientoVertical: -(distHombros * 0.05),
      );

      // Ancho esperado = 100 * 1.6 * 1.20 = 192.0
      expect(rect.width, 192.0);
      // Alto esperado = 192 * 1.22 = 234.24
      expect(rect.height, closeTo(234.24, 0.01));
      // Left esperado = 200 - (192 / 2) = 104.0
      expect(rect.left, 104.0);
      // Top esperado = 300 - (234.24 * 0.22) - 5.0 = 300 - 51.5328 - 5.0 = 243.4672
      expect(rect.top, closeTo(243.4672, 0.01));
      // El cuello de la prenda se eleva >55px sobre el centro de los hombros hacia la base del cuello
      expect(centro.dy - rect.top, greaterThan(50.0));
    });
  });

  group('CU18 - FiltroSuavizadoAR (EMA) Tests', () {
    test('Primer frame inicializa los valores directamente sin retardo', () {
      final filtro = FiltroSuavizadoAR(alpha: 0.25);
      final t1 = filtro.suavizar(
        nuevoCentro: const Offset(100, 100),
        nuevaDistancia: 120,
        nuevoAngulo: 0.1,
      );

      expect(t1.centro, const Offset(100, 100));
      expect(t1.distanciaHombros, 120);
      expect(t1.angulo, 0.1);
    });

    test('Segundo frame aplica fórmula EMA ponderando alpha', () {
      final filtro = FiltroSuavizadoAR(alpha: 0.20);
      filtro.suavizar(
        nuevoCentro: const Offset(100, 100),
        nuevaDistancia: 100,
        nuevoAngulo: 0.0,
      );

      // Salto brusco a 200
      final t2 = filtro.suavizar(
        nuevoCentro: const Offset(200, 200),
        nuevaDistancia: 200,
        nuevoAngulo: 1.0,
      );

      // Con alpha = 0.20:
      // Centro = 100 * 0.8 + 200 * 0.2 = 120
      expect(t2.centro.dx, 120.0);
      expect(t2.centro.dy, 120.0);
      // Distancia = 100 * 0.8 + 200 * 0.2 = 120
      expect(t2.distanciaHombros, 120.0);
      // Ángulo = 0 * 0.8 + 1 * 0.2 = 0.2
      expect(t2.angulo, closeTo(0.2, 0.001));
    });

    test('Reset limpia estado previo', () {
      final filtro = FiltroSuavizadoAR(alpha: 0.20);
      filtro.suavizar(
        nuevoCentro: const Offset(100, 100),
        nuevaDistancia: 100,
        nuevoAngulo: 0.0,
      );
      filtro.reset();

      final t = filtro.suavizar(
        nuevoCentro: const Offset(500, 500),
        nuevaDistancia: 300,
        nuevoAngulo: 0.5,
      );
      expect(t.centro, const Offset(500, 500));
      expect(t.distanciaHombros, 300);
    });
  });
}
