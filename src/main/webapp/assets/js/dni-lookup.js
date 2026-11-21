// Consulta de nombres y apellidos por DNI (botón "Buscar" del formulario de usuario).
// Funciona en la página normal y dentro del modal: los eventos se delegan en "document".
(function () {
    'use strict';

    const CTX = (document.querySelector('meta[name="ctx"]') || {}).content || '';

    function elementos(raiz) {
        return {
            inputDni: raiz.querySelector('#dni'),
            inputNombre: raiz.querySelector('#nombre'),
            inputNombreDni: raiz.querySelector('#nombre_dni'),
            inputEmail: raiz.querySelector('#email'),
            inputCelular: raiz.querySelector('#celular'),
            btnBuscar: raiz.querySelector('#btn-buscar-dni'),
            searchIcon: raiz.querySelector('#dni-search-icon'),
            searchText: raiz.querySelector('#dni-search-text'),
            feedback: raiz.querySelector('#dni-feedback'),
            avisoNombre: raiz.querySelector('#nombre-dni-aviso')
        };
    }

    async function consultarDni(raiz) {
        const el = elementos(raiz);
        if (!el.inputDni || !el.btnBuscar || !el.feedback) {
            return;
        }
        const dni = el.inputDni.value.trim();

        if (dni.length !== 8) {
            el.feedback.className = 'text-[0.875em] mt-1 text-danger';
            el.feedback.textContent = 'El DNI debe tener 8 dígitos numéricos.';
            el.inputDni.focus();
            return;
        }

        el.btnBuscar.disabled = true;
        if (el.searchIcon) el.searchIcon.className = 'spinner-border spinner-border-sm';
        if (el.searchText) el.searchText.textContent = 'Buscando...';
        el.feedback.className = 'text-[0.875em] mt-1 text-primary';
        el.feedback.textContent = 'Consultando datos en RENIEC...';

        try {
            const url = CTX + '/usuarios/dni-lookup?dni=' + encodeURIComponent(dni);
            const response = await fetch(url, { headers: { 'Accept': 'application/json' } });
            const data = await response.json();

            if (response.ok && data.success && data.nombre_completo) {
                if (el.inputNombre) {
                    el.inputNombre.value = data.nombre_completo;
                    el.inputNombre.readOnly = true;
                }
                if (el.inputNombreDni) {
                    el.inputNombreDni.value = data.nombre_completo;
                }
                if (el.avisoNombre) {
                    el.avisoNombre.className = 'text-[0.875em] mt-1 text-success font-bold';
                    el.avisoNombre.textContent = 'Nombre vinculado al DNI: no se puede modificar.';
                }

                // Generar correo: primer nombre + @universidad.edu
                let primerNombre = '';
                if (data.nombres) {
                    primerNombre = data.nombres.trim().split(/\s+/)[0];
                } else if (data.nombre_completo) {
                    primerNombre = data.nombre_completo.trim().split(/\s+/)[0];
                }

                if (primerNombre && el.inputEmail) {
                    // Minúsculas, sin tildes ni caracteres especiales
                    const nombreLimpio = primerNombre.toLowerCase()
                        .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
                        .replace(/[^a-z0-9]/g, '');
                    if (nombreLimpio) {
                        el.inputEmail.value = nombreLimpio + '@universidad.edu';
                    }
                }

                el.feedback.className = 'text-[0.875em] mt-1 text-success font-bold';
                el.feedback.textContent = '✓ Datos encontrados y autocompletados con éxito.';

                // Foco al siguiente campo vacío
                if (el.inputCelular && !el.inputCelular.value) {
                    el.inputCelular.focus();
                }
            } else {
                el.feedback.className = 'text-[0.875em] mt-1 text-danger';
                el.feedback.textContent = data.error || 'No se encontraron datos para este DNI.';
                if (el.inputNombre) el.inputNombre.readOnly = false;
                if (el.inputNombreDni) el.inputNombreDni.value = '';
                if (el.avisoNombre) el.avisoNombre.textContent = '';
            }
        } catch (error) {
            console.error('Error al consultar DNI:', error);
            el.feedback.className = 'text-[0.875em] mt-1 text-danger';
            el.feedback.textContent = 'Error de conexión al consultar el DNI. Intente nuevamente.';
            if (el.inputNombre) el.inputNombre.readOnly = false;
            if (el.inputNombreDni) el.inputNombreDni.value = '';
            if (el.avisoNombre) el.avisoNombre.textContent = '';
        } finally {
            el.btnBuscar.disabled = false;
            if (el.searchIcon) el.searchIcon.className = 'ri-search-line';
            if (el.searchText) el.searchText.textContent = 'Buscar';
        }
    }

    function raizDe(elemento) {
        return elemento.closest('form') || document;
    }

    document.addEventListener('click', function (event) {
        const boton = event.target.closest ? event.target.closest('#btn-buscar-dni') : null;
        if (!boton) {
            return;
        }
        consultarDni(raizDe(boton));
    });

    // Enter en el campo DNI = buscar (sin enviar el formulario)
    document.addEventListener('keydown', function (event) {
        if (event.key !== 'Enter') {
            return;
        }
        const input = event.target.closest ? event.target.closest('#dni') : null;
        if (!input) {
            return;
        }
        event.preventDefault();
        consultarDni(raizDe(input));
    });

    // Evita registrar un usuario con un nombre distinto al obtenido por DNI
    document.addEventListener('submit', function (event) {
        const form = event.target;
        if (!form || !form.querySelector) return;
        const inputNombre = form.querySelector('#nombre');
        const inputNombreDni = form.querySelector('#nombre_dni');
        if (!inputNombre || !inputNombreDni) return;
        const esperado = inputNombreDni.value.trim();
        if (esperado && inputNombre.value.trim() !== esperado) {
            event.preventDefault();
            event.stopPropagation();
            inputNombre.value = esperado;
            inputNombre.readOnly = true;
            const aviso = form.querySelector('#nombre-dni-aviso');
            if (aviso) {
                aviso.className = 'text-[0.875em] mt-1 text-danger font-bold';
                aviso.textContent = 'El nombre debe corresponder al DNI consultado y no puede modificarse.';
            }
        }
    }, true);

    // Consulta automática al completar los 8 dígitos
    document.addEventListener('input', function (event) {
        const input = event.target.closest ? event.target.closest('#dni') : null;
        if (!input) {
            return;
        }
        const raiz = raizDe(input);
        const el = elementos(raiz);
        if (!el.feedback) {
            return;
        }
        el.feedback.className = 'text-[0.875em] mt-1 text-muted';
        el.feedback.textContent = 'Ingrese los 8 dígitos y haga clic en Buscar.';
        if (input.value.trim().length !== 8) {
            if (el.inputNombre) el.inputNombre.readOnly = false;
            if (el.inputNombreDni) el.inputNombreDni.value = '';
            if (el.avisoNombre) el.avisoNombre.textContent = '';
        }
        if (input.value.trim().length === 8) {
            consultarDni(raiz);
        }
    });
})();
