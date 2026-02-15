package es.uca.legends.controllers;

import es.uca.legends.repositories.NotificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.stereotype.Controller;

@Controller
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationRepository notificationRepository;

    @MessageMapping("/read") // Flutter enviaría a "/app/read"
    public void markAsRead(Long notificationId) {
        notificationRepository.markAsRead(notificationId);
        System.out.println("Marcando notificación " + notificationId + " como leída");
    }
}
