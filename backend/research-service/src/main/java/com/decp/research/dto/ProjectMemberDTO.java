package com.decp.research.dto;

import com.decp.research.model.ProjectMember;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProjectMemberDTO {
    private Long id;
    private Long userId;
    private String userName;
    private ProjectMember.ProjectRole role;
    private LocalDateTime joinedAt;
}
