# Importación biométrica del GAM Sipe Sipe

**Importación Biométrica conserva la evidencia RAW exactamente como llega y evita únicamente duplicados técnicos exactos. La interpretación de asistencia ocurre posteriormente y nunca modifica la evidencia original.**

## Arquitectura auditada

Flutter consume la **API RRHH independiente** en `C:/dev/rrhh_sipe_sipe_api`. Este backend usa PostgreSQL propio, autentica mediante la sesión delegada existente y consulta Biometric API por HTTPS mediante un worker. El directorio local `backend/` es un overlay histórico ignorado por Git. El backend vigente ya tenía un importador JSON para filas de archivo, un lector TXT/DAT en Flutter, cola de sincronización, cobertura y deduplicación por hash. El borrador Flutter ya incluía previsualización, selector de columnas e historial.

Los dos caminos convergen en la validación y la inserción RAW del backend RRHH.

| Origen | Flujo |
| --- | --- |
| TXT/DAT | Lector Flutter → filas con códigos y texto original → `POST /rrhh/biometric/import` → PostgreSQL |
| Biometric API | `POST /rrhh/biometric/sync` → cola PostgreSQL → worker → descarga paginada por rango → PostgreSQL |

La importación y el worker terminan en persistencia, conteos e historial. La cobertura técnica de descarga se conserva para las sincronizaciones.

## Tablas y migración

| Tabla reutilizada | Uso |
| --- | --- |
| `biometric_records` | Evidencia, hash único, dispositivo, usuario biométrico, hora del reloj, `status_raw`, `punch_raw`, `uid_raw`, origen y fecha de incorporación. |
| `biometric_syncs` | Cola API e historial de ambas fuentes. Guarda el actor, las fechas operativas, el rango, los contadores, el estado y un mensaje resumido de fallo. |
| `biometric_sync_coverage` | Estado de descarga por dispositivo y día, utilizado por el planificador de sincronizaciones API. |
| `biometric_devices`, `biometric_employee_links` | Identidad del dispositivo y vínculo administrativo existente. El vínculo se guarda en una columna ajena a la evidencia del reloj. |

La migración `0002_biometric_import_batches` extiende estas tablas existentes. En `biometric_syncs` agrega `origin`, `source_file_name` y `error_records`, permite rangos vacíos para lotes de archivo y limita el índice parcial `uq_sync_active` a trabajos API. En `biometric_records` agrega `source_file_name`, `import_batch_id` con FK e índice y `raw_payload` en JSONB. La API expone el `synced_at` existente como `imported_at`.

PostgreSQL mantiene `rrhh_raw_evidence_guard` para proteger los campos originales y el borrado. `rrhh_raw_import_metadata_guard` protege los tres campos nuevos. Las filas históricas preservan sus identificadores y valores. El lote y la carga original quedan vacíos cuando el sistema anterior carecía de esa información. Los lotes previos corresponden al origen API.

## Identidad exacta

`record_id` es SHA-256 del JSON compacto UTF-8 `[device_id,user_id,timestamp,status,punch]`, con fecha y hora local del reloj en ISO 8601, separador `T`, segundos y sin zona. PostgreSQL aplica `UNIQUE (record_id)` mediante `biometric_records_record_id_key`. La inserción usa `ON CONFLICT (record_id) DO NOTHING RETURNING id` y ordena las claves para que los lotes concurrentes las adquieran en el mismo orden.

`uid` se conserva fuera de la clave porque puede variar entre exportaciones. El origen, el archivo, el lote y los campos adicionales tampoco forman parte de la identidad. `status` y `punch` conservan sus valores, incluido `null` cuando el dato está ausente. Dos eventos separados por dos segundos, o con distinto `status` o `punch`, son registros distintos. El primer registro conserva su procedencia y carga originales.

## TXT, sincronización y errores

- **TXT/DAT.** El lector existente admite UTF-8, seis campos separados por tabulaciones y fecha y hora con minutos o segundos. El operador confirma qué columnas corresponden a `status`, `punch` y `uid`. La API conserva la línea, su número y los valores tipados. El formato admite hasta 10.000 filas enviadas por lote. Las líneas en blanco se ignoran y las filas inválidas se contabilizan. Con alguna fila válida el lote termina en `completed`, incluso si todas las válidas ya existían. Con filas recibidas y ninguna válida queda en `failed`. Una falla de inserción revierte las marcas del lote y registra el fallo cuando PostgreSQL sigue disponible.
- **Biometric API.** El worker conserva el objeto de cada fila válida y lo inserta mediante la misma función. Si hay filas mal formadas, guarda las válidas, cuenta los errores y el lote queda fallido con cobertura incompleta en el intervalo afectado. Una respuesta con eventos fuera del rango invalida ese intervalo completo como error de protocolo. La cobertura y las marcas de intervalos ya confirmados se conservan.
- **Force resync.** `force: true` vuelve a planificar y consultar los días solicitados aunque figuren con cobertura completa. La inserción omite los hashes existentes y agrega únicamente los nuevos. Mantiene el acceso Gestor delegado, `rrhh.manage` y, además, `rrhh.resync` o rol `ADMIN`/`SUPERADMIN`. La sincronización normal consulta los días pendientes según el planificador vigente.
- **Contadores.** Un lote completado cumple `recibidos = nuevos + duplicados + errores`. Un fallo de protocolo u operación puede dejar filas recibidas sin procesar. `error_records` cuenta errores de filas, y `error_code` y `error_message` describen el fallo operativo. El detalle RAW muestra las filas incorporadas por el lote, por lo que un lote de duplicados tiene un detalle vacío.

