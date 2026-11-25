(function () {
    'use strict';
    const root = document.getElementById('otiAiRoot');
    if (!root) return;
    const ctx = root.dataset.ctx || '';
    const csrf = root.dataset.csrf || '';
    const role = root.dataset.role || 'usuario';
    const panel = document.getElementById('otiAiPanel');
    const toggle = document.getElementById('otiAiToggle');
    const close = document.getElementById('otiAiClose');
    const messages = document.getElementById('otiAiMessages');
    const form = document.getElementById('otiAiForm');
    const input = document.getElementById('otiAiInput');
    const send = document.getElementById('otiAiSend');
    const mic = document.getElementById('otiAiMic');
    const speak = document.getElementById('otiAiSpeak');
    let conversationId = sessionStorage.getItem('otiAiConversation') || '';
    let lastAssistantText = '';

    function openPanel() {
        panel.classList.add('is-open');
        panel.setAttribute('aria-hidden', 'false');
        toggle.setAttribute('aria-expanded', 'true');
        setTimeout(() => input.focus(), 80);
    }
    function closePanel() {
        panel.classList.remove('is-open');
        panel.setAttribute('aria-hidden', 'true');
        toggle.setAttribute('aria-expanded', 'false');
    }
    toggle.addEventListener('click', () => panel.classList.contains('is-open') ? closePanel() : openPanel());
    close.addEventListener('click', closePanel);

    function addMessage(text, who, modeLabel) {
        const bubble = document.createElement('div');
        bubble.className = 'oti-ai-message ' + who;
        let visibleText = text || '';
        const abreSolicitud = who === 'assistant' && visibleText.includes('/equipos/listar');
        const abreMantenimiento = who === 'assistant' && visibleText.includes('/ia/mantenimiento');
        visibleText = visibleText.replace(/\s*Abre el módulo:\s*\/equipos\/listar/gi, '').replace(/\s*Abre el módulo:\s*\/ia\/mantenimiento/gi, '').trim();
        bubble.textContent = visibleText;
        const time = document.createElement('small');
        time.textContent = new Date().toLocaleTimeString('es-PE', {hour: '2-digit', minute: '2-digit'}) + (modeLabel ? ' · ' + modeLabel : '');
        bubble.appendChild(time);
        if (abreSolicitud) {
            const action = document.createElement('button'); action.type = 'button'; action.className = 'oti-ai-shortcut'; action.textContent = 'Abrir formulario de solicitud';
            action.addEventListener('click', () => window.abrirModal ? window.abrirModal(ctx + '/equipos/solicitud?modal=1', 'Formulario de Solicitud de Equipo', {textoBoton: 'Enviar Solicitud'}) : (window.location.href = ctx + '/equipos/listar'));
            bubble.appendChild(action);
        }
        if (abreMantenimiento) {
            const link = document.createElement('a'); link.className = 'oti-ai-shortcut'; link.href = ctx + '/ia/mantenimiento'; link.textContent = 'Abrir mantenimiento inteligente'; bubble.appendChild(link);
        }
        messages.appendChild(bubble);
        messages.scrollTop = messages.scrollHeight;
        return bubble;
    }
    function addResults(equipos, emptyText) {
        if (!equipos || !equipos.length) {
            addMessage(emptyText || 'No encontré equipos disponibles que coincidan con esa búsqueda.', 'assistant');
            return;
        }
        const intro = document.createElement('div');
        intro.className = 'oti-ai-message assistant';
        intro.textContent = 'Encontré estas opciones en el inventario:';
        equipos.forEach(eq => {
            const card = document.createElement('div');
            card.className = 'oti-ai-result';
            const title = document.createElement('strong');
            title.textContent = eq.nombre || 'Equipo';
            const detail = document.createElement('span');
            detail.textContent = [eq.codigo, eq.categoria, eq.estado, eq.ubicacion].filter(Boolean).join(' · ');
            card.append(title, detail);
            const action = document.createElement('button');
            action.type = 'button';
            action.className = 'oti-ai-shortcut';
            action.textContent = 'Solicitar este equipo';
            action.addEventListener('click', () => {
                const texto = (eq.nombre || '') + (eq.codigo ? ' (' + eq.codigo + ')' : '');
                if (window.abrirModal) {
                    window.abrirModal(ctx + '/equipos/solicitud?modal=1&busqueda=' + encodeURIComponent(texto),
                        'Formulario de Solicitud de Equipo', {textoBoton: 'Enviar Solicitud'});
                } else {
                    window.location.href = ctx + '/equipos/listar';
                }
            });
            card.appendChild(action);
            intro.appendChild(card);
        });
        messages.appendChild(intro);
        messages.scrollTop = messages.scrollHeight;
    }
    function showTyping() {
        const el = document.createElement('div'); el.className = 'oti-ai-typing'; el.textContent = 'OTI está pensando…';
        messages.appendChild(el); messages.scrollTop = messages.scrollHeight; return el;
    }
    async function postChat(text) {
        const question = (text || '').trim();
        if (!question) return;
        addMessage(question, 'user');
        input.value = '';
        send.disabled = true;
        const typing = showTyping();
        try {
            const body = new URLSearchParams({csrf_token: csrf, mensaje: question, conversacion_id: conversationId});
            const response = await fetch(ctx + '/ia/chat', {method: 'POST', headers: {'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'}, body});
            const data = await response.json();
            typing.remove();
            if (!response.ok || !data.ok) throw new Error(data.mensaje || 'No se pudo responder.');
            conversationId = String(data.conversacionId || conversationId);
            if (conversationId) sessionStorage.setItem('otiAiConversation', conversationId);
            lastAssistantText = data.respuesta || '';
            addMessage(lastAssistantText, 'assistant', data.modo === 'ia' ? 'IA conectada' : 'Ayuda integrada');
            if (/\b(buscar|disponible|laptop|proyector|computadora|impresora)\b/i.test(question)) {
                try {
                    const r = await fetch(ctx + '/ia/buscar?q=' + encodeURIComponent(question), {headers: {'Accept': 'application/json'}});
                    const d = await r.json();
                    if (d.ok && d.equipos && d.equipos.length) addResults(d.equipos);
                } catch (_) { /* la respuesta conversacional sigue disponible */ }
            }
        } catch (error) {
            typing.remove();
            addMessage(error.message || 'No pude conectar con el asistente. Inténtalo otra vez.', 'assistant');
        } finally {
            send.disabled = false; input.focus();
        }
    }
    form.addEventListener('submit', event => { event.preventDefault(); postChat(input.value); });

    document.querySelectorAll('[data-oti-ai-action]').forEach(button => {
        button.addEventListener('click', async () => {
            const action = button.dataset.otiAiAction;
            openPanel();
            if (action === 'recomendaciones') {
                addMessage('Muéstrame equipos recomendados.', 'user');
                try {
                    const r = await fetch(ctx + '/ia/recomendaciones'); const d = await r.json();
                    addResults(d.equipos, 'No hay equipos disponibles para recomendar por ahora.');
                } catch (_) { addMessage('No pude cargar las recomendaciones.', 'assistant'); }
            } else if (action === 'alertas') {
                try {
                    const r = await fetch(ctx + '/ia/alertas'); const d = await r.json();
                    if (role === 'usuario') {
                        if (!d.prestamos || !d.prestamos.length) addMessage('No tienes préstamos activos registrados.', 'assistant');
                        else d.prestamos.forEach(p => addMessage((p.vencido ? 'ATENCIÓN: devolución vencida. ' : 'Devolución pendiente. ') + p.equipo + ' (' + p.codigo + '). Fecha: ' + p.fechaDevolucion, 'assistant'));
                    } else addMessage('Actualmente hay ' + d.prestamosVencidos + ' préstamos vencidos. Revisa el módulo Vencidos para consultar el detalle.', 'assistant');
                } catch (_) { addMessage('No pude consultar tus alertas en este momento.', 'assistant'); }
            } else if (action === 'solicitud') {
                addMessage('Te abriré el formulario oficial. Completa la oficina, las fechas y el motivo; la solicitud quedará pendiente de revisión por la OTI.', 'assistant');
                if (window.abrirModal) window.abrirModal(ctx + '/equipos/solicitud?modal=1', 'Formulario de Solicitud de Equipo', {textoBoton: 'Enviar Solicitud'});
                else window.location.href = ctx + '/equipos/listar';
            } else if (action === 'notificaciones') {
                postChat('Explícame mis notificaciones y qué significan los estados de mis solicitudes y préstamos.');
            } else if (action === 'buscar') {
                input.placeholder = 'Ej.: laptop, proyector, impresora…'; input.focus();
                addMessage('Escribe el equipo, categoría o código que necesitas. Buscaré coincidencias en el inventario.', 'assistant');
            }
        });
    });

    if (mic) {
        const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
        if (!SpeechRecognition) mic.title = 'El navegador no admite reconocimiento de voz';
        mic.addEventListener('click', () => {
            if (!SpeechRecognition) { addMessage('El reconocimiento de voz no está disponible en este navegador. Puedes escribir tu consulta.', 'assistant'); return; }
            const recognition = new SpeechRecognition();
            recognition.lang = 'es-PE'; recognition.interimResults = false; recognition.maxAlternatives = 1;
            mic.disabled = true; mic.classList.add('opacity-50');
            recognition.onresult = event => { input.value = event.results[0][0].transcript; postChat(input.value); };
            recognition.onerror = () => addMessage('No pude reconocer el audio. Verifica el permiso del micrófono e inténtalo nuevamente.', 'assistant');
            recognition.onend = () => { mic.disabled = false; mic.classList.remove('opacity-50'); };
            try { recognition.start(); } catch (_) { mic.disabled = false; mic.classList.remove('opacity-50'); }
        });
    }
    if (speak) speak.addEventListener('click', () => {
        if (!lastAssistantText || !('speechSynthesis' in window)) { addMessage('La lectura por voz no está disponible en este navegador.', 'assistant'); return; }
        window.speechSynthesis.cancel();
        const utterance = new SpeechSynthesisUtterance(lastAssistantText);
        utterance.lang = 'es-PE'; utterance.rate = 1; window.speechSynthesis.speak(utterance);
    });

    if (!messages.children.length) addMessage('¡Hola! Soy el Asistente Inteligente OTI. Puedo ayudarte a buscar equipos, preparar solicitudes, revisar devoluciones y entender las notificaciones. También puedes usar el micrófono para hablar conmigo.', 'assistant');
})();
