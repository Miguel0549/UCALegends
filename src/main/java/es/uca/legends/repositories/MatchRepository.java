package es.uca.legends.repositories;
import es.uca.legends.entities.Match;
import es.uca.legends.entities.Tournament;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MatchRepository extends JpaRepository<Match,Long> {

    Optional<Match> findByRiotMatchId(String riotMatchId);

    List<Match> findByTournamentAndRound(Tournament tournament, int round);

    Boolean existsByTournamentAndRoundAndStatusNot(Tournament tournament, int round, String status);
    List<Match> findByTournamentAndRound(Tournament t , Integer r);

    List<Match> findByTournamentIdOrderByRoundAsc(Long tournamentId);

    boolean existsByTournamentAndRoundAndStatusNot(Tournament tournament, Integer round, String status);

}
