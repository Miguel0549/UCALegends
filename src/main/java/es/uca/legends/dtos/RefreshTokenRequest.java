package es.uca.legends.dtos;
import lombok.Data;

@Data
public class RefreshTokenRequest {
    private String refreshToken;
}