package es.uca.legends.controllers;

import es.uca.legends.dtos.PlayerResponse;
import es.uca.legends.dtos.TeamMemberDto;
import es.uca.legends.dtos.TeamResponseDto;
import es.uca.legends.dtos.UserResponse;
import es.uca.legends.entities.Player;
import es.uca.legends.entities.Team;
import es.uca.legends.entities.User;
import es.uca.legends.repositories.UserRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserRepository userRepository;

    @GetMapping("/me")
    public ResponseEntity<?> getMyProfile(@AuthenticationPrincipal User user) {

        UserResponse userDto = new UserResponse();
        userDto.setId(user.getId());
        userDto.setEmail(user.getEmail());
        userDto.setRole(user.getRole());

        if (user.getPlayer() != null) {
            Player player = user.getPlayer();

            PlayerResponse playerDto = new PlayerResponse();
            playerDto.setId(player.getId());
            playerDto.setRiotIdName(player.getRiotIdName());
            playerDto.setRiotIdTag(player.getRiotIdTag());
            playerDto.setTier(player.getTier());
            playerDto.setSummonerLevel(player.getSummonerLevel());
            playerDto.setLeaguePoints(player.getLeaguePoints());
            playerDto.setDivision(player.getDivision());
            playerDto.setProfileIconId(player.getProfileIconId());

            if (player.getTeam() != null) {
                Team team = player.getTeam(); // Variable auxiliar para escribir menos

                TeamResponseDto teamDto = new TeamResponseDto();
                teamDto.setId(team.getId());
                teamDto.setName(team.getName());
                teamDto.setTag(team.getTag());
                teamDto.setDivision(team.getDivision());

                List<TeamMemberDto> memberList = team.getMembers().stream().map(member -> {
                    TeamMemberDto m = new TeamMemberDto();
                    m.setRiotIdName(member.getRiotIdName());
                    m.setRiotIdTag(member.getRiotIdTag());
                    m.setTier(member.getTier());
                    m.setDivision(member.getDivision());
                    boolean isLeader = team.getLeader() != null && member.getId().equals(team.getLeader().getId());
                    m.setLeader(isLeader);
                    return m;
                }).toList();

                teamDto.setMembers(memberList);

                playerDto.setTeam(teamDto);
            }

            userDto.setPlayer(playerDto);
        }

        return ResponseEntity.ok(userDto);
    }
}