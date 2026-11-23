# Cierre del frontend RRHH

Este repositorio contiene la aplicación Flutter y sus paquetes locales. El backend se publica por separado en `AndyGuzmanEscalera/correspondencia-sipe-sipe`, rama `develop`, commit `e08980157bde47f9da2a3b0fa79ee92f3c8e1bfb`. No se vuelve a incluir su código ni el ZIP original del lector.

## Configuración de API

`packages/rrhh_api/lib/src/core/network/api_config.dart` recibe `API_BASE_URL` mediante `String.fromEnvironment`. El valor de desarrollo es `http://localhost:8000`; los builds de QA deben especificar `/api` si el frontend y la API comparten origen, o la URL HTTPS real de la API si usan orígenes distintos. No incluir credenciales ni secretos en `--dart-define`: sus valores son públicos en la aplicación web.

## Flutter Web en el dominio independiente

El acceso canónico es `https://rrhh.sipesipe.gob.bo/login`. El inicio usa `/home`. Las secciones protegidas tienen sus propias rutas y el hosting sirve `index.html` al abrirlas directamente. Los favoritos antiguos se redirigen a las rutas actuales.

    flutter build web --release --base-href=/ --dart-define=API_BASE_URL=https://api-rrhh.sipesipe.gob.bo

Comprobar acceso directo, recarga, restauración de sesión y navegación con el botón Atrás del navegador.

## Validaciones

Desde la raíz:

```bash
flutter pub get
flutter analyze
flutter test
flutter test --no-pub packages/rrhh_api/test packages/rrhh_repository/test packages/failures/test
flutter build web
```

`flutter test` desde la raíz ejecuta las pruebas de `test/`; las de los tres paquetes locales se ejecutan explícitamente. El total previo de 149 corresponde a ambas ejecuciones. Los dobles de pruebas no se usan para ejecutar la aplicación contra staging. No se contacta el biométrico desde las pruebas Flutter.

Revalidación de esta entrega: `pub get` correcto; `flutter analyze` sin incidencias; `flutter test` y las suites de paquetes correctas; ejecución conjunta adicional con **149 pruebas aprobadas**. `flutter build web` y el build release con `--base-href=/ --dart-define=API_BASE_URL=/api` terminaron correctamente. El HTML generado conserva `<base href="/">`. Se revisaron 353 archivos preparados para el primer commit y no se encontraron secretos reales; el único literal señalado por la búsqueda fue `debug-invalid-access-token`, una cadena deliberadamente inválida para depuración, inactiva en release. Pub informó versiones nuevas fuera de los constraints y la descontinuación de `url_strategy`; no se actualizaron dependencias ni se ocultaron errores.

## Archivos incluidos y exclusiones

Se incluyen fuentes de `lib/`, paquetes de `packages/`, pruebas, `pubspec.yaml`, `pubspec.lock`, configuración de análisis, `web/`, scaffolding nativo estándar, `.metadata`, `.gitignore` y documentación del frontend y su integración.

Se excluyen, sin borrarlos: `backend/`, `biometric-reader.zip`, `%SystemDrive%/`, `.flutter`, `.flutter_tool_state`, `.vscode/`, `.dart_tool/`, `build/`, caches, dependencias locales Python, PostgreSQL temporal, archivos `.env` reales y claves de firma. Los `.gitignore` de cada plataforma conservan sus exclusiones de archivos generados y configuraciones locales.

El estado inicial de esta revisión fue `master`, sin commits ni remote. El usuario autorizó expresamente el repositorio `https://github.com/AndyGuzmanEscalera/rrhh-sipe-sipe.git` y la rama `main` para la primera publicación. El remoto se comprobó vacío antes de configurar origin. Esta autorización es específica de este repositorio frontend; no cambia la rama ni el backend de Correspondencia.

## Pendientes funcionales para QA

Mantener autenticación y permisos `rrhh.read` / `rrhh.manage`, configurar API/cookies con el origen público correcto y usar la fuente institucional confirmada o la configuración temporal exclusiva de QA. `ready=false` continúa mostrando dependencias pendientes. Los contratos, turnos/calendario histórico, cobertura y la política de tolerancia de salida siguen sujetos a la configuración/confirmación del backend. La importación TXT/DAT conserva sus límites de persistencia documentados. La sincronización manual existente descarga el histórico completo del reloj a través de API/worker; Flutter no se conecta directamente al dispositivo.
