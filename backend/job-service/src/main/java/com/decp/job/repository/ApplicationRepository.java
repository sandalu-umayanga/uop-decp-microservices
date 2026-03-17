package com.decp.job.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.decp.job.model.Application;

@Repository
public interface ApplicationRepository extends JpaRepository<Application, Long> {
    List<Application> findAllByJobId(Long jobId);
    List<Application> findAllByUserId(Long userId);
    long countByJobId(Long jobId);
    void deleteByJobId(Long jobId);
}
