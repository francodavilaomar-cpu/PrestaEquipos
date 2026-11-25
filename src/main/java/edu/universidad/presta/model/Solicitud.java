package edu.universidad.presta.model;

import edu.universidad.presta.util.Oficinas;
import java.time.LocalDateTime;

/** Solicitud de equipo hecha por un usuario (tabla solicitudes). */
public class Solicitud {

    private int id;
    private int usuarioId;
    private String equipoSolicitado;
    private LocalDateTime fechaPrestamo;
    private LocalDateTime fechaDevolucion;
    private String oficina;
    private String estado;
    private String observaciones;
    private LocalDateTime fechaSolicitud;
    private String usuarioNombre;
    private String usuarioEmail;
    private String motivoRechazo;

    public String getMotivoRechazo() {
        return motivoRechazo;
    }

    public void setMotivoRechazo(String motivoRechazo) {
        this.motivoRechazo = motivoRechazo;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getUsuarioId() {
        return usuarioId;
    }

    public void setUsuarioId(int usuarioId) {
        this.usuarioId = usuarioId;
    }

    public String getEquipoSolicitado() {
        return equipoSolicitado;
    }

    public void setEquipoSolicitado(String equipoSolicitado) {
        this.equipoSolicitado = equipoSolicitado;
    }

    public LocalDateTime getFechaPrestamo() {
        return fechaPrestamo;
    }

    public void setFechaPrestamo(LocalDateTime fechaPrestamo) {
        this.fechaPrestamo = fechaPrestamo;
    }

    public LocalDateTime getFechaDevolucion() {
        return fechaDevolucion;
    }

    public void setFechaDevolucion(LocalDateTime fechaDevolucion) {
        this.fechaDevolucion = fechaDevolucion;
    }

    public String getOficina() {
        return oficina;
    }

    public void setOficina(String oficina) {
        this.oficina = oficina;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }

    public String getObservaciones() {
        return observaciones;
    }

    public void setObservaciones(String observaciones) {
        this.observaciones = observaciones;
    }

    public LocalDateTime getFechaSolicitud() {
        return fechaSolicitud;
    }

    public void setFechaSolicitud(LocalDateTime fechaSolicitud) {
        this.fechaSolicitud = fechaSolicitud;
    }

    public String getUsuarioNombre() {
        return usuarioNombre;
    }

    public void setUsuarioNombre(String usuarioNombre) {
        this.usuarioNombre = usuarioNombre;
    }

    public String getUsuarioEmail() {
        return usuarioEmail;
    }

    public void setUsuarioEmail(String usuarioEmail) {
        this.usuarioEmail = usuarioEmail;
    }


    /** Área universitaria a la que pertenece la oficina solicitada. */
    public String getArea() {
        return Oficinas.area(oficina);
    }

}
