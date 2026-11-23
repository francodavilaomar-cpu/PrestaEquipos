<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="f" uri="http://universidad.edu/presta/funciones" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<t:layout title="${pageTitle}">

<div class="flex justify-between items-center mb-6 flex-wrap gap-2">
    <div>
        <h4 class="mb-0 font-bold"><i class="ri-group-line me-2 text-success"></i> Gestión de Usuarios</h4>
        <small class="text-muted">Administra las cuentas, accesos, DNI y teléfonos de contacto</small>
    </div>
    <button type="button" class="btn btn-primary"
            data-modal-url="${ctx}/usuarios/crear?modal=1"
            data-modal-title="Crear Nuevo Usuario"
            data-modal-boton="Crear Usuario">
        <i class="ri-user-add-line me-1"></i> Nuevo Usuario
    </button>
</div>

<!-- Filtros de búsqueda -->
<div class="card shadow-sm border-0 mb-6 bg-white">
    <div class="card-body p-4 md:p-6">
        <form method="GET" action="${ctx}/usuarios/listar" class="grid grid-cols-12 gap-4 items-end">
            <div class="col-span-12 md:col-span-6">
                <label for="busqueda" class="form-label text-[0.875em] font-bold text-dark mb-1">Buscar Usuario</label>
                <div class="input-group">
                    <span class="input-group-text bg-white text-muted"><i class="ri-search-line"></i></span>
                    <input type="text" class="form-control" id="busqueda" name="busqueda" placeholder="Buscar por DNI, celular, nombre o email..." value="${f:h(busqueda)}">
                </div>
            </div>
            <div class="col-span-12 md:col-span-4">
                <label for="rol" class="form-label text-[0.875em] font-bold text-dark mb-1">Rol</label>
                <select class="form-select" id="rol" name="rol">
                    <option value="">Todos los roles</option>
                    <option value="admin" ${rolSel == 'admin' ? 'selected' : ''}>Administrador</option>
                    <option value="encargado" ${rolSel == 'encargado' ? 'selected' : ''}>Encargado</option>
                    <option value="usuario" ${rolSel == 'usuario' ? 'selected' : ''}>Usuario</option>
                </select>
            </div>
            <div class="col-span-12 md:col-span-2 flex items-end gap-1">
                <button type="submit" class="btn btn-primary grow">Filtrar</button>
                <c:if test="${not empty busqueda or not empty rolSel}">
                    <a href="${ctx}/usuarios/listar" class="btn btn-outline-secondary" title="Limpiar filtros"><i class="ri-close-line"></i></a>
                </c:if>
            </div>
        </form>
    </div>
</div>

