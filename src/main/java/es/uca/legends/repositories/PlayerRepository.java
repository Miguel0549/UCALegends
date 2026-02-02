package es.uca.legends.repositories;
import es.uca.legends.entities.Player;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface PlayerRepository extends JpaRepository<Player, Long> {

    Optional<Player> findByPuuid(String puuid);

    Optional<Player> findByRiotIdNameAndRiotIdTag(String riotIdName, String riotIdTag);

    List<Player> findByRegion(String region);
}
