<%@ page contentType="text/html;charset=UTF-8" %>
    <%@ taglib prefix="c" uri="jakarta.tags.core" %>
        <%@ taglib prefix="f" uri="http://universidad.edu/presta/funciones" %>
            <%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
                <c:set var="ctx" value="${pageContext.request.contextPath}" />
                <%-- Fragmento del formulario de usuarios: se usa en usuarios/form.jsp y dentro del modal del panel.
                    --%>

                    <t:errores />
                    <form method="POST"
                        action="${ctx}/usuarios/${esEdicion ? 'editar' : 'crear'}${esEdicion ? '?id=' : ''}${esEdicion ? usuario.id : ''}"
                        class="needs-validation" novalidate>
                        <t:csrf />

                        <div class="mb-4">
                            <label for="nombre" class="form-label font-bold">Nombre Completo *</label>
                            <input type="text" class="form-control" id="nombre" name="nombre" required
                                placeholder="Ej: Juan Carlos Pérez Flores" value="${f:h(form.nombre)}">
                            <input type="hidden" id="nombre_dni" name="nombre_dni" value="">
                            <div class="invalid-feedback">El nombre completo es obligatorio.</div>
                            <small class="text-muted d-block mt-1" id="nombre-dni-aviso"></small>
                        </div>

                        <div class="grid grid-cols-12 gap-x-6">
                            <div class="col-span-12 md:col-span-6 mb-4">
                                <label for="dni" class="form-label font-bold">DNI (Perú - 8 dígitos) *</label>
                                <div class="input-group">
                                    <span class="input-group-text"><i class="ri-id-card-line"></i></span>
                                    <input type="text" class="form-control" id="dni" name="dni" required maxlength="8"
                                        minlength="8" pattern="[0-9]{8}" placeholder="Ej: 71234567"
                                        oninput="this.value = this.value.replace(/[^0-9]/g, '');"
                                        value="${f:h(form.dni)}">
                                    <c:if test="${not esEdicion}">
                                        <button type="button" class="btn btn-primary" id="btn-buscar-dni"
                                            title="Buscar nombres y apellidos por DNI">
                                            <i class="ri-search-line" id="dni-search-icon"></i>
                                            <span class="hidden sm:inline ms-1" id="dni-search-text">Buscar</span>
                                        </button>
                                    </c:if>
                                </div>
                                <c:choose>
                                    <c:when test="${esEdicion}"><small class="text-muted">Exactamente 8 dígitos
                                            numéricos</small></c:when>
                                    <c:otherwise>
                                        <div id="dni-feedback" class="text-[0.875em] mt-1 text-muted">Ingrese los 8
                                            dígitos y haga clic en Buscar.</div>
                                    </c:otherwise>
                                </c:choose>
                                <div class="invalid-feedback">Ingrese un DNI peruano de 8 dígitos.</div>
                            </div>
                            <div class="col-span-12 md:col-span-6 mb-4">
                                <label for="celular" class="form-label font-bold">Número de Celular (Perú) *</label>
                                <div class="input-group">
                                    <span class="input-group-text"><i class="ri-phone-line"></i></span>
                                    <input type="tel" class="form-control" id="celular" name="celular" required
                                        maxlength="9" minlength="9" pattern="9[0-9]{8}" placeholder="Ej: 987654321"
                                        oninput="this.value = this.value.replace(/[^0-9]/g, '');"
                                        value="${f:h(form.celular)}">
                                </div>
                                <small class="text-muted">9 dígitos comenzando con 9</small>
                                <div class="invalid-feedback">Ingrese un celular peruano válido (9 dígitos que inicie
                                    con 9).</div>
                            </div>
                        </div>

                        <div class="mb-4">
                            <label for="email" class="form-label font-bold">Correo Electrónico *</label>
                            <div class="input-group">
                                <span class="input-group-text"><i class="ri-mail-line"></i></span>
                                <input type="email" class="form-control" id="email" name="email" required
                                    placeholder="usuario@universidad.edu" value="${f:h(form.email)}">
                            </div>
                            <div class="invalid-feedback">Ingrese un correo válido.</div>
                        </div>

                        <c:choose>
                            <c:when test="${esEdicion}">
                                <div class="mb-4">
                                    <label for="nuevo_password" class="form-label font-bold">Nueva Contraseña
                                        (opcional)</label>
                                    <input type="password" class="form-control" id="nuevo_password"
                                        name="nuevo_password" placeholder="••••••••">
                                    <small class="text-muted d-block mt-1"><i
                                            class="ri-shield-keyhole-line text-success"></i> Debe tener al menos 8
                                        caracteres, incluir mayúscula (A-Z), minúscula (a-z) y número o símbolo.</small>
                                </div>
                            </c:when>
                            <c:otherwise>
                                <div class="grid grid-cols-12 gap-x-6">
                                    <div class="col-span-12 md:col-span-6 mb-4">
                                        <div class="flex items-center justify-between">
                                            <label for="password" class="form-label font-bold mb-0">Contraseña *</label>
                                            <span class="badge bg-light text-primary text-[0.75rem] border"><i
                                                    class="ri-magic-line me-1"></i>Automática (Inicial + DNI)</span>
                                        </div>
                                        <div class="input-group mt-1">
                                            <span class="input-group-text"><i class="ri-lock-password-line"></i></span>
                                            <input type="text" class="form-control font-mono" id="password"
                                                name="password" required minlength="8" placeholder="Ej: A71234567">
                                        </div>
                                        <small class="text-muted d-block mt-1" id="password-hint"><i
                                                class="ri-shield-keyhole-line text-success"></i> Se autogenera con la
                                            1ra letra del nombre en mayúscula y el DNI.</small>
                                        <div class="invalid-feedback">La contraseña debe tener al menos 8 caracteres y
                                            cumplir los requisitos de seguridad.</div>
                                    </div>
                                    <div class="col-span-12 md:col-span-6 mb-4">
                                        <label for="password_confirm" class="form-label font-bold">Confirmar Contraseña
                                            *</label>
                                        <div class="input-group">
                                            <span class="input-group-text"><i class="ri-lock-check-line"></i></span>
                                            <input type="text" class="form-control font-mono" id="password_confirm"
                                                name="password_confirm" required placeholder="Ej: A71234567">
                                        </div>
                                        <div class="invalid-feedback">Confirme la contraseña.</div>
                                    </div>
                                </div>
                            </c:otherwise>
                        </c:choose>

                        <div class="mb-4">
                            <label for="oficina" class="form-label font-bold">Oficina / Área de Adscripción</label>
                            <div class="input-group">
                                <span class="input-group-text"><i class="ri-building-line"></i></span>
                                <select class="form-select" id="oficina" name="oficina" data-buscable
                                    data-placeholder="Buscar o seleccionar área u oficina...">
                                    <option value="">Selecciona el área u oficina...</option>
                                    <c:forEach var="of" items="${oficinasDisponibles}">
                                        <option value="${f:h(of.nombre)}" ${form.oficina==of.nombre ? 'selected' : '' }>
                                            ${f:h(of.nombre)}</option>
                                    </c:forEach>
                                </select>
                            </div>
                            <small class="text-muted">Se autocompletará en sus solicitudes de préstamos de
                                equipos.</small>
                        </div>

                        <div class="mb-4 p-3 bg-light rounded-3 border">
                            <label class="form-label font-bold text-dark d-flex align-items-center mb-2">
                                <i class="ri-send-plane-fill text-success me-1 text-lg"></i> Enviar credenciales al
                                usuario:
                            </label>
                            <div class="d-flex flex-wrap gap-2">
                                <button type="button"
                                    class="btn btn-outline-success btn-sm d-flex align-items-center gap-1"
                                    id="btn-enviar-whatsapp">
                                    <i class="ri-whatsapp-line text-lg"></i> Enviar por WhatsApp
                                </button>
                                <button type="button"
                                    class="btn btn-outline-primary btn-sm d-flex align-items-center gap-1"
                                    id="btn-enviar-email">
                                    <i class="ri-mail-send-line text-lg"></i> Enviar por Correo / Gmail
                                </button>
                            </div>
                            <small class="text-muted d-block mt-2" style="font-size: 0.8rem;">
                                <i class="ri-information-line"></i> Abre WhatsApp Web o tu cliente de correo/Gmail con
                                el mensaje ya redactado (usuario y clave).
                            </small>
                        </div>

                        <div class="mb-6">
                            <label for="rol" class="form-label font-bold">Rol de Usuario *</label>
                            <select class="form-select" id="rol" name="rol" required>
                                <option value="usuario" ${form.rol=='usuario' ? 'selected' : '' }>${esEdicion ?
                                    'Usuario' : 'Usuario (Docente / Estudiante / Personal)'}</option>
                                <option value="encargado" ${form.rol=='encargado' ? 'selected' : '' }>${esEdicion ?
                                    'Encargado' : 'Encargado de Almacén / Laboratorio'}</option>
                                <option value="admin" ${form.rol=='admin' ? 'selected' : '' }>${esEdicion ?
                                    'Administrador' : 'Administrador del Sistema'}</option>
                            </select>
                        </div>

                        <c:if test="${not esModal}">
                            <div class="flex justify-end gap-2 pt-4 border-t acciones-formulario">
                                <a href="${ctx}/usuarios/listar" class="btn btn-secondary">Cancelar</a>
                                <button type="submit" class="btn btn-primary"><i class="ri-save-line me-1"></i>
                                    ${esEdicion ? 'Actualizar Usuario' : 'Crear Usuario'}</button>
                            </div>
                        </c:if>
                    </form>