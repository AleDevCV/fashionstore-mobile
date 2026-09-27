/// ConfiguraciÃ³n global de la app mÃ³vil de FashionStore.
library;

/// URL base de la API REST (FastAPI).
///
/// Como el backend vive en el mismo equipo, el valor depende de dÃ³nde corra la
/// app:
///   - Dispositivo fÃ­sico (LAN Wi-Fi): http://192.168.1.18:8000
///   - Emulador de Android: http://10.0.2.2:8000  (alias del localhost del host).
///   - Despliegue en la nube: https://api.fashionstore.example.com
///
/// Puede sobrescribirse en tiempo de compilaciÃ³n con:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.9:8000
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://fashionstore.aledevcv.me',
);

const String webBaseUrl = String.fromEnvironment(
  'WEB_BASE_URL',
  defaultValue: 'https://fashionstore.aledevcv.me',
);
