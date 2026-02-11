package es.uca.legends.dtos;
import es.uca.legends.entities.Team;
import lombok.Data;

@Data
public class PlayerResponse {

    private Long id;
    private String puuid;
    private String riotIdName;
    private String riotIdTag;
    private String region;
    private Integer summonerLevel;
    private String tier;
    private String division;
    private Integer leaguePoints;
    private Integer profileIconId;
    private TeamResponseDto team;
}
