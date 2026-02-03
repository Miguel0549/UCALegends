package es.uca.legends.repositories;
import es.uca.legends.entities.Tournament;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface TournamentRepository extends JpaRepository<Tournament,Long> {

    List<Tournament> findByRegion(String region);

    List<Tournament> findByGameMode(String gameMode);

}
