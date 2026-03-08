package com.decp.career_service.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
@Entity
@Table(name = "job_applications")
public class JobApplication {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // We store the ID of the job they are applying to
    private Long jobId;

    // Who is applying?
    private String applicantId;
    private String applicantName;

    @Column(columnDefinition = "TEXT")
    private String coverLetter;

    // A URL to their Google Drive or Portfolio
    private String resumeLink;

    // e.g., "PENDING", "REVIEWED", "REJECTED", "INTERVIEW"
    private String status = "PENDING";

    private LocalDateTime appliedAt;

    @PrePersist
    protected void onCreate() {
        this.appliedAt = LocalDateTime.now();
    }
}