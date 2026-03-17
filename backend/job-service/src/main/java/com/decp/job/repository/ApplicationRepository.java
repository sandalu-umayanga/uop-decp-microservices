package com.decp.job.repository;

import com.decp.job.model.Application;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ApplicationRepository extends JpaRepository<Application, Long> {
    List<Application> findAllByJobId(Long jobId);
    List<Application> findAllByUserId(Long userId);
    long countByJobId(Long jobId);
}
