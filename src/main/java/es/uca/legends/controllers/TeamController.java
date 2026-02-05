package es.uca.legends.controllers;

import es.uca.legends.dtos.CreateTeamRequest;
import es.uca.legends.entities.Team;
import es.uca.legends.entities.User;
import es.uca.legends.services.TeamService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/teams")
@RequiredArgsConstructor
public class TeamController {

    private final TeamService teamService;

    @PostMapping("/create")
    public ResponseEntity<?> createTeam(@AuthenticationPrincipal User user, @RequestBody CreateTeamRequest request)
    {
        try {
            Team createdTeam = teamService.createTeam(user, request);
            return ResponseEntity.ok(createdTeam);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @DeleteMapping("/kick/{playerId}")
    public ResponseEntity<?> kickPlayer(@AuthenticationPrincipal User user, @PathVariable Long playerId)
    {
        try {
            teamService.kickPlayer(user, playerId);
            return ResponseEntity.ok("Jugador expulsado correctamente.");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @DeleteMapping("/delete")
    public ResponseEntity<?> deleteTeam(@AuthenticationPrincipal User user) {
        try {
            teamService.deleteTeam(user);
            return ResponseEntity.ok("Equipo disuelto y eliminado correctamente.");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/{teamId}/join")
    public ResponseEntity<?> joinTeam(@AuthenticationPrincipal User user, @PathVariable Long teamId)
    {
        try {
            teamService.joinTeam(user, teamId);
            return ResponseEntity.ok("Te has unido al equipo correctamente.");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/leave")
    public ResponseEntity<?> leaveTeam(@AuthenticationPrincipal User user)
    {
        try {
            teamService.leaveTeam(user);
            return ResponseEntity.ok("Has abandonado el equipo correctamente.");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PutMapping("/leader/{newLeaderPlayerId}")
    public ResponseEntity<?> transferLeadership(@AuthenticationPrincipal User user, @PathVariable Long newLeaderPlayerId)
    {
        try {
            teamService.transferLeadership(user, newLeaderPlayerId);
            return ResponseEntity.ok("Liderazgo transferido correctamente.");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}
