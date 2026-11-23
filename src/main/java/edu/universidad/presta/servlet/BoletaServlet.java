package edu.universidad.presta.servlet;

import edu.universidad.presta.dao.PrestamoDao;
import edu.universidad.presta.dao.SolicitudDao;
import edu.universidad.presta.dao.UsuarioDao;
import edu.universidad.presta.model.Prestamo;
import edu.universidad.presta.model.Solicitud;
import edu.universidad.presta.model.Usuario;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * Boleta de un préstamo o de una solicitud: página lista para ver, imprimir o descargar en PDF.
 * /boleta?tipo=prestamo&id=N  |  /boleta?tipo=solicitud&id=N
 * Cada usuario solo ve sus propias boletas; admin y encargado ven todas.
 */
@WebServlet(urlPatterns = {"/boleta"})
public class BoletaServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        Usuario actual = usuario(req);
        Integer id = entero(p(req, "id"));
        String tipo = p(req, "tipo");
        if (actual == null || id == null) {
            res.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        int duenoId;
        if ("prestamo".equals(tipo)) {
            Prestamo pr = PrestamoDao.porId(id);
            if (pr == null) {
                res.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
            duenoId = pr.getUsuarioId();
            req.setAttribute("prestamo", pr);
        } else if ("solicitud".equals(tipo)) {
            Solicitud so = SolicitudDao.porId(id);
            if (so == null) {
                res.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
            duenoId = so.getUsuarioId();
            req.setAttribute("solicitud", so);
        } else {
            res.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        if (!actual.isEncargado() && actual.getId() != duenoId) {
            res.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        Usuario dueno = UsuarioDao.porId(duenoId);
        if (dueno == null) {
            res.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        req.setAttribute("tipoBoleta", tipo);
        req.setAttribute("duenoBoleta", dueno);
        req.setAttribute("emitidoPor", actual);
        req.setAttribute("emitidoEn", java.time.LocalDateTime.now());
        renderSimple(req, res, "boleta");
    }
}
