package es.uca.legends.controllers;
import es.uca.legends.entities.Match;
import es.uca.legends.services.TournamentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tournaments/{tournamentId}/matches")
@RequiredArgsConstructor
public class MatchmakingController {

    private final TournamentService tournamentService;

    // 1. GENERAR / AVANZAR RONDA (Solo Admin)
    // Este endpoint sirve tanto para INICIAR el torneo (Ronda 1) como para pasar a la siguiente.
    @PostMapping("/advance")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> advanceRound(@PathVariable Long tournamentId) {
        try {
            tournamentService.advanceToNextRound(tournamentId);
            return ResponseEntity.ok("Ronda generada con éxito. ¡A jugar!");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body("Error al avanzar ronda: " + e.getMessage());
        }
    }

    // 2. VER LOS PARTIDOS DE LA RONDA ACTUAL
    // Para que los usuarios sepan contra quién juegan
    @GetMapping("/current")
    public ResponseEntity<?> getCurrentRoundMatches(@PathVariable Long tournamentId) {
        try {
            // Necesitarás exponer este método en el servicio (te lo pongo abajo)
            List<Match> matches = tournamentService.getCurrentRoundMatches(tournamentId);
            return ResponseEntity.ok(matches);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // 3. (Opcional) VER BRACKET COMPLETO
    // Si quieres ver el historial de todas las rondas
    @GetMapping("/all")
    public ResponseEntity<?> getAllMatches(@PathVariable Long tournamentId) {
        // Implementar lógica para devolver todos los partidos del torneo
        return ResponseEntity.ok().build(); // TODO
    }
}