package es.uca.legends.controllers;


import es.uca.legends.dtos.DevPLayerLinkRequest;
import es.uca.legends.entities.User;
import es.uca.legends.services.PlayerService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/players")
@RequiredArgsConstructor
public class PlayerController {

    private final PlayerService playerService;

    // Endpoint de desarrollo para simular la vinculación
    @PostMapping("/dev/link")
    public ResponseEntity<?> linkDevPlayer(@AuthenticationPrincipal User user, @RequestBody DevPLayerLinkRequest request)
    {
        try {
            return ResponseEntity.ok(playerService.linkDevPlayer(user, request));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @DeleteMapping("/dev/unlink")
    public ResponseEntity<?> unlinkRiotAccount(
            @AuthenticationPrincipal User user
    ) {
        try {
            playerService.unlinkRiotAccount(user);
            return ResponseEntity.ok("Cuenta de Riot desvinculada y datos de jugador eliminados correctamente.");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}
