package edu.universidad.presta.util;

import edu.universidad.presta.config.AppConfig;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Consulta de DNI en RENIEC (equivale a dni_lookup.php): primero Decolecta con el token configurado y,
 * si no responde o no encuentra datos, el proveedor de respaldo apis.net.pe.
 */
public final class DniLookup {

    private static final Logger LOG = Logger.getLogger(DniLookup.class.getName());
    private static final HttpClient CLIENTE = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();

    /** Resultado de una consulta correcta. */
    public static final class Persona {
        public final String nombreCompleto;
        public final String nombres;
        public final String apellidoPaterno;
        public final String apellidoMaterno;

        Persona(String nombreCompleto, String nombres, String apellidoPaterno, String apellidoMaterno) {
            this.nombreCompleto = nombreCompleto;
            this.nombres = nombres;
            this.apellidoPaterno = apellidoPaterno;
            this.apellidoMaterno = apellidoMaterno;
        }
    }

    private DniLookup() {
    }

    /** Devuelve los datos del DNI o null si ningún proveedor los encontró. El DNI ya debe estar validado (8 dígitos). */
    public static Persona buscar(String dni) {
        String token = AppConfig.dniApiToken();
        Persona p = null;
        if (!token.isEmpty()) {
            p = consultar("https://api.decolecta.com/v1/reniec/dni?numero=" + codificar(dni), token, 5);
        }
        if (p == null) {
            // Reintento con backoff en caso de saturación temporal (rate limit 429)
            for (int intento = 1; intento <= 3; intento++) {
                p = consultar("https://api.apis.net.pe/v1/dni?numero=" + codificar(dni), null, 6);
                if (p != null) {
                    break;
                }
                if (intento < 3) {
                    try {
                        Thread.sleep(800L * intento);
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                        break;
                    }
                }
            }
        }
        return p;
    }

    private static String codificar(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }

    private static Persona consultar(String url, String token, int segundos) {
        try {
            HttpRequest.Builder rb = HttpRequest.newBuilder(URI.create(url))
                    .timeout(Duration.ofSeconds(segundos))
                    .header("Accept", "application/json")
                    .header("User-Agent", "Mozilla/5.0");
            if (token != null) {
                rb.header("Authorization", "Bearer " + token);
            }
            HttpResponse<String> r = CLIENTE.send(rb.GET().build(), HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (r.statusCode() != 200 || r.body() == null || r.body().isEmpty()) {
                return null;
            }
            return interpretar(r.body());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return null;
        } catch (Exception e) {
            LOG.log(Level.WARNING, "No se pudo consultar el DNI en " + url.replaceAll("\\?.*", ""), e);
            return null;
        }
    }

    /** Acepta los nombres de campo de ambos proveedores. */
    static Persona interpretar(String json) {
        String nombres = primero(json, "nombres", "first_name");
        String paterno = primero(json, "apellidoPaterno", "apellido_paterno", "paternal_surname");
        String materno = primero(json, "apellidoMaterno", "apellido_materno", "maternal_surname");
        String completo = primero(json, "nombreCompleto", "nombre");
        if (completo.isEmpty() && (!nombres.isEmpty() || !paterno.isEmpty())) {
            completo = (nombres + " " + paterno + " " + materno).trim().replaceAll("\\s+", " ");
        }
        return completo.isEmpty() ? null : new Persona(completo, nombres, paterno, materno);
    }

    private static String primero(String json, String... claves) {
        for (String k : claves) {
            String v = valor(json, k);
            if (!v.isEmpty()) {
                return v;
            }
        }
        return "";
    }

    /** Valor de texto de una clave de primer nivel (suficiente para estas respuestas planas). */
    private static String valor(String json, String clave) {
        Matcher m = Pattern.compile("\"" + Pattern.quote(clave) + "\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"").matcher(json);
        return m.find() ? desescapar(m.group(1)).trim() : "";
    }

    private static String desescapar(String s) {
        StringBuilder sb = new StringBuilder(s.length());
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (c != '\\' || i + 1 >= s.length()) {
                sb.append(c);
                continue;
            }
            char n = s.charAt(++i);
            switch (n) {
                case 'n': sb.append(' '); break;
                case 't': sb.append(' '); break;
                case 'r': break;
                case 'u':
                    if (i + 4 < s.length()) {
                        try {
                            sb.append((char) Integer.parseInt(s.substring(i + 1, i + 5), 16));
                            i += 4;
                            break;
                        } catch (NumberFormatException ignorada) {
                            // se conserva tal cual
                        }
                    }
                    sb.append('u');
                    break;
                default: sb.append(n);
            }
        }
        return sb.toString();
    }
}
