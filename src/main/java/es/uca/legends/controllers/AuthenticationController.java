package es.uca.legends.controllers;
import es.uca.legends.dtos.AuthenticationRequest;
import es.uca.legends.dtos.AuthenticationResponse;
import es.uca.legends.dtos.RefreshTokenRequest;
import es.uca.legends.entities.User;
import es.uca.legends.repositories.UserRepository;
import es.uca.legends.services.AuthenticationService;
import es.uca.legends.services.JwtService;
import io.jsonwebtoken.ExpiredJwtException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthenticationController {

    private final AuthenticationService service;
    private final JwtService jwtService;
    private final UserRepository userRepository;

    @PostMapping("/register")
    public ResponseEntity<AuthenticationResponse> register(
            @RequestBody AuthenticationRequest request
    ) {
        return ResponseEntity.ok(service.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthenticationResponse> authenticate(
            @RequestBody AuthenticationRequest request
    ) {
        return ResponseEntity.ok(service.authenticate(request));
    }

    @GetMapping("/verify")
    public ResponseEntity<Void> verify(@RequestHeader("Authorization") String authHeader) throws ExpiredJwtException {

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return ResponseEntity.status(403).build();
        }

        String token = authHeader.substring(7);

        try {
            String email = jwtService.extraerEmail(token);
            Optional<User> user = userRepository.findByEmail(email);

            if (user.isEmpty() || !jwtService.isTokenValid(token, user.get())) {
                return ResponseEntity.status(403).build();
            }

            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.status(403).build();
        }
    }

    @PostMapping("/refresh-token")
    public ResponseEntity<AuthenticationResponse> refreshToken(
            @RequestBody RefreshTokenRequest request
    ){
        return ResponseEntity.ok(service.refresh(request.getRefreshToken()));
    }

}
