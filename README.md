# Sistema de Préstamo de Equipos — Java (JSP + Servlets) + SQL Server

Aplicación web con **Servlets + JSP + JSTL + JDBC**, para **Apache Tomcat 10.1** (`jakarta.servlet`),
con base de datos **SQL Server** y pensada para abrirse en **IntelliJ IDEA**.

## Requisitos

| Pieza | Versión |
|---|---|
| JDK | 21 (`maven.compiler.release=21`, igual que PlantillaWeb) |
| IntelliJ IDEA | Ultimate (con Tomcat) — no hace falta instalar Maven: se usa `mvnw` |
| Apache Tomcat | **10.1.x** (no sirve Tomcat 9) |
| SQL Server | 2019 o superior, en `localhost:1433`, con autenticación mixta |

## Puesta en marcha en IntelliJ

1. **Abre el proyecto** con *File → Open* y elige el `pom.xml` (*Open as Project*). Espera a que Maven descargue las dependencias.
   Si venías de NetBeans, no copies carpetas `.idea` ni `nbproject` de otra máquina.
2. **Contraseña de SQL Server.** En *Run → Edit Configurations → Tomcat Server → Server → Environment variables* agrega:
   `PRESTAMOS_DB_PASS=tu_contraseña_de_sa`
   (o edita `db.password` en `src/main/resources/app.properties`, pero no lo subas a Git).
3. **Configura Tomcat 10.1**: *+ → Tomcat Server → Local*, pestaña *Deployment* → *+ → Artifact* → `prestamos-equipos:war exploded`.
   En *Application context* pon `/prestamos-equipos`.
4. Pulsa ▶ y abre `http://localhost:8080/prestamos-equipos/`.

**No hace falta ejecutar el script a mano:** al arrancar, la aplicación crea la base `prestamos_equipos`
y carga tablas y datos iniciales si todavía no existen. Si prefieres hacerlo tú:

```powershell
sqlcmd -S localhost,1433 -E -C -i database\prestamos_equipos.sql
```

El script es idempotente (puede correrse varias veces sin borrar nada).

**Usuario inicial:** `admin@universidad.edu` / `admin123` (cámbiala después de entrar).

## Configuración (`src/main/resources/app.properties`)

Cada valor puede sobrescribirse con una variable de entorno:

| Propiedad | Variable | Por defecto |
|---|---|---|
| `db.host` | `PRESTAMOS_DB_HOST` | `localhost` |
| `db.port` | `PRESTAMOS_DB_PORT` | `1433` |
| `db.name` | `PRESTAMOS_DB_NAME` | `prestamos_equipos` |
| `db.user` | `PRESTAMOS_DB_USER` | `sa` |
| `db.password` | `PRESTAMOS_DB_PASS` | *(definir)* |
| `db.trustServerCertificate` | `PRESTAMOS_DB_TRUST_CERT` | `true` |
| `db.poolSize` | `PRESTAMOS_DB_POOL` | `10` |
| `app.timezone` | `PRESTAMOS_TZ` | `America/Lima` |
| `dni.api.token` | `PRESTAMOS_DNI_TOKEN` | *(vacío = solo proveedor de respaldo apis.net.pe)* |
| `ai.api.key` | `PRESTAMOS_AI_API_KEY` | *(vacío = modo integrado sin generación externa)* |
| `ai.model` | `PRESTAMOS_AI_MODEL` | `gpt-5.6-luna` |
| `ai.endpoint` | `PRESTAMOS_AI_ENDPOINT` | `https://api.openai.com/v1/chat/completions` |
| `ai.timeout.seconds` | `PRESTAMOS_AI_TIMEOUT` | `35` |

## Pool de conexiones

`config/Conexion.java` es el pool casero (basado en el de PlantillaWeb): reutiliza conexiones y `close()` las devuelve al pool.
Es perezoso (no abre nada hasta la primera consulta), restablece `autoCommit` al devolver cada conexión
(necesario porque `Db.tx` lo desactiva) y reemplaza las conexiones caídas. `Database.init()` crea la base
usando una conexión directa a `master`, fuera del pool.

