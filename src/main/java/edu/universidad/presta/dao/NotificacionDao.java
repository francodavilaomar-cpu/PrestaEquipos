package edu.universidad.presta.dao;

import edu.universidad.presta.model.Notificacion;
import edu.universidad.presta.model.Prestamo;
import edu.universidad.presta.model.Solicitud;
import edu.universidad.presta.util.Fechas;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Notificaciones de la cabecera. Los avisos no se guardan: se calculan al vuelo a partir de las
 * solicitudes pendientes y de los préstamos vencidos o próximos a vencer. En la tabla
 * notificaciones_leidas solo se recuerda qué avisos ya leyó cada usuario.
 */
public final class NotificacionDao {

    /** Tope por tipo para no llenar el desplegable con avisos antiguos. */
    private static final int LIMITE_POR_TIPO = 15;
    private static final DateTimeFormatter FECHA_HORA = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    private NotificacionDao() {
    }

    /** Avisos del panel de administración (admin y encargado), ya marcados como leídos o no. */
    public static List<Notificacion> deEncargado(int usuarioId) {
        List<Notificacion> lista = avisosActuales();
        Set<String> leidas = clavesLeidas(usuarioId);
        for (Notificacion n : lista) {
            n.setLeida(leidas.contains(n.getClave()));
        }
        return lista;
    }

    /** Avisos personalizados para un usuario normal: sus solicitudes y préstamos recientes. */
    public static List<Notificacion> deUsuario(int usuarioId) {
        List<Notificacion> lista = new ArrayList<>();
        // Solicitudes del usuario
        List<Solicitud> solicitudes = SolicitudDao.deUsuario(usuarioId);
        int countSol = 0;
        for (Solicitud s : solicitudes) {
            if (countSol >= LIMITE_POR_TIPO) break;
            Notificacion n = new Notificacion();
            String estado = s.getEstado();
            n.setClave("solicitud-usuario:" + s.getId() + ":" + estado);
            n.setTipo("solicitud");
            n.setTitulo("Solicitud de préstamo");
            String msg = "Solicitaste " + s.getEquipoSolicitado() + " para " + s.getOficina() + ".";
            if ("aprobada".equals(estado)) msg += " (Aprobada)";
            else if ("rechazada".equals(estado)) msg += " (Rechazada)";
            else msg += " (Pendiente)";
            n.setMensaje(msg);
            n.setFecha(s.getFechaSolicitud());
            n.setEnlace("/equipos/listar?tab=mis_solicitudes");
            lista.add(n);
            countSol++;
        }
        // Préstamos del usuario
        for (Prestamo p : PrestamoDao.ultimos(usuarioId, LIMITE_POR_TIPO)) {
            Notificacion n = new Notificacion();
            if ("devuelto".equals(p.getEstado())) {
                n.setClave("prestamo-devuelto:" + p.getId());
                n.setTipo("prestamo");
                n.setTitulo("Préstamo devuelto");
                n.setMensaje("Devolverás/devolviste " + p.getEquipoNombre() + ".");
                n.setFecha(p.getFechaDevolucionReal());
            } else {
                n.setClave("prestamo-registrado:" + p.getId());
                n.setTipo("prestamo");
                n.setTitulo("Préstamo registrado");
                n.setMensaje("Se te prestó " + p.getEquipoNombre() + ".");
                n.setFecha(p.getFechaPrestamo());
            }
            n.setEnlace("/prestamos/mis");
            lista.add(n);
        }
        // Más recientes primero
        lista.sort(Comparator.comparing(Notificacion::getFecha, Comparator.nullsLast(Comparator.<LocalDateTime>reverseOrder())));
        Set<String> leidas = clavesLeidas(usuarioId);
        for (Notificacion n : lista) {
            n.setLeida(leidas.contains(n.getClave()));
        }
        return lista;
    }

    /** Cantidad de avisos que todavía no se leyeron. */
    public static long contarNoLeidas(List<Notificacion> lista) {
        return lista.stream().filter(n -> !n.isLeida()).count();
    }

    /** Marca como leídos todos los avisos que existen en este momento. */
    public static void marcarTodas(int usuarioId) {
        for (Notificacion n : avisosActuales()) {
            Db.update("IF NOT EXISTS (SELECT 1 FROM notificaciones_leidas WHERE usuario_id = ? AND clave = ?) "
                            + "INSERT INTO notificaciones_leidas (usuario_id, clave) VALUES (?, ?)",
                    usuarioId, n.getClave(), usuarioId, n.getClave());
        }
    }

    /** Marca como leídos los avisos de préstamos vencidos del usuario. */
    public static void marcarVencidos(int usuarioId) {
        for (Notificacion n : avisosActuales()) {
            if ("/prestamos/vencidos".equals(n.getEnlace())) {
                Db.update("IF NOT EXISTS (SELECT 1 FROM notificaciones_leidas WHERE usuario_id = ? AND clave = ?) "
                                + "INSERT INTO notificaciones_leidas (usuario_id, clave) VALUES (?, ?)",
                        usuarioId, n.getClave(), usuarioId, n.getClave());
            }
        }
    }

