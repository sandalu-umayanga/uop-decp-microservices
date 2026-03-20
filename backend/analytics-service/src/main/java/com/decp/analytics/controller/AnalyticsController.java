package com.decp.analytics.controller;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.decp.analytics.dto.AnalyticsOverviewResponse;
import com.decp.analytics.dto.EventMetricsResponse;
import com.decp.analytics.dto.JobMetricsResponse;
import com.decp.analytics.dto.MessageMetricsResponse;
import com.decp.analytics.dto.PostMetricsResponse;
import com.decp.analytics.dto.ResearchMetricsResponse;
import com.decp.analytics.dto.TimelineEntry;
import com.decp.analytics.dto.UserMetricsResponse;
import com.decp.analytics.service.AnalyticsService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/analytics")
@RequiredArgsConstructor
public class AnalyticsController {

    private final AnalyticsService analyticsService;

    @GetMapping("/overview")
    public ResponseEntity<AnalyticsOverviewResponse> getOverview(
            @RequestHeader("X-User-Role") String userRole) {
        validateAdmin(userRole);
        return ResponseEntity.ok(analyticsService.getOverview());
    }

    @GetMapping("/users")
    public ResponseEntity<UserMetricsResponse> getUserMetrics(
            @RequestHeader("X-User-Role") String userRole) {
        validateAdmin(userRole);
        return ResponseEntity.ok(analyticsService.getUserMetrics());
    }

    @GetMapping("/posts")
    public ResponseEntity<PostMetricsResponse> getPostMetrics(
            @RequestHeader("X-User-Role") String userRole) {
        validateAdmin(userRole);
        return ResponseEntity.ok(analyticsService.getPostMetrics());
    }

    @GetMapping("/jobs")
    public ResponseEntity<JobMetricsResponse> getJobMetrics(
            @RequestHeader("X-User-Role") String userRole) {
        validateAdmin(userRole);
        return ResponseEntity.ok(analyticsService.getJobMetrics());
    }

    @GetMapping("/events")
    public ResponseEntity<EventMetricsResponse> getEventMetrics(
            @RequestHeader("X-User-Role") String userRole) {
        validateAdmin(userRole);
        return ResponseEntity.ok(analyticsService.getEventMetrics());
    }

    @GetMapping("/research")
    public ResponseEntity<ResearchMetricsResponse> getResearchMetrics(
            @RequestHeader("X-User-Role") String userRole) {
        validateAdmin(userRole);
        return ResponseEntity.ok(analyticsService.getResearchMetrics());
    }

    @GetMapping("/messages")
    public ResponseEntity<MessageMetricsResponse> getMessageMetrics(
            @RequestHeader("X-User-Role") String userRole) {
        validateAdmin(userRole);
        return ResponseEntity.ok(analyticsService.getMessageMetrics());
    }

    @GetMapping("/timeline")
    public ResponseEntity<List<TimelineEntry>> getTimeline(
            @RequestHeader("X-User-Role") String userRole,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        validateAdmin(userRole);
        if (from.isAfter(to)) {
            throw new RuntimeException("Invalid date range: 'from' must be before 'to'");
        }
        return ResponseEntity.ok(analyticsService.getTimelineMetrics(from, to));
    }

    @GetMapping("/export")
    public ResponseEntity<String> exportCsv(
            @RequestHeader("X-User-Role") String userRole,
            @RequestParam(defaultValue = "csv") String format,
            @RequestParam(defaultValue = "snapshots") String type) {
        validateAdmin(userRole);
        String csv = analyticsService.exportMetricsAsCsv(type);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"analytics-" + type + "-" + LocalDate.now() + ".csv\"")
                .contentType(MediaType.parseMediaType("text/csv"))
                .body(csv);
    }

    @PostMapping("/backfill")
    public ResponseEntity<Map<String, Object>> backfill(
            @RequestHeader("X-User-Role") String userRole,
            @RequestParam(defaultValue = "false") boolean force) {
        validateAdmin(userRole);
        Map<String, Long> counters = analyticsService.backfillFromSourceDatabases(force);
        return ResponseEntity.ok(Map.of(
                "status", "ok",
                "force", force,
                "counters", counters));
    }

    private void validateAdmin(String userRole) {
        if (!"ADMIN".equals(userRole)) {
            throw new RuntimeException("Access denied: ADMIN role required");
        }
    }
}
