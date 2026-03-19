package com.decp.mentorship.service;

import com.decp.mentorship.dto.MentorshipProfileRequest;
import com.decp.mentorship.dto.MentorshipProfileResponse;
import com.decp.mentorship.model.MentorshipProfile;
import com.decp.mentorship.model.UserRole;
import com.decp.mentorship.repository.MentorshipProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class MentorshipProfileService {

    private final MentorshipProfileRepository profileRepository;

    @Transactional
    public MentorshipProfileResponse createOrUpdateProfile(Long userId, String userName, String userRole,
                                                            MentorshipProfileRequest request) {
        MentorshipProfile profile = profileRepository.findByUserId(userId)
                .orElse(MentorshipProfile.builder()
                        .userId(userId)
                        .userName(userName)
                        .userRole(UserRole.valueOf(userRole))
                        .rating(0.0)
                        .ratingCount(0L)
                        .isVerified(false)
                        .build());

        profile.setUserName(userName);
        profile.setRole(request.getRole());
        profile.setDepartment(request.getDepartment());
        profile.setYearsOfExperience(request.getYearsOfExperience());
        profile.setExpertise(request.getExpertise() != null ? request.getExpertise() : new ArrayList<>());
        profile.setInterests(request.getInterests() != null ? request.getInterests() : new ArrayList<>());
        profile.setBio(request.getBio());
        profile.setAvailability(request.getAvailability());
        profile.setTimezone(request.getTimezone());
        profile.setLinkedInUrl(request.getLinkedInUrl());

        MentorshipProfile saved = profileRepository.save(profile);
        return toResponse(saved);
    }

    public List<MentorshipProfileResponse> getAvailableMentors() {
        return profileRepository.findAvailableMentors().stream()
                .map(MentorshipProfileService::toResponse)
                .toList();
    }

    public MentorshipProfileResponse getProfile(Long userId) {
        MentorshipProfile profile = profileRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Mentorship profile not found for user: " + userId));
        return toResponse(profile);
    }

    public MentorshipProfileResponse getProfileById(Long profileId) {
        MentorshipProfile profile = profileRepository.findById(profileId)
                .orElseThrow(() -> new RuntimeException("Mentorship profile not found with id: " + profileId));
        return toResponse(profile);
    }

    public static MentorshipProfileResponse toResponse(MentorshipProfile profile) {
        return MentorshipProfileResponse.builder()
                .id(profile.getId())
                .userId(profile.getUserId())
                .userName(profile.getUserName())
                .role(profile.getRole())
                .department(profile.getDepartment())
                .yearsOfExperience(profile.getYearsOfExperience())
                .expertise(profile.getExpertise())
                .interests(profile.getInterests())
                .bio(profile.getBio())
                .availability(profile.getAvailability())
                .timezone(profile.getTimezone())
                .isVerified(profile.getIsVerified())
                .rating(profile.getRating())
                .ratingCount(profile.getRatingCount())
                .linkedInUrl(profile.getLinkedInUrl())
                .createdAt(profile.getCreatedAt())
                .updatedAt(profile.getUpdatedAt())
                .build();
    }
}
