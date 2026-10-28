# Asistencia Biométrica Flutter — 27 de octubre de 2026

## Resultado

El menú **Asistencia Biométrica** reemplaza la base visual de Marcaciones y ofrece
sincronización, parámetros/filtros, generación y lista compacta. El detalle dedicado
del funcionario contiene calendario, hoja individual y un único componente de detalle
diario compartido por ambas vistas. Flutter presenta las evaluaciones del backend;
no asocia marcas, calcula atrasos, interpreta códigos ni aplica sugerencias.

## Arquitectura conservada

```text
Widget → Cubit → AttendanceRepository → AttendanceApi → ApiMethod/Dio
```

Se mantienen GetIt, Result/Failure, Equatable/StatusState, sesión y permisos existentes.
`AttendanceApi` usa `mainApi`, con los mismos interceptores de autenticación/refresh.
El repositorio transforma el JSON real en modelos inmutables. Los modelos de días,
incidencias y sugerencias del servidor tienen prefijo `ServerAttendance...` para
preservar íntegros los modelos previos del importador local.

`AttendanceCubit` vive dentro de la sesión, junto al Cubit del importador. Conserva
filtros/resultados al cambiar de menú y cancela el seguimiento al terminar la sesión.
El detalle usa su propio `AttendanceReportCubit`, que se cierra al salir de la página.
La navegación usa `Navigator` y `MaterialPageRoute`, como el detalle existente del
importador, conservando la protección y limpieza de sesión. El nombre de la ruta es
`/rrhh/attendance/employees/{employee_id}/report`; no se añadió una ruta GoRouter ni
se promete restauración de ese detalle mediante una URL directa del navegador.

## Endpoints consumidos

Las rutas internas son `/rrhh/...`. La base pública del despliegue agrega `/api`.

| Método/ruta interna | Uso |
| --- | --- |
| GET `/rrhh/biometric/status` | Estado seguro del dispositivo |
| GET `/rrhh/biometric/syncs/latest` | Última solicitud, incluido trabajo activo |
| GET `/rrhh/biometric/syncs/{id}` | Seguimiento de una sincronización |
| POST `/rrhh/biometric/sync` | Solicitud explícita con fechas inicial/final |
| GET `/rrhh/attendance/contracts` | Catálogo institucional confirmado o pendientes |
| GET `/rrhh/attendance/parameters` | Valores persistidos, en segundos |
| PUT `/rrhh/attendance/parameters` | Guardado explícito de los seis parámetros |
| POST `/rrhh/attendance/generate` | Contrato, año y mes elegidos |
| GET `/rrhh/attendance/employees/{id}/report` | Detalle con los mismos filtros generados |

Se agregaron las dos lecturas que faltaban: catálogo y última sincronización.
Ambas requieren `rrhh.read`. La ruta estática `syncs/latest` se registra antes de la
variable UUID, evitando que `latest` se valide erróneamente como un ID.
No hay tablas ni migraciones nuevas. `EmployeeEvaluationSummary` agrega `status` y
`shifts`, calculados en backend; Flutter no deduce el estado general por contadores.

`AttendanceSource.contracts(db)` entrega únicamente opciones reales confirmadas.
La fuente predeterminada devuelve un catálogo vacío y sus dependencias: no reutiliza
nombres de políticas como contratos sin confirmación ni crea tres valores ficticios.

## Flujo de sincronización

Al abrir el módulo se consultan parámetros, catálogo, última sincronización y estado.
No se inicia ninguna descarga ni generación automáticamente. Consultar estado es una
operación del backend: Flutter nunca abre un socket al reloj.

El botón de sincronización requiere `rrhh.manage`. Solicita un rango mediante el
selector de fechas y explica que el lector descarga el histórico completo antes de
persistirlo. Las fechas de ese selector no se presentan como una política de corte.
El rango se limita al contrato existente del endpoint (367 días inclusivos).

Un trabajo queued/running deshabilita otra solicitud. El Cubit consulta su estado
cada tres segundos; usa progreso indeterminado, sin inventar porcentajes. Al completar,
informa que el reporte debe generarse nuevamente; no lo genera automáticamente.
Un error de seguimiento permite actualizar el estado y no convierte el trabajo
remoto en fallido sin confirmación. Un conflicto al iniciar vuelve a consultar el
último trabajo para detectar la solicitud activa de otro usuario.

## Filtros y parámetros

Contrato real, mes en español y año. El selector de año permite cambiarlo y adapta
su rango alrededor de la selección. Cambiar filtros descarta el resultado anterior;
durante la generación quedan bloqueados y se evita la doble solicitud.

Los seis parámetros persistidos se muestran en **minutos**. La conversión a segundos
se limita al transporte de la configuración: no calcula asistencia. Acepta fracciones
que representen segundos completos, conserva incluso un segundo al guardar sin cambios
y rechaza valores inválidos, negativos, no finitos o mayores que el límite del backend.
No hay guardado al editar. Los cambios sin guardar impiden generar hasta guardarlos
o recargar los valores persistidos. Un usuario con `rrhh.read` puede consultar/generar;
solo `rrhh.manage` habilita edición y sincronización.

## Resultados y ready=false

`ready=false` es un resultado válido y muestra:

> El reporte aún no puede evaluarse completamente.

Se listan las dependencias recibidas, traducidas cuando son conocidas. No se muestra
una tabla ficticia ni se sustituye null por cero. Un fallo HTTP se muestra por separado,
con reintento. Un catálogo que no pudo cargarse no se presenta como catálogo vacío confirmado.

