# Integración con API RRHH independiente — 16/11/2026

Frontend: `C:\Andy\proyectos\rrhh_sipe_sipe`. API: `C:\dev\rrhh_sipe_sipe_api`.
Informe completo y contratos: `docs/INTEGRACION_REAL_Y_FLUTTER.md` y
`docs/CONTRATOS_CORRESPONDENCIA.md` del repositorio API. Esta fase no publica ni despliega.

## Una fachada y una identidad

En la primera versión, todos los usuarios activos de tipo/rol GESTOR de Correspondencia tienen acceso base a RRHH.
El contrato real transporta códigos en `roles`; el seed oficial identifica
`MANAGER` como Gestor. La API verifica ese código exacto y el estado activo mediante
`/auth/me`, sin requerir rrhh.read para entrada o lectura. ADMIN por sí solo no
sustituye Gestor. Gestión exige además rrhh.manage; force requiere también
ADMIN/SUPERADMIN o rrhh.resync. No se añadieron cuentas, roles ni grants al maestro.

La API proyecta permisos funcionales de lectura en su perfil público para los
guards existentes; conserva los grants administrativos remotos sin ampliarlos.
Flutter consume esas capacidades y no calcula permisos por rol, cargo o CI.
No fue necesario cambiar lógica de producción Flutter por esta política; se
añadieron pruebas de lectura permitida y administración oculta. El upstream conserva
su RBAC para maestros: si una instalación quita sus lecturas del rol MANAGER, la
consulta puede devolver 403 y requiere provisión institucional, no un bypass local.

Flutter usa exclusivamente `API_BASE_URL` para negocio y renovación de sesión.
Valor local predeterminado: `http://localhost:8200`; configurable mediante `--dart-define`.
La API RRHH reenvía login/refresh/logout a Correspondencia, conserva el mismo JWT y
traslada su refresh opaco en cookie HttpOnly. No crea cuentas, contraseñas, JWT ni
sesiones en PostgreSQL RRHH. Cada solicitud protegida valida `/auth/me` remoto,
sin caché de identidad. La API biométrica y su token quedan exclusivamente en backend.

En HTTPS se mantiene `SESSION_COOKIE_SECURE=true`. Para desarrollo HTTP local puede
configurarse `SESSION_COOKIE_SECURE=false` solo en entorno development, SameSite=lax.
Si el proxy publica API bajo `/api`, configurar `SESSION_COOKIE_PATH=/api/auth`;
el valor interno predeterminado `/auth` solo corresponde a una API sin prefijo público.
Cookie de RRHH: `rrhh_refresh_token`, sin Domain, distinta de la cookie del sitio
Correspondencia, pero contiene el mismo refresh de la sesión delegada. En CORS usar
origen explícito autorizado y credenciales; preferir mismo origen en el futuro.

| Flutter | API anterior | API independiente | Compatibilidad / cambio |
|---|---|---|---|
| Login, refresh, logout | `/auth/*` en Correspondencia | mismas rutas en RRHH, relay | mismo Bearer y rotación remota; interceptor y coordinador existentes |
| Perfil | `/auth/me` | fachada delegada | conserva employee/unidad/cargo, roles; permisos públicos limitados a funciones implementadas |
| Funcionarios / áreas / cargos | `/admin/*` | GET de las mismas rutas | lectura remota; no se duplica el maestro |
| CRUD de maestros / usuarios / jerarquías | POST/PUT/PATCH administrativos | no expuestos | no se anuncian permisos de gestión en `/auth/me`; administración continúa en Correspondencia |
| Estado / usuarios biométricos | `/rrhh/biometric/status`, `/users` | mismas rutas | modelos aceptan api_available y device_connected |
| Sync / seguimiento | `/rrhh/biometric/sync`, `/syncs*` | mismas rutas | POST independiente; queued/running/completed/failed; descarga en worker |
| Parámetros | PUT `/rrhh/attendance/parameters` | misma ruta | ahora exige valid_from, admite valid_to; segundos conservados |
| Contratos / generación | `/rrhh/attendance/contracts`, `/generate` | mismas rutas | ready=false y dependencias pendientes preservados |
| Calendario / detalle / reporte | reporte individual y records | mismas rutas | marcas locales; no dispara sync; revisiones históricas; rango diario opcional solo backend |

El formulario solicita vigencia explícita; no inventa fechas institucionales.
Las revisiones no se sobrescriben: una superposición devuelve un mensaje útil.
Cerrar revisiones abiertas se realiza mediante el endpoint backend `/close`; esta
fase no añade una pantalla nueva de mantenimiento histórico ni gestión de turnos.

Los errores distinguen RRHH inaccesible, Correspondencia no disponible, API
biométrica no disponible, dispositivo desconectado y trabajo fallido/pendiente.
Coverage incompleta se presenta como configuración pendiente; no implica ausencia.
Los errores estructurados usan mensajes seguros y los logs ocultan tokens/cookies.

## Flutter Web en el dominio independiente

El frontend usa /login para entrar y /home para el inicio. Las secciones protegidas tienen sus propias rutas y el hosting sirve index.html al abrirlas directamente. Los favoritos antiguos se redirigen a las rutas actuales.

    flutter build web --release --base-href=/ --dart-define=API_BASE_URL=https://api-rrhh.sipesipe.gob.bo

Comprobar acceso directo, recarga, restauración de sesión y navegación con el botón Atrás del navegador.

## Validación

`flutter pub get`, `flutter analyze`, pruebas raíz y de los tres paquetes locales,
y build web release. Resultados y advertencias definitivos en el informe API.
Se preservaron los cambios que ya existían en los dos documentos de asistencia y
en attendance_view.dart. No se hizo commit/push, ni se configuró remote ni QA.
