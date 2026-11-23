package edu.universidad.presta.dao;

import edu.universidad.presta.util.Fechas;
import edu.universidad.presta.model.Equipo;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public final class EquipoDao {

    private static final String SELECT_CON_CATEGORIA =
            "SELECT e.*, c.nombre AS categoria_nombre FROM equipos e LEFT JOIN categorias c ON e.categoria_id = c.id";

    private EquipoDao() {
    }

    private static Equipo map(ResultSet rs) throws SQLException {
        Equipo e = new Equipo();
        e.setId(rs.getInt("id"));
        e.setCodigoInventario(rs.getString("codigo_inventario"));
        e.setNombre(rs.getString("nombre"));
        e.setDescripcion(rs.getString("descripcion"));
        e.setCategoriaId(Db.integer(rs, "categoria_id"));
        e.setEstado(rs.getString("estado"));
        e.setUbicacion(rs.getString("ubicacion"));
        e.setFechaRegistro(Db.dt(rs, "fecha_registro"));
        if (Db.has(rs, "categoria_nombre")) {
            e.setCategoriaNombre(rs.getString("categoria_nombre"));
        }
        return e;
    }

    public static Equipo porId(int id) {
        return Db.one("SELECT * FROM equipos WHERE id = ?", EquipoDao::map, id);
    }

    public static Equipo porCodigoOParte(String texto) {
        if (texto == null || texto.trim().isEmpty()) return null;
        String t = texto.trim();
        // 1. Coincidencia exacta por código
        Equipo eq = Db.one("SELECT TOP 1 * FROM equipos WHERE LOWER(codigo_inventario) = LOWER(?)", EquipoDao::map, t);
        if (eq != null) return eq;
        // 2. Coincidencia si el texto contiene el código entre paréntesis (ej: "Laptop HP (LPT-001)")
        int ini = t.lastIndexOf('(');
        int fin = t.lastIndexOf(')');
        if (ini >= 0 && fin > ini) {
            String codigo = t.substring(ini + 1, fin).trim();
            eq = Db.one("SELECT TOP 1 * FROM equipos WHERE LOWER(codigo_inventario) = LOWER(?)", EquipoDao::map, codigo);
            if (eq != null) return eq;
        }
        // 3. Coincidencia por nombre exacto
        eq = Db.one("SELECT TOP 1 * FROM equipos WHERE LOWER(nombre) = LOWER(?)", EquipoDao::map, t);
        if (eq != null) return eq;
        // 4. Coincidencia parcial
        return Db.one("SELECT TOP 1 * FROM equipos WHERE LOWER(codigo_inventario) LIKE LOWER(?) OR LOWER(nombre) LIKE LOWER(?)",
                EquipoDao::map, "%" + t + "%", "%" + t + "%");
    }

    /** Lee y bloquea la fila dentro de una transacción. */
    public static Equipo porIdBloqueado(Connection c, int id) {
        return Db.one(c, "SELECT * FROM equipos WITH (UPDLOCK, ROWLOCK) WHERE id = ?", EquipoDao::map, id);
    }

    /** Catálogo con filtros opcionales (valores vacíos = sin filtro). */
    public static List<Equipo> filtrar(String busqueda, Integer categoriaId, String oficina, String estado) {
        StringBuilder sql = new StringBuilder(SELECT_CON_CATEGORIA).append(" WHERE 1=1");
        List<Object> p = new ArrayList<>();
        if (!busqueda.isEmpty()) {
            sql.append(" AND (e.nombre LIKE ? OR e.codigo_inventario LIKE ?)");
            p.add("%" + busqueda + "%");
            p.add("%" + busqueda + "%");
        }
        if (categoriaId != null) {
            sql.append(" AND e.categoria_id = ?");
            p.add(categoriaId);
        }
        if (!oficina.isEmpty()) {
            sql.append(" AND e.ubicacion = ?");
            p.add(oficina);
        }
        if (!estado.isEmpty()) {
            sql.append(" AND e.estado = ?");
            p.add(estado);
        }
        sql.append(" ORDER BY e.codigo_inventario DESC");
        return Db.list(sql.toString(), EquipoDao::map, p.toArray());
    }

    /** Equipos disponibles (catálogo de usuarios y listas desplegables), ordenados por nombre. */
    public static List<Equipo> disponibles() {
        return Db.list(SELECT_CON_CATEGORIA + " WHERE e.estado = 'disponible' ORDER BY e.nombre", EquipoDao::map);
    }

    /** Búsqueda inteligente por términos útiles en nombre, código, descripción, categoría y ubicación. */
    public static List<Equipo> buscarInteligente(String consulta, boolean soloDisponibles, int limite) {
        String q = consulta == null ? "" : consulta.trim().toLowerCase(java.util.Locale.ROOT);
        String[] stop = {"necesito", "quiero", "quisiera", "busco", "buscar", "muestrame", "muéstrame", "dame", "por", "favor", "para", "mañana", "hoy", "un", "una", "el", "la", "los", "las", "de", "del", "equipo", "equipos", "disponible", "disponibles", "que", "qué", "hay", "tienes", "tiene"};
        List<String> terminos = new ArrayList<>();
        for (String token : q.split("\\s+")) {
            String t = token.replaceAll("[^\\p{L}\\p{N}-]", "").trim();
            if (t.equals("laptops")) t = "laptop";
            else if (t.equals("proyectores")) t = "proyector";
            else if (t.equals("computadoras")) t = "computadora";
            else if (t.equals("impresoras")) t = "impresora";
            else if (t.equals("tablets")) t = "tablet";
            else if (t.equals("cámaras")) t = "cámara";
            if (t.length() < 2) continue;
            boolean ignorar = false;
            for (String palabra : stop) if (palabra.equals(t)) { ignorar = true; break; }
            if (!ignorar && !terminos.contains(t) && terminos.size() < 5) terminos.add(t);
        }
        StringBuilder sql = new StringBuilder("SELECT TOP (?) e.*, c.nombre AS categoria_nombre FROM equipos e ")
                .append("LEFT JOIN categorias c ON e.categoria_id=c.id WHERE 1=1");
        List<Object> p = new ArrayList<>();
        p.add(Math.max(1, Math.min(20, limite)));
        if (soloDisponibles) sql.append(" AND e.estado='disponible'");
        if (!terminos.isEmpty()) {
            sql.append(" AND (");
            for (int i = 0; i < terminos.size(); i++) {
                if (i > 0) sql.append(" OR ");
                sql.append("(e.nombre LIKE ? OR e.codigo_inventario LIKE ? OR e.descripcion LIKE ? OR c.nombre LIKE ? OR e.ubicacion LIKE ?)");
                String like = "%" + terminos.get(i).replace("[", "[[]").replace("%", "[%]").replace("_", "[_]") + "%";
                for (int j = 0; j < 5; j++) p.add(like);
            }
            sql.append(")");
        }
        sql.append(" ORDER BY CASE WHEN e.estado='disponible' THEN 0 ELSE 1 END, e.nombre");
        return Db.list(sql.toString(), EquipoDao::map, p.toArray());
    }

    /** Equipos disponibles mejor valorados por demanda histórica de préstamos. */
    public static List<Equipo> recomendados(int limite) {
        return Db.list("SELECT TOP (?) e.*, c.nombre AS categoria_nombre, COUNT(p.id) AS popularidad "
                + "FROM equipos e LEFT JOIN categorias c ON c.id=e.categoria_id "
                + "LEFT JOIN prestamos p ON p.equipo_id=e.id "
                + "WHERE e.estado='disponible' GROUP BY e.id,e.codigo_inventario,e.nombre,e.descripcion,e.categoria_id,e.estado,e.ubicacion,e.fecha_registro,c.nombre "
                + "ORDER BY COUNT(p.id) DESC,e.nombre", EquipoDao::map, Math.max(1, Math.min(12, limite)));
    }

    /** Todos los equipos con su categoría ("General" si no tiene), para el catálogo de usuarios. */
    public static List<Equipo> catalogo() {
        return Db.list("SELECT e.*, COALESCE(c.nombre, 'General') AS categoria_nombre FROM equipos e "
                + "LEFT JOIN categorias c ON e.categoria_id = c.id ORDER BY c.nombre, e.nombre", EquipoDao::map);
    }

    /** Cantidad de equipos por estado (incluye los estados con 0). */
    public static Map<String, Integer> conteoPorEstado() {
        Map<String, Integer> m = new LinkedHashMap<>();
        m.put("disponible", 0);
        m.put("prestado", 0);
        m.put("mantenimiento", 0);
        m.put("dado_de_baja", 0);
        Db.list("SELECT estado, COUNT(*) AS total FROM equipos GROUP BY estado", rs -> {
            m.put(rs.getString("estado"), rs.getInt("total"));
            return null;
        });
        return m;
    }

    public static boolean existeCodigo(String codigo, int excluirId) {
        return Db.scalar("SELECT COUNT(*) FROM equipos WHERE codigo_inventario = ? AND id <> ?", codigo, excluirId) > 0;
    }

    public static int crear(String codigo, String nombre, String descripcion, int categoriaId, String ubicacion, String estado) {
        return (int) Db.insert("INSERT INTO equipos (codigo_inventario, nombre, descripcion, categoria_id, ubicacion, estado, fecha_registro) VALUES (?, ?, ?, ?, ?, ?, ?)",
                codigo, nombre, descripcion, categoriaId, ubicacion, estado, Fechas.ahora());
    }

    public static void actualizar(int id, String codigo, String nombre, String descripcion, int categoriaId, String ubicacion, String estado) {
        Db.update("UPDATE equipos SET codigo_inventario = ?, nombre = ?, descripcion = ?, categoria_id = ?, ubicacion = ?, estado = ? WHERE id = ?",
                codigo, nombre, descripcion, categoriaId, ubicacion, estado, id);
    }

    public static void setEstado(Connection c, int id, String estado) {
        Db.update(c, "UPDATE equipos SET estado = ? WHERE id = ?", estado, id);
    }

    public static void eliminar(Connection c, int id) {
        Db.update(c, "DELETE FROM equipos WHERE id = ?", id);
    }
}
