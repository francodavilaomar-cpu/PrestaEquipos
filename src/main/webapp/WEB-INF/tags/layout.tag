<%@ tag body-content="scriptless" pageEncoding="UTF-8" %>
<%@ attribute name="title" required="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="f" uri="http://universidad.edu/presta/funciones" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<%-- Clases reutilizadas varias veces en el layout (Tailwind las detecta por el texto) --%>
<c:set var="lnk" value="mb-[3px] flex items-center gap-3 rounded-lg px-4 py-2.5 text-[0.92rem] font-medium text-white/80 no-underline transition-all hover:bg-white/[0.08] hover:text-white"/>
<c:set var="lnkOn" value="!bg-sidebar-active !font-semibold !text-white shadow-[0_2px_8px_rgb(0_0_0/0.12)]"/>
<c:set var="btnHeader" value="relative inline-flex size-10 items-center justify-center rounded-full border border-line bg-white p-0 text-[1.2rem] text-ink transition-colors hover:bg-slate-100"/>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="ctx" content="${ctx}">
    <meta name="csrf" content="${f:h(csrf)}">
    <title>${f:h(title)} - ${f:h(siteName)}</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/tom-select@2.3.1/dist/css/tom-select.default.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/remixicon@4.5.0/fonts/remixicon.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.min.css">
    <link rel="stylesheet" href="${ctx}/assets/css/tailwind.css?v=20261113e">
    <link rel="stylesheet" href="${ctx}/assets/css/asistente-ia.css?v=20261114a">
