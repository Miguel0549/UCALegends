package es.uca.legends.services;
import es.uca.legends.dtos.CreateTeamRequest;
import es.uca.legends.entities.*;
import es.uca.legends.repositories.PlayerRepository;
import es.uca.legends.repositories.TeamJoinRequestRepository;
import es.uca.legends.repositories.TeamRepository;
import es.uca.legends.repositories.TournamentRegistrationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

@Service
@RequiredArgsConstructor
public class TeamService {

    private final TeamRepository teamRepository;
    private final PlayerRepository playerRepository;
    private final TeamJoinRequestRepository requestRepository;
    private final TournamentRegistrationRepository tournamentRegistrationRepository;

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

        List<Player> lider = new ArrayList<>();
        lider.add(currentPlayer);

        Team newTeam = Team.builder()
                .name(request.getName())
                .tag(request.getTag())
                .region(request.getRegion())
                .members(lider)
                .leader(currentPlayer) // Asignamos líder
                .build();

        newTeam = updateTeamDivision(newTeam);

        currentPlayer.setTeam(newTeam);
        playerRepository.save(currentPlayer);

        return newTeam;
    }

    public void requestJoinTeam(User user, Long teamId) {
        Player player = user.getPlayer();
        Team team = teamRepository.findById(teamId).orElseThrow();

        if (player.getTeam() != null) throw new RuntimeException("Ya tienes equipo.");
        if (requestRepository.existsByPlayerIdAndTeamId(player.getId(), teamId)) {
            throw new RuntimeException("Ya has enviado solicitud a este equipo.");
        }

        TeamJoinRequest req = TeamJoinRequest.builder()
                .player(player)
                .team(team)
                .requestDate(LocalDateTime.now())
                .build();

        requestRepository.save(req);
    }

    public List<TeamJoinRequest> getPendingRequests(User user) {
        Team team = user.getPlayer().getTeam();
        if (team == null || !team.getLeader().getId().equals(user.getPlayer().getId())) {
            throw new RuntimeException("Solo el líder puede ver solicitudes.");
        }
        return requestRepository.findByTeamId(team.getId());
    }

    // --- D. RESPONDER SOLICITUD (Aceptar/Rechazar) ---
    public void respondToRequest(User leaderUser, Long requestId, boolean accept) {
        TeamJoinRequest req = requestRepository.findById(requestId)
                .orElseThrow(() -> new RuntimeException("Solicitud no encontrada"));

        // Verificar permisos
        if (!req.getTeam().getLeader().getId().equals(leaderUser.getPlayer().getId())) {
            throw new RuntimeException("No autorizado.");
        }

        Player newMember = req.getPlayer();

        if ( newMember.getTeam() == null ){
            if (accept) {

                Team team = req.getTeam();

                // Asignar equipo
                newMember.setTeam(team);
                playerRepository.save(newMember);

                // Actualizar media (FIX de memoria incluido)
                if (team.getMembers() == null) team.setMembers(new ArrayList<>());
                team.getMembers().add(newMember);
                updateTeamDivision(team);
                teamRepository.save(team);
            }
        }else throw new RuntimeException("El jugador ya está en un equipo");


        // Borrar la solicitud (tanto si se acepta como si se rechaza)
        requestRepository.delete(req);
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

        if (tournamentRegistrationRepository.isTeamPlayingActiveTournament(team)) {
            throw new RuntimeException("No puedes abandonar el equipo ahora mismo. Estáis participando en un torneo en curso.");
        }

        List<TournamentRegistration> pendingRegistrations = tournamentRegistrationRepository.findPendingRegistrationsByTeam(team);

        if (!pendingRegistrations.isEmpty()) {
            tournamentRegistrationRepository.deleteAll(pendingRegistrations);
        }

        currentPlayer.setTeam(null);
        playerRepository.save(currentPlayer);
        team.getMembers().remove(currentPlayer);
        updateTeamDivision(team);
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
        team.getMembers().remove(playerToKick);
        playerToKick.setTeam(null);
        playerRepository.save(playerToKick);
        updateTeamDivision(team);
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

        List<Player> members = team.getMembers();

        for (Player member : members) {
            member.setTeam(null);  // Rompemos la relación en el objeto Java
            playerRepository.save(member); // Actualizamos el estado del jugador
        }

        team.getMembers().clear();

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

    private Team updateTeamDivision(Team team) {

        List<Player> members = team.getMembers();

        if (members == null || members.isEmpty()) {
            team.setDivision("III");
        }else{

            double totalScore = 0;
            int count = 0;

            for (Player p : members) {
                double puntosJugador = getTierValue(p.getTier()) + getDivisionValue(p.getDivision()) + (0.002 * p.getLeaguePoints());
                totalScore += puntosJugador;
                count++;
            }


            double average = (count > 0) ? totalScore / count : 0;
            team.setAverageScore(average);

            if (average <= 3.0) { // Hierro, Bronce, Plata
                team.setDivision("IV");
            } else if (average <= 5.0) { // Oro ,Platino,
                team.setDivision("III");
            } else if (average <= 7) { // Esmeralda, Diamante
                team.setDivision("II");
            } else team.setDivision("I");
        }



        return teamRepository.save(team);
    }

    private int getTierValue(String tier) {
        if (tier == null) return 0; // Unranked cuenta como 0

        return switch (tier.toUpperCase()) {
            case "IRON" -> 1;
            case "BRONZE" -> 2;
            case "SILVER" -> 3;
            case "GOLD" -> 4;
            case "PLATINUM" -> 5;
            case "EMERALD" -> 6; // OJO: Emerald existe en LoL moderno
            case "DIAMOND" -> 7;
            case "MASTER" -> 8;
            case "GRANDMASTER" -> 9;
            case "CHALLENGER" -> 10;
            default -> 0; // Unranked
        };
    }


    private double getDivisionValue(String division){

        if (division == null ) return 0;

        return switch (division.toUpperCase()) {
            case "IV" -> 0.2;
            case "III" -> 0.4;
            case "II" -> 0.6;
            case "I" -> 0.8;
            default -> 0;
        };
    }

}
