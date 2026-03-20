import { useState, useEffect } from "react";
import { useAuth } from "../context/AuthContext";
import { analyticsService } from "../services/analytics";
import type { AnalyticsOverview } from "../types";
import LoadingSpinner from "../components/common/LoadingSpinner";
import ErrorAlert from "../components/common/ErrorAlert";

function toTitle(key: string) {
  return key.replace(/([A-Z])/g, " $1").trim();
}

function shouldHideMetric(section: string, key: string) {
  const normalized = key.trim();

  if (
    normalized === "activeUsersToday" ||
    normalized === "activeUsersThisWeek" ||
    normalized === "activeUsersThisMonth"
  ) {
    return true;
  }

  if (section === "posts") {
    return (
      normalized === "averageViewsPerPost" || normalized === "engagementTrend"
    );
  }

  if (section === "users" && normalized === "mostActiveUsers") {
    return true;
  }
  if (
    section === "users" &&
    (normalized === "studentCount" ||
      normalized === "alumniCount" ||
      normalized === "adminCount")
  ) {
    return true;
  }

  return false;
}

function renderPieChart(
  title: string,
  segments: { label: string; value: number; color: string }[],
  centerLabel?: string,
) {
  const safeSegments = segments.filter((s) => s.value > 0);
  const total = safeSegments.reduce((sum, s) => sum + s.value, 0);

  if (total <= 0) {
    return (
      <div className="rounded-md border border-gray-200 bg-gray-50 p-4">
        <h3 className="mb-2 text-sm font-semibold text-gray-700">{title}</h3>
        <p className="text-sm text-gray-400">No data available.</p>
      </div>
    );
  }

  const gradientStops: string[] = [];
  let start = 0;
  for (const segment of safeSegments) {
    const angle = (segment.value / total) * 360;
    const end = start + angle;
    gradientStops.push(
      `${segment.color} ${start.toFixed(2)}deg ${end.toFixed(2)}deg`,
    );
    start = end;
  }

  return (
    <div className="rounded-md border border-gray-200 bg-gray-50 p-4">
      <h3 className="mb-3 text-sm font-semibold text-gray-700">{title}</h3>
      <div className="flex flex-col items-center gap-4 sm:flex-row sm:items-start">
        <div className="relative h-40 w-40">
          <div
            className="h-40 w-40 rounded-full"
            style={{
              background: `conic-gradient(${gradientStops.join(", ")})`,
            }}
          />
          <div className="absolute inset-6 flex items-center justify-center rounded-full bg-white text-center">
            <span className="text-sm font-semibold text-gray-700">
              {centerLabel ?? `Total ${total}`}
            </span>
          </div>
        </div>

        <div className="w-full space-y-2 text-sm">
          {safeSegments.map((segment) => {
            const percent = (segment.value / total) * 100;
            return (
              <div
                key={segment.label}
                className="flex items-center justify-between rounded-md bg-white px-3 py-2"
              >
                <div className="flex items-center gap-2">
                  <span
                    className="inline-block h-2.5 w-2.5 rounded-full"
                    style={{ backgroundColor: segment.color }}
                  />
                  <span className="text-gray-700">{segment.label}</span>
                </div>
                <span className="font-medium text-gray-900">
                  {segment.value.toLocaleString()} ({percent.toFixed(1)}%)
                </span>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

function renderTopFiveGraph(
  section: "posts" | "jobs" | "events",
  rows: Record<string, unknown>[],
) {
  const config =
    section === "posts"
      ? {
          labelKey: "authorName",
          valueKey: "totalInteractions",
          title: "Top 5 By Interactions",
          valueLabel: "Interactions",
          barColor: "bg-indigo-500",
        }
      : section === "jobs"
        ? {
            labelKey: "title",
            valueKey: "applications",
            title: "Top 5 By Applications",
            valueLabel: "Applications",
            barColor: "bg-emerald-500",
          }
        : {
            labelKey: "title",
            valueKey: "rsvpCount",
            title: "Top 5 By Attendees",
            valueLabel: "Attendees",
            barColor: "bg-amber-500",
          };

  const chartRows = rows
    .map((row, idx) => {
      const likes = Number.parseFloat(String(row.likes ?? 0));
      const comments = Number.parseFloat(String(row.comments ?? 0));
      const derivedInteractions =
        section === "posts" &&
        Number.isFinite(likes) &&
        Number.isFinite(comments)
          ? likes + comments
          : null;
      const raw =
        derivedInteractions ?? row[config.valueKey] ?? row.totalEngagement ?? 0;
      const numeric =
        typeof raw === "number" ? raw : Number.parseFloat(String(raw ?? 0));
      return {
        rank: idx + 1,
        label: String(row[config.labelKey] ?? `Item ${idx + 1}`),
        value: Number.isFinite(numeric) ? numeric : 0,
      };
    })
    .slice(0, 5);

  const maxValue = chartRows.reduce((max, r) => Math.max(max, r.value), 0);

  return (
    <div className="rounded-md border border-gray-200 bg-gray-50 p-3">
      <h3 className="mb-3 text-sm font-semibold text-gray-700">
        {config.title}
      </h3>
      <div className="space-y-2">
        {chartRows.map((row) => {
          const widthPct = maxValue > 0 ? (row.value / maxValue) * 100 : 0;
          return (
            <div key={`${row.rank}-${row.label}`}>
              <div className="mb-1 flex items-center justify-between gap-3 text-xs text-gray-700">
                <span className="truncate">
                  {row.rank}. {row.label}
                </span>
                <span className="font-semibold">
                  {row.value.toLocaleString()} {config.valueLabel}
                </span>
              </div>
              <div className="h-2.5 w-full rounded-full bg-gray-200">
                <div
                  className={`h-2.5 rounded-full ${config.barColor}`}
                  style={{ width: `${Math.max(4, Math.round(widthPct))}%` }}
                />
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function renderTopFive(section: "posts" | "jobs" | "events", value: unknown) {
  if (!Array.isArray(value) || value.length === 0) {
    return <span className="text-gray-400">No records</span>;
  }

  const rows = value
    .filter((item) => typeof item === "object" && item !== null)
    .slice(0, 5) as Record<string, unknown>[];

  if (rows.length === 0) {
    return <span className="text-gray-400">No records</span>;
  }

  const itemSummary = (
    sectionName: "posts" | "jobs" | "events",
    row: Record<string, unknown>,
  ) => {
    if (sectionName === "posts") {
      return [
        { label: "Post By", value: String(row.authorName ?? "-") },
        { label: "Likes", value: String(row.likes ?? "0") },
        { label: "Comments", value: String(row.comments ?? "0") },
      ];
    }

    if (sectionName === "jobs") {
      return [
        { label: "Job Title", value: String(row.title ?? "-") },
        { label: "Applications", value: String(row.applications ?? "0") },
      ];
    }

    return [
      { label: "Event Title", value: String(row.title ?? "-") },
      { label: "Attendees", value: String(row.rsvpCount ?? "0") },
    ];
  };

  return (
    <div className="space-y-3">
      {renderTopFiveGraph(section, rows)}

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {rows.map((row, index) => (
          <div
            key={index}
            className="rounded-md border border-gray-200 bg-white p-3"
          >
            <div className="mb-2 flex items-center justify-between">
              <span className="text-xs font-semibold tracking-wide text-gray-500">
                Rank #{index + 1}
              </span>
            </div>
            <div className="space-y-1.5 text-sm">
              {itemSummary(section, row).map((entry) => (
                <div
                  key={entry.label}
                  className="flex items-center justify-between gap-3"
                >
                  <span className="text-gray-500">{entry.label}</span>
                  <span className="font-medium text-gray-900">
                    {entry.value}
                  </span>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function renderUsersCharts(sectionData: Record<string, unknown>) {
  const students = Number(sectionData.studentCount ?? 0);
  const alumni = Number(sectionData.alumniCount ?? 0);
  const admins = Number(sectionData.adminCount ?? 0);

  return (
    <div className="grid gap-4 lg:grid-cols-2">
      {renderPieChart("Users By Role", [
        {
          label: "Students",
          value: Number.isFinite(students) ? students : 0,
          color: "#2563eb",
        },
        {
          label: "Alumni",
          value: Number.isFinite(alumni) ? alumni : 0,
          color: "#059669",
        },
        {
          label: "Admin",
          value: Number.isFinite(admins) ? admins : 0,
          color: "#f59e0b",
        },
      ])}
    </div>
  );
}

function renderSectionMetric(section: string, key: string, value: unknown) {
  if (section === "posts" && key === "topPostsAllTime") {
    return renderTopFive("posts", value);
  }

  if (section === "jobs" && key === "topJobsByApplications") {
    return renderTopFive("jobs", value);
  }

  if (section === "events" && key === "topEventsByRsvps") {
    return renderTopFive("events", value);
  }

  return renderValue(value);
}

function renderValue(value: unknown) {
  if (typeof value === "number") {
    return (
      <span className="font-medium text-gray-900">
        {value.toLocaleString()}
      </span>
    );
  }

  if (Array.isArray(value)) {
    if (value.length === 0) {
      return <span className="text-gray-400">No records</span>;
    }

    return (
      <div className="space-y-2 text-sm">
        {value.map((item, idx) => {
          if (typeof item === "object" && item !== null) {
            const row = Object.entries(item as Record<string, unknown>)
              .map(([k, v]) => `${toTitle(k)}: ${String(v ?? "-")}`)
              .join(" | ");
            return (
              <div
                key={idx}
                className="rounded-md bg-gray-50 px-3 py-2 text-gray-700"
              >
                {row}
              </div>
            );
          }
          return (
            <div
              key={idx}
              className="rounded-md bg-gray-50 px-3 py-2 text-gray-700"
            >
              {String(item)}
            </div>
          );
        })}
      </div>
    );
  }

  if (typeof value === "object" && value !== null) {
    const entries = Object.entries(value as Record<string, unknown>);
    if (entries.length === 0) {
      return <span className="text-gray-400">No records</span>;
    }

    return (
      <div className="space-y-1 text-sm">
        {entries.map(([k, v]) => (
          <div key={k} className="flex items-center justify-between gap-4">
            <span className="text-gray-500">{k}</span>
            <span className="font-medium text-gray-900">
              {String(v ?? "-")}
            </span>
          </div>
        ))}
      </div>
    );
  }

  return (
    <span className="font-medium text-gray-900">{String(value ?? "-")}</span>
  );
}

export default function AdminPage() {
  const { user } = useAuth();
  const [overview, setOverview] = useState<AnalyticsOverview | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [warning, setWarning] = useState("");
  const [activeSection, setActiveSection] = useState<
    "overview" | "users" | "posts" | "jobs" | "events"
  >("overview");
  const [sectionData, setSectionData] = useState<Record<
    string,
    unknown
  > | null>(null);
  const [sectionLoading, setSectionLoading] = useState(false);

  useEffect(() => {
    (async () => {
      try {
        const overviewRes = await analyticsService.getOverview();
        setOverview(overviewRes.data);
      } catch {
        setError("Failed to load analytics");
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  useEffect(() => {
    if (activeSection === "overview") {
      setSectionData(null);
      return;
    }
    const fetchers: Record<string, () => Promise<{ data: unknown }>> = {
      users: analyticsService.getUserMetrics,
      posts: analyticsService.getPostMetrics,
      jobs: analyticsService.getJobMetrics,
      events: analyticsService.getEventMetrics,
    };

    const fetchSection = fetchers[activeSection];
    if (!fetchSection) {
      setSectionData(null);
      return;
    }

    (async () => {
      try {
        setSectionLoading(true);
        const res = await fetchSection();
        setSectionData(res.data as Record<string, unknown>);
      } catch {
        setSectionData(null);
      } finally {
        setSectionLoading(false);
      }
    })();
  }, [activeSection]);

  if (user?.role !== "ADMIN") {
    return (
      <div className="flex min-h-[50vh] items-center justify-center">
        <div className="text-center">
          <h2 className="text-xl font-bold text-gray-900">Access Denied</h2>
          <p className="text-gray-500">Admin privileges required.</p>
        </div>
      </div>
    );
  }

  if (loading) return <LoadingSpinner />;
  if (error) return <ErrorAlert message={error} onClose={() => setError("")} />;

  const statCards = [
    {
      label: "Total Users",
      value: overview?.totalUsers ?? "-",
      color: "bg-blue-500",
    },
    {
      label: "Total Posts",
      value: overview?.totalPosts ?? "-",
      color: "bg-green-500",
    },
    {
      label: "Total Jobs",
      value: overview?.totalJobs ?? "-",
      color: "bg-purple-500",
    },
    {
      label: "Total Events",
      value: overview?.totalEvents ?? "-",
      color: "bg-orange-500",
    },
  ];

  const sections: { key: typeof activeSection; label: string }[] = [
    { key: "overview", label: "Overview" },
    { key: "users", label: "Users" },
    { key: "posts", label: "Posts" },
    { key: "jobs", label: "Jobs" },
    { key: "events", label: "Events" },
  ];

  return (
    <div className="mx-auto max-w-7xl px-4 py-6">
      <h1 className="mb-6 text-2xl font-bold text-gray-900">Admin Dashboard</h1>

      {warning && (
        <ErrorAlert message={warning} onClose={() => setWarning("")} />
      )}

      <div className="mb-8 grid grid-cols-2 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {statCards.map((s) => (
          <div
            key={s.label}
            className="rounded-xl bg-white p-4 shadow-sm border border-gray-200"
          >
            <div
              className={`mb-2 inline-block h-2 w-8 rounded-full ${s.color}`}
            />
            <p className="text-2xl font-bold text-gray-900">{s.value}</p>
            <p className="text-xs text-gray-500">{s.label}</p>
          </div>
        ))}
      </div>
      <div className="mb-6 flex gap-1 rounded-lg bg-gray-100 p-1">
        {sections.map((s) => (
          <button
            key={s.key}
            onClick={() => setActiveSection(s.key)}
            className={`flex-1 rounded-md px-4 py-2 text-sm font-medium transition ${
              activeSection === s.key
                ? "bg-white text-primary-700 shadow-sm"
                : "text-gray-600 hover:text-gray-900"
            }`}
          >
            {s.label}
          </button>
        ))}
      </div>

      {activeSection === "overview" && overview ? (
        <div className="rounded-xl border border-gray-200 bg-white p-6">
          <h2 className="mb-4 text-lg font-semibold text-gray-900">
            Platform Overview
          </h2>
          <div className="space-y-3">
            {[
              ["totalUsers", overview.totalUsers],
              ["totalPosts", overview.totalPosts],
              ["totalJobs", overview.totalJobs],
              ["totalEvents", overview.totalEvents],
              ["totalResearch", overview.totalResearch],
            ].map(([key, value]) => (
              <div
                key={String(key)}
                className="flex items-center justify-between border-b border-gray-100 pb-2"
              >
                <span className="text-sm text-gray-600 capitalize">
                  {String(key)
                    .replace(/([A-Z])/g, " $1")
                    .trim()}
                </span>
                <span className="font-medium text-gray-900">
                  {Number(value).toLocaleString()}
                </span>
              </div>
            ))}
          </div>
        </div>
      ) : sectionLoading ? (
        <LoadingSpinner />
      ) : sectionData ? (
        <div className="rounded-xl border border-gray-200 bg-white p-6">
          <h2 className="mb-4 text-lg font-semibold text-gray-900 capitalize">
            {activeSection} Metrics
          </h2>
          {activeSection === "users" && renderUsersCharts(sectionData)}
          <div className="space-y-3">
            {Object.entries(sectionData)
              .filter(([key]) => !shouldHideMetric(activeSection, key))
              .map(([key, val]) => (
                <div
                  key={key}
                  className="flex items-center justify-between border-b border-gray-100 pb-2"
                >
                  <span className="text-sm text-gray-600 capitalize">
                    {toTitle(key)}
                  </span>
                  <div className="max-w-[70%]">
                    {renderSectionMetric(activeSection, key, val)}
                  </div>
                </div>
              ))}
          </div>
        </div>
      ) : activeSection !== "overview" ? (
        <p className="text-center text-gray-500">No data available.</p>
      ) : null}
    </div>
  );
}
