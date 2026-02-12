package es.uca.legends.entities;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;
import org.apache.commons.lang3.builder.HashCodeExclude;


@Entity
@Table(name="Players")
@Getter
@Setter
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Player {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    @EqualsAndHashCode.Include
    private Long id;

    @Column(name = "PUUID", unique = true)
    private String puuid;

    @Column(name="RiotIdName")
    private String riotIdName;

    @Column(name="RiotIdTag")
    private String riotIdTag;

    @Column(name="Region")
    private String region;

    @Column(name="SummonerLevel")
    private Integer summonerLevel;

    @Column(name="Tier")
    private String tier;

    @Column(name = "Division")
    private String division;

    @Column(name = "LeaguePoints")
    private Integer leaguePoints;

    @Column(name = "ProfileIconId")
    private Integer profileIconId;

    @OneToOne
    @JoinColumn(name = "UserId", nullable = false)
    @ToString.Exclude
    private User user;

    @ManyToOne
    @JoinColumn(name = "TeamId")
    @JsonIgnoreProperties({"members", "leader"})
    @ToString.Exclude
    private Team team;

}
