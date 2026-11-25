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
            inputPassword: raiz.querySelector('#password'),
            inputPasswordConfirm: raiz.querySelector('#password_confirm'),
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

                // Autogenerar contraseña: Inicial del nombre en mayúscula + DNI (ej: A71234567)
                let inicialNombre = '';
                if (primerNombre) {
                    inicialNombre = primerNombre.charAt(0).toUpperCase();
                } else if (data.nombre_completo) {
                    inicialNombre = data.nombre_completo.trim().charAt(0).toUpperCase();
                }
                if (inicialNombre && dni) {
                    const claveGenerada = inicialNombre + dni;
                    const passInput = el.inputPassword || document.querySelector('#password');
                    const passConfInput = el.inputPasswordConfirm || document.querySelector('#password_confirm');
                    if (passInput) {
                        passInput.value = claveGenerada;
                        passInput.setAttribute('value', claveGenerada);
                        passInput.dispatchEvent(new Event('input', { bubbles: true }));
                        passInput.dispatchEvent(new Event('change', { bubbles: true }));
                    }
                    if (passConfInput) {
                        passConfInput.value = claveGenerada;
                        passConfInput.setAttribute('value', claveGenerada);
                        passConfInput.dispatchEvent(new Event('input', { bubbles: true }));
                        passConfInput.dispatchEvent(new Event('change', { bubbles: true }));
                    }
                }

                el.feedback.className = 'text-[0.875em] mt-1 text-success font-bold';
                el.feedback.textContent = '✓ Datos encontrados y autocompletados con éxito.';

                // Foco al siguiente campo vacío
                if (el.inputCelular && !el.inputCelular.value) {
                    el.inputCelular.focus();
                }
            } else {
                el.feedback.className = 'text-[0.875em] mt-1 text-warning font-semibold';
                el.feedback.innerHTML = '<i class="ri-information-line me-1"></i>No se encontró automáticamente en RENIEC. Ingrese el nombre manualmente.';
                if (el.inputNombre) {
                    el.inputNombre.readOnly = false;
                    el.inputNombre.focus();
                }
                if (el.inputNombreDni) el.inputNombreDni.value = '';
                if (el.avisoNombre) el.avisoNombre.textContent = '';
            }
        } catch (error) {
            console.error('Error al consultar DNI:', error);
            el.feedback.className = 'text-[0.875em] mt-1 text-warning font-semibold';
            el.feedback.innerHTML = '<i class="ri-wifi-off-line me-1"></i>Servicio RENIEC no disponible. Ingrese el nombre manualmente.';
            if (el.inputNombre) {
                el.inputNombre.readOnly = false;
                el.inputNombre.focus();
            }
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

    // Actualizar contraseña automáticamente si el usuario escribe o edita el nombre a mano
    document.addEventListener('input', function (event) {
        const input = event.target.closest ? event.target.closest('#nombre, #dni') : null;
        if (!input) return;
        const form = input.closest('form');
        if (!form) return;
        const el = elementos(form);
        if (!el.inputPassword || !el.inputPasswordConfirm) return;

        const dniVal = el.inputDni ? el.inputDni.value.trim() : '';
        const nombreVal = el.inputNombre ? el.inputNombre.value.trim() : '';

        if (dniVal && nombreVal) {
            const inicial = nombreVal.charAt(0).toUpperCase();
            if (/[A-ZÁÉÍÓÚÑ]/.test(inicial)) {
                const autogen = inicial + dniVal;
                if (!el.inputPassword.dataset.manualEdited) {
                    el.inputPassword.value = autogen;
                    el.inputPassword.setAttribute('value', autogen);
                    el.inputPassword.dispatchEvent(new Event('change', { bubbles: true }));
                }
                if (!el.inputPasswordConfirm.dataset.manualEdited) {
                    el.inputPasswordConfirm.value = autogen;
                    el.inputPasswordConfirm.setAttribute('value', autogen);
                    el.inputPasswordConfirm.dispatchEvent(new Event('change', { bubbles: true }));
                }
            }
        }
    });

    // Si el usuario edita la contraseña manualmente, respetar su valor
    document.addEventListener('input', function (event) {
        const pass = event.target.closest ? event.target.closest('#password') : null;
        if (pass) {
            pass.dataset.manualEdited = 'true';
        }
    });

    // Enviar credenciales por WhatsApp o Correo / Gmail
    function obtenerCredenciales(form) {
        const el = elementos(form);
        const nombre = el.inputNombre ? el.inputNombre.value.trim() : '';
        const email = el.inputEmail ? el.inputEmail.value.trim() : '';
        const celular = el.inputCelular ? el.inputCelular.value.trim() : '';
        const dni = el.inputDni ? el.inputDni.value.trim() : '';

        // En creación es #password, en edición puede ser #nuevo_password
        const inputNuevoPass = form.querySelector('#nuevo_password');
        let password = '';
        if (el.inputPassword && el.inputPassword.value.trim()) {
            password = el.inputPassword.value.trim();
        } else if (inputNuevoPass && inputNuevoPass.value.trim()) {
            password = inputNuevoPass.value.trim();
        } else if (nombre && dni) {
            // Si está en edición y no cambió contraseña, deducir la clave por defecto
            const inicial = nombre.charAt(0).toUpperCase();
            password = inicial + dni;
        }

        return { nombre, email, celular, password, dni };
    }

    document.addEventListener('click', function (event) {
        const btnWa = event.target.closest ? event.target.closest('#btn-enviar-whatsapp') : null;
        const btnMail = event.target.closest ? event.target.closest('#btn-enviar-email') : null;

        if (!btnWa && !btnMail) return;

        const form = (btnWa || btnMail).closest('form') || document.querySelector('form');
        const c = obtenerCredenciales(form);

        if (!c.email || !c.password) {
            if (typeof Swal !== 'undefined') {
                Swal.fire({
                    icon: 'warning',
                    title: 'Faltan datos',
                    text: 'Debe ingresar o autocompletar el DNI y la contraseña antes de enviar.',
                    confirmButtonColor: '#004d3d'
                });
            } else {
                alert('Debe ingresar el correo y la contraseña antes de enviar.');
            }
            return;
        }

        const mensaje = '¡Hola ' + (c.nombre || 'Usuario') + '! 🎓\n\n'
            + 'Se ha creado tu cuenta en el *Sistema de Préstamos de Equipos - UNCP*.\n\n'
            + 'Tus credenciales de acceso son:\n'
            + '👤 *Usuario / Correo:* ' + c.email + '\n'
            + '🔑 *Contraseña:* ' + c.password + '\n\n'
            + 'Puedes acceder al sistema desde el enlace de la universidad.';

        if (btnWa) {
            let cel = c.celular.replace(/[^0-9]/g, '');
            if (!cel) {
                if (typeof Swal !== 'undefined') {
                    Swal.fire({
                        icon: 'info',
                        title: 'Sin celular registrado',
                        text: 'Ingresa un número de celular de 9 dígitos en el formulario para abrir la conversación directamente.',
                        confirmButtonColor: '#004d3d'
                    });
                }
                return;
            }
            // Si es número peruano de 9 dígitos sin código de país, anteponer 51
            if (cel.length === 9) {
                cel = '51' + cel;
            }
            const waUrl = 'https://api.whatsapp.com/send?phone=' + cel + '&text=' + encodeURIComponent(mensaje);
            window.open(waUrl, 'whatsappCompose', 'width=900,height=700,scrollbars=yes,resizable=yes');
        } else if (btnMail) {
            const asunto = 'Credenciales de Acceso - Sistema de Préstamos de Equipos UNCP';
            const cuerpoMail = mensaje.replace(/\*/g, ''); // Quitar negritas de WhatsApp para el correo
            // Si es Gmail web directo
            const gmailUrl = 'https://mail.google.com/mail/?view=cm&fs=1&to=' + encodeURIComponent(c.email) + '&su=' + encodeURIComponent(asunto) + '&body=' + encodeURIComponent(cuerpoMail);
            
            // Intentar abrir Gmail web, con fallback a mailto
            const win = window.open(gmailUrl, 'gmailCompose', 'width=900,height=700,scrollbars=yes,resizable=yes');
            if (!win) {
                window.location.href = 'mailto:' + encodeURIComponent(c.email) + '?subject=' + encodeURIComponent(asunto) + '&body=' + encodeURIComponent(cuerpoMail);
            }
        }
    });
})();
