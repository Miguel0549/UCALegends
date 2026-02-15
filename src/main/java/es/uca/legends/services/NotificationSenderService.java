package es.uca.legends.services;

import es.uca.legends.entities.*;
import es.uca.legends.repositories.NotificationRepository;
import es.uca.legends.repositories.TeamRepository;
import es.uca.legends.repositories.TournamentRegistrationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class NotificationSenderService {

    private final SimpMessagingTemplate messagingTemplate;
    private final NotificationRepository notificationRepository;
    private final TeamRepository teamRepository;
    private final TournamentRegistrationRepository tournamentRegistrationRepository;

    public void notifyTeam(Long teamId, String title, String message) {

        Team team = teamRepository.findById(teamId).orElse(new Team());
        List<Player> members = team.getMembers();

        if (members != null && !members.isEmpty()){
            // 2. Repartes la notificación a cada uno
            for (Player player : members) {
                sendPersonalNotification(player.getId(), title, message);
            }
            System.out.println("Notificaciones guardadas y enviadas a los miembros del equipo " + teamId);
        }

    }

    /**
     * Envía una notificación a todos los inscritos en un torneo.
     */
    public void notifyTournament(Long tournamentId, String title, String message) {

        List<Team> teams = tournamentRegistrationRepository.findTeamsByTournamentId(tournamentId);

        for ( Team t : teams){
            for ( Player p : t.getMembers()){
                sendPersonalNotification(p.getId(), title, message);
            }
        }

        System.out.println("Notificaciones guardadas y enviadas al torneo " + tournamentId);
    }

    /**
     * Método auxiliar privado que hace la magia de guardar en DB y enviar por STOMP.
     */
    private void sendPersonalNotification(Long playerId, String title, String message) {
        // A) Guardar en la base de datos MySQL
        Notification notification = new Notification();
        notification.setPlayerId(playerId);
        notification.setTitle(title);
        notification.setMessage(message);
        notification.setIsRead(false);

        Notification savedNotification = notificationRepository.save(notification);

        // B) Enviar por WebSocket al canal personal del usuario
        // El destino coincide exactamente con lo que Flutter está escuchando
        String destination = "/topic/notifications/" + playerId;

        // Spring Boot convierte automáticamente el objeto 'savedNotification' a JSON
        messagingTemplate.convertAndSend(destination, savedNotification);
    }
}
