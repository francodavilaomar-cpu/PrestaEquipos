package edu.universidad.presta.util;

import org.mindrot.jbcrypt.BCrypt;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;

/** Contraseñas (BCrypt, compatible con password_hash de PHP) y token CSRF. */
public final class Seguridad {

    public static final String CSRF_SESSION = "csrf_token";
    public static final String CSRF_PARAM = "csrf_token";
    private static final SecureRandom RANDOM = new SecureRandom();

    private Seguridad() {
    }

    public static String hash(String clave) {
        return BCrypt.hashpw(clave, BCrypt.gensalt(10));
    }

    /**
     * Valida que la contraseña cumpla los requisitos mínimos:
     * - Al menos 8 caracteres
     * - Al menos una letra mayúscula
     * - Al menos un número
     */
    public static String validarFortaleza(String clave) {
        if (clave == null || clave.length() < 8) {
            return "La contraseña debe tener al menos 8 caracteres.";
        }
        boolean tieneMayus = false;
        boolean tieneNumero = false;
        for (char c : clave.toCharArray()) {
            if (Character.isUpperCase(c)) tieneMayus = true;
            else if (Character.isDigit(c)) tieneNumero = true;
        }
        if (!tieneMayus) {
            return "La contraseña debe incluir al menos una letra mayúscula (A-Z).";
        }
        if (!tieneNumero) {
            return "La contraseña debe incluir al menos un número (ej. DNI).";
        }
        return null;
    }

    /**
     * PHP genera hashes con prefijo $2y$; jBCrypt solo conoce $2a$. Son el mismo algoritmo,
     * así que se normaliza el prefijo antes de verificar.
     */
    public static boolean verificar(String clave, String hash) {
        if (clave == null || hash == null) {
            return false;
        }
        String h = hash;
        if (h.startsWith("$2y$") || h.startsWith("$2x$") || h.startsWith("$2b$")) {
            h = "$2a$" + h.substring(4);
        }
        try {
            return BCrypt.checkpw(clave, h);
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    /** Token CSRF de la sesión (se crea la primera vez). */
    public static String token(HttpSession sesion) {
        Object t = sesion.getAttribute(CSRF_SESSION);
        if (t == null) {
            byte[] b = new byte[32];
            RANDOM.nextBytes(b);
            StringBuilder sb = new StringBuilder();
            for (byte x : b) {
                sb.append(String.format("%02x", x));
            }
            t = sb.toString();
            sesion.setAttribute(CSRF_SESSION, t);
        }
        return (String) t;
    }

    public static boolean tokenValido(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute(CSRF_SESSION) == null) {
            return false;
        }
        String enviado = req.getParameter(CSRF_PARAM);
        if (enviado == null) {
            return false;
        }
        return MessageDigest.isEqual(
                ((String) s.getAttribute(CSRF_SESSION)).getBytes(StandardCharsets.UTF_8),
                enviado.getBytes(StandardCharsets.UTF_8));
    }
}
