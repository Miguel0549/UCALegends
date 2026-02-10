package es.uca.legends.repositories;

import es.uca.legends.entities.Team;
import es.uca.legends.entities.TournamentRegistration;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface TournamentRegistrationRepository extends JpaRepository<TournamentRegistration,Long> {

    boolean existsByTournamentIdAndTeamId(Long tournamentId, Long teamId);

    Long countByTournamentId(Long tournamentId);

    Optional<TournamentRegistration> findByTournamentIdAndTeamId(Long tournamentId, Long teamId);

    @Query("SELECT r.team FROM TournamentRegistration r WHERE r.tournament.id = :tournamentId")
    List<Team> findTeamsByTournamentId(@Param("tournamentId") Long tournamentId);

    @Query("SELECT r.hasReceivedBye FROM TournamentRegistration r " +
            "WHERE r.tournament.id = :tId AND r.team.id = :teamId")
    boolean hasReceivedBye(@Param("tId") Long tournamentId, @Param("teamId") Long teamId);


}
