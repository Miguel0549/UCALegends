package es.uca.legends.controllers;

import es.uca.legends.entities.Notification;
import es.uca.legends.repositories.NotificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
@CrossOrigin(origins = "*") // Para evitar problemas de CORS si pruebas desde la web o emuladores
public class NotificationRestController {

    private final NotificationRepository notificationRepository;

    @GetMapping("/{playerId}")
    public ResponseEntity<List<Notification>> getUserNotifications(@PathVariable Long playerId) {
        // Buscamos las notificaciones en la base de datos
        List<Notification> notifications = notificationRepository.findByPlayerIdOrderByCreatedAtDesc(playerId);

        // Las devolvemos con un status 200 OK
        return ResponseEntity.ok(notifications);
    }
}