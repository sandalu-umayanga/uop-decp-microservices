package com.decp.notification.service;

import com.decp.notification.dto.NotificationResponse;
import com.decp.notification.model.Notification;
import com.decp.notification.model.NotificationType;
import com.decp.notification.model.ReferenceType;
import com.decp.notification.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final StringRedisTemplate redisTemplate;

    private static final String UNREAD_COUNT_KEY_PREFIX = "notifications:unread:";

    public Notification createNotification(String userId, NotificationType type, String title,
                                           String message, String referenceId, ReferenceType referenceType) {
        Notification notification = Notification.builder()
                .userId(userId)
                .type(type)
                .title(title)
                .message(message)
                .referenceId(referenceId)
                .referenceType(referenceType)
                .read(false)
                .createdAt(LocalDateTime.now())
                .expiresAt(LocalDateTime.now().plusDays(30))
                .build();

        Notification saved = notificationRepository.save(notification);
        incrementUnreadCount(userId);
        return saved;
    }

    public List<NotificationResponse> getUserNotifications(String userName) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userName)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public NotificationResponse markAsRead(String id, String userName) {
        Notification notification = notificationRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Notification not found with id: " + id));

        if (!userName.equals(notification.getUserId())) {
            throw new RuntimeException("Not authorized to modify this notification");
        }

        if (!notification.isRead()) {
            notification.setRead(true);
            notificationRepository.save(notification);
            decrementUnreadCount(userName);
        }

        return toResponse(notification);
    }

    public void markAllAsRead(String userName) {
        List<Notification> unread = notificationRepository.findByUserIdAndReadFalse(userName);
        unread.forEach(n -> n.setRead(true));
        notificationRepository.saveAll(unread);
        resetUnreadCount(userName);
    }

    public long getUnreadCount(String userName) {
        String cached = redisTemplate.opsForValue().get(UNREAD_COUNT_KEY_PREFIX + userName);
        if (cached != null) {
            return Long.parseLong(cached);
        }
        long count = notificationRepository.countByUserIdAndReadFalse(userName);
        redisTemplate.opsForValue().set(UNREAD_COUNT_KEY_PREFIX + userName, String.valueOf(count));
        return count;
    }

    public void deleteNotification(String id, String userName) {
        Notification notification = notificationRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Notification not found with id: " + id));

        if (!userName.equals(notification.getUserId())) {
            throw new RuntimeException("Not authorized to delete this notification");
        }

        if (!notification.isRead()) {
            decrementUnreadCount(userName);
        }

        notificationRepository.delete(notification);
    }

    private void incrementUnreadCount(String userId) {
        redisTemplate.opsForValue().increment(UNREAD_COUNT_KEY_PREFIX + userId);
    }

    private void decrementUnreadCount(String userId) {
        String key = UNREAD_COUNT_KEY_PREFIX + userId;
        String current = redisTemplate.opsForValue().get(key);
        if (current != null && Long.parseLong(current) > 0) {
            redisTemplate.opsForValue().decrement(key);
        }
    }

    private void resetUnreadCount(String userId) {
        redisTemplate.opsForValue().set(UNREAD_COUNT_KEY_PREFIX + userId, "0");
    }

    private NotificationResponse toResponse(Notification notification) {
        return NotificationResponse.builder()
                .id(notification.getId())
                .userId(notification.getUserId())
                .type(notification.getType())
                .title(notification.getTitle())
                .message(notification.getMessage())
                .referenceId(notification.getReferenceId())
                .referenceType(notification.getReferenceType())
                .read(notification.isRead())
                .createdAt(notification.getCreatedAt())
                .build();
    }
}
