package es.uca.legends.services;
import es.uca.legends.entities.User;
import es.uca.legends.repositories.TokenRepository;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.NonNull;
import org.jspecify.annotations.Nullable;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.logout.LogoutHandler;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class LogoutService implements LogoutHandler {

    private final TokenRepository tokenRepository;

    @Override
    public void logout(@NonNull HttpServletRequest request, @NonNull HttpServletResponse response, @Nullable Authentication authentication) {

        final String authHeader = request.getHeader("Authorization");
        final String jwt;

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return;
        }

        jwt = authHeader.substring(7);
        var storedToken = tokenRepository.findByJwtToken(jwt).orElse(null);

        if (storedToken != null) {

            var user = storedToken.getUser();
            revokeAllUserTokens(user);
            SecurityContextHolder.clearContext();
        }
    }

    private void revokeAllUserTokens(User user) {
        var validUserTokens = tokenRepository.findAllValidTokenByUser(user.getId());
        if (validUserTokens.isEmpty())
            return;

        validUserTokens.forEach(token -> {
            token.setRevocado(true);
        });
        tokenRepository.saveAll(validUserTokens);
    }
}

