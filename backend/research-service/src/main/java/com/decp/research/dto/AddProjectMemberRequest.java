package com.decp.research.dto;

import com.decp.research.model.ProjectMember;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AddProjectMemberRequest {
    @NotNull
    private Long userId;
    @NotNull
    private String userName;
    @NotNull
    private ProjectMember.ProjectRole role;
}
