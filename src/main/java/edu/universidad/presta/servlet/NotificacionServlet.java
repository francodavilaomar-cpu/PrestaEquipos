package edu.universidad.presta.servlet;

import edu.universidad.presta.dao.Db;
import edu.universidad.presta.dao.NotificacionDao;
import edu.universidad.presta.model.Notificacion;
import edu.universidad.presta.model.Usuario;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * Campana de la cabecera: lista completa de avisos y acción "Marcar todas como leídas".
 * La campana desplegable de la cabecera usa esta misma acción por AJAX.
 */
@WebServlet(urlPatterns = {"/notificaciones", "/notificaciones/*"})
public class NotificacionServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        if ("/ir".equals(subRuta(req, ""))) {
            marcarYRedirigir(req, res);
            return;
        }
        if ("1".equals(p(req, "ajax"))) {
            if (!esEncargado(req)) {
                res.sendError(HttpServletResponse.SC_FORBIDDEN);
                return;
            }
            responderJsonNotificaciones(req, res);
            return;
        }
        if (!esEncargado(req)) {
            redirigir(req, res, "/dashboard");
            return;
        }
        listar(req, res);
    }

    private void marcarYRedirigir(HttpServletRequest req, HttpServletResponse res) throws IOException {
        Usuario u = usuario(req);
        String clave = p(req, "clave");
        String url = p(req, "url");
        if (!clave.isEmpty()) {
            Db.update("IF NOT EXISTS (SELECT 1 FROM notificaciones_leidas WHERE usuario_id = ? AND clave = ?) "
                    + "INSERT INTO notificaciones_leidas (usuario_id, clave) VALUES (?, ?)",
                    u.getId(), clave, u.getId(), clave);
        }
        if (url.isEmpty() || !url.startsWith("/")) {
            url = "/notificaciones";
        }
        redirigir(req, res, url);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        if (!esEncargado(req)) {
            redirigir(req, res, "/dashboard");
            return;
        }
        if ("marcar_todas".equals(p(req, "accion"))) {
            NotificacionDao.marcarTodas(usuario(req).getId());
            if (esAjax(req)) {
                responderJson(res, true, "Todas las notificaciones se marcaron como leídas.", null);
            } else {
                flash(req, "Todas las notificaciones se marcaron como leídas.", "success");
                redirigir(req, res, "/notificaciones");
            }
            return;
        }
        redirigir(req, res, "/notificaciones");
    }

    private void responderJsonNotificaciones(HttpServletRequest req, HttpServletResponse res) throws IOException {
        Usuario u = usuario(req);
        List<Notificacion> todas = NotificacionDao.deEncargado(u.getId());
        long noLeidas = NotificacionDao.contarNoLeidas(todas);
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
        StringBuilder sb = new StringBuilder();
        sb.append("{\"noLeidas\":").append(noLeidas).append(",\"items\":[");
        for (int i = 0; i < todas.size(); i++) {
            Notificacion n = todas.get(i);
            if (i > 0) {
                sb.append(",");
            }
            sb.append("{");
            sb.append("\"clave\":\"").append(esc(n.getClave())).append("\",");
            sb.append("\"tipo\":\"").append(esc(n.getTipo())).append("\",");
            sb.append("\"titulo\":\"").append(esc(n.getTitulo())).append("\",");
            sb.append("\"mensaje\":\"").append(esc(n.getMensaje())).append("\",");
            sb.append("\"fecha\":\"").append(n.getFecha() == null ? "" : esc(n.getFecha().format(fmt))).append("\",");
            sb.append("\"enlace\":\"").append(esc(n.getEnlace())).append("\",");
            sb.append("\"icono\":\"").append(esc(n.getIcono())).append("\",");
            sb.append("\"tono\":\"").append(esc(n.getTono())).append("\",");
            sb.append("\"leida\":").append(n.isLeida());
            sb.append("}");
        }
        sb.append("]}");
        res.setContentType("application/json; charset=UTF-8");
        res.getWriter().write(sb.toString());
    }

    private static String esc(String v) {
        if (v == null) {
            return "";
        }
        return v.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t");
    }

    private void listar(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        Usuario u = usuario(req);
        boolean soloNoLeidas = "no-leidas".equals(p(req, "filtro"));
        List<Notificacion> todas = NotificacionDao.deEncargado(u.getId());
        long noLeidas = NotificacionDao.contarNoLeidas(todas);
        List<Notificacion> visibles = soloNoLeidas
                ? todas.stream().filter(n -> !n.isLeida()).toList()
                : todas;

        req.setAttribute("notificacionesLista", todas);
        req.setAttribute("notificacionesVisibles", visibles);
        req.setAttribute("notificacionesTodas", todas.size());
        req.setAttribute("notificacionesNoLeidas", noLeidas);
        req.setAttribute("filtroNoLeidas", soloNoLeidas);
        req.setAttribute("vistaNotificaciones", Boolean.TRUE);
        render(req, res, "notificaciones/listar", "Notificaciones", "notificaciones");
    }
}
