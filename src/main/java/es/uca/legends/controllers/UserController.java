package es.uca.legends.controllers;

import es.uca.legends.dtos.PlayerResponse;
import es.uca.legends.dtos.TeamMemberDto;
import es.uca.legends.dtos.TeamResponseDto;
import es.uca.legends.dtos.UserResponse;
import es.uca.legends.entities.Player;
import es.uca.legends.entities.Team;
import es.uca.legends.entities.User;
import es.uca.legends.repositories.PlayerRepository;
import es.uca.legends.repositories.UserRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserRepository userRepository;
    private final PlayerRepository playerRepository;
    private final JdbcTemplate jdbcTemplate;

    @GetMapping("/me")
    public ResponseEntity<?> getMyProfile(@AuthenticationPrincipal User user) {

        UserResponse userDto = new UserResponse();
        userDto.setId(user.getId());
        userDto.setEmail(user.getEmail());
        userDto.setRole(user.getRole());

        if (user.getPlayer() != null) {

            Player player = user.getPlayer();

            if (player.getTeam() != null) {
                Team team = player.getTeam(); // Variable auxiliar para escribir menos

                Team teamDto = new Team();
                teamDto.setId(team.getId());
                teamDto.setLeader(team.getLeader());
                teamDto.setName(team.getName());
                teamDto.setTag(team.getTag());
                teamDto.setDivision(team.getDivision());

                List<Player> memberList = team.getMembers().stream().map(member -> {
                    Player m = new Player();
                    m.setId(member.getId());
                    m.setRiotIdName(member.getRiotIdName());
                    m.setRiotIdTag(member.getRiotIdTag());
                    m.setTier(member.getTier());
                    m.setDivision(member.getDivision());
                    return m;
                }).toList();

                teamDto.setMembers(memberList);

                player.setTeam(teamDto);
            }

            userDto.setPlayer(player);
        }

        return ResponseEntity.ok(userDto);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Player> getMyProfile(@AuthenticationPrincipal User actualUser, @PathVariable Long id) {

        Player player = playerRepository.findById(id).orElse(new Player());

        return ResponseEntity.ok(player);
    }

}