# Migración de la base común a rrhh_sipe_sipe

Fecha: 7 de octubre de 2026.
Origen de lectura: C:\dev\correspondencia_sipe_sipe. Destino de todas las escrituras de esta tarea: C:\Andy\proyectos\rrhh_sipe_sipe.

## Arquitectura revisada

Se inventariaron lib, packages, test, web, backend, database, deploy, scripts, website y configuración del origen. Website es un producto Astro independiente y backend contiene FastAPI, SQLAlchemy y Alembic; ninguno se copió. La base Flutter sigue Widget → Cubit → Repository → API/ApiMethod/Dio. Result, Failure, handleExceptions y listeners devuelven errores a la interfaz. GetIt conserva inyección separada para repositorios e infraestructura y cubits.

## Base copiada y adaptada

- lib/core: app, permisos y guard, contexto institucional de sesión, helpers, formularios, tema, diseño responsive, utilidades de descarga, router y rutas.
- lib/shared/widgets: formularios, diálogos, superficies, tablas genéricas y paginación, indicadores, estados vacíos y componentes visuales.
- lib/features/app, authentication y splash: sesión global, login y restauración de sesión.
- lib/injection: GetIt y registros exclusivos de API, autenticación y sesión.
- packages/rrhh_api: red Dio, logging, interceptores, coordinación de refresh, token store, modelos de autenticación y modelos genéricos de paginación/estado activo.
- packages/rrhh_repository: autenticación, entidades de sesión/contexto institucional, mapper de usuario y contenedor genérico AdminPage.
- packages/failures: Result, excepciones, Failure, mensajes y normalización de errores.
- Pruebas reutilizables de red, refresh, repositorio de autenticación, permisos, sesión, descargas y errores.

Los paquetes locales se renombraron a rrhh_api y rrhh_repository. Se adaptaron imports y exports, pubspec, textos de login e identidad institucional. Se creó un inicio autenticado mínimo sin módulos de negocio y una prueba de redirección al login cuando termina la sesión.

## Archivos reemplazados y exclusiones

Se reemplazaron lib/main.dart, pubspec.yaml, analysis_options.yaml, README.md y el test del contador generado por Flutter. Se añadió permiso INTERNET al manifiesto Android. No se eliminaron archivos existentes.

No se copiaron correspondencias, derivaciones, hojas de ruta, bandejas, dashboard operativo, seguimiento, consulta pública, reportes, módulos de administración, APIs/repositorios de negocio, backend, base de datos, deploy, website, secretos .env, cachés ni artefactos compilados del origen. core/data/local_store.dart se excluyó porque contiene mocks de Correspondencia; no es almacenamiento genérico. Se retiraron de la copia las rutas, registros DI, enums, permisos documentales y exports específicos.

## Dependencias

flutter_bloc, equatable, intl, responsive_framework, get_it, go_router, url_strategy, data_table_2, cupertino_icons y los tres paquetes locales. Dio vive en rrhh_api. CupertinoIcons es necesario para las fuentes de iconos de los widgets compartidos. Se conserva flutter_lints y flutter_test. file_picker no se añadió. Las restricciones de versión provienen del origen; pub get generó el lock del destino.

## Backend y almacenamiento

API_BASE_URL sigue siendo un dart-define con valor predeterminado http://localhost:8000. Las rutas reutilizadas /auth/login, /auth/refresh, /auth/logout y /auth/me permanecen iguales. No se modificaron endpoints ni lógica del servidor; se omitieron constantes de endpoints no utilizados de negocio.

La arquitectura del origen guarda el access token en memoria (AuthTokenStore) y usa cookie HttpOnly para refresh en web. No contiene una base común de secure storage nativo para copiar. No se añadió persistencia de credenciales ni un mecanismo nuevo. configureWebAdapter conserva withCredentials para web y el stub nativo del origen.

## Validación

- flutter pub get: correcto.
- flutter analyze: sin problemas.
- flutter test test packages/rrhh_api/test packages/rrhh_repository/test packages/failures/test: 32 pruebas correctas.
- flutter build web: correcto; artefacto en build/web.

