package com.decp.research.controller;

import com.decp.research.dto.AddProjectMemberRequest;
import com.decp.research.dto.ProjectMemberDTO;
import com.decp.research.service.CollaborationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/research/{id}/members")
@RequiredArgsConstructor
public class CollaborationController {

    private final CollaborationService collaborationService;

    @GetMapping
    public ResponseEntity<List<ProjectMemberDTO>> getProjectMembers(@PathVariable Long id) {
        return ResponseEntity.ok(collaborationService.getProjectMembers(id));
    }

    @PostMapping
    public ResponseEntity<ProjectMemberDTO> addProjectMember(
            @PathVariable Long id,
            @RequestHeader("X-User-Id") Long currentUserId,
            @Valid @RequestBody AddProjectMemberRequest request) {
        
        if (!collaborationService.isOwner(id, currentUserId)) {
            return ResponseEntity.status(403).build();
        }
        
        return ResponseEntity.ok(collaborationService.addProjectMember(
                id, request.getUserId(), request.getUserName(), request.getRole()));
    }

    @DeleteMapping("/{userId}")
    public ResponseEntity<Void> removeProjectMember(
            @PathVariable Long id,
            @PathVariable Long userId,
            @RequestHeader("X-User-Id") Long currentUserId) {
        
        if (!collaborationService.isOwner(id, currentUserId)) {
            return ResponseEntity.status(403).build();
        }
        
        collaborationService.removeProjectMember(id, userId);
        return ResponseEntity.noContent().build();
    }
}
