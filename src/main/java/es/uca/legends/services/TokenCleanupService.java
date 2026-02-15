package es.uca.legends.services;
import es.uca.legends.repositories.TokenRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class TokenCleanupService {

    private final TokenRepository tokenRepository;

    @Scheduled(cron = "0 0 * * * *",zone = "Europe/Madrid")
    public void removeExpiredTokens() {
        tokenRepository.deleteAllExpiredOrRevokedTokens();
        System.out.println("Limpieza de tokens finalizada."); // Log para que lo veas en consola
    }


}
