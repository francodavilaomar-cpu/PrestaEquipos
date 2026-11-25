package edu.universidad.presta.dao;

import edu.universidad.presta.util.Fechas;
import edu.universidad.presta.model.Usuario;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public final class UsuarioDao {

    private UsuarioDao() {
    }

    private static Usuario map(ResultSet rs) throws SQLException {
        Usuario u = new Usuario();
        u.setId(rs.getInt("id"));
        u.setNombre(rs.getString("nombre"));
        u.setDni(rs.getString("dni"));
        u.setCelular(rs.getString("celular"));
        u.setEmail(rs.getString("email"));
        u.setPasswordHash(rs.getString("password_hash"));
        u.setRol(rs.getString("rol"));
        if (Db.has(rs, "oficina")) {
            u.setOficina(rs.getString("oficina"));
        }
        u.setEstado(rs.getInt("estado"));
        u.setFechaRegistro(Db.dt(rs, "fecha_registro"));
        return u;
    }

    public static Usuario porId(int id) {
        return Db.one("SELECT * FROM usuarios WHERE id = ?", UsuarioDao::map, id);
    }

    public static Usuario porEmailActivo(String email) {
        return Db.one("SELECT * FROM usuarios WHERE email = ? AND estado = 1", UsuarioDao::map, email);
    }

    /** Listado del módulo Usuarios: filtro por texto (nombre, email, DNI, celular) y rol. */
    public static List<Usuario> listar(String busqueda, String rol) {
        StringBuilder sql = new StringBuilder("SELECT * FROM usuarios WHERE 1=1");
        List<Object> p = new ArrayList<>();
        if (!busqueda.isEmpty()) {
            sql.append(" AND (nombre LIKE ? OR email LIKE ? OR dni LIKE ? OR celular LIKE ?)");
            for (int i = 0; i < 4; i++) {
                p.add("%" + busqueda + "%");
            }
        }
        if (!rol.isEmpty()) {
            sql.append(" AND rol = ?");
            p.add(rol);
        }
        sql.append(" ORDER BY nombre");
        return Db.list(sql.toString(), UsuarioDao::map, p.toArray());
    }

    /** Usuarios activos (buscador del formulario de préstamos). */
    public static List<Usuario> activos() {
        return Db.list("SELECT * FROM usuarios WHERE estado = 1 ORDER BY nombre", UsuarioDao::map);
    }

    /** Búsqueda directa por DNI, celular, email o parte del nombre. */
    public static Usuario buscarActivo(String texto) {
        return Db.one("SELECT TOP (1) * FROM usuarios WHERE estado = 1 AND (dni = ? OR celular = ? OR email = ? OR nombre LIKE ?)",
                UsuarioDao::map, texto, texto, texto, "%" + texto + "%");
    }

    public static boolean existeDni(String dni, int excluirId) {
        return Db.scalar("SELECT COUNT(*) FROM usuarios WHERE dni = ? AND id <> ?", dni, excluirId) > 0;
    }

    public static boolean existeEmail(String email, int excluirId) {
        return Db.scalar("SELECT COUNT(*) FROM usuarios WHERE email = ? AND id <> ?", email, excluirId) > 0;
    }

    public static long crear(String nombre, String dni, String celular, String email, String hash, String rol, String oficina) {
        return Db.insert("INSERT INTO usuarios (nombre, dni, celular, email, password_hash, rol, oficina, estado, fecha_registro) VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)",
                nombre, dni, celular, email, hash, rol, oficina, Fechas.ahora());
    }

    public static long crear(String nombre, String dni, String celular, String email, String hash, String rol) {
        return crear(nombre, dni, celular, email, hash, rol, null);
    }

    /** Actualiza los datos; si hash es null se conserva la contraseña actual. */
    public static void actualizar(int id, String nombre, String dni, String celular, String email, String rol, String oficina, String hash) {
        if (hash == null) {
            Db.update("UPDATE usuarios SET nombre = ?, dni = ?, celular = ?, email = ?, rol = ?, oficina = ? WHERE id = ?",
                    nombre, dni, celular, email, rol, oficina, id);
        } else {
            Db.update("UPDATE usuarios SET nombre = ?, dni = ?, celular = ?, email = ?, rol = ?, oficina = ?, password_hash = ? WHERE id = ?",
                    nombre, dni, celular, email, rol, oficina, hash, id);
        }
    }

    public static void actualizar(int id, String nombre, String dni, String celular, String email, String rol, String hash) {
        actualizar(id, nombre, dni, celular, email, rol, null, hash);
    }

    /** Cambia solo la contraseña (perfil y recuperación). */
    public static void setPassword(int id, String hash) {
        Db.update("UPDATE usuarios SET password_hash = ? WHERE id = ?", hash, id);
    }

    /** Usuario activo que coincide con correo y DNI (verificación de identidad al recuperar la contraseña). */
    public static Usuario porEmailYDniActivo(String email, String dni) {
        return Db.one("SELECT * FROM usuarios WHERE email = ? AND dni = ? AND estado = 1", UsuarioDao::map, email, dni);
    }

    public static void setEstado(int id, int estado) {
        Db.update("UPDATE usuarios SET estado = ? WHERE id = ?", estado, id);
    }

    /** Elimina un usuario por su ID siempre que no sea administrador principal. */
    public static void eliminar(int id) {
        Db.tx(c -> {
            // Eliminar registros dependientes si existieran
            Db.update(c, "DELETE FROM notificaciones_leidas WHERE usuario_id = ?", id);
            Db.update(c, "DELETE FROM solicitudes WHERE usuario_id = ?", id);
            Db.update(c, "DELETE FROM prestamos WHERE usuario_id = ?", id);
            Db.update(c, "DELETE FROM reservas WHERE usuario_id = ?", id);
            Db.update(c, "UPDATE historial_movimientos SET usuario_id = NULL WHERE usuario_id = ?", id);
            Db.update(c, "DELETE FROM usuarios WHERE id = ?", id);
            return null;
        });
    }
}
