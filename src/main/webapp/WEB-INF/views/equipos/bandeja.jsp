<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="f" uri="http://universidad.edu/presta/funciones" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<t:layout title="${pageTitle}">

<div class="mb-4">
    <h4 class="mb-0 font-bold"><i class="ri-inbox-line me-2 text-success"></i> Bandeja de Solicitudes de Equipos</h4>
    <small class="text-muted">Atiende las solicitudes de los usuarios</small>
</div>

<div class="card shadow-sm border-0">
    <div class="card-header bg-white py-4 px-6 flex justify-between items-center flex-wrap gap-2">
        <h6 class="mb-0 text-dark font-bold"><i class="ri-inbox-line me-2 text-success text-xl"></i> Bandeja de Solicitudes de Equipos</h6>
        <div class="flex gap-2 items-center flex-wrap">
            <label for="selectRegistrosBandeja" class="text-[0.875em] text-muted mb-0">Mostrar</label>
            <select id="selectRegistrosBandeja" class="form-select form-select-sm" style="width: auto;">
                <option value="5">5</option>
                <option value="10" selected>10</option>
                <option value="15">15</option>
                <option value="25">25</option>
                <option value="50">50</option>
                <option value="100">100</option>
            </select>
            <span class="text-[0.875em] text-muted">registros</span>
            <button type="button" class="btn-export-excel" onclick="exportTableToCSV('tablaSolicitudes', 'solicitudes_equipos.csv')" title="Exportar a Excel (CSV)">
                <i class="ri-file-excel-2-line"></i> Excel
            </button>
            <button type="button" class="btn-export-pdf" onclick="exportTableToPDF('tablaSolicitudes', 'Bandeja de Solicitudes de Equipos', 'solicitudes_equipos.pdf')" title="Exportar a PDF">
                <i class="ri-file-pdf-2-line"></i> PDF
            </button>
        </div>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0" id="tablaSolicitudes">
                <thead>
                    <tr>
                        <th class="ps-6">Usuario</th>
                        <th>Equipo Solicitado</th>
                        <th>Fecha Préstamo</th>
                        <th>Fecha Devolución</th>
                        <th>Oficina y Área</th>
                        <th>Observaciones</th>
                        <th>Estado</th>
                        <th class="text-right pe-6">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <c:forEach var="sol" items="${solicitudes}">
                        <tr>
                            <td class="ps-6">
                                <div class="font-bold"><c:choose><c:when test="${empty sol.usuarioNombre}">Usuario #${sol.usuarioId}</c:when><c:otherwise>${f:h(sol.usuarioNombre)}</c:otherwise></c:choose></div>
                                <small class="text-muted">${f:h(sol.usuarioEmail)}</small>
                            </td>
                            <td><span class="font-semibold text-dark">${f:h(sol.equipoSolicitado)}</span></td>
                            <td>${f:fecha(sol.fechaPrestamo, 'dd/MM/yyyy HH:mm')}</td>
                            <td>${f:fecha(sol.fechaDevolucion, 'dd/MM/yyyy HH:mm')}</td>
                            <td>
                                <div class="text-[0.875em] text-muted font-bold uppercase" style="font-size: 0.7rem; letter-spacing: 0.5px;">${f:h(sol.area)}</div>
                                <div class="font-semibold">${f:h(sol.oficina)}</div>
                            </td>
                            <td><small class="text-muted">${empty sol.observaciones ? '-' : f:h(sol.observaciones)}</small></td>
                            <td>
                                <c:choose>
                                    <c:when test="${sol.estado == 'aprobada'}">
                                        <span class="badge badge-disponible"><i class="ri-checkbox-circle-fill"></i> Aprobada</span>
                                    </c:when>
                                    <c:when test="${sol.estado == 'rechazada'}">
                                        <span class="badge badge-vencido"><i class="ri-close-circle-fill"></i> Rechazada</span>
                                    </c:when>
                                    <c:when test="${sol.estado == 'devuelta'}">
                                        <span class="badge badge-disponible"><i class="ri-arrow-go-back-line"></i> Devuelta</span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="badge badge-mantenimiento"><i class="ri-time-line"></i> Pendiente</span>
                                    </c:otherwise>
                                </c:choose>
                            </td>
                            <td class="text-right pe-6">
                                <c:choose>
                                    <c:when test="${sol.estado == 'pendiente'}">
                                        <c:if test="${not esAdmin and solicitudesRegistrables.contains(sol.id)}">
                                            <button type="button" class="btn-action-icon btn-action-edit me-1" title="Registrar préstamo desde esta solicitud"
                                                    data-modal-url="${ctx}/prestamos/registrar?modal=1&amp;solicitud_id=${sol.id}"
                                                    data-modal-title="Registrar Préstamo"
                                                    data-modal-boton="Registrar Préstamo">
                                                <i class="ri-add-circle-line"></i>
                                            </button>
                                        </c:if>
                                        <c:if test="${esAdmin}">
                                            <form method="POST" action="${ctx}/equipos/bandeja" class="inline">
                                                <t:csrf/>
                                                <input type="hidden" name="solicitud_id" value="${sol.id}">
                                                <input type="hidden" name="accion" value="aprobar_solicitud">
                                                <button type="submit" class="btn-action-icon btn-action-edit me-1" title="Aprobar solicitud"><i class="ri-check-line"></i></button>
                                            </form>
                                            <form method="POST" action="${ctx}/equipos/bandeja" class="inline">
                                                <t:csrf/>
                                                <input type="hidden" name="solicitud_id" value="${sol.id}">
                                                <input type="hidden" name="accion" value="rechazar_solicitud">
                                                <button type="submit" class="btn-action-icon btn-action-delete me-1" title="Rechazar solicitud"><i class="ri-close-line"></i></button>
                                            </form>
                                        </c:if>
                                        <form method="POST" action="${ctx}/equipos/bandeja" class="inline form-eliminar" data-confirm="¿Está seguro de eliminar esta solicitud? Esta acción no se puede deshacer.">
                                            <t:csrf/>
                                            <input type="hidden" name="solicitud_id" value="${sol.id}">
                                            <input type="hidden" name="accion" value="eliminar_solicitud">
                                            <button type="submit" class="btn-action-icon btn-action-delete" title="Eliminar solicitud"><i class="ri-delete-bin-line"></i></button>
                                        </form>
                                    </c:when>
                                    <c:when test="${sol.estado == 'aprobada'}">
                                        <c:if test="${not esAdmin and solicitudesRegistrables.contains(sol.id)}">
                                            <button type="button" class="btn-action-icon btn-action-edit me-1" title="Registrar préstamo desde esta solicitud"
                                                    data-modal-url="${ctx}/prestamos/registrar?modal=1&amp;solicitud_id=${sol.id}"
                                                    data-modal-title="Registrar Préstamo"
                                                    data-modal-boton="Registrar Préstamo">
                                                <i class="ri-add-circle-line"></i>
                                            </button>
                                        </c:if>
                                        <form method="POST" action="${ctx}/equipos/bandeja" class="inline form-eliminar" data-confirm="¿Está seguro de eliminar esta solicitud? Esta acción no se puede deshacer.">
                                            <t:csrf/>
                                            <input type="hidden" name="solicitud_id" value="${sol.id}">
                                            <input type="hidden" name="accion" value="eliminar_solicitud">
                                            <button type="submit" class="btn-action-icon btn-action-delete" title="Eliminar solicitud"><i class="ri-delete-bin-line"></i></button>
                                        </form>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="text-muted text-[0.875em] me-1">Atendido</span>
                                        <form method="POST" action="${ctx}/equipos/bandeja" class="inline form-eliminar" data-confirm="¿Está seguro de eliminar esta solicitud? Esta acción no se puede deshacer.">
                                            <t:csrf/>
                                            <input type="hidden" name="solicitud_id" value="${sol.id}">
                                            <input type="hidden" name="accion" value="eliminar_solicitud">
                                            <button type="submit" class="btn-action-icon btn-action-delete" title="Eliminar solicitud"><i class="ri-delete-bin-line"></i></button>
                                        </form>
                                    </c:otherwise>
                                </c:choose>
                            </td>
                        </tr>
                    </c:forEach>
                    <c:if test="${empty solicitudes}">
                        <tr id="filaSinResultados"><td colspan="8" class="text-center text-muted py-12">
                            <i class="ri-inbox-line text-muted opacity-50" style="font-size: 3rem;"></i>
                            <p class="mt-4 mb-0">No hay solicitudes registradas.</p>
                        </td></tr>
                    </c:if>
                </tbody>
            </table>
        </div>
    </div>
    <div class="card-footer bg-white py-4 px-6 flex justify-between items-center flex-wrap gap-2" id="footerPaginacionBandeja">
        <small class="text-muted mb-0" id="infoPaginacionBandeja"></small>
        <nav aria-label="Paginación de solicitudes">
            <ul class="pagination pagination-sm mb-0" id="paginacionBandeja"></ul>
        </nav>
    </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function () {
    const tabla = document.getElementById('tablaSolicitudes');
    if (!tabla) return;
    const tbody = tabla.querySelector('tbody');
    if (!tbody) return;
    let filas = Array.from(tbody.querySelectorAll('tr')).filter(function (tr) {
        return tr.querySelectorAll('td').length > 1;
    });
    const filaVacia = tbody.querySelector('#filaSinResultados');
    const select = document.getElementById('selectRegistrosBandeja');
    let porPagina = select ? (parseInt(select.value, 10) || 10) : 10;
    let paginaActual = 1;

    function paginar() {
        const totalPaginas = Math.max(1, Math.ceil(filas.length / porPagina));
        if (paginaActual > totalPaginas) paginaActual = totalPaginas;
        const inicio = (paginaActual - 1) * porPagina;
        const fin = inicio + porPagina;
        filas.forEach(function (fila, idx) {
            fila.style.display = (idx >= inicio && idx < fin) ? '' : 'none';
        });
        if (filaVacia) {
            filaVacia.style.display = filas.length ? 'none' : '';
        }
        const info = document.getElementById('infoPaginacionBandeja');
        if (info) {
            if (!filas.length) {
                info.textContent = 'No hay solicitudes para mostrar';
            } else {
                info.textContent = 'Mostrando ' + (inicio + 1) + '–' + Math.min(fin, filas.length) +
                    ' de ' + filas.length + ' registros';
            }
        }
        renderPaginacion(totalPaginas);
    }

    function paginasVisibles(total, actual) {
        if (total <= 7) {
            const arr = [];
            for (let i = 1; i <= total; i++) arr.push(i);
            return arr;
        }
        if (actual <= 4) return [1, 2, 3, 4, 5, '...', total];
        if (actual >= total - 3) return [1, '...', total - 4, total - 3, total - 2, total - 1, total];
        return [1, '...', actual - 1, actual, actual + 1, '...', total];
    }

    function renderPaginacion(totalPaginas) {
        const contenedor = document.getElementById('paginacionBandeja');
        if (!contenedor) return;
        contenedor.innerHTML = '';
        const nav = contenedor.closest('nav');
        if (nav) nav.style.display = totalPaginas > 1 ? '' : 'none';
        if (totalPaginas <= 1) return;

        function crearItem(texto, destino, opciones) {
            opciones = opciones || {};
            const li = document.createElement('li');
            li.className = 'page-item' + (opciones.activo ? ' active' : '') + (opciones.deshabilitado ? ' disabled' : '');
            const boton = document.createElement('button');
            boton.type = 'button';
            boton.className = 'page-link';
            boton.innerHTML = texto;
            if (opciones.titulo) boton.title = opciones.titulo;
            if (!opciones.deshabilitado && !opciones.activo) {
                boton.addEventListener('click', function () { irAPagina(destino); });
            }
            li.appendChild(boton);
            contenedor.appendChild(li);
        }

        crearItem('<i class="ri-arrow-left-s-line"></i>', paginaActual - 1, {
            deshabilitado: paginaActual === 1,
            titulo: 'Página anterior'
        });

        paginasVisibles(totalPaginas, paginaActual).forEach(function (pagina) {
            if (pagina === '...') {
                const li = document.createElement('li');
                li.className = 'page-item disabled';
                li.innerHTML = '<span class="page-link">…</span>';
                contenedor.appendChild(li);
            } else {
                crearItem(String(pagina), pagina, { activo: pagina === paginaActual });
            }
        });

        crearItem('<i class="ri-arrow-right-s-line"></i>', paginaActual + 1, {
            deshabilitado: paginaActual === totalPaginas,
            titulo: 'Página siguiente'
        });
    }

    function irAPagina(pagina) {
        const totalPaginas = Math.max(1, Math.ceil(filas.length / porPagina));
        if (pagina < 1 || pagina > totalPaginas) return;
        paginaActual = pagina;
        paginar();
        const tablaEl = document.getElementById('tablaSolicitudes');
        if (tablaEl) {
            const y = tablaEl.getBoundingClientRect().top + window.pageYOffset - 100;
            window.scrollTo({ top: y, behavior: 'smooth' });
        }
    }

    if (select) {
        select.addEventListener('change', function () {
            porPagina = parseInt(this.value, 10) || 10;
            paginaActual = 1;
            paginar();
        });
    }

    paginar();
});
</script>

</t:layout>