    /** Claves de los avisos ya leídos por el usuario. */
    public static Set<String> clavesLeidas(int usuarioId) {
        return new HashSet<>(Db.list("SELECT clave FROM notificaciones_leidas WHERE usuario_id = ?",
                rs -> rs.getString("clave"), usuarioId));
    }

    // ------------------------------------------------------------------ generación

    private static List<Notificacion> avisosActuales() {
        List<Notificacion> lista = new ArrayList<>();
        lista.addAll(solicitudesPendientes());
        lista.addAll(solicitudesAprobadas());
        lista.addAll(solicitudesRechazadas());
        lista.addAll(prestamosVencidos());
        lista.addAll(prestamosPorVencer());
        lista.addAll(prestamosRecientes());
        // Más recientes primero; los avisos sin fecha quedan al final.
        lista.sort(Comparator.comparing(Notificacion::getFecha,
                Comparator.nullsLast(Comparator.<LocalDateTime>reverseOrder())));
        return lista;
    }

    private static List<Notificacion> solicitudesPendientes() {
        return Db.list("SELECT TOP (" + LIMITE_POR_TIPO + ") s.id, s.equipo_solicitado, s.oficina, s.fecha_solicitud, "
                + "u.nombre AS usuario_nombre "
                + "FROM solicitudes s JOIN usuarios u ON s.usuario_id = u.id "
                + "WHERE s.estado = 'pendiente' ORDER BY s.fecha_solicitud DESC",
                NotificacionDao::mapSolicitud);
    }

    private static List<Notificacion> solicitudesAprobadas() {
        return Db.list("SELECT TOP (" + LIMITE_POR_TIPO + ") s.id, s.equipo_solicitado, s.oficina, s.fecha_solicitud, "
                + "u.nombre AS usuario_nombre "
                + "FROM solicitudes s JOIN usuarios u ON s.usuario_id = u.id "
                + "WHERE s.estado = 'aprobada' ORDER BY s.fecha_solicitud DESC",
                NotificacionDao::mapSolicitudAprobada);
    }

    private static List<Notificacion> solicitudesRechazadas() {
        return Db.list("SELECT TOP (" + LIMITE_POR_TIPO + ") s.id, s.equipo_solicitado, s.oficina, s.fecha_solicitud, "
                + "u.nombre AS usuario_nombre "
                + "FROM solicitudes s JOIN usuarios u ON s.usuario_id = u.id "
                + "WHERE s.estado = 'rechazada' ORDER BY s.fecha_solicitud DESC",
                NotificacionDao::mapSolicitudRechazada);
    }

    private static List<Notificacion> prestamosVencidos() {
        return Db.list("SELECT TOP (" + LIMITE_POR_TIPO + ") p.id, p.fecha_devolucion_esperada, "
                + "e.nombre AS equipo_nombre, u.nombre AS usuario_nombre "
                + "FROM prestamos p JOIN equipos e ON p.equipo_id = e.id JOIN usuarios u ON p.usuario_id = u.id "
                + "WHERE p.estado IN ('activo', 'vencido') AND p.fecha_devolucion_real IS NULL "
                + "AND p.fecha_devolucion_esperada < ? "
                + "ORDER BY p.fecha_devolucion_esperada ASC",
                NotificacionDao::mapVencido, Fechas.ahora());
    }

    private static List<Notificacion> prestamosPorVencer() {
        LocalDateTime ahora = Fechas.ahora();
        return Db.list("SELECT TOP (" + LIMITE_POR_TIPO + ") p.id, p.fecha_devolucion_esperada, "
                + "e.nombre AS equipo_nombre, u.nombre AS usuario_nombre "
                + "FROM prestamos p JOIN equipos e ON p.equipo_id = e.id JOIN usuarios u ON p.usuario_id = u.id "
                + "WHERE p.estado = 'activo' AND p.fecha_devolucion_real IS NULL "
                + "AND p.fecha_devolucion_esperada >= ? AND p.fecha_devolucion_esperada <= ? "
                + "ORDER BY p.fecha_devolucion_esperada ASC",
                NotificacionDao::mapPorVencer, ahora, ahora.plusHours(24));
    }

    private static List<Notificacion> prestamosRecientes() {
        return Db.list("SELECT TOP (" + LIMITE_POR_TIPO + ") p.id, p.fecha_prestamo, p.fecha_devolucion_real, p.estado, "
                + "e.nombre AS equipo_nombre, u.nombre AS usuario_nombre "
                + "FROM prestamos p JOIN equipos e ON p.equipo_id = e.id JOIN usuarios u ON p.usuario_id = u.id "
                + "ORDER BY p.fecha_prestamo DESC",
                NotificacionDao::mapPrestamoReciente);
    }

    // ------------------------------------------------------------------ mapeo

