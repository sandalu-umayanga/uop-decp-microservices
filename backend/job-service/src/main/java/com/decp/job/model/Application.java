package com.decp.job.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "job_applications")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Application {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long jobId;
    private Long userId; // Applicant ID
    private String applicantName;
    
    @Column(columnDefinition = "TEXT")
    private String whyInterested; // Why are you interested in this position?
    
    private String resumeUrl;
    
    private String status; // e.g., PENDING, REVIEWED, ACCEPTED, REJECTED

    private LocalDateTime appliedAt;

    @PrePersist
    protected void onCreate() {
        appliedAt = LocalDateTime.now();
        if (status == null) {
            status = "PENDING";
        }
    }
}
