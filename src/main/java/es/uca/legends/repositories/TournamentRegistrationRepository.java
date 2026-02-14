package es.uca.legends.repositories;

import es.uca.legends.entities.Team;
import es.uca.legends.entities.Tournament;
import es.uca.legends.entities.TournamentRegistration;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

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

    @Modifying
    @Transactional
    @Query("UPDATE TournamentRegistration t SET t.hasFinishedTournament = true WHERE t.tournament = :tournament AND t.team = :team")
    void setTeamOutOfTournament(Tournament tournament, Team team);

    @Query("SELECT CASE WHEN COUNT(t) > 0 THEN true ELSE false END " +
            "FROM TournamentRegistration t " +
            "WHERE t.team = :team " +
            "AND t.tournament.status = 'EN_CURSO' " +
            "AND t.hasFinishedTournament = false")
    boolean isTeamPlayingActiveTournament(@Param("team") Team team);

    @Query("SELECT t FROM TournamentRegistration t " +
            "WHERE t.team = :team " +
            "AND t.tournament.status IN ('ABIERTO', 'CERRADO')")
    List<TournamentRegistration> findPendingRegistrationsByTeam(@Param("team") Team team);

}
