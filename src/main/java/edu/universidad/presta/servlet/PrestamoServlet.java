package edu.universidad.presta.servlet;

import edu.universidad.presta.dao.DataAccessException;
import edu.universidad.presta.dao.EquipoDao;
import edu.universidad.presta.dao.PrestamoDao;
import edu.universidad.presta.dao.SolicitudDao;
import edu.universidad.presta.dao.UsuarioDao;
import edu.universidad.presta.model.Equipo;
import edu.universidad.presta.model.Prestamo;
import edu.universidad.presta.model.Solicitud;
import edu.universidad.presta.model.Usuario;
import edu.universidad.presta.service.PrestamoService;
import edu.universidad.presta.service.ReglaNegocioException;
import edu.universidad.presta.util.Fechas;
import edu.universidad.presta.util.Json;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/** Módulo de préstamos (prestamos/*.php): /prestamos/registrar, /devolver y /vencidos (solo admin y encargado). */
@WebServlet(urlPatterns = {"/prestamos", "/prestamos/*"})
public class PrestamoServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(PrestamoServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        switch (subRuta(req, "/registrar")) {
            case "/registrar":
                Integer solicitudId = entero(p(req, "solicitud_id"));
                Solicitud solicitudSel = (solicitudId == null) ? null : SolicitudDao.porId(solicitudId);
                formularioRegistro(req, res, new ArrayList<>(), null, "", solicitudSel);
                break;
            case "/devolver":
                formularioDevolucion(req, res, new ArrayList<>());
                break;
            case "/vencidos":
                vencidos(req, res);
                break;
            case "/mis":
                misEquipos(req, res);
                break;
            default:
                redirigir(req, res, "/prestamos/vencidos");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        switch (subRuta(req, "/registrar")) {
            case "/registrar":
                registrar(req, res);
                break;
            case "/devolver":
                devolver(req, res);
                break;
            default:
                redirigir(req, res, "/prestamos/vencidos");
        }
    }

    // ================================================================== registrar

    private void formularioRegistro(HttpServletRequest req, HttpServletResponse res, List<String> errores,
                                    Usuario seleccionado, String busqueda, Solicitud solicitudSel) throws ServletException, IOException {
        LocalDateTime ahora = Fechas.ahora();
        req.setAttribute("equiposDisponibles", EquipoDao.disponibles());
        req.setAttribute("usuariosJson", Json.usuarios(UsuarioDao.activos()));
        req.setAttribute("errores", errores);

        // Pre-llenado a partir de una solicitud (para que el encargado no tenga que buscar).
        Integer equipoSugeridoId = null;
        if (solicitudSel != null) {
            req.setAttribute("solicitudId", solicitudSel.getId());
            if (seleccionado == null) {
                seleccionado = UsuarioDao.porId(solicitudSel.getUsuarioId());
            }
            if (p(req, "fecha_prestamo").isEmpty()) {
                req.setAttribute("fechaPrestamoValor", Fechas.input(solicitudSel.getFechaPrestamo()));
            }
            if (p(req, "fecha_devolucion_esperada").isEmpty()) {
                req.setAttribute("fechaDevolucionValor", Fechas.input(solicitudSel.getFechaDevolucion()));
            }
            // Intentar ubicar un equipo disponible que coincida con lo solicitado.
            String textoEquipo = solicitudSel.getEquipoSolicitado() == null ? "" : solicitudSel.getEquipoSolicitado().toLowerCase();
            for (Equipo eq : EquipoDao.disponibles()) {
                String codigo = eq.getCodigoInventario() == null ? "" : eq.getCodigoInventario().toLowerCase();
                String nombre = eq.getNombre() == null ? "" : eq.getNombre().toLowerCase();
                if (!textoEquipo.isEmpty() && (textoEquipo.contains(codigo) || codigo.contains(textoEquipo)
                        || textoEquipo.contains(nombre) || nombre.contains(textoEquipo))) {
                    equipoSugeridoId = eq.getId();
                    break;
                }
            }
            req.setAttribute("equipoSugeridoId", equipoSugeridoId);
            req.setAttribute("equipoSolicitadoTexto", solicitudSel.getEquipoSolicitado());
        }

        req.setAttribute("usuarioSeleccionado", seleccionado);
        String textoBusqueda = busqueda;
        if (seleccionado != null) {
            textoBusqueda = seleccionado.getNombre()
                    + (seleccionado.getDni() != null && !seleccionado.getDni().isEmpty() ? " (DNI: " + seleccionado.getDni() + ")" : "");
        }
        req.setAttribute("usuarioBusquedaValor", textoBusqueda);
        req.setAttribute("minPrestamo", Fechas.input(Fechas.hoy().atStartOfDay()));
        req.setAttribute("minDevolucion", Fechas.input(ahora));
        if (!p(req, "fecha_prestamo").isEmpty()) {
            req.setAttribute("fechaPrestamoValor", p(req, "fecha_prestamo"));
        } else if (req.getAttribute("fechaPrestamoValor") == null) {
            req.setAttribute("fechaPrestamoValor", Fechas.input(ahora));
        }
        if (esModal(req)) {
            renderFragmento(req, res, "prestamos/_registrar");
            return;
        }
        render(req, res, "prestamos/registrar", "Registrar Préstamo", "prestamos");
    }

    private void registrar(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        List<String> errores = new ArrayList<>();
        String busqueda = p(req, "usuario_busqueda");
        Integer usuarioId = entero(p(req, "usuario_id"));
        Integer equipoId = entero(p(req, "equipo_id"));
        String observaciones = p(req, "observaciones");

        // Si el encargado escribió algo (DNI, celular, nombre o email) sin elegir de la lista, se busca directamente
        Usuario seleccionado = null;
        if (usuarioId == null || usuarioId == 0) {
            if (!busqueda.isEmpty()) {
                seleccionado = UsuarioDao.buscarActivo(busqueda);
            }
        } else {
            seleccionado = UsuarioDao.porId(usuarioId);
            if (seleccionado != null && !seleccionado.isActivo()) {
                seleccionado = null;
            }
        }
        if (seleccionado == null) {
            errores.add("Debe buscar y seleccionar un usuario válido por DNI, nombres, apellidos o celular.");
        }
        if (equipoId == null) {
            errores.add("Seleccione un equipo.");
        }

        LocalDateTime ahora = Fechas.ahora();
        LocalDateTime prestamo = p(req, "fecha_prestamo").isEmpty() ? ahora : Fechas.parse(p(req, "fecha_prestamo"));
        LocalDateTime devolucion = Fechas.parse(p(req, "fecha_devolucion_esperada"));

        // "Hoy" es válido a cualquier hora: solo se rechazan días anteriores a hoy.
        if (prestamo == null) {
            errores.add("La fecha del préstamo no es válida.");
        } else if (prestamo.isBefore(Fechas.hoy().atStartOfDay())) {
            errores.add("La fecha del préstamo no puede ser anterior a hoy.");
        }
        if (devolucion == null) {
            errores.add("La fecha de devolución esperada es obligatoria.");
        } else if (devolucion.isBefore(ahora)) {
            errores.add("La devolución esperada debe ser posterior a la hora actual.");
        } else if (prestamo != null && !devolucion.isAfter(prestamo)) {
            errores.add("La fecha de devolución debe ser posterior a la fecha de préstamo.");
        }

        if (errores.isEmpty()) {
            try {
                PrestamoService.registrar(seleccionado.getId(), equipoId, prestamo, devolucion, observaciones);
                Integer solicitudIdReg = entero(p(req, "solicitud_id"));
                if (solicitudIdReg != null && solicitudIdReg > 0) {
                    SolicitudDao.eliminar(solicitudIdReg);
                }
                flash(req, "Préstamo registrado exitosamente.", "success");
                if (esAjax(req)) {
                    responderJson(res, true, "Préstamo registrado exitosamente.", new ArrayList<>());
                    return;
                }
                redirigir(req, res, "/prestamos/vencidos");
                return;
            } catch (ReglaNegocioException e) {
                errores.add(e.getMessage());
            } catch (DataAccessException e) {
                LOG.log(Level.WARNING, "Error al registrar el préstamo", e);
                errores.add("Error al registrar el préstamo. Verifique que el equipo no tenga otro préstamo activo.");
            }
        }
        if (esAjax(req)) {
            responderJson(res, false, "No se pudo registrar el préstamo.", errores);
            return;
        }
        formularioRegistro(req, res, errores, seleccionado, busqueda, null);
    }

    // ================================================================== devolver

    private void formularioDevolucion(HttpServletRequest req, HttpServletResponse res, List<String> errores)
            throws ServletException, IOException {
        List<Prestamo> activos = PrestamoDao.activos();
        Usuario u = usuario(req);
        if (u != null && !u.isEncargado()) {
            List<Prestamo> propios = new ArrayList<>();
            for (Prestamo pr : activos) {
                if (pr.getUsuarioId() == u.getId()) {
                    propios.add(pr);
                }
            }
            activos = propios;
        }
        req.setAttribute("prestamosActivos", activos);
        req.setAttribute("errores", errores);
        req.setAttribute("prestamoSel", p(req, "prestamo_id"));
        req.setAttribute("fechaRealValor", Fechas.input(Fechas.ahora()));
        if (esModal(req)) {
            renderFragmento(req, res, "prestamos/_devolver");
            return;
        }
        render(req, res, "prestamos/devolver", "Devolver Equipo", "prestamos");
    }

    private void devolver(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        List<String> errores = new ArrayList<>();
        Integer prestamoId = entero(p(req, "prestamo_id"));
        String estadoEquipo = "mantenimiento".equals(p(req, "estado_equipo")) ? "mantenimiento" : "disponible";
        String observaciones = p(req, "observaciones");
        LocalDateTime real = p(req, "fecha_devolucion_real").isEmpty() ? Fechas.ahora() : Fechas.parse(p(req, "fecha_devolucion_real"));

        if (prestamoId == null) {
            errores.add("Seleccione un préstamo activo.");
        }
        if (real == null) {
            errores.add("La fecha de devolución real no es válida.");
        }
        if (errores.isEmpty()) {
            try {
                PrestamoService.devolver(prestamoId, real, estadoEquipo, observaciones);
                // Marcar la solicitud relacionada (si existe) como devuelta.
                Prestamo pr = PrestamoDao.porId(prestamoId);
                if (pr != null) {
                    for (Solicitud s : SolicitudDao.deUsuario(pr.getUsuarioId())) {
                        if ("aprobada".equals(s.getEstado()) || "prestado".equals(s.getEstado())) {
                            String eqSol = s.getEquipoSolicitado() == null ? "" : s.getEquipoSolicitado().toLowerCase();
                            String eqNom = pr.getEquipoNombre() == null ? "" : pr.getEquipoNombre().toLowerCase();
                            String eqCod = pr.getCodigoInventario() == null ? "" : pr.getCodigoInventario().toLowerCase();
                            if ((!eqNom.isEmpty() && eqSol.contains(eqNom)) || (!eqCod.isEmpty() && eqSol.contains(eqCod))) {
                                SolicitudDao.setEstado(s.getId(), "devuelta");
                            }
                        }
                    }
                }
                flash(req, "Equipo devuelto exitosamente.", "success");
                if (esAjax(req)) {
                    responderJson(res, true, "Equipo devuelto exitosamente.", new ArrayList<>());
                    return;
                }
                redirigir(req, res, "/prestamos/vencidos");
                return;
            } catch (ReglaNegocioException e) {
                errores.add(e.getMessage());
            } catch (DataAccessException e) {
                LOG.log(Level.WARNING, "Error al registrar la devolución", e);
                errores.add("Error al registrar la devolución. Inténtelo de nuevo.");
            }
        }
        if (esAjax(req)) {
            responderJson(res, false, "No se pudo registrar la devolución.", errores);
            return;
        }
        formularioDevolucion(req, res, errores);
    }

    // ================================================================== mis equipos (usuario)

    private void misEquipos(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        Usuario u = usuario(req);
        List<Prestamo> prestamos = PrestamoDao.ultimos(u.getId(), 100);
        req.setAttribute("prestamos", prestamos);
        render(req, res, "prestamos/mis", "Mis Equipos", "mis-equipos");
    }

    // ================================================================== activos y vencidos

    private void vencidos(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        List<Prestamo> prestamos = PrestamoDao.activosYVencidos();
        long vencidos = prestamos.stream().filter(Prestamo::isVencido).count();
        req.setAttribute("prestamos", prestamos);
        req.setAttribute("totalVencidos", vencidos);
        render(req, res, "prestamos/vencidos", "Préstamos Activos y Vencidos", "vencidos");
    }
}
