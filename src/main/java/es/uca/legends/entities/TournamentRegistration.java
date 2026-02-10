package es.uca.legends.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "Tournament_Registrations")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TournamentRegistration {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "TournamentId", nullable = false)
    private Tournament tournament;

    @ManyToOne
    @JoinColumn(name = "TeamId", nullable = false)
    private Team team;

    @Column(name = "RegisteredAt")
    private LocalDateTime registeredAt;

    @Column(name = "HasReceivedBye")
    private Boolean hasReceivedBye;

}