## Contrato HTTP

Rutas internas FastAPI. En instalaciones con prefijo público `/api`, el proxy lo retira antes de reenviar al backend.

| Método y ruta | Permiso y comportamiento |
| --- | --- |
| POST `/rrhh/biometric/import` | Gestión. Recibe `device_id`, `records`, `source_file_name` y contadores opcionales del lector. Devuelve el identificador y resumen del lote. |
| POST `/rrhh/biometric/sync` | Gestión. Recibe `start_date`, `end_date` y `force` opcional. Devuelve HTTP 202 y el lote. |
| GET `/rrhh/biometric/syncs` | Lectura. Historial de ambas fuentes con `limit`, `offset` y `origin` opcional. |
| GET `/rrhh/biometric/syncs/{sync_id}` | Lectura. Detalle y progreso del lote. |
| GET `/rrhh/biometric/records` | Lectura. Registros RAW con `from_date`, `to_date`, `user_id`, `device_id`, `source`, `batch_id`, `limit` y `offset`. Ambos días límite son inclusivos. |
| GET `/rrhh/biometric/devices` | Lectura. Dispositivo configurado y otros dispositivos activos registrados. |

`GET /rrhh/biometric/syncs/latest` sigue mostrando la última sincronización API para los consumidores que ya lo usan. La ruta RAW admite solo GET.

## Flutter

La pantalla presenta importación TXT, selección de dispositivo y columnas, previsualización, errores de lectura, sincronización por fechas, estado del último lote e historial paginado. El detalle muestra usuario biométrico, hora del reloj, Status, Punch y origen. Durante la sincronización consulta el lote hasta obtener su resultado. Los usuarios de lectura pueden inspeccionar historial y marcas. Los controles de escritura requieren gestión. El backend aplica sus propios permisos a cada solicitud.

## Validación

- **Backend:** 182 pruebas con PostgreSQL 18 desechable. Las pruebas biométricas cubren nueva inserción, reimportación total y parcial, dos segundos de diferencia, variaciones de Status y Punch, inserciones concurrentes, inmutabilidad y borrado, errores de fila, rollback, persistencia desde el worker, force resync, historial y filtros RAW. El contrato se verificó contra `/openapi.json`. `compileall` pasó. La suite emitió una advertencia de deprecación de Starlette/AnyIO.
- **Migración:** actualización de `0001_rrhh` a `0002_biometric_import_batches` con datos históricos sintéticos, deduplicación contra la marca histórica, reversión y reascenso en una base desechable y `alembic check` sin diferencias.
- **Flutter:** `flutter analyze` sin hallazgos, 87 pruebas de la aplicación y 82 de los paquetes locales. La compilación web de release se generó en `build/web` con `flutter build web --release --no-pub --base-href=/ --dart-define=API_BASE_URL=/api`.
- **Entorno:** las pruebas usaron fixtures y transporte simulado para el reloj. El despliegue y la aceptación con el dispositivo instalado siguen pendientes.

## Archivos

- **Aplicación Flutter:** `lib/features/biometric_import/{cubit,views,widgets}`, `lib/injection/{injection_bloc,injection_repository}.dart` y pruebas en `test/features/biometric_import` y `test/auth_navigation_test.dart`.
- **Paquetes Flutter:** API HTTP y rutas en `packages/rrhh_api/lib`. Parser, mapeo, entidades, repositorio y pruebas en `packages/rrhh_repository`.
- **API RRHH:** `app/biometric/{router,import_schemas,models,storage,worker,coverage}.py`, traslado del esquema exclusivo de archivo desde `app/attendance/schemas.py`, `alembic/versions/0002_biometric_import_batches.py` y `tests/test_biometric_import.py`.

## Despliegue y riesgos

1. Respaldar PostgreSQL de RRHH y verificar que API y worker usan la misma base y el mismo `BIOMETRIC_DEVICE_ID` que el reloj asociado a los archivos.
2. Pausar el worker y esperar que termine el trabajo activo. Desde el repositorio de la API aplicar `python -m alembic upgrade head` y verificar `python -m alembic current` y `python -m alembic check`.
3. Desplegar API y worker con la misma revisión. Reiniciar el worker que ejecuta `python -m app.biometric.worker`. Verificar salud, OpenAPI y lectura de dispositivos e historial con las cuentas autorizadas.
4. Publicar `build/web` con el proxy `/api` apuntando a la API RRHH independiente y el fallback Flutter para `/rrhh/*`. En pruebas de aceptación, importar un archivo sintético dos veces y comprobar los conteos y el detalle. Verificar también los permisos de lectura, gestión y sincronización forzada.

Una asignación distinta de columnas o de dispositivo cambia la identidad del evento. La cobertura histórica depende de lo que el reloj aún pueda entregar. Los registros previos carecen de detalle de lote cuando su procedencia no fue registrada. La migración bloquea su reversión si detecta historial TXT, errores de fila o metadatos RAW nuevos que esa reversión borraría.

Commits sugeridos, uno por repositorio.

- API RRHH `feat(biometric): audit immutable RAW import batches`
- Flutter `feat(biometric): import TXT and inspect RAW batch history`
