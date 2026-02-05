package es.uca.legends.controllers;

import es.uca.legends.entities.Tournament;
import es.uca.legends.entities.User;
import es.uca.legends.services.TournamentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/tournaments")
@RequiredArgsConstructor
public class TournamentController {

    private final TournamentService tournamentService;

    // --- ADMIN ---

    @PostMapping("/create")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> createTournament(@RequestBody Tournament tournament) {
        try {
            return ResponseEntity.ok(tournamentService.createTournament(tournament));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @DeleteMapping("/{id}/delete")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deleteTournament(@PathVariable Long id) {
        try {
            tournamentService.deleteTournament(id);
            return ResponseEntity.ok("Torneo eliminado correctamente.");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // --- USUARIOS (LÍDERES) ---

    @PostMapping("/{id}/join")
    public ResponseEntity<?> joinTournament(@PathVariable Long id, @AuthenticationPrincipal User user)
    {
        try {
            tournamentService.joinTournament(user, id);
            return ResponseEntity.ok("Inscripción realizada con éxito.");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @DeleteMapping("/{id}/leave")
    public ResponseEntity<?> leaveTournament(@PathVariable Long id, @AuthenticationPrincipal User user)
    {
        try {
            tournamentService.leaveTournament(user, id);
            return ResponseEntity.ok("Inscripción cancelada con éxito. Has salido del torneo.");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> changeStatus(@PathVariable Long id, @RequestParam String status)
    {
        try {
            if (!status.matches("ABIERTO|CERRADO|EN_CURSO|FINALIZADO|CANCELADO")) {
                throw new RuntimeException("Estado inválido.");
            }

            tournamentService.updateTournamentStatus(id, status);
            return ResponseEntity.ok("Estado del torneo actualizado a: " + status);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}
