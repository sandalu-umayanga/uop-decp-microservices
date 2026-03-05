package com.decp.notification.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

@Document(collection = "notifications")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Notification {

    @Id
    private String id;

    @Indexed
    private String userId;

    private NotificationType type;

    private String title;

    private String message;

    private String referenceId;

    private ReferenceType referenceType;

    @Builder.Default
    private boolean read = false;

    private LocalDateTime createdAt;

    @Indexed(expireAfter = "0s")
    private LocalDateTime expiresAt;
}
