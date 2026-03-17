package com.decp.job.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.decp.job.model.Application;
import com.decp.job.model.Job;
import com.decp.job.repository.ApplicationRepository;
import com.decp.job.repository.JobRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class JobService {

    private final JobRepository jobRepository;
    private final ApplicationRepository applicationRepository;

    public Job createJob(Job job) {
        return jobRepository.save(job);
    }

    public List<Job> getAllJobs() {
        return jobRepository.findAllByOrderByCreatedAtDesc();
    }

    public Job getJobById(Long id) {
        return jobRepository.findById(id).orElseThrow(() -> new RuntimeException("Job not found"));
    }

    @Transactional
    public Application applyForJob(Application application) {
        Application saved = applicationRepository.save(application);
        
        // Increment application count for the job
        Job job = getJobById(application.getJobId());
        job.setApplicationCount((job.getApplicationCount() != null ? job.getApplicationCount() : 0) + 1);
        jobRepository.save(job);
        
        return saved;
    }

    public Job updateJob(Long id, Job jobUpdates, Long userId) {
        Job job = getJobById(id);
        
        // Only the poster can update
        if (!job.getPostedBy().equals(userId)) {
            throw new RuntimeException("Only the job poster can update this job");
        }
        
        job.setTitle(jobUpdates.getTitle());
        job.setDescription(jobUpdates.getDescription());
        job.setCompany(jobUpdates.getCompany());
        job.setLocation(jobUpdates.getLocation());
        job.setType(jobUpdates.getType());
        
        return jobRepository.save(job);
    }

    public Job closeJob(Long id, Long userId) {
        Job job = getJobById(id);
        
        // Only the poster can close
        if (!job.getPostedBy().equals(userId)) {
            throw new RuntimeException("Only the job poster can close this job");
        }
        
        job.setStatus("CLOSED");
        return jobRepository.save(job);
    }

    public Job openJob(Long id, Long userId) {
        Job job = getJobById(id);
        
        // Only the poster can reopen
        if (!job.getPostedBy().equals(userId)) {
            throw new RuntimeException("Only the job poster can reopen this job");
        }
        
        job.setStatus("OPEN");
        return jobRepository.save(job);
    }

    public int getApplicationCount(Long jobId) {
        return (int) applicationRepository.countByJobId(jobId);
    }

    public List<Application> getApplicationsByJobId(Long jobId) {
        return applicationRepository.findAllByJobId(jobId);
    }

    public List<Application> getApplicationsByUserId(Long userId) {
        return applicationRepository.findAllByUserId(userId);
    }

    @Transactional
    public void deleteJob(Long id, Long userId) {
        Job job = getJobById(id);
        
        // Only the poster can delete
        if (!job.getPostedBy().equals(userId)) {
            throw new RuntimeException("Only the job poster can delete this job");
        }
        
        // Delete all applications for this job
        applicationRepository.deleteByJobId(id);
        
        // Delete the job
        jobRepository.deleteById(id);
    }
}
