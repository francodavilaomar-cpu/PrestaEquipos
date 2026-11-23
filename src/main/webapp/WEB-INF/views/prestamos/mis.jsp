<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="f" uri="http://universidad.edu/presta/funciones" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<t:layout title="${pageTitle}">

<div class="mb-6">
    <h4 class="mb-1 font-bold"><i class="ri-computer-line text-success me-2"></i> Mis Equipos</h4>
    <p class="text-muted mb-0">Equipos que tienes en préstamo actualmente.</p>
</div>

<!-- Exportar ambas tablas -->
<div class="flex justify-end gap-2 mb-4 flex-wrap">
    <button type="button" class="btn-export-excel" onclick="exportarMisExcel()" title="Exportar ambas tablas a Excel (CSV)">
        <i class="ri-file-excel-2-line"></i> Excel (ambos cuadros)
    </button>
    <button type="button" class="btn-export-pdf" onclick="exportarMisPDF()" title="Exportar ambas tablas a PDF">
        <i class="ri-file-pdf-2-line"></i> PDF (ambos cuadros)
    </button>
</div>

<!-- Selector de registros por página -->
<div class="flex justify-end gap-2 mb-4 flex-wrap items-center">
    <label for="selectRegistrosMis" class="text-[0.875em] text-muted mb-0">Mostrar</label>
    <select id="selectRegistrosMis" class="form-select form-select-sm" style="width: auto;">
        <option value="5">5</option>
        <option value="10" selected>10</option>
        <option value="15">15</option>
        <option value="25">25</option>
        <option value="50">50</option>
        <option value="100">100</option>
    </select>
    <span class="text-[0.875em] text-muted">registros</span>
</div>


<!-- Vencidos -->
<div class="card shadow-sm border-0 mb-6">
    <div class="card-header bg-white py-4 px-6 flex flex-wrap justify-between items-center gap-2">
        <h6 class="mb-0 text-dark font-bold"><i class="ri-error-warning-line me-2 text-danger text-xl"></i> Vencidos</h6>
        <div class="flex gap-2">
            <button type="button" class="btn-export-excel" onclick="exportTableToCSV('tablaVencidosMis', 'mis_equipos_vencidos.csv')" title="Exportar a Excel (CSV)"><i class="ri-file-excel-2-line"></i> Excel</button>
            <button type="button" class="btn-export-pdf" onclick="exportTableToPDF('tablaVencidosMis', 'Mis Equipos - Vencidos', 'mis_equipos_vencidos.pdf')" title="Exportar a PDF"><i class="ri-file-pdf-2-line"></i> PDF</button>
        </div>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0" id="tablaVencidosMis">
                <thead>
                    <tr>
                        <th class="ps-6">Equipo</th>
                        <th>Código</th>
                        <th>Fecha Préstamo</th>
                        <th>Devolución Esperada</th>
                        <th>Estado</th>
                        <th class="pe-6">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <c:set var="hayVencidosMis" value="false"/>
                    <c:forEach var="p" items="${prestamos}">
                        <c:if test="${p.estado == 'vencido' or (empty p.fechaDevolucionReal and p.vencido)}">
                            <c:set var="hayVencidosMis" value="true"/>
                            <tr>
                                <td class="ps-6"><div class="font-semibold text-dark">${f:h(p.equipoNombre)}</div></td>
                                <td><span class="code-pill">${f:h(p.codigoInventario)}</span></td>
                                <td>${f:fecha(p.fechaPrestamo, 'dd/MM/yyyy HH:mm')}</td>
                                <td>${f:fecha(p.fechaDevolucionEsperada, 'dd/MM/yyyy')}</td>
                                <td><span class="badge badge-vencido">Vencido</span></td>
                                <td class="pe-6">
                                    <c:if test="${empty p.fechaDevolucionReal}">
                                        <button type="button" class="btn btn-sm btn-primary shadow-sm"
                                                data-modal-url="${ctx}/prestamos/devolver?modal=1&amp;prestamo_id=${p.id}"
                                                data-modal-title="Devolver Equipo"
                                                data-modal-boton="Devolver">
                                            <i class="ri-arrow-go-back-line me-1"></i> Devolver
                                        </button>
                                    </c:if>
                                </td>
                            </tr>
                        </c:if>
                    </c:forEach>
                    <c:if test="${!hayVencidosMis}">
                        <tr><td colspan="6" class="text-center text-muted py-8">No tienes equipos vencidos.</td></tr>
                    </c:if>
                </tbody>
            </table>
        </div>
        <div class="card-footer bg-white py-3 px-6">
            <nav><ul class="pagination pagination-sm mb-0" id="pagVencidosMis"></ul></nav>
        </div>
    </div>
