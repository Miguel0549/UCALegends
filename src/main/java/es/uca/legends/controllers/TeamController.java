package es.uca.legends.controllers;

import es.uca.legends.dtos.CreateTeamRequest;
import es.uca.legends.dtos.TeamMemberDto;
import es.uca.legends.dtos.TeamResponseDto;
import es.uca.legends.entities.Team;
import es.uca.legends.entities.User;
import es.uca.legends.repositories.TeamRepository;
import es.uca.legends.services.TeamService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/teams")
@RequiredArgsConstructor
public class TeamController {

    private final TeamService teamService;
    private final TeamRepository teamRepository;

    @GetMapping("/")
    public ResponseEntity<?> getAllTeams() {
        return ResponseEntity.ok(teamRepository.findAll());
    }

    @PostMapping("/create")
    public ResponseEntity<?> createTeam(@AuthenticationPrincipal User user, @RequestBody CreateTeamRequest request) {
        try {
            // 1. Llamamos al servicio para crear el equipo
            Team createdTeam = teamService.createTeam(user, request);

            // 2. CONVERSIÓN MANUAL A DTO (Para evitar el bucle infinito)
            TeamResponseDto response = new TeamResponseDto();
            response.setId(createdTeam.getId());
            response.setName(createdTeam.getName());
            response.setTag(createdTeam.getTag());
            response.setDivision(createdTeam.getDivision());
            response.setRegion(createdTeam.getRegion());

            List<TeamMemberDto> memberDtos = createdTeam.getMembers().stream().map(player -> {
                TeamMemberDto m = new TeamMemberDto();
                m.setRiotIdName(player.getRiotIdName());
                m.setRiotIdTag(player.getRiotIdTag());
                m.setTier(player.getTier());
                m.setDivision(player.getDivision());
                // Comprobar si es el líder
                m.setLeader(player.equals(createdTeam.getLeader()));
                return m;
            }).toList();

            response.setMembers(memberDtos);

            // Seguridad para evitar NullPointer si el player no cargo bien
            if (user.getPlayer() != null) {
                response.setLeaderName(user.getPlayer().getRiotIdName());
            }

            // Al crearse, siempre tiene 1 miembro (el líder)
            response.setMemberCount(1);

            // 3. ¡IMPORTANTE! Devolvemos 'response', NO 'createdTeam'
            return ResponseEntity.ok(response);

        } catch (IllegalArgumentException | IllegalStateException e) {
            // Capturamos errores de validación (nombre duplicado, usuario ya tiene equipo, etc)
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            e.printStackTrace(); // Imprime el error real en consola para que lo veas
            return ResponseEntity.internalServerError().body("Error interno del servidor: " + e.getMessage());
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
