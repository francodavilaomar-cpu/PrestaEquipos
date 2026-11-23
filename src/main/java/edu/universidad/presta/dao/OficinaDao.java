package edu.universidad.presta.dao;

import edu.universidad.presta.model.Oficina;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

public final class OficinaDao {

    private OficinaDao() {
    }

    private static Oficina map(ResultSet rs) throws SQLException {
        Oficina o = new Oficina();
        o.setId(rs.getInt("id"));
        o.setNombre(rs.getString("nombre"));
        o.setGrupo(rs.getString("grupo"));
        o.setDescripcion(rs.getString("descripcion"));
        o.setActivo(rs.getBoolean("activo"));
        o.setFechaRegistro(Db.dt(rs, "fecha_registro"));
        return o;
    }

    public static List<Oficina> listarTodas() {
        return Db.list("SELECT * FROM oficinas ORDER BY grupo ASC, nombre ASC", OficinaDao::map);
    }

    public static List<Oficina> listarActivas() {
        return Db.list("SELECT * FROM oficinas WHERE activo = 1 ORDER BY grupo ASC, nombre ASC", OficinaDao::map);
    }

    public static Oficina porId(int id) {
        return Db.one("SELECT * FROM oficinas WHERE id = ?", OficinaDao::map, id);
    }

    public static Oficina porNombre(String nombre) {
        return Db.one("SELECT * FROM oficinas WHERE LOWER(nombre) = LOWER(?)", OficinaDao::map, nombre);
    }

    public static void crear(String nombre, String grupo, String descripcion) {
        Db.update("INSERT INTO oficinas (nombre, grupo, descripcion, activo) VALUES (?, ?, ?, 1)",
                nombre, (grupo == null || grupo.trim().isEmpty()) ? "General" : grupo.trim(), descripcion);
    }

    public static void actualizar(int id, String nombre, String grupo, String descripcion, boolean activo) {
        Db.update("UPDATE oficinas SET nombre = ?, grupo = ?, descripcion = ?, activo = ? WHERE id = ?",
                nombre, (grupo == null || grupo.trim().isEmpty()) ? "General" : grupo.trim(), descripcion, activo ? 1 : 0, id);
    }

    public static void eliminar(int id) {
        Db.update("DELETE FROM oficinas WHERE id = ?", id);
    }

    public static List<String> listarGrupos() {
        return Db.list("SELECT DISTINCT grupo FROM oficinas WHERE grupo IS NOT NULL AND grupo <> '' ORDER BY grupo ASC",
                rs -> rs.getString("grupo"));
    }
}
