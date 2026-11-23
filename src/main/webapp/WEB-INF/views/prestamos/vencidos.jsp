<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="f" uri="http://universidad.edu/presta/funciones" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<t:layout title="${pageTitle}">

<div class="flex justify-between items-center mb-6 flex-wrap gap-2">
    <div>
        <h4 class="mb-0 font-bold"><i class="ri-time-line me-2 text-success"></i> Préstamos Activos y Vencidos</h4>
        <small class="text-muted">Control de préstamos en curso, fechas límite y devoluciones</small>
    </div>
    <div class="flex gap-2">
        <button type="button" class="btn btn-primary"
                data-modal-url="${ctx}/prestamos/registrar?modal=1"
                data-modal-title="Registrar Préstamo de Equipo"
                data-modal-boton="Registrar Préstamo">
            <i class="ri-add-line me-1"></i> Nuevo Préstamo
        </button>
        <button type="button" class="btn btn-success"
                data-modal-url="${ctx}/prestamos/devolver?modal=1"
                data-modal-title="Devolver Equipo"
                data-modal-boton="Confirmar Devolución">
            <i class="ri-arrow-go-back-line me-1"></i> Devolver Equipo
        </button>
    </div>
</div>


<!-- Exportar ambas tablas -->
<div class="flex justify-end gap-2 mb-4 flex-wrap">
    <button type="button" class="btn-export-excel" onclick="exportarVencidosExcel()" title="Exportar ambas tablas a Excel (CSV)">
        <i class="ri-file-excel-2-line"></i> Excel (ambos cuadros)
    </button>
    <button type="button" class="btn-export-pdf" onclick="exportarVencidosPDF()" title="Exportar ambas tablas a PDF">
        <i class="ri-file-pdf-2-line"></i> PDF (ambos cuadros)
    </button>
</div>

<!-- Selector de registros por página -->
<div class="flex justify-end gap-2 mb-4 flex-wrap items-center">
    <label for="selectRegistrosVencidos" class="text-[0.875em] text-muted mb-0">Mostrar</label>
    <select id="selectRegistrosVencidos" class="form-select form-select-sm" style="width: auto;">
        <option value="5">5</option>
        <option value="10" selected>10</option>
        <option value="15">15</option>
        <option value="25">25</option>
        <option value="50">50</option>
        <option value="100">100</option>
    </select>
    <span class="text-[0.875em] text-muted">registros</span>
</div>

<!-- Activos -->
<div class="card shadow-sm border-0 mb-6">
    <div class="card-header bg-white py-4 px-6 flex justify-between items-center flex-wrap gap-2">
        <h6 class="mb-0 font-bold text-dark"><i class="ri-checkbox-circle-line me-2 text-success text-xl"></i> Activos</h6>
        <div class="flex gap-2">
            <button type="button" class="btn-export-excel" onclick="exportTableToCSV('tablaActivos', 'prestamos_activos.csv')"><i class="ri-file-excel-2-line"></i> Excel</button>
            <button type="button" class="btn-export-pdf" onclick="exportTableToPDF('tablaActivos', 'Préstamos Activos', 'prestamos_activos.pdf')"><i class="ri-file-pdf-2-line"></i> PDF</button>
        </div>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0" id="tablaActivos">
                <thead>
                    <tr>
                        <th class="ps-6">Equipo</th>
                        <th>Usuario</th>
                        <th>Fecha Préstamo</th>
                        <th>Fecha Esperada</th>
                        <th>Días Vencido</th>
                        <th>Estado</th>
                        <th class="text-right pe-6">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <c:set var="hayActivos" value="false"/>
                    <c:forEach var="p" items="${prestamos}">
                        <c:if test="${!p.vencido}">
                            <c:set var="hayActivos" value="true"/>
                            <tr>
                                <td class="ps-6">
                                    <span class="code-pill">${f:h(p.codigoInventario)}</span>
                                    <div class="font-bold text-dark mt-1">${f:h(p.equipoNombre)}</div>
                                </td>
                                <td>
                                    <div class="font-bold text-dark">${f:h(p.usuarioNombre)}</div>
                                    <small class="text-muted">${f:h(p.usuarioEmail)}</small>
                                </td>
                                <td>${f:fecha(p.fechaPrestamo, 'dd/MM/yyyy HH:mm')}</td>
                                <td>${f:fecha(p.fechaDevolucionEsperada, 'dd/MM/yyyy')}</td>
                                <td><span class="text-success"><i class="ri-checkbox-circle-fill me-1"></i>A tiempo</span></td>
                                <td><span class="badge badge-prestado">Activo</span></td>
                                <td class="text-right pe-6">
                                    <button type="button" class="btn-action-icon btn-action-edit" title="Devolver"
                                            data-modal-url="${ctx}/prestamos/devolver?modal=1&amp;prestamo_id=${p.id}"
                                            data-modal-title="Devolver Equipo"
                                            data-modal-boton="Confirmar Devolución">
                                        <i class="ri-checkbox-circle-line"></i>
                                    </button>
                                </td>
                            </tr>
                        </c:if>
                    </c:forEach>
                    <c:if test="${!hayActivos}">
                        <tr><td colspan="7" class="text-center text-muted py-8">No hay préstamos activos.</td></tr>
                    </c:if>
                </tbody>
            </table>
        </div>
        <div class="card-footer bg-white py-3 px-6">
            <nav><ul class="pagination pagination-sm mb-0" id="pagActivos"></ul></nav>
        </div>
    </div>
