package es.uca.legends.entities;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;
import java.util.List;

@Entity
@Table(name = "Teams")
@Getter
@Setter
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Team {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    @EqualsAndHashCode.Include
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
    @JsonIgnoreProperties({"team", "user"})
    @ToString.Exclude
    private Player leader;

    @OneToMany(mappedBy = "team", fetch = FetchType.EAGER)
    @JsonIgnoreProperties({"team", "user"}) // <--- Asegúrate de ignorar "user" aquí también
    @ToString.Exclude
    private List<Player> members;

}
