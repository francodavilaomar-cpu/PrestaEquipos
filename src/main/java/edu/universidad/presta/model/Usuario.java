package edu.universidad.presta.model;

import java.time.LocalDateTime;

/** Usuario del sistema (tabla usuarios). */
public class Usuario {

    private int id;
    private String nombre;
    private String dni;
    private String celular;
    private String email;
    private String passwordHash;
    private String rol;
    private String oficina;
    private int estado;
    private LocalDateTime fechaRegistro;

    public String getOficina() {
        return oficina;
    }

    public void setOficina(String oficina) {
        this.oficina = oficina;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public String getDni() {
        return dni;
    }

    public void setDni(String dni) {
        this.dni = dni;
    }

    public String getCelular() {
        return celular;
    }

    public void setCelular(String celular) {
        this.celular = celular;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    public String getRol() {
        return rol;
    }

    public void setRol(String rol) {
        this.rol = rol;
    }

    public int getEstado() {
        return estado;
    }

    public void setEstado(int estado) {
        this.estado = estado;
    }

    public LocalDateTime getFechaRegistro() {
        return fechaRegistro;
    }

    public void setFechaRegistro(LocalDateTime fechaRegistro) {
        this.fechaRegistro = fechaRegistro;
    }


    /** true si la cuenta está activa (estado = 1). */
    public boolean isActivo() {
        return estado == 1;
    }

    public boolean isAdmin() {
        return "admin".equals(rol);
    }

    /** Admin y encargado comparten permisos de gestión. */
    public boolean isEncargado() {
        return "admin".equals(rol) || "encargado".equals(rol);
    }

}
