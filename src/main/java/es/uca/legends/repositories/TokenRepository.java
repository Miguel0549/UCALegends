package es.uca.legends.repositories;
import es.uca.legends.entities.Token;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface TokenRepository extends JpaRepository<Token,Long> {

    @Query(value = """
      select t from Token t inner join User u\s
      on t.user.id = u.id\s
      where u.id = :id and (t.expirado = false and t.revocado = false)\s
      """)
    List<Token> findAllValidTokenByUser(Long id);

    @Modifying
    @Transactional
    @Query("DELETE FROM Token t WHERE t.expirado = true OR t.revocado = true")
    void deleteAllExpiredOrRevokedTokens();

    @Modifying
    @Transactional
    @Query("UPDATE Token t SET t.expirado= true WHERE t.expirado = false AND t.fechaExpiracion <= :now")
    int markTokensAsExpired(@Param("now") LocalDateTime now);

    Optional<Token> findByJwtToken(String token);
}
