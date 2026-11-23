// ============================================================
// SweetAlert2 — Configuración global para el Sistema de Préstamos UNCP
// Reemplaza los confirm() y alert() nativos con diálogos modernos.
// ============================================================
(function () {
    'use strict';

    // Paleta UNCP
    var UNCP_GREEN      = '#004d3d';
    var UNCP_GREEN_DARK = '#00382b';
    var UNCP_GOLD       = '#eab308';
    var UNCP_RED        = '#E11D48';
    var UNCP_DEEP       = '#00382b';

    // Configuración base reutilizable
    var defaultMixin = Swal.mixin({
        customClass: {
            confirmButton: 'btn btn-primary swal-btn px-6 py-2 font-bold',
            cancelButton:  'btn btn-secondary swal-btn px-6 py-2 font-bold',
            denyButton:    'btn btn-danger swal-btn px-6 py-2 font-bold',
            popup:         'swal-uncp-popup'
        },
        buttonsStyling: false,
        reverseButtons: true,
        focusConfirm: false,
        didOpen: function (popup) {
            popup.style.borderRadius = '18px';
        }
    });

    // ------------------------------------------------------------------
    // 1. Formularios de eliminar (.form-eliminar):
    //    Interceptar y mostrar SweetAlert2 en lugar de confirm()
    // ------------------------------------------------------------------
    document.addEventListener('submit', function (e) {
        var form = e.target;
        if (!form || !form.classList || !form.classList.contains('form-eliminar')) {
            return;
        }
        // Si ya fue confirmado (flag interno), dejar pasar
        if (form.getAttribute('data-swal-confirmed') === '1') {
            return;
        }
        e.preventDefault();
        e.stopImmediatePropagation();

        var mensaje = form.dataset.confirm || '¿Está seguro de eliminar este registro?';
        defaultMixin.fire({
            title: '¿Confirmar eliminación?',
            html: '<p class="text-muted mb-0" style="font-size:0.95rem;">' + mensaje + '</p>',
            icon: 'warning',
            iconColor: UNCP_RED,
            showCancelButton: true,
            confirmButtonText: '<i class="ri-delete-bin-line me-1"></i> Sí, eliminar',
            cancelButtonText: '<i class="ri-close-circle-line me-1"></i> Cancelar',
            confirmButtonColor: UNCP_RED,
            customClass: {
                confirmButton: 'btn btn-danger swal-btn px-6 py-2 font-bold',
                cancelButton:  'btn btn-secondary swal-btn px-6 py-2 font-bold',
                popup:         'swal-uncp-popup'
            }
        }).then(function (result) {
            if (result.isConfirmed) {
                form.setAttribute('data-swal-confirmed', '1');
                form.submit();
            }
        });
    }, true);  // useCapture = true para interceptar antes que el listener original

    // ------------------------------------------------------------------
    // 2. Formularios de cambio de estado de usuario (activar/desactivar)
    // ------------------------------------------------------------------
    document.addEventListener('submit', function (e) {
        var form = e.target;
        if (!form || !form.closest) return;
        // Detectar formularios de cambiar-estado que NO sean .form-eliminar
        var action = form.getAttribute('action') || '';
        if (action.indexOf('cambiar-estado') === -1) return;
        if (form.getAttribute('data-swal-confirmed') === '1') return;

        e.preventDefault();
        e.stopImmediatePropagation();

        // Determinar si activa o desactiva por el ícono del botón
        var btn = form.querySelector('button[type="submit"]');
        var esDesactivar = btn && btn.classList.contains('btn-outline-danger');

        defaultMixin.fire({
            title: esDesactivar ? '¿Desactivar usuario?' : '¿Activar usuario?',
            html: esDesactivar
                ? '<p class="text-muted mb-0">El usuario no podrá acceder al sistema mientras esté desactivado.</p>'
                : '<p class="text-muted mb-0">El usuario volverá a tener acceso al sistema.</p>',
            icon: esDesactivar ? 'warning' : 'question',
            iconColor: esDesactivar ? UNCP_RED : UNCP_GREEN,
            showCancelButton: true,
            confirmButtonText: esDesactivar
                ? '<i class="ri-user-search-line me-1"></i> Sí, desactivar'
                : '<i class="ri-user-follow-line me-1"></i> Sí, activar',
            cancelButtonText: '<i class="ri-close-circle-line me-1"></i> Cancelar',
            customClass: {
                confirmButton: esDesactivar ? 'btn btn-danger swal-btn px-6 py-2 font-bold' : 'btn btn-success swal-btn px-6 py-2 font-bold',
                cancelButton:  'btn btn-secondary swal-btn px-6 py-2 font-bold',
                popup:         'swal-uncp-popup'
            }
        }).then(function (result) {
            if (result.isConfirmed) {
                form.setAttribute('data-swal-confirmed', '1');
                form.submit();
            }
        });
    }, true);

    // ------------------------------------------------------------------
    // 3. Formularios de aprobar/rechazar solicitudes
    // ------------------------------------------------------------------
    document.addEventListener('submit', function (e) {
        var form = e.target;
        if (!form) return;
        var accionInput = form.querySelector('input[name="accion"]');
        if (!accionInput) return;
        var accion = accionInput.value;
        if (accion !== 'aprobar_solicitud' && accion !== 'rechazar_solicitud') return;
        if (form.getAttribute('data-swal-confirmed') === '1') return;

        e.preventDefault();
        e.stopImmediatePropagation();

        var esAprobar = accion === 'aprobar_solicitud';

        if (esAprobar) {
            defaultMixin.fire({
                title: '¿Aprobar solicitud?',
                html: '<p class="text-muted mb-0">El equipo será asignado al usuario solicitante y se registrará el préstamo.</p>',
                icon: 'question',
                iconColor: UNCP_GREEN,
                showCancelButton: true,
                confirmButtonText: '<i class="ri-checkbox-circle-line me-1"></i> Sí, aprobar',
                cancelButtonText: 'Cancelar',
                customClass: {
                    confirmButton: 'btn btn-success swal-btn px-6 py-2 font-bold',
                    cancelButton:  'btn btn-secondary swal-btn px-6 py-2 font-bold',
                    popup:         'swal-uncp-popup'
                }
            }).then(function (result) {
                if (result.isConfirmed) {
                    form.setAttribute('data-swal-confirmed', '1');
                    form.submit();
                }
            });
        } else {
            // Rechazo con solicitud obligatoria de motivo
            defaultMixin.fire({
                title: 'Rechazar solicitud',
                html: '<p class="text-muted mb-3" style="font-size:0.9rem;">Por favor, ingresa el motivo del rechazo para notificar al usuario:</p>' +
                      '<textarea id="swalMotivoRechazo" class="form-control" rows="3" placeholder="Ej: Equipo actualmente reservado o no disponible para dicha fecha..." style="resize:vertical;"></textarea>',
                icon: 'warning',
                iconColor: UNCP_RED,
                showCancelButton: true,
                confirmButtonText: '<i class="ri-close-circle-line me-1"></i> Confirmar rechazo',
                cancelButtonText: 'Cancelar',
                customClass: {
                    confirmButton: 'btn btn-danger swal-btn px-6 py-2 font-bold',
                    cancelButton:  'btn btn-secondary swal-btn px-6 py-2 font-bold',
                    popup:         'swal-uncp-popup'
                },
                preConfirm: function () {
                    var motivo = document.getElementById('swalMotivoRechazo').value.trim();
                    if (!motivo) {
                        Swal.showValidationMessage('Debe ingresar el motivo del rechazo.');
                        return false;
                    }
                    return motivo;
                }
            }).then(function (result) {
                if (result.isConfirmed) {
                    var motivo = result.value;
                    var hiddenMotivo = form.querySelector('input[name="motivo_rechazo"]');
                    if (!hiddenMotivo) {
                        hiddenMotivo = document.createElement('input');
                        hiddenMotivo.type = 'hidden';
                        hiddenMotivo.name = 'motivo_rechazo';
                        form.appendChild(hiddenMotivo);
                    }
                    hiddenMotivo.value = motivo;
                    form.setAttribute('data-swal-confirmed', '1');
                    form.submit();
                }
            });
        }
    }, true);

    // ------------------------------------------------------------------
    // 4. Interceptar mensajes flash de sesión y mostrarlos como SweetAlert
    // ------------------------------------------------------------------
    document.addEventListener('DOMContentLoaded', function () {
        // Buscar alertas de Bootstrap generadas por el layout (sessionScope.mensaje)
        var alertas = document.querySelectorAll('.container-fluid > .alert.alert-dismissible');
        alertas.forEach(function (alerta) {
            var texto = alerta.textContent.trim();
            if (!texto) return;

            var tipo = 'info';
            var iconColor = UNCP_GREEN;
            if (alerta.classList.contains('alert-success')) {
                tipo = 'success';
                iconColor = UNCP_GREEN;
            } else if (alerta.classList.contains('alert-danger') || alerta.classList.contains('alert-error')) {
                tipo = 'error';
                iconColor = UNCP_RED;
            } else if (alerta.classList.contains('alert-warning')) {
                tipo = 'warning';
                iconColor = UNCP_GOLD;
            }

            // Ocultar la alerta original
            alerta.style.display = 'none';

            defaultMixin.fire({
                title: tipo === 'success' ? '¡Operación exitosa!' : (tipo === 'error' ? '¡Error!' : (tipo === 'warning' ? '¡Atención!' : 'Información')),
                html: '<p class="mb-0" style="font-size:0.95rem;">' + texto + '</p>',
                icon: tipo,
                iconColor: iconColor,
                confirmButtonText: '<i class="ri-check-line me-1"></i> Entendido',
                timer: tipo === 'success' ? 3000 : null,
                timerProgressBar: tipo === 'success'
            });
        });
    });

    // ------------------------------------------------------------------
    // 5. Cerrar sesión con confirmación
    // ------------------------------------------------------------------
    document.addEventListener('click', function (e) {
        var link = e.target.closest ? e.target.closest('a[href*="/logout"]') : null;
        if (!link) return;

        e.preventDefault();
        defaultMixin.fire({
            title: '¿Cerrar sesión?',
            html: '<p class="text-muted mb-0">Saldrás del sistema de préstamos de equipos.</p>',
            icon: 'question',
            iconColor: UNCP_GREEN_DARK,
            showCancelButton: true,
            confirmButtonText: '<i class="ri-logout-box-r-line me-1"></i> Sí, cerrar sesión',
            cancelButtonText: '<i class="ri-arrow-left-line me-1"></i> Volver',
            customClass: {
                confirmButton: 'btn btn-danger swal-btn px-6 py-2 font-bold',
                cancelButton:  'btn btn-secondary swal-btn px-6 py-2 font-bold',
                popup:         'swal-uncp-popup'
            }
        }).then(function (result) {
            if (result.isConfirmed) {
                window.location.href = link.href;
            }
        });
    });

    // ------------------------------------------------------------------
    // 6. Confirmación en formularios de envío de solicitud (usuario)
    // ------------------------------------------------------------------
    document.addEventListener('submit', function (e) {
        var form = e.target;
        if (!form) return;
        var accionInput = form.querySelector('input[name="accion"]');
        if (!accionInput || accionInput.value !== 'solicitar') return;
        if (form.getAttribute('data-swal-confirmed') === '1') return;
        
        // Validación con alerta si faltan campos
        if (!form.checkValidity()) {
            e.preventDefault();
            e.stopImmediatePropagation();
            form.classList.add('was-validated');

            var primerInvalido = form.querySelector(':invalid');
            var mensajeDetalle = 'Debes completar los campos requeridos para enviar la solicitud.';
            if (primerInvalido) {
                var label = form.querySelector('label[for="' + primerInvalido.id + '"]');
                var nombreCampo = label ? label.textContent.replace('*', '').trim() : primerInvalido.name;
                mensajeDetalle = 'El campo <strong>"' + (nombreCampo || 'requerido') + '"</strong> es obligatorio.';
                primerInvalido.focus();
            }

            defaultMixin.fire({
                title: '¡Faltan datos en la solicitud!',
                html: '<p class="text-muted mb-0">' + mensajeDetalle + '</p>',
                icon: 'warning',
                iconColor: UNCP_GOLD,
                confirmButtonText: 'Entendido',
                customClass: {
                    confirmButton: 'btn btn-warning swal-btn px-6 py-2 font-bold text-dark',
                    popup:         'swal-uncp-popup'
                }
            });
            return;
        }

        e.preventDefault();
        e.stopImmediatePropagation();

        defaultMixin.fire({
            title: '¿Enviar solicitud?',
            html: '<p class="text-muted mb-0">Tu solicitud será enviada al encargado para su aprobación.</p>',
            icon: 'question',
            iconColor: UNCP_GREEN,
            showCancelButton: true,
            confirmButtonText: '<i class="ri-send-plane-line me-1"></i> Sí, enviar solicitud',
            cancelButtonText: 'Cancelar'
        }).then(function (result) {
            if (result.isConfirmed) {
                form.setAttribute('data-swal-confirmed', '1');
                form.submit();
            }
        });
    }, true);

    // ------------------------------------------------------------------
    // 6.1 Confirmación con SweetAlert2 para creación y registro
    // (Nuevo Préstamo, Nuevo Equipo, Devolver Equipo, Nuevo Usuario)
    // ------------------------------------------------------------------
    document.addEventListener('submit', function (e) {
        var form = e.target;
        if (!form || !form.getAttribute) return;
        if (form.getAttribute('data-swal-confirmed') === '1') return;
        if (form.classList.contains('form-eliminar')) return; // Manejado arriba
        var action = form.getAttribute('action') || form.action || '';
        
        // No interceptar búsquedas, filtros o login
        var method = (form.getAttribute('method') || 'GET').toUpperCase();
        if (method !== 'POST') return;
        if (action.indexOf('/login') !== -1 || action.indexOf('/recuperar-password') !== -1) return;
        if (action.indexOf('/cambiar-estado') !== -1) return; // Manejado arriba
        if (form.querySelector('input[name="accion"]')) {
            var accionVal = form.querySelector('input[name="accion"]').value;
            if (accionVal === 'solicitar' || accionVal === 'aprobar_solicitud' || accionVal === 'rechazar_solicitud') return; // Manejados arriba
        }

        // Validar formulario primero: si no es válido, alertar con SweetAlert2
        if (!form.checkValidity()) {
            e.preventDefault();
            e.stopImmediatePropagation();
            form.classList.add('was-validated');

            // Identificar los campos obligatorios o inválidos que faltan
            var primerInvalido = form.querySelector(':invalid');
            var mensajeDetalle = 'Por favor completa todos los campos requeridos marcados en rojo antes de continuar.';
            if (primerInvalido) {
                var label = form.querySelector('label[for="' + primerInvalido.id + '"]');
                var nombreCampo = label ? label.textContent.replace('*', '').trim() : primerInvalido.name;
                if (primerInvalido.value.trim() === '') {
                    mensajeDetalle = 'El campo <strong>"' + (nombreCampo || 'requerido') + '"</strong> es obligatorio.';
                } else if (primerInvalido.validationMessage) {
                    mensajeDetalle = '<strong>' + (nombreCampo || 'Campo') + '</strong>: ' + primerInvalido.validationMessage;
                }
                primerInvalido.focus();
            }

            defaultMixin.fire({
                title: '¡Formulario incompleto!',
                html: '<p class="text-muted mb-0" style="font-size:0.95rem;">' + mensajeDetalle + '</p>',
                icon: 'warning',
                iconColor: UNCP_GOLD,
                confirmButtonText: '<i class="ri-pencil-line me-1"></i> Completar campos',
                customClass: {
                    confirmButton: 'btn btn-warning swal-btn px-6 py-2 font-bold text-dark',
                    popup:         'swal-uncp-popup'
                }
            });
            return;
        }

        var config = null;

        if (action.indexOf('/prestamos/registrar') !== -1) {
            config = {
                title: '¿Registrar nuevo préstamo?',
                html: '<p class="text-muted mb-0">Se asignará el equipo al usuario seleccionado y comenzará el préstamo.</p>',
                icon: 'question',
                confirmText: '<i class="ri-checkbox-circle-line me-1"></i> Sí, registrar préstamo'
            };
        } else if (action.indexOf('/prestamos/devolver') !== -1) {
            config = {
                title: '¿Confirmar devolución de equipo?',
                html: '<p class="text-muted mb-0">El préstamo se marcará como devuelto y el equipo volverá a estar disponible.</p>',
                icon: 'question',
                confirmText: '<i class="ri-checkbox-circle-line me-1"></i> Sí, confirmar devolución'
            };
        } else if (action.indexOf('/equipos/crear') !== -1) {
            config = {
                title: '¿Guardar nuevo equipo?',
                html: '<p class="text-muted mb-0">El equipo se registrará en el inventario institucional.</p>',
                icon: 'question',
                confirmText: '<i class="ri-save-line me-1"></i> Guardar equipo'
            };
        } else if (action.indexOf('/equipos/editar') !== -1) {
            config = {
                title: '¿Actualizar equipo?',
                html: '<p class="text-muted mb-0">Se guardarán los cambios realizados al equipo.</p>',
                icon: 'question',
                confirmText: '<i class="ri-pencil-line me-1"></i> Guardar cambios'
            };
        } else if (action.indexOf('/usuarios/crear') !== -1) {
            config = {
                title: '¿Crear nuevo usuario?',
                html: '<p class="text-muted mb-0">Se creará la cuenta con los datos y accesos especificados.</p>',
                icon: 'question',
                confirmText: '<i class="ri-user-add-line me-1"></i> Crear usuario'
            };
        } else if (action.indexOf('/usuarios/editar') !== -1) {
            config = {
                title: '¿Actualizar datos del usuario?',
                html: '<p class="text-muted mb-0">Se guardarán las modificaciones en la cuenta del usuario.</p>',
                icon: 'question',
                confirmText: '<i class="ri-save-line me-1"></i> Actualizar'
            };
        } else if (action.indexOf('/perfil') !== -1) {
            config = {
                title: '¿Actualizar contraseña?',
                html: '<p class="text-muted mb-0">Se actualizará la contraseña de tu cuenta institucional.</p>',
                icon: 'question',
                confirmText: '<i class="ri-key-2-fill me-1"></i> Guardar contraseña'
            };
        }

        if (config) {
            e.preventDefault();
            e.stopImmediatePropagation();

            defaultMixin.fire({
                title: config.title,
                html: config.html,
                icon: config.icon,
                iconColor: UNCP_GREEN,
                showCancelButton: true,
                confirmButtonText: config.confirmText,
                cancelButtonText: '<i class="ri-close-circle-line me-1"></i> Cancelar',
                customClass: {
                    confirmButton: 'btn btn-primary swal-btn px-6 py-2 font-bold',
                    cancelButton:  'btn btn-secondary swal-btn px-6 py-2 font-bold',
                    popup:         'swal-uncp-popup'
                }
            }).then(function (result) {
                if (result.isConfirmed) {
                    form.setAttribute('data-swal-confirmed', '1');
                    // Si vive dentro de un modal, disparar evento o submit
                    if (typeof form.requestSubmit === 'function') {
                        form.requestSubmit();
                    } else {
                        form.submit();
                    }
                }
            });
        }
    }, true);

    // ------------------------------------------------------------------
    // 7. Toast de éxito para operaciones rápidas (función global)
    // ------------------------------------------------------------------
    window.SwalToast = Swal.mixin({
        toast: true,
        position: 'top-end',
        showConfirmButton: false,
        timer: 3000,
        timerProgressBar: true,
        iconColor: UNCP_GREEN,
        customClass: {
            popup: 'swal-toast-uncp'
        },
        didOpen: function (toast) {
            toast.addEventListener('mouseenter', Swal.stopTimer);
            toast.addEventListener('mouseleave', Swal.resumeTimer);
        }
    });

    // ------------------------------------------------------------------
    // 8. Función global para confirmaciones personalizadas
    // ------------------------------------------------------------------
    window.SwalConfirm = function (opciones) {
        return defaultMixin.fire({
            title: opciones.titulo || '¿Está seguro?',
            html: opciones.mensaje ? '<p class="text-muted mb-0">' + opciones.mensaje + '</p>' : '',
            icon: opciones.icono || 'question',
            iconColor: opciones.color || UNCP_GREEN,
            showCancelButton: true,
            confirmButtonText: opciones.textoConfirmar || 'Sí, confirmar',
            cancelButtonText: opciones.textoCancelar || 'Cancelar',
            customClass: {
                confirmButton: 'btn ' + (opciones.claseBoton || 'btn-primary') + ' swal-btn px-4 py-2 fw-bold',
                cancelButton:  'btn btn-secondary swal-btn px-6 py-2 font-bold',
                popup:         'swal-uncp-popup'
            }
        });
    };
})();

