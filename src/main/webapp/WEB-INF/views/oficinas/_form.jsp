<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="f" uri="http://universidad.edu/presta/funciones" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>

<form method="POST" action="${ctx}/oficinas/guardar" id="formOficina">
    <t:csrf/>
    <c:if test="${not empty oficina}">
        <input type="hidden" name="id" value="${oficina.id}">
    </c:if>

    <div class="mb-4">
        <label for="nombreOficina" class="form-label font-semibold text-slate-700">Nombre de la Oficina o Área <span class="text-danger">*</span></label>
        <div class="input-group">
            <span class="input-group-text"><i class="ri-building-line"></i></span>
            <input type="text" class="form-control" id="nombreOficina" name="nombre" value="${f:h(oficina.nombre)}" placeholder="Ej: Laboratorio de Cómputo 02" required autofocus>
        </div>
    </div>

    <input type="hidden" name="grupo" value="${f:h(oficina.grupo)}">

    <div class="mb-4">
        <label for="descOficina" class="form-label font-semibold text-slate-700">Descripción o Ubicación</label>
        <textarea class="form-control" id="descOficina" name="descripcion" rows="2" placeholder="Edificio, pabellón o detalles">${f:h(oficina.descripcion)}</textarea>
    </div>

    <c:if test="${not empty oficina}">
        <div class="mb-2">
            <div class="form-check form-switch">
                <input class="form-check-input" type="checkbox" id="activoOficina" name="activo" value="1" ${oficina.activo ? 'checked' : ''}>
                <label class="form-check-label font-semibold text-slate-700" for="activoOficina">Oficina activa para solicitudes</label>
            </div>
        </div>
    </c:if>
</form>
