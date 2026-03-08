package com.decp.career_service.controller;

import com.decp.career_service.entity.JobPosting;
import com.decp.career_service.repository.JobPostingRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/careers")
public class JobPostingController {

    @Autowired
    private JobPostingRepository jobPostingRepository;

    // 1. GET ALL JOBS (Sorted newest to oldest)
    @GetMapping
    public ResponseEntity<List<JobPosting>> getAllJobs() {
        List<JobPosting> jobs = jobPostingRepository.findAll(
                Sort.by(Sort.Direction.DESC, "createdAt")
        );
        return ResponseEntity.ok(jobs);
    }

    // 2. CREATE A NEW JOB POSTING
    @PostMapping
    public ResponseEntity<JobPosting> createJob(@RequestBody JobPosting jobPosting) {
        JobPosting savedJob = jobPostingRepository.save(jobPosting);
        return ResponseEntity.ok(savedJob);
    }

    // 3. DELETE A JOB POSTING
    @DeleteMapping("/{id}")
    public ResponseEntity<String> deleteJob(@PathVariable Long id) {
        try {
            jobPostingRepository.deleteById(id);
            return ResponseEntity.ok("Job posting deleted successfully!");
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Failed to delete job posting.");
        }
    }
}