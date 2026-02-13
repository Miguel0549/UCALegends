package es.uca.legends.controllers;

import es.uca.legends.entities.User;
import es.uca.legends.services.MatchService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/matches")
@RequiredArgsConstructor
public class MatchController {

    private final MatchService matchService;

    @PostMapping("/{matchId}/report")
    public ResponseEntity<?> reportMatchResult(@PathVariable Long matchId, @RequestBody Map<String, String> body, @AuthenticationPrincipal User user) {
        try {
            matchService.reportMatchResult(matchId, body.get("riotMatchId"), user);
            return ResponseEntity.ok("Resultado procesado con éxito.");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}
