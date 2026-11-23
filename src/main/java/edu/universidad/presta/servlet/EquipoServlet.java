package edu.universidad.presta.servlet;

import edu.universidad.presta.dao.CategoriaDao;
import edu.universidad.presta.dao.DataAccessException;
import edu.universidad.presta.dao.EquipoDao;
import edu.universidad.presta.dao.HistorialDao;
import edu.universidad.presta.dao.PrestamoDao;
import edu.universidad.presta.dao.SolicitudDao;
import edu.universidad.presta.model.Equipo;
import edu.universidad.presta.model.Solicitud;
import edu.universidad.presta.service.EquipoService;
import edu.universidad.presta.service.ReglaNegocioException;
import edu.universidad.presta.util.Fechas;
import edu.universidad.presta.util.Oficinas;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Módulo de equipos (equipos/*.php): /equipos/listar, /crear, /editar y /eliminar.
 * El listado también atiende las solicitudes de préstamo de los usuarios.
 */
@WebServlet(urlPatterns = {"/equipos", "/equipos/*"})
public class EquipoServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(EquipoServlet.class.getName());
    private static final Set<String> ESTADOS_NUEVO = new HashSet<>(Arrays.asList("disponible", "mantenimiento", "dado_de_baja"));
    private static final Set<String> ESTADOS_EDICION = new HashSet<>(Arrays.asList("disponible", "prestado", "mantenimiento", "dado_de_baja"));

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        switch (subRuta(req, "/listar")) {
            case "/listar":
                listar(req, res);
                break;
            case "/bandeja":
                bandeja(req, res);
                break;
            case "/crear":
                formularioNuevo(req, res, new ArrayList<>());
                break;
            case "/editar":
                formularioEdicion(req, res);
                break;
            case "/solicitud":
                formularioSolicitud(req, res);
                break;
            default:
                redirigir(req, res, "/equipos/listar");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        String sub = subRuta(req, "/listar");
        if ("/bandeja".equals(sub)) {
            accionesDelListado(req, res);
            return;
        }
        switch (sub) {
            case "/listar":
                accionesDelListado(req, res);
                break;
            case "/crear":
                crear(req, res);
                break;
            case "/editar":
                editar(req, res);
                break;
            case "/eliminar":
                eliminar(req, res);
                break;
            default:
                redirigir(req, res, "/equipos/listar");
        }
    }

    // ================================================================== listado

    private void listar(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        String busqueda = p(req, "busqueda");
        String categoria = p(req, "categoria_id");
        String oficina = p(req, "oficina");
        String estado = p(req, "estado");
        String tab = p(req, "tab").isEmpty() ? "inventario" : p(req, "tab");
        if (!Oficinas.ESTADOS_EQUIPO.containsKey(estado)) {
            estado = "";
        }

        Map<String, Integer> conteo = EquipoDao.conteoPorEstado();
        int total = 0;
        for (int n : conteo.values()) {
            total += n;
        }

        // La búsqueda, la categoría y el estado se aplican en el navegador (filtrado en tiempo real);
        // los parámetros de la URL solo fijan el filtro inicial.
        req.setAttribute("categorias", CategoriaDao.listarConConteo());
        req.setAttribute("conteoEstados", conteo);
        req.setAttribute("totalEquiposGeneral", total);
        req.setAttribute("infoEstados", Oficinas.ESTADOS_EQUIPO);
        req.setAttribute("iconosCat", Oficinas.ICONOS_CATEGORIA);
        req.setAttribute("gruposOficinas", Oficinas.GRUPOS);
        req.setAttribute("busqueda", busqueda);
        req.setAttribute("categoriaSel", categoria);
        req.setAttribute("estadoSel", estado);
        req.setAttribute("tabActiva", tab);
        req.setAttribute("ahoraInput", Fechas.input(Fechas.ahora()));

        if (esEncargado(req)) {
            List<Solicitud> solicitudes = SolicitudDao.todas();
            long pendientes = solicitudes.stream().filter(s -> "pendiente".equals(s.getEstado())).count();
            req.setAttribute("equipos", EquipoDao.filtrar("", null, "", ""));
            req.setAttribute("solicitudes", solicitudes);
            req.setAttribute("solicitudesPendientes", pendientes);
            req.setAttribute("prestamosTodos", PrestamoDao.todos());

            // Solicitudes que se pueden registrar como préstamo (equipo disponible o pendiente por registrar).
            Set<Integer> registrables = new HashSet<>();
            List<Equipo> disponibles = EquipoDao.disponibles();
            for (Solicitud s : solicitudes) {
                if ("pendiente".equals(s.getEstado())) {
                    registrables.add(s.getId());
                } else if ("aprobada".equals(s.getEstado())) {
                    String texto = s.getEquipoSolicitado() == null ? "" : s.getEquipoSolicitado().toLowerCase();
                    for (Equipo eq : disponibles) {
                        String cod = eq.getCodigoInventario() == null ? "" : eq.getCodigoInventario().toLowerCase();
                        String nom = eq.getNombre() == null ? "" : eq.getNombre().toLowerCase();
                        if (!texto.isEmpty() && (texto.contains(cod) || cod.contains(texto)
                                || texto.contains(nom) || nom.contains(texto))) {
                            registrables.add(s.getId());
                            break;
                        }
                    }
                }
            }
            req.setAttribute("solicitudesRegistrables", registrables);
        } else {
            req.setAttribute("misSolicitudes", SolicitudDao.deUsuario(usuario(req).getId()));
            req.setAttribute("misPrestamos", PrestamoDao.ultimos(usuario(req).getId(), 100));
            req.setAttribute("equiposCatalogo", EquipoDao.catalogo());
            req.setAttribute("categoriasCatalogo", CategoriaDao.resumenCatalogo());
            req.setAttribute("equiposDisponibles", EquipoDao.disponibles());
        }
        render(req, res, "equipos/listar", "Gestión de Equipos", "equipos");
    }

    private void bandeja(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        List<Solicitud> solicitudes = SolicitudDao.todas();
        long pendientes = solicitudes.stream().filter(s -> "pendiente".equals(s.getEstado())).count();
        Set<Integer> registrables = new HashSet<>();
        List<Equipo> disponibles = EquipoDao.disponibles();
        for (Solicitud s : solicitudes) {
            if ("pendiente".equals(s.getEstado())) {
                registrables.add(s.getId());
            } else if ("aprobada".equals(s.getEstado())) {
                String texto = s.getEquipoSolicitado() == null ? "" : s.getEquipoSolicitado().toLowerCase();
                for (Equipo eq : disponibles) {
                    String cod = eq.getCodigoInventario() == null ? "" : eq.getCodigoInventario().toLowerCase();
                    String nom = eq.getNombre() == null ? "" : eq.getNombre().toLowerCase();
                    if (!texto.isEmpty() && (texto.contains(cod) || cod.contains(texto)
                            || texto.contains(nom) || nom.contains(texto))) {
                        registrables.add(s.getId());
                        break;
                    }
                }
            }
        }
        req.setAttribute("solicitudes", solicitudes);
        req.setAttribute("solicitudesPendientes", pendientes);
        req.setAttribute("solicitudesRegistrables", registrables);
        req.setAttribute("pageTitle", "Bandeja de Solicitudes");
        req.setAttribute("nav", "equipos");
        req.setAttribute("tabActiva", "solicitudes");
        render(req, res, "equipos/bandeja", "Bandeja de Solicitudes", "equipos");
    }

    private boolean esBandeja(HttpServletRequest req) {
        String uri = req.getRequestURI();
        return uri != null && uri.contains("bandeja");
    }

    private void accionesDelListado(HttpServletRequest req, HttpServletResponse res) throws IOException {
        String accion = p(req, "accion");
        if (!esEncargado(req)) {
            if ("solicitar".equals(accion)) {
                solicitar(req, res);
                return;
            }
        } else {
            switch (accion) {
                case "aprobar_solicitud":
                case "rechazar_solicitud":
                    resolverSolicitud(req, res, accion);
                    return;
                case "eliminar_solicitud":
                    eliminarSolicitud(req, res);
                    return;
                case "limpiar_aprobadas":
                    SolicitudDao.eliminarPorEstado("aprobada");
                    flash(req, "Solicitudes aprobadas eliminadas.", "success");
                    redirigir(req, res, esBandeja(req) ? "/equipos/bandeja" : "/equipos/listar?tab=solicitudes");
                    return;
                default:
                    break;
            }
        }
        redirigir(req, res, "/equipos/listar");
    }

    /** Un usuario envía una solicitud de equipo al panel de administración. */
    private void solicitar(HttpServletRequest req, HttpServletResponse res) throws IOException {
        String equipo = p(req, "busqueda");
        String fechaPrestamo = p(req, "fecha_prestamo");
        String fechaDevolucion = p(req, "fecha_devolucion");
        String oficina = p(req, "oficina");
        String observaciones = p(req, "observaciones");

        List<String> errores = new ArrayList<>();
        if (equipo.isEmpty() || fechaPrestamo.isEmpty() || fechaDevolucion.isEmpty() || oficina.isEmpty()) {
            errores.add("Por favor, complete todos los campos obligatorios de la solicitud.");
        } else {
            LocalDateTime fp = Fechas.parse(fechaPrestamo);
            LocalDateTime fd = Fechas.parse(fechaDevolucion);
            if (fp == null || fd == null) {
                errores.add("Las fechas de la solicitud no son válidas.");
            } else if (fd.isBefore(fp)) {
                errores.add("La fecha de devolución no puede ser anterior a la fecha de préstamo.");
            } else {
                int uid = usuario(req).getId();
                // Validar si el usuario ya tiene este equipo en préstamo activo o solicitud pendiente
                if (SolicitudDao.tieneSolicitudActivaDelEquipo(uid, equipo)) {
                    errores.add("Ya tienes una solicitud pendiente o aprobada para este equipo. No puedes solicitar el mismo equipo nuevamente.");
                } else {
                    // Validar si el equipo físico está marcado como no disponible (prestado, mantenimiento o baja)
                    edu.universidad.presta.model.Equipo eqFisico = EquipoDao.porCodigoOParte(equipo);
                    if (eqFisico != null && !"disponible".equalsIgnoreCase(eqFisico.getEstado())) {
                        errores.add("El equipo '" + eqFisico.getNombre() + "' (" + eqFisico.getCodigoInventario() + ") actualmente se encuentra en estado '" + eqFisico.getEstado() + "' y ya está en uso. Por favor elija otro equipo.");
                    }
                }

                if (errores.isEmpty()) {
                    SolicitudDao.crear(uid, equipo, fp, fd, oficina, observaciones);
                    flash(req, "Solicitud enviada exitosamente al panel de administración.", "success");
                    if (esAjax(req)) {
                        responderJson(res, true, "Solicitud enviada exitosamente al panel de administración.", new ArrayList<>());
                        return;
                    }
                    redirigir(req, res, "/equipos/listar?tab=mis_solicitudes");
                    return;
                }
            }
        }
        if (esAjax(req)) {
            responderJson(res, false, "No se pudo enviar la solicitud.", errores);
            return;
        }
        flash(req, errores.get(0), "danger");
        redirigir(req, res, "/equipos/listar?tab=mis_solicitudes");
    }

    /** Fragmento del formulario de solicitud de equipo (se usa dentro del modal del panel). */
    private void formularioSolicitud(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        req.setAttribute("gruposOficinas", Oficinas.gruposDinamicos());
        req.setAttribute("equiposDisponibles", EquipoDao.disponibles());
        req.setAttribute("ahoraInput", Fechas.input(Fechas.ahora()));
        req.setAttribute("minPrestamo", Fechas.input(Fechas.hoy().atStartOfDay()));
        req.setAttribute("busqueda", p(req, "busqueda"));
        edu.universidad.presta.model.Usuario u = usuario(req);
        req.setAttribute("usuarioOficina", u != null && u.getOficina() != null ? u.getOficina() : "");
        if (esModal(req)) {
            renderFragmento(req, res, "equipos/_solicitud");
            return;
        }
        redirigir(req, res, "/equipos/listar");
    }

    private void resolverSolicitud(HttpServletRequest req, HttpServletResponse res, String accion) throws IOException {
        Integer id = entero(p(req, "solicitud_id"));
        if (id != null && id > 0) {
            if ("aprobar_solicitud".equals(accion)) {
                SolicitudDao.setEstado(id, "aprobada");
                flash(req, "Solicitud aprobada correctamente.", "success");
            } else {
                String motivo = p(req, "motivo_rechazo");
                if (motivo.isEmpty()) {
                    motivo = p(req, "motivo");
                }
                SolicitudDao.rechazar(id, motivo);
                flash(req, "Solicitud rechazada correctamente.", "warning");
            }
        }
        redirigir(req, res, esBandeja(req) ? "/equipos/bandeja" : "/equipos/listar?tab=solicitudes");
    }

    private void eliminarSolicitud(HttpServletRequest req, HttpServletResponse res) throws IOException {
        Integer id = entero(p(req, "solicitud_id"));
        if (id != null && id > 0) {
            SolicitudDao.eliminar(id);
            flash(req, "Solicitud eliminada correctamente.", "success");
        } else {
            flash(req, "No se pudo eliminar la solicitud.", "danger");
        }
        redirigir(req, res, esBandeja(req) ? "/equipos/bandeja" : "/equipos/listar?tab=solicitudes");
    }

    // ================================================================== crear

    private void formularioNuevo(HttpServletRequest req, HttpServletResponse res, List<String> errores)
            throws ServletException, IOException {
        req.setAttribute("esEdicion", false);
        req.setAttribute("categorias", CategoriaDao.listar());
        req.setAttribute("errores", errores);
        if (esModal(req)) {
            renderFragmento(req, res, "equipos/_form");
            return;
        }
        render(req, res, "equipos/form", "Nuevo Equipo", "equipos");
    }

    private void crear(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        String codigo = p(req, "codigo_inventario");
        String nombre = p(req, "nombre");
        String descripcion = p(req, "descripcion");
        String ubicacion = p(req, "ubicacion");
        String estado = ESTADOS_NUEVO.contains(p(req, "estado")) ? p(req, "estado") : "disponible";
        Integer categoriaId = entero(p(req, "categoria_id"));

        List<String> errores = new ArrayList<>();
        if (codigo.isEmpty()) {
            errores.add("El código de inventario es obligatorio.");
        }
        if (nombre.isEmpty()) {
            errores.add("El nombre es obligatorio.");
        }
        if (categoriaId == null) {
            errores.add("Debe seleccionar una categoría.");
        }
        try {
            if (errores.isEmpty() && EquipoDao.existeCodigo(codigo, 0)) {
                errores.add("El código de inventario ya existe.");
            }
            if (errores.isEmpty()) {
                int id = EquipoDao.crear(codigo, nombre, descripcion, categoriaId, ubicacion, estado);
                HistorialDao.registrar(id, usuario(req).getId(), "alta", "Equipo creado: " + nombre);
                flash(req, "Equipo creado exitosamente.", "success");
                if (esAjax(req)) {
                    responderJson(res, true, "Equipo creado exitosamente.", new ArrayList<>());
                    return;
                }
                redirigir(req, res, "/equipos/listar");
                return;
            }
        } catch (DataAccessException e) {
            LOG.log(Level.WARNING, "Error al crear el equipo", e);
            errores.add("Error al crear el equipo. Inténtelo de nuevo.");
        }
        if (esAjax(req)) {
            responderJson(res, false, "No se pudo crear el equipo.", errores);
            return;
        }
        formularioNuevo(req, res, errores);
    }

    // ================================================================== editar

    private void formularioEdicion(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        Equipo equipo = buscar(req);
        if (equipo == null) {
            flash(req, "Equipo no encontrado.", "danger");
            redirigir(req, res, "/equipos/listar");
            return;
        }
        mostrarEdicion(req, res, equipo, new ArrayList<>());
    }

    private void mostrarEdicion(HttpServletRequest req, HttpServletResponse res, Equipo equipo, List<String> errores)
            throws ServletException, IOException {
        req.setAttribute("esEdicion", true);
        req.setAttribute("equipo", equipo);
        req.setAttribute("categorias", CategoriaDao.listar());
        req.setAttribute("errores", errores);
        if (esModal(req)) {
            renderFragmento(req, res, "equipos/_form");
            return;
        }
        render(req, res, "equipos/form", "Editar Equipo", "equipos");
    }

    private Equipo buscar(HttpServletRequest req) {
        Integer id = entero(p(req, "id"));
        return id == null ? null : EquipoDao.porId(id);
    }

    private void editar(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        Equipo equipo = buscar(req);
        if (equipo == null) {
            flash(req, "Equipo no encontrado.", "danger");
            redirigir(req, res, "/equipos/listar");
            return;
        }
        String codigo = p(req, "codigo_inventario");
        String nombre = p(req, "nombre");
        String descripcion = p(req, "descripcion");
        String ubicacion = p(req, "ubicacion");
        String estado = ESTADOS_EDICION.contains(p(req, "estado")) ? p(req, "estado") : "disponible";
        Integer categoriaId = entero(p(req, "categoria_id"));

        List<String> errores = new ArrayList<>();
        if (codigo.isEmpty()) {
            errores.add("El código de inventario es obligatorio.");
        }
        if (nombre.isEmpty()) {
            errores.add("El nombre es obligatorio.");
        }
        if (categoriaId == null) {
            errores.add("Debe seleccionar una categoría.");
        }
        try {
            if (errores.isEmpty() && EquipoDao.existeCodigo(codigo, equipo.getId())) {
                errores.add("El código de inventario ya existe.");
            }
            if (errores.isEmpty()) {
                EquipoDao.actualizar(equipo.getId(), codigo, nombre, descripcion, categoriaId, ubicacion, estado);
                HistorialDao.registrar(equipo.getId(), usuario(req).getId(), "edicion", "Equipo editado: " + nombre);
                flash(req, "Equipo actualizado exitosamente.", "success");
                if (esAjax(req)) {
                    responderJson(res, true, "Equipo actualizado exitosamente.", new ArrayList<>());
                    return;
                }
                redirigir(req, res, "/equipos/listar");
                return;
            }
        } catch (DataAccessException e) {
            LOG.log(Level.WARNING, "Error al actualizar el equipo", e);
            errores.add("Error al actualizar el equipo. Inténtelo de nuevo.");
        }
        if (esAjax(req)) {
            responderJson(res, false, "No se pudo actualizar el equipo.", errores);
            return;
        }
        mostrarEdicion(req, res, equipo, errores);
    }

    // ================================================================== eliminar

    private void eliminar(HttpServletRequest req, HttpServletResponse res) throws IOException {
        Integer id = entero(p(req, "id"));
        try {
            String mensaje = EquipoService.eliminarODarDeBaja(id == null ? 0 : id, usuario(req).getId());
            flash(req, mensaje, "success");
        } catch (ReglaNegocioException e) {
            flash(req, e.getMessage(), "danger");
        } catch (DataAccessException e) {
            LOG.log(Level.WARNING, "Error al eliminar equipo", e);
            flash(req, "No se pudo completar la operación. Inténtelo de nuevo o contacte al administrador.", "danger");
        }
        redirigir(req, res, "/equipos/listar");
    }
}
