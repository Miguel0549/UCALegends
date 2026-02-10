package es.uca.legends.exceptions;
import io.jsonwebtoken.ExpiredJwtException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authorization.AuthorizationDeniedException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.HashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<Map<String, String>> handleBadCredentialsException(BadCredentialsException ex) {
        Map<String, String> resp = new HashMap<>();
        resp.put("error", "Credenciales incorrectas");
        resp.put("message", "El usuario no existe o la contraseña es errónea.");

        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(resp);
    }

    @ExceptionHandler(AuthorizationDeniedException.class)
    public ResponseEntity<Map<String, String>> handleAuthorizationDenied(AuthorizationDeniedException ex) {
        Map<String, String> resp = new HashMap<>();
        resp.put("error", "Acceso Denegado");
        resp.put("message", "No tienes permisos para realizar esta accion");

        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(resp);
    }

    @ExceptionHandler(ExpiredJwtException.class)
    public ResponseEntity<Map<String, String>> handleJwTExpired(ExpiredJwtException ex) {
        Map<String, String> resp = new HashMap<>();
        resp.put("error", "Token expired");
        resp.put("message", "Tu sesion a expirado, por favor vuelve a iniciar sesion");

        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(resp);
    }

    @ExceptionHandler(DisabledException.class)
    public ResponseEntity<Map<String, String>> handleDisabledException(DisabledException ex) {
        Map<String, String> resp = new HashMap<>();
        resp.put("error", "Cuenta deshabilitada");
        resp.put("message", "Tu cuenta está desactivada. Contacta con soporte.");

        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(resp);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleGeneralException(Exception ex) {
        Map<String, String> resp = new HashMap<>();
        resp.put("error", "Error interno");
        resp.put("message", ex.getMessage());

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(resp);
    }
}
