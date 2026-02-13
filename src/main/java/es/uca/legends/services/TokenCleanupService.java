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

    @Scheduled(fixedRate = 10000/*1200000*/)
    public void removeExpiredTokens() {
        tokenRepository.deleteAllExpiredOrRevokedTokens();
        System.out.println("Limpieza de tokens finalizada."); // Log para que lo veas en consola
    }

    //@Scheduled(cron = "0 0 * * * *")
    @Scheduled(fixedRate = 10000)
    public void cleanExpiredTokens() {
        System.out.println("Iniciando tarea de limpieza de tokens caducados...");

        int updatedTokens = tokenRepository.markTokensAsExpired(LocalDateTime.now());

        System.out.println("Limpieza finalizada. Tokens expirados marcados: " + updatedTokens);
    }
}
