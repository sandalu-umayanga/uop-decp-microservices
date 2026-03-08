package com.decp.user_service.controller;

import com.decp.user_service.dto.UserLoginRequest;
import com.decp.user_service.dto.UserRegistrationRequest;
import com.decp.user_service.model.User;
import com.decp.user_service.repository.UserRepository;
import com.decp.user_service.security.JwtUtil;
import org.mindrot.jbcrypt.BCrypt;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/users")
public class UserController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtUtil jwtUtil;

    @PostMapping("/register")
    public ResponseEntity<?> registerUser(@RequestBody UserRegistrationRequest request) {
        if (userRepository.findByEmail(request.getEmail()).isPresent()) {
            return ResponseEntity.badRequest().body("Error: Email is already registered!");
        }

        String hashedPassword = BCrypt.hashpw(request.getPassword(), BCrypt.gensalt());

        User newUser = User.builder()
                .name(request.getName())
                .email(request.getEmail())
                .passwordHash(hashedPassword)
                .role(request.getRole())
                .status("ACTIVE")
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        User savedUser = userRepository.save(newUser);

        return ResponseEntity.status(201).body(Map.of(
            "id", savedUser.getId(),
            "name", savedUser.getName(),
            "email", savedUser.getEmail(),
            "role", savedUser.getRole().name(),
            "createdAt", savedUser.getCreatedAt()
        ));
    }

    @PostMapping("/login")
    public ResponseEntity<?> loginUser(@RequestBody UserLoginRequest request) {
        var optionalUser = userRepository.findByEmail(request.getEmail());

        if (optionalUser.isEmpty()) {
            return ResponseEntity.status(401).body("Error: Invalid email or password");
        }

        User user = optionalUser.get();

        if (!BCrypt.checkpw(request.getPassword(), user.getPasswordHash())) {
            return ResponseEntity.status(401).body("Error: Invalid email or password");
        }

        String token = jwtUtil.generateToken(user.getId(), user.getName(), user.getEmail(), user.getRole().name());

        return ResponseEntity.ok(Map.of(
                "token", token,
                "role", user.getRole().name(),
                "id", user.getId(),
                "name", user.getName()
        ));
    }
    
    @GetMapping("/{id}/profile")
    public ResponseEntity<?> getProfile(@PathVariable Long id) {
        Optional<User> user = userRepository.findById(id);
        if (user.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        
        User u = user.get();
        return ResponseEntity.ok(Map.of(
            "id", u.getId(),
            "name", u.getName(),
            "email", u.getEmail(),
            "role", u.getRole().name(),
            "bio", u.getBio() != null ? u.getBio() : "",
            "department", u.getDepartment() != null ? u.getDepartment() : "",
            "graduationYear", u.getGraduationYear() != null ? u.getGraduationYear() : 0,
            "researchInterests", u.getResearchInterests() != null ? u.getResearchInterests() : "[]",
            "courseProjects", u.getCourseProjects() != null ? u.getCourseProjects() : "[]",
            "createdAt", u.getCreatedAt() != null ? u.getCreatedAt() : ""
        ));
    }

    @PutMapping("/{id}/profile")
    public ResponseEntity<?> updateProfile(@PathVariable Long id, @RequestBody Map<String, Object> updates) {
        Optional<User> optionalUser = userRepository.findById(id);
        if (optionalUser.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        User user = optionalUser.get();
        if (updates.containsKey("name")) user.setName((String) updates.get("name"));
        if (updates.containsKey("bio")) user.setBio((String) updates.get("bio"));
        if (updates.containsKey("department")) user.setDepartment((String) updates.get("department"));
        if (updates.containsKey("graduationYear")) user.setGraduationYear((Integer) updates.get("graduationYear"));
        if (updates.containsKey("researchInterests")) user.setResearchInterests(updates.get("researchInterests").toString());
        if (updates.containsKey("courseProjects")) user.setCourseProjects(updates.get("courseProjects").toString());
        
        user.setUpdatedAt(LocalDateTime.now());
        User updatedUser = userRepository.save(user);

        return ResponseEntity.ok(updatedUser);
    }
}