# Impulsa Suite · Flutter Web

Migración del frontend React de Impulsa Suite a Flutter Web con Material 3,
`go_router`, `provider`, repositories mock y persistencia local de sesión.

## Requisitos

- Flutter 3.44 o superior
- Dart 3.12 o superior
- Edge o Chrome para ejecutar Flutter Web

## Ejecución

```powershell
flutter pub get
flutter run -d edge
```

Cuenta tenant mock:

- Correo: `m.lopez@grupovega.mx`
- Contraseña: cualquier valor no vacío, por ejemplo `demo1234`
- Roles: `OWNER`, `BRANCH_MANAGER`, `CASHIER` y `WAITER`
- Sucursal inicial: `CDMX-01`

Cuenta superadmin mock:

- Correo: `admin@impulsa.io`
- Contraseña: `demo1234`

## Calidad

```powershell
dart format lib test
dart analyze
flutter test
flutter build web
```

### `flutter analyze` y rutas con caracteres no ASCII

Flutter 3.44.4 calcula `Content-Length` con `message.length` al enviar el
mensaje LSP. Si la ruta del proyecto contiene `ñ`, como `Diseño`, el JSON llega
truncado al servidor y aparece `FormatException: Unexpected end of input`.
No es un error del código Dart.

Este proyecto incluye un comando que crea una unidad ASCII temporal, ejecuta
el análisis sobre los mismos archivos y elimina la unidad al terminar:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\flutter_analyze.ps1
```

Para omitir `pub get` durante el análisis:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\flutter_analyze.ps1 -NoPub
```

La alternativa permanente es mover el proyecto a una ruta que use solamente
caracteres ASCII.

## Estructura

- `lib/app`: router, guards y providers.
- `lib/core`: tema, red y utilidades.
- `lib/shared`: shells, estados y widgets transversales.
- `lib/features`: sesión, tenant, inventario, compras, POS, finanzas,
  analítica, restaurante, mesero y superadmin.
- `test`: persistencia de sesión y regresiones de layout.
