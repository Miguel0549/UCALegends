package es.uca.legends.entities;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "TeamRequests")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TeamJoinRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name="ID")
    private Long id;

    @ManyToOne
    @JoinColumn(name = "PlayerId", nullable = false)
    private Player player;

    @ManyToOne
    @JoinColumn(name = "TeamId", nullable = false)
    private Team team;

    @Column(name = "RequestDate")
    private LocalDateTime requestDate;
}