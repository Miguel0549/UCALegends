package es.uca.legends.entities;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "Matches")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Match {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @ManyToOne
    @JoinColumn(name = "TournamentId")
    private Tournament tournament;

    @ManyToOne
    @JoinColumn(name = "TeamAId")
    private Team teamA;

    @ManyToOne
    @JoinColumn(name = "TeamBId")
    private Team teamB;

    @ManyToOne
    @JoinColumn(name = "WinnerID")
    private Team winner;

    @Column(name = "RiotMatchId",unique = true)
    private String riotMatchId;

    @Column(name = "Round")
    private Integer round;

    @Column(name = "DurationSec")
    private Integer durationSec;

    @Column(name = "MatchDate")
    private LocalDateTime matchDate;

    @Column(name = "Status")
    private String status;

}
