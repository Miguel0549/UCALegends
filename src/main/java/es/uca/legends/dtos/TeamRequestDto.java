package es.uca.legends.dtos;
import es.uca.legends.entities.Player;
import lombok.Data;

@Data
public class TeamRequestDto {
    private Long requestId;
    private Player player;
}
