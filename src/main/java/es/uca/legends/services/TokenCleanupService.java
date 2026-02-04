package es.uca.legends.services;
import es.uca.legends.repositories.TokenRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class TokenCleanupService {

    private final TokenRepository tokenRepository;

    @Scheduled(fixedRate = 1200000)
    public void removeExpiredTokens() {
        tokenRepository.deleteAllExpiredOrRevokedTokens();
        System.out.println("Limpieza de tokens finalizada."); // Log para que lo veas en consola
    }
}
