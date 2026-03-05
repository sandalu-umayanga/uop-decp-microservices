package com.decp.notification.dto;

import com.decp.notification.model.NotificationType;
import com.decp.notification.model.ReferenceType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationResponse {
    private String id;
    private String userId;
    private NotificationType type;
    private String title;
    private String message;
    private String referenceId;
    private ReferenceType referenceType;
    private boolean read;
    private LocalDateTime createdAt;
}