Con `ready=true` se muestra una tabla paginada de 20 funcionarios: badge de estado,
nombre, documento, unidad, cargo, turnos y los contadores/minutos enviados por servidor.
La búsqueda local solo filtra la presentación por nombre, documento o unidad; no
recalcula la evaluación. Un componente con suscripción independiente evita reconstruir
las filas por cada actualización de seguimiento del dispositivo.

## Detalle, calendario y hoja individual

El encabezado incluye nombre, documento, ítem si existe, unidad, cargo, contrato,
turnos y período. Un turno actual sin vigencia histórica se etiqueta expresamente.
El período provisional se presenta como provisional. La navegación conserva el
contrato/año/mes del resultado seleccionado.

El calendario usa las fechas y estados de `calendar` del backend. Muestra primera
y última hora, punto semántico y fondo neutro; no lista todas las marcas en cada celda.
En móvil las dos horas usan líneas compactas. Fechas no recibidas quedan deshabilitadas,
sin asignarles artificialmente NO_DATA. Permite recorrer los meses que abarca el período.
El resumen superior conserva totales nulos y advierte sobre completitud/cobertura.

El mismo detalle de día se abre desde calendario o tabla:

- panel lateral a partir de 1100 px;
- modal desplazable en anchos menores;
- fecha, estado, turno y horas esperadas recibidas;
- eventos principales existentes, sin completar horas faltantes;
- métricas recibidas, distinguiendo salida anticipada computable y diferencia bruta;
- todas las marcas originales, ordenadas cronológicamente, con segundos;
- sección técnica expandible con status, punch, fuente e ID, sin interpretar códigos;
- incidencias legibles y sugerencias separadas, sin aplicar cambios.

La pestaña Reporte presenta una hoja institucional con encabezado y una fila por día,
turno, ambas entradas/salidas, métricas y badge. Una salida final faltante permanece
como —; no se sustituye por la salida de la primera sesión. Las filas no se pintan
con fondos fuertes. No se generó PDF.

## Importador preservado

El menú de importación existente se conserva. La pantalla principal agrega el acceso
**Importar archivo**, que cambia al mismo módulo sin crear otro parser ni duplicar UI.
Sus pruebas existentes siguen pasando. Se conserva su alcance anterior de lectura,
previsualización y análisis local; no se habilitó un guardado ficticio. La conexión de
sus columnas TXT/DAT al endpoint normalizado espera confirmar el mapeo crudo, como
estaba documentado antes de esta etapa.

## Archivos creados

- `packages/rrhh_api/lib/src/features/attendance/api/attendance_api.dart`.
- `packages/rrhh_repository/lib/src/features/attendance/entities/attendance_models.dart`.
- `packages/rrhh_repository/lib/src/features/attendance/repository/attendance_repository.dart`.
- `lib/features/attendance/cubit/{attendance_cubit,attendance_state,attendance_report_cubit}.dart`.
- `lib/features/attendance/models/attendance_presentation.dart`.
- `lib/features/attendance/views/{attendance_view,attendance_report_page}.dart`.
- `lib/features/attendance/widgets/{attendance_common,attendance_parameters_form,attendance_results_section,attendance_results_table,attendance_calendar,attendance_day_detail,attendance_report_table}.dart`.
- `test/features/attendance/{attendance_fixtures,attendance_cubit_test,attendance_widgets_test}.dart`.
- `packages/rrhh_api/test/attendance_api_test.dart`.
- `packages/rrhh_repository/test/attendance_repository_test.dart`.
- `backend/tests_rrhh/test_attendance_catalog.py`.
- Este informe.

## Archivos existentes modificados

- `attendance_page.dart`: reemplazo del placeholder con guard de permisos y vista real.
- `core/router.dart`, `core/auth/permissions.dart`: alcance de sesión y permisos RRHH.
- `injection_bloc.dart`, `injection_repository.dart`: registro de API/repositorio/Cubits.
- `menu_options.dart`: nombre Asistencia Biométrica.
- exports de `rrhh_api`, `rrhh_repository` y archivo central `endpoints.dart`.
- `test/auth_navigation_test.dart`: nueva sección protegida, conservando comportamiento de sesión.
- Backend compartido y extensión local: `router.py`, `evaluation_models.py`,
  `attendance_source.py`, `attendance_service.py`; instalador de la etapa para las nuevas pruebas.
- README y documentación de endpoints.

## Verificación y pendientes reales

- `flutter pub get`: correcto, sin agregar dependencias nuevas al proyecto.
- `flutter analyze`: sin problemas.
- `flutter build web --no-pub`: correcto; artefactos en `build/web`.
- Suite Flutter y paquetes: **149 pruebas aprobadas**, incluidas 32 nuevas.
- Backend RRHH/motor/arranque: **122 pruebas aprobadas**, usando PostgreSQL temporal.
- Layouts comprobados mediante widgets a 390, 900 y 1440 px, incluidos permisos,
  parámetros, ready=false, búsqueda, navegación, NO_DATA, sugerencias y tabla.

Los fixtures sintéticos se usan exclusivamente en pruebas, nunca como fuente de producción.
No se consultó el reloj físico ni se aplicaron migraciones a la base compartida.
La evaluación institucional real continúa pendiente de catálogo/asignaciones contractuales,
períodos y horarios históricos confirmados, ventanas y cobertura. La tolerancia de salida
mantiene la política pendiente indicada por el usuario. El frontend expone esos pendientes.
La imagen física de referencia no estaba disponible en este contexto; la hoja se diseñó
según los campos solicitados y el estilo existente, sin afirmar coincidencia exacta.
