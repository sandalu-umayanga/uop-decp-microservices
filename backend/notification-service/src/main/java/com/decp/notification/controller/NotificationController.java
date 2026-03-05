package com.decp.notification.controller;

import com.decp.notification.dto.NotificationResponse;
import com.decp.notification.dto.UnreadCountResponse;
import com.decp.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping
    public ResponseEntity<List<NotificationResponse>> getUserNotifications(
            @RequestHeader("X-User-Name") String userName) {
        return ResponseEntity.ok(notificationService.getUserNotifications(userName));
    }

    @PutMapping("/{id}/read")
    public ResponseEntity<NotificationResponse> markAsRead(
            @PathVariable String id,
            @RequestHeader("X-User-Name") String userName) {
        return ResponseEntity.ok(notificationService.markAsRead(id, userName));
    }

    @PutMapping("/read-all")
    public ResponseEntity<Void> markAllAsRead(
            @RequestHeader("X-User-Name") String userName) {
        notificationService.markAllAsRead(userName);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/unread-count")
    public ResponseEntity<UnreadCountResponse> getUnreadCount(
            @RequestHeader("X-User-Name") String userName) {
        long count = notificationService.getUnreadCount(userName);
        return ResponseEntity.ok(new UnreadCountResponse(count));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteNotification(
            @PathVariable String id,
            @RequestHeader("X-User-Name") String userName) {
        notificationService.deleteNotification(id, userName);
        return ResponseEntity.noContent().build();
    }
}
