package es.uca.legends.repositories;
import es.uca.legends.entities.Tournament;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface TournamentRepository extends JpaRepository<Tournament,Long> {

    List<Tournament> findByRegion(String region);

    List<Tournament> findByGameMode(String gameMode);

    List<Tournament> findAllByStatusAndFechaInscripcionesBefore(String status, LocalDateTime now);
    List<Tournament> findAllByStatusAndFechaInicioBefore(String status, LocalDateTime now);

    List<Tournament> findByStatusAndRegion(String status, String region);
    List<Tournament> findByStatus(String status);

    List<Tournament> findAllByStatusIn(List<String> status);
}
