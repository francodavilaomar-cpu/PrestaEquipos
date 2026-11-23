<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="f" uri="http://universidad.edu/presta/funciones" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<%-- Fragmento del formulario de préstamo: se usa en prestamos/registrar.jsp y dentro del modal del panel. --%>

<t:errores/>
<form method="POST" action="${ctx}/prestamos/registrar" class="needs-validation" novalidate>
    <t:csrf/>

    <!-- Búsqueda rápida de usuario (DNI, apellidos, nombre o celular) -->
    <div class="mb-6 relative" id="contenedorBusquedaUsuario">
        <label for="usuario_busqueda" class="form-label font-bold">Usuario Solicitante *</label>
        <div class="input-group">
            <span class="input-group-text bg-white"><i class="ri-search-line text-success"></i></span>
            <input type="text" class="form-control" id="usuario_busqueda" name="usuario_busqueda"
                   placeholder="Escribe DNI (8 dígitos), apellidos, nombres o teléfono..."
                   autocomplete="off" value="${f:h(usuarioBusquedaValor)}" required>
            <button class="btn btn-outline-secondary" type="button" id="btnLimpiarUsuario" title="Limpiar usuario"
                    ${empty usuarioSeleccionado ? 'style="display:none;"' : ''}>
                <i class="ri-close-line"></i>
            </button>
        </div>
        <input type="hidden" name="usuario_id" id="usuario_id" value="${empty usuarioSeleccionado ? '' : usuarioSeleccionado.id}">
<c:if test="${not empty solicitudId}">
    <input type="hidden" name="solicitud_id" value="${solicitudId}">
</c:if>

        <div class="form-text">
            <i class="ri-lightbulb-line text-warning me-1"></i> Puedes escribir el <strong>DNI</strong>, <strong>apellidos</strong>, <strong>nombres</strong> o <strong>número de celular</strong> para buscar rápidamente.
        </div>

        <div id="listaResultadosUsuarios" class="list-group shadow-lg absolute w-full z-30"
             style="display: none; max-height: 260px; overflow-y: auto; top: 72px;"></div>

        <div id="cardUsuarioSeleccionado" class="card bg-light border-success mt-2" ${empty usuarioSeleccionado ? 'style="display: none;"' : ''}>
            <div class="card-body py-2 px-4 flex justify-between items-center">
                <div>
                    <div class="font-bold text-dark" id="txtNombreUsuario">${f:h(usuarioSeleccionado.nombre)}</div>
                    <div class="text-[0.875em] text-muted">
                        <span><i class="ri-id-card-line text-success me-1"></i>DNI: <strong id="txtDniUsuario">${empty usuarioSeleccionado.dni ? 'No registrado' : f:h(usuarioSeleccionado.dni)}</strong></span>
                        <span class="ms-4"><i class="ri-phone-line text-success me-1"></i>Celular: <strong id="txtCelularUsuario">${empty usuarioSeleccionado.celular ? 'No registrado' : f:h(usuarioSeleccionado.celular)}</strong></span>
                        <span class="ms-4 hidden md:inline"><i class="ri-mail-line text-secondary me-1"></i><span id="txtEmailUsuario">${f:h(usuarioSeleccionado.email)}</span></span>
                    </div>
                </div>
                <span class="badge bg-success-subtle text-success border border-success px-2 py-1">
                    <i class="ri-checkbox-circle-fill me-1"></i> Seleccionado
                </span>
            </div>
        </div>
        <div class="invalid-feedback">Debe buscar y seleccionar un usuario.</div>
    </div>

    <div class="mb-4">
        <label for="equipo_id" class="form-label font-bold">Equipo *</label>
        <select class="form-select" id="equipo_id" name="equipo_id" required
                data-buscable data-placeholder="Buscar por código o nombre...">
            <option value="">Seleccionar equipo disponible...</option>
            <c:forEach var="eqp" items="${equiposDisponibles}">
                <option value="${eqp.id}" ${(not empty equipoSugeridoId && equipoSugeridoId == eqp.id) || (param.equipo_id == eqp.id) ? 'selected' : ''}>${f:h(eqp.codigoInventario)} - ${f:h(eqp.nombre)}</option>
            </c:forEach>
        </select>
        <div class="invalid-feedback">Seleccione un equipo.</div>
        <c:if test="${empty equiposDisponibles}">
            <div class="alert alert-warning mt-2"><i class="ri-alert-line me-1"></i> No hay equipos disponibles para préstamo.</div>
        </c:if>
    </div>

    <div class="grid grid-cols-12 gap-x-6">
        <div class="col-span-12 md:col-span-6 mb-4">
            <label for="fecha_prestamo" class="form-label font-bold">Fecha de Préstamo *</label>
            <input type="datetime-local" class="form-control" id="fecha_prestamo" name="fecha_prestamo" required
                   value="${fechaPrestamoValor}">
            <div class="invalid-feedback">Indique la fecha y hora del préstamo.</div>
        </div>
        <div class="col-span-12 md:col-span-6 mb-4">
            <label for="fecha_devolucion_esperada" class="form-label font-bold">Fecha de Devolución Esperada *</label>
            <input type="datetime-local" class="form-control" id="fecha_devolucion_esperada" name="fecha_devolucion_esperada" required
                   value="${empty param.fecha_devolucion_esperada ? fechaDevolucionValor : f:h(param.fecha_devolucion_esperada)}">
            <div class="invalid-feedback">Debe ser posterior a la fecha de préstamo.</div>
        </div>
    </div>

    <div class="mb-4">
        <label for="observaciones" class="form-label font-bold">Observaciones</label>
        <textarea class="form-control" id="observaciones" name="observaciones" rows="3"
                  placeholder="Notas adicionales o accesorios entregados...">${f:h(param.observaciones)}</textarea>
    </div>

    <c:if test="${not esModal}">
    <div class="flex justify-end gap-2 pt-4 border-t acciones-formulario">
        <a href="${ctx}/dashboard" class="btn btn-secondary">Cancelar</a>
        <button type="submit" class="btn btn-primary"><i class="ri-checkbox-circle-line me-1"></i> Registrar Préstamo</button>
    </div>
    </c:if>
</form>

<%-- Datos que consume el buscador de usuarios (assets/js/prestamo-usuarios.js). --%>
<script type="application/json" data-global="USUARIOS_PRESTAMO">${usuariosJson}</script>
