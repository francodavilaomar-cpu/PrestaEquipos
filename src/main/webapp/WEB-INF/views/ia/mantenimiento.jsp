<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="f" uri="http://universidad.edu/presta/funciones" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<t:layout title="Mantenimiento inteligente">
    <div class="oti-maint-page">
        <div class="oti-maint-header">
            <div>
                <div class="oti-maint-eyebrow"><i class="ri-brain-line"></i> Inteligencia preventiva OTI</div>
                <h2>Mantenimiento inteligente</h2>
                <p>Indicadores basados en el uso y los mantenimientos registrados. Son alertas de apoyo y deben validarse con una revisión técnica.</p>
            </div>
        </div>

        <div class="oti-maint-summary">
            <div class="card border-0 shadow-sm"><div class="card-body oti-maint-summary-body"><span class="oti-maint-summary-icon oti-maint-red"><i class="ri-alarm-warning-line"></i></span><div><div class="oti-maint-muted">Alertas preventivas</div><div class="oti-maint-number"><c:out value="${alertasMantenimiento.size()}"/></div></div></div></div>
            <div class="card border-0 shadow-sm"><div class="card-body oti-maint-summary-body"><span class="oti-maint-summary-icon oti-maint-amber"><i class="ri-tools-line"></i></span><div><div class="oti-maint-muted">Mantenimientos recientes</div><div class="oti-maint-number"><c:out value="${mantenimientos.size()}"/></div></div></div></div>
            <div class="card border-0 shadow-sm"><div class="card-body oti-maint-summary-body"><span class="oti-maint-summary-icon oti-maint-green"><i class="ri-shield-check-line"></i></span><div><div class="oti-maint-muted">Criterio de análisis</div><div class="oti-maint-summary-label">Uso + historial</div></div></div></div>
        </div>

        <section class="card oti-maint-section border-0 shadow-sm">
            <div class="card-header oti-maint-section-head">
                <div><h3><i class="ri-pulse-line"></i> Alertas preventivas sugeridas</h3><p>Mayor puntaje significa que conviene revisar el equipo primero.</p></div>
                <span class="badge bg-success-subtle text-success">Análisis automático</span>
            </div>
            <div class="card-body p-0">
                <c:if test="${empty alertasMantenimiento}">
                    <div class="oti-maint-empty"><i class="ri-checkbox-circle-line"></i><strong>No hay alertas preventivas</strong><span>No se identificaron indicadores relevantes con los registros disponibles.</span></div>
                </c:if>
                <c:if test="${not empty alertasMantenimiento}">
                    <div class="oti-maint-table-wrap"><table class="table oti-maint-table mb-0">
                        <thead><tr><th>Equipo</th><th>Uso (90 días)</th><th>Mantenimientos (12 meses)</th><th>Prioridad</th><th>Indicador</th></tr></thead>
                        <tbody><c:forEach var="a" items="${alertasMantenimiento}">
                            <tr>
                                <td><strong>${f:h(a.equipoNombre)}</strong><small>${f:h(a.codigoInventario)} · ${f:h(a.categoria)}</small></td>
                                <td>${a.prestamos90Dias} préstamos</td>
                                <td>${a.mantenimientos12Meses}</td>
                                <td><span class="badge ${a.prioridad == 'Alta' ? 'oti-maint-badge-high' : 'oti-maint-badge-medium'}">${f:h(a.prioridad)} · ${a.puntaje}/100</span></td>
                                <td class="oti-maint-reason">${f:h(a.motivo)}</td>
                            </tr>
                        </c:forEach></tbody>
                    </table></div>
                </c:if>
            </div>
        </section>

        <section class="card oti-maint-section border-0 shadow-sm">
            <div class="card-header oti-maint-section-head"><div><h3><i class="ri-add-circle-line"></i> Programar mantenimiento</h3><p>Registra una revisión preventiva o correctiva para un equipo.</p></div></div>
            <div class="card-body oti-maint-form-body">
                <form method="POST" action="${ctx}/ia/mantenimiento/registrar" class="oti-maint-form">
                    <t:csrf/>
                    <div class="oti-maint-field"><label class="form-label" for="equipo_id">Equipo *</label>
                        <select class="form-select" name="equipo_id" id="equipo_id" required>
                            <option value="">Seleccionar equipo...</option>
                            <c:forEach var="equipo" items="${equiposMantenimiento}"><option value="${equipo.id}">${f:h(equipo.nombre)} · ${f:h(equipo.codigoInventario)} (${f:h(equipo.estado)})</option></c:forEach>
                        </select>
                    </div>
                    <div class="oti-maint-field"><label class="form-label" for="tipo">Tipo *</label><select class="form-select" name="tipo" id="tipo" required><option value="preventivo">Preventivo</option><option value="correctivo">Correctivo</option></select></div>
                    <div class="oti-maint-field"><label class="form-label" for="fecha_programada">Fecha programada</label><input class="form-control" type="datetime-local" name="fecha_programada" id="fecha_programada"></div>
                    <div class="oti-maint-field oti-maint-description"><label class="form-label" for="descripcion">Descripción del trabajo *</label><textarea class="form-control" name="descripcion" id="descripcion" maxlength="2000" required placeholder="Describe la revisión, falla reportada o trabajo que se realizará..."></textarea></div>
                    <div class="oti-maint-actions"><button class="btn btn-primary" type="submit"><i class="ri-calendar-check-line me-1"></i> Programar mantenimiento</button></div>
                </form>
            </div>
        </section>

        <section class="card oti-maint-section border-0 shadow-sm">
            <div class="card-header oti-maint-section-head"><div><h3><i class="ri-history-line"></i> Historial reciente de mantenimiento</h3><p>Últimos 40 registros.</p></div></div>
            <div class="card-body p-0">
                <c:if test="${empty mantenimientos}"><div class="oti-maint-empty"><span>Todavía no hay mantenimientos registrados.</span></div></c:if>
                <c:if test="${not empty mantenimientos}"><div class="oti-maint-table-wrap"><table class="table oti-maint-table mb-0">
                    <thead><tr><th>Equipo</th><th>Tipo / Descripción</th><th>Programado</th><th>Estado</th><th>Acción</th></tr></thead>
                    <tbody><c:forEach var="m" items="${mantenimientos}"><tr>
                        <td><strong>${f:h(m.equipoNombre)}</strong><small>${f:h(m.codigoInventario)}</small></td>
                        <td><strong>${f:cap(m.tipo)}</strong><small>${f:h(m.descripcion)}</small></td>
                        <td>${empty m.fechaProgramada ? 'Sin fecha' : f:fecha(m.fechaProgramada, 'dd/MM/yyyy HH:mm')}</td>
                        <td><span class="badge ${m.estado == 'completado' ? 'oti-maint-badge-complete' : m.estado == 'en_proceso' ? 'oti-maint-badge-progress' : 'oti-maint-badge-pending'}">${f:cap(m.estado)}</span></td>
                        <td class="oti-maint-action-cell">
                            <c:if test="${m.estado == 'programado'}"><form method="POST" action="${ctx}/ia/mantenimiento/iniciar"><t:csrf/><input type="hidden" name="id" value="${m.id}"><button class="btn btn-sm btn-outline-primary" type="submit">Iniciar</button></form></c:if>
                            <c:if test="${m.estado == 'en_proceso'}"><form method="POST" action="${ctx}/ia/mantenimiento/finalizar"><t:csrf/><input type="hidden" name="id" value="${m.id}"><input class="form-control form-control-sm" name="observaciones" maxlength="1000" placeholder="Resultado (opcional)"><button class="btn btn-sm btn-success" type="submit">Completar</button></form></c:if>
                            <c:if test="${m.estado == 'completado'}"><span class="oti-maint-muted">${empty m.fechaFin ? '' : f:fecha(m.fechaFin, 'dd/MM/yyyy')}</span></c:if>
                        </td>
                    </tr></c:forEach></tbody>
                </table></div></c:if>
            </div>
        </section>
        <p class="oti-maint-disclaimer"><i class="ri-information-line"></i> El puntaje es una regla de priorización basada en préstamos recientes y mantenimientos registrados. No sustituye la inspección física ni representa un modelo de aprendizaje automático entrenado.</p>
    </div>
</t:layout>
