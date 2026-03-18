package com.decp.research.service;

import com.decp.research.dto.ProjectMemberDTO;
import com.decp.research.model.ProjectMember;
import com.decp.research.repository.ProjectMemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CollaborationService {

    private final ProjectMemberRepository projectMemberRepository;

    @Transactional
    public ProjectMemberDTO addProjectMember(Long researchId, Long userId, String userName, ProjectMember.ProjectRole role) {
        ProjectMember member = ProjectMember.builder()
                .researchId(researchId)
                .userId(userId)
                .userName(userName)
                .role(role)
                .build();
        ProjectMember saved = projectMemberRepository.save(member);
        return toDTO(saved);
    }

    public List<ProjectMemberDTO> getProjectMembers(Long researchId) {
        return projectMemberRepository.findByResearchId(researchId)
                .stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    @Transactional
    public void removeProjectMember(Long researchId, Long userId) {
        List<ProjectMember> members = projectMemberRepository.findByResearchId(researchId);
        members.stream()
                .filter(m -> m.getUserId().equals(userId))
                .findFirst()
                .ifPresent(projectMemberRepository::delete);
    }

    @Transactional
    public void deleteProjectCollaborationData(Long researchId) {
        projectMemberRepository.deleteByResearchId(researchId);
    }

    public boolean isOwner(Long researchId, Long userId) {
        return projectMemberRepository.findByResearchId(researchId)
                .stream()
                .anyMatch(m -> m.getUserId().equals(userId) && m.getRole() == ProjectMember.ProjectRole.OWNER);
    }

    private ProjectMemberDTO toDTO(ProjectMember member) {
        return ProjectMemberDTO.builder()
                .id(member.getId())
                .userId(member.getUserId())
                .userName(member.getUserName())
                .role(member.getRole())
                .joinedAt(member.getJoinedAt())
                .build();
    }
}
