package edu.universidad.presta.servlet;

import edu.universidad.presta.dao.DataAccessException;
import edu.universidad.presta.dao.UsuarioDao;
import edu.universidad.presta.model.Usuario;
import edu.universidad.presta.util.DniLookup;
import edu.universidad.presta.util.Json;
import edu.universidad.presta.util.Seguridad;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Pattern;

/** Módulo de usuarios (usuarios/*.php), solo administradores: /usuarios/listar, /crear, /editar y /cambiar-estado. */
@WebServlet(urlPatterns = {"/usuarios", "/usuarios/*"})
public class UsuarioServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(UsuarioServlet.class.getName());
    private static final Set<String> ROLES = new HashSet<>(Arrays.asList("usuario", "encargado", "admin"));
    private static final Pattern DNI = Pattern.compile("^[0-9]{8}$");
    private static final Pattern CELULAR = Pattern.compile("^9[0-9]{8}$");
    private static final Pattern EMAIL = Pattern.compile("^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*\\.[A-Za-z]{2,}$");

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        switch (subRuta(req, "/listar")) {
            case "/listar":
                listar(req, res);
                break;
            case "/crear":
                formulario(req, res, false, null, formVacio(), new ArrayList<>());
                break;
            case "/dni-lookup":
                consultarDni(req, res);
                break;
            case "/editar":
                Usuario u = buscar(req);
                if (u == null) {
                    flash(req, "Usuario no encontrado.", "danger");
                    redirigir(req, res, "/usuarios/listar");
                } else {
                    formulario(req, res, true, u, formDe(u), new ArrayList<>());
                }
                break;
            default:
                redirigir(req, res, "/usuarios/listar");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        switch (subRuta(req, "/listar")) {
            case "/crear":
                crear(req, res);
                break;
            case "/editar":
                editar(req, res);
                break;
            case "/cambiar-estado":
                cambiarEstado(req, res);
                break;
            case "/eliminar":
                eliminar(req, res);
                break;
            default:
                redirigir(req, res, "/usuarios/listar");
        }
    }

    // ================================================================== consulta de DNI (dni_lookup.php)

    /** Devuelve JSON con los nombres asociados a un DNI; lo usa el botón "Buscar" de Nuevo Usuario. */
    private void consultarDni(HttpServletRequest req, HttpServletResponse res) throws IOException {
        res.setContentType("application/json;charset=UTF-8");
        String dni = p(req, "dni");
        String json;
        if (!DNI.matcher(dni).matches()) {
            res.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            json = "{\"success\":false,\"error\":" + Json.texto("El DNI debe tener exactamente 8 dígitos numéricos.") + "}";
        } else {
            DniLookup.Persona persona = DniLookup.buscar(dni);
            if (persona == null) {
                res.setStatus(HttpServletResponse.SC_NOT_FOUND);
                json = "{\"success\":false,\"error\":" + Json.texto("No se encontraron datos para el DNI consultado.") + "}";
            } else {
                json = "{\"success\":true,\"dni\":" + Json.texto(dni)
                        + ",\"nombre_completo\":" + Json.texto(persona.nombreCompleto)
                        + ",\"nombres\":" + Json.texto(persona.nombres)
                        + ",\"apellido_paterno\":" + Json.texto(persona.apellidoPaterno)
                        + ",\"apellido_materno\":" + Json.texto(persona.apellidoMaterno) + "}";
            }
        }
        res.getWriter().write(json);
    }

    // ================================================================== listado

    private void listar(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        String busqueda = p(req, "busqueda");
        String rol = ROLES.contains(p(req, "rol")) ? p(req, "rol") : "";
        req.setAttribute("usuarios", UsuarioDao.listar(busqueda, rol));
        req.setAttribute("busqueda", busqueda);
        req.setAttribute("rolSel", rol);
        render(req, res, "usuarios/listar", "Gestión de Usuarios", "usuarios");
    }

    // ================================================================== formulario (crear / editar)

    private void formulario(HttpServletRequest req, HttpServletResponse res, boolean esEdicion, Usuario usuario,
                            Map<String, String> form, List<String> errores) throws ServletException, IOException {
        req.setAttribute("esEdicion", esEdicion);
        req.setAttribute("usuario", usuario);
        req.setAttribute("form", form);
        req.setAttribute("errores", errores);
        if (esModal(req)) {
            renderFragmento(req, res, "usuarios/_form");
            return;
        }
        render(req, res, "usuarios/form", esEdicion ? "Editar Usuario" : "Nuevo Usuario", "usuarios");
    }

    private Map<String, String> formVacio() {
        Map<String, String> f = new LinkedHashMap<>();
        f.put("nombre", "");
        f.put("dni", "");
        f.put("celular", "");
        f.put("email", "");
        f.put("rol", "usuario");
        return f;
    }

    private Map<String, String> formDe(Usuario u) {
        Map<String, String> f = new LinkedHashMap<>();
        f.put("nombre", u.getNombre());
        f.put("dni", u.getDni() == null ? "" : u.getDni());
        f.put("celular", u.getCelular() == null ? "" : u.getCelular());
        f.put("email", u.getEmail());
        f.put("rol", u.getRol());
        return f;
    }

    private Map<String, String> formDePost(HttpServletRequest req) {
        Map<String, String> f = new LinkedHashMap<>();
        f.put("nombre", p(req, "nombre"));
        f.put("dni", p(req, "dni"));
        f.put("celular", p(req, "celular"));
        f.put("email", p(req, "email"));
        f.put("rol", ROLES.contains(p(req, "rol")) ? p(req, "rol") : "usuario");
        return f;
    }

    /** Validaciones comunes a crear y editar. */
    private void validarDatos(Map<String, String> f, List<String> errores) {
        if (f.get("nombre").isEmpty()) {
            errores.add("El nombre es obligatorio.");
        }
        // DNI peruano: 8 dígitos
        if (f.get("dni").isEmpty()) {
            errores.add("El DNI es obligatorio.");
        } else if (!DNI.matcher(f.get("dni")).matches()) {
            errores.add("El DNI debe tener exactamente 8 dígitos numéricos.");
        }
        // Celular peruano: 9 dígitos que inician con 9
        if (f.get("celular").isEmpty()) {
            errores.add("El número de celular es obligatorio.");
        } else if (!CELULAR.matcher(f.get("celular")).matches()) {
            errores.add("El número de celular debe ser válido para Perú (9 dígitos numéricos e iniciar con 9).");
        }
        if (f.get("email").isEmpty() || !EMAIL.matcher(f.get("email")).matches()) {
            errores.add("Ingrese un email válido.");
        }
    }

    // ================================================================== crear

    private void crear(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        Map<String, String> f = formDePost(req);
        String clave = raw(req, "password");
        String nombreDni = p(req, "nombre_dni");
        List<String> errores = new ArrayList<>();

        validarDatos(f, errores);
        if (!nombreDni.isEmpty() && !nombreDni.equals(f.get("nombre"))) {
            errores.add("El nombre debe corresponder al DNI consultado y no puede modificarse.");
        }
        if (clave.length() < 8) {
            errores.add("La contraseña debe tener al menos 8 caracteres.");
        }
        if (!clave.equals(raw(req, "password_confirm"))) {
            errores.add("Las contraseñas no coinciden.");
        }
        try {
            if (errores.isEmpty() && UsuarioDao.existeDni(f.get("dni"), 0)) {
                errores.add("El DNI ingresado ya se encuentra registrado por otro usuario.");
            }
            if (errores.isEmpty() && UsuarioDao.existeEmail(f.get("email"), 0)) {
                errores.add("El email ya está registrado.");
            }
            if (errores.isEmpty()) {
                UsuarioDao.crear(f.get("nombre"), f.get("dni"), f.get("celular"), f.get("email"), Seguridad.hash(clave), f.get("rol"));
                flash(req, "Usuario creado exitosamente.", "success");
                if (esAjax(req)) {
                    responderJson(res, true, "Usuario creado exitosamente.", new ArrayList<>());
                    return;
                }
                redirigir(req, res, "/usuarios/listar");
                return;
            }
        } catch (DataAccessException e) {
            LOG.log(Level.WARNING, "Error al crear el usuario", e);
            errores.add("Error al crear el usuario. Inténtelo de nuevo.");
        }
        if (esAjax(req)) {
            responderJson(res, false, "No se pudo crear el usuario.", errores);
            return;
        }
        formulario(req, res, false, null, f, errores);
    }

    // ================================================================== editar

    private Usuario buscar(HttpServletRequest req) {
        Integer id = entero(p(req, "id"));
        return id == null ? null : UsuarioDao.porId(id);
    }

    private void editar(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        Usuario usuario = buscar(req);
        if (usuario == null) {
            flash(req, "Usuario no encontrado.", "danger");
            redirigir(req, res, "/usuarios/listar");
            return;
        }
        Map<String, String> f = formDePost(req);
        String nuevaClave = raw(req, "nuevo_password");
        List<String> errores = new ArrayList<>();

        validarDatos(f, errores);
        try {
            if (errores.isEmpty() && UsuarioDao.existeDni(f.get("dni"), usuario.getId())) {
                errores.add("El DNI ya está registrado por otro usuario.");
            }
            if (errores.isEmpty() && UsuarioDao.existeEmail(f.get("email"), usuario.getId())) {
                errores.add("El email ya está registrado por otro usuario.");
            }
            if (errores.isEmpty() && !nuevaClave.isEmpty() && nuevaClave.length() < 8) {
                errores.add("La nueva contraseña debe tener al menos 8 caracteres.");
            }
            if (errores.isEmpty()) {
                String hash = nuevaClave.isEmpty() ? null : Seguridad.hash(nuevaClave);
                UsuarioDao.actualizar(usuario.getId(), f.get("nombre"), f.get("dni"), f.get("celular"), f.get("email"), f.get("rol"), hash);
                flash(req, "Usuario actualizado exitosamente.", "success");
                if (esAjax(req)) {
                    responderJson(res, true, "Usuario actualizado exitosamente.", new ArrayList<>());
                    return;
                }
                redirigir(req, res, "/usuarios/listar");
                return;
            }
        } catch (DataAccessException e) {
            LOG.log(Level.WARNING, "Error al actualizar el usuario", e);
            errores.add("Error al actualizar el usuario. Inténtelo de nuevo.");
        }
        if (esAjax(req)) {
            responderJson(res, false, "No se pudo actualizar el usuario.", errores);
            return;
        }
        formulario(req, res, true, usuario, f, errores);
    }

    // ================================================================== activar / desactivar

    private void cambiarEstado(HttpServletRequest req, HttpServletResponse res) throws IOException {
        Integer id = entero(p(req, "id"));
        if (id != null && id == usuario(req).getId()) {
            // Un administrador no puede desactivarse a sí mismo
            flash(req, "No puede cambiar el estado de su propia cuenta.", "danger");
        } else {
            try {
                Usuario u = id == null ? null : UsuarioDao.porId(id);
                if (u != null) {
                    int nuevo = u.isActivo() ? 0 : 1;
                    UsuarioDao.setEstado(u.getId(), nuevo);
                    flash(req, nuevo == 1 ? "Usuario activado exitosamente." : "Usuario desactivado exitosamente.", "success");
                }
            } catch (DataAccessException e) {
                LOG.log(Level.WARNING, "Error al cambiar el estado del usuario", e);
                flash(req, "Error al cambiar el estado. Inténtelo de nuevo.", "danger");
            }
        }
        redirigir(req, res, "/usuarios/listar");
    }

    // ================================================================== eliminar usuario
    private void eliminar(HttpServletRequest req, HttpServletResponse res) throws IOException {
        Integer id = entero(p(req, "id"));
        if (id == null) {
            flash(req, "Usuario inválido.", "danger");
            redirigir(req, res, "/usuarios/listar");
            return;
        }

        Usuario usuarioSesion = usuario(req);
        if (id == usuarioSesion.getId()) {
            flash(req, "No puedes eliminar tu propia cuenta de usuario.", "danger");
            redirigir(req, res, "/usuarios/listar");
            return;
        }

        Usuario objetivo = UsuarioDao.porId(id);
        if (objetivo == null) {
            flash(req, "El usuario a eliminar no existe.", "danger");
            redirigir(req, res, "/usuarios/listar");
            return;
        }

        try {
            UsuarioDao.eliminar(id);
            flash(req, "El usuario '" + objetivo.getNombre() + "' fue eliminado correctamente.", "success");
        } catch (DataAccessException e) {
            LOG.log(Level.WARNING, "Error al eliminar el usuario " + id, e);
            flash(req, "No se pudo eliminar el usuario debido a restricciones de datos. Intente desactivarlo.", "danger");
        }
        redirigir(req, res, "/usuarios/listar");
    }
}
