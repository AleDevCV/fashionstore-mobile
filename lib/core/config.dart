/// Configuración global de la app móvil de FashionStore.
library;

/// URL base de la API REST (FastAPI).
///
/// Como el backend vive en el mismo equipo, el valor depende de dónde corra la
/// app:
///   - Emulador de Android: http://10.0.2.2:8000  (alias del localhost del host).
///   - Dispositivo físico:  http://<IP-LAN-DE-TU-PC>:8000  (ej. http://192.168.1.10:8000).
///   - Despliegue en la nube: https://api.fashionstore.example.com
///
/// Puede sobrescribirse en tiempo de compilación con:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);
