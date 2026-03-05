package com.decp.user_service.dto;

import com.decp.user_service.model.Role;
import lombok.Data;

@Data
public class UserRegistrationRequest {
    private String name;
    private String email;
    private String password;
    private Role role;
}