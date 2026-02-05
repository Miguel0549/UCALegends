package es.uca.legends.repositories;
import es.uca.legends.entities.Player;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface PlayerRepository extends JpaRepository<Player, Long> {

    Optional<Player> findByPuuid(String puuid);

    Optional<Player> findByRiotIdNameAndRiotIdTag(String riotIdName, String riotIdTag);

    List<Player> findByRegion(String region);

    Long countByTeamId(Long teamId);
}
