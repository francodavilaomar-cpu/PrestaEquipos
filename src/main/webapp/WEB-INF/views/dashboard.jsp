<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="f" uri="http://universidad.edu/presta/funciones" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<t:layout title="${pageTitle}">

<!-- Banner Institucional UNCP -->
<div class="relative overflow-hidden mb-6 rounded-2xl text-white px-5 py-7 md:px-10 md:py-9 shadow-[0_6px_22px_rgb(0_77_61/0.18)] bg-[linear-gradient(135deg,#01372c_0%,#004d3d_50%,#005a46_100%)]">
    <img src="${ctx}/assets/img/uncp-escudo.png" alt="UNCP" class="hidden md:block absolute top-1/2 -translate-y-1/2 right-8 size-[160px] object-contain opacity-[0.35] pointer-events-none select-none">
    <div class="relative z-[2]">
        <div class="inline-flex items-center gap-2.5 mb-4 px-3.5 py-1 rounded-full bg-black/[0.22] border border-white/[0.18] backdrop-blur-[4px]">
            <span class="px-2 py-0.5 rounded-full bg-gold text-ink text-xs font-extrabold tracking-wide">UNCP</span>
            <span class="text-[0.82rem] font-medium text-white/90">Sistema de Préstamos de Equipos</span>
        </div>
        <h2 class="mb-2 text-2xl md:text-[1.95rem] font-extrabold tracking-tight">¡Bienvenido, ${f:h(usuarioActual.nombre)}! 👋</h2>
        <p class="mb-0 max-w-[650px] text-[0.96rem] leading-normal text-white/85">
            Portal institucional de la Universidad Nacional del Centro del Perú para el control y solicitud de equipos tecnológicos.
        </p>
    </div>
</div>

<!-- Tarjetas de estadísticas -->
<c:choose>
    <c:when test="${esEncargado}">
        <div class="grid grid-cols-12 gap-4 mb-6">
            <div class="col-span-12 xl:col-span-3 sm:col-span-6">
                <a href="${ctx}/equipos/listar" class="stat-card stat-card-inventario">
                    <div class="flex justify-between items-center">
                        <div class="stat-icon-box"><i class="ri-smartphone-line"></i></div>
                        <span class="stat-pill">INVENTARIO</span>
                    </div>
                    <div>
                        <div class="stat-num">${totalEquipos}</div>
                        <div class="stat-desc">Total de Equipos</div>
                    </div>
                </a>
            </div>
            <div class="col-span-12 xl:col-span-3 sm:col-span-6">
                <a href="${ctx}/equipos/listar?estado=disponible" class="stat-card stat-card-operativos">
                    <div class="flex justify-between items-center">
                        <div class="stat-icon-box"><i class="ri-check-line"></i></div>
                        <span class="stat-pill">OPERATIVOS</span>
                    </div>
                    <div>
                        <div class="stat-num">${equiposDisponibles}</div>
                        <div class="stat-desc">Equipos Disponibles</div>
                    </div>
                </a>
            </div>
            <div class="col-span-12 xl:col-span-3 sm:col-span-6">
                <a href="${ctx}/equipos/listar?estado=prestado" class="stat-card stat-card-curso">
                    <div class="flex justify-between items-center">
                        <div class="stat-icon-box"><i class="ri-arrow-left-right-line"></i></div>
                        <span class="stat-pill">EN CURSO</span>
                    </div>
                    <div>
                        <div class="stat-num">${equiposPrestados}</div>
                        <div class="stat-desc">Préstamos Activos</div>
                    </div>
                </a>
            </div>
            <div class="col-span-12 xl:col-span-3 sm:col-span-6">
                <a href="${ctx}/prestamos/vencidos" class="stat-card stat-card-vencidos">
                    <div class="flex justify-between items-center">
                        <div class="stat-icon-box"><i class="ri-alert-fill"></i></div>
                        <span class="stat-pill">ATENCIÓN</span>
                    </div>
                    <div>
                        <div class="stat-num">${prestamosVencidos}</div>
                        <div class="stat-desc">Préstamos Vencidos</div>
                    </div>
                </a>
            </div>
        </div>
    </c:when>
    <c:otherwise>
        <div class="grid grid-cols-12 gap-4 mb-6">
            <div class="col-span-12 md:col-span-6">
                <a href="${ctx}/prestamos/mis" class="stat-card stat-card-inventario h-full no-underline block">
                    <div class="flex justify-between items-center">
                        <div class="stat-icon-box"><i class="ri-macbook-line"></i></div>
                        <span class="stat-pill">MIS PRÉSTAMOS</span>
                    </div>
                    <div>
                        <div class="stat-num">${misPrestamosActivos}</div>
                        <div class="stat-desc">Equipos actualmente en tu poder</div>
                    </div>
                </a>
            </div>
            <div class="col-span-12 md:col-span-6">
                <div class="h-full min-h-[145px] flex flex-col items-center justify-center text-center rounded-[14px] bg-accent px-8 py-6 text-white shadow-[0_4px_14px_rgb(5_150_105/0.2)]">
                    <h5 class="mb-1.5 text-xl font-bold">¿Necesitas un equipo tecnológico?</h5>
                    <p class="mb-4 max-w-[480px] text-[0.9rem] opacity-90">Revisa las computadoras, laptops y proyectores disponibles para préstamo.</p>
                    <a href="${ctx}/equipos/listar" class="btn btn-light text-dark font-bold px-6 py-2 rounded-lg shadow-sm">
                        <i class="ri-add-circle-line me-1 text-success"></i> Solicitar Préstamo
                    </a>
                </div>
            </div>
        </div>
    </c:otherwise>
