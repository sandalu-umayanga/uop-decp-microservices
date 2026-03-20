package com.decp.post.controller;

import com.decp.post.dto.PostRequest;
import com.decp.post.model.Post;
import com.decp.post.service.PostService;
import com.decp.post.service.S3Service;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/posts")
@RequiredArgsConstructor
public class PostController {

    private final PostService postService;
    private final S3Service s3Service;

    @PostMapping("/media")
    public ResponseEntity<Map<String, String>> uploadMedia(
            @RequestParam("file") MultipartFile file) throws IOException {
        String url = s3Service.uploadFile(file);
        return ResponseEntity.ok(Map.of("url", url));
    }

    @PostMapping
    public ResponseEntity<Post> createPost(
            @RequestHeader("X-User-Name") String username,
            @RequestBody PostRequest request) {

        return ResponseEntity.ok(postService.createPost(
                request.getUserId(),
                username,
                request.getFullName(),
                request.getContent(),
                request.getMediaUrls()));
    }

    @GetMapping
    public ResponseEntity<List<Post>> getAllPosts() {
        return ResponseEntity.ok(postService.getAllPosts());
    }

    @PostMapping("/{postId}/like")
    public ResponseEntity<Post> likePost(
            @PathVariable String postId,
            @RequestBody Map<String, Long> body) {
        return ResponseEntity.ok(postService.likePost(postId, body.get("userId")));
    }

    @PostMapping("/{postId}/comment")
    public ResponseEntity<Post> addComment(
            @PathVariable String postId,
            @RequestBody Post.Comment comment) {
        return ResponseEntity.ok(postService.addComment(postId, comment));
    }
}