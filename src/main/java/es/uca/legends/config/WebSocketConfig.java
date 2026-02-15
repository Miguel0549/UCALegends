package es.uca.legends.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // Este es el enchufe donde se conectará tu Frontend (React/JS)
        // Ejemplo de conexión en JS: new SockJS('http://localhost:8080/ws-chat');
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*") // Permite conexiones desde cualquier lado (cuidado en producción)
                .withSockJS(); // Habilita compatibilidad
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        // Los mensajes que envíes a "/topic/..." irán a los clientes suscritos
        registry.enableSimpleBroker("/topic","/queue");
        // Prefijo para mensajes que van DEL cliente AL servidor (aunque tú usas POST, está bien tenerlo)
        registry.setApplicationDestinationPrefixes("/app");
    }
}
