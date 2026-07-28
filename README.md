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

`API_BASE_URL` usa `http://localhost:3000` de forma predeterminada.

- HU01 consume las rutas reales de Superadmin bajo `/api/v1/superadmin`.
- HU02 consume autenticación, sesión, sucursales, usuarios y roles reales.
- HU03 consume catálogo, inventario, alertas, movimientos, proveedores y
  órdenes de compra reales.
- HU04 consume turnos de caja, búsqueda POS, ventas, tickets e intents de
  pago reales bajo `/api/v1/tenant/pos`.
- HU05 consume categorías, gastos operativos y los cuatro dashboards reales
  bajo `/api/v1/tenant/finance` y `/api/v1/tenant/analytics`.

Cada contexto conserva su propia sesión. El frontend no incluye credenciales
tenant ni datos simulados para HU01-HU05; deben usarse cuentas existentes en el
backend local. HU06 y posteriores continúan migrándose por fases.

## Calidad

```powershell
dart format lib test
flutter analyze
flutter test
flutter build web --dart-define=API_BASE_URL=http://localhost:3000
```

### `flutter analyze` y rutas con caracteres no ASCII

Flutter puede fallar al analizar desde rutas que contienen caracteres no ASCII.
Este proyecto incluye un comando que crea una unidad ASCII temporal, ejecuta el
análisis sobre los mismos archivos y elimina la unidad al terminar:

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
- `test`: persistencia de sesión, contratos por HU y regresiones de layout.
