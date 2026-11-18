<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="f" uri="http://universidad.edu/presta/funciones" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<t:layout title="${pageTitle}">

<c:choose>
<c:when test="${esEncargado}">
    <!-- ===== VISTA PARA ENCARGADOS Y ADMINISTRADORES ===== -->
    <c:if test="${tabActiva != 'solicitudes'}">
    <div class="flex justify-between items-center mb-6 flex-wrap gap-2">
        <div>
            <h4 class="mb-0 font-bold"><i class="ri-computer-line me-2 text-success"></i> Gestión de Equipos e Inventario</h4>
            <small class="text-muted">Administra el catálogo de equipos y atiende las solicitudes de usuarios</small>
        </div>
        <div class="flex gap-2">
            <div class="dropdown">
                <button class="btn btn-outline-secondary shadow-sm dropdown-toggle px-4" type="button" id="dropdownEstados" data-toggle="dropdown" aria-expanded="false">
                    <i class="ri-filter-3-line me-1"></i> Estado: ${empty estadoSel ? 'Todos' : infoEstados[estadoSel].label}
                </button>
                <ul class="dropdown-menu dropdown-menu-end shadow-sm" aria-labelledby="dropdownEstados">
                    <li><a class="dropdown-item ${empty estadoSel ? 'active' : ''}" href="${ctx}/equipos/listar">Todos los estados (${totalEquiposGeneral})</a></li>
                    <li><hr class="dropdown-divider"></li>
                    <c:forEach var="e" items="${infoEstados}">
                        <li>
                            <a class="dropdown-item flex justify-between items-center ${estadoSel == e.key ? 'active' : ''}" href="${ctx}/equipos/listar?estado=${e.key}">
                                <span><i class="${e.value.icono} me-2 ${e.value.colorTexto}"></i> ${e.value.label}</span>
                                <span class="badge bg-secondary rounded-full ms-2">${conteoEstados[e.key]}</span>
                            </a>
                        </li>
                    </c:forEach>
                </ul>
            </div>
            <button type="button" class="btn btn-primary"
                    data-modal-url="${ctx}/equipos/crear?modal=1"
                    data-modal-title="Registrar Nuevo Equipo"
                    data-modal-boton="Guardar Equipo">
                <i class="ri-add-line me-1"></i> Nuevo Equipo
            </button>
        </div>
    </div>
    </c:if>

    <!-- Pestañas -->
    <ul class="nav nav-pills mb-6" id="equiposTabs" role="tablist">
        <c:if test="${tabActiva != 'solicitudes'}">
        <li class="nav-item" role="presentation">
            <button class="nav-link ${tabActiva != 'solicitudes' ? 'active' : ''}" id="tab-inventario-btn" data-toggle="pill" data-target="#tab-inventario" type="button" role="tab" aria-controls="tab-inventario" aria-selected="${tabActiva != 'solicitudes'}">
                <i class="ri-apps-line me-1"></i> Catálogo de Equipos
                <span class="badge bg-light text-dark ms-1" id="badgeContadorPestana">${equipos.size()}</span>
            </button>
        </li>
        </c:if>


    </ul>

    <div class="tab-content" id="equiposTabsContent">

        <!-- PESTAÑA 1: INVENTARIO -->
        <c:if test="${tabActiva != 'solicitudes'}">
        <div class="tab-pane fade ${tabActiva != 'solicitudes' ? 'show active' : ''}" id="tab-inventario" role="tabpanel" aria-labelledby="tab-inventario-btn">

            <!-- Panel de búsqueda y filtros rápidos -->
            <div class="card shadow-sm border-0 mb-6 bg-white">
                <div class="card-body p-4 md:p-6">

                    <!-- Fila 1: buscador principal y controles -->
                    <form method="GET" action="${ctx}/equipos/listar" id="formFiltroEquipos" class="grid grid-cols-12 gap-4 items-end mb-4">
                        <div class="col-span-12 lg:col-span-5 md:col-span-6">
                            <label for="busqueda" class="form-label font-bold text-dark text-[0.875em] mb-1 flex justify-between">
                                <span><i class="ri-search-line text-success me-1"></i> Buscar Equipo</span>
                                <span class="text-muted font-normal text-[0.875em] hidden sm:inline" style="font-size: 0.75rem;">Filtrado en tiempo real</span>
                            </label>
                            <div class="input-group">
                                <span class="input-group-text bg-white border-e-0 text-muted"><i class="ri-search-line"></i></span>
                                <input type="text" class="form-control border-s-0 border-e-0 ps-0" id="busqueda" name="busqueda"
                                       placeholder="Nombre o código de inventario..." value="${f:h(busqueda)}" autocomplete="off">
                                <button class="btn btn-outline-secondary border-s-0 text-muted" type="button" id="btnLimpiarBusqueda" title="Limpiar búsqueda" style="${empty busqueda ? 'display:none;' : ''}">
                                    <i class="ri-close-circle-fill"></i>
                                </button>
                                <span class="input-group-text bg-light text-muted text-[0.875em] hidden md:flex" title="Atajo de teclado">
                                    <kbd class="bg-white text-muted border px-1" style="font-size:0.7rem;">Ctrl+K</kbd>
                                </span>
                            </div>
                        </div>

                        <div class="col-span-12 lg:col-span-3 md:col-span-3">
                            <label for="categoria_id" class="form-label font-bold text-dark text-[0.875em] mb-1"><i class="ri-price-tag-3-line text-success me-1"></i> Categoría</label>
                            <select class="form-select" id="categoria_id" name="categoria_id">
                                <option value="">Todas las categorías (${totalEquiposGeneral})</option>
                                <c:forEach var="cat" items="${categorias}">
                                    <option value="${cat.id}" data-nombre="${f:h(cat.nombre)}" ${categoriaSel == cat.id ? 'selected' : ''}>${f:h(cat.nombre)} (${cat.total})</option>
                                </c:forEach>
                            </select>
                        </div>

                        <div class="col-span-12 lg:col-span-2 md:col-span-3">
                            <label for="estado" class="form-label font-bold text-dark text-[0.875em] mb-1"><i class="ri-filter-line text-success me-1"></i> Estado</label>
                            <select class="form-select" id="estado" name="estado">
                                <option value="">Todos los estados</option>
                                <option value="disponible" ${estadoSel == 'disponible' ? 'selected' : ''}>Disponible (${conteoEstados['disponible']})</option>
                                <option value="prestado" ${estadoSel == 'prestado' ? 'selected' : ''}>Prestado (${conteoEstados['prestado']})</option>
                                <option value="mantenimiento" ${estadoSel == 'mantenimiento' ? 'selected' : ''}>En mantenimiento (${conteoEstados['mantenimiento']})</option>
                                <option value="dado_de_baja" ${estadoSel == 'dado_de_baja' ? 'selected' : ''}>Dado de baja (${conteoEstados['dado_de_baja']})</option>
                            </select>
                        </div>

                        <div class="col-span-12 lg:col-span-2 md:col-span-12 flex gap-2">
                            <button type="button" id="btnResetFiltros" class="btn btn-outline-secondary w-full" title="Restablecer todos los filtros">
                                <i class="ri-refresh-line me-1"></i> Limpiar
                            </button>
                        </div>
                    </form>

                    <!-- Fila 2: acceso rápido por categorías (chips de un clic) -->
                    <div class="pt-4 border-t">
                        <div class="flex justify-between items-center mb-2 flex-wrap gap-2">
                            <div class="text-[0.875em] font-bold text-dark uppercase flex items-center gap-1">
                                <i class="ri-flashlight-line text-warning"></i>
                                <span>CATEGORÍAS RÁPIDAS:</span>
                            </div>
                            <div class="text-[0.875em] text-muted" id="contadorEquiposTexto">
                                Mostrando <strong id="contadorEquiposVisibles" class="text-success">${equipos.size()}</strong> de ${totalEquiposGeneral} equipos
                            </div>
                        </div>

                        <div class="flex flex-wrap gap-2" id="contenedorChipsCategorias">
                            <button type="button" class="btn btn-sm ${empty categoriaSel ? 'btn-primary active' : 'btn-outline-secondary'} rounded-full px-4 py-1 chip-categoria-rapida font-semibold shadow-sm" data-id="" data-nombre="todas">
                                <i class="ri-apps-line me-1"></i> Todas
                                <span class="badge ${empty categoriaSel ? 'bg-white text-dark' : 'bg-secondary-subtle text-secondary'} ms-1 rounded-full">${totalEquiposGeneral}</span>
                            </button>
                            <c:forEach var="cat" items="${categorias}">
                                <c:set var="activa" value="${categoriaSel == cat.id}"/>
                                <button type="button" class="btn btn-sm ${activa ? 'btn-primary active' : 'btn-outline-secondary'} rounded-full px-4 py-1 chip-categoria-rapida font-semibold shadow-sm" data-id="${cat.id}" data-nombre="${f:h(cat.nombre)}">
                                    <i class="${empty iconosCat[cat.nombre] ? 'ri-box-3-line' : iconosCat[cat.nombre]} me-1"></i> ${f:h(cat.nombre)}
                                    <span class="badge ${activa ? 'bg-white text-dark' : 'bg-secondary-subtle text-secondary'} ms-1 rounded-full">${cat.total}</span>
                                </button>
                            </c:forEach>
                        </div>
                    </div>

                    <!-- Fila 3: filtro rápido por estados -->
                    <div class="pt-2 mt-2 flex flex-wrap items-center gap-2">
                        <span class="text-[0.875em] font-bold text-muted uppercase me-1" style="font-size: 0.75rem;"><i class="ri-sound-module-line me-1"></i> ESTADO:</span>
                        <button type="button" class="btn btn-sm ${empty estadoSel ? 'btn-dark text-white' : 'btn-outline-secondary'} rounded-full px-2 py-0 chip-estado-rapido" data-estado="" style="font-size: 0.8rem;">
                            Todos (${totalEquiposGeneral})
                        </button>
                        <button type="button" class="btn btn-sm ${estadoSel == 'disponible' ? 'btn-success text-white' : 'btn-outline-success'} rounded-full px-2 py-0 chip-estado-rapido" data-estado="disponible" style="font-size: 0.8rem;">
                            <i class="ri-checkbox-circle-line me-1"></i> Disponibles (${conteoEstados['disponible']})
                        </button>
                        <button type="button" class="btn btn-sm ${estadoSel == 'prestado' ? 'btn-info text-white' : 'btn-outline-info'} rounded-full px-2 py-0 chip-estado-rapido" data-estado="prestado" style="font-size: 0.8rem;">
                            <i class="ri-arrow-left-right-line me-1"></i> Prestados (${conteoEstados['prestado']})
                        </button>
                        <button type="button" class="btn btn-sm ${estadoSel == 'mantenimiento' ? 'btn-warning text-dark' : 'btn-outline-warning text-dark'} rounded-full px-2 py-0 chip-estado-rapido" data-estado="mantenimiento" style="font-size: 0.8rem;">
                            <i class="ri-tools-line me-1"></i> Mantenimiento (${conteoEstados['mantenimiento']})
                        </button>
                        <button type="button" class="btn btn-sm ${estadoSel == 'dado_de_baja' ? 'btn-danger text-white' : 'btn-outline-danger'} rounded-full px-2 py-0 chip-estado-rapido" data-estado="dado_de_baja" style="font-size: 0.8rem;">
                            <i class="ri-close-circle-line me-1"></i> Baja (${conteoEstados['dado_de_baja']})
                        </button>
                    </div>

                </div>
            </div>

            <!-- Tabla principal de equipos -->
            <div class="card shadow-sm border-0">
                <div class="card-header bg-white py-4 px-6 flex justify-between items-center flex-wrap gap-2">
                    <div class="flex items-center gap-2">
                        <h6 class="mb-0 text-dark font-bold"><i class="ri-archive-line me-2 text-success text-xl"></i> Catálogo de Equipos Registrados</h6>
                        <span class="badge bg-light text-dark border rounded-full px-2 py-1 text-[0.875em]" id="badgeTotalTabla">
                            <span id="spanTotalTabla">${equipos.size()}</span> equipos
                        </span>
                    </div>
                    <div class="flex items-center gap-2 flex-wrap">
                        <label for="selectRegistrosEquipos" class="text-[0.875em] text-muted mb-0">Mostrar</label>
                        <select id="selectRegistrosEquipos" class="form-select form-select-sm" style="width: auto;">
                            <option value="5">5</option>
                            <option value="10" selected>10</option>
                            <option value="15">15</option>
                            <option value="25">25</option>
                            <option value="50">50</option>
                            <option value="100">100</option>
                        </select>
                        <span class="text-[0.875em] text-muted">registros</span>
                        <button type="button" class="btn-export-excel" onclick="exportTableToCSV('tablaEquipos', 'inventario_equipos.csv')" title="Exportar filas visibles a Excel (CSV)">
                            <i class="ri-file-excel-2-line"></i> Excel
                        </button>
                        <button type="button" class="btn-export-pdf" onclick="exportTableToPDF('tablaEquipos', 'Inventario de Equipos', 'inventario_equipos.pdf')" title="Exportar filas visibles a PDF">
                            <i class="ri-file-pdf-2-line"></i> PDF
                        </button>
                    </div>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-hover align-middle mb-0" id="tablaEquipos">
                            <thead>
                                <tr>
                                    <th class="ps-6">Código</th>
                                    <th>Equipo</th>
                                    <th>Categoría</th>
                                    <th>Ubicación</th>
                                    <th>Estado</th>
                                    <th class="text-right pe-6">Acciones</th>
                                </tr>
                            </thead>
                            <tbody>
                                <c:forEach var="eqp" items="${equipos}">
                                    <c:set var="est" value="${infoEstados[eqp.estado]}"/>
                                    <tr class="fila-equipo"
                                        data-categoria-id="${eqp.categoriaId}"
                                        data-categoria-nombre="${f:h(eqp.categoriaNombre)}"
                                        data-estado="${f:h(eqp.estado)}"
                                        data-search="${f:h(eqp.textoBusqueda)}">
                                        <td class="ps-6"><span class="code-pill">${f:h(eqp.codigoInventario)}</span></td>
                                        <td>
                                            <div class="font-bold text-dark">${f:h(eqp.nombre)}</div>
                                            <c:if test="${not empty eqp.descripcion}">
                                                <small class="text-muted block truncate" style="max-width: 320px;">${f:h(eqp.descripcion)}</small>
                                            </c:if>
                                        </td>
                                        <td><span class="badge-cat-pill">${empty eqp.categoriaNombre ? 'Sin categoría' : f:h(eqp.categoriaNombre)}</span></td>
                                        <td><i class="ri-map-pin-line text-muted me-1"></i> ${empty eqp.ubicacion ? 'No asignada' : f:h(eqp.ubicacion)}</td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${eqp.estado == 'disponible'}">
                                                    <span class="badge badge-disponible"><i class="ri-checkbox-circle-fill"></i> Disponible</span>
                                                </c:when>
                                                <c:when test="${eqp.estado == 'prestado'}">
                                                    <span class="badge badge-prestado"><i class="ri-arrow-left-right-line"></i> Prestado</span>
                                                </c:when>
                                                <c:when test="${eqp.estado == 'mantenimiento'}">
                                                    <span class="badge badge-mantenimiento"><i class="ri-tools-line"></i> Mantenimiento</span>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="badge badge-baja"><i class="ri-close-circle-line"></i> Baja</span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td class="text-right pe-6">
                                            <div class="inline-flex gap-1" role="group">
                                                <button type="button" class="btn-action-icon btn-action-edit" title="Editar"
                                                        data-modal-url="${ctx}/equipos/editar?id=${eqp.id}&amp;modal=1"
                                                        data-modal-title="Editar Equipo"
                                                        data-modal-boton="Actualizar Equipo">
                                                    <i class="ri-edit-line"></i>
                                                </button>
                                                <c:if test="${esAdmin}">
                                                    <form method="POST" action="${ctx}/equipos/eliminar" class="inline form-eliminar" data-confirm="¿Está seguro de eliminar o dar de baja este equipo?">
                                                        <t:csrf/>
                                                        <input type="hidden" name="id" value="${eqp.id}">
                                                        <button type="submit" class="btn-action-icon btn-action-delete" title="Eliminar o dar de baja"><i class="ri-delete-bin-line"></i></button>
                                                    </form>
                                                </c:if>
                                            </div>
                                        </td>
                                    </tr>
                                </c:forEach>

                                <!-- Fila que se muestra cuando ningún resultado coincide con los filtros -->
                                <tr id="filaSinResultados" style="display: none;">
                                    <td colspan="6" class="text-center py-12">
                                        <div class="py-6">
                                            <i class="ri-search-line text-muted opacity-50" style="font-size: 3rem;"></i>
                                            <h6 class="mt-4 text-dark font-bold">No se encontraron equipos</h6>
                                            <p class="text-muted text-[0.875em] mb-4">No hay equipos que coincidan con la búsqueda o la categoría seleccionada.</p>
                                            <button type="button" class="btn btn-sm btn-outline-primary rounded-full px-4" id="btnRestablecerVacio">
                                                <i class="ri-refresh-line me-1"></i> Mostrar todos los equipos
                                            </button>
                                        </div>
                                    </td>
                                </tr>

                                <c:if test="${empty equipos}">
                                    <tr><td colspan="6" class="text-center text-muted py-12">
                                        <i class="ri-computer-line text-muted opacity-50" style="font-size: 3rem;"></i>
                                        <p class="mt-2 mb-0">No se encontraron equipos registrados en la base de datos.</p>
                                    </td></tr>
                                </c:if>
                            </tbody>
                        </table>
                    </div>
                </div>
                <div class="card-footer bg-white py-4 px-6 flex justify-between items-center flex-wrap gap-2" id="footerPaginacionEquipos">
                    <small class="text-muted mb-0" id="infoPaginacionEquipos"></small>
                    <nav aria-label="Paginación de equipos">
                        <ul class="pagination pagination-sm mb-0" id="paginacionEquipos"></ul>
                    </nav>
                </div>
            </div>
        </div>
        </c:if>

        <!-- PESTAÑA 2: SOLICITUDES -->
        <div class="tab-pane fade ${tabActiva == 'solicitudes' ? 'show active' : ''}" id="tab-solicitudes" role="tabpanel" aria-labelledby="tab-solicitudes-btn">
            <div class="mb-2">
                <h4 class="mb-0 font-bold"><i class="ri-inbox-line me-2 text-success"></i> Bandeja de Solicitudes de Equipos</h4>
                <small class="text-muted">Atiende las solicitudes de los usuarios</small>
            </div>
            <div class="card shadow-sm border-0">
                <div class="card-header bg-white py-4 px-6 flex justify-between items-center flex-wrap gap-2">
                    <h6 class="mb-0 text-dark font-bold"><i class="ri-inbox-line me-2 text-success text-xl"></i> Bandeja de Solicitudes de Equipos</h6>
                    <div class="flex gap-2">
                        <button type="button" class="btn-export-excel" onclick="exportTableToCSV('tablaSolicitudes', 'solicitudes_equipos.csv')" title="Exportar a Excel (CSV)">
                            <i class="ri-file-excel-2-line"></i> Excel
                        </button>
                        <button type="button" class="btn-export-pdf" onclick="exportTableToPDF('tablaSolicitudes', 'Bandeja de Solicitudes de Equipos', 'solicitudes_equipos.pdf')" title="Exportar a PDF">
                            <i class="ri-file-pdf-2-line"></i> PDF
                        </button>
                    </div>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-hover align-middle mb-0" id="tablaSolicitudes">
                            <thead>
                                <tr>
                                    <th class="ps-6">Usuario</th>
                                    <th>Equipo Solicitado</th>
                                    <th>Fecha Préstamo</th>
                                    <th>Fecha Devolución</th>
                                    <th>Oficina y Área</th>
                                    <th>Observaciones</th>
                                    <th>Estado</th>
                                    <th class="text-right pe-6">Acciones</th>
                                </tr>
                            </thead>
                            <tbody>
                                <c:forEach var="sol" items="${solicitudes}">
                                    <tr>
                                        <td class="ps-6">
                                            <div class="font-bold"><c:choose><c:when test="${empty sol.usuarioNombre}">Usuario #${sol.usuarioId}</c:when><c:otherwise>${f:h(sol.usuarioNombre)}</c:otherwise></c:choose></div>
                                            <small class="text-muted">${f:h(sol.usuarioEmail)}</small>
                                        </td>
                                        <td><span class="font-semibold text-dark">${f:h(sol.equipoSolicitado)}</span></td>
                                        <td>${f:fecha(sol.fechaPrestamo, 'dd/MM/yyyy HH:mm')}</td>
                                        <td>${f:fecha(sol.fechaDevolucion, 'dd/MM/yyyy HH:mm')}</td>
                                        <td>
                                            <div class="text-[0.875em] text-muted font-bold uppercase" style="font-size: 0.7rem; letter-spacing: 0.5px;">${f:h(sol.area)}</div>
                                            <div class="font-semibold">${f:h(sol.oficina)}</div>
                                        </td>
                                        <td><small class="text-muted">${empty sol.observaciones ? '-' : f:h(sol.observaciones)}</small></td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${sol.estado == 'aprobada'}">
                                                    <span class="badge badge-disponible"><i class="ri-checkbox-circle-fill"></i> Aprobada</span>
                                                </c:when>
                                                <c:when test="${sol.estado == 'prestado'}">
                                                    <span class="badge badge-prestado"><i class="ri-arrow-left-right-line"></i> Prestado</span>
                                                </c:when>
                                                <c:when test="${sol.estado == 'rechazada'}">
                                                    <span class="badge badge-vencido"><i class="ri-close-circle-fill"></i> Rechazada</span>
                                                </c:when>
                                                <c:when test="${sol.estado == 'devuelta'}">
                                                    <span class="badge badge-disponible"><i class="ri-arrow-go-back-line"></i> Devuelta</span>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="badge badge-mantenimiento"><i class="ri-time-line"></i> Pendiente</span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td class="text-right pe-6">
                                            <c:choose>
                                                <c:when test="${sol.estado == 'pendiente'}">
                                                    <c:if test="${not esAdmin and solicitudesRegistrables.contains(sol.id)}">
                                                        <button type="button" class="btn-action-icon btn-action-edit me-1" title="Registrar préstamo desde esta solicitud"
                                                                data-modal-url="${ctx}/prestamos/registrar?modal=1&amp;solicitud_id=${sol.id}"
                                                                data-modal-title="Registrar Préstamo"
                                                                data-modal-boton="Registrar Préstamo">
                                                            <i class="ri-add-circle-line"></i>
                                                        </button>
                                                    </c:if>
                                                    <c:if test="${esAdmin}">
                                                        <form method="POST" action="${ctx}/equipos/listar" class="inline">
                                                            <t:csrf/>
                                                            <input type="hidden" name="solicitud_id" value="${sol.id}">
                                                            <input type="hidden" name="accion" value="aprobar_solicitud">
                                                            <button type="submit" class="btn-action-icon btn-action-edit me-1" title="Aprobar solicitud"><i class="ri-check-line"></i></button>
                                                        </form>
                                                        <form method="POST" action="${ctx}/equipos/listar" class="inline">
                                                            <t:csrf/>
                                                            <input type="hidden" name="solicitud_id" value="${sol.id}">
                                                            <input type="hidden" name="accion" value="rechazar_solicitud">
                                                            <button type="submit" class="btn-action-icon btn-action-delete me-1" title="Rechazar solicitud"><i class="ri-close-line"></i></button>
                                                        </form>
                                                    </c:if>
                                                    <form method="POST" action="${ctx}/equipos/listar" class="inline form-eliminar" data-confirm="¿Está seguro de eliminar esta solicitud? Esta acción no se puede deshacer.">
                                                        <t:csrf/>
                                                        <input type="hidden" name="solicitud_id" value="${sol.id}">
                                                        <input type="hidden" name="accion" value="eliminar_solicitud">
                                                        <button type="submit" class="btn-action-icon btn-action-delete" title="Eliminar solicitud"><i class="ri-delete-bin-line"></i></button>
                                                    </form>
                                                </c:when>
                                                <c:when test="${sol.estado == 'aprobada'}">
                                                    <c:if test="${not esAdmin and solicitudesRegistrables.contains(sol.id)}">
                                                        <button type="button" class="btn-action-icon btn-action-edit me-1" title="Registrar préstamo desde esta solicitud"
                                                                data-modal-url="${ctx}/prestamos/registrar?modal=1&amp;solicitud_id=${sol.id}"
                                                                data-modal-title="Registrar Préstamo"
                                                                data-modal-boton="Registrar Préstamo">
                                                            <i class="ri-add-circle-line"></i>
                                                        </button>
                                                    </c:if>
                                                    <form method="POST" action="${ctx}/equipos/listar" class="inline form-eliminar" data-confirm="¿Está seguro de eliminar esta solicitud? Esta acción no se puede deshacer.">
                                                        <t:csrf/>
                                                        <input type="hidden" name="solicitud_id" value="${sol.id}">
                                                        <input type="hidden" name="accion" value="eliminar_solicitud">
                                                        <button type="submit" class="btn-action-icon btn-action-delete" title="Eliminar solicitud"><i class="ri-delete-bin-line"></i></button>
                                                    </form>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="text-muted text-[0.875em] me-1">Atendido</span>
                                                    <form method="POST" action="${ctx}/equipos/listar" class="inline form-eliminar" data-confirm="¿Está seguro de eliminar esta solicitud? Esta acción no se puede deshacer.">
                                                        <t:csrf/>
                                                        <input type="hidden" name="solicitud_id" value="${sol.id}">
                                                        <input type="hidden" name="accion" value="eliminar_solicitud">
                                                        <button type="submit" class="btn-action-icon btn-action-delete" title="Eliminar solicitud"><i class="ri-delete-bin-line"></i></button>
                                                    </form>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                    </tr>
                                </c:forEach>
                                <c:if test="${empty solicitudes}">
                                    <tr><td colspan="8" class="text-center text-muted py-12">
                                        <i class="ri-inbox-line text-muted opacity-50" style="font-size: 3rem;"></i>
                                        <p class="mt-4 mb-0">No hay solicitudes registradas.</p>
                                    </td></tr>
                                </c:if>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>

                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
    (function () {
        function paginar(idTabla, idPag, porPagina) {
            var tabla = document.getElementById(idTabla);
            var cont = document.getElementById(idPag);
            if (!tabla || !cont) return;
            var filas = Array.from(tabla.querySelectorAll('tbody tr'));
            var total = Math.ceil(filas.length / porPagina);
            if (total <= 1) { cont.style.display = 'none'; return; }
            var pagina = 1;
            function render() {
                filas.forEach(function (fila, idx) {
                    fila.style.display = (idx >= (pagina - 1) * porPagina && idx < pagina * porPagina) ? '' : 'none';
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
        paginar('encPrestando', 'pagEncPrestando', 5);
        paginar('encDevueltos', 'pagEncDevueltos', 5);
    })();
    </script>

    <script>
    document.addEventListener('DOMContentLoaded', function () {
        const inputBusqueda = document.getElementById('busqueda');
        const selectCategoria = document.getElementById('categoria_id');
        const selectEstado = document.getElementById('estado');
        const btnLimpiar = document.getElementById('btnLimpiarBusqueda');
        const btnReset = document.getElementById('btnResetFiltros');
        const btnRestablecerVacio = document.getElementById('btnRestablecerVacio');
        const chipsCategorias = document.querySelectorAll('.chip-categoria-rapida');
        const chipsEstados = document.querySelectorAll('.chip-estado-rapido');
        const filasEquipos = document.querySelectorAll('.fila-equipo');
        const filaSinResultados = document.getElementById('filaSinResultados');
        const contadorVisibles = document.getElementById('contadorEquiposVisibles');
        const spanTotalTabla = document.getElementById('spanTotalTabla');

        if (!filasEquipos.length) return;

        let categoriaFiltro = selectCategoria ? selectCategoria.value : '';
        let estadoFiltro = selectEstado ? selectEstado.value : '';

        // Paginación: cantidad de registros visible por página (configurable)
        let registrosPorPagina = 10;
        const selectRegistrosEquipos = document.getElementById('selectRegistrosEquipos');
        if (selectRegistrosEquipos) {
            registrosPorPagina = parseInt(selectRegistrosEquipos.value, 10) || 10;
        }
        let paginaActual = 1;
        let filasFiltradas = [];

        function aplicarFiltros() {
            const textoBusqueda = (inputBusqueda ? inputBusqueda.value : '').trim().toLowerCase();
            
            if (btnLimpiar) {
                btnLimpiar.style.display = textoBusqueda ? 'block' : 'none';
            }

            let contador = 0;
            filasFiltradas = [];

            filasEquipos.forEach(fila => {
                const filaCatId = fila.getAttribute('data-categoria-id') || '';
                const filaEstado = fila.getAttribute('data-estado') || '';
                const searchData = fila.getAttribute('data-search') || '';

                const cumpleCategoria = (!categoriaFiltro || filaCatId === categoriaFiltro);
                const cumpleEstado = (!estadoFiltro || filaEstado === estadoFiltro);
                const cumpleTexto = (!textoBusqueda || searchData.includes(textoBusqueda));

                if (cumpleCategoria && cumpleEstado && cumpleTexto) {
                    filasFiltradas.push(fila);
                    contador++;
                } else {
                    fila.style.display = 'none';
                }
            });

            if (contadorVisibles) contadorVisibles.textContent = contador;
            if (spanTotalTabla) spanTotalTabla.textContent = contador;

            if (filaSinResultados) {
                filaSinResultados.style.display = (contador === 0) ? '' : 'none';
            }

            paginaActual = 1;
            paginarEquipos();
        }

        function paginarEquipos() {
            const totalPaginas = Math.ceil(filasFiltradas.length / registrosPorPagina);
            if (paginaActual > totalPaginas) paginaActual = totalPaginas || 1;

            const inicio = (paginaActual - 1) * registrosPorPagina;
            const fin = inicio + registrosPorPagina;

            filasFiltradas.forEach((fila, idx) => {
                if (idx >= inicio && idx < fin) {
                    fila.style.display = '';
                } else {
                    fila.style.display = 'none';
                }
            });

            const info = document.getElementById('infoPaginacionEquipos');
            if (info) {
                if (!filasFiltradas.length) {
                    info.textContent = 'No hay equipos para mostrar';
                } else {
                    info.textContent = 'Mostrando ' + (inicio + 1) + '–' + Math.min(fin, filasFiltradas.length) +
                        ' de ' + filasFiltradas.length + ' registros';
                }
            }

            renderPaginacionEquipos(totalPaginas);
        }

        function paginasVisibles(total, actual) {
            if (total <= 7) {
                const arr = [];
                for (let i = 1; i <= total; i++) arr.push(i);
                return arr;
            }
            if (actual <= 4) return [1, 2, 3, 4, 5, '...', total];
            if (actual >= total - 3) return [1, '...', total - 4, total - 3, total - 2, total - 1, total];
            return [1, '...', actual - 1, actual, actual + 1, '...', total];
        }

        function renderPaginacionEquipos(totalPaginas) {
            const contenedor = document.getElementById('paginacionEquipos');
            if (!contenedor) return;
            contenedor.innerHTML = '';

            const nav = contenedor.closest('nav');
            if (nav) nav.style.display = totalPaginas > 1 ? '' : 'none';
            if (totalPaginas <= 1) return;

            function crearItem(texto, destino, opciones) {
                opciones = opciones || {};
                const li = document.createElement('li');
                li.className = 'page-item' + (opciones.activo ? ' active' : '') + (opciones.deshabilitado ? ' disabled' : '');
                const boton = document.createElement('button');
                boton.type = 'button';
                boton.className = 'page-link';
                boton.innerHTML = texto;
                if (opciones.titulo) boton.title = opciones.titulo;
                if (!opciones.deshabilitado && !opciones.activo) {
                    boton.addEventListener('click', function () { irAPaginaEquipos(destino); });
                }
                li.appendChild(boton);
                contenedor.appendChild(li);
            }

            crearItem('<i class="ri-arrow-left-s-line"></i>', paginaActual - 1, {
                deshabilitado: paginaActual === 1,
                titulo: 'Página anterior'
            });

            paginasVisibles(totalPaginas, paginaActual).forEach(function (pagina) {
                if (pagina === '...') {
                    const li = document.createElement('li');
                    li.className = 'page-item disabled';
                    li.innerHTML = '<span class="page-link">…</span>';
                    contenedor.appendChild(li);
                } else {
                    crearItem(String(pagina), pagina, { activo: pagina === paginaActual });
                }
            });

            crearItem('<i class="ri-arrow-right-s-line"></i>', paginaActual + 1, {
                deshabilitado: paginaActual === totalPaginas,
                titulo: 'Página siguiente'
            });
        }

        function irAPaginaEquipos(pagina) {
            paginaActual = pagina;
            paginarEquipos();
            const tabla = document.getElementById('tablaEquipos');
            if (tabla) {
                const y = tabla.getBoundingClientRect().top + window.pageYOffset - 100;
                window.scrollTo({ top: y, behavior: 'smooth' });
            }
        }

        // Búsqueda instantánea mientras se escribe
        if (inputBusqueda) {
            inputBusqueda.addEventListener('input', aplicarFiltros);
            
            // Atajo de teclado Ctrl+K para enfocar el buscador
            window.addEventListener('keydown', function(e) {
                if ((e.ctrlKey || e.metaKey) && (e.key === 'k' || e.key === 'K')) {
                    e.preventDefault();
                    inputBusqueda.focus();
                    inputBusqueda.select();
                }
            });
        }

        if (btnLimpiar) {
            btnLimpiar.addEventListener('click', function() {
                if (inputBusqueda) {
                    inputBusqueda.value = '';
                    aplicarFiltros();
                    inputBusqueda.focus();
                }
            });
        }

        // Sincronización al cambiar el dropdown de categoría
        if (selectCategoria) {
            selectCategoria.addEventListener('change', function() {
                categoriaFiltro = this.value;
                actualizarChipsCategoria(categoriaFiltro);
                aplicarFiltros();
            });
        }

        // Sincronización al cambiar el dropdown de estado
        if (selectEstado) {
            selectEstado.addEventListener('change', function() {
                estadoFiltro = this.value;
                actualizarChipsEstado(estadoFiltro);
                aplicarFiltros();
            });
        }

        // Actualizar chips de categoría
        function actualizarChipsCategoria(idSeleccionado) {
            chipsCategorias.forEach(chip => {
                const chipId = chip.getAttribute('data-id') || '';
                const isActive = (chipId === idSeleccionado) || (!idSeleccionado && !chipId);
                if (isActive) {
                    chip.classList.remove('btn-outline-secondary');
                    chip.classList.add('btn-primary', 'active');
                    const badge = chip.querySelector('.badge');
                    if (badge) {
                        badge.classList.remove('bg-secondary-subtle', 'text-secondary');
                        badge.classList.add('bg-white', 'text-dark');
                    }
                } else {
                    chip.classList.remove('btn-primary', 'active');
                    chip.classList.add('btn-outline-secondary');
                    const badge = chip.querySelector('.badge');
                    if (badge) {
                        badge.classList.remove('bg-white', 'text-dark');
                        badge.classList.add('bg-secondary-subtle', 'text-secondary');
                    }
                }
            });
        }

        // Clic en chips de categorías
        chipsCategorias.forEach(chip => {
            chip.addEventListener('click', function() {
                const chipId = this.getAttribute('data-id') || '';
                categoriaFiltro = chipId;
                if (selectCategoria) {
                    selectCategoria.value = chipId;
                }
                actualizarChipsCategoria(chipId);
                aplicarFiltros();
            });
        });

        // Actualizar chips de estados
        function actualizarChipsEstado(valEstado) {
            chipsEstados.forEach(chip => {
                const chipEstado = chip.getAttribute('data-estado') || '';
                const isActive = (chipEstado === valEstado);
                if (chipEstado === '') {
                    chip.className = 'btn btn-sm rounded-full px-2 py-0 chip-estado-rapido ' + (isActive ? 'btn-dark text-white' : 'btn-outline-secondary');
                } else if (chipEstado === 'disponible') {
                    chip.className = 'btn btn-sm rounded-full px-2 py-0 chip-estado-rapido ' + (isActive ? 'btn-success text-white' : 'btn-outline-success');
                } else if (chipEstado === 'prestado') {
                    chip.className = 'btn btn-sm rounded-full px-2 py-0 chip-estado-rapido ' + (isActive ? 'btn-info text-white' : 'btn-outline-info');
                } else if (chipEstado === 'mantenimiento') {
                    chip.className = 'btn btn-sm rounded-full px-2 py-0 chip-estado-rapido ' + (isActive ? 'btn-warning text-dark' : 'btn-outline-warning text-dark');
                } else if (chipEstado === 'dado_de_baja') {
                    chip.className = 'btn btn-sm rounded-full px-2 py-0 chip-estado-rapido ' + (isActive ? 'btn-danger text-white' : 'btn-outline-danger');
                }
            });
        }

        // Clic en chips de estado
        chipsEstados.forEach(chip => {
            chip.addEventListener('click', function() {
                const chipEstado = this.getAttribute('data-estado') || '';
                estadoFiltro = chipEstado;
                if (selectEstado) {
                    selectEstado.value = chipEstado;
                }
                actualizarChipsEstado(chipEstado);
                aplicarFiltros();
            });
        });

        // Botón para resetear todo
        function resetearTodo() {
            if (inputBusqueda) inputBusqueda.value = '';
            if (selectCategoria) selectCategoria.value = '';
            if (selectEstado) selectEstado.value = '';
            categoriaFiltro = '';
            estadoFiltro = '';
            actualizarChipsCategoria('');
            actualizarChipsEstado('');
            aplicarFiltros();
            if (inputBusqueda) inputBusqueda.focus();
        }

        if (btnReset) {
            btnReset.addEventListener('click', resetearTodo);
        }
        if (btnRestablecerVacio) {
            btnRestablecerVacio.addEventListener('click', resetearTodo);
        }

        if (selectRegistrosEquipos) {
            selectRegistrosEquipos.addEventListener('change', function () {
                registrosPorPagina = parseInt(this.value, 10) || 10;
                paginaActual = 1;
                paginarEquipos();
            });
        }

        const formFiltro = document.getElementById('formFiltroEquipos');
        if (formFiltro) {
            formFiltro.addEventListener('submit', function(e) {
                e.preventDefault();
                aplicarFiltros();
            });
        }

        actualizarChipsCategoria(categoriaFiltro);
        actualizarChipsEstado(estadoFiltro);
        aplicarFiltros();
    });
    </script>
</c:when>

<c:otherwise>
    <!-- ===== VISTA PARA USUARIOS NORMALES ===== -->
    <c:set var="tabCatalogo" value="${tabActiva != 'mis_solicitudes'}"/>
    <div class="flex justify-between items-center flex-wrap gap-4 mb-6">
        <div>
            <h4 class="mb-1 font-bold"><i class="ri-computer-line me-2 text-success"></i> Catálogo y Solicitud de Equipos</h4>
            <p class="text-muted mb-0">Consulta los equipos disponibles en la universidad y solicita el préstamo para tu oficina</p>
        </div>
        <button type="button" class="btn btn-primary"
                data-modal-url="${ctx}/equipos/solicitud?modal=1"
                data-modal-title="Formulario de Solicitud de Equipo"
                data-modal-boton="Enviar Solicitud">
            <i class="ri-send-plane-fill me-1"></i> Nueva Solicitud
        </button>
    </div>

    <ul class="nav nav-pills mb-6" id="userTabs" role="tablist">
        <li class="nav-item" role="presentation">
            <button class="nav-link ${tabCatalogo ? 'active' : ''}" id="tab-catalogo-btn" data-toggle="pill" data-target="#tab-catalogo" type="button" role="tab">
                <i class="ri-apps-line me-1"></i> Catálogo por Categorías (${equiposCatalogo.size()})
            </button>
        </li>

    </ul>

    <div class="tab-content" id="userTabsContent">

        <!-- CATÁLOGO POR CATEGORÍAS -->
        <div class="tab-pane fade ${tabCatalogo ? 'show active' : ''}" id="tab-catalogo" role="tabpanel">

            <!-- Panel de categorías y filtros -->
            <div class="card shadow-sm border-0 mb-6 bg-white">
                <div class="card-body p-4 md:p-6">
                    <div class="grid grid-cols-12 gap-4 items-center mb-4">
                        <div class="col-span-12 md:col-span-7">
                            <label class="form-label text-[0.875em] font-bold text-muted uppercase mb-1">
                                <i class="ri-search-line me-1"></i> BUSCAR EN EL CATÁLOGO (${equiposCatalogo.size()} EQUIPOS)
                            </label>
                            <div class="input-group">
                                <span class="input-group-text bg-white"><i class="ri-search-line text-muted"></i></span>
                                <input type="text" id="catalogo-buscar-texto" class="form-control" placeholder="Escribe el nombre, código (ej: LPT-001) o ubicación...">
                                <button class="btn btn-outline-secondary" type="button" id="catalogo-btn-limpiar" title="Limpiar búsqueda"><i class="ri-close-line"></i></button>
                            </div>
                        </div>
                        <div class="col-span-12 md:col-span-5">
                            <label class="form-label text-[0.875em] font-bold text-muted uppercase mb-1"><i class="ri-filter-line me-1"></i> ESTADO DEL EQUIPO</label>
                            <select id="catalogo-filtro-estado" class="form-select">
                                <option value="todos">Todos los equipos (${equiposCatalogo.size()})</option>
                                <option value="disponible" selected>Solo Disponibles (${equiposDisponibles.size()})</option>
                                <option value="mantenimiento">En Mantenimiento (${conteoEstados['mantenimiento']})</option>
                                <option value="dado_de_baja">Dados de baja (${conteoEstados['dado_de_baja']})</option>
                            </select>
                        </div>
                    </div>

                    <!-- Sección de categorías -->
                    <div class="pt-4 border-t">
                        <div class="flex justify-between items-center mb-2">
                            <span class="text-[0.875em] font-bold text-dark uppercase"><i class="ri-price-tag-3-line text-success me-1"></i> SECCIÓN DE CATEGORÍAS</span>
                            <span class="text-[0.875em] text-muted" id="catalogo-contador-texto">
                                Mostrando <strong id="catalogo-total-visible" class="text-success">${equiposDisponibles.size()}</strong> de ${equiposCatalogo.size()} equipos
                            </span>
                        </div>
                        <div class="flex flex-wrap gap-2" id="catalogo-chips-categorias">
                            <button type="button" class="btn btn-sm btn-primary rounded-full px-4 chip-categoria active" data-categoria="todas">
                                <i class="ri-apps-line me-1"></i> Todas las Categorías
                                <span class="badge bg-white text-dark ms-1">${equiposCatalogo.size()}</span>
                            </button>
                            <c:forEach var="cat" items="${categoriasCatalogo}">
                                <button type="button" class="btn btn-sm btn-outline-secondary rounded-full px-4 chip-categoria" data-categoria="${f:h(cat.nombre)}">
                                    <i class="${empty iconosCat[cat.nombre] ? 'ri-box-3-line' : iconosCat[cat.nombre]} me-1"></i> ${f:h(cat.nombre)}
                                    <span class="badge bg-secondary-subtle text-secondary ms-1">${cat.total}</span>
                                </button>
                            </c:forEach>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Listado de tarjetas de equipos (como en el mockup) -->
            <div class="grid grid-cols-12 gap-4" id="catalogo-lista-equipos">
                <c:forEach var="eqp" items="${equiposCatalogo}">
                    <c:set var="icono" value="${empty iconosCat[eqp.categoriaNombre] ? 'ri-box-3-line' : iconosCat[eqp.categoriaNombre]}"/>
                    <c:set var="esDisponible" value="${eqp.estado == 'disponible'}"/>
                    <div class="col-span-12 lg:col-span-4 md:col-span-6 tarjeta-equipo-item"
                         data-categoria="${f:h(eqp.categoriaNombre)}"
                         data-estado="${f:h(eqp.estado)}"
                         data-search="${f:h(eqp.textoCatalogo)}">
                        <div class="user-equipment-card shadow-sm">
                            <div>
                                <div class="flex justify-between items-start mb-2">
                                    <span class="badge-cat-pill">
                                        <i class="${icono} me-1"></i>${f:h(eqp.categoriaNombre)}
                                    </span>
                                    <c:choose>
                                        <c:when test="${esDisponible}"><span class="badge badge-disponible">Disponible</span></c:when>
                                        <c:when test="${eqp.estado == 'mantenimiento'}"><span class="badge badge-mantenimiento">Mantenimiento</span></c:when>
                                        <c:when test="${eqp.estado == 'prestado'}"><span class="badge badge-prestado">Prestado</span></c:when>
                                        <c:otherwise><span class="badge badge-baja">Baja</span></c:otherwise>
                                    </c:choose>
                                </div>

                                <div class="mb-2">
                                    <span class="code-pill">${f:h(eqp.codigoInventario)}</span>
                                </div>

                                <h6 class="font-bold text-dark mb-1">${f:h(eqp.nombre)}</h6>
                                <p class="text-muted text-[0.875em] mb-4">${empty eqp.descripcion ? 'Sin descripción detallada.' : f:h(eqp.descripcion)}</p>
                            </div>

                            <div class="flex justify-between items-center pt-4 border-t mt-auto">
                                <small class="text-muted"><i class="ri-map-pin-line me-1"></i> ${empty eqp.ubicacion ? 'Central' : f:h(eqp.ubicacion)}</small>
                                <c:choose>
                                    <c:when test="${esDisponible}">
                                        <button type="button" class="btn-solicitar-card"
                                                data-nombre="${f:h(eqp.nombre)} (${f:h(eqp.codigoInventario)})"
                                                onclick="seleccionarEquipoSolicitud(this.dataset.nombre)">
                                            Solicitar <i class="ri-arrow-right-line"></i>
                                        </button>
                                    </c:when>
                                    <c:otherwise>
                                        <button type="button" class="btn btn-sm btn-outline-secondary" disabled title="Este equipo no se encuentra disponible actualmente">No disponible</button>
                                    </c:otherwise>
                                </c:choose>
                            </div>
                        </div>
                    </div>
                </c:forEach>

                <div class="col-span-12 text-center py-12 text-muted hidden" id="catalogo-sin-resultados">
                    <i class="ri-search-line text-secondary" style="font-size: 3rem;"></i>
                    <h6 class="mt-2 font-bold text-dark">No se encontraron equipos</h6>
                    <p class="text-[0.875em] text-muted mb-4">Intenta cambiar la categoría o el término de búsqueda.</p>
                    <button type="button" class="btn btn-sm btn-outline-primary" id="catalogo-btn-reset-filtros">
                        <i class="ri-refresh-line me-1"></i> Restablecer filtros
                    </button>
                </div>
            </div>

            <!-- Paginación del catálogo: 9 equipos por página -->
            <div class="flex justify-between items-center flex-wrap gap-2 mt-6" id="footerPaginacionCatalogo">
                <small class="text-muted" id="infoPaginacionCatalogo"></small>
                <nav aria-label="Paginación del catálogo">
                    <ul class="pagination pagination-sm mb-0" id="paginacionCatalogo"></ul>
                </nav>
            </div>
        </div>

        <!-- MIS SOLICITUDES -->
        <div class="tab-pane fade ${tabActiva == 'mis_solicitudes' ? 'show active' : ''}" id="tab-mis-solicitudes" role="tabpanel">
            <!-- Selector de registros por página -->
            <div class="flex justify-end gap-2 mb-4 flex-wrap items-center">
                <label for="selectRegistrosMisSol" class="text-[0.875em] text-muted mb-0">Mostrar</label>
                <select id="selectRegistrosMisSol" class="form-select form-select-sm" style="width: auto;">
                    <option value="5">5</option>
                    <option value="10" selected>10</option>
                    <option value="15">15</option>
                    <option value="25">25</option>
                    <option value="50">50</option>
                    <option value="100">100</option>
                </select>
                <span class="text-[0.875em] text-muted">registros</span>
            </div>

            <!-- Exportar ambas tablas -->
            <div class="flex justify-end gap-2 mb-4 flex-wrap">
                <button type="button" class="btn-export-excel" onclick="exportarMisSolicitudesExcel()" title="Exportar ambas tablas a Excel">
                    <i class="ri-file-excel-2-line"></i> Excel (ambos cuadros)
                </button>
                <button type="button" class="btn-export-pdf" onclick="exportarMisSolicitudesPDF()" title="Exportar ambas tablas a PDF">
                    <i class="ri-file-pdf-2-line"></i> PDF (ambos cuadros)
                </button>
            </div>

            <!-- Pendientes -->
            <div class="card shadow-sm border-0 mb-6">
                <div class="card-header bg-white py-4 px-6 flex flex-wrap justify-between items-center gap-2">
                    <h6 class="mb-0 text-dark font-bold"><i class="ri-time-line me-2 text-warning text-xl"></i> Solicitudes Pendientes</h6>
                    <div class="flex gap-2">
                        <button type="button" class="btn-export-excel" onclick="exportTableToCSV('tablaMisSolicitudesPendientes', 'mis_solicitudes_pendientes.csv')" title="Exportar a Excel (CSV)"><i class="ri-file-excel-2-line"></i> Excel</button>
                        <button type="button" class="btn-export-pdf" onclick="exportTableToPDF('tablaMisSolicitudesPendientes', 'Mis Solicitudes - Pendientes', 'mis_solicitudes_pendientes.pdf')" title="Exportar a PDF"><i class="ri-file-pdf-2-line"></i> PDF</button>
                    </div>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-hover align-middle mb-0" id="tablaMisSolicitudesPendientes">
                            <thead>
                                <tr>
                                    <th class="ps-6">Equipo Solicitado</th>
                                    <th>Fecha Solicitud</th>
                                    <th>Período Solicitado</th>
                                    <th>Oficina Destino</th>
                                    <th class="pe-6">Estado</th>
                                </tr>
                            </thead>
                            <tbody>
                                <c:set var="hayPend" value="false"/>
                                <c:forEach var="ms" items="${misSolicitudes}">
                                    <c:if test="${ms.estado eq 'pendiente'}">
                                        <c:set var="hayPend" value="true"/>
                                        <tr>
                                            <td class="ps-6 font-bold">${f:h(ms.equipoSolicitado)}</td>
                                            <td>${f:fecha(ms.fechaSolicitud, 'dd/MM/yyyy HH:mm')}</td>
                                            <td>
                                                <small class="block">Desde: ${f:fecha(ms.fechaPrestamo, 'dd/MM/yyyy HH:mm')}</small>
                                                <small class="block">Hasta: ${f:fecha(ms.fechaDevolucion, 'dd/MM/yyyy HH:mm')}</small>
                                            </td>
                                            <td>${f:h(ms.oficina)}</td>
                                            <td class="pe-6"><span class="badge badge-mantenimiento"><i class="ri-time-line"></i> Pendiente</span></td>
                                        </tr>
                                    </c:if>
                                </c:forEach>
                                <c:if test="${!hayPend}">
                                    <tr><td colspan="5" class="text-center text-muted py-8">No tienes solicitudes pendientes.</td></tr>
                                </c:if>
                            </tbody>
                        </table>
                    </div>
                    <div class="card-footer bg-white py-3 px-6">
                        <nav><ul class="pagination pagination-sm mb-0" id="pagMisSolicitudesPendientes"></ul></nav>
                    </div>
                </div>
            </div>

            <!-- Atendidas -->
            <div class="card shadow-sm border-0">
                <div class="card-header bg-white py-4 px-6 flex flex-wrap justify-between items-center gap-2">
                    <h6 class="mb-0 text-dark font-bold"><i class="ri-checkbox-circle-line me-2 text-success text-xl"></i> Solicitudes Atendidas</h6>
                    <div class="flex gap-2">
                        <button type="button" class="btn-export-excel" onclick="exportTableToCSV('tablaMisSolicitudesAtendidas', 'mis_solicitudes_atendidas.csv')" title="Exportar a Excel (CSV)"><i class="ri-file-excel-2-line"></i> Excel</button>
                        <button type="button" class="btn-export-pdf" onclick="exportTableToPDF('tablaMisSolicitudesAtendidas', 'Mis Solicitudes - Atendidas', 'mis_solicitudes_atendidas.pdf')" title="Exportar a PDF"><i class="ri-file-pdf-2-line"></i> PDF</button>
                    </div>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-hover align-middle mb-0" id="tablaMisSolicitudesAtendidas">
                            <thead>
                                <tr>
                                    <th class="ps-6">Equipo Solicitado</th>
                                    <th>Fecha Solicitud</th>
                                    <th>Período Solicitado</th>
                                    <th>Oficina Destino</th>
                                    <th class="pe-6">Estado</th>
                                </tr>
                            </thead>
                            <tbody>
                                <c:set var="hayAtend" value="false"/>
                                <c:forEach var="ms" items="${misSolicitudes}">
                                    <c:if test="${ms.estado ne 'pendiente'}">
                                        <c:set var="hayAtend" value="true"/>
                                        <tr>
                                            <td class="ps-6 font-bold">${f:h(ms.equipoSolicitado)}</td>
                                            <td>${f:fecha(ms.fechaSolicitud, 'dd/MM/yyyy HH:mm')}</td>
                                            <td>
                                                <small class="block">Desde: ${f:fecha(ms.fechaPrestamo, 'dd/MM/yyyy HH:mm')}</small>
                                                <small class="block">Hasta: ${f:fecha(ms.fechaDevolucion, 'dd/MM/yyyy HH:mm')}</small>
                                            </td>
                                            <td>${f:h(ms.oficina)}</td>
                                            <td class="pe-6">
                                                <c:choose>
                                                    <c:when test="${ms.estado eq 'aprobada'}">
                                                        <span class="badge badge-disponible"><i class="ri-checkbox-circle-fill"></i> Aprobada</span>
                                                    </c:when>
                                                    <c:when test="${ms.estado eq 'prestado'}">
                                                        <span class="badge badge-prestado"><i class="ri-arrow-left-right-line"></i> Prestado</span>
                                                    </c:when>
                                                    <c:when test="${ms.estado eq 'rechazada'}">
                                                        <span class="badge badge-vencido"><i class="ri-close-circle-fill"></i> Rechazada</span>
                                                    </c:when>
                                                    <c:when test="${ms.estado eq 'devuelta'}">
                                                        <span class="badge badge-disponible"><i class="ri-arrow-go-back-line"></i> Devuelta</span>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <span class="badge badge-mantenimiento"><i class="ri-time-line"></i> ${f:cap(ms.estado)}</span>
                                                    </c:otherwise>
                                                </c:choose>
                                            </td>
                                        </tr>
                                    </c:if>
                                </c:forEach>
                                <c:if test="${!hayAtend}">
                                    <tr><td colspan="5" class="text-center text-muted py-8">No tienes solicitudes atendidas.</td></tr>
                                </c:if>
                            </tbody>
                        </table>
                    </div>
                    <div class="card-footer bg-white py-3 px-6">
                        <nav><ul class="pagination pagination-sm mb-0" id="pagMisSolicitudesAtendidas"></ul></nav>
                    </div>
                </div>
            </div>

            <script>
            (function () {
                var select = document.getElementById('selectRegistrosMisSol');
                function paginar(idTabla, idPag) {
                    var tabla = document.getElementById(idTabla);
                    var cont = document.getElementById(idPag);
                    if (!tabla || !cont) return;
                    var filas = Array.from(tabla.querySelectorAll('tbody tr'));
                    var pp = select ? (parseInt(select.value, 10) || 5) : 5;
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
                paginar('tablaMisSolicitudesPendientes', 'pagMisSolicitudesPendientes');
                paginar('tablaMisSolicitudesAtendidas', 'pagMisSolicitudesAtendidas');
                if (select) select.addEventListener('change', function () {
                    paginar('tablaMisSolicitudesPendientes', 'pagMisSolicitudesPendientes');
                    paginar('tablaMisSolicitudesAtendidas', 'pagMisSolicitudesAtendidas');
                });
            })();
            </script>
            <script>
            function exportarMisSolicitudesExcel() {
                exportMultipleTablesToCSV(['tablaMisSolicitudesPendientes', 'tablaMisSolicitudesAtendidas'], 'mis_solicitudes_completo.csv');
            }
            function exportarMisSolicitudesPDF() {
                exportMultipleTablesToPDF([
                    { id: 'tablaMisSolicitudesPendientes', title: 'Mis Solicitudes - Pendientes' },
                    { id: 'tablaMisSolicitudesAtendidas', title: 'Mis Solicitudes - Atendidas' }
                ], 'mis_solicitudes_completo.pdf');
            }
            </script>
        </div>
    </div>

    <script>
        function seleccionarEquipoSolicitud(nombre) {
            if (window.abrirModal) {
                window.abrirModal('${ctx}/equipos/solicitud?modal=1&busqueda=' + encodeURIComponent(nombre),
                    'Formulario de Solicitud de Equipo',
                    { textoBoton: 'Enviar Solicitud' });
                return;
            }
            window.location.href = '${ctx}/equipos/solicitud';
        }

        document.addEventListener('DOMContentLoaded', function () {
            const inputBuscar = document.getElementById('catalogo-buscar-texto');
            const selectEstado = document.getElementById('catalogo-filtro-estado');
            const btnLimpiar = document.getElementById('catalogo-btn-limpiar');
            const btnReset = document.getElementById('catalogo-btn-reset-filtros');
            const chipsCategorias = document.querySelectorAll('.chip-categoria');
            const tarjetas = document.querySelectorAll('.tarjeta-equipo-item');
            const totalVisibleSpan = document.getElementById('catalogo-total-visible');
            const sinResultadosDiv = document.getElementById('catalogo-sin-resultados');

            let categoriaSeleccionada = 'todas';

            const CATALOGO_POR_PAGINA = 9;
            let paginaActualCatalogo = 1;
            let tarjetasFiltradas = [];

            function filtrarCatalogo() {
                const texto = inputBuscar ? inputBuscar.value.trim().toLowerCase() : '';
                const estado = selectEstado ? selectEstado.value : 'disponible';
                let visibles = 0;
                tarjetasFiltradas = [];

                tarjetas.forEach(tarjeta => {
                    const cat = tarjeta.getAttribute('data-categoria') || '';
                    const est = tarjeta.getAttribute('data-estado') || '';
                    const searchData = tarjeta.getAttribute('data-search') || '';

                    const cumpleCat = (categoriaSeleccionada === 'todas' || cat === categoriaSeleccionada);
                    const cumpleEstado = (estado === 'todos' || est === estado);
                    const cumpleTexto = (!texto || searchData.includes(texto));

                    if (cumpleCat && cumpleEstado && cumpleTexto) {
                        tarjeta.classList.remove('hidden');
                        tarjetasFiltradas.push(tarjeta);
                        visibles++;
                    } else {
                        tarjeta.classList.add('hidden');
                    }
                });

                if (totalVisibleSpan) totalVisibleSpan.textContent = visibles;
                if (sinResultadosDiv) {
                    sinResultadosDiv.classList.toggle('hidden', visibles > 0);
                }

                paginaActualCatalogo = 1;
                paginarCatalogo();
            }

            function paginarCatalogo() {
                const totalPaginas = Math.ceil(tarjetasFiltradas.length / CATALOGO_POR_PAGINA);
                if (paginaActualCatalogo > totalPaginas) paginaActualCatalogo = totalPaginas || 1;

                const inicio = (paginaActualCatalogo - 1) * CATALOGO_POR_PAGINA;
                const fin = inicio + CATALOGO_POR_PAGINA;

                tarjetasFiltradas.forEach((tarjeta, idx) => {
                    if (idx >= inicio && idx < fin) {
                        tarjeta.classList.remove('hidden');
                    } else {
                        tarjeta.classList.add('hidden');
                    }
                });

                const info = document.getElementById('infoPaginacionCatalogo');
                if (info) {
                    if (!tarjetasFiltradas.length) {
                        info.textContent = 'No hay equipos para mostrar';
                    } else {
                        info.textContent = 'Mostrando ' + (inicio + 1) + '–' + Math.min(fin, tarjetasFiltradas.length) +
                            ' de ' + tarjetasFiltradas.length + ' equipos';
                    }
                }

                renderPaginacionCatalogo(totalPaginas);
            }

            function paginasVisiblesCatalogo(total, actual) {
                if (total <= 7) {
                    const arr = [];
                    for (let i = 1; i <= total; i++) arr.push(i);
                    return arr;
                }
                if (actual <= 4) return [1, 2, 3, 4, 5, '...', total];
                if (actual >= total - 3) return [1, '...', total - 4, total - 3, total - 2, total - 1, total];
                return [1, '...', actual - 1, actual, actual + 1, '...', total];
            }

            function renderPaginacionCatalogo(totalPaginas) {
                const contenedor = document.getElementById('paginacionCatalogo');
                if (!contenedor) return;
                contenedor.innerHTML = '';

                const nav = contenedor.closest('nav');
                if (nav) nav.style.display = totalPaginas > 1 ? '' : 'none';
                if (totalPaginas <= 1) return;

                function crearItem(texto, destino, opciones) {
                    opciones = opciones || {};
                    const li = document.createElement('li');
                    li.className = 'page-item' + (opciones.activo ? ' active' : '') + (opciones.deshabilitado ? ' disabled' : '');
                    const boton = document.createElement('button');
                    boton.type = 'button';
                    boton.className = 'page-link';
                    boton.innerHTML = texto;
                    if (opciones.titulo) boton.title = opciones.titulo;
                    if (!opciones.deshabilitado && !opciones.activo) {
                        boton.addEventListener('click', function () { irAPaginaCatalogo(destino); });
                    }
                    li.appendChild(boton);
                    contenedor.appendChild(li);
                }

                crearItem('<i class="ri-arrow-left-s-line"></i>', paginaActualCatalogo - 1, {
                    deshabilitado: paginaActualCatalogo === 1,
                    titulo: 'Página anterior'
                });

                paginasVisiblesCatalogo(totalPaginas, paginaActualCatalogo).forEach(function (pagina) {
                    if (pagina === '...') {
                        const li = document.createElement('li');
                        li.className = 'page-item disabled';
                        li.innerHTML = '<span class="page-link">…</span>';
                        contenedor.appendChild(li);
                    } else {
                        crearItem(String(pagina), pagina, { activo: pagina === paginaActualCatalogo });
                    }
                });

                crearItem('<i class="ri-arrow-right-s-line"></i>', paginaActualCatalogo + 1, {
                    deshabilitado: paginaActualCatalogo === totalPaginas,
                    titulo: 'Página siguiente'
                });
            }

            function irAPaginaCatalogo(pagina) {
                paginaActualCatalogo = pagina;
                paginarCatalogo();
                const lista = document.getElementById('catalogo-lista-equipos');
                if (lista) {
                    const y = lista.getBoundingClientRect().top + window.pageYOffset - 100;
                    window.scrollTo({ top: y, behavior: 'smooth' });
                }
            }

            if (chipsCategorias.length) {
                chipsCategorias.forEach(chip => {
                    chip.addEventListener('click', function () {
                        chipsCategorias.forEach(c => {
                            c.classList.remove('btn-primary', 'active');
                            c.classList.add('btn-outline-secondary');
                        });
                        this.classList.remove('btn-outline-secondary');
                        this.classList.add('btn-primary', 'active');
                        categoriaSeleccionada = this.getAttribute('data-categoria');
                        filtrarCatalogo();
                    });
                });
            }

            if (inputBuscar) {
                inputBuscar.addEventListener('input', filtrarCatalogo);
            }

            if (selectEstado) {
                selectEstado.addEventListener('change', filtrarCatalogo);
            }

            if (btnLimpiar) {
                btnLimpiar.addEventListener('click', function () {
                    if (inputBuscar) {
                        inputBuscar.value = '';
                        filtrarCatalogo();
                        inputBuscar.focus();
                    }
                });
            }

            if (btnReset) {
                btnReset.addEventListener('click', function () {
                    if (inputBuscar) inputBuscar.value = '';
                    if (selectEstado) selectEstado.value = 'todos';
                    categoriaSeleccionada = 'todas';
                    chipsCategorias.forEach(c => {
                        c.classList.remove('btn-primary', 'active');
                        c.classList.add('btn-outline-secondary');
                        if (c.getAttribute('data-categoria') === 'todas') {
                            c.classList.remove('btn-outline-secondary');
                            c.classList.add('btn-primary', 'active');
                        }
                    });
                    filtrarCatalogo();
                });
            }

            filtrarCatalogo();
        });
    </script>
</c:otherwise>
</c:choose>

</t:layout>
