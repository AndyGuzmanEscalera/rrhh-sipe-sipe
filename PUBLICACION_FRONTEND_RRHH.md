# Cierre del frontend RRHH

Este repositorio contiene la aplicación Flutter y sus paquetes locales. El backend se publica por separado en `AndyGuzmanEscalera/correspondencia-sipe-sipe`, rama `develop`, commit `e08980157bde47f9da2a3b0fa79ee92f3c8e1bfb`. No se vuelve a incluir su código ni el ZIP original del lector.

## Configuración de API

`packages/rrhh_api/lib/src/core/network/api_config.dart` recibe `API_BASE_URL` mediante `String.fromEnvironment`. El valor de desarrollo es `http://localhost:8000`; los builds de QA deben especificar `/api` si el frontend y la API comparten origen, o la URL HTTPS real de la API si usan orígenes distintos. No incluir credenciales ni secretos en `--dart-define`: sus valores son públicos en la aplicación web.

## Rutas y publicación posterior en `/rrhh/`

Se revisaron `lib/core/routes.dart`, `lib/core/router.dart`, `lib/bootstrap.dart`, `web/index.html` y el código de `PathUrlStrategy` del SDK instalado. Las rutas actuales son `/`, `/rrhh`, `/rrhh/login` y `/rrhh/home`; `setPathUrlStrategy()` está activo. El HTML mantiene el placeholder original `$FLUTTER_BASE_HREF`.

`PathUrlStrategy` elimina el base path al interpretar URLs y lo antepone al publicar rutas internas. Con estas rutas, `--base-href=/rrhh/` puede transformar `/rrhh/home` en `/rrhh/rrhh/home`; al abrir `/rrhh/home`, el router recibiría `/home`, que no está declarado. No combinar ambas configuraciones.

Comando compatible con las rutas **actuales**, sin modificarlas:

```bash
flutter build web --release --base-href=/ --dart-define=API_BASE_URL=/api
```

Este comando conserva las URLs `/rrhh/login` y `/rrhh/home`. **No basta por sí solo para alojar todos los archivos exclusivamente bajo `/rrhh/`**: con base `/`, el navegador pide bootstrap, JavaScript y otros recursos desde la raíz del dominio. Antes de desplegar, el responsable de QA debe resolver ese mapeo estático y el fallback SPA de `/rrhh`, `/rrhh/` y `/rrhh/*` al HTML de RRHH, sin capturar `/api` ni rutas de otras aplicaciones.

Si Correspondencia ya ocupa la raíz, publicar recursos RRHH con los mismos nombres puede interferir con ella. En ese escenario no existe un flag de build que resuelva simultáneamente el aislamiento de recursos y el prefijo que ya contiene el router. Habrá que aprobar una configuración coherente de subruta (por ejemplo, rutas internas sin `/rrhh` junto con base `/rrhh/`) o una estrategia explícita de carga de recursos. Esa decisión funcional/de servidor queda para la preparación del despliegue; esta entrega conserva router, bootstrap y base href fuente.

No se ha configurado Apache ni publicado un build en QA. Antes de desplegar validar en navegador las rutas iniciales, login, sesión restaurada, F5 en `/rrhh/home`, recursos estáticos, navegación atrás y acceso a API por HTTPS.

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
