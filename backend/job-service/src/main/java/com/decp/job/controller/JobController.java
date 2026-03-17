package com.decp.job.controller;

import com.decp.job.model.Application;
import com.decp.job.model.Job;
import com.decp.job.service.JobService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/jobs")
@RequiredArgsConstructor
public class JobController {

    private final JobService jobService;

    @PostMapping
    public ResponseEntity<Job> createJob(
            @RequestHeader("X-User-Role") String role,
            @RequestBody Job job) {
        if (!"ALUMNI".equals(role) && !"ADMIN".equals(role)) {
            return ResponseEntity.status(403).build();
        }
        return ResponseEntity.ok(jobService.createJob(job));
    }

    @GetMapping
    public ResponseEntity<List<Job>> getAllJobs() {
        return ResponseEntity.ok(jobService.getAllJobs());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Job> getJobById(@PathVariable Long id) {
        return ResponseEntity.ok(jobService.getJobById(id));
    }

    @PostMapping("/{id}/apply")
    public ResponseEntity<Application> applyForJob(
            @RequestHeader("X-User-Role") String role,
            @RequestHeader("X-User-Id") Long userId,
            @PathVariable Long id, 
            @RequestBody Application application) {
        if (!"STUDENT".equals(role)) {
            return ResponseEntity.status(403).build();
        }
        application.setJobId(id);
        application.setUserId(userId);
        return ResponseEntity.ok(jobService.applyForJob(application));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Job> updateJob(
            @RequestHeader("X-User-Role") String role,
            @RequestHeader("X-User-Id") Long userId,
            @PathVariable Long id,
            @RequestBody Job jobUpdates) {
        if (!"ALUMNI".equals(role) && !"ADMIN".equals(role)) {
            return ResponseEntity.status(403).build();
        }
        try {
            Job updated = jobService.updateJob(id, jobUpdates, userId);
            return ResponseEntity.ok(updated);
        } catch (RuntimeException e) {
            return ResponseEntity.status(403).build();
        }
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<Job> toggleJobStatus(
            @RequestHeader("X-User-Role") String role,
            @RequestHeader("X-User-Id") Long userId,
            @PathVariable Long id,
            @RequestParam String action) {
        if (!"ALUMNI".equals(role) && !"ADMIN".equals(role)) {
            return ResponseEntity.status(403).build();
        }
        try {
            Job updated = "close".equalsIgnoreCase(action) ? 
                jobService.closeJob(id, userId) : 
                jobService.openJob(id, userId);
            return ResponseEntity.ok(updated);
        } catch (RuntimeException e) {
            return ResponseEntity.status(403).build();
        }
    }

    @GetMapping("/{id}/applications")
    public ResponseEntity<?> getApplicationsByJob(
            @RequestHeader("X-User-Id") Long userId,
            @PathVariable Long id) {
        try {
            Job job = jobService.getJobById(id);
            if (!job.getPostedBy().equals(userId)) {
                return ResponseEntity.status(403).build();
            }
            return ResponseEntity.ok(jobService.getApplicationsByJobId(id));
        } catch (RuntimeException e) {
            return ResponseEntity.status(403).build();
        }
    }

    @GetMapping("/user/{userId}/applications")
    public ResponseEntity<List<Application>> getApplicationsByUser(@PathVariable Long userId) {
        return ResponseEntity.ok(jobService.getApplicationsByUserId(userId));
    }
}
