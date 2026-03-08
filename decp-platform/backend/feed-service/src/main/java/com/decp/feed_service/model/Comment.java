package com.decp.feed_service.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Comment {
    @Builder.Default
    private String id = UUID.randomUUID().toString();
    
    private String userId;
    private String userName;
    private String text;
    
    @Builder.Default
    private List<Comment> replies = new ArrayList<>();
    
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}