package es.uca.legends.services;

import es.uca.legends.entities.Match;
import es.uca.legends.entities.Team;
import es.uca.legends.entities.User;
import es.uca.legends.repositories.MatchRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class MatchService {

    private final MatchRepository matchRepository;

    // Inyectamos TU servicio para cederle el control de las rondas
    private final TournamentService tournamentService;

    @Transactional
    public void reportMatchResult(Long matchId, String riotMatchId, User currentUser) {
        Match match = matchRepository.findById(matchId)
                .orElseThrow(() -> new RuntimeException("Partida no encontrada"));

        if ("FINISHED".equals(match.getStatus())) {
            throw new RuntimeException("Esta partida ya ha finalizado.");
        }

        // 1. Validar que el usuario es el líder del Equipo A o del Equipo B
        boolean isLeaderA = match.getTeamA() != null && match.getTeamA().getLeader().getUser().getId().equals(currentUser.getId());
        boolean isLeaderB = match.getTeamB() != null && match.getTeamB().getLeader().getUser().getId().equals(currentUser.getId());

        if (!isLeaderA && !isLeaderB) {
            throw new RuntimeException("Solo los líderes participantes pueden reportar el resultado.");
        }

        // 2. Simular victoria (Aquí irá la lógica de la API de Riot en el futuro)
        Team simulatedWinner = Math.random() > 0.5 ? match.getTeamA() : match.getTeamB();
        if (match.getTeamB() == null) simulatedWinner = match.getTeamA(); // Fallback por si acaso

        match.setRiotMatchId(riotMatchId);
        match.setWinner(simulatedWinner);
        match.setStatus("FINISHED");
        matchRepository.save(match);

        // 3. ¿Es esta la última partida de la ronda?
        // Usamos la misma consulta que tú creaste en TournamentService
        boolean unfinishedMatches = matchRepository.existsByTournamentAndRoundAndStatusNot(
                match.getTournament(),
                match.getTournament().getCurrentRound(),
                "FINISHED"
        );

        // Si ya no quedan partidos pendientes, avanzamos de ronda mágicamente
        if (!unfinishedMatches) {
            tournamentService.advanceToNextRound(match.getTournament().getId());
        }
    }
}