</head>
<body>
    <div class="flex">
        <!-- Overlay para cerrar el menú en móvil -->
        <div class="sidebar-overlay" id="sidebarOverlay"></div>

        <!-- Sidebar UNCP -->
        <nav class="sidebar fixed left-0 top-0 z-[1040] flex min-h-screen-ui w-[260px] max-w-[80vw] flex-col overflow-y-auto border-r border-black/[0.08] bg-sidebar text-white lg:max-w-none" id="sidebar">
            <div class="p-4">
                <div class="mb-6 flex items-center gap-4 pt-1">
                    <img src="${ctx}/assets/img/uncp-escudo.png" alt="UNCP" class="size-11 rounded-full border-2 border-gold bg-black object-cover shadow-[0_4px_10px_rgb(0_0_0/0.2)]">
                    <div class="leading-none">
                        <h5 class="mb-1 text-[1.15rem] font-extrabold tracking-[0.5px] text-white">UNCP</h5>
                        <span class="text-[0.82rem] font-medium text-emerald-200">PrestaEquipos</span>
                    </div>
                    <button type="button" class="btn-close btn-close-white ms-auto lg:hidden" id="sidebarClose" aria-label="Cerrar menú"></button>
                </div>

                <ul class="m-0 flex list-none flex-col gap-1 p-0">
                    <li>
                        <a class="${lnk} ${nav == 'dashboard' ? lnkOn : ''}" href="${ctx}/dashboard">
                            <i class="ri-home-5-line shrink-0 text-[1.22rem]"></i> <span>Inicio</span>
                        </a>
                    </li>
                    <li>
                        <a class="${lnk} ${nav == 'equipos' && tabActiva != 'solicitudes' ? lnkOn : ''}" href="${ctx}/equipos/listar">
                            <i class="ri-computer-line shrink-0 text-[1.22rem]"></i> <span>Equipos</span>
                        </a>
                    </li>
                    <c:if test="${not esEncargado}">
                        <li>
                            <a class="${lnk}" href="${ctx}/equipos/listar?tab=mis_solicitudes">
                                <i class="ri-time-line shrink-0 text-[1.22rem]"></i> <span>Mis Solicitudes</span>
                            </a>
                        </li>
                        <li>
                            <a class="${lnk} ${nav == 'equipos' ? '' : ''}" href="${ctx}/prestamos/mis">
                                <i class="ri-archive-drawer-line shrink-0 text-[1.22rem]"></i> <span>Mis Equipos</span>
                            </a>
                        </li>
                    </c:if>
                    <c:if test="${esEncargado}">
                        <li>
                            <a class="${lnk} ${nav == 'equipos' && tabActiva == 'solicitudes' ? lnkOn : ''}" href="${ctx}/equipos/bandeja">
                                <i class="ri-inbox-line shrink-0 text-[1.22rem]"></i> <span>Bandeja de Solicitudes</span>
                            </a>
                        </li>
                    </c:if>
                    <c:if test="${esEncargado}">
                        <li>
                            <a class="${lnk} ${nav == 'vencidos' ? lnkOn : ''}" href="${ctx}/prestamos/vencidos">
                                <i class="ri-alert-line shrink-0 text-[1.22rem]"></i> <span>Vencidos</span>
                            </a>
                        </li>
                    </c:if>
                    <c:if test="${esAdmin}">
                        <li>
                            <a class="${lnk} ${nav == 'usuarios' ? lnkOn : ''}" href="${ctx}/usuarios/listar">
                                <i class="ri-group-line shrink-0 text-[1.22rem]"></i> <span>Usuarios</span>
                            </a>
                        </li>
                    </c:if>
                    <c:if test="${esEncargado}">
                        <li>
                            <a class="${lnk} ${nav == 'reportes' ? lnkOn : ''}" href="${ctx}/reportes">
                                <i class="ri-file-chart-line shrink-0 text-[1.22rem]"></i> <span>Reportes</span>
                            </a>
                        </li>
                    </c:if>
                    <c:if test="${esEncargado}">
                        <li>
                            <a class="${lnk} ${nav == 'mantenimiento' ? lnkOn : ''}" href="${ctx}/ia/mantenimiento">
                                <i class="ri-brain-line shrink-0 text-[1.22rem]"></i> <span>Mantenimiento inteligente</span>
                            </a>
                        </li>
                    </c:if>
                </ul>
            </div>

            <!-- Card Mesa de Ayuda institucional en el sidebar -->
            <div class="mt-auto p-4">
                <div class="rounded-xl border border-white/[0.06] bg-sidebar-help p-[1.1rem] shadow-[inset_0_1px_2px_rgb(0_0_0/0.15)]">
                    <div class="mb-2 flex items-center gap-2">
                        <span class="badge bg-warning px-2 py-1 text-[0.72rem] font-bold text-dark">OTI - UNCP</span>
                        <small class="text-[0.75rem] text-white/50">Soporte TI</small>
                    </div>
                    <div class="mb-1 flex items-center gap-2 text-[0.9rem] font-bold text-white">
                        <i class="ri-customer-service-2-line text-warning"></i>
                        <span>Mesa de Ayuda</span>
                    </div>
                    <p class="mb-4 text-[0.78rem] leading-[1.35] text-white/50">
                        Consultas y soporte para personal y docentes.
                    </p>
                    <div class="border-t border-white/[0.08] pt-[0.65rem] text-center text-[0.73rem] text-white/45">
                        &copy; UNCP &middot; Huancayo, Per&uacute;
                    </div>
                </div>
            </div>
        </nav>

        <!-- Contenido principal -->
        <main class="ml-0 flex min-h-screen-ui w-full min-w-0 grow flex-col lg:ml-[260px]">
            <!-- Header superior -->
            <header class="app-header mb-6 border-b border-line bg-white px-6 py-4 shadow-sm">
                <div class="flex items-center justify-between">
                    <div class="flex items-center gap-4">
                        <button type="button" class="btn btn-light lg:hidden" id="sidebarToggle" aria-label="Abrir menú">
                            <i class="ri-menu-line text-[1.3rem]"></i>
                        </button>
                        <h5 class="mb-0 text-xl font-bold tracking-[-0.3px] text-dark">${f:h(title)}</h5>
                    </div>
                    <div class="flex items-center gap-4">
                        <c:if test="${esEncargado}">
                            <div class="dropdown" id="notificacionesAdmin"
                                 data-url-marcar="${ctx}/notificaciones/marcar-todas">
                                <button class="${btnHeader}" type="button" id="btnNotificaciones"
                                        data-toggle="dropdown" data-auto-close="outside"
                                        aria-expanded="false" aria-label="Notificaciones">
                                    <i class="ri-notification-3-line"></i>
                                    <span class="badge absolute left-full top-0 -translate-1/2 rounded-full bg-danger ${notificacionesNoLeidas > 0 ? '' : 'hidden'}"
                                          id="badgeNotificaciones">${notificacionesNoLeidas}</span>
                                </button>
                                <div class="dropdown-menu dropdown-menu-end notificaciones-panel shadow-lg"
                                     aria-labelledby="btnNotificaciones">
                                    <div class="notificaciones-cabecera">
                                        <div>
                                            <h6 class="mb-0">Notificaciones</h6>
                                            <small class="text-muted" id="resumenNotificaciones">${notificacionesNoLeidas} sin leer</small>
                                        </div>
                                        <button type="button" class="btn btn-link btn-sm" id="marcarTodasNotificaciones"
                                                ${empty notificacionesLista || notificacionesNoLeidas == 0 ? 'disabled' : ''}>
                                            Marcar todas como leídas
                                        </button>
                                    </div>

                                    <div class="notificaciones-tabs" role="tablist">
                                        <button type="button" class="notificaciones-tab active" data-filtro="todas" role="tab" aria-selected="true">
                                            Todas <span class="notificaciones-contador" data-contador="todas">${notificacionesLista.size()}</span>
                                        </button>
                                        <button type="button" class="notificaciones-tab" data-filtro="no-leidas" role="tab" aria-selected="false">
                                            No leídas <span class="notificaciones-contador" data-contador="no-leidas">${notificacionesNoLeidas}</span>
                                        </button>
                                    </div>

                                    <div class="notificaciones-lista" id="listaNotificaciones">
                                        <c:forEach var="n" items="${notificacionesLista}">
                                            <a class="notificacion-item ${n.leida ? '' : 'no-leida'}"
                                               href="${ctx}/notificaciones/ir?clave=${n.clave}&amp;url=${n.enlace}"
                                               data-leida="${n.leida}" data-tipo="${n.tipo}">
                                                <span class="notificacion-icono text-${n.tono}"><i class="${n.icono}"></i></span>
                                                <span class="notificacion-texto">
                                                    <span class="notificacion-titulo">${f:h(n.titulo)}</span>
                                                    <span class="notificacion-mensaje">${f:h(n.mensaje)}</span>
                                                    <span class="notificacion-fecha">${f:hace(n.fecha)}</span>
                                                </span>
                                                <span class="notificacion-punto" aria-hidden="true"></span>
                                            </a>
                                        </c:forEach>
                                    </div>

                                    <div class="notificaciones-vacio hidden" id="notificacionesVacio">
                                        <i class="ri-notification-off-line"></i>
                                        <p class="notificaciones-vacio-titulo mb-1" data-vacio-titulo>Sin notificaciones</p>
                                        <p class="mb-0 text-[0.875em] text-muted" data-vacio-texto>Aquí verás los avisos de tus solicitudes, préstamos y de la plataforma.</p>
                                    </div>

                                    <a class="notificaciones-pie" href="${ctx}/prestamos/vencidos">
                                        Ver todas las notificaciones
                                    </a>
                                </div>
                            </div>
                        </c:if>

                        <c:if test="${not esEncargado}">
                            <div class="dropdown">
                                <button class="${btnHeader}" type="button" data-toggle="dropdown" aria-expanded="false" aria-label="Notificaciones">
                                    <i class="ri-notification-3-line"></i>
                                </button>
                                <div class="dropdown-menu dropdown-menu-end notificaciones-panel shadow-lg" style="width: 360px;">
                                    <div class="notificaciones-cabecera">
                                        <div>
                                            <h6 class="mb-0">Notificaciones</h6>
                                            <small class="text-muted">${notificacionesNoLeidas} sin leer</small>
                                        </div>
                                    </div>
                                    <div class="notificaciones-lista" id="listaNotificacionesUsuario">
                                        <c:if test="${empty notificacionesLista}">
                                            <div class="notificaciones-vacio py-6">
                                                <i class="ri-notification-off-line"></i>
                                                <p class="notificaciones-vacio-titulo mb-1">Sin notificaciones</p>
                                                <p class="mb-0 text-[0.875em] text-muted">Aquí verás los avisos de tus solicitudes y préstamos.</p>
                                            </div>
                                        </c:if>
                                        <c:forEach var="n" items="${notificacionesLista}">
                                            <a class="notificacion-item ${n.leida ? '' : 'no-leida'}"
                                               href="${ctx}/notificaciones/ir?clave=${n.clave}&amp;url=${n.enlace}"
                                               data-leida="${n.leida}" data-tipo="${n.tipo}">
                                                <span class="notificacion-icono text-${n.tono}"><i class="${n.icono}"></i></span>
                                                <span class="notificacion-texto">
                                                    <span class="notificacion-titulo">${f:h(n.titulo)}</span>
                                                    <span class="notificacion-mensaje">${f:h(n.mensaje)}</span>
                                                    <span class="notificacion-fecha">${f:hace(n.fecha)}</span>
                                                </span>
                                                <span class="notificacion-punto" aria-hidden="true"></span>
                                            </a>
                                        </c:forEach>
                                    </div>
                                    <a class="notificaciones-pie" href="${ctx}/prestamos/vencidos">
                                        Ver todas las notificaciones
                                    </a>
                                </div>
                            </div>
                        </c:if>

                        <!-- Menú de Usuario -->
                        <div class="dropdown">
                            <button class="dropdown-toggle flex items-center gap-2 rounded-full border border-line bg-white px-[0.85rem] py-[0.35rem] shadow-sm transition-colors hover:bg-slate-50" type="button" data-toggle="dropdown" aria-expanded="false">
                                <span class="inline-flex size-8 items-center justify-center rounded-full bg-primary text-[0.85rem] font-bold text-white shadow-[0_2px_5px_rgb(0_77_61/0.25)]">${f:cap(usuarioActual.nombre.substring(0, 1))}</span>
                                <span class="text-[0.9rem] font-semibold text-dark">${f:h(usuarioActual.nombre)}</span>
                                <i class="ri-arrow-down-s-line text-muted"></i>
                            </button>
                            <ul class="dropdown-menu dropdown-menu-end mt-2 border-0 shadow-lg">
                                <li>
                                    <div class="dropdown-item-text px-4 py-2 text-[0.875em] text-muted">
                                        <div class="font-bold text-dark">${f:h(usuarioActual.nombre)}</div>
                                        <div><i class="ri-shield-user-line me-1 text-success"></i> Rol: ${f:cap(usuarioActual.rol)}</div>
                                    </div>
                                </li>
                                <li><hr class="dropdown-divider my-1"></li>
                                <li><a class="dropdown-item ${nav == 'perfil' ? 'active' : ''} py-2" href="${ctx}/perfil"
                                       data-modal-url="${ctx}/perfil?modal=1"
                                       data-modal-title="Mi Perfil y Contraseña"
                                       data-modal-boton="Actualizar Contraseña">
                                    <i class="ri-user-settings-line me-2 text-primary"></i> Mi Perfil
                                </a></li>
                                <li><hr class="dropdown-divider my-1"></li>
                                <li><a class="dropdown-item py-2 text-danger" href="${ctx}/logout">
                                    <i class="ri-logout-box-r-line me-2"></i> Cerrar sesión
                                </a></li>
                            </ul>
                        </div>
                    </div>
                </div>
            </header>

            <div class="w-full grow px-6">
                <c:if test="${not empty sessionScope.mensaje}">
                    <div class="alert alert-${empty sessionScope.mensaje_tipo ? 'info' : sessionScope.mensaje_tipo} alert-dismissible fade show flex items-center gap-2 shadow-sm" role="alert">
                        <i class="ri-information-line text-xl"></i>
                        <div>${f:h(sessionScope.mensaje)}</div>
                        <button type="button" class="btn-close" data-dismiss="alert" aria-label="Cerrar"></button>
                    </div>
                    <c:remove var="mensaje" scope="session"/>
                    <c:remove var="mensaje_tipo" scope="session"/>
                </c:if>

                <jsp:doBody/>
            </div>

            <!-- Footer Institucional UNCP (como en los mockups) -->
            <footer class="app-footer mt-auto border-t bg-white px-6 py-4">
                <div class="flex flex-wrap items-center justify-between gap-2 text-[0.875em] text-muted">
                    <div class="flex items-center gap-2">
                        <img src="${ctx}/assets/img/uncp-escudo.png" alt="UNCP" class="size-5 rounded-full object-contain">
                        <span>&copy; 2026 <strong>Universidad Nacional del Centro del Per&uacute;</strong> &mdash; Oficina de Tecnolog&iacute;as de la Informaci&oacute;n</span>
                    </div>
                    <div class="flex items-center gap-4">
                        <span class="badge border bg-light px-2 py-1 text-secondary">Versi&oacute;n 2.0</span>
                        <a href="https://uncp.edu.pe" target="_blank" rel="noopener" class="flex items-center gap-1 text-secondary no-underline">
                            <i class="ri-global-line"></i> Portal UNCP
                        </a>
                    </div>
                </div>
            </footer>
        </main>
    </div>

    <!-- Asistente Inteligente OTI: disponible en todas las pantallas autenticadas -->
    <div class="oti-ai-root" id="otiAiRoot" data-ctx="${ctx}" data-role="${f:h(usuarioActual.rol)}" data-csrf="${f:h(csrf)}">
        <section class="oti-ai-panel" id="otiAiPanel" aria-label="Asistente Inteligente OTI" aria-hidden="true">
            <header class="oti-ai-head">
                <div class="oti-ai-avatar"><i class="ri-robot-2-line"></i></div>
                <div><div class="oti-ai-head-title">Asistente Inteligente OTI</div><div class="oti-ai-head-sub">PrestaEquipos · UNCP</div></div>
                <div class="oti-ai-head-actions">
                    <button type="button" class="oti-ai-icon-btn" id="otiAiSpeak" title="Leer última respuesta" aria-label="Leer última respuesta"><i class="ri-volume-up-line"></i></button>
                    <button type="button" class="oti-ai-icon-btn" id="otiAiClose" title="Cerrar asistente" aria-label="Cerrar asistente"><i class="ri-close-line"></i></button>
                </div>
            </header>
            <div class="oti-ai-shortcuts" aria-label="Accesos rápidos">
                <button type="button" class="oti-ai-shortcut" data-oti-ai-action="buscar"><i class="ri-search-line"></i> Buscar equipo</button>
                <button type="button" class="oti-ai-shortcut" data-oti-ai-action="solicitud"><i class="ri-file-add-line"></i> Solicitar equipo</button>
                <button type="button" class="oti-ai-shortcut" data-oti-ai-action="alertas"><i class="ri-calendar-check-line"></i> Mis devoluciones</button>
                <button type="button" class="oti-ai-shortcut" data-oti-ai-action="notificaciones"><i class="ri-notification-3-line"></i> Explicar avisos</button>
                <button type="button" class="oti-ai-shortcut" data-oti-ai-action="recomendaciones"><i class="ri-sparkling-line"></i> Recomendaciones</button>
                <c:if test="${esEncargado}"><a class="oti-ai-shortcut no-underline" href="${ctx}/ia/mantenimiento"><i class="ri-tools-line"></i> Mantenimiento</a></c:if>
            </div>
            <div class="oti-ai-messages" id="otiAiMessages" role="log" aria-live="polite"></div>
            <div class="oti-ai-compose">
                <form class="oti-ai-form" id="otiAiForm">
                    <input class="oti-ai-input" id="otiAiInput" type="text" maxlength="1200" autocomplete="off" placeholder="Escribe tu consulta…" aria-label="Escribe tu consulta">
                    <button class="oti-ai-mic" id="otiAiMic" type="button" title="Hablar" aria-label="Hablar"><i class="ri-mic-line"></i></button>
                    <button class="oti-ai-send" id="otiAiSend" type="submit" title="Enviar" aria-label="Enviar"><i class="ri-send-plane-fill"></i></button>
                </form>
                <p class="oti-ai-footnote">No compartas contraseñas ni información confidencial. Si la IA generativa está conectada, el texto se procesa mediante un proveedor externo. Verifica las respuestas antes de actuar.</p>
            </div>
        </section>
        <button type="button" class="oti-ai-toggle" id="otiAiToggle" aria-label="Abrir Asistente Inteligente OTI" aria-expanded="false"><i class="ri-robot-2-line"></i></button>
    </div>

    <!-- Modal genérico para los formularios flotantes del panel -->
    <div class="modal fade" id="modalFormulario" tabindex="-1" aria-labelledby="modalFormularioTitulo" aria-hidden="true">
        <div class="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable">
            <div class="modal-content border-0 shadow-lg">
                <div class="modal-header border-b px-6 py-4">
                    <h5 class="modal-title font-bold" id="modalFormularioTitulo">Formulario</h5>
                    <button type="button" class="btn-close" data-dismiss="modal" aria-label="Cerrar"></button>
                </div>
                <div class="modal-body p-6" id="modalFormularioCuerpo">
                    <div class="py-6 text-center">
                        <div class="spinner-border text-success" role="status"><span class="sr-only">Cargando...</span></div>
                    </div>
                </div>
                <div class="modal-footer border-t px-6 py-4">
                    <button type="button" class="btn btn-outline-secondary px-4" data-dismiss="modal">Cancelar</button>
                    <button type="button" class="btn btn-primary px-6" id="modalFormularioGuardar">
                        <i class="ri-checkbox-circle-line me-1"></i> Guardar
                    </button>
                </div>
            </div>
        </div>
    </div>

    <script src="${ctx}/assets/js/ui.js?v=20261113e"></script>
    <script src="https://cdn.jsdelivr.net/npm/tom-select@2.3.1/dist/js/tom-select.complete.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/jspdf@2.5.1/dist/jspdf.umd.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/jspdf-autotable@3.8.2/dist/jspdf.plugin.autotable.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script src="${ctx}/assets/js/sweetalert-config.js?v=20261113e"></script>
    <script src="${ctx}/assets/js/script.js?v=20261117n"></script>
    <script src="${ctx}/assets/js/modal.js?v=20261113e"></script>
    <script src="${ctx}/assets/js/buscador-select.js?v=20261113e"></script>
    <script src="${ctx}/assets/js/dni-lookup.js?v=20261113e"></script>
    <script src="${ctx}/assets/js/prestamo-usuarios.js?v=20261113e"></script>
    <script src="${ctx}/assets/js/notificaciones.js?v=20261113e"></script>
    <script src="${ctx}/assets/js/asistente-ia.js?v=20261114a"></script>
</body>
</html>
