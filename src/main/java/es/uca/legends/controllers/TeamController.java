package es.uca.legends.controllers;

import es.uca.legends.dtos.*;
import es.uca.legends.entities.Player;
import es.uca.legends.entities.Team;
import es.uca.legends.entities.TeamJoinRequest;
import es.uca.legends.entities.User;
import es.uca.legends.repositories.TeamRepository;
import es.uca.legends.services.TeamService;
import lombok.RequiredArgsConstructor;
import org.hibernate.Transaction;
import org.hibernate.engine.transaction.jta.platform.internal.SynchronizationRegistryBasedSynchronizationStrategy;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import es.uca.legends.controllers.UserController.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/teams")
@RequiredArgsConstructor
public class TeamController {

    private final TeamService teamService;
    private final TeamRepository teamRepository;

    @GetMapping("/")
    public ResponseEntity<?> getAllTeams() {

        List<Team> teams = teamRepository.findAll();

        System.out.println("--------------------------------------------------------------------------------------------");
        System.out.println("Cargados " + teams.size() + " equipos.");
        for ( Team t : teams){
            System.out.println("--------");
            System.out.println("Equipo:" + t);
            System.out.println("--------");
        }
        System.out.println("--------------------------------------------------------------------------------------------\n");
        return ResponseEntity.ok(teams);
    }

    @PostMapping("/create")
    public ResponseEntity<?> createTeam(@AuthenticationPrincipal User user, @RequestBody CreateTeamRequest request) {
        try {
            // 1. Llamamos al servicio para crear el equipo
            Team createdTeam = teamService.createTeam(user, request);

            // 2. CONVERSIÓN MANUAL A DTO (Para evitar el bucle infinito)
            Team response = new Team();
            response.setId(createdTeam.getId());
            response.setName(createdTeam.getName());
            response.setTag(createdTeam.getTag());
            response.setDivision(createdTeam.getDivision());
            response.setRegion(createdTeam.getRegion());

            List<Player> memberDtos = createdTeam.getMembers().stream().map(player -> {
                Player m = new Player();
                m.setRiotIdName(player.getRiotIdName());
                m.setRiotIdTag(player.getRiotIdTag());
                m.setTier(player.getTier());
                m.setDivision(player.getDivision());
                return m;
            }).toList();

            response.setMembers(memberDtos);

            // Seguridad para evitar NullPointer si el player no cargo bien
            if (user.getPlayer() != null) {
                response.setLeader(user.getPlayer());
            }


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

    @GetMapping("/{teamId}/members")
    public ResponseEntity<?> getTeamMembers(@PathVariable Long teamId) {
        // 1. Buscamos el equipo
        Team team = teamRepository.findById(teamId)
                .orElseThrow(() -> new RuntimeException("Equipo no encontrado con ID: " + teamId));

        // 2. Convertimos la lista de Players a TeamMemberDto
        // Esto es útil para calcular 'isLeader' al vuelo
        List<TeamMemberDto> membersDto = team.getMembers().stream().map(player -> {
            TeamMemberDto dto = new TeamMemberDto();
            dto.setId(player.getId());
            dto.setRiotIdName(player.getRiotIdName());
            dto.setRiotIdTag(player.getRiotIdTag());
            dto.setTier(player.getTier());
            dto.setDivision(player.getDivision());

            // Calculamos si este jugador es el líder del equipo
            boolean isLeader = team.getLeader() != null && team.getLeader().getId().equals(player.getId());
            dto.setLeader(isLeader);

            return dto;
        }).toList();

        return ResponseEntity.ok(membersDto);
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

    @PostMapping("/{teamId}/request")
    public ResponseEntity<?> requestJoin(@PathVariable Long teamId, @AuthenticationPrincipal User user) {
        teamService.requestJoinTeam(user, teamId);
        return ResponseEntity.ok("Solicitud enviada.");
    }

    @GetMapping("/requests")
    public ResponseEntity<List<TeamRequestDto>> getRequests(@AuthenticationPrincipal User user) {
        List<TeamJoinRequest> reqs = teamService.getPendingRequests(user);

        List<TeamRequestDto> dtos = reqs.stream().map(req -> {
            TeamRequestDto dto = new TeamRequestDto();

            Player actual = req.getPlayer();
            dto.setRequestId(req.getId());
            dto.setPlayer(actual);
            return dto;
        }).toList();

        return ResponseEntity.ok(dtos);
    }

    @PostMapping("/requests/{requestId}/{action}") // action: "accept" o "reject"
    public ResponseEntity<?> respondRequest(@PathVariable Long requestId, @PathVariable String action, @AuthenticationPrincipal User user) {
        teamService.respondToRequest(user, requestId, action.equalsIgnoreCase("accept"));
        return ResponseEntity.ok("Respuesta procesada.");
    }
    /*
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
    */
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
