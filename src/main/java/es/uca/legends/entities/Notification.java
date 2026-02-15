package es.uca.legends.entities;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name="Notifications")
@Getter
@Setter
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    @EqualsAndHashCode.Include
    private Long id;

    @Column(name = "PlayerId")
    private Long playerId;

    @Column(name = "Title", length = 100, nullable = false)
    private String title;

    @Column(name = "Message", columnDefinition = "TEXT", nullable = false)
    private String message;

    @Column(name = "Isread")
    @Builder.Default
    private Boolean isRead = false; // Por defecto a false en Java también

    // Hibernate se encarga de rellenar esto automáticamente cuando se hace el INSERT
    @CreationTimestamp
    @Column(name = "CreatedAt", updatable = false)
    private LocalDateTime createdAt;


}
