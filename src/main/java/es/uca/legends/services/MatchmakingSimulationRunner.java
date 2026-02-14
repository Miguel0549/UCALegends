package es.uca.legends.services;
import es.uca.legends.entities.*;
import es.uca.legends.repositories.*;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.NonNull;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

//@Component
@RequiredArgsConstructor
public class MatchmakingSimulationRunner implements CommandLineRunner {

    private final TeamRepository teamRepository;
    private final TournamentRepository tournamentRepository;
    private final TournamentService tournamentService;
    private final TournamentRegistrationRepository registrationRepository;
    private final MatchRepository matchRepository;
    private final PlayerRepository playerRepository;
    private final UserRepository userRepository;

    @Override
    @Transactional
    public void run(String @NonNull ... args) throws Exception {
        System.out.println("\n===========================================");
        System.out.println("⚡ INICIANDO SIMULACIÓN COMPLETA (Equipos Reales) ⚡");
        System.out.println("===========================================\n");

        // 1. CREAR TORNEO
        Tournament torneo = Tournament.builder()
                .name("Legends Cup " + System.currentTimeMillis())
                .region("EUW") // Importante que coincida con los equipos
                .gameMode("CLASSIC")
                .maxTeams(12)
                .fechaInscripciones(LocalDateTime.now().minusDays(1))
                .fechaInicio(LocalDateTime.now())
                .status("ABIERTO")
                .currentRound(0)
                .build();
        tournamentRepository.save(torneo);

        List<Team> equipos = new ArrayList<>();

        // 2. CREAR EQUIPOS CON DATOS REALISTAS
        // Simulamos distintos niveles para ver cómo quedan las divisiones I, II y III

        // Equipo División I (Challengers)
        equipos.add(crearEquipoCompleto("T1", "SKT", "EUW", "CHALLENGER"));

        // Equipo División II (Diamantes/Platinos)
        equipos.add(crearEquipoCompleto("G2 Esports", "G2", "EUW", "DIAMOND"));
        equipos.add(crearEquipoCompleto("Fnatic", "FNC", "EUW", "PLATINUM"));

        // Equipo División III (Oros/Hierros)
        equipos.add(crearEquipoCompleto("Koi", "KOI", "EUW", "GOLD"));
        equipos.add(crearEquipoCompleto("Mad Lions", "MAD", "EUW", "IRON"));

        // 3. INSCRIBIRLOS AL TORNEO
        for (Team t : equipos) {
            TournamentRegistration reg = TournamentRegistration.builder()
                    .tournament(torneo)
                    .team(t)
                    .registeredAt(LocalDateTime.now())
                    .hasReceivedBye(false)
                    .build();
            registrationRepository.save(reg);

            System.out.println("📝 Equipo Inscrito: " + t.getName() +
                    " | Media: " + t.getAverageScore() +
                    " | Div Equipo: " + t.getDivision());
        }

        System.out.println("\n>>> INICIANDO TORNEO (Genera Ronda 1) <<<");
        // Esto debería crear los partidos de la Ronda 1 en la base de datos con estado PENDING
        tournamentService.advanceToNextRound(torneo.getId());

        // =========================================================================
        // 🔴 RONDA 1
        // =========================================================================
        System.out.println("\n>>> JUGANDO RONDA 1 <<<");

        // 1. Recuperamos lo que startTournament ha creado en la BD
        List<Match> matchesR1 = matchRepository.findByTournamentAndRound(torneo, 1);

        if (matchesR1.isEmpty()) {
            throw new RuntimeException("Error: No se han generado partidos para la Ronda 1.");
        }

        // 2. Simulamos
        for (Match m : matchesR1) {
            simularPartido(m); // Método auxiliar abajo
        }

        // 3. Avanzamos (Esto valida que R1 acabó y GENERA los partidos de R2)
        System.out.println("✅ Ronda 1 finalizada. Avanzando...");
        tournamentService.advanceToNextRound(torneo.getId());


        // =========================================================================
        // 🔴 RONDA 2
        // =========================================================================
        System.out.println("\n>>> JUGANDO RONDA 2 <<<");

        // 1. Recuperamos los partidos que advanceToNextRound acaba de crear
        List<Match> matchesR2 = matchRepository.findByTournamentAndRound(torneo, 2);

        // 2. Simulamos
        for (Match m : matchesR2) {
            simularPartido(m);
        }

        // 3. Avanzamos (Valida R2 y genera R3)
        System.out.println("✅ Ronda 2 finalizada. Avanzando...");
        tournamentService.advanceToNextRound(torneo.getId());


        // =========================================================================
        // 🔴 RONDA 3 (FINAL o Semis, según cantidad de equipos)
        // =========================================================================
        System.out.println("\n>>> JUGANDO RONDA 3 <<<");

        List<Match> matchesR3 = matchRepository.findByTournamentAndRound(torneo, 3);

        // Si ya no hay partidos (porque el torneo acabó en la ronda anterior), controlamos eso
        if (!matchesR3.isEmpty()) {
            for (Match m : matchesR3) {
                simularPartido(m);
            }
            System.out.println("✅ Ronda 3 finalizada. Cerrando torneo...");
            // Al avanzar aquí, si era la final, el torneo pasará a FINALIZADO
            tournamentService.advanceToNextRound(torneo.getId());
        } else {
            System.out.println("Parece que el torneo ya ha terminado.");
        }

        System.out.println("\n✅ SIMULACIÓN COMPLETA FINALIZADA");
    }

