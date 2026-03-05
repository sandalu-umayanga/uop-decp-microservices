package com.decp.notification.listener;

import com.decp.notification.config.RabbitMQConfig;
import com.decp.notification.model.NotificationType;
import com.decp.notification.model.ReferenceType;
import com.decp.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
@RequiredArgsConstructor
@Slf4j
public class NotificationListener {

    private final NotificationService notificationService;

    @RabbitListener(queues = RabbitMQConfig.USER_REGISTERED_QUEUE)
    public void handleUserRegistered(Object message) {
        try {
            String userId = extractString(message);
            log.info("Received user.registered event for userId: {}", userId);
            notificationService.createNotification(
                    userId,
                    NotificationType.USER_REGISTERED,
                    "Welcome to DECP!",
                    "Welcome to the Department Engagement & Career Platform. Start by completing your profile.",
                    userId,
                    ReferenceType.USER
            );
        } catch (Exception e) {
            log.error("Error processing user.registered event: {}", e.getMessage(), e);
        }
    }

    @RabbitListener(queues = RabbitMQConfig.POST_CREATED_QUEUE)
    public void handlePostCreated(Object message) {
        try {
            String postId = extractString(message);
            log.info("Received post.created event for postId: {}", postId);
            // Post service sends just the post ID; broadcast notification handled at service level
            notificationService.createNotification(
                    "all",
                    NotificationType.NEW_POST,
                    "New Post",
                    "A new post has been shared on the platform.",
                    postId,
                    ReferenceType.POST
            );
        } catch (Exception e) {
            log.error("Error processing post.created event: {}", e.getMessage(), e);
        }
    }

    @RabbitListener(queues = RabbitMQConfig.POST_LIKED_QUEUE)
    public void handlePostLiked(Map<String, Object> message) {
        try {
            log.info("Received post.liked event: {}", message);
            String postOwnerId = getString(message, "postOwnerId");
            String userName = getString(message, "userName");
            String postId = getString(message, "postId");

            if (postOwnerId != null) {
                notificationService.createNotification(
                        postOwnerId,
                        NotificationType.POST_LIKED,
                        "Post Liked",
                        userName + " liked your post.",
                        postId,
                        ReferenceType.POST
                );
            }
        } catch (Exception e) {
            log.error("Error processing post.liked event: {}", e.getMessage(), e);
        }
    }

    @RabbitListener(queues = RabbitMQConfig.POST_COMMENTED_QUEUE)
    public void handlePostCommented(Map<String, Object> message) {
        try {
            log.info("Received post.commented event: {}", message);
            String postOwnerId = getString(message, "postOwnerId");
            String userName = getString(message, "userName");
            String postId = getString(message, "postId");

            if (postOwnerId != null) {
                notificationService.createNotification(
                        postOwnerId,
                        NotificationType.POST_COMMENTED,
                        "New Comment",
                        userName + " commented on your post.",
                        postId,
                        ReferenceType.POST
                );
            }
        } catch (Exception e) {
            log.error("Error processing post.commented event: {}", e.getMessage(), e);
        }
    }

    @RabbitListener(queues = RabbitMQConfig.JOB_CREATED_QUEUE)
    public void handleJobCreated(Map<String, Object> message) {
        try {
            log.info("Received job.created event: {}", message);
            String title = getString(message, "title");
            String jobId = getString(message, "jobId");

            notificationService.createNotification(
                    "all",
                    NotificationType.JOB_CREATED,
                    "New Job Opportunity",
                    "New job opportunity: " + title,
                    jobId,
                    ReferenceType.JOB
            );
        } catch (Exception e) {
            log.error("Error processing job.created event: {}", e.getMessage(), e);
        }
    }

    @RabbitListener(queues = RabbitMQConfig.JOB_APPLIED_QUEUE)
    public void handleJobApplied(Map<String, Object> message) {
        try {
            log.info("Received job.applied event: {}", message);
            String employerId = getString(message, "employerId");
            String userName = getString(message, "userName");
            String jobId = getString(message, "jobId");
            String jobTitle = getString(message, "jobTitle");

            if (employerId != null) {
                notificationService.createNotification(
                        employerId,
                        NotificationType.JOB_APPLICATION,
                        "New Application",
                        userName + " applied to your job: " + jobTitle,
                        jobId,
                        ReferenceType.JOB
                );
            }
        } catch (Exception e) {
            log.error("Error processing job.applied event: {}", e.getMessage(), e);
        }
    }

    @RabbitListener(queues = RabbitMQConfig.EVENT_CREATED_QUEUE)
    public void handleEventCreated(Map<String, Object> message) {
        try {
            log.info("Received event.created event: {}", message);
            String title = getString(message, "title");
            String eventId = getString(message, "eventId");

            notificationService.createNotification(
                    "all",
                    NotificationType.EVENT_CREATED,
                    "New Event",
                    "New event: " + title,
                    eventId,
                    ReferenceType.EVENT
            );
        } catch (Exception e) {
            log.error("Error processing event.created event: {}", e.getMessage(), e);
        }
    }

    @RabbitListener(queues = RabbitMQConfig.EVENT_RSVP_QUEUE)
    public void handleEventRsvp(Map<String, Object> message) {
        try {
            log.info("Received event.rsvp event: {}", message);
            String organizerName = getString(message, "organizerName");
            String userName = getString(message, "userName");
            String eventId = getString(message, "eventId");
            String status = getString(message, "status");

            if (organizerName != null && !userName.equals(organizerName)) {
                notificationService.createNotification(
                        organizerName,
                        NotificationType.EVENT_RSVP,
                        "New RSVP",
                        userName + " RSVP'd (" + status + ") to your event.",
                        eventId,
                        ReferenceType.EVENT
                );
            }
        } catch (Exception e) {
            log.error("Error processing event.rsvp event: {}", e.getMessage(), e);
        }
    }

    private String getString(Map<String, Object> map, String key) {
        Object value = map.get(key);
        return value != null ? value.toString() : null;
    }

    private String extractString(Object message) {
        if (message instanceof String) {
            return (String) message;
        }
        return message.toString();
    }
}
