package es.uca.legends.services;

import es.uca.legends.dtos.TournamentHistoryDto;
import es.uca.legends.entities.*;
import es.uca.legends.repositories.MatchRepository;
import es.uca.legends.repositories.PlayerRepository;
import es.uca.legends.repositories.TournamentRegistrationRepository;
import es.uca.legends.repositories.TournamentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Service
@RequiredArgsConstructor
public class TournamentService {

    private final TournamentRepository tournamentRepository;
    private final TournamentRegistrationRepository registrationRepository;
    private final PlayerRepository playerRepository;
    private final MatchRepository matchRepository;


    @Transactional
    public void deleteTournament(Long tournamentId) {
        if (!tournamentRepository.existsById(tournamentId)) {
            throw new RuntimeException("El torneo no existe.");
        }
        tournamentRepository.deleteById(tournamentId);
    }

    @Transactional
    public void joinTournament(User user, Long tournamentId) {
        // 1. Validar Usuario y Equipo
        Player leader = user.getPlayer();
        if (leader == null || leader.getTeam() == null) {
            throw new RuntimeException("Debes pertenecer a un equipo para inscribirte.");
        }
        Team team = leader.getTeam();

        if (!team.getLeader().getId().equals(leader.getId())) {
            throw new RuntimeException("Solo el líder del equipo puede realizar la inscripción.");
        }

        Long membersCount = playerRepository.countByTeamId(team.getId());

        if (membersCount != 5) {
            throw new RuntimeException("El equipo debe tener exactamente 5 integrantes para participar. " +
                    "Actualmente tiene: " + membersCount);
        }

        Tournament tournament = tournamentRepository.findById(tournamentId)
                .orElseThrow(() -> new RuntimeException("Torneo no encontrado."));

        if ( !tournament.getRegion().equals(team.getRegion())){
            throw new RuntimeException("El equipo debe pertenecer a la region " + tournament.getRegion() + " para poder inscribirte en este torneo");
        }

        if (!"ABIERTO".equals(tournament.getStatus())) {
            throw new RuntimeException("El torneo no admite inscripciones (Estado: " + tournament.getStatus() + ").");
        }

        if (tournament.getFechaInscripciones() != null && LocalDateTime.now().isAfter(tournament.getFechaInscripciones())) {
            throw new RuntimeException("El plazo de inscripción finalizó el " + tournament.getFechaInscripciones());
        }

        if (tournament.getRegion() != null && !tournament.getRegion().equalsIgnoreCase(team.getRegion())) {
            throw new RuntimeException("Región incorrecta. Tu equipo es de " + team.getRegion() +
                    " y el torneo es de " + tournament.getRegion());
        }

        long inscritos = registrationRepository.countByTournamentId(tournamentId);
        if (tournament.getMaxTeams() != null && inscritos >= tournament.getMaxTeams()) {
            throw new RuntimeException("El torneo está lleno (" + inscritos + "/" + tournament.getMaxTeams() + ").");
        }

        if (registrationRepository.existsByTournamentIdAndTeamId(tournamentId, team.getId())) {
            throw new RuntimeException("Tu equipo ya está inscrito en este torneo.");
        }

        TournamentRegistration registration = TournamentRegistration.builder()
                .tournament(tournament)
                .team(team)
                .registeredAt(LocalDateTime.now())
                .build();

        registrationRepository.save(registration);
    }

    @Transactional
    public void leaveTournament(User user, Long tournamentId) {
        Player leader = user.getPlayer();

        if (leader == null || leader.getTeam() == null) {
            throw new RuntimeException("No tienes equipo.");
        }
        Team team = leader.getTeam();

        if (!team.getLeader().getId().equals(leader.getId())) {
            throw new RuntimeException("Solo el líder puede retirar al equipo.");
        }

        // Buscar la inscripción específica
        TournamentRegistration registration = registrationRepository
                .findByTournamentIdAndTeamId(tournamentId, team.getId())
                .orElseThrow(() -> new RuntimeException("El equipo no está inscrito en este torneo."));

        Tournament tournament = registration.getTournament();

        if (tournament.getFechaInicio() != null && LocalDateTime.now().isAfter(tournament.getFechaInicio())) {
            throw new RuntimeException("No puedes abandonar el torneo porque ya ha comenzado.");
        }

        if ("EN_CURSO".equals(tournament.getStatus()) || "FINALIZADO".equals(tournament.getStatus())) {
            throw new RuntimeException("No puedes abandonar un torneo en curso o finalizado.");
        }

        registrationRepository.delete(registration);
    }


    // Método auxiliar para obtener ganadores

