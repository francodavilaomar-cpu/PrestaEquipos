<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="f" uri="http://universidad.edu/presta/funciones" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<%-- Fragmento del formulario de solicitud de equipo: se usa en equipos/listar.jsp y dentro del modal del panel. --%>

<t:errores/>
<form method="POST" action="${ctx}/equipos/listar" class="needs-validation" novalidate>
    <t:csrf/>
    <input type="hidden" name="accion" value="solicitar">

    <div class="mb-6">
        <label for="busqueda" class="form-label text-dark font-bold">Equipo Requerido *</label>
        <input type="text" class="form-control" id="busqueda" name="busqueda" list="listaEquiposDisponibles"
               placeholder="Selecciona o escribe el equipo deseado..." value="${f:h(busqueda)}" required>
        <datalist id="listaEquiposDisponibles">
            <c:forEach var="eqp" items="${equiposDisponibles}">
                <option value="${f:h(eqp.nombre)} (${f:h(eqp.codigoInventario)})">
            </c:forEach>
        </datalist>
        <div class="form-text">Puedes elegir uno de los equipos disponibles sugeridos o escribir el tipo de equipo.</div>
        <div class="invalid-feedback">Por favor indique el equipo requerido.</div>
    </div>

    <div class="mb-6">
        <label for="oficina" class="form-label text-dark font-bold">Oficina / Unidad Destino *</label>
        <c:choose>
            <c:when test="${not empty usuarioOficina}">
                <div class="input-group">
                    <span class="input-group-text bg-light text-success"><i class="ri-building-line"></i></span>
                    <input type="text" class="form-control bg-light" value="${f:h(usuarioOficina)}" readonly>
                    <input type="hidden" id="oficina" name="oficina" value="${f:h(usuarioOficina)}">
                </div>
                <div class="form-text text-success font-medium"><i class="ri-checkbox-circle-line me-1"></i>Área / oficina asignada automáticamente según su cuenta.</div>
            </c:when>
            <c:otherwise>
                <select class="form-select" id="oficina" name="oficina" required
                        data-buscable data-placeholder="Buscar oficina o área...">
                    <option value="">Seleccionar oficina o área...</option>
                    <c:forEach var="g" items="${gruposOficinas}">
                        <optgroup label="${f:h(g.etiqueta)}">
                            <c:forEach var="o" items="${g.oficinas}">
                                <option value="${f:h(o)}">${f:h(o)}</option>
                            </c:forEach>
                        </optgroup>
                    </c:forEach>
                </select>
                <div class="invalid-feedback">Seleccione la oficina donde se utilizará el equipo.</div>
            </c:otherwise>
        </c:choose>
    </div>

    <div class="grid grid-cols-12 gap-x-6">
        <div class="col-span-12 md:col-span-6 mb-6">
            <label for="fecha_prestamo" class="form-label text-dark font-bold">Fecha de Préstamo *</label>
            <input type="datetime-local" class="form-control" id="fecha_prestamo" name="fecha_prestamo"
                   min="${minPrestamo}" value="${f:h(ahoraInput)}" required>
            <div class="invalid-feedback">Indique la fecha y hora de entrega.</div>
        </div>
        <div class="col-span-12 md:col-span-6 mb-6">
            <label for="fecha_devolucion" class="form-label text-dark font-bold">Fecha de Devolución Esperada *</label>
            <input type="datetime-local" class="form-control" id="fecha_devolucion" name="fecha_devolucion" min="${ahoraInput}" required>
            <div class="invalid-feedback">Indique la fecha esperada de devolución.</div>
        </div>
    </div>

    <div class="mb-6">
        <label for="observaciones" class="form-label text-dark font-bold">Observaciones / Motivo</label>
        <textarea class="form-control" id="observaciones" name="observaciones" rows="3" placeholder="Indique el motivo del uso, accesorios necesarios u observaciones adicionales..."></textarea>
    </div>

    <c:if test="${not esModal}">
    <div class="flex justify-end gap-2 mt-2 pt-4 border-t acciones-formulario">
        <button type="submit" class="btn btn-primary px-6"><i class="ri-send-plane-fill me-1"></i> Enviar Solicitud</button>
    </div>
    </c:if>
</form>