</c:choose>

<!-- Últimos préstamos / Historial Reciente -->
<div class="grid grid-cols-12 gap-x-6">
    <div class="col-span-12">
        <div class="card shadow-sm border-0">
            <div class="card-header bg-white py-4 px-6 flex items-center justify-between">
                <h6 class="mb-0 font-bold flex items-center gap-2">
                    <i class="ri-time-line text-success text-xl"></i>
                    <span>${esEncargado ? 'Últimos Préstamos' : 'Mi Historial Reciente'}</span>
                </h6>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead>
                            <tr>
                                <th class="ps-6">Equipo</th>
                                <th>Usuario</th>
                                <th>Fecha Préstamo</th>
                                <th>Fecha Devolución</th>
                                <th class="pe-6">Estado</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach var="p" items="${ultimosPrestamos}">
                                <tr>
                                    <td class="ps-6 font-semibold">${f:h(p.equipoNombre)}</td>
                                    <td>${f:h(p.usuarioNombre)}</td>
                                    <td>${f:fecha(p.fechaPrestamo, 'dd/MM/yyyy HH:mm')}</td>
                                    <td>${empty p.fechaDevolucionEsperada ? '-' : f:fecha(p.fechaDevolucionEsperada, 'dd/MM/yyyy')}</td>
                                    <td class="pe-6">
                                        <c:choose>
                                            <c:when test="${p.estado == 'activo'}">
                                                <span class="badge badge-prestado"><i class="ri-arrow-left-right-line"></i> Prestado</span>
                                            </c:when>
                                            <c:when test="${p.estado == 'devuelto'}">
                                                <span class="badge badge-disponible"><i class="ri-checkbox-circle-fill"></i> Devuelto</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="badge badge-vencido"><i class="ri-alert-fill"></i> Vencido</span>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>
                                </tr>
                            </c:forEach>
                            <c:if test="${empty ultimosPrestamos}">
                                <tr>
                                    <td colspan="5" class="text-center text-muted py-12">
                                        <div class="py-4">
                                            <i class="ri-inbox-line text-[2rem] block text-muted mb-2 opacity-50"></i>
                                            <span>No hay préstamos registrados</span>
                                        </div>
                                    </td>
                                </tr>
                            </c:if>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>

</t:layout>
