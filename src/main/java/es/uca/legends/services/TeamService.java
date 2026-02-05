package es.uca.legends.services;
import es.uca.legends.dtos.CreateTeamRequest;
import es.uca.legends.entities.Player;
import es.uca.legends.entities.Team;
import es.uca.legends.entities.User;
import es.uca.legends.repositories.PlayerRepository;
import es.uca.legends.repositories.TeamRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class TeamService {

    private final TeamRepository teamRepository;
    private final PlayerRepository playerRepository;

    @Transactional
    public Team createTeam(User user, CreateTeamRequest request) {

        Player currentPlayer = user.getPlayer();

        if (currentPlayer == null) {
            throw new RuntimeException("Debes vincular una cuenta de Riot antes de crear un equipo.");
        }

        if (currentPlayer.getTeam() != null) {
            throw new RuntimeException("Ya perteneces al equipo '" + currentPlayer.getTeam().getName() + "'. Debes abandonarlo antes de crear uno nuevo.");
        }

        if (teamRepository.existsByName(request.getName())) {
            throw new RuntimeException("Ya existe un equipo con ese nombre.");
        }

        Team newTeam = Team.builder()
                .name(request.getName())
                .tag(request.getTag())
                .region(request.getRegion())
                .leader(currentPlayer) // Asignamos líder
                .build();

        newTeam = teamRepository.save(newTeam);

        currentPlayer.setTeam(newTeam);
        playerRepository.save(currentPlayer);

        return newTeam;
    }


    @Transactional
    public void joinTeam(User user, Long teamId) {
        Player currentPlayer = user.getPlayer();

        if (currentPlayer == null) {
            throw new RuntimeException("No tienes perfil de jugador.");
        }

        if (currentPlayer.getTeam() != null) {
            throw new RuntimeException("Ya estás en un equipo. Sal primero para unirte a otro.");
        }

        Team team = teamRepository.findById(teamId)
                .orElseThrow(() -> new RuntimeException("El equipo no existe."));

        if (team.getMembers().size() >= 5) throw new RuntimeException("Equipo lleno");

        currentPlayer.setTeam(team);
        playerRepository.save(currentPlayer);
    }

    @Transactional
    public void leaveTeam(User user) {
        Player currentPlayer = user.getPlayer();

        if (currentPlayer == null || currentPlayer.getTeam() == null) {
            throw new RuntimeException("No estás en ningún equipo.");
        }

        Team team = currentPlayer.getTeam();

        if (team.getLeader().getId().equals(currentPlayer.getId())) {
            throw new RuntimeException("Eres el líder. Debes nombrar otro líder o disolver el equipo.");
        }

        currentPlayer.setTeam(null);
        playerRepository.save(currentPlayer);
    }

    @Transactional
    public void kickPlayer(User user, Long playerIdToKick) {
        Player leaderPlayer = user.getPlayer();

        if (leaderPlayer == null || leaderPlayer.getTeam() == null) {
            throw new RuntimeException("No perteneces a ningún equipo.");
        }

        Team team = leaderPlayer.getTeam();

        if (!team.getLeader().getId().equals(leaderPlayer.getId())) {
            throw new RuntimeException("Solo el líder del equipo puede expulsar miembros.");
        }

        if (leaderPlayer.getId().equals(playerIdToKick)) {
            throw new RuntimeException("No puedes expulsarte a ti mismo. Usa la opción de 'Disolver equipo' o 'Salir'.");
        }

        Player playerToKick = playerRepository.findById(playerIdToKick)
                .orElseThrow(() -> new RuntimeException("El jugador no existe."));

        if (!team.getId().equals(playerToKick.getTeam().getId())) {
            throw new RuntimeException("Ese jugador no pertenece a tu equipo.");
        }

        // 5. Ejecutar la expulsión (Desvincular)
        playerToKick.setTeam(null);
        playerRepository.save(playerToKick);
    }

    @Transactional
    public void deleteTeam(User user) {
        Player leaderPlayer = user.getPlayer();

        if (leaderPlayer == null || leaderPlayer.getTeam() == null) {
            throw new RuntimeException("No tienes equipo para eliminar.");
        }

        Team team = leaderPlayer.getTeam();

        if (!team.getLeader().getId().equals(leaderPlayer.getId())) {
            throw new RuntimeException("Solo el líder puede disolver el equipo.");
        }

        leaderPlayer.setTeam(null);
        playerRepository.save(leaderPlayer);

        teamRepository.delete(team);
    }

    @Transactional
    public void transferLeadership(User currentUser, Long newLeaderId) {
        Player currentLeader = currentUser.getPlayer();

        if (currentLeader == null || currentLeader.getTeam() == null) {
            throw new RuntimeException("No perteneces a ningún equipo.");
        }

        Team team = currentLeader.getTeam();

        if (!team.getLeader().getId().equals(currentLeader.getId())) {
            throw new RuntimeException("Solo el líder actual puede transferir el liderazgo.");
        }

        Player newLeader = playerRepository.findById(newLeaderId)
                .orElseThrow(() -> new RuntimeException("El jugador candidato no existe."));

        if (newLeader.getTeam() == null || !newLeader.getTeam().getId().equals(team.getId())) {
            throw new RuntimeException("El nuevo líder debe ser miembro de tu equipo.");
        }

        team.setLeader(newLeader);
        teamRepository.save(team);
    }

}
