package es.uca.legends.services;
import es.uca.legends.entities.User;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import javax.crypto.SecretKey;
import java.util.Date;
import java.util.List;

@Service
public class JwtService {

    @Value("${application.security.jwt.secret-key}")
    private String secretKey;

    @Value("${application.security.jwt.expiration}")
    private long jwtExpiration;

    @Value("${application.security.jwt.refresh-token.expiration}")
    private long refreshExpiration;

    public String generateToken ( final User user )
    {
        return buildToken(user,jwtExpiration);
    }

    public String generateRefreshToken ( final User user )
    {
        return buildToken(user,refreshExpiration);
    }


    public String extraerEmail( final String token ){
        final Claims jwtToken = Jwts.parserBuilder()
                .setSigningKey(getSecretKey())
                .build()
                .parseClaimsJws(token)
                .getBody();
        return jwtToken.getSubject();
    }

    public Date extraerExpiracion(final String token ){
        final Claims jwtToken = Jwts.parserBuilder()
                .setSigningKey(getSecretKey())
                .build()
                .parseClaimsJws(token)
                .getBody();
        return jwtToken.getExpiration();
    }


    public boolean isTokenValid( final String token , final User user ) {
        final String email = extraerEmail(token);
        return (email.equals(user.getEmail())) && !isTokenExpired(token);
    }

    public boolean isTokenExpired( final String token ){
        return extraerExpiracion(token).before(new Date());
    }


    private String buildToken( final User user, final long expiration ){

        String rol = (user.getRole() != null) ? user.getRole() : "ROLE_USER";

        return Jwts.builder()
                .claim("Roles", List.of(rol))
                .setSubject(user.getEmail())
                .setIssuedAt(new Date(System.currentTimeMillis()))
                .setExpiration(new Date(System.currentTimeMillis()+expiration))
                .signWith(getSecretKey())
                .compact();
    }


    private SecretKey getSecretKey() {
        byte[] keyBytes = Decoders.BASE64.decode(secretKey);
        return Keys.hmacShaKeyFor(keyBytes);
    }
}