La validación de compilación es web, la plataforma del origen. No se validó compilación Android/iOS/escritorio ni login con servidor real. Para desarrollo web: flutter run -d chrome --web-port 5000; configurar API_BASE_URL y CORS/cookies según el backend existente.

## Pendiente

Implementar módulos de Recursos Humanos en una etapa posterior. Biométrico, marcaciones y reportes no implementados. Revisar sesión y almacenamiento nativo si se define un destino móvil/escritorio. Verificar integración real con el backend y despliegue de rutas SPA cuando corresponda.

## Integridad del origen

No se ejecutaron escrituras de esta tarea sobre el proyecto origen. Durante la comparación de hashes se observaron cambios externos en archivos de backend, configuración de sistema, endpoints del origen y PROJECT_CONTEXT.md. Por ello no se afirma que el origen permaneció globalmente inmutable durante la ejecución; estos cambios no se copiaron como módulos ni se corrigieron o revirtieron.

## Inventario exacto de archivos copiados

- lib/bootstrap.dart
- lib/core/app/app.dart
- lib/core/app/views/app_body.dart
- lib/core/app/views/app_view.dart
- lib/core/app/widgets/app_navigation_listener.dart
- lib/core/auth/permission_guard.dart
- lib/core/auth/permissions.dart
- lib/core/auth/session_header_labels.dart
- lib/core/helpers/dialog_message.dart
- lib/core/helpers/extensions/extension_context.dart
- lib/core/helpers/extensions/extension_device.dart
- lib/core/helpers/full_widget_generics.dart
- lib/core/helpers/listener/listener_generic.dart
- lib/core/helpers/status_state.dart
- lib/core/platform/file_download_platform.dart
- lib/core/platform/file_download_platform_stub.dart
- lib/core/platform/file_download_platform_web.dart
- lib/core/platform/file_download_service.dart
- lib/core/platform/format_file_size.dart
- lib/core/platform/safe_filename.dart
- lib/core/presentation/screens/error_screen.dart
- lib/core/presentation/widget/responsive_breakpoints.dart
- lib/core/presentation/widget/responsive_layout.dart
- lib/core/router.dart
- lib/core/routes.dart
- lib/core/theme/app_decorations.dart
- lib/core/theme/app_theme.dart
- lib/core/theme/ui_colors.dart
- lib/core/util/enums.dart
- lib/core/util/form/controllers/controllers.dart
- lib/core/util/form/models/form_option.dart
- lib/core/util/form/result_validate.dart
- lib/core/util/form/validator_field/valid.dart
- lib/core/util/form/validator_field/validator_field.dart
- lib/features/app/cubit/app_session_cubit.dart
- lib/features/authentication/sign_in/cubit/sign_in_cubit.dart
- lib/features/authentication/sign_in/cubit/sign_in_state.dart
- lib/features/authentication/sign_in/helpers/sign_in_form_inherited.dart
- lib/features/authentication/sign_in/views/sign_in_page.dart
- lib/features/splash/cubit/splash_cubit.dart
- lib/features/splash/cubit/splash_state.dart
- lib/features/splash/splash.dart
- lib/features/splash/views/splash_view.dart
- lib/injection/get_it.dart
- lib/injection/get_it_test_helper.dart
- lib/injection/injection.dart
- lib/main.dart
- lib/shared/widgets/app_form_dialog.dart
- lib/shared/widgets/app_surface.dart
- lib/shared/widgets/auth_split_layout.dart
- lib/shared/widgets/data_grid/app_data_grid.dart
- lib/shared/widgets/data_grid/app_data_grid_action.dart
- lib/shared/widgets/data_grid/app_data_grid_actions_bar.dart
- lib/shared/widgets/data_grid/app_data_grid_cell_type.dart
- lib/shared/widgets/data_grid/app_data_grid_column.dart
- lib/shared/widgets/data_grid/app_data_grid_desktop_table.dart
- lib/shared/widgets/data_grid/app_data_grid_mobile_item.dart
- lib/shared/widgets/data_grid/app_data_grid_pagination.dart
- lib/shared/widgets/data_grid/app_data_grid_value_utils.dart
- lib/shared/widgets/data_grid/app_status_badge.dart
- lib/shared/widgets/empty_state.dart
- lib/shared/widgets/form/app_dropdown.dart
- lib/shared/widgets/form/app_form_field_style.dart
- lib/shared/widgets/form/app_searchable_dropdown.dart
- lib/shared/widgets/form/app_text_field.dart
- lib/shared/widgets/form/app_text_password.dart
- lib/shared/widgets/form/form_save_error.dart
- lib/shared/widgets/metric_tile.dart
- lib/shared/widgets/page_container.dart
- lib/shared/widgets/section_header.dart
- lib/shared/widgets/status_badge.dart
- packages/failures/lib/failures.dart
- packages/failures/lib/src/app_logger.dart
- packages/failures/lib/src/error_code.dart
- packages/failures/lib/src/exceptions.dart
- packages/failures/lib/src/failure_generic.dart
- packages/failures/lib/src/failures.dart
- packages/failures/lib/src/handle_exceptions.dart
- packages/failures/lib/src/result.dart
- packages/failures/pubspec.yaml
- packages/failures/test/failure_generic_test.dart
- packages/rrhh_api/lib/rrhh_api.dart
- packages/rrhh_api/lib/src/core/models/active_toggle_request.dart
- packages/rrhh_api/lib/src/core/models/paginated_response.dart
- packages/rrhh_api/lib/src/core/network/api_client.dart
- packages/rrhh_api/lib/src/core/network/api_config.dart
- packages/rrhh_api/lib/src/core/network/api_interceptor.dart
- packages/rrhh_api/lib/src/core/network/api_logger.dart
- packages/rrhh_api/lib/src/core/network/api_method.dart
- packages/rrhh_api/lib/src/core/network/auth_interceptor.dart
- packages/rrhh_api/lib/src/core/network/auth_refresh_coordinator.dart
- packages/rrhh_api/lib/src/core/network/auth_refresh_interceptor.dart
- packages/rrhh_api/lib/src/core/network/auth_token_store.dart
- packages/rrhh_api/lib/src/core/network/configure_web_adapter_stub.dart
- packages/rrhh_api/lib/src/core/network/configure_web_adapter_web.dart
- packages/rrhh_api/lib/src/core/network/credentials_interceptor.dart
- packages/rrhh_api/lib/src/core/network/endpoints.dart
- packages/rrhh_api/lib/src/core/network/network.dart
- packages/rrhh_api/lib/src/features/authentication/api/auth_api.dart
- packages/rrhh_api/lib/src/features/authentication/api/auth_remote.dart
- packages/rrhh_api/lib/src/features/authentication/authentication.dart
- packages/rrhh_api/lib/src/features/authentication/models/auth_response.dart
- packages/rrhh_api/lib/src/features/authentication/models/me_employee_response.dart
- packages/rrhh_api/lib/src/features/authentication/models/user_response.dart
- packages/rrhh_api/pubspec.yaml
- packages/rrhh_api/test/api_config_test.dart
- packages/rrhh_api/test/api_validation_test.dart
- packages/rrhh_api/test/auth_refresh_coordinator_test.dart
- packages/rrhh_api/test/auth_refresh_interceptor_test.dart
- packages/rrhh_repository/lib/rrhh_repository.dart
- packages/rrhh_repository/lib/src/core/entities/admin_page.dart
- packages/rrhh_repository/lib/src/features/authentication/authentication.dart
- packages/rrhh_repository/lib/src/features/authentication/entities/institutional_context.dart
- packages/rrhh_repository/lib/src/features/authentication/entities/user_session.dart
- packages/rrhh_repository/lib/src/features/authentication/mappers/user_response_mapper.dart
- packages/rrhh_repository/lib/src/features/authentication/repository/auth_repository.dart
- packages/rrhh_repository/pubspec.yaml
- packages/rrhh_repository/test/auth_repository_test.dart
- packages/rrhh_repository/test/user_response_mapper_test.dart
- test/core/auth/permission_guard_test.dart
- test/core/auth/session_header_labels_test.dart
- test/core/platform/file_download_service_test.dart
- test/core/platform/safe_filename_test.dart
