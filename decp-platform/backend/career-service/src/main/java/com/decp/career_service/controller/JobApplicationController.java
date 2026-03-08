package com.decp.career_service.controller;

import com.decp.career_service.entity.JobApplication;
import com.decp.career_service.repository.JobApplicationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/careers/applications")
public class JobApplicationController {

    @Autowired
    private JobApplicationRepository applicationRepository;

    // 1. STUDENT APPLIES TO A JOB
    @PostMapping
    public ResponseEntity<JobApplication> submitApplication(@RequestBody JobApplication application) {
        JobApplication savedApp = applicationRepository.save(application);
        return ResponseEntity.ok(savedApp);
    }

    // 2. POSTER VIEWS APPLICANTS FOR A SPECIFIC JOB
    @GetMapping("/job/{jobId}")
    public ResponseEntity<List<JobApplication>> getApplicationsForJob(@PathVariable Long jobId) {
        return ResponseEntity.ok(applicationRepository.findByJobId(jobId));
    }

    // 3. STUDENT VIEWS THEIR OWN APPLICATIONS
    @GetMapping("/student/{studentId}")
    public ResponseEntity<List<JobApplication>> getApplicationsByStudent(@PathVariable String studentId) {
        return ResponseEntity.ok(applicationRepository.findByApplicantId(studentId));
    }
}