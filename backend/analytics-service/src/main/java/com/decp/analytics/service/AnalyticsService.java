package com.decp.analytics.service;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

import org.bson.Document;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.decp.analytics.cache.MetricsCache;
import com.decp.analytics.dto.AnalyticsOverviewResponse;
import com.decp.analytics.dto.EventMetricsResponse;
import com.decp.analytics.dto.EventSummaryDTO;
import com.decp.analytics.dto.JobMetricsResponse;
import com.decp.analytics.dto.JobSummaryDTO;
import com.decp.analytics.dto.MessageMetricsResponse;
import com.decp.analytics.dto.PostMetricsResponse;
import com.decp.analytics.dto.PostSummaryDTO;
import com.decp.analytics.dto.ResearchMetricsResponse;
import com.decp.analytics.dto.TimelineEntry;
import com.decp.analytics.dto.UserMetricsResponse;
import com.decp.analytics.dto.UserSummaryDTO;
import com.decp.analytics.model.AnalyticsSnapshot;
import com.decp.analytics.model.MetricType;
import com.decp.analytics.model.PostMetric;
import com.decp.analytics.model.UserRole;
import com.decp.analytics.repository.AnalyticsSnapshotRepository;
import com.decp.analytics.repository.PostMetricRepository;
import com.decp.analytics.repository.UserMetricRepository;
import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.mongodb.client.MongoDatabase;
import com.mongodb.client.model.Filters;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class AnalyticsService {

    private final AnalyticsSnapshotRepository snapshotRepository;
    private final UserMetricRepository userMetricRepository;
    private final PostMetricRepository postMetricRepository;
    private final MetricsCache metricsCache;

        @Value("${analytics.source.user-db-url}")
        private String userDbUrl;

        @Value("${analytics.source.job-db-url}")
        private String jobDbUrl;

        @Value("${analytics.source.event-db-url}")
        private String eventDbUrl;

        @Value("${analytics.source.research-db-url}")
        private String researchDbUrl;

        @Value("${analytics.source.post-mongo-uri}")
        private String postMongoUri;

        @Value("${analytics.source.messaging-mongo-uri}")
        private String messagingMongoUri;

        @Value("${POSTGRES_USER:decp_user}")
        private String postgresUser;

        @Value("${POSTGRES_PASSWORD:decp_password}")
        private String postgresPassword;

    public AnalyticsOverviewResponse getOverview() {
                refreshSourceDataSafely();
        Long totalUsers = fallbackToDb(metricsCache.getCounter("users:total"), MetricType.USERS);
        Long totalPosts = fallbackToDb(metricsCache.getCounter("posts:total"), MetricType.POSTS);
                Long totalJobs = getReliableTotalJobs();
        Long totalEvents = fallbackToDb(metricsCache.getCounter("events:total"), MetricType.EVENTS);
        Long totalResearch = fallbackToDb(metricsCache.getCounter("research:total"), MetricType.RESEARCH);

        LocalDateTime now = LocalDateTime.now();
        Long activeToday = userMetricRepository.countByLastActiveAtAfter(now.toLocalDate().atStartOfDay());
        Long activeThisWeek = userMetricRepository.countByLastActiveAtAfter(now.minusDays(7));
        Long activeThisMonth = userMetricRepository.countByLastActiveAtAfter(now.minusDays(30));

        // Engagement trend: last 7 days from snapshots
        LocalDate today = LocalDate.now();
        List<AnalyticsSnapshot> weekSnapshots = safeSnapshotsBetween(today.minusDays(7), today);

        List<Double> engagementTrend = new ArrayList<>();
        for (int i = 6; i >= 0; i--) {
            LocalDate day = today.minusDays(i);
            double avg = weekSnapshots.stream()
                    .filter(s -> s.getSnapshotDate().equals(day))
                    .mapToDouble(AnalyticsSnapshot::getEngagementScore)
                    .average()
                    .orElse(0.0);
            engagementTrend.add(avg);
        }

        // Top posts this week
        List<PostSummaryDTO> topPosts = safeTopPosts().stream()
                .limit(5)
                .map(p -> PostSummaryDTO.builder()
                        .postId(p.getPostId())
                        .likes(p.getLikes())
                        .comments(p.getComments())
                        .views(p.getViews())
                        .totalEngagement(p.getLikes() + p.getComments() + p.getViews())
                        .build())
                .toList();

        // Top events from Redis leaderboard
        List<EventSummaryDTO> topEvents = metricsCache.getTopEvents(5).stream()
                .map(m -> EventSummaryDTO.builder()
                        .eventId((String) m.get("eventId"))
                        .title((String) m.get("title"))
                        .rsvpCount((Long) m.get("rsvpCount"))
                        .build())
                .toList();

        return AnalyticsOverviewResponse.builder()
                .totalUsers(totalUsers)
                .totalPosts(totalPosts)
                .totalJobs(totalJobs)
                .totalEvents(totalEvents)
                .totalResearch(totalResearch)
                .activeUsersToday(activeToday)
                .activeUsersThisWeek(activeThisWeek)
                .activeUsersThisMonth(activeThisMonth)
                .engagementTrendLastWeek(engagementTrend)
                .topPostsThisWeek(topPosts)
                .topEventsThisWeek(topEvents)
                .build();
    }

    public UserMetricsResponse getUserMetrics() {
                refreshSourceDataSafely();
                Long repoTotal = userMetricRepository.count();
                Long total = repoTotal > 0 ? repoTotal : fallbackToDb(metricsCache.getCounter("users:total"), MetricType.USERS);
        LocalDateTime now = LocalDateTime.now();
                Long repoThisMonth = userMetricRepository.countByCreatedAtAfter(now.minusDays(30));
                Long thisMonth = repoThisMonth > 0 ? repoThisMonth : fallbackNewCount(metricsCache.getCounter("users:new:month"), MetricType.USERS, 30);

                Long repoStudents = userMetricRepository.countByRole(UserRole.STUDENT);
                Long repoAlumni = userMetricRepository.countByRole(UserRole.ALUMNI);
                Long repoAdmins = userMetricRepository.countByRole(UserRole.ADMIN);
                Long students = repoStudents > 0 ? repoStudents : metricsCache.getCounter("users:role:student");
                Long alumni = repoAlumni > 0 ? repoAlumni : metricsCache.getCounter("users:role:alumni");
                Long admins = repoAdmins > 0 ? repoAdmins : metricsCache.getCounter("users:role:admin");

                Long repoNewThisWeek = userMetricRepository.countByCreatedAtAfter(now.minusDays(7));
                Long newThisWeek = repoNewThisWeek > 0 ? repoNewThisWeek : fallbackNewCount(metricsCache.getCounter("users:new:week"), MetricType.USERS, 7);

        List<UserSummaryDTO> mostActive = userMetricRepository.findMostActiveUsers().stream()
                .map(u -> UserSummaryDTO.builder()
                        .userId(u.getUserId())
                        .userName(u.getUserName())
                        .role(u.getRole() != null ? u.getRole().name() : null)
                        .totalActivity(u.getPostsCreated() + u.getEventsAttended() +
                                u.getJobsApplied() + u.getResearchUploaded() + u.getMessagesCount())
                        .build())
                .toList();

        // Retention rate: % of users active this week who were also active last week
        Long activeThisWeek = userMetricRepository.countByLastActiveAtAfter(now.minusDays(7));
        Long returning = userMetricRepository.countReturningUsersSince(now.minusDays(7));
        Double retention = activeThisWeek > 0 ? (returning * 100.0) / activeThisWeek : 0.0;

        return UserMetricsResponse.builder()
                .totalUsers(total)
                .usersThisMonth(thisMonth)
                .studentCount(students)
                .alumniCount(alumni)
                .adminCount(admins)
                .mostActiveUsers(mostActive)
                .newUsersThisWeek(newThisWeek)
                .userRetentionRate(Math.round(retention * 100.0) / 100.0)
                .build();
    }

    public PostMetricsResponse getPostMetrics() {
                refreshSourceDataSafely();
                Long repoTotal = postMetricRepository.count();
                Long total = repoTotal > 0 ? repoTotal : fallbackToDb(metricsCache.getCounter("posts:total"), MetricType.POSTS);

                Long repoThisMonth = postMetricRepository.countByCreatedAtAfter(LocalDateTime.now().minusDays(30));
                Long thisMonth = repoThisMonth > 0 ? repoThisMonth : fallbackNewCount(metricsCache.getCounter("posts:new:month"), MetricType.POSTS, 30);

        Double avgLikes = postMetricRepository.findAverageLikes();
        Double avgComments = postMetricRepository.findAverageComments();
        Double avgViews = postMetricRepository.findAverageViews();

        Map<Long, String> sourceUserNameById = loadUserDisplayNamesFromSourceDb();
        Map<Long, String> userNameById = sourceUserNameById.isEmpty()
                ? userMetricRepository.findAll().stream()
                .filter(u -> u.getUserId() != null)
                .collect(Collectors.toMap(
                        u -> u.getUserId(),
                        u -> u.getUserName() != null && !u.getUserName().isBlank()
                                ? u.getUserName()
                                : "User #" + u.getUserId(),
                        (a, b) -> a,
                        LinkedHashMap::new))
                : sourceUserNameById;

        Map<String, String> postAuthorByPostId = resolvePostAuthorNames(safeTopPosts());

        List<PostSummaryDTO> topPosts = safeTopPosts().stream()
                .map(p -> PostSummaryDTO.builder()
                        .postId(p.getPostId())
                        .authorName(resolveAuthorName(p, postAuthorByPostId, userNameById))
                        .likes(p.getLikes())
                        .comments(p.getComments())
                        .views(p.getViews())
                        .totalEngagement(p.getLikes() + p.getComments() + p.getViews())
                        .build())
                .toList();

        // Engagement trend from snapshots
        LocalDate today = LocalDate.now();
        List<AnalyticsSnapshot> snapshots = safeSnapshotsByTypeBetween(
                MetricType.POSTS, today.minusDays(30), today);

        Map<LocalDate, Double> trend = snapshots.stream()
                .collect(Collectors.toMap(
                        AnalyticsSnapshot::getSnapshotDate,
                        AnalyticsSnapshot::getEngagementScore,
                        (a, b) -> b,
                        LinkedHashMap::new));

        return PostMetricsResponse.builder()
                .totalPosts(total)
                .postsThisMonth(thisMonth)
                .averageLikesPerPost(Math.round(avgLikes * 100.0) / 100.0)
                .averageCommentsPerPost(Math.round(avgComments * 100.0) / 100.0)
                .averageViewsPerPost(Math.round(avgViews * 100.0) / 100.0)
                .topPostsAllTime(topPosts)
                .engagementTrend(trend)
                .build();
    }

    public JobMetricsResponse getJobMetrics() {
                refreshSourceDataSafely();
                Long totalJobs = getReliableTotalJobs();
        Long openJobs = metricsCache.getCounter("jobs:open");
        Long jobsThisMonth = fallbackNewCount(metricsCache.getCounter("jobs:new:today"), MetricType.JOBS, 30);
        Long totalApps = fallbackDerivedCount(
                metricsCache.getCounter("jobs:applications:total"),
                MetricType.JOBS,
                (snapshot) -> Math.round(snapshot.getEngagementScore() * snapshot.getTotalCount()));
        Long appsThisMonth = metricsCache.getCounter("jobs:applications:today");

        Double avgApps = totalJobs > 0 ? (double) totalApps / totalJobs : 0.0;

        List<JobSummaryDTO> topJobs = metricsCache.getTopJobs(10).stream()
                .map(m -> JobSummaryDTO.builder()
                        .jobId((String) m.get("jobId"))
                        .title((String) m.get("title"))
                        .applications((Long) m.get("applications"))
                        .build())
                .toList();

        // Application trend from snapshots
        LocalDate today = LocalDate.now();
        List<AnalyticsSnapshot> snapshots = safeSnapshotsByTypeBetween(
                MetricType.JOBS, today.minusDays(30), today);

        Map<LocalDate, Long> trend = snapshots.stream()
                .collect(Collectors.toMap(
                        AnalyticsSnapshot::getSnapshotDate,
                        AnalyticsSnapshot::getNewCount,
                        (a, b) -> b,
                        LinkedHashMap::new));

        return JobMetricsResponse.builder()
                .totalJobs(totalJobs)
                .openJobs(openJobs)
                .jobsThisMonth(jobsThisMonth)
                .totalApplications(totalApps)
                .applicationsThisMonth(appsThisMonth)
                .averageApplicationsPerJob(Math.round(avgApps * 100.0) / 100.0)
                .topJobsByApplications(topJobs)
                .applicationTrendLastMonth(trend)
                .build();
    }

    public EventMetricsResponse getEventMetrics() {
                refreshSourceDataSafely();
        Long totalEvents = fallbackToDb(metricsCache.getCounter("events:total"), MetricType.EVENTS);
        Long eventsThisMonth = fallbackNewCount(metricsCache.getCounter("events:new:today"), MetricType.EVENTS, 30);
        Long totalRsvps = fallbackDerivedCount(
                metricsCache.getCounter("events:rsvps:total"),
                MetricType.EVENTS,
                (snapshot) -> Math.round(snapshot.getEngagementScore() * snapshot.getTotalCount()));
        Long rsvpsThisMonth = metricsCache.getCounter("events:rsvps:today");

        Double avgRsvps = totalEvents > 0 ? (double) totalRsvps / totalEvents : 0.0;

        List<EventSummaryDTO> topEvents = metricsCache.getTopEvents(10).stream()
                .map(m -> EventSummaryDTO.builder()
                        .eventId((String) m.get("eventId"))
                        .title((String) m.get("title"))
                        .rsvpCount((Long) m.get("rsvpCount"))
                        .build())
                .toList();

        LocalDate today = LocalDate.now();
        List<AnalyticsSnapshot> snapshots = safeSnapshotsByTypeBetween(
                MetricType.EVENTS, today.minusDays(30), today);

        Map<LocalDate, Long> trend = snapshots.stream()
                .collect(Collectors.toMap(
                        AnalyticsSnapshot::getSnapshotDate,
                        AnalyticsSnapshot::getNewCount,
                        (a, b) -> b,
                        LinkedHashMap::new));

        return EventMetricsResponse.builder()
                .totalEvents(totalEvents)
                .eventsThisMonth(eventsThisMonth)
                .totalRsvps(totalRsvps)
                .rsvpsThisMonth(rsvpsThisMonth)
                .averageRsvpsPerEvent(Math.round(avgRsvps * 100.0) / 100.0)
                .topEventsByRsvps(topEvents)
                .eventTrendLastMonth(trend)
                .build();
    }

        private Long getReliableTotalJobs() {
                Long sourceCount = queryPgCountNullable(jobDbUrl, "SELECT COUNT(*) FROM jobs");
                // Accept 0 as a valid source-of-truth value; only fallback when the DB query fails.
                if (sourceCount != null) {
                        return sourceCount;
                }
                return fallbackToDb(metricsCache.getCounter("jobs:total"), MetricType.JOBS);
        }

        private void refreshSourceDataSafely() {
                try {
                        backfillFromSourceDatabases(false);
                } catch (Exception ex) {
                        log.warn("Source backfill failed before serving analytics response: {}", ex.getMessage());
                }
        }

    public ResearchMetricsResponse getResearchMetrics() {
                refreshSourceDataSafely();
        Long total = fallbackToDb(metricsCache.getCounter("research:total"), MetricType.RESEARCH);
        Long thisMonth = fallbackNewCount(metricsCache.getCounter("research:new:today"), MetricType.RESEARCH, 30);
        Long totalDownloads = metricsCache.getCounter("research:downloads:total");
        Long totalCitations = metricsCache.getCounter("research:citations:today");

        Double avgViews = total > 0 ? (double) metricsCache.getCounter("research:views:total") / total : 0.0;

        LocalDate today = LocalDate.now();
        List<AnalyticsSnapshot> snapshots = safeSnapshotsByTypeBetween(
                MetricType.RESEARCH, today.minusDays(30), today);

        Map<LocalDate, Long> trend = snapshots.stream()
                .collect(Collectors.toMap(
                        AnalyticsSnapshot::getSnapshotDate,
                        AnalyticsSnapshot::getNewCount,
                        (a, b) -> b,
                        LinkedHashMap::new));

        return ResearchMetricsResponse.builder()
                .totalResearch(total)
                .researchThisMonth(thisMonth)
                .totalDownloads(totalDownloads)
                .totalCitations(totalCitations)
                .averageViewsPerPaper(Math.round(avgViews * 100.0) / 100.0)
                .uploadTrendLastMonth(trend)
                .build();
    }

    public MessageMetricsResponse getMessageMetrics() {
                refreshSourceDataSafely();
        Long totalMessages = fallbackToDb(metricsCache.getCounter("messages:total"), MetricType.MESSAGES);
        Long thisMonth = fallbackNewCount(metricsCache.getCounter("messages:month"), MetricType.MESSAGES, 30);
        Long thisWeek = fallbackNewCount(metricsCache.getCounter("messages:week"), MetricType.MESSAGES, 7);
        Long today = fallbackNewCount(metricsCache.getCounter("messages:today"), MetricType.MESSAGES, 1);
        Long activeConversations = metricsCache.getCounter("messages:conversations:active");

        LocalDate todayDate = LocalDate.now();
        List<AnalyticsSnapshot> snapshots = safeSnapshotsByTypeBetween(
                MetricType.MESSAGES, todayDate.minusDays(30), todayDate);

        Map<LocalDate, Long> trend = snapshots.stream()
                .collect(Collectors.toMap(
                        AnalyticsSnapshot::getSnapshotDate,
                        AnalyticsSnapshot::getNewCount,
                        (a, b) -> b,
                        LinkedHashMap::new));

        return MessageMetricsResponse.builder()
                .totalMessages(totalMessages)
                .messagesThisMonth(thisMonth)
                .messagesThisWeek(thisWeek)
                .messagesToday(today)
                .activeConversations(activeConversations)
                .messageTrendLastMonth(trend)
                .build();
    }

    public Map<String, Long> backfillFromSourceDatabases(boolean force) {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime monthAgo = now.minusDays(30);
        LocalDateTime weekAgo = now.minusDays(7);

        Long totalUsers = queryPgCount(userDbUrl, "SELECT COUNT(*) FROM users");
        Long usersThisMonth = queryPgCountSince(userDbUrl, "SELECT COUNT(*) FROM users WHERE created_at >= ?", monthAgo);
        Long usersThisWeek = queryPgCountSince(userDbUrl, "SELECT COUNT(*) FROM users WHERE created_at >= ?", weekAgo);
        Long studentCount = queryPgCount(userDbUrl, "SELECT COUNT(*) FROM users WHERE role = 'STUDENT'");
        Long alumniCount = queryPgCount(userDbUrl, "SELECT COUNT(*) FROM users WHERE role = 'ALUMNI'");
        Long adminCount = queryPgCount(userDbUrl, "SELECT COUNT(*) FROM users WHERE role = 'ADMIN'");

        Long totalJobs = queryPgCount(jobDbUrl, "SELECT COUNT(*) FROM jobs");
        Long openJobs = queryPgCount(jobDbUrl, "SELECT COUNT(*) FROM jobs WHERE status = 'OPEN'");
        Long jobsThisMonth = queryPgCountSince(jobDbUrl, "SELECT COUNT(*) FROM jobs WHERE created_at >= ?", monthAgo);
        Long totalJobApplications = queryPgCount(jobDbUrl, "SELECT COUNT(*) FROM job_applications");
        Long jobApplicationsThisMonth = queryPgCountSince(jobDbUrl, "SELECT COUNT(*) FROM job_applications WHERE applied_at >= ?", monthAgo);
        List<Map<String, Object>> topJobs = queryPgRows(jobDbUrl,
                "SELECT id, title, COALESCE(application_count, 0) AS applications " +
                        "FROM jobs ORDER BY COALESCE(application_count, 0) DESC, id DESC LIMIT 10");

        Long totalEvents = queryPgCount(eventDbUrl, "SELECT COUNT(*) FROM events");
        Long eventsThisMonth = queryPgCountSince(eventDbUrl, "SELECT COUNT(*) FROM events WHERE created_at >= ?", monthAgo);
        Long totalRsvps = queryPgCount(eventDbUrl, "SELECT COUNT(*) FROM rsvps");
        Long rsvpsThisMonth = queryPgCountSince(eventDbUrl, "SELECT COUNT(*) FROM rsvps WHERE responded_at >= ?", monthAgo);
        List<Map<String, Object>> topEvents = queryPgRows(eventDbUrl,
                "SELECT e.id, e.title, COALESCE(COUNT(r.id), 0) AS rsvp_count " +
                        "FROM events e LEFT JOIN rsvps r ON r.event_id = e.id " +
                        "GROUP BY e.id, e.title ORDER BY rsvp_count DESC, e.id DESC LIMIT 10");

        Long totalResearch = queryPgCount(researchDbUrl, "SELECT COUNT(*) FROM research");
        Long researchThisMonth = queryPgCountSince(researchDbUrl, "SELECT COUNT(*) FROM research WHERE created_at >= ?", monthAgo);
        Long totalDownloads = queryPgCount(researchDbUrl, "SELECT COALESCE(SUM(downloads), 0) FROM research");
        Long totalCitations = queryPgCount(researchDbUrl, "SELECT COALESCE(SUM(citations), 0) FROM research");

        Long totalPosts = queryMongoCount(postMongoUri, "posts", monthAgo, false);
        Long postsThisMonth = queryMongoCount(postMongoUri, "posts", monthAgo, true);
        syncPostMetricsFromMongo();

        Long totalMessages = queryMongoCount(messagingMongoUri, "messages", monthAgo, false);
        Long messagesThisMonth = queryMongoCount(messagingMongoUri, "messages", monthAgo, true);
        Long messagesThisWeek = queryMongoCountSince(messagingMongoUri, "messages", weekAgo);
        Long messagesToday = queryMongoCountSince(messagingMongoUri, "messages", now.toLocalDate().atStartOfDay());
        Long activeConversations = queryMongoDistinctCount(messagingMongoUri, "messages", "conversationId");

        metricsCache.setCounter("users:total", totalUsers);
        metricsCache.setCounter("users:new:month", usersThisMonth);
        metricsCache.setCounter("users:new:week", usersThisWeek);
        metricsCache.setCounter("users:role:student", studentCount);
        metricsCache.setCounter("users:role:alumni", alumniCount);
        metricsCache.setCounter("users:role:admin", adminCount);

        metricsCache.setCounter("posts:total", totalPosts);
        metricsCache.setCounter("posts:new:month", postsThisMonth);

        metricsCache.setCounter("jobs:total", totalJobs);
        metricsCache.setCounter("jobs:open", openJobs);
        metricsCache.setCounter("jobs:applications:total", totalJobApplications);
        metricsCache.setCounter("jobs:applications:today", jobApplicationsThisMonth);
        topJobs.forEach(job -> metricsCache.upsertJobLeaderboard(
                String.valueOf(job.getOrDefault("id", "")),
                String.valueOf(job.getOrDefault("title", "")),
                ((Number) job.getOrDefault("applications", 0)).longValue()));

        metricsCache.setCounter("events:total", totalEvents);
        metricsCache.setCounter("events:rsvps:total", totalRsvps);
        metricsCache.setCounter("events:rsvps:today", rsvpsThisMonth);
        topEvents.forEach(event -> metricsCache.upsertEventLeaderboard(
                String.valueOf(event.getOrDefault("id", "")),
                String.valueOf(event.getOrDefault("title", "")),
                ((Number) event.getOrDefault("rsvp_count", 0)).longValue()));

        metricsCache.setCounter("research:total", totalResearch);
        metricsCache.setCounter("research:downloads:total", totalDownloads);
        metricsCache.setCounter("research:citations:today", totalCitations);

        metricsCache.setCounter("messages:total", totalMessages);
        metricsCache.setCounter("messages:month", messagesThisMonth);
        metricsCache.setCounter("messages:week", messagesThisWeek);
        metricsCache.setCounter("messages:today", messagesToday);
        metricsCache.setCounter("messages:conversations:active", activeConversations);

        upsertSnapshot(MetricType.USERS, totalUsers, usersThisMonth, 0L, 0.0);
        upsertSnapshot(MetricType.POSTS, totalPosts, postsThisMonth, 0L, 0.0);
        upsertSnapshot(MetricType.JOBS, totalJobs, jobsThisMonth, 0L,
                totalJobs > 0 ? (double) totalJobApplications / totalJobs : 0.0);
        upsertSnapshot(MetricType.EVENTS, totalEvents, eventsThisMonth, 0L,
                totalEvents > 0 ? (double) totalRsvps / totalEvents : 0.0);
        upsertSnapshot(MetricType.RESEARCH, totalResearch, researchThisMonth, 0L, 0.0);
        upsertSnapshot(MetricType.MESSAGES, totalMessages, messagesThisMonth, 0L, 0.0);

        Map<String, Long> counters = new LinkedHashMap<>();
        counters.put("users:total", totalUsers);
        counters.put("posts:total", totalPosts);
        counters.put("jobs:total", totalJobs);
        counters.put("events:total", totalEvents);
        counters.put("research:total", totalResearch);
        counters.put("messages:total", totalMessages);
        return counters;
    }

    public List<TimelineEntry> getTimelineMetrics(LocalDate from, LocalDate to) {
                List<AnalyticsSnapshot> snapshots = safeSnapshotsBetween(from, to);

        return snapshots.stream()
                .map(s -> TimelineEntry.builder()
                        .date(s.getSnapshotDate())
                        .metricType(s.getMetricType())
                        .totalCount(s.getTotalCount())
                        .newCount(s.getNewCount())
                        .engagementScore(s.getEngagementScore())
                        .build())
                .toList();
    }

    public String exportMetricsAsCsv(String type) {
        StringWriter sw = new StringWriter();
        PrintWriter pw = new PrintWriter(sw);

        if ("users".equalsIgnoreCase(type)) {
            pw.println("userId,userName,role,postsCreated,eventsAttended,jobsApplied,researchUploaded,messagesCount,lastActiveAt,loginCount");
            userMetricRepository.findAll().forEach(u ->
                    pw.printf("%d,%s,%s,%d,%d,%d,%d,%d,%s,%d%n",
                            u.getUserId(),
                            escapeCsv(u.getUserName()),
                            u.getRole(),
                            u.getPostsCreated(),
                            u.getEventsAttended(),
                            u.getJobsApplied(),
                            u.getResearchUploaded(),
                            u.getMessagesCount(),
                            u.getLastActiveAt(),
                            u.getLoginCount()));
        } else if ("posts".equalsIgnoreCase(type)) {
            pw.println("postId,createdByUserId,likes,comments,shares,views,createdAt");
            postMetricRepository.findAll().forEach(p ->
                    pw.printf("%s,%s,%d,%d,%d,%d,%s%n",
                            escapeCsv(p.getPostId()),
                            p.getCreatedByUserId(),
                            p.getLikes(),
                            p.getComments(),
                            p.getShares(),
                            p.getViews(),
                            p.getCreatedAt()));
        } else {
            // Default: snapshots
            pw.println("date,metricType,totalCount,newCount,activeCount,engagementScore,averageEngagement");
            snapshotRepository.findAll().forEach(s ->
                    pw.printf("%s,%s,%d,%d,%d,%.2f,%.2f%n",
                            s.getSnapshotDate(),
                            s.getMetricType(),
                            s.getTotalCount(),
                            s.getNewCount(),
                            s.getActiveCount(),
                            s.getEngagementScore(),
                            s.getAverageEngagement()));
        }

        pw.flush();
        return sw.toString();
    }

    private Long fallbackToDb(Long redisValue, MetricType type) {
        if (redisValue != null && redisValue > 0) return redisValue;
                try {
                        return snapshotRepository.findTopByMetricTypeOrderBySnapshotDateDesc(type)
                .map(AnalyticsSnapshot::getTotalCount)
                .orElse(0L);
                } catch (Exception ex) {
                        log.warn("Snapshot total fallback failed for {}: {}", type, ex.getMessage());
                        return 0L;
                }
    }

    private Long fallbackNewCount(Long redisValue, MetricType type, int days) {
        if (redisValue != null && redisValue > 0) return redisValue;

        LocalDate today = LocalDate.now();
        LocalDate from = today.minusDays(Math.max(0, days - 1L));
        return safeSnapshotsByTypeBetween(type, from, today)
                .stream()
                .map(AnalyticsSnapshot::getNewCount)
                .filter(Objects::nonNull)
                .reduce(0L, Long::sum);
    }

    private Long fallbackDerivedCount(
            Long redisValue,
            MetricType type,
            java.util.function.Function<AnalyticsSnapshot, Long> extractor) {
        if (redisValue != null && redisValue > 0) return redisValue;
                try {
                        return snapshotRepository.findTopByMetricTypeOrderBySnapshotDateDesc(type)
                                        .map(extractor)
                                        .orElse(0L);
                } catch (Exception ex) {
                        log.warn("Snapshot derived fallback failed for {}: {}", type, ex.getMessage());
                        return 0L;
                }
        }

        private List<AnalyticsSnapshot> safeSnapshotsBetween(LocalDate from, LocalDate to) {
                try {
                        return snapshotRepository.findBySnapshotDateBetweenOrderBySnapshotDateAsc(from, to);
                } catch (Exception ex) {
                        log.warn("Snapshot range query failed for {} to {}: {}", from, to, ex.getMessage());
                        return List.of();
                }
        }

        private List<AnalyticsSnapshot> safeSnapshotsByTypeBetween(MetricType type, LocalDate from, LocalDate to) {
                try {
                        return snapshotRepository.findByMetricTypeAndSnapshotDateBetweenOrderBySnapshotDateAsc(type, from, to);
                } catch (Exception ex) {
                        log.warn("Snapshot range query failed for {} from {} to {}: {}", type, from, to, ex.getMessage());
                        return List.of();
                }
        }

        private List<PostMetric> safeTopPosts() {
                try {
                        return postMetricRepository.findTopPostsByEngagement();
                } catch (Exception ex) {
                        log.warn("Top posts query failed: {}", ex.getMessage());
                        return List.of();
                }
    }

        private Long queryPgCount(String jdbcUrl, String sql) {
                try (Connection connection = DriverManager.getConnection(jdbcUrl, postgresUser, postgresPassword);
                         PreparedStatement statement = connection.prepareStatement(sql);
                         ResultSet rs = statement.executeQuery()) {
                        return rs.next() ? rs.getLong(1) : 0L;
                } catch (Exception ex) {
                        log.warn("PostgreSQL count query failed ({}): {}", jdbcUrl, ex.getMessage());
                        return 0L;
                }
        }

        private Long queryPgCountNullable(String jdbcUrl, String sql) {
                try (Connection connection = DriverManager.getConnection(jdbcUrl, postgresUser, postgresPassword);
                         PreparedStatement statement = connection.prepareStatement(sql);
                         ResultSet rs = statement.executeQuery()) {
                        return rs.next() ? rs.getLong(1) : 0L;
                } catch (Exception ex) {
                        log.warn("PostgreSQL nullable count query failed ({}): {}", jdbcUrl, ex.getMessage());
                        return null;
                }
        }

        private Long queryPgCountSince(String jdbcUrl, String sql, LocalDateTime since) {
                try (Connection connection = DriverManager.getConnection(jdbcUrl, postgresUser, postgresPassword);
                         PreparedStatement statement = connection.prepareStatement(sql)) {
                        statement.setTimestamp(1, Timestamp.valueOf(since));
                        try (ResultSet rs = statement.executeQuery()) {
                                return rs.next() ? rs.getLong(1) : 0L;
                        }
                } catch (Exception ex) {
                        log.warn("PostgreSQL ranged count query failed ({}): {}", jdbcUrl, ex.getMessage());
                        return 0L;
                }
        }

        private Long queryMongoCount(String mongoUri, String collection, LocalDateTime since, boolean applySince) {
                try (MongoClient mongoClient = MongoClients.create(mongoUri)) {
                        MongoDatabase database = resolveMongoDatabase(mongoClient, mongoUri);
                        if (database == null) {
                                return 0L;
                        }

                        if (!applySince) {
                                return database.getCollection(collection).countDocuments();
                        }
                        return database.getCollection(collection).countDocuments(
                                        Filters.gte("createdAt", Date.from(since.atZone(java.time.ZoneId.systemDefault()).toInstant())));
                } catch (Exception ex) {
                        log.warn("Mongo count query failed ({}:{}): {}", mongoUri, collection, ex.getMessage());
                        return 0L;
                }
        }

        private Long queryMongoCountSince(String mongoUri, String collection, LocalDateTime since) {
                return queryMongoCount(mongoUri, collection, since, true);
        }

        private void syncPostMetricsFromMongo() {
                try (MongoClient mongoClient = MongoClients.create(postMongoUri)) {
                        MongoDatabase database = resolveMongoDatabase(mongoClient, postMongoUri);
                        if (database == null) {
                                return;
                        }

                        for (Document doc : database.getCollection("posts").find()) {
                                String postId = String.valueOf(doc.get("_id"));
                                if (postId == null || postId.isBlank()) {
                                        continue;
                                }

                                Long createdByUserId = null;
                                Object userIdVal = doc.get("userId");
                                if (userIdVal instanceof Number n) {
                                        createdByUserId = n.longValue();
                                }

                                int likes = 0;
                                Object likedByVal = doc.get("likedBy");
                                if (likedByVal instanceof List<?> list) {
                                        likes = list.size();
                                }

                                int comments = 0;
                                Object commentsVal = doc.get("comments");
                                if (commentsVal instanceof List<?> list) {
                                        comments = list.size();
                                }

                                PostMetric metric = postMetricRepository.findByPostId(postId)
                                                .orElse(PostMetric.builder().postId(postId).build());

                                metric.setCreatedByUserId(createdByUserId);
                                metric.setLikes((long) likes);
                                metric.setComments((long) comments);
                                Long shares = metric.getShares();
                                Long views = metric.getViews();
                                metric.setShares(shares != null ? shares : 0L);
                                metric.setViews(views != null ? views : 0L);

                                postMetricRepository.save(metric);
                        }
                } catch (Exception ex) {
                        log.warn("Post metrics sync from Mongo failed: {}", ex.getMessage());
                }
        }

        private Long queryMongoDistinctCount(String mongoUri, String collection, String field) {
                try (MongoClient mongoClient = MongoClients.create(mongoUri)) {
                        MongoDatabase database = resolveMongoDatabase(mongoClient, mongoUri);
                        if (database == null) {
                                return 0L;
                        }
                        List<String> values = database.getCollection(collection)
                                        .distinct(field, String.class)
                                        .into(new ArrayList<>());
                        return (long) values.size();
                } catch (Exception ex) {
                        log.warn("Mongo distinct query failed ({}:{}): {}", mongoUri, collection, ex.getMessage());
                        return 0L;
                }
        }

        private MongoDatabase resolveMongoDatabase(MongoClient mongoClient, String mongoUri) {
                try {
                        String afterSlash = mongoUri.substring(mongoUri.lastIndexOf('/') + 1);
                        String dbName = afterSlash.contains("?") ? afterSlash.substring(0, afterSlash.indexOf('?')) : afterSlash;
                        if (dbName.isBlank()) {
                                return null;
                        }
                        return mongoClient.getDatabase(dbName);
                } catch (Exception ex) {
                        log.warn("Could not resolve Mongo database from uri: {}", mongoUri);
                        return null;
                }
        }

        private void upsertSnapshot(MetricType metricType, Long total, Long newCount, Long activeCount, Double engagement) {
                LocalDate today = LocalDate.now();
                AnalyticsSnapshot snapshot = snapshotRepository
                                .findByMetricTypeAndSnapshotDate(metricType, today)
                                .orElse(AnalyticsSnapshot.builder()
                                                .snapshotDate(today)
                                                .metricType(metricType)
                                                .build());

                snapshot.setTotalCount(total != null ? total : 0L);
                snapshot.setNewCount(newCount != null ? newCount : 0L);
                snapshot.setActiveCount(activeCount != null ? activeCount : 0L);
                snapshot.setEngagementScore(engagement != null ? engagement : 0.0);
                snapshot.setAverageEngagement((total != null && total > 0)
                                ? snapshot.getEngagementScore() / total
                                : 0.0);
                snapshotRepository.save(snapshot);
        }

    private String escapeCsv(String value) {
        if (value == null) return "";
        if (value.contains(",") || value.contains("\"") || value.contains("\n")) {
            return "\"" + value.replace("\"", "\"\"") + "\"";
        }
        return value;
    }

        private String resolveAuthorName(
                PostMetric post,
                Map<String, String> postAuthorByPostId,
                Map<Long, String> userNameById) {
                String authorFromPost = postAuthorByPostId.get(post.getPostId());
                if (authorFromPost != null && !authorFromPost.isBlank()) {
                        return authorFromPost;
                }

                Long authorId = post.getCreatedByUserId();
                if (authorId != null) {
                        return userNameById.getOrDefault(authorId, "User #" + authorId);
                }

                return "Unknown";
        }

        private Map<String, String> resolvePostAuthorNames(List<PostMetric> posts) {
                Map<String, String> authors = new LinkedHashMap<>();
                List<String> postIds = posts.stream()
                                .map(PostMetric::getPostId)
                                .filter(Objects::nonNull)
                                .filter(id -> !id.isBlank())
                                .toList();

                if (postIds.isEmpty()) {
                        return authors;
                }

                try (MongoClient mongoClient = MongoClients.create(postMongoUri)) {
                        MongoDatabase database = resolveMongoDatabase(mongoClient, postMongoUri);
                        if (database == null) {
                                return authors;
                        }

                        for (Document doc : database.getCollection("posts").find(Filters.in("_id", postIds))) {
                                String postId = String.valueOf(doc.get("_id"));
                                String fullName = doc.getString("fullName");
                                String username = doc.getString("username");
                                String display = (fullName != null && !fullName.isBlank())
                                                ? fullName
                                                : ((username != null && !username.isBlank()) ? username : null);

                                if (postId != null && !postId.isBlank() && display != null) {
                                        authors.put(postId, display);
                                }
                        }
                } catch (Exception ex) {
                        log.warn("Resolving post author names from Mongo failed: {}", ex.getMessage());
                }

                return authors;
        }

        private Map<Long, String> loadUserDisplayNamesFromSourceDb() {
                Map<Long, String> names = new LinkedHashMap<>();
                String sql = "SELECT id, COALESCE(NULLIF(full_name, ''), NULLIF(username, ''), NULLIF(email, ''), ('User #' || id::text)) AS display_name FROM users";

                try (Connection connection = DriverManager.getConnection(userDbUrl, postgresUser, postgresPassword);
                         PreparedStatement statement = connection.prepareStatement(sql);
                         ResultSet rs = statement.executeQuery()) {

                        while (rs.next()) {
                                Long id = rs.getLong("id");
                                String displayName = rs.getString("display_name");
                                if (id != null && displayName != null && !displayName.isBlank()) {
                                        names.put(id, displayName);
                                }
                        }
                } catch (Exception ex) {
                        log.warn("Loading user display names from source DB failed: {}", ex.getMessage());
                }

                return names;
        }

        private List<Map<String, Object>> queryPgRows(String jdbcUrl, String sql) {
                List<Map<String, Object>> rows = new ArrayList<>();
                try (Connection connection = DriverManager.getConnection(jdbcUrl, postgresUser, postgresPassword);
                         PreparedStatement statement = connection.prepareStatement(sql);
                         ResultSet rs = statement.executeQuery()) {

                        while (rs.next()) {
                                Map<String, Object> row = new LinkedHashMap<>();
                                int columnCount = rs.getMetaData().getColumnCount();
                                for (int i = 1; i <= columnCount; i++) {
                                        row.put(rs.getMetaData().getColumnLabel(i), rs.getObject(i));
                                }
                                rows.add(row);
                        }
                } catch (Exception ex) {
                        log.warn("PostgreSQL rows query failed ({}): {}", jdbcUrl, ex.getMessage());
                }
                return rows;
        }
}
