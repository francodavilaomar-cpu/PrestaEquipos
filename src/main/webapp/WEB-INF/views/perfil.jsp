<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="f" uri="http://universidad.edu/presta/funciones" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<t:layout title="${pageTitle}">

<div class="grid grid-cols-12 gap-x-6 justify-center">
    <div class="col-span-12 lg:col-span-8">

        <div class="grid grid-cols-12 gap-6">
            <!-- Cambio de contraseña -->
            <div class="col-span-12">
                <div class="card shadow-sm border-0 h-full">
                    <div class="card-header bg-white py-4">
                        <h5 class="mb-0 font-bold text-dark"><i class="ri-key-2-fill me-2 text-success"></i> Cambiar Mi Contraseña</h5>
                    </div>
                    <div class="card-body p-6">
                        <jsp:include page="/WEB-INF/views/perfil/_form.jsp"/>
                    </div>
                </div>
            </div>
        </div>

    </div>
</div>

</t:layout>
