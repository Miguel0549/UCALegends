package es.uca.legends.repositories;
import es.uca.legends.entities.Token;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
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

    Optional<Token> findByJwtToken(String token);
}
