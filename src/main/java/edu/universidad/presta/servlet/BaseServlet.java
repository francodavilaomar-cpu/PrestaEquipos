package edu.universidad.presta.servlet;

import edu.universidad.presta.dao.NotificacionDao;
import edu.universidad.presta.dao.PrestamoDao;
import edu.universidad.presta.dao.SolicitudDao;
import edu.universidad.presta.model.Notificacion;
import edu.universidad.presta.model.Usuario;
import edu.universidad.presta.util.Json;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;

/** Utilidades comunes de los controladores: vistas, mensajes flash, parámetros y usuario actual. */
public abstract class BaseServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final String VISTAS = "/WEB-INF/views/";

    // ------------------------------------------------------------------ vistas

    /** Muestra una vista dentro del layout (menú lateral, cabecera, mensajes). */
    protected void render(HttpServletRequest req, HttpServletResponse res, String vista, String titulo, String menu)
            throws ServletException, IOException {
        req.setAttribute("pageTitle", titulo);
        req.setAttribute("nav", menu);
        cargarDatosDelLayout(req);
        req.getRequestDispatcher(VISTAS + vista + ".jsp").forward(req, res);
    }

    /** Vista sin layout (pantalla de login). */
    protected void renderSimple(HttpServletRequest req, HttpServletResponse res, String vista)
            throws ServletException, IOException {
        req.getRequestDispatcher(VISTAS + vista + ".jsp").forward(req, res);
    }

    /**
     * Solo el fragmento del formulario (sin layout ni cabecera), para insertarlo dentro de un modal.
     * La ruta es relativa a /WEB-INF/views/ y se escribe con guion bajo inicial (p. ej. "equipos/_form").
     */
    protected void renderFragmento(HttpServletRequest req, HttpServletResponse res, String fragmento)
            throws ServletException, IOException {
        // Marca el modo modal: los fragmentos no dibujan su propia fila de botones
        // (Cancelar / Guardar) porque el modal ya tiene la suya.
        req.setAttribute("esModal", Boolean.TRUE);
        req.getRequestDispatcher(VISTAS + fragmento + ".jsp").forward(req, res);
    }

    /** Datos que muestra la cabecera: campana de avisos (encargados) o últimas solicitudes (usuarios). */
    private void cargarDatosDelLayout(HttpServletRequest req) {
        Usuario u = usuario(req);
        if (u == null) {
            return;
        }
        if (u.isEncargado()) {
            req.setAttribute("notificaciones", PrestamoDao.contarVencidos());
            List<Notificacion> lista = NotificacionDao.deEncargado(u.getId());
            req.setAttribute("notificacionesLista", lista);
            req.setAttribute("notificacionesNoLeidas", NotificacionDao.contarNoLeidas(lista));
        } else {
            req.setAttribute("notificacionesUsuario", SolicitudDao.recientesDe(u.getId(), 5));
        }
    }

    protected void redirigir(HttpServletRequest req, HttpServletResponse res, String ruta) throws IOException {
        res.sendRedirect(req.getContextPath() + ruta);
    }

    // ------------------------------------------------------------------ mensajes flash

    /** Mensaje que se muestra en la siguiente página. tipo: success, danger, warning, info. */
    protected void flash(HttpServletRequest req, String mensaje, String tipo) {
        req.getSession().setAttribute("mensaje", mensaje);
        req.getSession().setAttribute("mensaje_tipo", tipo);
    }

    // ------------------------------------------------------------------ usuario y permisos

    protected Usuario usuario(HttpServletRequest req) {
        return (Usuario) req.getAttribute("usuarioActual");
    }

    protected boolean esAdmin(HttpServletRequest req) {
        Usuario u = usuario(req);
        return u != null && u.isAdmin();
    }

    protected boolean esEncargado(HttpServletRequest req) {
        Usuario u = usuario(req);
        return u != null && u.isEncargado();
    }

    // ------------------------------------------------------------------ parámetros

    /** Parámetro recortado ("" si no viene). */
    protected String p(HttpServletRequest req, String nombre) {
        String v = req.getParameter(nombre);
        return v == null ? "" : v.trim();
    }

    /** Parámetro sin recortar (contraseñas). */
    protected String raw(HttpServletRequest req, String nombre) {
        String v = req.getParameter(nombre);
        return v == null ? "" : v;
    }

    /** Entero o null si el texto no es un número. */
    protected Integer entero(String texto) {
        try {
            return Integer.valueOf(texto.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /** Parte de la URL después del módulo: /equipos/crear → "/crear". */
    protected String subRuta(HttpServletRequest req, String porDefecto) {
        String s = req.getPathInfo();
        if (s == null || s.equals("/")) {
            return porDefecto;
        }
        return s.endsWith("/") ? s.substring(0, s.length() - 1) : s;
    }

    // ------------------------------------------------------------------ modales del panel

    /** El cliente pide únicamente el fragmento del formulario (sin layout) para meterlo en un modal. */
    protected boolean esModal(HttpServletRequest req) {
        return "1".equals(req.getParameter("modal"));
    }

    /** El cliente espera una respuesta JSON en lugar de una página (envío del formulario dentro del modal). */
    protected boolean esAjax(HttpServletRequest req) {
        return "1".equals(req.getParameter("ajax"))
                || "XMLHttpRequest".equalsIgnoreCase(req.getHeader("X-Requested-With"));
    }

    /** Responde en JSON al modal: ok + mensaje + lista de errores de validación. */
    protected void responderJson(HttpServletResponse res, boolean ok, String mensaje, List<String> errores)
            throws IOException {
        res.setContentType("application/json;charset=UTF-8");
        res.setCharacterEncoding("UTF-8");
        StringBuilder sb = new StringBuilder("{\"ok\":").append(ok);
        sb.append(",\"mensaje\":").append(Json.texto(mensaje == null ? "" : mensaje));
        sb.append(",\"errores\":[");
        if (errores != null) {
            for (int i = 0; i < errores.size(); i++) {
                if (i > 0) {
                    sb.append(',');
                }
                sb.append(Json.texto(errores.get(i)));
            }
        }
        sb.append("]}");
        res.getWriter().write(sb.toString());
    }
}
