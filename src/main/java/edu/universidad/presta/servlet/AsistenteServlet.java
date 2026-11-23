package edu.universidad.presta.servlet;

import edu.universidad.presta.ai.OpenAiChatClient;
import edu.universidad.presta.dao.DataAccessException;
import edu.universidad.presta.dao.EquipoDao;
import edu.universidad.presta.dao.MantenimientoDao;
import edu.universidad.presta.dao.PrestamoDao;
import edu.universidad.presta.model.AlertaMantenimiento;
import edu.universidad.presta.model.Equipo;
import edu.universidad.presta.model.Mantenimiento;
import edu.universidad.presta.model.Prestamo;
import edu.universidad.presta.model.Usuario;
import edu.universidad.presta.service.AsistenteIAService;
import edu.universidad.presta.util.Fechas;
import edu.universidad.presta.util.Json;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/** Endpoints del asistente conversacional, búsqueda, alertas y mantenimiento preventivo. */
@WebServlet(urlPatterns = {"/ia", "/ia/*"})
public class AsistenteServlet extends BaseServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(AsistenteServlet.class.getName());
    private static final DateTimeFormatter FECHA = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        String ruta = subRuta(req, "/inicio");
        switch (ruta) {
            case "/buscar": buscar(req, res); break;
            case "/recomendaciones": recomendaciones(req, res); break;
            case "/alertas": alertas(req, res); break;
            case "/mantenimiento": paginaMantenimiento(req, res); break;
            case "/mantenimiento/datos": datosMantenimiento(req, res); break;
            default: res.sendError(HttpServletResponse.SC_NOT_FOUND);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        String ruta = subRuta(req, "/chat");
        switch (ruta) {
            case "/chat": chat(req, res); break;
            case "/mantenimiento/registrar": registrarMantenimiento(req, res); break;
            case "/mantenimiento/iniciar": iniciarMantenimiento(req, res); break;
            case "/mantenimiento/finalizar": finalizarMantenimiento(req, res); break;
            default: res.sendError(HttpServletResponse.SC_NOT_FOUND);
        }
    }

    private void chat(HttpServletRequest req, HttpServletResponse res) throws IOException {
        Usuario u = usuario(req);
        String mensaje = p(req, "mensaje");
        Long conversacion = numeroLargo(p(req, "conversacion_id"));
        try {
            AsistenteIAService.Resultado r = AsistenteIAService.responder(u, mensaje, conversacion);
            json(res, "{\"ok\":true,\"respuesta\":" + Json.texto(r.getRespuesta())
                    + ",\"conversacionId\":" + r.getConversacionId()
                    + ",\"modo\":" + Json.texto(r.getModo()) + "}");
        } catch (IllegalArgumentException e) {
            jsonError(res, HttpServletResponse.SC_BAD_REQUEST, e.getMessage());
        } catch (DataAccessException e) {
            LOG.log(Level.WARNING, "No se pudo consultar el contexto del asistente", e);
            jsonError(res, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "No pude consultar la información del sistema en este momento. Inténtalo nuevamente.");
        } catch (RuntimeException e) {
            LOG.log(Level.SEVERE, "Error inesperado en el asistente", e);
            jsonError(res, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "El asistente no pudo procesar la consulta.");
        }
    }

    private void buscar(HttpServletRequest req, HttpServletResponse res) throws IOException {
        Usuario u = usuario(req);
        String q = p(req, "q");
        List<Equipo> equipos = EquipoDao.buscarInteligente(q, !u.isEncargado(), 12);
        StringBuilder out = new StringBuilder("{\"ok\":true,\"equipos\":[");
        for (int i = 0; i < equipos.size(); i++) {
            Equipo e = equipos.get(i); if (i > 0) out.append(',');
            out.append("{\"id\":").append(e.getId())
                    .append(",\"nombre\":").append(Json.texto(e.getNombre()))
                    .append(",\"codigo\":").append(Json.texto(e.getCodigoInventario()))
                    .append(",\"categoria\":").append(Json.texto(e.getCategoriaNombre()))
                    .append(",\"estado\":").append(Json.texto(e.getEstado()))
                    .append(",\"ubicacion\":").append(Json.texto(e.getUbicacion())).append('}');
        }
        out.append("]}"); json(res, out.toString());
    }

    private void recomendaciones(HttpServletRequest req, HttpServletResponse res) throws IOException {
        List<Equipo> equipos = EquipoDao.recomendados(8);
        StringBuilder out = new StringBuilder("{\"ok\":true,\"equipos\":[");
        for (int i = 0; i < equipos.size(); i++) {
            Equipo e = equipos.get(i); if (i > 0) out.append(',');
            out.append("{\"id\":").append(e.getId()).append(",\"nombre\":").append(Json.texto(e.getNombre()))
                    .append(",\"codigo\":").append(Json.texto(e.getCodigoInventario()))
                    .append(",\"categoria\":").append(Json.texto(e.getCategoriaNombre()))
                    .append(",\"ubicacion\":").append(Json.texto(e.getUbicacion())).append('}');
        }
        out.append("],\"criterio\":\"Disponibilidad y demanda histórica de préstamos\"}"); json(res, out.toString());
    }

    private void alertas(HttpServletRequest req, HttpServletResponse res) throws IOException {
        Usuario u = usuario(req);
        if (u.isEncargado()) {
            json(res, "{\"ok\":true,\"prestamosVencidos\":" + PrestamoDao.contarVencidos()
                    + ",\"mensaje\":\"Consulta el módulo Vencidos para ver el detalle de gestión.\"}");
            return;
        }
        List<Prestamo> prestamos = PrestamoDao.activosDeUsuario(u.getId());
        StringBuilder out = new StringBuilder("{\"ok\":true,\"prestamos\":[");
        for (int i = 0; i < prestamos.size(); i++) {
            Prestamo p = prestamos.get(i); if (i > 0) out.append(',');
            out.append("{\"equipo\":").append(Json.texto(p.getEquipoNombre()))
                    .append(",\"codigo\":").append(Json.texto(p.getCodigoInventario()))
                    .append(",\"fechaDevolucion\":").append(Json.texto(p.getFechaDevolucionEsperada() == null ? "Sin fecha" : p.getFechaDevolucionEsperada().format(FECHA)))
                    .append(",\"vencido\":").append(p.isVencido()).append('}');
        }
        out.append("]}"); json(res, out.toString());
    }

    private void paginaMantenimiento(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        if (!esEncargado(req)) { res.sendError(HttpServletResponse.SC_FORBIDDEN); return; }
        req.setAttribute("alertasMantenimiento", MantenimientoDao.alertasPreventivas());
        req.setAttribute("mantenimientos", MantenimientoDao.recientes(40));
        List<Equipo> equiposMant = new ArrayList<>();
        for (Equipo e : EquipoDao.catalogo()) {
            if (!"dado_de_baja".equals(e.getEstado())) equiposMant.add(e);
        }
        req.setAttribute("equiposMantenimiento", equiposMant);
        render(req, res, "ia/mantenimiento", "Mantenimiento inteligente", "mantenimiento");
    }

    private void datosMantenimiento(HttpServletRequest req, HttpServletResponse res) throws IOException {
        if (!esEncargado(req)) { jsonError(res, HttpServletResponse.SC_FORBIDDEN, "No tienes permisos para ver este módulo."); return; }
        List<AlertaMantenimiento> alertas = MantenimientoDao.alertasPreventivas();
        StringBuilder out = new StringBuilder("{\"ok\":true,\"alertas\":[");
        for (int i = 0; i < alertas.size(); i++) {
            AlertaMantenimiento a = alertas.get(i); if (i > 0) out.append(',');
            out.append("{\"equipo\":").append(Json.texto(a.getEquipoNombre()))
                    .append(",\"codigo\":").append(Json.texto(a.getCodigoInventario()))
                    .append(",\"prioridad\":").append(Json.texto(a.getPrioridad()))
                    .append(",\"puntaje\":").append(a.getPuntaje())
                    .append(",\"motivo\":").append(Json.texto(a.getMotivo())).append('}');
        }
        out.append("],\"nota\":\"Indicadores basados en reglas y registros disponibles; requieren validación técnica.\"}"); json(res, out.toString());
    }

    private void registrarMantenimiento(HttpServletRequest req, HttpServletResponse res) throws IOException {
        if (!esEncargado(req)) { res.sendError(HttpServletResponse.SC_FORBIDDEN); return; }
        Integer equipoId = entero(p(req, "equipo_id"));
        String tipo = p(req, "tipo");
        String descripcion = p(req, "descripcion");
        LocalDateTime fecha = Fechas.parse(p(req, "fecha_programada"));
        Equipo equipo = equipoId == null ? null : EquipoDao.porId(equipoId);
        if (equipo == null || "dado_de_baja".equals(equipo.getEstado()) || descripcion.isBlank()
                || descripcion.length() > 2000 || (fecha != null && fecha.isBefore(Fechas.ahora()))
                || !("preventivo".equals(tipo) || "correctivo".equals(tipo))) {
            flash(req, "Revisa el equipo, tipo y descripción del mantenimiento.", "warning");
            redirigir(req, res, "/ia/mantenimiento"); return;
        }
        MantenimientoDao.registrar(equipoId, usuario(req).getId(), tipo, descripcion, fecha);
        flash(req, "Mantenimiento programado correctamente.", "success");
        redirigir(req, res, "/ia/mantenimiento");
    }

    private void iniciarMantenimiento(HttpServletRequest req, HttpServletResponse res) throws IOException {
        if (!esEncargado(req)) { res.sendError(HttpServletResponse.SC_FORBIDDEN); return; }
        Integer id = entero(p(req, "id"));
        boolean ok = id != null && MantenimientoDao.iniciar(id, usuario(req).getId());
        flash(req, ok ? "Mantenimiento iniciado. El equipo pasó al estado de mantenimiento." : "No se pudo iniciar. Verifica que esté programado y que no tenga un préstamo activo.", ok ? "success" : "warning");
        redirigir(req, res, "/ia/mantenimiento");
    }

    private void finalizarMantenimiento(HttpServletRequest req, HttpServletResponse res) throws IOException {
        if (!esEncargado(req)) { res.sendError(HttpServletResponse.SC_FORBIDDEN); return; }
        Integer id = entero(p(req, "id"));
        String observaciones = p(req, "observaciones");
        boolean ok = id != null && MantenimientoDao.finalizar(id, usuario(req).getId(), observaciones);
        flash(req, ok ? "Mantenimiento finalizado y registrado en el historial." : "No se pudo finalizar el mantenimiento.", ok ? "success" : "warning");
        redirigir(req, res, "/ia/mantenimiento");
    }

    private static Long numeroLargo(String s) {
        try { return s == null || s.isBlank() ? null : Long.valueOf(s); }
        catch (NumberFormatException e) { return null; }
    }

    private static void json(HttpServletResponse res, String contenido) throws IOException {
        res.setCharacterEncoding("UTF-8"); res.setContentType("application/json;charset=UTF-8");
        res.setHeader("Cache-Control", "no-store"); res.getWriter().write(contenido);
    }

    private static void jsonError(HttpServletResponse res, int status, String mensaje) throws IOException {
        res.setStatus(status); json(res, "{\"ok\":false,\"mensaje\":" + Json.texto(mensaje) + "}");
    }
}
