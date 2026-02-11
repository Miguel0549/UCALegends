package es.uca.legends.entities;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;
import java.util.List;

@Entity
@Table(name = "Teams")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Team {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @Column(name = "Name",unique = true)
    private String name;

    @Column(name = "Tag")
    private String tag;

    @Column(name = "Region")
    private String region;

    @Column(name = "AverageScore")
    private Double averageScore;

    @Column(name = "Division")
    private String division; // Valores posibles: "I", "II", "III"

    @OneToOne
    @JoinColumn(name = "LeaderId")
    @JsonIgnoreProperties("team")
    private Player leader;

    @OneToMany(mappedBy = "team", fetch = FetchType.EAGER)
    @ToString.Exclude
    private List<Player> members;

}
