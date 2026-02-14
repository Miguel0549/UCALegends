package es.uca.legends.services;
import es.uca.legends.entities.Tournament;
import es.uca.legends.repositories.TournamentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class TournamentUpdateFunctions {

    private final TournamentScheduler tournamentScheduler;
    private final TournamentRepository tournamentRepository;

    @Transactional
    public Tournament createTournament(Tournament tournament) {
        if (tournament.getStatus() == null) {
            tournament.setStatus("ABIERTO");
        }
        // Aquí podrías validar que FechaInicio sea posterior a FechaInscripciones
        if (tournament.getFechaInicio() != null && tournament.getFechaInscripciones() != null) {
            if (tournament.getFechaInicio().isBefore(tournament.getFechaInscripciones())) {
                throw new RuntimeException("La fecha de inicio no puede ser anterior al cierre de inscripciones.");
            }
        }

        Tournament savedTournament = tournamentRepository.save(tournament);

        tournamentScheduler.scheduleTournamentEvents(savedTournament);

        return savedTournament;
    }

    @Transactional
    public void updateTournamentStatus(Long tournamentId, String newStatus) {
        Tournament tournament = tournamentRepository.findById(tournamentId)
                .orElseThrow(() -> new RuntimeException("Torneo no encontrado"));

        String currentStatus = tournament.getStatus();

        if ("EN_CURSO".equals(newStatus) && !"CERRADO".equals(currentStatus)) {
            throw new RuntimeException("Debes cerrar las inscripciones antes de iniciar el torneo.");
        }

        if ("FINALIZADO".equals(newStatus) && !"EN_CURSO".equals(currentStatus)) {
            throw new RuntimeException("El torneo debe estar en curso para poder finalizarlo.");
        }

        tournament.setStatus(newStatus);
        Tournament t = tournamentRepository.save(tournament);
        tournamentScheduler.scheduleTournamentEvents(t);
    }
}
