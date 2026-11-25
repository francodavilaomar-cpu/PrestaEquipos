<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="f" uri="http://universidad.edu/presta/funciones" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<t:layout title="${pageTitle}">

    <div class="flex justify-between items-center mb-6 flex-wrap gap-2">
        <div>
            <h4 class="mb-0 font-bold"><i class="ri-building-4-line me-2 text-success"></i> Gestión de Oficinas y Áreas</h4>
            <small class="text-muted">Administra las dependencias y unidades para solicitudes y usuarios</small>
        </div>
        <div>
            <button type="button" class="btn btn-primary"
                    data-modal-url="${ctx}/oficinas/crear?modal=1"
                    data-modal-title="Nueva Oficina / Área"
                    data-modal-boton="Guardar Oficina">
                <i class="ri-add-line me-1"></i> Nueva Oficina
            </button>
        </div>
    </div>

    <div class="card shadow-sm border-0 mb-6 bg-white">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0" id="tablaOficinas">
                    <thead class="table-light">
                        <tr>
                            <th class="ps-6">ID</th>
                            <th>Nombre de Oficina / Área</th>
                            <th>Descripción</th>
                            <th>Estado</th>
                            <th class="text-right pe-6">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="of" items="${oficinas}">
                            <tr>
                                <td class="ps-6 text-muted">#${of.id}</td>
                                <td><span class="font-bold text-dark">${f:h(of.nombre)}</span></td>
                                <td><small class="text-muted">${empty of.descripcion ? '-' : f:h(of.descripcion)}</small></td>
                                <td>
                                    <c:choose>
                                        <c:when test="${of.activo}">
                                            <span class="badge badge-disponible"><i class="ri-checkbox-circle-fill"></i> Activa</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="badge badge-vencido"><i class="ri-close-circle-fill"></i> Inactiva</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="text-right pe-6">
                                    <button type="button" class="btn-action-icon btn-action-edit me-1" title="Editar"
                                            data-modal-url="${ctx}/oficinas/editar?modal=1&amp;id=${of.id}"
                                            data-modal-title="Editar Oficina / Área"
                                            data-modal-boton="Actualizar">
                                        <i class="ri-pencil-line"></i>
                                    </button>
                                    <form method="POST" action="${ctx}/oficinas/eliminar" class="inline form-eliminar" data-confirm="¿Está seguro de eliminar esta oficina?">
                                        <t:csrf/>
                                        <input type="hidden" name="id" value="${of.id}">
                                        <button type="submit" class="btn-action-icon btn-action-delete" title="Eliminar"><i class="ri-delete-bin-line"></i></button>
                                    </form>
                                </td>
                            </tr>
                        </c:forEach>
                        <c:if test="${empty oficinas}">
                            <tr><td colspan="6" class="text-center text-muted py-8">No hay oficinas registradas.</td></tr>
                        </c:if>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

</t:layout>
