# rrhh_sipe_sipe

Publicación del frontend y revisión de rutas para QA: [PUBLICACION_FRONTEND_RRHH.md](PUBLICACION_FRONTEND_RRHH.md).

Flujo Flutter de Asistencia Biométrica: ver [ASISTENCIA_BIOMETRICA_FLUTTER.md](ASISTENCIA_BIOMETRICA_FLUTTER.md).

Prueba controlada contra Ubuntu y biométrico real: [PRUEBA_END_TO_END_RRHH.md](PRUEBA_END_TO_END_RRHH.md). Preparación exclusiva de QA; no ejecuta consultas físicas automáticamente.

Integración biométrica del backend compartido: ver [README_BIOMETRIC.md](https://github.com/AndyGuzmanEscalera/correspondencia-sipe-sipe/blob/e08980157bde47f9da2a3b0fa79ee92f3c8e1bfb/backend/README_BIOMETRIC.md).
Motor de evaluación y reporte individual: ver [README_ATTENDANCE_EVALUATION.md](https://github.com/AndyGuzmanEscalera/correspondencia-sipe-sipe/blob/e08980157bde47f9da2a3b0fa79ee92f3c8e1bfb/backend/README_ATTENDANCE_EVALUATION.md).
El directorio local `backend/` es una copia de trabajo excluida del repositorio frontend;
el servidor existente está en `C:/dev/correspondencia_sipe_sipe/backend` y se versiona por separado.
Las notas históricas siguientes describen etapas anteriores del frontend.

Base del Sistema de Recursos Humanos GAM Sipe Sipe, reutilizada desde la arquitectura de Correspondencia.

Flujo: Widget → Cubit → Repository → ApiMethod/Dio. Inyección GetIt; navegación GoRouter; errores Result/Failure.

## Ejecutar

~~~powershell
flutter pub get
flutter run -d chrome --web-port 5000 --dart-define=API_BASE_URL=http://localhost:8000
~~~

## Validar

~~~powershell
flutter analyze
flutter test test packages/rrhh_api/test packages/rrhh_repository/test packages/failures/test
flutter build web
~~~

Autenticación heredada: access token en memoria y refresh mediante cookie HttpOnly en web. Menú disponible: Dashboard, Importar Biométrico, Marcaciones, Funcionarios, Reportes y Configuración. Importar Biométrico permite seleccionar, validar, previsualizar y analizar archivos. Funcionarios reutiliza el CRUD compartido de Correspondencia. Marcaciones, Reportes y Configuración siguen siendo bases visuales; los indicadores del Dashboard siguen siendo temporales.

Ver [MIGRACION_BASE_COMUN.md](MIGRACION_BASE_COMUN.md) para el inventario, exclusiones y pendientes.

## Estructura visual de Recursos Humanos

- core/app/app_identity.dart: nombre e institución.
- core/router.dart y core/routes.dart: acceso y una única pantalla principal protegida por sesión en /home. Login en /login y secciones en /importacion, /asistencia, /funcionarios, /reportes y /configuracion.
- features/home: estructura responsive, menú lateral y menú móvil. SideMenuCubit selecciona el módulo y MainScreenPage cambia el contenido dentro de la pantalla principal, como en Correspondencia, sin abrir rutas por módulo.
- features/dashboard/views: indicadores temporales.
- features/biometric_import/views: base de Importar Biométrico.
- features/attendance/views: base de Marcaciones.
- features/employees/views: base de Funcionarios.
- features/reports/views: base de Reportes.
- features/settings/views: base de Configuración.
- shared/widgets/feature_placeholder.dart: presentación común de pantallas pendientes.

Se conserva la paleta índigo institucional de RRHH. Cubits/BLoC y GetIt continúan gestionando autenticación y sesión; las pantallas estáticas no introducen estados ni servicios de negocio artificiales.

Se permite leer, previsualizar y analizar TXT/DAT. El horario y la interpretación de tipos se configuran desde la importación. No hay guardado definitivo de importaciones, reportes persistidos ni IA. No se cambiaron endpoints ni contratos de autenticación. Los títulos visibles de web, Android, iOS y escritorio se adaptaron, manteniendo el nombre técnico del paquete rrhh_sipe_sipe.

Validación de esta etapa: flutter pub get, flutter analyze sin problemas, 33 pruebas correctas y flutter build web. Las compilaciones nativas no se validaron en esta etapa.

## Importar Biométrico: lectura y previsualización

Flujo: BiometricImportPage/View → BiometricImportCubit → BiometricImportRepository → BiometricParser. BiometricFilePicker adapta el selector local; GetIt registra las dependencias. Se reutilizan GeneralStatus, StatusState, Result/Failure, AppSurface, HomeInfoCard y AppDataGrid.

Se acepta un archivo .dat/.txt; file_picker ^8.1.4 quedó resuelto a 8.3.2 en pubspec.lock. Lee UTF-8 (incluido BOM); un error de codificación se informa sin reemplazar caracteres silenciosamente. El selector entrega bytes también en web, sin dependencia de dart:io.

LineSplitter admite saltos Windows/Unix. Total de líneas cuenta las líneas físicas, incluidas las vacías; registros encontrados = válidos + inválidos. Las vacías se ignoran para la validación y no se crea una línea ficticia después del último salto. Cada fila exige seis campos separados por tabulaciones, identificador no vacío y fecha estricta yyyy-MM-dd HH:mm o yyyy-MM-dd HH:mm:ss. No se aceptan fechas inexistentes ni normalizaciones de día/mes/hora. Se recortan espacios del identificador y de la fecha para validarlos; campos 3–6 y rawLine quedan originales. rawLine excluye el separador de línea y el BOM de codificación. Los duplicados mantienen orden y número físico de línea.

Resumen: líneas, válidos, inválidos, identificadores únicos de registros válidos y fechas mínima/máxima. Previsualización de 20 registros por página, con scroll interno y altura limitada; errores con ListView.separated. El parser cede el control cada 500 líneas para mantener la interfaz receptiva. Se comprobó un archivo de 10.000 filas. No se retienen bytes en el estado después del procesamiento ni se persisten archivos/registros. Cancelar el selector conserva la selección anterior; seleccionar otro archivo reinicia resultado y paginación.

Importar marcaciones queda deshabilitado. Punto de extensión: packages/rrhh_repository/lib/src/features/biometric_import/repository/biometric_import_repository.dart → importBiometricRecords(List<BiometricRecord>). supportsImport es false y el método devuelve un Failure explícito; no hay endpoint inventado ni éxito ficticio. La lectura conserva los campos originales; el análisis posterior interpreta entradas/salidas y calcula atrasos únicamente según la configuración aplicada.

### Archivos creados

- lib/features/biometric_import/cubit/biometric_import_cubit.dart
- lib/features/biometric_import/cubit/biometric_import_state.dart
- lib/features/biometric_import/data/biometric_file_picker.dart
- lib/features/biometric_import/widgets/biometric_preview.dart
- lib/features/biometric_import/widgets/biometric_errors_dialog.dart
- packages/rrhh_repository/lib/src/features/biometric_import/biometric_import.dart
- packages/rrhh_repository/lib/src/features/biometric_import/entities/biometric_record.dart
- packages/rrhh_repository/lib/src/features/biometric_import/entities/biometric_parse_result.dart
- packages/rrhh_repository/lib/src/features/biometric_import/services/biometric_parser.dart
- packages/rrhh_repository/lib/src/features/biometric_import/repository/biometric_import_repository.dart
- packages/rrhh_repository/test/biometric_parser_test.dart
- test/features/biometric_import/biometric_import_cubit_test.dart
- test/features/biometric_import/biometric_import_view_test.dart

### Archivos modificados

- lib/features/biometric_import/views/biometric_import_page.dart
- lib/injection/injection_bloc.dart
- lib/injection/injection_repository.dart
- packages/rrhh_repository/lib/rrhh_repository.dart
- pubspec.yaml y pubspec.lock
- test/auth_navigation_test.dart
- macos/Runner/DebugProfile.entitlements y Release.entitlements: acceso de lectura a archivos seleccionados por el usuario.
- macos/Flutter/GeneratedPluginRegistrant.swift: registro generado por Flutter para file_picker.
- README.md

Validación: flutter pub get correcto, flutter analyze sin problemas, 46 pruebas aprobadas y flutter build web correcto. Las pruebas cubren parser, fechas, duplicados, archivos vacíos, errores de codificación/selección, cancelación, cierre de pantalla, navegación y vista móvil/escritorio. El selector nativo real y las compilaciones nativas no se verificaron en este entorno.

## Funcionarios compartidos y análisis de importaciones — 8 de octubre de 2026

Se adaptó el módulo de Funcionarios de `C:/dev/correspondencia_sipe_sipe` sin escribir en ese proyecto. Se conserva `EmployeeAdmin`, su CI, sus asignaciones a unidad/cargo y los contratos existentes: GET/POST `/admin/employees`, GET/PUT `/admin/employees/{id}`, PATCH `/admin/employees/{id}/active`. No se crea ninguna tabla ni registro paralelo de funcionarios. La lista exige `master_data.employees.read`; crear, editar y activar/desactivar exige `master_data.employees.manage`. Los catálogos de unidades y cargos se consultan paginados en los endpoints compartidos existentes.

El resultado de importar muestra una lista paginada y buscable por funcionario/CI con días analizados, sin novedad, con observaciones y con anomalías. Cada fila abre una nueva pantalla con `Navigator.push(MaterialPageRoute)`, igual que Correspondencia, y el regreso conserva la lista y su búsqueda; las semanas se agrupan de lunes a domingo y se recortan a las fechas mínima/máxima del archivo completo. Los días laborales sin registros dentro de ese período pueden producir marcaciones faltantes. No se evalúan funcionarios ausentes completamente del archivo. La primera pantalla del funcionario muestra un calendario mensual con navegación por mes y resumen de días normales, observados y anómalos. Cada celda mide 88 px de alto, tiene fondo neutro e indicador de estado discreto. Muestra hasta dos horas y +N más en escritorio, o un conteo breve en anchos estrechos; al seleccionarla se abre un modal con el detalle completo con horas exactas, tipo/código original, campos originales, rawLine, incidencias y sugerencias. Verde indica normal, amarillo observación, rojo anomalía y gris sin datos. Solo se proyectan análisis dentro del período importado: las fechas exteriores son grises y no cuentan como anomalías. Los días sin marcas pero con faltantes detectados conservan su anomalía; sin marcas ni incidencias son grises. El calendario no ejecuta reglas ni modifica originales. Se mantienen también la previsualización y los errores del parser.

Flujo: `BiometricImportCubit` → `AttendanceAnalysisRepository` → catálogo compartido de funcionarios + `AttendanceAnalyzer` → `ImportAttendanceAnalysis` → resumen, semanas y detalle diario. La asociación usa CI exacto sin convertir a número ni eliminar ceros; incluye funcionarios inactivos para archivos históricos. Si un CI no existe o coincide con varios funcionarios, queda sin vincular y visible. Si el catálogo falla, se informa el error y se conserva el análisis por identificador. No se presentan datos ficticios de funcionarios.

`BiometricRecord` permanece inmutable. El analizador ordena copias de las listas y guarda referencias a los registros originales en objetos de análisis separados. Una sugerencia contiene el registro principal sugerido, todas las marcas implicadas y estado de revisión `pending`, `accepted` o `ignored`; esta etapa solo genera `pending`. No existen acciones que apliquen sugerencias ni modifiquen/eliminar originales. La importación y su configuración sobreviven a cambios de menú durante la sesión; se descartan al salir de la sesión.

Reglas iniciales:

- Jornada compatible con el horario: sin incidencias es `normal` (verde). Una observación es `observation` (amarillo); faltantes y secuencias incoherentes son `anomaly` (rojo), con prioridad sobre observaciones del mismo día.
- `late` (`LATE`): diferencia positiva respecto de la primera entrada esperada más tolerancia. 08:06 − (08:00 + 5 min) = 1 min; se conserva precisión de segundos. Las entradas anticipadas no generan incidencias.
- `lateReturn` (`LATE_RETURN`): entrada esperada después de una salida programada, posterior al horario más tolerancia. Con entrada de tarde a las 14:00, 14:05 es normal y 14:10 genera 5 min computables.
- `earlyExit` (`EARLY_EXIT`): salida anterior al horario esperado, sin aplicar tolerancia de entrada. 11:50 frente a 12:00 genera 10 min; 17:40 frente a 18:00 genera 20 min. Las salidas posteriores no generan incidencias. Las tres incidencias son observaciones para revisión.
- La distancia absoluta solo se usa para escoger una asociación entre marcas candidatas, nunca para penalizar un evento. La ventana de asociación no excluye entradas anticipadas ni salidas posteriores en el mismo día; se separan horarios del mismo sentido para evitar confundir mañana y tarde.
- `missingMark`: no hay marca compatible con el sentido y la ventana horaria configurada. La asociación sigue orden cronológico y cada original se asocia como máximo a una marca esperada.
- `extraMark`: marcas no asociadas al horario; son observación, nunca anomalía solo por cantidad. No se presupone que un día tenga cuatro marcas.
- `possibleDuplicate`: mismo CI, fecha y valor del campo de tipo elegido dentro de una ventana medida desde la primera marca del grupo. Se sugiere la más temprana sin descartar ninguna.
- `intermediateExit`: salida seguida de entrada que no corresponde al descanso esperado. Se calcula duración y se pide revisión sin inferir la causa.
- `inconsistentSequence`: sentidos iguales consecutivos fuera de la ventana de posibles duplicados.
- Sin horario confirmado no se evalúan atrasos ni faltantes; sin equivalencias de códigos no se interpretan sentidos, salidas ni retornos. Se informa configuración pendiente o tipos desconocidos en vez de declarar una jornada normal.

En **Configurar análisis** se pueden establecer cualquier cantidad de marcas esperadas del mismo día (HH:mm E/S), días de semana, tolerancia de atraso (5 min iniciales), ventana de posibles duplicados (5 min iniciales), ventana de asociación al horario (90 min iniciales), campo de tipo (campos 3–6) y códigos de entrada/salida. El campo 4 es una selección inicial revisable, no una afirmación del formato del dispositivo. El horario está vacío hasta que se confirme; 08:00/12:00/14:00/18:00 es solo un ejemplo visible. Se puede reanalizar y actualizar el catálogo de funcionarios sin releer ni sustituir los originales.

Pendientes de backend/base de datos: conectar `API_BASE_URL` al mismo backend/base compartida de Correspondencia y verificar sus permisos reales; persistir importaciones y originales inmutables; persistir análisis, configuración e historial de revisiones en estructuras separadas cuando se diseñen sus contratos. En esta etapa no se crean migraciones ni endpoints de importación/análisis. No hay persistencia local de las importaciones/configuraciones ni asignación de horarios distintos por funcionario. El motor inicial usa horarios dentro de un mismo día; turnos nocturnos, calendarios institucionales y feriados requieren otra etapa. No incluye hojas de salida, permisos, vacaciones, IA, descuentos ni sanciones.

### Archivos creados en esta etapa

Módulo reutilizado y adaptado:

- `lib/features/administration/basic_data/employees/list_employees/cubit/employees_cubit.dart`
- `lib/features/administration/basic_data/employees/list_employees/cubit/employees_state.dart`
- `lib/features/administration/basic_data/employees/list_employees/views/employees_page.dart`
- `lib/features/administration/basic_data/employees/list_employees/views/employees_view.dart`
- `lib/features/administration/basic_data/employees/list_employees/views/employees_body.dart`
- `lib/features/administration/basic_data/employees/list_employees/tables/employees_table.dart`
- `lib/features/administration/basic_data/employees/upsert_employees/cubit/upsert_employees_cubit.dart`
- `lib/features/administration/basic_data/employees/upsert_employees/cubit/upsert_employees_state.dart`
- `lib/features/administration/basic_data/employees/upsert_employees/helpers/upsert_employees_inherited.dart`
- `lib/features/administration/basic_data/employees/upsert_employees/views/upsert_employees_view.dart`
- `lib/features/administration/basic_data/employee_detail/employee_detail_page.dart`
- `lib/features/administration/common/admin_active_filter.dart`
- `lib/features/administration/common/admin_logical_delete_dialog.dart`
- `lib/features/administration/common/admin_upsert_bloc_listener.dart`

Contratos compartidos:

- `packages/rrhh_api/lib/src/features/organization/api/employees_admin_api.dart`
- `packages/rrhh_api/lib/src/features/organization/api/organizational_units_admin_api.dart`
- `packages/rrhh_api/lib/src/features/organization/api/positions_admin_api.dart`
- `packages/rrhh_api/lib/src/features/organization/models/employee_admin_response.dart`
- `packages/rrhh_api/lib/src/features/organization/models/organizational_unit_admin_response.dart`
- `packages/rrhh_api/lib/src/features/organization/models/position_admin_response.dart`
- `packages/rrhh_repository/lib/src/features/organization/entities/employee_admin.dart`
- `packages/rrhh_repository/lib/src/features/organization/entities/organizational_unit_admin.dart`
- `packages/rrhh_repository/lib/src/features/organization/entities/position_admin.dart`
- `packages/rrhh_repository/lib/src/features/organization/mappers/organization_admin_mapper.dart`
- `packages/rrhh_repository/lib/src/features/organization/repository/employees_admin_repository.dart`
- `packages/rrhh_repository/lib/src/features/organization/repository/organizational_units_admin_repository.dart`
- `packages/rrhh_repository/lib/src/features/organization/repository/positions_admin_repository.dart`

Análisis e interfaz:

- `packages/rrhh_repository/lib/src/features/attendance_analysis/entities/attendance_analysis.dart`
- `packages/rrhh_repository/lib/src/features/attendance_analysis/services/attendance_analyzer.dart`
- `packages/rrhh_repository/lib/src/features/attendance_analysis/services/attendance_configuration_parser.dart`
- `packages/rrhh_repository/lib/src/features/attendance_analysis/repository/attendance_analysis_repository.dart`
- `lib/features/biometric_import/views/employee_attendance_page.dart`
- `lib/features/biometric_import/widgets/attendance_analysis_view.dart`
- `lib/features/biometric_import/widgets/attendance_day_card.dart`
- `lib/features/biometric_import/widgets/attendance_configuration_dialog.dart`
- `lib/features/biometric_import/widgets/attendance_status_badge.dart`

Pruebas nuevas o adaptadas del origen:

- `test/features/administration/basic_data/employees/employees_cubit_test.dart`
- `test/features/administration/basic_data/employees/employees_page_test.dart`
- `test/features/administration/basic_data/employees/upsert_employees_cubit_test.dart`
- `test/features/administration/basic_data/employees/upsert_employees_inherited_test.dart`
- `test/features/administration/basic_data/employees/upsert_employees_view_test.dart`
- `test/test_helpers/app_dropdown_test_helpers.dart`
- `test/features/biometric_import/attendance_analysis_view_test.dart`
- `packages/rrhh_repository/test/attendance_analyzer_test.dart`
- `packages/rrhh_repository/test/shared_employees_contract_test.dart`

### Archivos modificados en esta etapa

- `lib/core/router.dart`: Cubit de importación con alcance de sesión para conservar el archivo al cambiar de menú.
- `lib/core/auth/permission_guard.dart`: contenedor compatible con el scroll de la pantalla principal.
- `lib/features/employees/views/employees_page.dart`: módulo compartido protegido por permiso de lectura.
- `lib/features/biometric_import/cubit/biometric_import_cubit.dart`: delegación al analizador, reanálisis y control de resultados asíncronos.
- `lib/features/biometric_import/cubit/biometric_import_state.dart`: originales y análisis separados.
- `lib/features/biometric_import/views/biometric_import_page.dart`: resumen por funcionario y configuración.
- `lib/injection/injection_bloc.dart` y `lib/injection/injection_repository.dart`: registros del CRUD y del analizador.
- `packages/rrhh_api/lib/rrhh_api.dart` y `packages/rrhh_api/lib/src/core/network/endpoints.dart`: exports y rutas compartidas existentes.
- `packages/rrhh_repository/lib/rrhh_repository.dart`: exports de entidades, repositorios y motor.
- `test/auth_navigation_test.dart`: permisos y conservación del Cubit de importación.
- `test/features/biometric_import/biometric_import_cubit_test.dart`: reanálisis sin mutaciones y sustitución del archivo.
- `test/features/biometric_import/biometric_import_view_test.dart`: delimitación de la tabla de originales ante el nuevo resumen.
- `README.md`: funcionamiento, reglas, configuración, inventario y pendientes.

Validación de esta etapa: `flutter analyze` sin problemas, 96 pruebas aprobadas y `flutter build web --no-pub` correcto (artefactos en `build/web`). Las pruebas incluyen contratos exactos del backend compartido, CRUD y formularios, asociación paginada, CI ambiguo, estados diarios, precisión de atraso, conservación de todos los originales y detalle de ocho marcas en móvil/escritorio. La integración con servidor real y las compilaciones nativas no están verificadas.

Calendario mensual: modelos de presentación en lib/features/biometric_import/models/attendance_calendar_month.dart; cuadrícula en lib/features/biometric_import/widgets/attendance_month_calendar.dart; detalle diario modal en lib/features/biometric_import/widgets/attendance_day_dialog.dart. Pruebas de límites de rango, resumen y febrero bisiesto en test/features/biometric_import/attendance_calendar_month_test.dart.
