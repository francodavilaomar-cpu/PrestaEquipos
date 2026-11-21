<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="f" uri="http://universidad.edu/presta/funciones" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<c:set var="esPrestamo" value="${tipoBoleta eq 'prestamo'}"/>
<c:set var="nro" value="${esPrestamo ? prestamo.id : solicitud.id}"/>
<c:set var="codigo" value="${esPrestamo ? 'BP' : 'BS'}-${f:fecha(emitidoEn, 'yyyy')}-${nro < 10 ? '0000' : (nro < 100 ? '000' : (nro < 1000 ? '00' : (nro < 10000 ? '0' : '')))}${nro}"/>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Boleta ${codigo}</title>
    <style>
        * { box-sizing: border-box; }
        body { margin: 0; background: #e5e7eb; font-family: "Segoe UI", Arial, sans-serif; color: #1f2937; }
        .barra { position: sticky; top: 0; z-index: 10; display: flex; gap: .5rem; align-items: center; justify-content: space-between;
                 padding: .6rem 1rem; background: #111827; color: #fff; flex-wrap: wrap; }
        .barra .titulo { font-weight: 600; font-size: .95rem; }
        .barra .acciones { display: flex; gap: .5rem; flex-wrap: wrap; }
        .barra button { border: 0; border-radius: .4rem; padding: .5rem .9rem; font-size: .875rem; font-weight: 600; cursor: pointer; color: #fff; }
        .b-print { background: #2563eb; } .b-pdf { background: #16a34a; } .b-close { background: #4b5563; }
        .barra button:disabled { opacity: .6; cursor: wait; }
        .hoja-wrap { padding: 1.5rem 1rem 2rem; overflow-x: auto; }
        .hoja { position: relative; width: 210mm; min-height: 148mm; margin: 0 auto; background: #fff; padding: 14mm 16mm;
                box-shadow: 0 4px 16px rgba(0,0,0,.2); overflow: hidden; }
        .marca { position: absolute; inset: 0; background: url('${ctx}/assets/img/reporte-marca-agua.png') center/60% no-repeat; opacity: .07; pointer-events: none; }
        .cabecera { display: flex; align-items: center; gap: 14px; border-bottom: 2px solid #1e3a8a; padding-bottom: 10px; position: relative; }
        .cabecera img { height: 62px; }
        .cabecera .uni { flex: 1; }
        .cabecera .uni b { display: block; font-size: 15px; color: #1e3a8a; letter-spacing: .3px; }
        .cabecera .uni span { font-size: 11px; color: #6b7280; }
        .nro { text-align: center; border: 1.5px solid #1e3a8a; border-radius: 6px; padding: 6px 12px; }
        .nro small { display: block; font-size: 10px; color: #6b7280; text-transform: uppercase; }
        .nro strong { font-size: 15px; color: #1e3a8a; }
        h1 { text-align: center; font-size: 17px; margin: 16px 0 12px; letter-spacing: 1px; text-transform: uppercase; position: relative; }
        .seccion { position: relative; margin-bottom: 12px; }
        .seccion h2 { font-size: 11px; text-transform: uppercase; letter-spacing: .8px; color: #fff; background: #1e3a8a; padding: 4px 8px; margin: 0; }
        table { width: 100%; border-collapse: collapse; font-size: 12.5px; }
        td { border: 1px solid #d1d5db; padding: 6px 8px; vertical-align: top; }
        td.k { width: 28%; background: #f3f4f6; font-weight: 600; color: #374151; }
        .estado { display: inline-block; padding: 1px 10px; border-radius: 999px; font-weight: 700; font-size: 11px; text-transform: uppercase; background: #e0e7ff; color: #3730a3; }
        .firmas { display: flex; gap: 40px; margin-top: 46px; position: relative; }
        .firmas div { flex: 1; text-align: center; border-top: 1px solid #111827; padding-top: 4px; font-size: 11.5px; }
        .pie { margin-top: 18px; font-size: 10.5px; color: #6b7280; text-align: center; position: relative; }
        @page { size: A4 portrait; margin: 0; }
        @media print {
            body { background: #fff; }
            .barra { display: none; }
            .hoja-wrap { padding: 0; }
            .hoja { box-shadow: none; margin: 0; width: 210mm; }
            * { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
        }
    </style>
</head>
<body>
<div class="barra">
    <span class="titulo">Vista previa · Boleta ${codigo}</span>
    <div class="acciones">
        <button type="button" class="b-print" id="btnImprimir">Imprimir</button>
        <button type="button" class="b-pdf" id="btnPdf">Descargar PDF</button>
        <button type="button" class="b-close" id="btnCerrar">Cerrar</button>
    </div>
</div>

<div class="hoja-wrap">
<div class="hoja" id="hoja">
    <div class="marca"></div>
    <div class="cabecera">
        <img src="${ctx}/assets/img/reporte-logo.png" alt="Logo" crossorigin="anonymous">
        <div class="uni">
            <b>UNIVERSIDAD NACIONAL DEL CENTRO DEL PERÚ</b>
            <span>Sistema de Préstamo de Equipos</span>
        </div>
        <div class="nro"><small>Boleta N.°</small><strong>${codigo}</strong></div>
    </div>

    <h1>Boleta de ${esPrestamo ? 'préstamo de equipo' : 'solicitud de equipo'}</h1>

    <div class="seccion">
        <h2>Datos del usuario</h2>
        <table>
            <tr><td class="k">Nombre</td><td>${f:h(duenoBoleta.nombre)}</td></tr>
            <tr><td class="k">DNI</td><td>${f:h(duenoBoleta.dni)}</td></tr>
            <tr><td class="k">Correo</td><td>${f:h(duenoBoleta.email)}</td></tr>
            <tr><td class="k">Celular</td><td>${f:h(duenoBoleta.celular)}</td></tr>
        </table>
    </div>

    <div class="seccion">
        <h2>Detalle ${esPrestamo ? 'del préstamo' : 'de la solicitud'}</h2>
        <table>
            <c:choose>
                <c:when test="${esPrestamo}">
                    <tr><td class="k">Equipo</td><td>${f:h(prestamo.equipoNombre)}</td></tr>
                    <tr><td class="k">Código de inventario</td><td>${f:h(prestamo.codigoInventario)}</td></tr>
                    <tr><td class="k">Fecha de préstamo</td><td>${f:fecha(prestamo.fechaPrestamo, 'dd/MM/yyyy HH:mm')}</td></tr>
                    <tr><td class="k">Devolución esperada</td><td>${f:fecha(prestamo.fechaDevolucionEsperada, 'dd/MM/yyyy')}</td></tr>
                    <tr><td class="k">Devuelto el</td><td>${empty prestamo.fechaDevolucionReal ? '— (aún en préstamo)' : f:fecha(prestamo.fechaDevolucionReal, 'dd/MM/yyyy HH:mm')}</td></tr>
                    <tr><td class="k">Estado</td><td><span class="estado">${empty prestamo.fechaDevolucionReal ? f:cap(prestamo.estado) : 'Devuelto'}</span></td></tr>
                    <tr><td class="k">Observaciones</td><td>${empty prestamo.observaciones ? '—' : f:h(prestamo.observaciones)}</td></tr>
                </c:when>
                <c:otherwise>
                    <tr><td class="k">Equipo solicitado</td><td>${f:h(solicitud.equipoSolicitado)}</td></tr>
                    <tr><td class="k">Fecha de solicitud</td><td>${f:fecha(solicitud.fechaSolicitud, 'dd/MM/yyyy HH:mm')}</td></tr>
                    <tr><td class="k">Período solicitado</td><td>Desde ${f:fecha(solicitud.fechaPrestamo, 'dd/MM/yyyy HH:mm')} hasta ${f:fecha(solicitud.fechaDevolucion, 'dd/MM/yyyy HH:mm')}</td></tr>
                    <tr><td class="k">Oficina destino</td><td>${f:h(solicitud.oficina)}</td></tr>
                    <tr><td class="k">Estado</td><td><span class="estado">${f:cap(solicitud.estado)}</span></td></tr>
                    <tr><td class="k">Observaciones</td><td>${empty solicitud.observaciones ? '—' : f:h(solicitud.observaciones)}</td></tr>
                </c:otherwise>
            </c:choose>
        </table>
    </div>

    <div class="firmas">
        <div>Firma del usuario<br><small>${f:h(duenoBoleta.nombre)}</small></div>
        <div>Firma del encargado</div>
    </div>
    <div class="pie">Emitido el ${f:fecha(emitidoEn, 'dd/MM/yyyy HH:mm')} por ${f:h(emitidoPor.nombre)} · Documento generado por el Sistema de Préstamo de Equipos</div>
</div>
</div>

<script src="https://cdn.jsdelivr.net/npm/html2canvas@1.4.1/dist/html2canvas.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/jspdf@2.5.1/dist/jspdf.umd.min.js"></script>
<script>
(function () {
    var cod = '${codigo}';
    document.getElementById('btnImprimir').addEventListener('click', function () { window.print(); });
    document.getElementById('btnCerrar').addEventListener('click', function () {
        if (window.parent && window.parent !== window && typeof window.parent.cerrarBoleta === 'function') {
            window.parent.cerrarBoleta();
        } else { window.close(); }
    });
    document.getElementById('btnPdf').addEventListener('click', function () {
        var btn = this;
        if (!window.html2canvas || !window.jspdf) { window.print(); return; }
        btn.disabled = true; btn.textContent = 'Generando…';
        html2canvas(document.getElementById('hoja'), { scale: 2, useCORS: true, backgroundColor: '#ffffff' }).then(function (canvas) {
            var pdf = new window.jspdf.jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });
            var w = 210, h = canvas.height * w / canvas.width;
            pdf.addImage(canvas.toDataURL('image/jpeg', 0.95), 'JPEG', 0, 0, w, Math.min(h, 297));
            pdf.save('boleta_' + cod + '.pdf');
        }).catch(function () { window.print(); })
          .finally(function () { btn.disabled = false; btn.textContent = 'Descargar PDF'; });
    });
})();
</script>
</body>
</html>
