package com.decp.career_service.controller;

import com.decp.career_service.entity.JobApplication;
import com.decp.career_service.repository.JobApplicationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/jobs/applications")
public class JobApplicationController {

    @Autowired
    private JobApplicationRepository applicationRepository;

    @GetMapping("/job/{jobId}")
    public ResponseEntity<List<JobApplication>> getApplicationsForJob(@PathVariable Long jobId) {
        return ResponseEntity.ok(applicationRepository.findByJobId(jobId));
    }

    @GetMapping("/me")
    public ResponseEntity<List<JobApplication>> getMyApplications(@RequestHeader("X-User-Id") String userIdStr) {
        Long userId = Long.parseLong(userIdStr);
        return ResponseEntity.ok(applicationRepository.findByApplicantId(userId));
    }
}