    public List<Match> getCurrentRoundMatches(Long tournamentId) {
        Tournament t = tournamentRepository.findById(tournamentId)
                .orElseThrow(() -> new RuntimeException("Torneo no encontrado"));

        return matchRepository.findByTournamentAndRound(t, t.getCurrentRound());
    }

    public List<TournamentHistoryDto> getTournamentHistory(String region) {
        // Buscamos solo los FINALIZADOS de esa región
        List<Tournament> tournaments = tournamentRepository.findByStatusAndRegion("FINALIZADO", region);

        // Convertimos la lista de Entidades a lista de DTOs
        return tournaments.stream()
                .map(t -> TournamentHistoryDto.builder()
                        .tournamentName(t.getName())
                        .fechaInicio(t.getFechaInicio())
                        .region(t.getRegion())
                        // Usamos un ternario por seguridad (si winner fuera null por algún bug antiguo)
                        .winnerName(t.getWinner() != null ? t.getWinner().getName() : "Sin Ganador")
                        .build())
                .toList();
    }


    @Transactional
    public void closeInscriptionsNow(Long tournamentId) {
        tournamentRepository.findById(tournamentId).ifPresent(t -> {
            // Comprobamos el estado por si un Admin lo canceló a mano antes de tiempo
            if ("ABIERTO".equals(t.getStatus())) {
                t.setStatus("CERRADO");
                System.out.println("Inscripciones cerradas automáticamente para: " + t.getName());
                tournamentRepository.save(t);
            }
        });
    }

    @Transactional
    public void beginTournamentNow(Long tournamentId) {
        tournamentRepository.findById(tournamentId).ifPresent(t -> {
            if ("CERRADO".equals(t.getStatus())) {
                try {
                    advanceToNextRound(t.getId());
                    System.out.println("Torneo iniciado con éxito: " + t.getName());
                } catch (Exception e) {
                    System.out.println("Cancelando por falta de equipos: " + t.getName());
                    t.setStatus("CANCELADO");
                    tournamentRepository.save(t);
                }
            }
        });
    }

    @Transactional
    public void advanceToNextRound(Long tournamentId) {
        Tournament tournament = tournamentRepository.findById(tournamentId)
                .orElseThrow(() -> new RuntimeException("Torneo no encontrado"));

        if (tournament.getCurrentRound() == null) {
            tournament.setCurrentRound(0);
        }

        // 1. Validar que la ronda actual ha terminado
        if (tournament.getCurrentRound() > 0) {
            boolean unfinishedMatches = matchRepository.existsByTournamentAndRoundAndStatusNot(
                    tournament,
                    tournament.getCurrentRound(),
                    "FINISHED"
            );

            if (unfinishedMatches) {
                throw new RuntimeException("No se puede avanzar de ronda: Aún hay partidos pendientes.");
            }
        }

        // 2. Obtener los ganadores de la ronda actual (para pasarlos a la siguiente)
        List<Team> winners;

        if (tournament.getCurrentRound() == 0) {
            // CASO ESPECIAL: Si es la ronda 0, pasamos a Ronda 1 con TODOS los inscritos
            winners = registrationRepository.findTeamsByTournamentId(tournamentId);
            if ( winners.isEmpty() || winners.size() < 4 ){
                throw new RuntimeException("No hay equipos suficientes para empezar el torneo");
            }
            tournament.setStatus("EN_CURSO");
        } else {
            // CASO NORMAL: Buscamos los ganadores de la ronda que acaba de terminar
            winners = getWinnersOfRound(tournament, tournament.getCurrentRound());

            // Si solo queda 1 ganador, ¡El torneo ha terminado!
            if (winners.size() == 1) {
                tournament.setStatus("FINALIZADO");

                // --- NUEVO: Guardamos al ganador ---
                tournament.setWinner(winners.getFirst());
                // -----------------------------------

                tournamentRepository.save(tournament);
                return;
            }
        }

        // 3. Incrementar ronda
        int nextRound = tournament.getCurrentRound() + 1;
        tournament.setCurrentRound(nextRound);

        // 4. Generar los cruces usando tu MatchmakingService
        generateMatches(tournament, winners, nextRound);

        tournamentRepository.save(tournament);
    }

    private List<Team> getWinnersOfRound(Tournament tournament, int round) {
        List<Match> matches = matchRepository.findByTournamentAndRound(tournament, round);
        List<Team> winners = new ArrayList<>();

        for (Match m : matches) {
            if (m.getWinner() != null) {
                winners.add(m.getWinner());
            } else {
                // Esto no debería pasar si validamos unfinishedMatches antes,
                // pero por seguridad lanzamos error.
                throw new RuntimeException("Error crítico: El partido " + m.getId() + " no tiene ganador.");
            }
        }
        return winners;
    }

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
                    .matchDate(LocalDateTime.now())
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
}