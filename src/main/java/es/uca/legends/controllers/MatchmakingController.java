package es.uca.legends.controllers;
import es.uca.legends.entities.Match;
import es.uca.legends.entities.User;
import es.uca.legends.services.MatchService;
import es.uca.legends.services.TournamentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/tournaments/{tournamentId}/matches")
@RequiredArgsConstructor
public class MatchmakingController {

    private final TournamentService tournamentService;

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