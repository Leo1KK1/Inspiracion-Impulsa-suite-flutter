# Impulsa Suite · Flutter Web

Frontend Flutter Web de Impulsa Suite con Material 3, `go_router`, `provider`
y repositorios por historia de usuario.

## Requisitos

- Flutter 3.44 o superior
- Dart 3.12 o superior
- Edge o Chrome para ejecutar Flutter Web
- Backend local de Impulsa Suite

## Ejecución

```powershell
flutter pub get
flutter run -d edge --dart-define=API_BASE_URL=http://localhost:3000
```

`API_BASE_URL` usa `http://localhost:3000` de forma predeterminada. HU01
consume las 12 rutas reales bajo `/api/v1/superadmin` y persiste su sesión con
una clave separada de la sesión tenant.

Las historias posteriores continúan en migración por fases. Mientras HU02 no
se integre, la cuenta tenant de desarrollo es:

- Correo: `m.lopez@grupovega.mx`
- Contraseña: cualquier valor no vacío, por ejemplo `demo1234`
- Roles: `OWNER`, `BRANCH_MANAGER`, `CASHIER` y `WAITER`
- Sucursal inicial: `CDMX-01`

## Calidad

```powershell
dart format lib test
flutter analyze
flutter test
flutter build web --dart-define=API_BASE_URL=http://localhost:3000
```

### `flutter analyze` y rutas con caracteres no ASCII

Flutter 3.44.4 puede fallar al analizar desde rutas que contienen caracteres
no ASCII. Este proyecto incluye un comando que crea una unidad ASCII temporal,
ejecuta el análisis sobre los mismos archivos y elimina la unidad al terminar:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\flutter_analyze.ps1
```

Para omitir `pub get` durante el análisis:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\flutter_analyze.ps1 -NoPub
```

## Estructura

- `lib/app`: router, guards y providers.
- `lib/core`: configuración, tema, red y utilidades.
- `lib/shared`: shells, estados y widgets transversales.
- `lib/features`: sesión, tenant, inventario, compras, POS, finanzas,
  analítica, restaurante, mesero y superadmin.
- `test`: persistencia de sesión, contratos HU01 y regresiones de layout.
