package es.uca.legends.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "Tokens")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Token {

    public enum TokenType {
        BEARER,
        REFRESH
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    public Long id;

    @Column(name = "JwTToken",nullable = false, columnDefinition = "TEXT")
    public String jwtToken;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    @Column(name = "Tipo")
    public TokenType tipo = TokenType.BEARER;

    @Column(name = "Revocado" )
    public boolean revocado;

    @Column(name = "Expirado")
    public boolean expirado;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "User_id")
    public User user;

    @Column(name = "FechaExpiracion")
    public LocalDateTime fechaExpiracion;

}


