package es.uca.legends.dtos;
import lombok.Data;

@Data
public class DevPLayerLinkRequest {
    private String gameName;
    private String tagLine;
    private Integer summonerLevel;
    private String tier;
    private String division;
    private Integer leaguePoints;
    private Integer iconId;
}
