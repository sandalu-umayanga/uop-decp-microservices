package com.decp.analytics.repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.QueryHints;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.decp.analytics.model.AnalyticsSnapshot;
import com.decp.analytics.model.MetricType;

import jakarta.persistence.QueryHint;

@Repository
public interface AnalyticsSnapshotRepository extends JpaRepository<AnalyticsSnapshot, Long> {

    @QueryHints(@QueryHint(name = "jakarta.persistence.query.timeout", value = "3000"))
    Optional<AnalyticsSnapshot> findByMetricTypeAndSnapshotDate(MetricType metricType, LocalDate snapshotDate);

    @QueryHints(@QueryHint(name = "jakarta.persistence.query.timeout", value = "3000"))
    Optional<AnalyticsSnapshot> findTopByMetricTypeOrderBySnapshotDateDesc(MetricType metricType);

    @QueryHints(@QueryHint(name = "jakarta.persistence.query.timeout", value = "3000"))
    List<AnalyticsSnapshot> findBySnapshotDateBetweenOrderBySnapshotDateAsc(LocalDate from, LocalDate to);

    @QueryHints(@QueryHint(name = "jakarta.persistence.query.timeout", value = "3000"))
    List<AnalyticsSnapshot> findByMetricTypeAndSnapshotDateBetweenOrderBySnapshotDateAsc(
            MetricType metricType, LocalDate from, LocalDate to);

    @Query("SELECT a FROM AnalyticsSnapshot a WHERE a.snapshotDate < :cutoff")
    List<AnalyticsSnapshot> findOlderThan(@Param("cutoff") LocalDate cutoff);
}
