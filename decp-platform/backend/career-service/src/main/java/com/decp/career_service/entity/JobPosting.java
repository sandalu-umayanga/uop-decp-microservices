package com.decp.career_service.entity;

import jakarta.persistence.*;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Entity
@Table(name = "job_postings")
public class JobPosting {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;
    private String company;

    @Column(columnDefinition = "TEXT")
    private String description;

    private String location;
    private String employmentType; // e.g., "Internship", "Full-Time", "Contract"
    private String applyLink;

    // To track who posted this opportunity (e.g., an Alumni)
    private String postedByUserId;
    private String postedByUserName;

    private LocalDateTime createdAt;

    // Automatically set the timestamp when the post is saved
    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    // --- GETTERS AND SETTERS ---
    // (If you are using @Data from Lombok, you can delete all of these!)

    public void setId(Long id) { this.id = id; }

    public void setTitle(String title) { this.title = title; }

    public void setCompany(String company) { this.company = company; }

    public void setDescription(String description) { this.description = description; }

    public void setLocation(String location) { this.location = location; }

    public void setEmploymentType(String employmentType) { this.employmentType = employmentType; }

    public void setApplyLink(String applyLink) { this.applyLink = applyLink; }

    public void setPostedByUserId(String postedByUserId) { this.postedByUserId = postedByUserId; }

    public void setPostedByUserName(String postedByUserName) { this.postedByUserName = postedByUserName; }

    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}