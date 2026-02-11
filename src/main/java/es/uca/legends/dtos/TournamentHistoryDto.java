package es.uca.legends.dtos;
import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class TournamentHistoryDto {
    private String tournamentName;
    private LocalDateTime fechaInicio;
    private String region;
    private String winnerName;
}