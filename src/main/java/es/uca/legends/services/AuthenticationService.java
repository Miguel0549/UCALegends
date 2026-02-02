package es.uca.legends.services;
import es.uca.legends.entities.User;
import es.uca.legends.repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthenticationService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public User register(String email, String rawPassword) {

        if (userRepository.findByEmail(email).isPresent()) {
            throw new RuntimeException("El email " + email + " ya está en uso.");
        }

        User newUser = User.builder()
                .email(email)
                .passwordHash(passwordEncoder.encode(rawPassword))
                .role("USER")
                .build();

        return userRepository.save(newUser);
    }
}
