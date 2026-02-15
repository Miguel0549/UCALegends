package es.uca.legends.services;

import es.uca.legends.repositories.NotificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class NotificationCleanupService {

    private final NotificationRepository notificationRepository;

    @Scheduled(cron = "0 0 * * * *",zone = "Europe/Madrid")
    public void removeExpiredTokens() {
        notificationRepository.deleteAllByIsReadIsTrue();
    }
}