    private void simularPartido(Match m) {
        if (m.getTeamB() == null) {
            // Es un BYE (pase directo)
            m.setWinner(m.getTeamA());
            m.setStatus("FINISHED");
            System.out.println("   ✨ [BYE] " + m.getTeamA().getName() + " pasa de ronda.");
        } else {
            // Simulación: Gana siempre el Team A (o haz un random)
            m.setWinner(m.getTeamA());
            m.setStatus("FINISHED");
            m.setDurationSec(1800); // 30 min
            System.out.println("   ⚔️  " + m.getTeamA().getName() + " gana a " + m.getTeamB().getName());
        }
        matchRepository.save(m);
    }

    /**
     * Crea toda la estructura:
     * Team -> 5 Users -> 5 Players
     * Y calcula la División del Equipo (I, II, III) basada en los jugadores.
     */
    private Team crearEquipoCompleto(String nombre, String tag, String region, String tierJugadores) {

        // PASO 1: Crear PRIMERO al Líder (Usuario + Player)
        // Necesitamos un líder guardado para poder crear el equipo

        // A. Usuario del Líder
        User leaderUser = User.builder()
                .email("leader_" + tag + "_" + System.nanoTime() + "@test.com")
                .passwordHash("pass")
                .role("ROLE_USER")
                .build();
        userRepository.save(leaderUser);

        // B. Jugador Líder (Team = null temporalmente)
        Player leader = Player.builder()
                .user(leaderUser)
                .puuid("puuid-"+"lider-" + tag )
                .team(null) // Aún no existe el equipo, lo dejamos null
                .riotIdName("Lider-" + tag)
                .riotIdTag(region)
                .leaguePoints(24)
                .region(region)
                .tier(tierJugadores)
                .summonerLevel(400)
                .profileIconId(7)
                .build();
        leader = playerRepository.save(leader); // Guardamos para generar su ID

        double totalScore = getTierValue(tierJugadores); // Ya llevamos 1 jugador (el líder)

        // PASO 2: Crear el Equipo (Ahora SÍ tenemos líder)
        Team t = Team.builder()
                .name(nombre + " " + System.nanoTime())
                .tag(tag)
                .region(region)
                .division("III")
                .averageScore(0.0)
                .leader(leader) // <--- ¡AQUÍ ESTÁ LA CLAVE!
                .build();
        t = teamRepository.save(t); // Ahora la BD aceptará el equipo porque tiene LeaderId

        // PASO 3: Actualizar al Líder para ponerle su equipo
        leader.setTeam(t);
        playerRepository.save(leader);

        // PASO 4: Crear los otros 4 miembros
        for (int i = 2; i <= 5; i++) {

            User u = User.builder()
                    .email("u" + i + "_" + t.getTag() + "_" + System.nanoTime() + "@test.com")
                    .passwordHash("pass")
                    .role("ROLE_USER")
                    .build();
            userRepository.save(u);

            Player p = Player.builder()
                    .user(u)
                    .team(t) // Ellos sí nacen con equipo
                    .puuid("puuid-member-" + t.getId() + "-" + i + "-" +tag)
                    .riotIdName("Member" + i + "-" + tag)
                    .riotIdTag(region)
                    .leaguePoints(24)
                    .region(region)
                    .tier(tierJugadores)
                    .summonerLevel(400)
                    .profileIconId(7)
                    .build();
            playerRepository.save(p);

            totalScore += getTierValue(tierJugadores);
        }

        // PASO 5: Calcular División (Igual que antes)
        double average = totalScore / 5.0;
        t.setAverageScore(average);

        if (average <= 4.0) {
            t.setDivision("III");
        } else if (average <= 7.0) {
            t.setDivision("II");
        } else {
            t.setDivision("I");
        }

        return teamRepository.save(t);
    }

    // Copia exacta de tu lógica de valores en TeamService
    private int getTierValue(String tier) {
        switch (tier) {
            case "IRON":        return 1;
            case "BRONZE":      return 2;
            case "SILVER":      return 3;
            case "GOLD":        return 4;
            case "PLATINUM":    return 5;
            case "EMERALD":     return 6;
            case "DIAMOND":     return 7;
            case "MASTER":      return 8;
            case "GRANDMASTER": return 9;
            case "CHALLENGER":  return 10;
            default:            return 0;
        }
    }

    private void imprimirResultados(List<Match> matches) {
        for (Match m : matches) {
            if (m.getTeamB() == null) {
                System.out.println("✨ [BYE] " + m.getTeamA().getName() + " pasa directo.");
            } else {
                System.out.println("⚔️  [VS]  " +
                        m.getTeamA().getName() + " (Div " + m.getTeamA().getDivision() + ") vs " +
                        m.getTeamB().getName() + " (Div " + m.getTeamB().getDivision() + ")");
            }
        }
    }
}