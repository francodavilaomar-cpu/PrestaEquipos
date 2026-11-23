<%@ page contentType="text/html;charset=UTF-8" isErrorPage="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="f" uri="http://universidad.edu/presta/funciones" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<c:set var="codigo" value="${requestScope['jakarta.servlet.error.status_code']}"/>
<c:set var="mensajeError" value="${requestScope['jakarta.servlet.error.message']}"/>
<c:set var="excepcion" value="${requestScope['jakarta.servlet.error.exception']}"/>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Error - ${f:h(siteName)}</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/remixicon@4.5.0/fonts/remixicon.css">
    <link rel="stylesheet" href="${ctx}/assets/css/tailwind.css?v=20261113e">
</head>
<body class="min-h-screen-ui flex items-center">
<div class="mx-auto w-full max-w-[640px] px-3 py-12">
    <div class="card shadow-[0_12px_40px_rgb(0_56_43/0.10)] border-0 rounded-[18px]">
        <div class="card-body p-6 text-center">
            <div class="mx-auto flex size-[72px] items-center justify-center rounded-full bg-red-50 text-[2.2rem] text-danger"><i class="ri-error-warning-line"></i></div>
            <c:choose>
                <c:when test="${codigo == 404}">
                    <h4 class="mt-4">Página no encontrada</h4>
                    <p class="text-muted">La dirección que busca no existe.</p>
                </c:when>
                <c:when test="${codigo == 403}">
                    <h4 class="mt-4">Acceso denegado</h4>
                    <p class="text-muted">${f:h(mensajeError)}</p>
                </c:when>
                <c:when test="${not empty excepcion and fn:contains(excepcion, 'DataAccessException')}">
                    <h4 class="mt-4">Error de base de datos</h4>
                    <p class="text-muted">Error de conexión a la base de datos. Verifique que SQL Server esté iniciado
                        y que los datos de <code>app.properties</code> sean correctos.</p>
                    <p class="text-muted small mt-2"><code>${f:h(mensajeError)}</code></p>
                </c:when>
                <c:otherwise>
                    <h4 class="mt-4">Ocurrió un error inesperado</h4>
                    <p class="text-muted">Inténtelo de nuevo. Si el problema continúa, contacte al administrador.</p>
                </c:otherwise>
            </c:choose>
            <a href="${ctx}/dashboard" class="btn btn-primary mt-2"><i class="ri-home-5-line"></i> Volver al inicio</a>
        </div>
    </div>
</div>
</body>
</html>
