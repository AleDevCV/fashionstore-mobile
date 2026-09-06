# FashionStore — App Móvil (Flutter)

App móvil del **Cliente** de FashionStore (Iteración 1). Consume la misma API
REST de FastAPI que el frontend web (`../fashionstore-backend`).

## Alcance (Iteración 1)

| Caso de uso | Funcionalidad | Endpoint |
| :--- | :--- | :--- |
| CU01 | Inicio y cierre de sesión | `POST /api/login/` |
| CU14 | Catálogo público con filtros y búsqueda | `GET /api/catalogo/`, `GET /api/catalogo/filtros` |
| CU14 | Ficha con disponibilidad por sucursal | `GET /api/catalogo/{id_prenda}` |

> Los casos de uso administrativos (CU02, CU06, CU07, CU08) son propios del
> frontend web (Angular). CU05 (alta de cliente) requiere un endpoint público
> que el backend actual no expone (`POST /api/clientes/` exige token JWT).

## Estructura

```
lib/
├── main.dart                 # Punto de entrada
├── app.dart                  # MaterialApp + tema
├── core/
│   ├── config.dart           # URL base de la API
│   ├── theme.dart            # Tema y utilidades de formato
│   ├── api_client.dart       # Cliente HTTP + traducción de errores
│   ├── widgets.dart          # Imagen de red y badge de stock
│   └── models/               # Modelos (auth y catálogo)
├── services/                 # AuthService y CatalogoService
└── features/
    ├── splash/               # Bienvenida
    ├── login/                # Inicio de sesión (CU01)
    ├── catalogo/             # Vitrina + filtros (CU14)
    └── detalle/              # Ficha + disponibilidad (CU14)
```

## Requisitos

- Flutter SDK 3.3 o superior (con Dart).
- Android Studio / VS Code (con plugin de Flutter) y un emulador Android o
  dispositivo físico.
- El backend corriendo (ver `../fashionstore-backend`).

## Configurar la URL de la API

En `lib/core/config.dart`, el valor por defecto es `http://10.0.2.2:8000`
(alias del `localhost` del host visto desde el emulador de Android).

- **Emulador Android:** `http://10.0.2.2:8000`
- **Dispositivo físico:** usa la IP LAN de tu PC, p. ej. `http://192.168.1.10:8000`
- **Nube:** el dominio público del backend.

También puedes inyectarla sin tocar el código:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
```

## Ejecutar

1. Levanta el backend (Docker) en `../fashionstore-backend`.
2. Si faltan las carpetas de plataforma (`android/`, `ios/`), genera el
   esqueleto con:
   ```bash
   flutter create --platforms=android,ios --org com.fashionstore --project-name fashionstore_mobile .
   ```
3. Instala dependencias y ejecuta:
   ```bash
   flutter pub get
   flutter run
   ```

## Notas

- El cierre de sesión destruye el token en memoria (el backend no guarda estado).
- El catálogo es público: se puede explorar sin iniciar sesión.

