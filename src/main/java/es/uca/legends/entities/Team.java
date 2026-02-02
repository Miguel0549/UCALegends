package es.uca.legends.entities;
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

    @OneToOne
    @JoinColumn(name = "LeaderId")
    private Player leader;

    @OneToMany(mappedBy = "team", fetch = FetchType.LAZY)
    @ToString.Exclude
    private List<Player> members;

}
