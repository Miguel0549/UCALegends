package es.uca.legends.dtos;
import es.uca.legends.entities.Player;
import lombok.Data;


@Data
public class UserResponse {

    private Long id;
    private String email;
    private String passwordHash;
    private String role;
    private Player player;

}