</div>

<!-- Devueltos -->
<div class="card shadow-sm border-0">
    <div class="card-header bg-white py-4 px-6 flex flex-wrap justify-between items-center gap-2">
        <h6 class="mb-0 text-dark font-bold"><i class="ri-arrow-go-back-line me-2 text-success text-xl"></i> Devueltos</h6>
        <div class="flex gap-2">
            <button type="button" class="btn-export-excel" onclick="exportTableToCSV('tablaDevueltos', 'mis_equipos_devueltos.csv')" title="Exportar a Excel (CSV)"><i class="ri-file-excel-2-line"></i> Excel</button>
            <button type="button" class="btn-export-pdf" onclick="exportTableToPDF('tablaDevueltos', 'Mis Equipos - Devueltos', 'mis_equipos_devueltos.pdf')" title="Exportar a PDF"><i class="ri-file-pdf-2-line"></i> PDF</button>
        </div>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0" id="tablaDevueltos">
                <thead>
                    <tr>
                        <th class="ps-6">Equipo</th>
                        <th>Código</th>
                        <th>Fecha Préstamo</th>
                        <th>Devuelto el</th>
                        <th>Estado</th>
                        <th class="col-boleta pe-6">Boleta</th>
                    </tr>
                </thead>
                <tbody>
                    <c:set var="hayDevueltos" value="false"/>
                    <c:forEach var="p" items="${prestamos}">
                        <c:if test="${not empty p.fechaDevolucionReal and p.estado != 'vencido'}">
                            <c:set var="hayDevueltos" value="true"/>
                            <tr>
                                <td class="ps-6"><div class="font-semibold text-dark">${f:h(p.equipoNombre)}</div></td>
                                <td><span class="code-pill">${f:h(p.codigoInventario)}</span></td>
                                <td>${f:fecha(p.fechaPrestamo, 'dd/MM/yyyy HH:mm')}</td>
                                <td>${f:fecha(p.fechaDevolucionReal, 'dd/MM/yyyy HH:mm')}</td>
                                <td><span class="badge badge-disponible">Devuelto</span></td>
                                <td class="col-boleta"><button type="button" class="btn btn-sm btn-outline-primary" onclick="abrirBoleta('prestamo', ${p.id})" title="Ver boleta"><i class="ri-file-text-line me-1"></i> Boleta</button></td>
                            </tr>
                        </c:if>
                    </c:forEach>
                    <c:if test="${!hayDevueltos}">
                        <tr><td colspan="6" class="text-center text-muted py-8">No tienes equipos devueltos.</td></tr>
                    </c:if>
                </tbody>
            </table>
        </div>
        <div class="card-footer bg-white py-3 px-6">
            <nav><ul class="pagination pagination-sm mb-0" id="pagDevueltos"></ul></nav>
        </div>
    </div>
</div>

<script>
(function () {
    var select = document.getElementById('selectRegistrosMis');
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
        paginar('tablaVencidosMis', 'pagVencidosMis');
        paginar('tablaDevueltos', 'pagDevueltos');
    }
    aplicar();
    if (select) select.addEventListener('change', aplicar);
})();

function exportarMisExcel() {
    exportMultipleTablesToCSV(['tablaVencidosMis', 'tablaDevueltos'], 'mis_equipos_completo.csv');
}
function exportarMisPDF() {
    exportMultipleTablesToPDF([
        { id: 'tablaVencidosMis', title: 'Mis Equipos - Vencidos' },
        { id: 'tablaDevueltos', title: 'Mis Equipos - Devueltos' }
    ], 'mis_equipos_completo.pdf');
}
</script>
</t:layout>