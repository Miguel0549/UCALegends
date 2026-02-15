package es.uca.legends.repositories;
import es.uca.legends.entities.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification,Long> {

    @Modifying
    @Transactional
    @Query("UPDATE Notification SET isRead = true WHERE id = :Id")
    void markAsRead( @Param("Id")Long Id);

    void deleteAllByIsReadIsTrue();

    List<Notification> findByPlayerIdOrderByCreatedAtDesc(Long userId);
}
