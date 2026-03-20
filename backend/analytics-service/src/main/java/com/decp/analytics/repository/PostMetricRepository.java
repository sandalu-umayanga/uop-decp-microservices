package com.decp.analytics.repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.QueryHints;
import org.springframework.stereotype.Repository;

import com.decp.analytics.model.PostMetric;

import jakarta.persistence.QueryHint;

@Repository
public interface PostMetricRepository extends JpaRepository<PostMetric, Long> {

    Optional<PostMetric> findByPostId(String postId);

    Long countByCreatedAtAfter(LocalDateTime after);

    @QueryHints(@QueryHint(name = "jakarta.persistence.query.timeout", value = "3000"))
    @Query("SELECT p FROM PostMetric p ORDER BY (p.likes + p.comments + p.views) DESC")
    List<PostMetric> findTopPostsByEngagement();

    @Query("SELECT COALESCE(AVG(p.likes), 0) FROM PostMetric p")
    Double findAverageLikes();

    @Query("SELECT COALESCE(AVG(p.comments), 0) FROM PostMetric p")
    Double findAverageComments();

    @Query("SELECT COALESCE(AVG(p.views), 0) FROM PostMetric p")
    Double findAverageViews();
}
