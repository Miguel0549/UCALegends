package es.uca.legends.services;
import es.uca.legends.dtos.DevPLayerLinkRequest;
import es.uca.legends.entities.Player;
import es.uca.legends.entities.User;
import es.uca.legends.repositories.PlayerRepository;
import es.uca.legends.repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.webmvc.autoconfigure.WebMvcProperties;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class PlayerService {

    private final PlayerRepository playerRepository;
    private final UserRepository userRepository;

    @Transactional
    public Player linkDevPlayer(User user, DevPLayerLinkRequest request) {

        if (user.getPlayer() != null) {
            throw new RuntimeException("El usuario ya tiene una cuenta de Riot vinculada.");
        }

        String gameName = request.getGameName();
        String tagLine = request.getTagLine();
        Integer summonerLevel = request.getSummonerLevel();
        String tier = request.getTier();
        String division = request.getDivision();
        Integer leaguePoints = request.getLeaguePoints();
        Integer iconId = request.getIconId();


        // PUUID simulado
        String mockPuuid = "mock-puuid-" + gameName.toLowerCase() + "-" + tagLine.toLowerCase();

        Player newPlayer = Player.builder()
                .riotIdName(gameName)
                .riotIdTag(tagLine)
                .puuid(mockPuuid)
                .region("EUW")
                .summonerLevel(summonerLevel)
                .tier(tier)
                .division(division)
                .leaguePoints(leaguePoints)
                .profileIconId(iconId)
                .user(user)
                .build();

        return playerRepository.save(newPlayer);
    }


    @Transactional
    public void unlinkRiotAccount(User principal) {

        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));

        Player player = user.getPlayer();

        if (player == null) {
            throw new RuntimeException("No tienes ninguna cuenta de Riot vinculada.");
        }

        if (player.getTeam() != null) {
            throw new RuntimeException("No puedes desvincular tu cuenta mientras pertenezcas a un equipo ("
                    + player.getTeam().getName() + "). Sal del equipo o disuélvelo primero.");
        }

        user.setPlayer(null);

        userRepository.save(user);
    }
}
