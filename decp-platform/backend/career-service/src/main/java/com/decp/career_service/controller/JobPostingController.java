package com.decp.career_service.controller;

import com.decp.career_service.entity.JobApplication;
import com.decp.career_service.entity.JobPosting;
import com.decp.career_service.repository.JobApplicationRepository;
import com.decp.career_service.repository.JobPostingRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/jobs")
public class JobPostingController {

    @Autowired
    private JobPostingRepository jobPostingRepository;
    
    @Autowired
    private JobApplicationRepository jobApplicationRepository;

    @GetMapping
    public ResponseEntity<?> getAllJobs(@RequestParam(required = false, defaultValue = "0") int page,
                                        @RequestParam(required = false, defaultValue = "20") int size,
                                        @RequestParam(required = false, defaultValue = "all") String type) {
        List<JobPosting> jobs = jobPostingRepository.findAll(
                Sort.by(Sort.Direction.DESC, "createdAt")
        );
        return ResponseEntity.ok(jobs);
    }

    @PostMapping
    public ResponseEntity<JobPosting> createJob(
            @RequestBody JobPosting jobPosting,
            @RequestHeader("X-User-Id") String userIdStr) {
            
        Long userId = Long.parseLong(userIdStr);
        jobPosting.setPostedBy(userId);
        JobPosting savedJob = jobPostingRepository.save(jobPosting);
        return ResponseEntity.status(201).body(savedJob);
    }

    @GetMapping("/{id}")
    public ResponseEntity<JobPosting> getJob(@PathVariable Long id) {
        Optional<JobPosting> job = jobPostingRepository.findById(id);
        return job.map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PostMapping("/{id}/apply")
    public ResponseEntity<JobApplication> applyForJob(
            @PathVariable Long id, 
            @RequestBody JobApplication application,
            @RequestHeader("X-User-Id") String userIdStr) {
            
        Long userId = Long.parseLong(userIdStr);
        application.setJobId(id);
        application.setApplicantId(userId);
        application.setStatus("SUBMITTED");
        
        JobApplication savedApp = jobApplicationRepository.save(application);
        return ResponseEntity.status(201).body(savedApp);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<String> deleteJob(
            @PathVariable Long id,
            @RequestHeader("X-User-Id") String userIdStr) {
            
        Long userId = Long.parseLong(userIdStr);
        Optional<JobPosting> job = jobPostingRepository.findById(id);
        if (job.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        
        if (!job.get().getPostedBy().equals(userId)) {
            return ResponseEntity.status(403).body("Unauthorized to delete this job");
        }

        try {
            jobPostingRepository.deleteById(id);
            return ResponseEntity.noContent().build();
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Failed to delete job posting.");
        }
    }
}