    private static Notificacion mapSolicitud(ResultSet rs) throws SQLException {
        String equipo = rs.getString("equipo_solicitado");
        String oficina = rs.getString("oficina");
        String usuario = rs.getString("usuario_nombre");
        Notificacion n = new Notificacion();
        n.setClave("solicitud-pendiente:" + rs.getInt("id"));
        n.setTipo("solicitud");
        n.setTitulo("Nueva solicitud de préstamo");
        n.setMensaje((usuario == null ? "Un usuario" : usuario) + " solicitó " + equipo
                + (oficina == null || oficina.isEmpty() ? "." : " para " + oficina + "."));
        n.setFecha(Db.dt(rs, "fecha_solicitud"));
        n.setEnlace("/equipos/listar?tab=solicitudes");
        return n;
    }

    private static Notificacion mapSolicitudAprobada(ResultSet rs) throws SQLException {
        String equipo = rs.getString("equipo_solicitado");
        String oficina = rs.getString("oficina");
        String usuario = rs.getString("usuario_nombre");
        Notificacion n = new Notificacion();
        n.setClave("solicitud-aprobada:" + rs.getInt("id"));
        n.setTipo("solicitud");
        n.setTitulo("Solicitud aprobada");
        String msgAprob = (usuario == null ? "Un usuario" : usuario) + " - " + equipo + (oficina == null || oficina.isEmpty() ? "." : " (" + oficina + ").");
        n.setMensaje(msgAprob);
        n.setFecha(Db.dt(rs, "fecha_solicitud"));
        n.setEnlace("/equipos/listar?tab=solicitudes");
        return n;
    }

    private static Notificacion mapSolicitudRechazada(ResultSet rs) throws SQLException {
        String equipo = rs.getString("equipo_solicitado");
        String oficina = rs.getString("oficina");
        String usuario = rs.getString("usuario_nombre");
        Notificacion n = new Notificacion();
        n.setClave("solicitud-rechazada:" + rs.getInt("id"));
        n.setTipo("solicitud");
        n.setTitulo("Solicitud rechazada");
        String msgAprob = (usuario == null ? "Un usuario" : usuario) + " - " + equipo + (oficina == null || oficina.isEmpty() ? "." : " (" + oficina + ").");
        n.setMensaje(msgAprob);
        n.setFecha(Db.dt(rs, "fecha_solicitud"));
        n.setEnlace("/equipos/listar?tab=solicitudes");
        return n;
    }

    private static Notificacion mapVencido(ResultSet rs) throws SQLException {
        LocalDateTime fecha = Db.dt(rs, "fecha_devolucion_esperada");
        Notificacion n = new Notificacion();
        n.setClave("prestamo-vencido:" + rs.getInt("id"));
        n.setTipo("vencido");
        n.setTitulo("Préstamo vencido");
        n.setMensaje("El préstamo de " + rs.getString("equipo_nombre") + " de " + rs.getString("usuario_nombre")
                + " debía devolverse el " + (fecha == null ? "" : fecha.format(FECHA_HORA)) + ".");
        n.setFecha(fecha);
        n.setEnlace("/prestamos/vencidos");
        return n;
    }

    private static Notificacion mapPorVencer(ResultSet rs) throws SQLException {
        LocalDateTime fecha = Db.dt(rs, "fecha_devolucion_esperada");
        Notificacion n = new Notificacion();
        n.setClave("prestamo-por-vencer:" + rs.getInt("id"));
        n.setTipo("por_vencer");
        n.setTitulo("Devolución próxima");
        n.setMensaje("El préstamo de " + rs.getString("equipo_nombre") + " de " + rs.getString("usuario_nombre")
                + " debe devolverse el " + (fecha == null ? "" : fecha.format(FECHA_HORA)) + ".");
        n.setFecha(fecha);
        n.setEnlace("/prestamos/vencidos");
        return n;
    }

    private static Notificacion mapPrestamoReciente(ResultSet rs) throws SQLException {
        int id = rs.getInt("id");
        String estado = rs.getString("estado");
        String equipo = rs.getString("equipo_nombre");
        String usuario = rs.getString("usuario_nombre");
        Notificacion n = new Notificacion();
        if ("devuelto".equals(estado)) {
            n.setClave("prestamo-devuelto:" + id);
            n.setTipo("prestamo");
            n.setTitulo("Préstamo devuelto");
            n.setMensaje((usuario == null ? "Un usuario" : usuario) + " devolvió " + equipo + ".");
            n.setFecha(Db.dt(rs, "fecha_devolucion_real"));
        } else {
            n.setClave("prestamo-registrado:" + id);
            n.setTipo("prestamo");
            n.setTitulo("Préstamo registrado");
            n.setMensaje("Se prestó " + equipo + " a " + (usuario == null ? "un usuario" : usuario) + ".");
            n.setFecha(Db.dt(rs, "fecha_prestamo"));
        }
        n.setEnlace("/prestamos/vencidos");
        return n;
    }
}
