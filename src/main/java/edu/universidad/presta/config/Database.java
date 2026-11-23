package edu.universidad.presta.config;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Pattern;

/**
 * Conexión JDBC a SQL Server.
 * Si la base no existe la crea; si no tiene tablas, ejecuta /db/prestamos_equipos.sql
 * (el mismo script de la carpeta database/, que Maven copia al classpath).
 */
public final class Database {

    private static final Logger LOG = Logger.getLogger(Database.class.getName());
    private static final String SQL_INICIAL = "/db/prestamos_equipos.sql";
    /** El script trae CREATE DATABASE / USE para sqlcmd; aquí la base ya se creó y estamos conectados a ella. */
    private static final Pattern IGNORAR = Pattern.compile("^(IF\\s+DB_ID|CREATE\\s+DATABASE|USE)\\b.*",
            Pattern.CASE_INSENSITIVE | Pattern.DOTALL);
    private static final Pattern LINEA_GO = Pattern.compile("(?im)^\\s*GO\\s*$");

    /**
     * Tablas creadas después de la primera versión del esquema. Se comprueban en cada arranque
     * para que una base ya existente reciba las novedades sin tener que reinstalarla.
     */
    private static final String[] TABLAS_NUEVAS = {
        "IF OBJECT_ID(N'dbo.notificaciones_leidas', N'U') IS NULL "
            + "CREATE TABLE dbo.notificaciones_leidas ("
            + " usuario_id INT NOT NULL,"
            + " clave NVARCHAR(120) NOT NULL,"
            + " fecha_leida DATETIME2(0) NOT NULL CONSTRAINT df_notificaciones_leidas_fecha DEFAULT SYSDATETIME(),"
            + " CONSTRAINT pk_notificaciones_leidas PRIMARY KEY (usuario_id, clave),"
            + " CONSTRAINT fk_notificaciones_leidas_usuario FOREIGN KEY (usuario_id) REFERENCES dbo.usuarios(id) ON DELETE CASCADE)",
        "IF OBJECT_ID(N'dbo.mantenimientos', N'U') IS NULL CREATE TABLE dbo.mantenimientos ("
            + " id INT IDENTITY(1,1) NOT NULL CONSTRAINT pk_mantenimientos PRIMARY KEY,"
            + " equipo_id INT NOT NULL, usuario_id INT NULL, tipo VARCHAR(20) NOT NULL CONSTRAINT df_mantenimientos_tipo DEFAULT 'preventivo',"
            + " descripcion NVARCHAR(MAX) NOT NULL, fecha_programada DATETIME2(0) NULL, fecha_inicio DATETIME2(0) NULL,"
            + " fecha_fin DATETIME2(0) NULL, estado VARCHAR(20) NOT NULL CONSTRAINT df_mantenimientos_estado DEFAULT 'programado',"
            + " observaciones NVARCHAR(MAX) NULL, fecha_registro DATETIME2(0) NOT NULL CONSTRAINT df_mantenimientos_fecha DEFAULT SYSDATETIME(),"
            + " CONSTRAINT ck_mantenimientos_tipo CHECK (tipo IN ('preventivo','correctivo')) ,"
            + " CONSTRAINT ck_mantenimientos_estado CHECK (estado IN ('programado','en_proceso','completado','cancelado')) ,"
            + " CONSTRAINT fk_mantenimientos_equipo FOREIGN KEY (equipo_id) REFERENCES dbo.equipos(id),"
            + " CONSTRAINT fk_mantenimientos_usuario FOREIGN KEY (usuario_id) REFERENCES dbo.usuarios(id) ON DELETE SET NULL)",
        "IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='ix_mantenimientos_equipo_fecha') CREATE INDEX ix_mantenimientos_equipo_fecha ON dbo.mantenimientos(equipo_id, fecha_registro DESC)",
        "IF OBJECT_ID(N'dbo.ia_conversaciones', N'U') IS NULL CREATE TABLE dbo.ia_conversaciones ("
            + " id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT pk_ia_conversaciones PRIMARY KEY,"
            + " usuario_id INT NOT NULL, titulo NVARCHAR(150) NOT NULL CONSTRAINT df_ia_conversaciones_titulo DEFAULT N'Consulta al asistente',"
            + " fecha_creacion DATETIME2(0) NOT NULL CONSTRAINT df_ia_conversaciones_creacion DEFAULT SYSDATETIME(),"
            + " fecha_actualizacion DATETIME2(0) NOT NULL CONSTRAINT df_ia_conversaciones_actualizacion DEFAULT SYSDATETIME(),"
            + " CONSTRAINT fk_ia_conversaciones_usuario FOREIGN KEY (usuario_id) REFERENCES dbo.usuarios(id) ON DELETE CASCADE)",
        "IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='ix_ia_conversaciones_usuario') CREATE INDEX ix_ia_conversaciones_usuario ON dbo.ia_conversaciones(usuario_id, fecha_actualizacion DESC)",
        "IF OBJECT_ID(N'dbo.ia_mensajes', N'U') IS NULL CREATE TABLE dbo.ia_mensajes ("
            + " id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT pk_ia_mensajes PRIMARY KEY,"
            + " conversacion_id BIGINT NOT NULL, rol VARCHAR(20) NOT NULL, contenido NVARCHAR(MAX) NOT NULL,"
            + " fecha DATETIME2(0) NOT NULL CONSTRAINT df_ia_mensajes_fecha DEFAULT SYSDATETIME(),"
            + " CONSTRAINT ck_ia_mensajes_rol CHECK (rol IN ('user','assistant')) ,"
            + " CONSTRAINT fk_ia_mensajes_conversacion FOREIGN KEY (conversacion_id) REFERENCES dbo.ia_conversaciones(id) ON DELETE CASCADE)",
        "IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='ix_ia_mensajes_conversacion') CREATE INDEX ix_ia_mensajes_conversacion ON dbo.ia_mensajes(conversacion_id, id DESC)",
        "IF COL_LENGTH('dbo.solicitudes', 'motivo_rechazo') IS NULL ALTER TABLE dbo.solicitudes ADD motivo_rechazo NVARCHAR(MAX) NULL",
        "IF COL_LENGTH('dbo.usuarios', 'oficina') IS NULL ALTER TABLE dbo.usuarios ADD oficina NVARCHAR(150) NULL",
        "IF OBJECT_ID(N'dbo.oficinas', N'U') IS NULL CREATE TABLE dbo.oficinas ("
            + " id INT IDENTITY(1,1) NOT NULL CONSTRAINT pk_oficinas PRIMARY KEY,"
            + " nombre NVARCHAR(150) NOT NULL CONSTRAINT uq_oficinas_nombre UNIQUE,"
            + " grupo NVARCHAR(100) NULL, descripcion NVARCHAR(255) NULL,"
            + " activo BIT NOT NULL CONSTRAINT df_oficinas_activo DEFAULT 1,"
            + " fecha_registro DATETIME2(0) NOT NULL CONSTRAINT df_oficinas_fecha DEFAULT SYSDATETIME())"
    };

