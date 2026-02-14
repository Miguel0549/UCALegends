package es.uca.legends.services;
import es.uca.legends.entities.Tournament;
import es.uca.legends.repositories.TournamentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.TaskScheduler;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;

@Service
@RequiredArgsConstructor
public class TournamentScheduler {

    private final TournamentRepository tournamentRepository;
    private final TournamentService tournamentService;
    private final TaskScheduler taskScheduler;


    @EventListener(ApplicationReadyEvent.class)
    public void reloadSchedulesOnStartup() {
        System.out.println("Recuperando alarmas de torneos tras el arranque...");

        List<Tournament> pendingTournaments = tournamentRepository.findAllByStatusIn(List.of("ABIERTO", "CERRADO"));

        for (Tournament t : pendingTournaments) {
            scheduleTournamentEvents(t);
        }
    }


    public void scheduleTournamentEvents(Tournament tournament) {

        // 1. Programar el cierre de inscripciones
        if (tournament.getFechaInscripciones() != null && "ABIERTO".equals(tournament.getStatus())) {
            Instant closeInstant = tournament.getFechaInscripciones()
                    .atZone(ZoneId.systemDefault())
                    .toInstant();

            // Le pasamos el Instant directamente al scheduler
            taskScheduler.schedule(() -> tournamentService.closeInscriptionsNow(tournament.getId()), closeInstant);
        }

        // 2. Programar el inicio del torneo
        if (tournament.getFechaInicio() != null && ("ABIERTO".equals(tournament.getStatus()) || "CERRADO".equals(tournament.getStatus()))) {
            Instant beginInstant = tournament.getFechaInicio()
                    .atZone(ZoneId.systemDefault())
                    .toInstant();

            taskScheduler.schedule(() -> tournamentService.beginTournamentNow(tournament.getId()), beginInstant);
        }
    }

}