## Interfaz e iconos

Los estilos usan **Tailwind CSS v4** (ya no se usa Bootstrap), con la paleta verde UNCP y la fuente Plus Jakarta Sans.

- Fuente de estilos: `src/main/frontend/tailwind.css` (tema, componentes `.btn`, `.card`, `.badge`, `.form-control`, tablas, modal…).
- Salida compilada (versionada): `src/main/webapp/assets/css/tailwind.css`. Así el proyecto corre en Tomcat/IntelliJ sin necesitar Node.
- Si cambias clases en los JSP/JS o el tema, recompila (requiere Node 18+):

  ```powershell
  npm install        # solo la primera vez
  npm run build:css  # o `npm run watch:css` mientras desarrollas
  ```

- Comportamiento (dropdowns, pestañas, alertas, modal): `assets/js/ui.js` reemplaza a `bootstrap.bundle.js`.
- La escala de la interfaz (80 %) se cambia con `--escala-ui` en `tailwind.css`.
Todos los iconos son de [Remix Icon](https://remixicon.com) 4.5.0 (CDN `remixicon.css`): se usan con `<i class="ri-nombre-line"></i>`.
Los iconos dinámicos (estado de equipos, categorías, notificaciones) se definen en `util/Oficinas.java` y `model/Notificacion.java`.

## Docker (opcional)

```powershell
copy .env.example .env     # y cambia DB_SA_PASSWORD
docker compose up --build  # SQL Server + la app en http://localhost:8080/
```

## Generar el WAR

`mvnw.cmd clean package` → `target/prestamos-equipos.war`.

## Cambios de la migración MySQL → SQL Server

| Antes (MySQL/MariaDB) | Ahora (SQL Server) |
|---|---|
| Driver `mariadb-java-client` | `mssql-jdbc` |
| `ENUM(...)` | `VARCHAR` + `CHECK` |
| `AUTO_INCREMENT` | `IDENTITY(1,1)` |
| `TEXT` / `VARCHAR` | `NVARCHAR` / `NVARCHAR(MAX)` (tildes y ñ) |
| `DATETIME DEFAULT CURRENT_TIMESTAMP` | `DATETIME2(0)`; las fechas las envía Java con la zona `app.timezone` |
| `UNIQUE(dni)` con varios NULL | índice único filtrado `WHERE dni IS NOT NULL` |
| Columna generada `equipo_activo` + UNIQUE | índice único filtrado `ON prestamos(equipo_id) WHERE estado='activo'` |
| `SELECT ... FOR UPDATE` | `WITH (UPDLOCK, ROWLOCK)` |
| `LIMIT n` | `TOP (n)` |
| `NOW()`, `DATE_SUB`, `TIMESTAMPDIFF` | parámetro `Fechas.ahora()`, `DATEDIFF` |
| `CONCAT(IFNULL(...))` | `CONCAT(ISNULL(...))` |
| `CREATE DATABASE` por JDBC a MariaDB | `CREATE DATABASE` desde `master` + script por lotes `GO` |

El nombre de la base queda unificado como **`prestamos_equipos`** (antes el `.sql` de `database/` usaba
`sistema-prestamos` y `app.properties` usaba `prestamos_equipos`).

## Equivalencias PHP → Java

| PHP | Java |
|---|---|
| `config.php`, `includes/db.php` | `config/AppConfig`, `config/Database` (+ `app.properties`) |
| `includes/auth.php` (sesión, roles, CSRF) | `filter/AuthFilter`, `filter/CsrfFilter`, `util/Seguridad` |
| `includes/header.php` / `footer.php` | `WEB-INF/tags/layout.tag` |
| `login.php`, `logout.php`, `dashboard.php` | `LoginServlet`, `LogoutServlet`, `DashboardServlet` |
| `recuperar_password.php` | `RecuperarPasswordServlet` (`/recuperar-password`, pública) |
| `perfil.php` | `PerfilServlet` (`/perfil`) |
| `dni_lookup.php` | `UsuarioServlet` (`/usuarios/dni-lookup`, solo admin) + `util/DniLookup` |
| `equipos/*.php` | `EquipoServlet` (`/equipos/listar`, `crear`, `editar`, `eliminar`) |
| `prestamos/*.php` | `PrestamoServlet` (`/prestamos/registrar`, `devolver`, `vencidos`) |
| `reservas/*.php` | `ReservaServlet` (`/reservas/listar`, `crear`, `cambiar-estado`) |
| `usuarios/*.php` | `UsuarioServlet` (`/usuarios/listar`, `crear`, `editar`, `cambiar-estado`) |
| `reportes/index.php` | `ReporteServlet` (`/reportes`) |
| Consultas SQL | `dao/*Dao` (PreparedStatement) y `service/*Service` (transacciones) |
| Vistas | `WEB-INF/views/**/*.jsp` |

La base de datos, el CSS y el JavaScript (`assets/`) son los mismos del proyecto PHP.
Las contraseñas existentes (`$2y$…` de PHP) siguen funcionando.

## Novedades sincronizadas con el PHP (21/10/2026)

- **Login rediseñado** (portada institucional, mostrar/ocultar contraseña) — `login.jsp` (clases Tailwind).
- **Recuperar contraseña** en 3 pasos (correo + DNI → nueva contraseña → confirmación).
- **Perfil** (menú de usuario → *Perfil*): datos de la cuenta y cambio de contraseña.
- **Nuevo usuario**: botón *Buscar* que autocompleta nombre y correo desde el DNI (RENIEC).
  El token se configura en `app.properties` (`dni.api.token`); si falla se usa el proveedor de respaldo `apis.net.pe`.
  Requiere internet en el equipo donde corre Tomcat.
- **Equipos (encargados/admin)**: búsqueda y filtros en tiempo real (texto, categoría, estado), chips de categoría y
  estado, contador de resultados y atajo **Ctrl+K**. Los parámetros `?estado=` y `?categoria_id=` siguen fijando el filtro inicial.
- **Equipos (usuarios)**: nueva pestaña *Catálogo por Categorías* con búsqueda, filtro de estado y botón *Solicitar*;
  la fecha de préstamo se rellena con la hora actual.
- *Dashboard* de usuarios: «Reservar Ahora» ahora lleva a Equipos.

## Diferencias respecto al PHP (a propósito)

- El módulo **Reservas** está retirado del menú y `/reservas/*` redirige al panel (igual que la versión Apache).
- Un usuario **desactivado** pierde el acceso de inmediato, aunque tenga la sesión abierta.
- Las reservas solo admiten las transiciones que ofrece la pantalla
  (pendiente → confirmada/cancelada; confirmada → completada/cancelada).
- La recuperación de contraseña aplica el mismo bloqueo temporal que el login (5 intentos fallidos en 15 minutos).
- Los contadores del catálogo de usuarios (mantenimiento, dados de baja) se calculan; en el PHP estaban escritos a mano.
- Los errores de base de datos se registran en el log del servidor y al usuario se le muestra un mensaje genérico.
- No se portó `includes/ia_supervisor_modal.php`: ninguna página del proyecto PHP lo incluía.

## Estructura

```
database/prestamos_equipos.sql           Script T-SQL (Maven lo copia al classpath como /db/)
src/main/java/edu/universidad/presta/    config/ dao/ filter/ listener/ model/ service/ servlet/ util/
src/main/resources/app.properties
src/main/webapp/                         WEB-INF/{web.xml, views, tags, tld}, assets/
```

## Asistente Inteligente OTI — 7 funciones

Se añadió un asistente flotante en las pantallas autenticadas. El módulo está integrado con Java/JSP/Servlets y consulta SQL Server mediante DAO; no tiene acceso libre a SQL ni puede ejecutar consultas arbitrarias.

1. **Chatbot institucional:** responde preguntas sobre PrestaEquipos y conserva el historial de conversación por usuario.
2. **Búsqueda inteligente:** interpreta términos útiles de una frase y busca por nombre, código, descripción, categoría y ubicación. A los solicitantes solo les muestra equipos disponibles.
3. **Ayuda para solicitudes:** explica el proceso y abre el formulario real de solicitud; al elegir un equipo desde los resultados, precarga el nombre y código. El usuario confirma y envía el formulario normal.
4. **Alertas de préstamos y notificaciones:** permite consultar las fechas de devolución propias y explicar estados de solicitudes. El personal encargado ve el conteo de préstamos vencidos y debe abrir el módulo de gestión para el detalle.
5. **Recomendaciones:** muestra equipos disponibles ordenados por demanda histórica de préstamos.
6. **Voz:** usa las capacidades de voz del navegador para dictar preguntas y leer la última respuesta. Requiere permiso de micrófono y un navegador compatible (Chrome/Edge actual); en producción se recomienda HTTPS.
7. **Mantenimiento preventivo:** el personal encargado puede programar, iniciar y completar mantenimientos, además de consultar alertas basadas en préstamos recientes y mantenimientos registrados.

### Conectar el proveedor de IA

La integración generativa usa el endpoint servidor-a-servidor de Chat Completions. La clave nunca se incluye en JavaScript ni en las páginas JSP. En IntelliJ, abre **Run → Edit Configurations → Tomcat → Environment variables** y agrega:

```text
PRESTAMOS_AI_API_KEY=tu_clave_de_API
PRESTAMOS_AI_MODEL=gpt-5.6-luna
```

En PowerShell, si inicias Tomcat desde esa misma terminal, también puedes establecerlas así:

```powershell
$env:PRESTAMOS_AI_API_KEY="tu_clave_de_API"
$env:PRESTAMOS_AI_MODEL="gpt-5.6-luna"
```

Opcionalmente puedes configurar `PRESTAMOS_AI_ENDPOINT` y `PRESTAMOS_AI_TIMEOUT`. El endpoint predeterminado es `https://api.openai.com/v1/chat/completions` y el modelo predeterminado es `gpt-5.6-luna`.

Si no configuras la clave, el asistente continúa funcionando en **modo integrado**: búsqueda SQL, consulta de préstamos propios, recomendaciones, guía de solicitudes y reglas preventivas. La conversación generativa completa requiere una clave válida y una cuenta API con acceso y facturación habilitados; el uso de la API puede generar cargos.

**Privacidad:** el sistema guarda los mensajes en `ia_conversaciones` e `ia_mensajes`, asociados al usuario autenticado. Cuando la API está configurada, la pregunta y un contexto mínimo del sistema se envían al proveedor externo para generar la respuesta. No se adjuntan contraseñas, hashes, DNI ni correos desde las tablas de usuarios; además, el asistente oculta correos y números etiquetados como DNI/celular o claves que aparezcan en el texto. No escribas información confidencial en el chat. El rol del usuario limita qué datos se consultan y muestran.

### Base de datos y migración

Al iniciar la aplicación, `Database.init()` crea automáticamente las tablas nuevas si no existen. Si administras la base por separado, ejecuta una vez este script en SQL Server Management Studio:

```text
database/ia_7_funciones_migration.sql
```

La migración es idempotente y no elimina ni modifica los registros existentes. Crea:

- `mantenimientos`: intervenciones preventivas y correctivas.
- `ia_conversaciones`: conversaciones del asistente por usuario.
- `ia_mensajes`: mensajes del historial.

### Alcance y límites

- Las recomendaciones se basan en disponibilidad y frecuencia histórica de préstamos; no son predicciones de demanda entrenadas.
- Las alertas de mantenimiento son reglas de priorización (uso reciente e historial registrado), no un diagnóstico técnico ni un modelo de aprendizaje automático. El personal debe validar físicamente los equipos.
- La IA no aprueba solicitudes, no crea préstamos y no registra devoluciones. Esas operaciones siguen el flujo autorizado de PrestaEquipos.
- La voz depende del soporte del navegador. Si no está disponible, el chat escrito sigue funcionando.

Documentación del proveedor: [Chat Completions API](https://developers.openai.com/api/reference/resources/chat/subresources/completions/methods/create) · [Modelos API](https://developers.openai.com/api/docs/models).
# PrestaEquipos
