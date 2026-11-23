package edu.universidad.presta.servlet;

import edu.universidad.presta.dao.OficinaDao;
import edu.universidad.presta.model.Oficina;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@WebServlet(urlPatterns = {"/oficinas", "/oficinas/*"})
public class OficinaServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        if (!esAdmin(req)) {
            redirigir(req, res, "/dashboard");
            return;
        }

        switch (subRuta(req, "/listar")) {
            case "/listar":
                listar(req, res);
                break;
            case "/crear":
                formulario(req, res, null);
                break;
            case "/editar":
                Integer id = entero(p(req, "id"));
                Oficina o = (id == null) ? null : OficinaDao.porId(id);
                if (o == null) {
                    flash(req, "Oficina no encontrada.", "danger");
                    redirigir(req, res, "/oficinas/listar");
                    return;
                }
                formulario(req, res, o);
                break;
            default:
                redirigir(req, res, "/oficinas/listar");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        if (!esAdmin(req)) {
            redirigir(req, res, "/dashboard");
            return;
        }

        switch (subRuta(req, "/listar")) {
            case "/guardar":
                guardar(req, res);
                break;
            case "/eliminar":
                eliminar(req, res);
                break;
            default:
                redirigir(req, res, "/oficinas/listar");
        }
    }

    private void listar(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        req.setAttribute("oficinas", OficinaDao.listarTodas());
        req.setAttribute("grupos", OficinaDao.listarGrupos());
        render(req, res, "oficinas/listar", "Gestión de Oficinas y Áreas", "oficinas");
    }

    private void formulario(HttpServletRequest req, HttpServletResponse res, Oficina oficina) throws ServletException, IOException {
        req.setAttribute("oficina", oficina);
        req.setAttribute("grupos", OficinaDao.listarGrupos());
        if (esModal(req)) {
            renderFragmento(req, res, "oficinas/_form");
            return;
        }
        render(req, res, "oficinas/form", oficina == null ? "Nueva Oficina / Área" : "Editar Oficina / Área", "oficinas");
    }

    private void guardar(HttpServletRequest req, HttpServletResponse res) throws IOException {
        Integer id = entero(p(req, "id"));
        String nombre = p(req, "nombre").trim();
        String grupo = p(req, "grupo").trim();
        String descripcion = p(req, "descripcion").trim();
        boolean activo = "1".equals(p(req, "activo")) || "on".equalsIgnoreCase(p(req, "activo")) || req.getParameter("activo") == null;

        List<String> errores = new ArrayList<>();
        if (nombre.isEmpty()) {
            errores.add("El nombre de la oficina o área es obligatorio.");
        }

        if (errores.isEmpty()) {
            Oficina existente = OficinaDao.porNombre(nombre);
            if (existente != null && (id == null || existente.getId() != id)) {
                errores.add("Ya existe una oficina o área con ese nombre.");
            }
        }

        if (errores.isEmpty()) {
            if (id == null || id <= 0) {
                OficinaDao.crear(nombre, grupo, descripcion);
                flash(req, "Oficina / área creada exitosamente.", "success");
            } else {
                OficinaDao.actualizar(id, nombre, grupo, descripcion, activo);
                flash(req, "Oficina / área actualizada exitosamente.", "success");
            }
            if (esAjax(req)) {
                responderJson(res, true, "Guardado exitosamente.", new ArrayList<>());
                return;
            }
            redirigir(req, res, "/oficinas/listar");
            return;
        }

        if (esAjax(req)) {
            responderJson(res, false, "Error al guardar oficina.", errores);
            return;
        }
        flash(req, errores.get(0), "danger");
        redirigir(req, res, "/oficinas/listar");
    }

    private void eliminar(HttpServletRequest req, HttpServletResponse res) throws IOException {
        Integer id = entero(p(req, "id"));
        if (id != null && id > 0) {
            OficinaDao.eliminar(id);
            flash(req, "Oficina / área eliminada correctamente.", "success");
        }
        redirigir(req, res, "/oficinas/listar");
    }
}
