package es.uca.legends.services;
import es.uca.legends.entities.Tournament;
import es.uca.legends.repositories.TournamentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class TournamentScheduler {

    private final TournamentRepository tournamentRepository;
    private final TournamentService tournamentService;

    // Se ejecuta cada 60000ms (1 minuto)
    @Scheduled(fixedRate = 60000)
    @Transactional
    public void closeExpiredInscriptions() {

        List<Tournament> toClose = tournamentRepository.findAllByStatusAndFechaInscripcionesBefore(
                "ABIERTO",
                LocalDateTime.now()
        );

        if (toClose.isEmpty()) return;

        for (Tournament t : toClose) {
            t.setStatus("CERRADO");
            System.out.println("Cerrando inscripciones automáticamente para el torneo: " + t.getName());
        }

        tournamentRepository.saveAll(toClose);
    }

    @Scheduled(fixedRate = 60000)
    @Transactional
    public void beginTournament() {

        List<Tournament> toBegin = tournamentRepository.findAllByStatusAndFechaInicioBefore(
                "CERRADO",
                LocalDateTime.now()
        );

        if (toBegin.isEmpty()) return;

        for (Tournament t : toBegin) {
            try {
                System.out.println("Iniciando generación de cuadro para el torneo: " + t.getName());

                tournamentService.advanceToNextRound(t.getId());

                System.out.println("Torneo {} iniciado con éxito :" + t.getName());

            } catch (Exception e) {
                System.out.println("Error al iniciar el torneo " + t.getName() + ": " + e.getMessage());
                t.setStatus("CANCELADO");
                tournamentRepository.save(t);
            }
        }

        tournamentRepository.saveAll(toBegin);
    }
}
