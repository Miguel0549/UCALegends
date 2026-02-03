package es.uca.legends.services;
import es.uca.legends.dtos.AuthenticationRequest;
import es.uca.legends.dtos.AuthenticationResponse;
import es.uca.legends.entities.Token;
import es.uca.legends.entities.User;
import es.uca.legends.repositories.TokenRepository;
import es.uca.legends.repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Date;

@Service
@RequiredArgsConstructor
public class AuthenticationService {

    private final UserRepository repository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    private final TokenRepository tokenRepository;

    @Transactional
    public AuthenticationResponse register(AuthenticationRequest request) {

        var user = User.builder()
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .role("ROLE_USER")
                .build();


        repository.save(user);

        var jwtToken = jwtService.generateToken(user);
        var refreshToken = jwtService.generateRefreshToken(user);

        saveUserToken(user, jwtToken);
        saveRefreshToken(user, refreshToken);

        return AuthenticationResponse.builder()
                .accessToken(jwtToken)
                .refreshToken(refreshToken)
                .build();
    }

    public AuthenticationResponse authenticate(AuthenticationRequest request) {

        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getEmail(),
                        request.getPassword()
                )
        );

        var user = repository.findByEmail(request.getEmail())
                .orElseThrow();

        var jwtToken = jwtService.generateToken(user);
        var refreshToken = jwtService.generateRefreshToken(user);

        revokeAllUserTokens(user);
        saveUserToken(user, jwtToken);
        saveRefreshToken(user, refreshToken);

        return AuthenticationResponse.builder()
                .accessToken(jwtToken)
                .refreshToken(refreshToken)
                .build();
    }

    private void saveUserToken(User user, String jwtToken) {

        Date expirationDate = jwtService.extraerExpiracion(jwtToken);

        LocalDateTime expiracionLocal = expirationDate.toInstant().atZone(ZoneId.systemDefault()).toLocalDateTime();

        var token = Token.builder()
                .user(user)
                .jwtToken(jwtToken)
                .tipo(Token.TokenType.BEARER)
                .expirado(false)
                .revocado(false)
                .fechaExpiracion(expiracionLocal)
                .build();
        tokenRepository.save(token);
    }

    private void saveRefreshToken(User user, String jwtToken) {

        Date expirationDate = jwtService.extraerExpiracion(jwtToken);

        LocalDateTime expiracionLocal = expirationDate.toInstant().atZone(ZoneId.systemDefault()).toLocalDateTime();

        var token = Token.builder()
                .user(user)
                .jwtToken(jwtToken)
                .tipo(Token.TokenType.REFRESH)
                .expirado(false)
                .revocado(false)
                .fechaExpiracion(expiracionLocal)
                .build();
        tokenRepository.save(token);
    }

    private void revokeAllUserTokens(User user) {
        var validUserTokens = tokenRepository.findAllValidTokenByUser(user.getId());
        if (validUserTokens.isEmpty())
            return;

        validUserTokens.forEach(token -> {
            token.setExpirado(true);
            token.setRevocado(true);
        });
        tokenRepository.saveAll(validUserTokens);
    }
}
