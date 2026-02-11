package es.uca.legends.dtos;

import lombok.Data;
import java.util.List;

@Data
public class TeamResponseDto {
    private Long id;
    private String name;
    private String tag;
    private String region;
    private String division;
    private String leaderName;
    private int memberCount;

    private List<TeamMemberDto> members;
}