</div>

<!-- Vencidos -->
<div class="card shadow-sm border-0">
    <div class="card-header bg-white py-4 px-6 flex justify-between items-center flex-wrap gap-2">
        <h6 class="mb-0 font-bold text-dark"><i class="ri-error-warning-line me-2 text-danger text-xl"></i> Vencidos</h6>
        <div class="flex gap-2">
            <button type="button" class="btn-export-excel" onclick="exportTableToCSV('tablaVencidos', 'prestamos_vencidos.csv')"><i class="ri-file-excel-2-line"></i> Excel</button>
            <button type="button" class="btn-export-pdf" onclick="exportTableToPDF('tablaVencidos', 'Préstamos Vencidos', 'prestamos_vencidos.pdf')"><i class="ri-file-pdf-2-line"></i> PDF</button>
        </div>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0" id="tablaVencidos">
                <thead>
                    <tr>
                        <th class="ps-6">Equipo</th>
                        <th>Usuario</th>
                        <th>Fecha Préstamo</th>
                        <th>Fecha Esperada</th>
                        <th>Días Vencido</th>
                        <th>Estado</th>
                        <th class="text-right pe-6">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <c:set var="hayVencidos" value="false"/>
                    <c:forEach var="p" items="${prestamos}">
                        <c:if test="${p.vencido}">
                            <c:set var="hayVencidos" value="true"/>
                            <tr class="table-danger">
                                <td class="ps-6">
                                    <span class="code-pill">${f:h(p.codigoInventario)}</span>
                                    <div class="font-bold text-dark mt-1">${f:h(p.equipoNombre)}</div>
                                </td>
                                <td>
                                    <div class="font-bold text-dark">${f:h(p.usuarioNombre)}</div>
                                    <small class="text-muted">${f:h(p.usuarioEmail)}</small>
                                </td>
                                <td>${f:fecha(p.fechaPrestamo, 'dd/MM/yyyy HH:mm')}</td>
                                <td>${f:fecha(p.fechaDevolucionEsperada, 'dd/MM/yyyy')}</td>
                                <td><span class="text-danger font-bold"><i class="ri-error-warning-fill me-1"></i>${p.diasVencido} día(s)</span></td>
                                <td><span class="badge badge-vencido">Vencido</span></td>
                                <td class="text-right pe-6">
                                    <button type="button" class="btn-action-icon btn-action-edit" title="Devolver"
                                            data-modal-url="${ctx}/prestamos/devolver?modal=1&amp;prestamo_id=${p.id}"
                                            data-modal-title="Devolver Equipo"
                                            data-modal-boton="Confirmar Devolución">
                                        <i class="ri-checkbox-circle-line"></i>
                                    </button>
                                </td>
                            </tr>
                        </c:if>
                    </c:forEach>
                    <c:if test="${!hayVencidos}">
                        <tr><td colspan="7" class="text-center text-muted py-8">No hay préstamos vencidos.</td></tr>
                    </c:if>
                </tbody>
            </table>
        </div>
        <div class="card-footer bg-white py-3 px-6">
            <nav><ul class="pagination pagination-sm mb-0" id="pagVencidos"></ul></nav>
        </div>
    </div>
</div>

<script>
(function () {
    var select = document.getElementById('selectRegistrosVencidos');
    function porPagina() { return select ? (parseInt(select.value, 10) || 10) : 10; }

    function paginar(idTabla, idPag) {
        var tabla = document.getElementById(idTabla);
        var cont = document.getElementById(idPag);
        if (!tabla || !cont) return;
        var filas = Array.from(tabla.querySelectorAll('tbody tr'));
        var pp = porPagina();
        var total = Math.ceil(filas.length / pp);
        if (total <= 1) { cont.style.display = 'none'; return; }
        var pagina = 1;
        function render() {
            filas.forEach(function (fila, idx) {
                fila.style.display = (idx >= (pagina - 1) * pp && idx < pagina * pp) ? '' : 'none';
            });
            cont.innerHTML = '';
            for (var i = 1; i <= total; i++) {
                var li = document.createElement('li');
                li.className = 'page-item' + (i === pagina ? ' active' : '');
                var btn = document.createElement('button');
                btn.type = 'button';
                btn.className = 'page-link';
                btn.textContent = i;
                (function (p) { btn.addEventListener('click', function () { pagina = p; render(); }); })(i);
                li.appendChild(btn);
                cont.appendChild(li);
            }
        }
        render();
    }

    function aplicar() {
        paginar('tablaActivos', 'pagActivos');
        paginar('tablaVencidos', 'pagVencidos');
    }
    aplicar();
    if (select) select.addEventListener('change', aplicar);
})();

function exportarVencidosExcel() {
    exportMultipleTablesToCSV(['tablaActivos', 'tablaVencidos'], 'prestamos_activos_y_vencidos.csv');
}
function exportarVencidosPDF() {
    exportMultipleTablesToPDF([
        { id: 'tablaActivos', title: 'Préstamos Activos' },
        { id: 'tablaVencidos', title: 'Préstamos Vencidos' }
    ], 'prestamos_activos_y_vencidos.pdf');
}
</script>

</t:layout>