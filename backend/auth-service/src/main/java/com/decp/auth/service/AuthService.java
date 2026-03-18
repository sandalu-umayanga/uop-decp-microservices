package com.decp.auth.service;

import com.decp.auth.dto.AuthRequest;
import com.decp.auth.dto.AuthResponse;
import com.decp.auth.dto.UserDTO;
import com.decp.auth.util.JwtUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.server.ResponseStatusException;

import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final JwtUtils jwtUtils;
    private final RestTemplate restTemplate;
    private final org.springframework.security.crypto.password.PasswordEncoder passwordEncoder;

    @Value("${user.service.url:http://localhost:8082}")
    private String userServiceUrl;

    private String getUserServiceInternalUrl() {
        return userServiceUrl + "/api/users/internal";
    }

    public AuthResponse login(AuthRequest request) {
        try {
            UserDTO user = restTemplate.getForObject(getUserServiceInternalUrl() + "/" + request.getUsername(), UserDTO.class);
            
            if (user == null || !passwordEncoder.matches(request.getPassword(), user.getPassword())) {
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials");
            }

            Map<String, Object> claims = new HashMap<>();
            claims.put("role", user.getRole());
            claims.put("userId", user.getId());

            String token = jwtUtils.generateToken(user.getUsername(), claims);
            
            // Strip password before sending to client
            user.setPassword(null);
            return new AuthResponse(token, user);
        } catch (HttpClientErrorException.NotFound e) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials");
        } catch (ResponseStatusException e) {
            throw e;
        } catch (RestClientException e) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Authentication service dependency unavailable");
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Authentication failed");
        }
    }

    public boolean validate(String token) {
        return jwtUtils.validateToken(token);
    }
}