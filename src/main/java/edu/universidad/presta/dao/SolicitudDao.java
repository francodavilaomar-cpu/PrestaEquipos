package edu.universidad.presta.dao;

import edu.universidad.presta.util.Fechas;
import edu.universidad.presta.model.Solicitud;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.List;

public final class SolicitudDao {

    private SolicitudDao() {
    }

    private static Solicitud map(ResultSet rs) throws SQLException {
        Solicitud s = new Solicitud();
        s.setId(rs.getInt("id"));
        s.setUsuarioId(rs.getInt("usuario_id"));
        s.setEquipoSolicitado(rs.getString("equipo_solicitado"));
        s.setFechaPrestamo(Db.dt(rs, "fecha_prestamo"));
        s.setFechaDevolucion(Db.dt(rs, "fecha_devolucion"));
        s.setOficina(rs.getString("oficina"));
        s.setEstado(rs.getString("estado"));
        s.setObservaciones(rs.getString("observaciones"));
        if (Db.has(rs, "motivo_rechazo")) {
            s.setMotivoRechazo(rs.getString("motivo_rechazo"));
        }
        s.setFechaSolicitud(Db.dt(rs, "fecha_solicitud"));
        if (Db.has(rs, "usuario_nombre")) {
            s.setUsuarioNombre(rs.getString("usuario_nombre"));
            s.setUsuarioEmail(rs.getString("usuario_email"));
        }
        return s;
    }

    public static void crear(int usuarioId, String equipo, LocalDateTime fechaPrestamo, LocalDateTime fechaDevolucion,
                             String oficina, String observaciones) {
        Db.update("INSERT INTO solicitudes (usuario_id, equipo_solicitado, fecha_prestamo, fecha_devolucion, oficina, observaciones, fecha_solicitud) VALUES (?, ?, ?, ?, ?, ?, ?)",
                usuarioId, equipo, fechaPrestamo, fechaDevolucion, oficina, observaciones, Fechas.ahora());
    }

    /** Bandeja completa (encargados y administradores). */
    public static List<Solicitud> todas() {
        return Db.list("SELECT s.*, u.nombre AS usuario_nombre, u.email AS usuario_email FROM solicitudes s "
                + "LEFT JOIN usuarios u ON s.usuario_id = u.id ORDER BY s.fecha_solicitud DESC", SolicitudDao::map);
    }

    public static Solicitud porId(int id) {
        return Db.one("SELECT s.*, u.nombre AS usuario_nombre, u.email AS usuario_email FROM solicitudes s "
                + "LEFT JOIN usuarios u ON s.usuario_id = u.id WHERE s.id = ?", SolicitudDao::map, id);
    }

    public static List<Solicitud> deUsuario(int usuarioId) {
        return Db.list("SELECT * FROM solicitudes WHERE usuario_id = ? ORDER BY fecha_solicitud DESC", SolicitudDao::map, usuarioId);
    }

    public static long contarPendientes() {
        return Db.scalar("SELECT COUNT(*) FROM solicitudes WHERE estado = 'pendiente'");
    }

    public static boolean tieneSolicitudActivaDelEquipo(int usuarioId, String equipo) {
        if (equipo == null || equipo.trim().isEmpty()) return false;
        long total = Db.scalar("SELECT COUNT(*) FROM solicitudes WHERE usuario_id = ? AND estado IN ('pendiente', 'aprobada', 'prestado') "
                + "AND (LOWER(equipo_solicitado) = LOWER(?) OR equipo_solicitado LIKE ?)",
                usuarioId, equipo.trim(), "%" + equipo.trim() + "%");
        return total > 0;
    }

    public static List<Solicitud> recientesDe(int usuarioId, int limite) {
        return Db.list("SELECT TOP (" + limite + ") * FROM solicitudes WHERE usuario_id = ? ORDER BY fecha_solicitud DESC",
                SolicitudDao::map, usuarioId);
    }

    public static void setEstado(int id, String estado) {
        Db.update("UPDATE solicitudes SET estado = ? WHERE id = ?", estado, id);
    }

    public static void rechazar(int id, String motivo) {
        Db.update("UPDATE solicitudes SET estado = 'rechazada', motivo_rechazo = ? WHERE id = ?", motivo, id);
    }

    /** Elimina una solicitud de la bandeja por su ID. */
    public static void eliminar(int id) {
        Db.update("DELETE FROM solicitudes WHERE id = ?", id);
    }

    /** Elimina todas las solicitudes con un estado dado (ej. aprobadas). */
    public static void eliminarPorEstado(String estado) {
        Db.update("DELETE FROM solicitudes WHERE estado = ?", estado);
    }
}
