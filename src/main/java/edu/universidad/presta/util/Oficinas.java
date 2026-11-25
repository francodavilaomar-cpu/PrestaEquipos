package edu.universidad.presta.util;

import edu.universidad.presta.model.EstadoInfo;
import edu.universidad.presta.model.GrupoOficinas;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Catálogos fijos: oficinas de la universidad y estados de equipo. */
public final class Oficinas {

    public static final List<GrupoOficinas> GRUPOS = Collections.unmodifiableList(Arrays.asList(
        new GrupoOficinas("Órganos de Alta Dirección y Gobierno", "Alta Dirección y Gobierno", Arrays.asList(
            "Rectorado",
            "Vicerrectorado Académico",
            "Vicerrectorado de Investigación",
            "Secretaría General")),
        new GrupoOficinas("Órganos de Asesoramiento, Control y Apoyo", "Asesoramiento, Control y Apoyo", Arrays.asList(
            "Órgano de Control Institucional (OCI)",
            "Oficina de Asesoría Jurídica",
            "Oficina de Planeamiento y Presupuesto",
            "Oficina de Gestión de la Calidad")),
        new GrupoOficinas("Órganos de Línea (Direcciones Generales y Unidades)", "Órganos de Línea", Arrays.asList(
            "Unidad de Abastecimiento (Logística)",
            "Unidad de Talento Humano (Recursos Humanos)",
            "Unidad de Servicios Generales",
            "Unidad de Contabilidad y Unidad de Tesorería")),
        new GrupoOficinas("Direcciones de Servicios Académicos y Estudiantiles", "Servicios Académicos y Estudiantiles", Arrays.asList(
            "Dirección de Admisión",
            "Dirección de Centros Experimentales y Laboratorios",
            "Dirección de Gestión e Innovación Académica",
            "Oficina de Tecnologías de la Información (OTI)",
            "Oficina de Bienestar Universitario")),
        new GrupoOficinas("Órganos de Extensión e Impacto Social", "Extensión e Impacto Social", Arrays.asList(
            "Dirección de Responsabilidad Social Universitaria, Proyección Social y Extensión Cultural",
            "Dirección de Innovación y Transferencia Tecnológica",
            "IncubaCentro (Unidad de Incubadora de Empresas)",
            "Defensoría Universitaria"))
    ));

    /** Estados de equipo en el orden en que se muestran. */
    public static final Map<String, EstadoInfo> ESTADOS_EQUIPO;

    static {
        Map<String, EstadoInfo> m = new LinkedHashMap<>();
        m.put("disponible", new EstadoInfo("Disponible", "ri-checkbox-circle-fill", "bg-success"));
        m.put("prestado", new EstadoInfo("Prestado", "ri-arrow-left-right-line", "bg-info"));
        m.put("mantenimiento", new EstadoInfo("Mantenimiento", "ri-tools-line", "bg-warning text-dark"));
        m.put("dado_de_baja", new EstadoInfo("Dado de baja", "ri-close-circle-line", "bg-danger"));
        ESTADOS_EQUIPO = Collections.unmodifiableMap(m);
    }

    /** Icono Remix Icon de cada categoría para identificarla de un vistazo (por defecto: ri-box-3-line). */
    public static final Map<String, String> ICONOS_CATEGORIA;

    static {
        Map<String, String> m = new LinkedHashMap<>();
        m.put("Componentes", "ri-cpu-line");
        m.put("Cables", "ri-plug-line");
        m.put("Periféricos", "ri-keyboard-line");
        m.put("Laptops", "ri-macbook-line");
        m.put("Monitores", "ri-computer-line");
        m.put("CPU", "ri-hard-drive-2-line");
        m.put("Accesorios", "ri-headphone-line");
        m.put("Impresoras", "ri-printer-line");
        m.put("Redes", "ri-router-line");
        m.put("Audio", "ri-speaker-line");
        m.put("Proyectores", "ri-projector-line");
        m.put("Tablets", "ri-tablet-line");
        m.put("Cámaras", "ri-vidicon-line");
        ICONOS_CATEGORIA = Collections.unmodifiableMap(m);
    }

    private Oficinas() {
    }

    /** Devuelve la lista dinámica de grupos con sus oficinas registradas en la base de datos. */
    public static List<GrupoOficinas> gruposDinamicos() {
        try {
            List<edu.universidad.presta.model.Oficina> oficinas = edu.universidad.presta.dao.OficinaDao.listarActivas();
            if (oficinas.isEmpty()) {
                return GRUPOS;
            }
            Map<String, List<String>> porGrupo = new LinkedHashMap<>();
            for (edu.universidad.presta.model.Oficina o : oficinas) {
                String grp = (o.getGrupo() != null && !o.getGrupo().trim().isEmpty()) ? o.getGrupo().trim() : "General";
                porGrupo.computeIfAbsent(grp, k -> new ArrayList<>()).add(o.getNombre());
            }
            List<GrupoOficinas> lista = new ArrayList<>();
            for (Map.Entry<String, List<String>> e : porGrupo.entrySet()) {
                lista.add(new GrupoOficinas(e.getKey(), e.getKey(), Collections.unmodifiableList(e.getValue())));
            }
            return Collections.unmodifiableList(lista);
        } catch (Exception e) {
            return GRUPOS;
        }
    }

    /** Área a la que pertenece una oficina ("Otra Categoría" si no está en el catálogo). */
    public static String area(String oficina) {
        if (oficina == null || oficina.trim().isEmpty()) {
            return "General";
        }
        try {
            edu.universidad.presta.model.Oficina o = edu.universidad.presta.dao.OficinaDao.porNombre(oficina.trim());
            if (o != null && o.getGrupo() != null && !o.getGrupo().trim().isEmpty()) {
                return o.getGrupo();
            }
        } catch (Exception ignored) {}
        for (GrupoOficinas g : GRUPOS) {
            if (g.getOficinas().contains(oficina)) {
                return g.getArea();
            }
        }
        return "Otra Categoría";
    }
}
