package es.uca.legends.services;

import es.uca.legends.entities.Match;
import es.uca.legends.entities.Team;
import es.uca.legends.entities.Tournament;
import es.uca.legends.entities.TournamentRegistration;
import es.uca.legends.repositories.MatchRepository;
import es.uca.legends.repositories.TournamentRegistrationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.expression.spel.ast.NullLiteral;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Service
@RequiredArgsConstructor
public class MatchmakingService {

    private final MatchRepository matchRepository;
    private final TournamentRegistrationRepository registrationRepository;

    @Transactional
    public List<Match> generateMatches(Tournament tournament, List<Team> teamsInput, int roundNumber) {

        if (teamsInput.size() < 2) {
            return new ArrayList<>();
        }

        List<Team> activeTeams = new ArrayList<>(teamsInput);

        activeTeams.sort(Comparator.comparingDouble(Team::getAverageScore).reversed());

        List<Match> newMatches = new ArrayList<>();

        // 2. GESTIÓN DEL "BYE" (Si el número de equipos es IMPAR)
        if (activeTeams.size() % 2 != 0) {
            Team byeTeam = findByeCandidate(tournament, activeTeams);

            // Creamos el partido "falso" de victoria automática
            Match byeMatch = Match.builder()
                    .tournament(tournament)
                    .teamA(byeTeam)
                    .teamB(null)
                    .round(roundNumber)
                    .riotMatchId("EUW_"+tournament.getId() + "_" + byeTeam.getId() + "_" + "BYE_" + roundNumber)
                    .matchDate(calculateMatchDate(tournament, roundNumber))
                    .winner(byeTeam)   // Gana directamente
                    .status("FINISHED")
                    .build();

            newMatches.add(byeMatch);

            // IMPORTANTE: Marcar en la BD que ya gastó su Bye
            markTeamAsByeReceived(tournament, byeTeam);

            // Lo quitamos de la lista para no emparejarlo con nadie más
            activeTeams.remove(byeTeam);
        }

        // 3. EMPAREJAMIENTO DEL RESTO (Sistema Escalera)
        // Como ya quitamos el impar, ahora la lista es PAR.
        for (int i = 0; i < activeTeams.size(); i += 2) {
            Team team1 = activeTeams.get(i);
            Team team2 = activeTeams.get(i + 1);

            Match match = Match.builder()
                    .tournament(tournament)
                    .teamA(team1)
                    .teamB(team2)
                    .round(roundNumber)
                    .riotMatchId("EUW_"+tournament.getId() + "_" + team1.getId() + "_" + team2.getId() + "_" + roundNumber)
                    .matchDate(null)
                    .status("SCHEDULED")
                    .build();

            newMatches.add(match);
        }

        return matchRepository.saveAll(newMatches);
    }

    // --- MÉTODOS AUXILIARES ---

    /**
     * Busca al peor equipo disponible que NO haya tenido un Bye todavía.
     */
    private Team findByeCandidate(Tournament tournament, List<Team> teams) {
        // Recorremos la lista AL REVÉS (desde el peor ELO hacia el mejor)
        for (int i = teams.size() - 1; i >= 0; i--) {
            Team candidate = teams.get(i);

            // Consultamos si ya tuvo Bye
            boolean alreadyHadBye = registrationRepository
                    .hasReceivedBye(tournament.getId(), candidate.getId());

            if (!alreadyHadBye) {
                return candidate; // ¡Encontrado!
            }
        }

        // EDGE CASE: Si todos los equipos vivos ya tuvieron un Bye (muy raro,
        // solo pasa en formatos de liga o finales raras), le damos el Bye al último (el peor).
        return teams.getLast();
    }

    private void markTeamAsByeReceived(Tournament tournament, Team team) {
        TournamentRegistration reg = registrationRepository
                .findByTournamentIdAndTeamId(tournament.getId(), team.getId())
                .orElseThrow();

        reg.setHasReceivedBye(true);
        registrationRepository.save(reg);
    }

    private LocalDateTime calculateMatchDate(Tournament tournament, int round) {
        // Ejemplo: Cada ronda dura 1 hora
        // Ronda 1: Inicio
        // Ronda 2: Inicio + 1 hora
        return tournament.getFechaInicio().plusHours(round - 1);
    }
}