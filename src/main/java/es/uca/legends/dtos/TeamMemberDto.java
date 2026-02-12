package es.uca.legends.dtos;

import lombok.Data;

@Data
public class TeamMemberDto {
    private Long id;
    private String riotIdName;
    private String riotIdTag; // El #EUW, #KR1, etc.
    private String tier;      // GOLD, DIAMOND...
    private String division;      // I, II, III, IV
    private boolean isLeader; // Para ponerle una coronita 👑
}