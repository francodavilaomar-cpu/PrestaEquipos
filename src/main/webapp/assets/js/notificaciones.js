/**
 * Campana de notificaciones de la cabecera (admin y encargado).
 * Las pestañas "Todas" / "No leídas" filtran en el navegador y "Marcar todas como leídas"
 * avisa al servidor sin recargar la página.
 */
(function () {
    'use strict';

    var panel = document.getElementById('notificacionesAdmin');
    if (!panel) {
        return;
    }

    var lista = document.getElementById('listaNotificaciones');
    var vacio = document.getElementById('notificacionesVacio');
    var tituloVacio = vacio ? vacio.querySelector('[data-vacio-titulo]') : null;
    var textoVacio = vacio ? vacio.querySelector('[data-vacio-texto]') : null;
    var badge = document.getElementById('badgeNotificaciones');
    var resumen = document.getElementById('resumenNotificaciones');
    var botonMarcar = document.getElementById('marcarTodasNotificaciones');
    var tabs = Array.prototype.slice.call(panel.querySelectorAll('.notificaciones-tab'));
    var contadores = Array.prototype.slice.call(panel.querySelectorAll('[data-contador]'));
    var filtro = 'todas';

    var TEXTO_VACIO_TODAS = 'Aquí verás los avisos de tus solicitudes, préstamos y de la plataforma.';
    var TEXTO_VACIO_NO_LEIDAS = 'Ya revisaste todos tus avisos.';

    function items() {
        return lista ? Array.prototype.slice.call(lista.querySelectorAll('.notificacion-item')) : [];
    }

    function totalNoLeidas() {
        return items().filter(function (item) {
            return item.getAttribute('data-leida') !== 'true';
        }).length;
    }

    function pintarContadores() {
        var noLeidas = totalNoLeidas();
        contadores.forEach(function (contador) {
            var esNoLeidas = contador.getAttribute('data-contador') === 'no-leidas';
            contador.textContent = esNoLeidas ? noLeidas : items().length;
        });
        if (badge) {
            badge.textContent = noLeidas;
            badge.classList.toggle('hidden', noLeidas === 0);
        }
        if (resumen) {
            resumen.textContent = noLeidas + ' sin leer';
            resumen.classList.remove('text-danger');
        }
        if (botonMarcar) {
            botonMarcar.disabled = noLeidas === 0;
        }
    }

    function aplicarFiltro() {
        var visibles = 0;
        items().forEach(function (item) {
            var mostrar = filtro === 'todas' || item.getAttribute('data-leida') !== 'true';
            item.classList.toggle('hidden', !mostrar);
            if (mostrar) {
                visibles++;
            }
        });
        if (vacio) {
            vacio.classList.toggle('hidden', visibles > 0);
            if (visibles === 0 && tituloVacio && textoVacio) {
                var soloNoLeidas = filtro === 'no-leidas' && items().length > 0;
                tituloVacio.textContent = soloNoLeidas ? 'Sin notificaciones sin leer' : 'Sin notificaciones';
                textoVacio.textContent = soloNoLeidas ? TEXTO_VACIO_NO_LEIDAS : TEXTO_VACIO_TODAS;
            }
        }
    }

    function mostrarError(mensaje) {
        if (resumen) {
            resumen.textContent = mensaje;
            resumen.classList.add('text-danger');
        }
    }

    tabs.forEach(function (tab) {
        tab.addEventListener('click', function () {
            filtro = tab.getAttribute('data-filtro') || 'todas';
            tabs.forEach(function (otro) {
                var activo = otro === tab;
                otro.classList.toggle('active', activo);
                otro.setAttribute('aria-selected', activo ? 'true' : 'false');
            });
            aplicarFiltro();
        });
    });

    if (botonMarcar) {
        botonMarcar.addEventListener('click', function () {
            if (botonMarcar.disabled || totalNoLeidas() === 0) {
                return;
            }
            var token = document.querySelector('meta[name="csrf"]');
            var etiqueta = botonMarcar.innerHTML;
            botonMarcar.disabled = true;
            botonMarcar.innerHTML = '<span class="spinner-border spinner-border-sm me-1" role="status" aria-hidden="true"></span>Marcando...';

            var datos = new URLSearchParams();
            datos.append('accion', 'marcar_todas');
            datos.append('csrf_token', token ? token.getAttribute('content') : '');

            fetch(panel.getAttribute('data-url-marcar'), {
                method: 'POST',
                body: datos.toString(),
                credentials: 'same-origin',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                    'X-Requested-With': 'XMLHttpRequest',
                    'Accept': 'application/json'
                }
            })
                .then(function (r) {
                    return r.json().catch(function () {
                        return { ok: false, mensaje: 'No se pudo marcar las notificaciones.' };
                    });
                })
                .then(function (data) {
                    if (!data || !data.ok) {
                        throw new Error((data && data.mensaje) || 'No se pudo marcar las notificaciones.');
                    }
                    items().forEach(function (item) {
                        item.setAttribute('data-leida', 'true');
                        item.classList.remove('no-leida');
                    });
                    pintarContadores();
                    aplicarFiltro();
                })
                .catch(function (error) {
                    mostrarError(error.message || 'No se pudo marcar las notificaciones.');
                })
                .finally(function () {
                    botonMarcar.innerHTML = etiqueta;
                    botonMarcar.disabled = totalNoLeidas() === 0;
                });
        });
    }

    pintarContadores();
    aplicarFiltro();

    // Notificaciones en tiempo real: consulta periódica sin recargar la página.
    var metaCtx = document.querySelector('meta[name="ctx"]');
    var ctx = metaCtx ? metaCtx.getAttribute('content') : '';
    var urlJson = ctx + '/notificaciones?ajax=1';

    function escHtml(v) {
        return String(v == null ? '' : v)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function renderNotificaciones(data) {
        if (!lista || !data) return;
        var itemsData = data.items || [];
        lista.innerHTML = '';
        itemsData.forEach(function (n) {
            var a = document.createElement('a');
            a.className = 'notificacion-item ' + (n.leida ? '' : 'no-leida');
            a.href = ctx + '/notificaciones/ir?clave=' + encodeURIComponent(n.clave || '') + '&url=' + encodeURIComponent(n.enlace || '');
            a.setAttribute('data-leida', n.leida ? 'true' : 'false');
            a.setAttribute('data-tipo', n.tipo || '');
            a.innerHTML =
                '<span class="notificacion-icono text-' + escHtml(n.tono || 'primary') + '"><i class="' + escHtml(n.icono || 'ri-notification-3-line') + '"></i></span>' +
                '<span class="notificacion-texto">' +
                    '<span class="notificacion-titulo">' + escHtml(n.titulo) + '</span>' +
                    '<span class="notificacion-mensaje">' + escHtml(n.mensaje) + '</span>' +
                    '<span class="notificacion-fecha">' + escHtml(n.fecha) + '</span>' +
                '</span>' +
                '<span class="notificacion-punto" aria-hidden="true"></span>';
            lista.appendChild(a);
        });
        if (vacio) {
            vacio.classList.toggle('hidden', itemsData.length > 0);
        }
        pintarContadores();
        aplicarFiltro();
    }

    function actualizarNotificaciones() {
        fetch(urlJson, {
            credentials: 'same-origin',
            headers: { 'Accept': 'application/json' }
        })
            .then(function (r) { return r.json(); })
            .then(renderNotificaciones)
            .catch(function () { /* silencioso */ });
    }

    setInterval(actualizarNotificaciones, 10000);
})();
