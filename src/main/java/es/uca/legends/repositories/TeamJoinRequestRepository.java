package es.uca.legends.repositories;
import es.uca.legends.entities.TeamJoinRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface TeamJoinRequestRepository extends JpaRepository<TeamJoinRequest, Long> {
    List<TeamJoinRequest> findByTeamId(Long teamId);
    boolean existsByPlayerIdAndTeamId(Long playerId, Long teamId);
}