    private Database() {
    }

    /** Conexión a la base de la aplicación, tomada del pool. Quien la pide debe cerrarla (try-with-resources). */
    public static Connection getConnection() throws SQLException {
        return Conexion.getConnection();
    }

    /** Crea la base y el esquema la primera vez. No lanza excepción: si falla solo lo registra en el log. */
    public static void init() {
        try {
            try (Connection admin = Conexion.abrirDirecta("master"); Statement st = admin.createStatement()) {
                String nombre = AppConfig.dbName().replace("]", "]]");
                st.execute("IF DB_ID(N'" + AppConfig.dbName().replace("'", "''") + "') IS NULL CREATE DATABASE [" + nombre + "]");
            }
            try (Connection c = getConnection(); Statement st = c.createStatement();
                 ResultSet rs = st.executeQuery("SELECT CASE WHEN OBJECT_ID(N'dbo.usuarios', N'U') IS NULL THEN 0 ELSE 1 END")) {
                rs.next();
                if (rs.getInt(1) == 0) {
                    importarEsquema(c);
                }
            }
            asegurarTablasNuevas();
            LOG.info("Base de datos lista: " + AppConfig.dbName());
        } catch (SQLException | IOException e) {
            LOG.log(Level.SEVERE, "No se pudo preparar la base de datos. Verifique que SQL Server esté iniciado "
                    + "(puerto " + AppConfig.dbPort() + "), el usuario y la contraseña de app.properties.", e);
        }
    }

    /** Crea las tablas que se añadieron después de la primera versión del esquema. */
    private static void asegurarTablasNuevas() throws SQLException {
        try (Connection c = getConnection(); Statement st = c.createStatement()) {
            for (String ddl : TABLAS_NUEVAS) {
                st.execute(ddl);
            }
        }
    }

    private static void importarEsquema(Connection c) throws SQLException, IOException {
        String sql;
        try (InputStream in = Database.class.getResourceAsStream(SQL_INICIAL)) {
            if (in == null) {
                LOG.warning("No se encontró " + SQL_INICIAL + " dentro de la aplicación.");
                return;
            }
            ByteArrayOutputStream buf = new ByteArrayOutputStream();
            byte[] tmp = new byte[8192];
            int n;
            while ((n = in.read(tmp)) > 0) {
                buf.write(tmp, 0, n);
            }
            sql = new String(buf.toByteArray(), StandardCharsets.UTF_8);
        }
        try (Statement st = c.createStatement()) {
            for (String lote : dividirLotes(sql)) {
                if (!IGNORAR.matcher(lote).matches()) {
                    st.execute(lote);
                }
            }
        }
        LOG.info("Esquema y datos iniciales importados desde " + SQL_INICIAL);
    }

    /** Divide un script de SQL Server en lotes usando las líneas "GO" (igual que sqlcmd / SSMS). */
    static List<String> dividirLotes(String sql) {
        List<String> out = new ArrayList<>();
        // Quita el BOM si el archivo se guardó con él
        String texto = sql.startsWith("\uFEFF") ? sql.substring(1) : sql;
        for (String parte : LINEA_GO.split(texto)) {
            String lote = quitarComentariosIniciales(parte).trim();
            if (!lote.isEmpty()) {
                out.add(lote);
            }
        }
        return out;
    }

    /** Quita las líneas de comentario "--" y las vacías del comienzo, para poder reconocer la primera sentencia. */
    private static String quitarComentariosIniciales(String lote) {
        String[] lineas = lote.split("\\R", -1);
        int i = 0;
        while (i < lineas.length && (lineas[i].trim().isEmpty() || lineas[i].trim().startsWith("--"))) {
            i++;
        }
        StringBuilder sb = new StringBuilder();
        for (; i < lineas.length; i++) {
            sb.append(lineas[i]).append('\n');
        }
        return sb.toString();
    }
}
