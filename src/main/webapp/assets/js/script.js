// Funciones JavaScript generales

// Cierra las alertas visibles después de 5 segundos. Se puede volver a llamar
// cuando se insertan alertas nuevas (por ejemplo, dentro de un modal).
window.autoCerrarAlertas = function () {
    document.querySelectorAll('.alert:not([data-auto-cerrada])').forEach(function (alert) {
        alert.setAttribute('data-auto-cerrada', '1');
        
        setTimeout(function () {
            UI.cerrarAlerta(alert);
        }, 5000);
    });
};

document.addEventListener('DOMContentLoaded', function() {

    window.autoCerrarAlertas();
    
    // Confirmación para acciones de eliminar
    // (Manejado por SweetAlert2 en sweetalert-config.js)
    
    // Validación de formularios con Bootstrap (delegado: también aplica a los formularios
    // que se cargan dentro de un modal).
    document.addEventListener('submit', function(event) {
        const form = event.target;
        if (!form || form.tagName !== 'FORM' || !form.classList.contains('needs-validation')) {
            return;
        }
        if (!form.checkValidity()) {
            event.preventDefault();
        }
        form.classList.add('was-validated');
    });
    
    // Rango de fechas: la fecha de fin nunca puede ser anterior a la de inicio.
    // Un mismo campo de inicio puede alimentar varios destinos (el formulario del
    // admin usa "fecha_devolucion_esperada" y el de solicitud del usuario "fecha_devolucion").
    const RANGOS_FECHAS = {
        'fecha_prestamo': ['fecha_devolucion_esperada', 'fecha_devolucion'],
        'fecha_inicio': ['fecha_fin']
    };
    document.addEventListener('change', function(event) {
        const origen = event.target;
        if (!origen || !origen.id) {
            return;
        }
        const idsDestino = RANGOS_FECHAS[origen.id];
        if (!idsDestino) {
            return;
        }
        const raiz = origen.closest('form') || document;
        idsDestino.forEach(function (idDestino) {
            const destino = raiz.querySelector('#' + idDestino);
            if (!destino || !origen.value) {
                return;
            }
            destino.min = origen.value;
            if (destino.value && destino.value < origen.value) {
                destino.value = origen.value;
            }
        });
    });
    
    // Función para formatear fechas
    window.formatDate = function(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        return date.toLocaleDateString('es-ES', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    };
    
    // Buscar en tablas
    const searchInputs = document.querySelectorAll('.table-search');
    searchInputs.forEach(function(input) {
        input.addEventListener('keyup', function() {
            const searchTerm = this.value.toLowerCase();
            const table = this.closest('.card').querySelector('table tbody');
            if (table) {
                const rows = table.querySelectorAll('tr');
                rows.forEach(function(row) {
                    const text = row.textContent.toLowerCase();
                    row.style.display = text.includes(searchTerm) ? '' : 'none';
                });
            }
        });
    });

    // Menú lateral deslizante (off-canvas) para móvil y tablet
    const sidebar = document.getElementById('sidebar');
    const sidebarToggle = document.getElementById('sidebarToggle');
    const sidebarClose = document.getElementById('sidebarClose');
    const sidebarOverlay = document.getElementById('sidebarOverlay');

    function openSidebar() {
        if (!sidebar) return;
        sidebar.classList.add('show');
        sidebarOverlay.classList.add('show');
        document.body.classList.add('sidebar-open');
    }

    function closeSidebar() {
        if (!sidebar) return;
        sidebar.classList.remove('show');
        sidebarOverlay.classList.remove('show');
        document.body.classList.remove('sidebar-open');
    }

    if (sidebarToggle) {
        sidebarToggle.addEventListener('click', openSidebar);
    }
    if (sidebarClose) {
        sidebarClose.addEventListener('click', closeSidebar);
    }
    if (sidebarOverlay) {
        sidebarOverlay.addEventListener('click', closeSidebar);
    }
    // Cerrar el menú al pasar a escritorio
    window.addEventListener('resize', function() {
        if (window.innerWidth >= 992) {
            closeSidebar();
        }
    });
});

// Helpers para la vista previa de exportación
function cargarImagen(src) {
    return new Promise(function (resolve, reject) {
        const img = new Image();
        img.crossOrigin = 'anonymous';
        img.onload = function () {
            try {
                const canvas = document.createElement('canvas');
                canvas.width = img.naturalWidth || img.width;
                canvas.height = img.naturalHeight || img.height;
                const ctx = canvas.getContext('2d');
                ctx.drawImage(img, 0, 0);
                resolve({ dataUrl: canvas.toDataURL('image/png'), width: canvas.width, height: canvas.height });
            } catch (e) {
                reject(e);
            }
        };
        img.onerror = function () { reject(new Error('No se pudo cargar ' + src)); };
        img.src = src;
    });
}

function escapeHtmlExport(texto) {
    return String(texto == null ? '' : texto)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

function construirTablaPreview(headers, filas, maxFilas) {
    maxFilas = maxFilas || 50;
    let html = '<div style="background:#ffffff;border:1px solid #cbd5e1;border-radius:0;overflow:auto;max-height:360px;font-family:Calibri,Segoe UI,Arial,sans-serif;font-size:11px;border-top:none;border-bottom:none;">';
    html += '<div style="background:linear-gradient(90deg,#004d3d,#006b55);color:#fff;padding:6px 12px;font-weight:600;font-size:11px;display:flex;align-items:center;gap:6px;">' +
        '<i style="font-style:normal;">📊</i> Hoja1 — Vista previa</div>';
    html += '<table style="border-collapse:collapse;width:100%;table-layout:auto;">';
    if (headers && headers.length) {
        html += '<thead><tr>';
        headers.forEach(function (h) {
            html += '<th style="background:#004d3d;color:#fff;border:1px solid #00382b;padding:6px 10px;font-weight:600;white-space:nowrap;text-align:left;">' + escapeHtmlExport(h) + '</th>';
        });
        html += '</tr></thead>';
    }
    html += '<tbody>';
    const limite = Math.min(filas.length, maxFilas);
    for (let i = 0; i < limite; i++) {
        const bg = (i % 2 === 0) ? '#ffffff' : '#f1f5f9';
        html += '<tr style="background:' + bg + ';">';
        filas[i].forEach(function (c) {
            html += '<td style="border:1px solid #e2e8f0;padding:5px 10px;white-space:nowrap;max-width:240px;overflow:hidden;text-overflow:ellipsis;color:#1e293b;">' + escapeHtmlExport(c) + '</td>';
        });
        html += '</tr>';
    }
    html += '</tbody></table></div>';
    if (filas.length > maxFilas) {
        html += '<p style="color:#64748b;font-size:11px;margin-top:6px;margin-bottom:0;">… y ' + (filas.length - maxFilas) + ' filas más (se exportarán todas).</p>';
    }
    return html;
}

// Función para exportar varias tablas a CSV en un solo archivo (con vista previa)
function exportMultipleTablesToCSV(tableIds, filename) {
    const sections = (tableIds || []).map(function (id) {
        const table = document.getElementById(id);
        let headers = null;
        const rows = [];
        if (table) {
            table.querySelectorAll('tr').forEach(function (row) {
                const ocultaPorFiltro = row.style.display === 'none' && !row.classList.contains('pagina-oculta');
                if (ocultaPorFiltro || row.id === 'filaSinResultados' || row.classList.contains('fila-mensaje')) return;
                const cols = row.querySelectorAll('td, th');
                if (!cols.length) return;
                const values = Array.from(cols).map(function (col) { return col.innerText.trim(); });
                if (row.querySelector('th')) {
                    if (!headers) headers = values;
                } else {
                    rows.push(values);
                }
            });
        }
        return { id: id, headers: headers, rows: rows };
    });

    async function descargarCSV() {
        const fecha = new Date().toLocaleDateString('es-ES', { year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit' });
        const xlsFilename = filename.replace(/\.csv$/i, '.xls');
        let html = '<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns="http://www.w3.org/TR/REC-html40">';
        html += '<head><meta charset="utf-8"><style>';
        html += 'body{font-family:Calibri,Arial,sans-serif;font-size:11px;}';
        html += '.hdr{background:linear-gradient(90deg,#00382b,#004d3d);color:#fff;padding:10px 14px;}';
        html += '.hdr td{color:#fff;border:none;}';
        html += 'table{border-collapse:collapse;width:100%;}';
        html += 'th{background:#004d3d;color:#fff;border:1px solid #00382b;padding:6px 10px;font-weight:bold;}';
        html += 'td{border:1px solid #e2e8f0;padding:5px 10px;}';
        html += 'tr:nth-child(even) td{background:#f1f5f9;}';
        html += '.footer{background:#f1f5f9;padding:8px 12px;font-size:9px;color:#475569;}';
        html += '</style></head><body>';
        html += '<table style="width:100%;"><tr><td class="hdr" colspan="100%">';
        html += '<table style="width:100%;"><tr>';

        html += '<td><div style="font-weight:800;font-size:14px;">UNIVERSIDAD NACIONAL DEL CENTRO DEL PERÚ</div>';
        html += '<div style="font-size:10px;color:#a7f3d0;">Somos del centro, Somos del Perú</div>';
        html += '<div style="font-size:12px;color:#fde68a;font-weight:600;margin-top:4px;">Exportación a Excel</div></td>';
        html += '<td style="text-align:right;font-size:9px;color:#cbd5e1;">Generado el<br>' + fecha + '</td>';
        html += '</tr></table></td></tr></table>';

        html += bloquePersonaDownloadExcel();

        sections.forEach(function (sec, idx) {
            if (idx > 0) html += '<br>';
            html += '<table>';
            if (sec.headers) {
                html += '<tr>' + sec.headers.map(function (h) { return '<th>' + escapeHtmlExport(h) + '</th>'; }).join('') + '</tr>';
            }
            sec.rows.forEach(function (r, i) {
                const bg = (i % 2 === 0) ? '#ffffff' : '#f1f5f9';
                html += '<tr>' + r.map(function (c) { return '<td style="background:' + bg + ';">' + escapeHtmlExport(c) + '</td>'; }).join('') + '</tr>';
            });
            html += '</table>';
        });

        html += '<table style="width:100%;margin-top:10px;"><tr><td class="footer">';
        html += '© 2026 Sistema de Préstamo de Equipos UNCP &nbsp;·&nbsp; Reporte Generado: ' + fecha;
        html += '</td></tr></table>';
        html += '</body></html>';

        const blob = new Blob([html], { type: 'application/vnd.ms-excel;charset=utf-8;' });
        const link = document.createElement('a');
        if (navigator.msSaveBlob) {
            navigator.msSaveBlob(blob, xlsFilename);
        } else {
            link.href = URL.createObjectURL(blob);
            link.download = xlsFilename;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
    }

    if (typeof window.Swal !== 'undefined') {
        let previewHtml = '';
        sections.forEach(function (sec, idx) {
            if (idx > 0) previewHtml += '<div style="margin-top:12px;"></div>';
            previewHtml += construirTablaPreview(sec.headers || [], sec.rows);
        });
        const totalFilas = sections.reduce(function (a, s) { return a + s.rows.length; }, 0);
        Swal.fire({
            title: 'Vista previa - Exportar a Excel',
            html: encabezadoPreviewExcel('Exportación a Excel') + bloquePersonaPreviewExcel() + previewHtml + '<p class="text-muted mt-3 mb-0">Se exportarán <strong>' + totalFilas + '</strong> filas visibles en total.</p>' + piePreviewExcel(),
            width: '80%',
            showCancelButton: true,
            confirmButtonText: '<i class="ri-download-2-line me-1"></i> Descargar Excel',
            cancelButtonText: 'Cancelar',
            customClass: { popup: 'swal-uncp-popup' }
        }).then(function (result) {
            if (result.isConfirmed) descargarCSV();
        });
    } else {
        descargarCSV();
    }
}

function urlLogoUncp() {
    const meta = document.querySelector('meta[name="ctx"]');
    const ctx = meta ? (meta.getAttribute('content') || '') : '';
    return ctx + '/assets/img/reporte-logo.png';
}

function encabezadoPreviewExcel(titulo) {
    const fecha = new Date().toLocaleDateString('es-ES', { year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit' });
    return '<div style="display:flex;align-items:center;gap:12px;padding:10px 14px;border-radius:10px 10px 0 0;background:linear-gradient(90deg,#00382b,#004d3d);color:#fff;margin-bottom:0;">' +
        '<div style="line-height:1.2;flex:1;">' +
            '<div style="font-weight:800;font-size:14px;letter-spacing:0.5px;">UNIVERSIDAD NACIONAL DEL CENTRO DEL PERÚ</div>' +
            '<div style="font-size:10px;color:#a7f3d0;margin-top:2px;">Somos del centro, Somos del Perú</div>' +
            '<div style="font-size:12px;color:#fde68a;font-weight:600;margin-top:4px;">' + escapeHtmlExport(titulo || 'Exportación a Excel') + '</div>' +
        '</div>' +
        '<div style="text-align:right;font-size:9px;color:#cbd5e1;">Generado el<br>' + fecha + '</div>' +
    '</div>';
}

function piePreviewExcel() {
    const fecha = new Date().toLocaleDateString('es-ES', { year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit' });
    return '<div style="margin-top:10px;padding:8px 12px;border-radius:0 0 10px 10px;background:#f1f5f9;font-size:9px;color:#475569;display:flex;justify-content:space-between;align-items:center;">' +
        '<span>© 2026 Sistema de Préstamo de Equipos UNCP</span>' +
        '<span>Reporte Generado: ' + fecha + '</span>' +
    '</div>';
}

function bloquePersonaPreviewExcel() {
    const p = (typeof window.reportePersona !== 'undefined') ? window.reportePersona : null;
    if (!p) return '';
    let html = '<div style="background:#f8fafc;padding:10px 14px;border:1px solid #cbd5e1;border-top:none;font-size:11px;">';
    html += '<div style="font-weight:700;font-size:12px;color:#004d3d;margin-bottom:4px;">' + escapeHtmlExport(p.nombre || '') + '</div>';
    html += '<div style="color:#475569;font-size:10px;">' + escapeHtmlExport(p.universidad || '') + '</div>';
    html += '<table style="margin-top:6px;border-collapse:collapse;width:100%;font-size:10px;">';
    if (p.dni) html += '<tr><td style="padding:2px 6px;color:#64748b;width:120px;">DNI</td><td style="padding:2px 6px;">' + escapeHtmlExport(p.dni) + '</td></tr>';
    if (p.celular) html += '<tr><td style="padding:2px 6px;color:#64748b;">Celular</td><td style="padding:2px 6px;">' + escapeHtmlExport(p.celular) + '</td></tr>';
    if (p.correo) html += '<tr><td style="padding:2px 6px;color:#64748b;">Correo Electrónico</td><td style="padding:2px 6px;">' + escapeHtmlExport(p.correo) + '</td></tr>';
    if (p.fechaNacimiento) html += '<tr><td style="padding:2px 6px;color:#64748b;">Fecha de Nacimiento</td><td style="padding:2px 6px;">' + escapeHtmlExport(p.fechaNacimiento) + '</td></tr>';
    else if (p.fechaRegistro) html += '<tr><td style="padding:2px 6px;color:#64748b;">Fecha de Registro</td><td style="padding:2px 6px;">' + escapeHtmlExport(p.fechaRegistro) + '</td></tr>';
    html += '</table></div>';
    return html;
}

function bloquePersonaDownloadExcel() {
    const p = (typeof window.reportePersona !== 'undefined') ? window.reportePersona : null;
    if (!p) return '';
    let html = '<table style="width:100%;margin-bottom:10px;"><tr><td style="background:#f8fafc;padding:10px 14px;border:1px solid #cbd5e1;">';
    html += '<div style="font-weight:700;font-size:12px;color:#004d3d;">' + escapeHtmlExport(p.nombre || '') + '</div>';
    html += '<div style="color:#475569;font-size:10px;">' + escapeHtmlExport(p.universidad || '') + '</div>';
    html += '<table style="margin-top:6px;border-collapse:collapse;font-size:10px;">';
    if (p.dni) html += '<tr><td style="padding:2px 6px;color:#64748b;width:120px;">DNI</td><td style="padding:2px 6px;">' + escapeHtmlExport(p.dni) + '</td></tr>';
    if (p.celular) html += '<tr><td style="padding:2px 6px;color:#64748b;">Celular</td><td style="padding:2px 6px;">' + escapeHtmlExport(p.celular) + '</td></tr>';
    if (p.correo) html += '<tr><td style="padding:2px 6px;color:#64748b;">Correo Electrónico</td><td style="padding:2px 6px;">' + escapeHtmlExport(p.correo) + '</td></tr>';
    if (p.fechaNacimiento) html += '<tr><td style="padding:2px 6px;color:#64748b;">Fecha de Nacimiento</td><td style="padding:2px 6px;">' + escapeHtmlExport(p.fechaNacimiento) + '</td></tr>';
    else if (p.fechaRegistro) html += '<tr><td style="padding:2px 6px;color:#64748b;">Fecha de Registro</td><td style="padding:2px 6px;">' + escapeHtmlExport(p.fechaRegistro) + '</td></tr>';
    html += '</table></td></tr></table>';
    return html;
}

// Función para exportar tablas a Excel con formato (vista previa antes de descargar)
async function exportTableToCSV(tableId, filename) {
    const table = document.getElementById(tableId);
    if (!table) return;

    // Recolectar encabezados y filas visibles (mismo criterio que la exportación)
    let headers = null;
    const rowsData = [];
    table.querySelectorAll('tr').forEach(function (row) {
        const ocultaPorFiltro = row.style.display === 'none' && !row.classList.contains('pagina-oculta');
        if (ocultaPorFiltro || row.id === 'filaSinResultados' || row.classList.contains('fila-mensaje')) return;
        const cols = row.querySelectorAll('td, th');
        if (!cols.length) return;
        const values = Array.from(cols).map(function (col) { return col.innerText.trim(); });
        if (row.querySelector('th')) {
            if (!headers) headers = values;
        } else {
            rowsData.push(values);
        }
    });

    async function descargarCSV() {
        const fecha = new Date().toLocaleDateString('es-ES', { year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit' });
        const xlsFilename = filename.replace(/\.csv$/i, '.xls');
        let html = '<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns="http://www.w3.org/TR/REC-html40">';
        html += '<head><meta charset="utf-8"><style>';
        html += 'body{font-family:Calibri,Arial,sans-serif;font-size:11px;}';
        html += '.hdr{background:linear-gradient(90deg,#00382b,#004d3d);color:#fff;padding:10px 14px;}';
        html += 'table{border-collapse:collapse;width:100%;}';
        html += 'th{background:#004d3d;color:#fff;border:1px solid #00382b;padding:6px 10px;font-weight:bold;}';
        html += 'td{border:1px solid #e2e8f0;padding:5px 10px;}';
        html += 'tr:nth-child(even) td{background:#f1f5f9;}';
        html += '.footer{background:#f1f5f9;padding:8px 12px;font-size:9px;color:#475569;}';
        html += '</style></head><body>';
        html += '<table style="width:100%;"><tr><td class="hdr" colspan="100%">';
        html += '<table style="width:100%;"><tr>';

        html += '<td><div style="font-weight:800;font-size:14px;">UNIVERSIDAD NACIONAL DEL CENTRO DEL PERÚ</div>';
        html += '<div style="font-size:10px;color:#a7f3d0;">Somos del centro, Somos del Perú</div>';
        html += '<div style="font-size:12px;color:#fde68a;font-weight:600;margin-top:4px;">Exportación a Excel</div></td>';
        html += '<td style="text-align:right;font-size:9px;color:#cbd5e1;">Generado el<br>' + fecha + '</td>';
        html += '</tr></table></td></tr></table>';

        html += bloquePersonaDownloadExcel();

        html += '<table>';
        if (headers) html += '<tr>' + headers.map(function (h) { return '<th>' + escapeHtmlExport(h) + '</th>'; }).join('') + '</tr>';
        rowsData.forEach(function (r, i) {
            const bg = (i % 2 === 0) ? '#ffffff' : '#f1f5f9';
            html += '<tr>' + r.map(function (c) { return '<td style="background:' + bg + ';">' + escapeHtmlExport(c) + '</td>'; }).join('') + '</tr>';
        });
        html += '</table>';

        html += '<table style="width:100%;margin-top:10px;"><tr><td class="footer">';
        html += '© 2026 Sistema de Préstamo de Equipos UNCP &nbsp;·&nbsp; Reporte Generado: ' + fecha;
        html += '</td></tr></table>';
        html += '</body></html>';

        const blob = new Blob([html], { type: 'application/vnd.ms-excel;charset=utf-8;' });
        const link = document.createElement('a');
        if (navigator.msSaveBlob) {
            navigator.msSaveBlob(blob, xlsFilename);
        } else {
            link.href = URL.createObjectURL(blob);
            link.download = xlsFilename;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
    }

    if (typeof window.Swal !== 'undefined') {
        const previewHtml = construirTablaPreview(headers || [], rowsData);
        Swal.fire({
            title: 'Vista previa - Exportar a Excel',
            html: encabezadoPreviewExcel('Exportación a Excel') + bloquePersonaPreviewExcel() + previewHtml + '<p class="text-muted mt-3 mb-0">Se exportarán <strong>' + rowsData.length + '</strong> filas visibles.</p>' + piePreviewExcel(),
            width: '80%',
            showCancelButton: true,
            confirmButtonText: '<i class="ri-download-2-line me-1"></i> Descargar Excel',
            cancelButtonText: 'Cancelar',
            customClass: { popup: 'swal-uncp-popup' }
        }).then(function (result) {
            if (result.isConfirmed) descargarCSV();
        });
    } else {
        descargarCSV();
    }
}

// ===================================================================
// Exportación a PDF con el diseño de "Reporte UNCP":
//  - Encabezado con logo, nombre de la universidad y lema en TODAS las páginas
//  - Marca de agua (logo UNCP) de fondo en TODAS las páginas
//  - Bloque de datos de la persona (avatar, nombre, DNI, celular, correo...)
//  - Tabla limpia (sin relleno) para que la marca de agua se vea a través
//  - Pie con copyright, fecha de generación y número de página
// ===================================================================
function fechaReportePdf() {
    const d = new Date();
    const p = function (n) { return String(n).padStart(2, '0'); };
    return d.getFullYear() + '-' + p(d.getMonth() + 1) + '-' + p(d.getDate()) + ' ' +
           p(d.getHours()) + ':' + p(d.getMinutes()) + ':' + p(d.getSeconds());
}

// Lee encabezados y filas visibles de una tabla HTML (sin la columna "Acciones")
function leerTablaParaPdf(tableId) {
    const table = document.getElementById(tableId);
    const head = [];
    const body = [];
    if (!table) return { head: head, body: body };

    let accionesIndex = -1;
    table.querySelectorAll('thead th').forEach(function (th, i) {
        const text = th.innerText.trim();
        if (text.toLowerCase() === 'acciones') { accionesIndex = i; return; }
        head.push(text);
    });
    table.querySelectorAll('tbody tr').forEach(function (tr) {
        const ocultaPorFiltro = tr.style.display === 'none' && !tr.classList.contains('pagina-oculta');
        if (ocultaPorFiltro || tr.id === 'filaSinResultados' || tr.classList.contains('fila-mensaje')) return;
        const cells = tr.querySelectorAll('td');
        if (!cells.length) return;
        const row = [];
        cells.forEach(function (td, i) {
            if (i === accionesIndex) return;
            row.push(td.innerText.trim().replace(/\s+/g, ' '));
        });
        if (row.length) body.push(row);
    });
    return { head: head, body: body };
}

// Avatar (birrete + persona) dibujado con formas vectoriales
function dibujarAvatarPdf(doc, cx, y) {
    const gris = [74, 74, 74];
    doc.setFillColor(gris[0], gris[1], gris[2]);
    // hombros: semielipse
    const rx = 13, ry = 9, cy = y + 32;
    const pts = [];
    for (let a = 180; a <= 360; a += 10) {
        const r = a * Math.PI / 180;
        pts.push([cx + rx * Math.cos(r), cy + ry * Math.sin(r)]);
    }
    const seg = [];
    for (let i = 1; i < pts.length; i++) seg.push([pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]]);
    doc.lines(seg, pts[0][0], pts[0][1], [1, 1], 'F', true);
    // cabeza
    doc.circle(cx, y + 15, 6.2, 'F');
    // birrete: base y tablero
    doc.rect(cx - 6, y + 8.5, 12, 4, 'F');
    doc.lines([[14, -5], [14, 5], [-14, 5]], cx - 14, y + 7, [1, 1], 'F', true);
    // borla
    doc.setDrawColor(gris[0], gris[1], gris[2]);
    doc.setLineWidth(0.6);
    doc.line(cx + 10, y + 8, cx + 10, y + 14);
}

async function generarPdfReporte(opts) {
    const tablas = opts.tablas || [];
    const persona = opts.persona || null;

    // Cargar logo y marca de agua (la marca de agua YA trae su transparencia)
    const metaCtx = document.querySelector('meta[name="ctx"]');
    const ctxBase = metaCtx ? (metaCtx.getAttribute('content') || '') : '';
    let logoImg = null;
    let watermarkImg = null;
    try { logoImg = await cargarImagen(ctxBase + '/assets/img/reporte-logo.png'); } catch (e) { /* sin logo */ }
    try { watermarkImg = await cargarImagen(ctxBase + '/assets/img/reporte-marca-agua.png'); } catch (e) { /* sin marca */ }

    const { jsPDF } = window.jspdf;
    const ancho = tablas.some(function (t) { return t.head.length > 5; });
    const doc = new jsPDF({ orientation: ancho ? 'landscape' : 'portrait', unit: 'mm', format: 'a4' });
    const pw = doc.internal.pageSize.getWidth();
    const ph = doc.internal.pageSize.getHeight();
    const MARGEN = 20;
    const VERDE = [19, 84, 57];
    const TEXTO = [37, 37, 37];
    const TOP = 36;          // donde empieza el contenido (debajo del encabezado)
    const BOTTOM = 26;       // espacio reservado para el pie
    const fechaGen = fechaReportePdf();

    // Encabezado + marca de agua; se dibuja una sola vez por página
    const paginasDecoradas = {};
    function decorarPagina() {
        const n = doc.internal.getCurrentPageInfo().pageNumber;
        if (paginasDecoradas[n]) return;
        paginasDecoradas[n] = true;

        if (watermarkImg && watermarkImg.dataUrl) {
            try {
                const wmW = Math.min(pw, ph) * 0.80;
                const wmH = wmW * (watermarkImg.height / watermarkImg.width);
                doc.addImage(watermarkImg.dataUrl, 'PNG', (pw - wmW) / 2, (ph - wmH) / 2 + 8, wmW, wmH);
            } catch (e) { console.error('watermark', e); }
        }
        if (logoImg && logoImg.dataUrl) {
            try { doc.addImage(logoImg.dataUrl, 'PNG', MARGEN, 6, 20, 20 * (logoImg.height / logoImg.width)); } catch (e) { console.error('logo', e); }
        }
        const cx = pw / 2 + 12;
        doc.setFont('helvetica', 'bold');
        doc.setFontSize(10.5);
        doc.setTextColor(TEXTO[0], TEXTO[1], TEXTO[2]);
        const titulo = 'UNIVERSIDAD NACIONAL DEL CENTRO DEL PERÚ';
        doc.text(titulo, cx, 13, { align: 'center' });
        const tw = doc.getTextWidth(titulo);
        doc.setDrawColor(VERDE[0], VERDE[1], VERDE[2]);
        doc.setLineWidth(0.5);
        doc.line(cx - tw / 2, 14.8, cx + tw / 2, 14.8);
        doc.setFontSize(7.5);
        doc.text('¡Somos del centro, Somos del Perú!', cx, 20, { align: 'center' });
        doc.setLineWidth(0.8);
        doc.line(0, 29, pw, 29);
    }

    decorarPagina();

    // Título principal
    let y = TOP + 8;
    let tituloPrincipal = opts.tituloPrincipal;
    if (!tituloPrincipal) {
        tituloPrincipal = persona ? 'REPORTE DE HISTORIAL DE PRÉSTAMOS'
            : (tablas.length === 1 ? String(tablas[0].title || 'REPORTE').toUpperCase() : 'REPORTE');
    }
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(14);
    doc.setTextColor(TEXTO[0], TEXTO[1], TEXTO[2]);
    doc.text(tituloPrincipal, pw / 2, y, { align: 'center' });
    y += 8;

    // Bloque de la persona: avatar + nombre a la izquierda, datos a la derecha
    if (persona) {
        const colIzq = MARGEN + (pw - 2 * MARGEN) * 0.25;
        dibujarAvatarPdf(doc, colIzq, y);
        doc.setFont('helvetica', 'bold');
        doc.setFontSize(9.5);
        doc.setTextColor(TEXTO[0], TEXTO[1], TEXTO[2]);
        const nombreLineas = doc.splitTextToSize(String(persona.nombre || '').toUpperCase(), 62);
        doc.text(nombreLineas, colIzq, y + 40, { align: 'center' });
        let yUni = y + 40 + nombreLineas.length * 4.6 + 3;
        const uniLineas = doc.splitTextToSize(String(persona.universidad || '').toUpperCase(), 62);
        doc.text(uniLineas, colIzq, yUni, { align: 'center' });
        const finIzq = yUni + uniLineas.length * 4.6;

        const filas = [];
        if (persona.dni) filas.push(['DNI', persona.dni]);
        if (persona.celular) filas.push(['Celular', persona.celular]);
        if (persona.correo) filas.push(['Correo Electrónico', persona.correo]);
        if (persona.fechaNacimiento) filas.push(['Fecha de Nacimiento', persona.fechaNacimiento]);
        else if (persona.fechaRegistro) filas.push(['Fecha de Registro', persona.fechaRegistro]);

        const xLabel = pw / 2 - 2;
        const xValor = xLabel + 36;
        const xFin = pw - MARGEN;
        let yf = y + 6;
        doc.setFontSize(9);
        filas.forEach(function (f) {
            doc.setFont('helvetica', 'bold');
            doc.text(f[0], xLabel, yf);
            doc.setFont('helvetica', 'bold');
            const valor = doc.splitTextToSize(String(f[1]), xFin - xValor);
            doc.text(valor, xValor, yf);
            yf += (valor.length - 1) * 4;
            doc.setDrawColor(VERDE[0], VERDE[1], VERDE[2]);
            doc.setLineWidth(0.5);
            doc.line(xLabel, yf + 2, xFin, yf + 2);
            yf += 8;
        });
        y = Math.max(finIzq, yf) + 8;
    } else {
        y += 2;
    }

    const mostrarSubtitulo = !!persona || tablas.length > 1;

    tablas.forEach(function (t) {
        if (mostrarSubtitulo) {
            if (y > ph - BOTTOM - 25) {
                doc.addPage();
                decorarPagina();
                y = TOP + 4;
            }
            doc.setFont('helvetica', 'bold');
            doc.setFontSize(11);
            doc.setTextColor(VERDE[0], VERDE[1], VERDE[2]);
            doc.text(t.title || '', MARGEN, y);
            y += 3;
        }

        const opcionesTabla = {
            head: [t.head],
            body: t.body,
            startY: y + 2,
            theme: 'plain',
            showHead: 'everyPage',
            margin: { top: TOP, bottom: BOTTOM, left: MARGEN, right: MARGEN },
            styles: {
                font: 'helvetica', fontSize: 9, textColor: TEXTO,
                cellPadding: { top: 1.3, bottom: 1.3, left: 1.5, right: 1.5 },
                lineWidth: 0, fillColor: false, overflow: 'linebreak'
            },
            headStyles: { fontStyle: 'bold', halign: 'center', fillColor: false, textColor: TEXTO, cellPadding: { top: 2, bottom: 2, left: 1.5, right: 1.5 } },
            bodyStyles: { halign: 'left', valign: 'middle' },
            willDrawPage: function () { decorarPagina(); },
            didDrawCell: function (data) {
                // Líneas del encabezado de la tabla: verde arriba, fina abajo
                if (data.section === 'head') {
                    doc.setDrawColor(VERDE[0], VERDE[1], VERDE[2]);
                    doc.setLineWidth(0.7);
                    doc.line(data.cell.x, data.cell.y, data.cell.x + data.cell.width, data.cell.y);
                    doc.setDrawColor(60, 60, 60);
                    doc.setLineWidth(0.25);
                    doc.line(data.cell.x, data.cell.y + data.cell.height, data.cell.x + data.cell.width, data.cell.y + data.cell.height);
                }
            }
        };

        if (typeof doc.autoTable === 'function') {
            doc.autoTable(opcionesTabla);
        } else if (typeof window.jspdf.autoTable === 'function') {
            window.jspdf.autoTable(doc, opcionesTabla);
        } else {
            throw new Error('El complemento de tablas para PDF no está disponible.');
        }
        y = (doc.lastAutoTable && doc.lastAutoTable.finalY) ? doc.lastAutoTable.finalY + 10 : y + 20;
    });

    // Pie de página en todas las páginas
    const total = doc.internal.getNumberOfPages();
    for (let i = 1; i <= total; i++) {
        doc.setPage(i);
        doc.setDrawColor(VERDE[0], VERDE[1], VERDE[2]);
        doc.setLineWidth(0.6);
        doc.line(0, ph - 19, pw, ph - 19);
        doc.setFont('helvetica', 'normal');
        doc.setFontSize(7.5);
        doc.setTextColor(TEXTO[0], TEXTO[1], TEXTO[2]);
        doc.text('Copyright © 2026 - Sistema de Préstamo de Equipos UNCP', pw / 2, ph - 14.5, { align: 'center' });
        doc.line(0, ph - 11.5, pw, ph - 11.5);
        doc.text('Reporte Generado: ' + fechaGen, pw / 2, ph - 6.5, { align: 'center' });
        doc.text('Página ' + i + ' de ' + total, pw - MARGEN, ph - 6.5, { align: 'right' });
    }
    return doc;
}

function avisoErrorPdf(titulo, texto) {
    if (typeof window.Swal !== 'undefined') {
        Swal.fire({ icon: 'warning', title: titulo, text: texto, confirmButtonColor: '#004d3d' });
    } else {
        alert(texto);
    }
}

function mostrarVistaPreviaPdf(doc, filename, textoPie) {
    const blob = doc.output('blob');
    const url = URL.createObjectURL(blob);

    if (typeof window.Swal !== 'undefined') {
        Swal.fire({
            title: 'Vista previa - Exportar a PDF',
            html: '<iframe src="' + url + '" style="width:100%;height:65vh;min-height:420px;border:1px solid #cbd5e1;border-radius:4px;background:#fff;"></iframe>' +
                  '<p class="text-muted mt-3 mb-0">' + textoPie + '</p>',
            width: '90%',
            showCancelButton: true,
            confirmButtonText: '<i class="ri-download-2-line me-1"></i> Descargar PDF',
            cancelButtonText: 'Cancelar',
            customClass: { popup: 'swal-uncp-popup' }
        }).then(function (result) {
            if (result.isConfirmed) {
                const link = document.createElement('a');
                link.href = url;
                link.download = filename;
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
            }
            URL.revokeObjectURL(url);
        });
    } else {
        doc.save(filename);
        URL.revokeObjectURL(url);
    }
}

function pdfDisponible() {
    if (!window.jspdf || typeof window.jspdf.jsPDF !== 'function') {
        avisoErrorPdf('Error', 'No se pudo cargar el generador de PDF. Verifica tu conexión a internet e inténtalo de nuevo.');
        return false;
    }
    return true;
}

async function exportarPdfReporte(tablas, filename, textoPie) {
    let doc;
    try {
        doc = await generarPdfReporte({
            tablas: tablas,
            persona: (typeof window.reportePersona !== 'undefined') ? window.reportePersona : null
        });
    } catch (err) {
        console.error('Error al generar el PDF:', err);
        avisoErrorPdf('Error al generar PDF', 'Ocurrió un error al generar el PDF. Intenta nuevamente o usa la exportación a Excel.');
        return;
    }
    mostrarVistaPreviaPdf(doc, filename, textoPie);
}

// Exportar varias tablas a PDF en un solo documento (con vista previa)
async function exportMultipleTablesToPDF(configs, filename) {
    configs = configs || [];
    if (!pdfDisponible()) return;
    const tablas = configs.map(function (cfg) {
        const datos = leerTablaParaPdf(cfg.id);
        return { title: cfg.title || '', head: datos.head, body: datos.body };
    });
    await exportarPdfReporte(tablas, filename, 'Se exportarán ' + (tablas.length > 1 ? 'ambas tablas' : 'la tabla') + '.');
}

// Exportar una tabla a PDF (vista previa real del documento antes de descargar)
async function exportTableToPDF(tableId, title, filename) {
    if (!document.getElementById(tableId)) return;
    if (!pdfDisponible()) return;
    const datos = leerTablaParaPdf(tableId);
    await exportarPdfReporte(
        [{ title: title, head: datos.head, body: datos.body }],
        filename,
        'Se exportarán <strong>' + datos.body.length + '</strong> filas visibles.'
    );
}