<!-- Tabla Directorio de Usuarios -->
<div class="card shadow-sm border-0">
    <div class="card-header bg-white py-4 px-6 flex justify-between items-center flex-wrap gap-2">
        <h6 class="mb-0 font-bold text-dark"><i class="ri-menu-line me-2 text-success text-xl"></i> Directorio de Usuarios Registrados</h6>
        <span class="badge bg-light text-dark border px-2 py-1">${usuarios.size()} usuarios</span>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0" id="tablaUsuarios">
                <thead>
                    <tr>
                        <th class="ps-6">ID</th>
                        <th>Nombre Completo</th>
                        <th>DNI</th>
                        <th>Celular / Contacto</th>
                        <th>Correo Institucional</th>
                        <th>Rol</th>
                        <th>Estado</th>
                        <th>Fecha Registro</th>
                        <th class="text-right pe-6">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <c:forEach var="u" items="${usuarios}">
                        <tr>
                            <td class="ps-6 text-muted text-[0.875em] font-bold">#${u.id}</td>
                            <td><div class="font-bold text-dark">${f:h(u.nombre)}</div></td>
                            <td>
                                <c:choose>
                                    <c:when test="${not empty u.dni}">
                                        <span class="badge border border-success-border text-success bg-white font-mono px-2 py-1">
                                            <i class="ri-id-card-line me-1"></i>${f:h(u.dni)}
                                        </span>
                                    </c:when>
                                    <c:otherwise><span class="text-muted text-[0.875em]">-</span></c:otherwise>
                                </c:choose>
                            </td>
                            <td>
                                <c:choose>
                                    <c:when test="${not empty u.celular}">
                                        <span class="text-dark text-[0.875em]"><i class="ri-phone-line text-success me-1"></i>${f:h(u.celular)}</span>
                                    </c:when>
                                    <c:otherwise><span class="text-muted text-[0.875em]">-</span></c:otherwise>
                                </c:choose>
                            </td>
                            <td><small class="text-muted">${f:h(u.email)}</small></td>
                            <td>
                                <c:choose>
                                    <c:when test="${u.rol == 'admin'}">
                                        <span class="badge bg-danger rounded-full px-2 py-1">Admin</span>
                                    </c:when>
                                    <c:when test="${u.rol == 'encargado'}">
                                        <span class="badge bg-warning text-dark rounded-full px-2 py-1">Encargado</span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="badge bg-info text-white rounded-full px-2 py-1">Usuario</span>
                                    </c:otherwise>
                                </c:choose>
                            </td>
                            <td>
                                <c:choose>
                                    <c:when test="${u.activo}"><span class="badge badge-disponible">Activo</span></c:when>
                                    <c:otherwise><span class="badge badge-baja">Inactivo</span></c:otherwise>
                                </c:choose>
                            </td>
                            <td><small class="text-muted">${f:fecha(u.fechaRegistro, 'dd/MM/yyyy')}</small></td>
                            <td class="text-right pe-6">
                                <div class="inline-flex gap-1" role="group">
                                    <button type="button" class="btn-action-icon btn-action-key" title="Editar usuario"
                                            data-modal-url="${ctx}/usuarios/editar?id=${u.id}&amp;modal=1"
                                            data-modal-title="Editar Usuario"
                                            data-modal-boton="Actualizar Usuario">
                                        <i class="ri-edit-line"></i>
                                    </button>
                                    <c:if test="${u.id != usuarioActual.id}">
                                        <form method="POST" action="${ctx}/usuarios/cambiar-estado" class="inline">
                                            <t:csrf/>
                                            <input type="hidden" name="id" value="${u.id}">
                                            <button type="submit" class="btn-action-icon ${u.activo ? 'btn-action-delete' : 'btn-action-edit'}" title="${u.activo ? 'Desactivar usuario' : 'Activar usuario'}">
                                                <i class="${u.activo ? 'ri-user-unfollow-line' : 'ri-user-follow-line'}"></i>
                                            </button>
                                        </form>
                                    </c:if>
                                    <c:if test="${u.id != usuarioActual.id}">
                                        <form method="POST" action="${ctx}/usuarios/eliminar" class="inline form-eliminar" data-confirm="¿Está seguro de eliminar permanentemente al usuario '${f:h(u.nombre)}'? Esta acción no se puede deshacer.">
                                            <t:csrf/>
                                            <input type="hidden" name="id" value="${u.id}">
                                            <button type="submit" class="btn-action-icon btn-action-delete" title="Eliminar usuario permanentemente">
                                                <i class="ri-delete-bin-line"></i>
                                            </button>
                                        </form>
                                    </c:if>
                                </div>
                            </td>
                        </tr>
                    </c:forEach>
                    <c:if test="${empty usuarios}">
                        <tr><td colspan="9" class="text-center text-muted py-12">
                            <i class="ri-group-line text-muted opacity-50" style="font-size: 3rem;"></i>
                            <p class="mt-2 mb-0">No se encontraron usuarios registrados.</p>
                        </td></tr>
                    </c:if>
                </tbody>
            </table>
        </div>
    </div>
</div>

</t:layout>
