package es.uca.legends.dtos;

import es.uca.legends.entities.Player;
import lombok.Data;
import java.util.List;

@Data
public class TeamResponseDto {
    private Long id;
    private String name;
    private String tag;
    private String region;
    private String division;
    private PlayerResponse leader;

    private List<TeamMemberDto> members;
}