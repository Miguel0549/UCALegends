package es.uca.legends.controllers;

import es.uca.legends.dtos.TournamentHistoryDto;
import es.uca.legends.entities.Match;
import es.uca.legends.entities.Tournament;
import es.uca.legends.entities.User;
import es.uca.legends.repositories.MatchRepository;
import es.uca.legends.repositories.TournamentRegistrationRepository;
import es.uca.legends.repositories.TournamentRepository;
import es.uca.legends.services.TournamentService;
import es.uca.legends.services.TournamentUpdateFunctions;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/tournaments")
@RequiredArgsConstructor
public class TournamentController {

    private final TournamentRepository tournamentRepository;
    private final TournamentRegistrationRepository registrationRepository;
    private final TournamentUpdateFunctions tournamentUpdateFunctions;
    private final TournamentService tournamentService;
    private final MatchRepository matchRepository;

    // --- General ---

    @GetMapping("/")
    public ResponseEntity<List<Tournament>> getAllTournaments() {

        return ResponseEntity.ok(tournamentRepository.findAll());
    }

    @GetMapping("/{id}/count")
    public ResponseEntity<Long> getInscribedCount(@PathVariable Long id) {
        // Devuelve el conteo de la tabla de registros
        return ResponseEntity.ok(registrationRepository.countByTournamentId(id));
    }

    @GetMapping("/history")
    public ResponseEntity<?> getHistory(@RequestParam String region) {
        try {
            // Ejemplo de llamada: GET /api/tournaments/history?region=EUW
            return ResponseEntity.ok(tournamentService.getTournamentHistory(region));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getTournamentById(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(tournamentRepository.findById(id));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // Partidas

    @GetMapping("/{id}/matches")
    public ResponseEntity<List<Match>> getTournamentMatches(@PathVariable Long id) {
        return ResponseEntity.ok(matchRepository.findByTournamentIdOrderByRoundAsc(id));
    }


    // --- ADMIN ---

    @PostMapping("/create")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> createTournament(@RequestBody Tournament tournament) {
        try {
            return ResponseEntity.ok(tournamentUpdateFunctions.createTournament(tournament));
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

            tournamentUpdateFunctions.updateTournamentStatus(id, status);
            return ResponseEntity.ok("Estado del torneo actualizado a: " + status);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}
