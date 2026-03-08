package com.decp.career_service.repository;

import com.decp.career_service.entity.JobApplication;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface JobApplicationRepository extends JpaRepository<JobApplication, Long> {

    // For the Alumni/Admin: "Show me everyone who applied to my job"
    List<JobApplication> findByJobId(Long jobId);

    // For the Student: "Show me all the jobs I've applied to"
    List<JobApplication> findByApplicantId(Long applicantId);
}