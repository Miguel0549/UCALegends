package es.uca.legends.repositories;

import es.uca.legends.entities.TournamentRegistration;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface TournamentRegistrationRepository extends JpaRepository<TournamentRegistration,Long> {

    boolean existsByTournamentIdAndTeamId(Long tournamentId, Long teamId);
    Long countByTournamentId(Long tournamentId);
    Optional<TournamentRegistration> findByTournamentIdAndTeamId(Long tournamentId, Long teamId);
}
