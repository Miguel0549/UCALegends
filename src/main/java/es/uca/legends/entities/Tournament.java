package es.uca.legends.entities;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;


@Entity
@Table(name = "Tournaments")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Tournament {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @Column(name = "Name")
    private String name;

    @Column(name = "Status")
    private String status;

    @Column(name = "Region")
    private String region;

    @Column(name = "GameMode")
    private String gameMode;

    @Column(name = "MaxTeams")
    private Integer maxTeams;

    @Column(name = "CurrentRound")
    private Integer currentRound = 0;

    @Column(name="FechaInscripciones")
    private LocalDateTime fechaInscripciones;

    @Column(name = "FechaInicio")
    private LocalDateTime fechaInicio;

    @ManyToOne
    @JoinColumn(name = "WinnerId")
    private Team winner;

}
