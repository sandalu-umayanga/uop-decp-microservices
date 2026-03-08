package com.decp.feed_service.controller;

import com.decp.feed_service.dto.CommentRequest;
import com.decp.feed_service.dto.PostRequest;
import com.decp.feed_service.model.Comment;
import com.decp.feed_service.model.Post;
import com.decp.feed_service.repository.PostRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api/posts")
public class FeedController {

    @Autowired
    private PostRepository postRepository;

    @PostMapping
    public ResponseEntity<Post> createPost(
            @RequestBody PostRequest request, 
            @RequestHeader("X-User-Id") String userIdStr, 
            @RequestHeader("X-User-Name") String userName) {
            
        Long userId = Long.parseLong(userIdStr);
        
        Post newPost = Post.builder()
                .authorId(userId)
                .authorName(userName)
                .text(request.getText())
                .mediaUrl(request.getMediaUrl())
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .likes(new ArrayList<>())
                .comments(new ArrayList<>())
                .build();

        Post savedPost = postRepository.save(newPost);
        return ResponseEntity.status(201).body(savedPost);
    }

    @GetMapping("/feed")
    public ResponseEntity<List<Post>> getAllPosts() {
        List<Post> posts = postRepository.findAll();
        return ResponseEntity.ok(posts);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePost(
            @PathVariable String id, 
            @RequestHeader("X-User-Id") String userIdStr) {
        
        Optional<Post> post = postRepository.findById(id);
        if (post.isEmpty()) return ResponseEntity.notFound().build();
        
        if (!post.get().getAuthorId().equals(Long.parseLong(userIdStr))) {
            return ResponseEntity.status(403).build();
        }

        postRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/likes")
    public ResponseEntity<?> toggleLike(
            @PathVariable String id, 
            @RequestHeader("X-User-Id") String userIdStr) {
        
        Optional<Post> optionalPost = postRepository.findById(id);
        if (optionalPost.isEmpty()) return ResponseEntity.notFound().build();
        
        Long userId = Long.parseLong(userIdStr);
        Post post = optionalPost.get();
        
        if (post.getLikes().contains(userId)) post.getLikes().remove(userId);
        else post.getLikes().add(userId);
        
        postRepository.save(post);
        return ResponseEntity.ok(post);
    }
    
    @PostMapping("/{id}/comments")
    public ResponseEntity<?> addComment(
            @PathVariable String id, 
            @RequestBody CommentRequest request,
            @RequestHeader("X-User-Id") String userIdStr, 
            @RequestHeader("X-User-Name") String userName) {
            
        Optional<Post> optionalPost = postRepository.findById(id);
        if (optionalPost.isPresent()) {
            Post post = optionalPost.get();
            Comment comment = Comment.builder()
                    .id(UUID.randomUUID().toString())
                    .userId(userIdStr)
                    .userName(userName)
                    .text(request.getText())
                    .createdAt(LocalDateTime.now())
                    .updatedAt(LocalDateTime.now())
                    .replies(new ArrayList<>())
                    .build();
            post.getComments().add(comment);
            post.setUpdatedAt(LocalDateTime.now());
            postRepository.save(post);
            return ResponseEntity.status(201).body(comment);
        }
        return ResponseEntity.notFound().build();
    }

    @PostMapping("/{id}/comments/{commentId}/replies")
    public ResponseEntity<?> addReply(
            @PathVariable String id,
            @PathVariable String commentId,
            @RequestBody CommentRequest request,
            @RequestHeader("X-User-Id") String userIdStr,
            @RequestHeader("X-User-Name") String userName) {
            
        Optional<Post> optionalPost = postRepository.findById(id);
        if (optionalPost.isPresent()) {
            Post post = optionalPost.get();
            for (Comment c : post.getComments()) {
                if (c.getId().equals(commentId)) {
                    Comment reply = Comment.builder()
                            .id(UUID.randomUUID().toString())
                            .userId(userIdStr)
                            .userName(userName)
                            .text(request.getText())
                            .createdAt(LocalDateTime.now())
                            .updatedAt(LocalDateTime.now())
                            .replies(new ArrayList<>())
                            .build();
                    c.getReplies().add(reply);
                    postRepository.save(post);
                    return ResponseEntity.status(201).body(reply);
                }
            }
        }
        return ResponseEntity.notFound().build();
    }

    @PutMapping("/{id}/comments/{commentId}")
    public ResponseEntity<?> editComment(
            @PathVariable String id,
            @PathVariable String commentId,
            @RequestBody CommentRequest request,
            @RequestHeader("X-User-Id") String userIdStr) {
            
        Optional<Post> optionalPost = postRepository.findById(id);
        if (optionalPost.isPresent()) {
            Post post = optionalPost.get();
            if (updateCommentInList(post.getComments(), commentId, request.getText(), userIdStr)) {
                postRepository.save(post);
                return ResponseEntity.ok().build();
            }
        }
        return ResponseEntity.notFound().build();
    }

    @DeleteMapping("/{id}/comments/{commentId}")
    public ResponseEntity<?> deleteComment(
            @PathVariable String id,
            @PathVariable String commentId,
            @RequestHeader("X-User-Id") String userIdStr) {
            
        Optional<Post> optionalPost = postRepository.findById(id);
        if (optionalPost.isPresent()) {
            Post post = optionalPost.get();
            if (removeCommentFromList(post.getComments(), commentId, userIdStr)) {
                postRepository.save(post);
                return ResponseEntity.noContent().build();
            }
        }
        return ResponseEntity.notFound().build();
    }

    private boolean updateCommentInList(List<Comment> comments, String id, String newText, String userId) {
        for (Comment c : comments) {
            if (c.getId().equals(id)) {
                if (!c.getUserId().equals(userId)) return false;
                c.setText(newText);
                c.setUpdatedAt(LocalDateTime.now());
                return true;
            }
            if (updateCommentInList(c.getReplies(), id, newText, userId)) return true;
        }
        return false;
    }

    private boolean removeCommentFromList(List<Comment> comments, String id, String userId) {
        for (int i = 0; i < comments.size(); i++) {
            Comment c = comments.get(i);
            if (c.getId().equals(id)) {
                if (!c.getUserId().equals(userId)) return false;
                comments.remove(i);
                return true;
            }
            if (removeCommentFromList(c.getReplies(), id, userId)) return true;
        }
        return false;
    }
}