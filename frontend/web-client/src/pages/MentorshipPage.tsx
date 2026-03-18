import { useState, useEffect, useCallback } from "react";
import { useAuth } from "../context/AuthContext";
import { mentorshipService } from "../services/mentorship";
import type {
  MentorshipProfileResponse,
  MentorshipMatchDTO,
  MentorshipRequestResponse,
  MentorshipRelationshipResponse,
  MentorshipProfileRequest,
  MentorshipRequestRequest,
  MentorshipRole,
  Availability,
  ProposedDuration,
} from "../types";
import LoadingSpinner from "../components/common/LoadingSpinner";
import ErrorAlert from "../components/common/ErrorAlert";
import { formatDate } from "../utils/formatDate";

type Tab = "discover" | "requests" | "relationships" | "my-profile";

export default function MentorshipPage() {
  const { user } = useAuth();
  const [tab, setTab] = useState<Tab>("discover");

  const tabs: { key: Tab; label: string }[] = [
    { key: "discover", label: "Find Mentors" },
    { key: "requests", label: "Requests" },
    { key: "relationships", label: "My Mentorships" },
    { key: "my-profile", label: "My Profile" },
  ];

  const visibleTabs =
    user?.role === "STUDENT"
      ? tabs.filter((t) => t.key !== "my-profile")
      : tabs;

  return (
    <div className="mx-auto max-w-7xl px-4 py-6 sm:px-6">
      <h1 className="mb-6 text-3xl font-bold text-gray-900 dark:text-white">Mentorship</h1>

      <div className="glass-panel mb-6 flex gap-1 rounded-2xl p-1.5">
        {visibleTabs.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={`flex-1 rounded-xl px-4 py-2 text-sm font-medium transition ${
              tab === t.key
                ? "bg-primary-500/15 text-primary-700 shadow-sm dark:bg-primary-500/30 dark:text-primary-200"
                : "ink-muted hover:bg-white/60 hover:text-gray-900 dark:hover:bg-white/10 dark:hover:text-gray-100"
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      {tab === "discover" && <DiscoverTab />}
      {tab === "requests" && <RequestsTab />}
      {tab === "relationships" && <RelationshipsTab />}
      {tab === "my-profile" && <MyProfileTab />}
    </div>
  );
}

function DiscoverTab() {
  const { user } = useAuth();
  const [matches, setMatches] = useState<MentorshipMatchDTO[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [expertise, setExpertise] = useState("");

  const fetchMatches = useCallback(async () => {
    try {
      setLoading(true);
      const params = expertise ? { expertise } : undefined;
      const res = params
        ? await mentorshipService.getAdvancedMatches(params)
        : await mentorshipService.getMatches();
      setMatches(res.data);
    } catch {
      setError("Failed to load mentors");
    } finally {
      setLoading(false);
    }
  }, [expertise]);

  useEffect(() => {
    fetchMatches();
  }, [fetchMatches]);

  const [showRequestModal, setShowRequestModal] = useState<number | null>(null);

  if (loading) return <LoadingSpinner />;
  if (error) return <ErrorAlert message={error} onClose={() => setError("")} />;

  return (
    <div>
      <div className="mb-4">
        <input
          type="text"
          placeholder="Filter by expertise..."
          value={expertise}
          onChange={(e) => setExpertise(e.target.value)}
          className="w-full max-w-md rounded-xl border subtle-border bg-white/80 px-4 py-2 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
        />
      </div>
      {matches.length === 0 ? (
        <p className="py-8 text-center ink-muted">
          No mentor matches found.
        </p>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {matches.map((m) => (
            <div
              key={m.userId}
              className="glass-panel rounded-2xl p-5"
            >
              <div className="mb-2 flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary-500/15 text-sm font-bold text-primary-700 dark:bg-primary-500/30 dark:text-primary-200">
                  {m.userName?.charAt(0)?.toUpperCase() || "M"}
                </div>
                <div>
                  <p className="font-semibold text-gray-900 dark:text-white">{m.userName}</p>
                  <p className="text-xs ink-muted">
                    {m.profile.department}
                  </p>
                </div>
              </div>
              {m.profile.bio && (
                <p className="mb-3 line-clamp-3 text-sm ink-muted">
                  {m.profile.bio}
                </p>
              )}
              <div className="mb-2 flex flex-wrap gap-1.5">
                {m.profile.expertise?.slice(0, 4).map((s: string) => (
                  <span
                    key={s}
                    className="rounded-full bg-primary-500/15 px-2 py-0.5 text-xs text-primary-700 dark:bg-primary-500/30 dark:text-primary-200"
                  >
                    {s}
                  </span>
                ))}
              </div>
              {m.commonInterests.length > 0 && (
                <p className="mb-2 text-xs text-emerald-600 dark:text-emerald-400">
                  {m.commonInterests.length} common interests
                </p>
              )}
              <div className="flex items-center justify-between">
                <span className="text-xs ink-muted">
                  Score: {m.compatibilityScore}%
                </span>
                {user?.role === "STUDENT" && (
                  <button
                    onClick={() => setShowRequestModal(m.userId)}
                    className="rounded-xl bg-gradient-to-r from-primary-600 to-emerald-600 px-3 py-1.5 text-xs font-semibold text-white shadow-sm shadow-primary-500/20 transition hover:brightness-110"
                  >
                    Request Mentorship
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {showRequestModal != null && (
        <SendRequestModal
          mentorId={showRequestModal}
          onClose={() => setShowRequestModal(null)}
          onSent={() => {
            setShowRequestModal(null);
            alert("Request sent!");
          }}
        />
      )}
    </div>
  );
}

function SendRequestModal({
  mentorId,
  onClose,
  onSent,
}: {
  mentorId: number;
  onClose: () => void;
  onSent: () => void;
}) {
  const [message, setMessage] = useState("");
  const [topics, setTopics] = useState("");
  const [duration, setDuration] = useState<ProposedDuration>("THREE_MONTHS");
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setSubmitting(true);
      const data: MentorshipRequestRequest = {
        mentorId,
        message: message.trim(),
        topics: topics
          .split(",")
          .map((t) => t.trim())
          .filter(Boolean),
        proposedDuration: duration,
      };
      await mentorshipService.sendRequest(data);
      onSent();
    } catch {
      alert("Failed to send request");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 backdrop-blur-sm"
      onClick={onClose}
    >
      <div
        className="glass-panel w-full max-w-md rounded-2xl p-6"
        onClick={(e) => e.stopPropagation()}
      >
        <h2 className="mb-4 text-lg font-bold text-gray-900 dark:text-white">
          Request Mentorship
        </h2>
        <form onSubmit={handleSubmit} className="space-y-4">
          <textarea
            placeholder="Why would you like this mentor?"
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            rows={3}
            required
            className="w-full rounded-xl border subtle-border bg-white/80 px-4 py-2 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
          />
          <input
            type="text"
            placeholder="Topics of interest (comma-separated)"
            value={topics}
            onChange={(e) => setTopics(e.target.value)}
            className="w-full rounded-xl border subtle-border bg-white/80 px-4 py-2 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
          />
          <select
            value={duration}
            onChange={(e) => setDuration(e.target.value as ProposedDuration)}
            className="w-full rounded-xl border subtle-border bg-white/80 px-4 py-2 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
          >
            <option value="ONE_MONTH">1 Month</option>
            <option value="THREE_MONTHS">3 Months</option>
            <option value="SIX_MONTHS">6 Months</option>
            <option value="ONE_YEAR">1 Year</option>
          </select>
          <div className="flex justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
              className="rounded-xl border subtle-border px-4 py-2 text-sm font-medium ink-muted hover:bg-white/70 dark:hover:bg-white/10"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={submitting}
              className="rounded-xl bg-gradient-to-r from-primary-600 to-emerald-600 px-4 py-2 text-sm font-semibold text-white shadow-sm shadow-primary-500/20 transition hover:brightness-110 disabled:opacity-50"
            >
              {submitting ? "Sending..." : "Send Request"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

function RequestsTab() {
  const [requests, setRequests] = useState<MentorshipRequestResponse[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchRequests = useCallback(async () => {
    try {
      setLoading(true);
      const res = await mentorshipService.getMyRequests();
      setRequests(res.data);
    } catch {
      /* ignore */
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchRequests();
  }, [fetchRequests]);

  const respond = async (
    id: number,
    status: string,
    rejectionReason?: string,
  ) => {
    try {
      await mentorshipService.updateRequest(id, { status, rejectionReason });
      fetchRequests();
    } catch {
      /* ignore */
    }
  };

  if (loading) return <LoadingSpinner />;

  return (
    <div className="space-y-3">
      {requests.length === 0 ? (
        <p className="py-8 text-center ink-muted">No requests.</p>
      ) : (
        requests.map((r) => (
          <div
            key={r.id}
            className="glass-panel flex items-center justify-between rounded-2xl p-4"
          >
            <div>
              <p className="font-medium text-gray-900 dark:text-white">
                {r.mentorUserName} ↔ {r.menteeUserName}
              </p>
              {r.message && (
                <p className="text-sm ink-muted">{r.message}</p>
              )}
              {r.topics.length > 0 && (
                <div className="mt-1 flex flex-wrap gap-1">
                  {r.topics.map((t: string) => (
                    <span
                      key={t}
                      className="rounded-full bg-white/70 px-2 py-0.5 text-xs ink-muted dark:bg-white/10"
                    >
                      {t}
                    </span>
                  ))}
                </div>
              )}
              <p className="mt-1 text-xs ink-muted">
                {formatDate(r.createdAt)} · {r.status} ·{" "}
                {r.proposedDuration?.replace(/_/g, " ")}
              </p>
            </div>
            {r.status === "PENDING" && (
              <div className="flex gap-2">
                <button
                  onClick={() => respond(r.id, "ACCEPTED")}
                  className="rounded-xl bg-emerald-600 px-3 py-1.5 text-xs font-semibold text-white transition hover:bg-emerald-700"
                >
                  Accept
                </button>
                <button
                  onClick={() => respond(r.id, "REJECTED", "Not available")}
                  className="rounded-xl bg-red-600 px-3 py-1.5 text-xs font-semibold text-white transition hover:bg-red-700"
                >
                  Decline
                </button>
              </div>
            )}
            {r.status !== "PENDING" && (
              <span
                className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${
                  r.status === "ACCEPTED"
                    ? "bg-green-100 text-green-700"
                    : "bg-red-100 text-red-700"
                }`}
              >
                {r.status}
              </span>
            )}
          </div>
        ))
      )}
    </div>
  );
}

function RelationshipsTab() {
  const [relationships, setRelationships] = useState<
    MentorshipRelationshipResponse[]
  >([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      try {
        const res = await mentorshipService.getRelationships();
        setRelationships(res.data);
      } catch {
        /* ignore */
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  if (loading) return <LoadingSpinner />;

  return (
    <div className="space-y-3">
      {relationships.length === 0 ? (
        <p className="py-8 text-center ink-muted">
          No active mentorships yet.
        </p>
      ) : (
        relationships.map((r) => (
          <div
            key={r.id}
            className="glass-panel rounded-2xl p-4"
          >
            <div className="flex items-center justify-between">
              <div>
                <p className="font-medium text-gray-900 dark:text-white">
                  {r.mentorUserName} ↔ {r.menteeUserName}
                </p>
                <p className="text-xs ink-muted">
                  Since {formatDate(r.startDate)} ·{" "}
                  {r.frequency?.replace(/_/g, " ")} ·{" "}
                  {r.preferredChannel?.replace(/_/g, " ")}
                </p>
              </div>
              <span
                className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${
                  r.status === "ACTIVE"
                    ? "bg-green-100 text-green-700"
                    : r.status === "PAUSED"
                      ? "bg-yellow-100 text-yellow-700"
                      : "bg-white/70 text-gray-700 dark:bg-white/10 dark:text-gray-200"
                }`}
              >
                {r.status}
              </span>
            </div>
              {r.goals && <p className="mt-2 text-sm ink-muted">{r.goals}</p>}
          </div>
        ))
      )}
    </div>
  );
}

function MyProfileTab() {
  const { user } = useAuth();
  const [profile, setProfile] = useState<MentorshipProfileResponse | null>(
    null,
  );
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState(false);
  const [form, setForm] = useState<MentorshipProfileRequest>({
    role: "MENTOR" as MentorshipRole,
    department: "",
    yearsOfExperience: 0,
    expertise: [],
    interests: [],
    bio: "",
    availability: "PART_TIME" as Availability,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
  });
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    (async () => {
      try {
        const res = await mentorshipService.getMyProfile();
        setProfile(res.data);
        setForm({
          role: res.data.role,
          department: res.data.department,
          yearsOfExperience: res.data.yearsOfExperience,
          expertise: res.data.expertise,
          interests: res.data.interests,
          bio: res.data.bio,
          availability: res.data.availability,
          timezone: res.data.timezone,
          linkedInUrl: res.data.linkedInUrl,
        });
      } catch {
        /* no profile yet */
      } finally {
        setLoading(false);
      }
    })();
  }, [user]);

  const save = async () => {
    try {
      setSaving(true);
      await mentorshipService.createProfile(form);
      setEditing(false);
      const res = await mentorshipService.getMyProfile();
      setProfile(res.data);
    } catch {
      /* ignore */
    } finally {
      setSaving(false);
    }
  };

  if (loading) return <LoadingSpinner />;

  if (!profile && !editing) {
    return (
      <div className="glass-panel rounded-2xl p-8 text-center">
        <p className="mb-4 ink-muted">
          You haven't created a mentorship profile yet.
        </p>
        <button
          onClick={() => setEditing(true)}
          className="rounded-xl bg-gradient-to-r from-primary-600 to-emerald-600 px-4 py-2 text-sm font-semibold text-white shadow-md shadow-primary-500/20 transition hover:brightness-110"
        >
          Create Profile
        </button>
      </div>
    );
  }

  if (editing) {
    return (
      <div className="glass-panel mx-auto max-w-lg rounded-2xl p-6">
        <h2 className="mb-4 text-lg font-bold text-gray-900 dark:text-white">
          {profile ? "Edit" : "Create"} Mentorship Profile
        </h2>
        <div className="space-y-4">
          <select
            value={form.role}
            onChange={(e) =>
              setForm({ ...form, role: e.target.value as MentorshipRole })
            }
            className="w-full rounded-xl border subtle-border bg-white/80 px-4 py-2 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
          >
            <option value="MENTOR">Mentor</option>
            <option value="MENTEE">Mentee</option>
          </select>
          <input
            type="text"
            placeholder="Department"
            value={form.department}
            onChange={(e) => setForm({ ...form, department: e.target.value })}
            className="w-full rounded-xl border subtle-border bg-white/80 px-4 py-2 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
          />
          <input
            type="number"
            placeholder="Years of experience"
            value={form.yearsOfExperience}
            onChange={(e) =>
              setForm({
                ...form,
                yearsOfExperience: parseInt(e.target.value) || 0,
              })
            }
            className="w-full rounded-xl border subtle-border bg-white/80 px-4 py-2 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
          />
          <textarea
            placeholder="Bio..."
            value={form.bio}
            onChange={(e) => setForm({ ...form, bio: e.target.value })}
            rows={3}
            className="w-full rounded-xl border subtle-border bg-white/80 px-4 py-2 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
          />
          <input
            type="text"
            placeholder="Expertise (comma-separated)"
            value={form.expertise.join(", ")}
            onChange={(e) =>
              setForm({
                ...form,
                expertise: e.target.value
                  .split(",")
                  .map((s) => s.trim())
                  .filter(Boolean),
              })
            }
            className="w-full rounded-xl border subtle-border bg-white/80 px-4 py-2 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
          />
          <input
            type="text"
            placeholder="Interests (comma-separated)"
            value={form.interests.join(", ")}
            onChange={(e) =>
              setForm({
                ...form,
                interests: e.target.value
                  .split(",")
                  .map((s) => s.trim())
                  .filter(Boolean),
              })
            }
            className="w-full rounded-xl border subtle-border bg-white/80 px-4 py-2 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
          />
          <select
            value={form.availability}
            onChange={(e) =>
              setForm({ ...form, availability: e.target.value as Availability })
            }
            className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:border-primary-500 focus:ring-primary-500"
          >
            <option value="FULL_TIME">Full Time</option>
            <option value="PART_TIME">Part Time</option>
            <option value="WEEKENDS_ONLY">Weekends Only</option>
          </select>
          <input
            type="url"
            placeholder="LinkedIn URL (optional)"
            value={form.linkedInUrl || ""}
            onChange={(e) =>
              setForm({ ...form, linkedInUrl: e.target.value || undefined })
            }
            className="w-full rounded-xl border subtle-border bg-white/80 px-4 py-2 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
          />
          <div className="flex justify-end gap-3">
            <button
              onClick={() => setEditing(false)}
              className="rounded-xl border subtle-border px-4 py-2 text-sm font-medium ink-muted hover:bg-white/70 dark:hover:bg-white/10"
            >
              Cancel
            </button>
            <button
              onClick={save}
              disabled={saving}
              className="rounded-xl bg-gradient-to-r from-primary-600 to-emerald-600 px-4 py-2 text-sm font-semibold text-white shadow-sm shadow-primary-500/20 transition hover:brightness-110 disabled:opacity-50"
            >
              {saving ? "Saving..." : "Save"}
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="glass-panel mx-auto max-w-lg rounded-2xl p-6">
      <div className="mb-4 flex items-center justify-between">
        <h2 className="text-lg font-bold text-gray-900 dark:text-white">
          My Mentorship Profile
        </h2>
        <button
          onClick={() => setEditing(true)}
          className="text-sm font-semibold text-primary-600 hover:text-primary-700"
        >
          Edit
        </button>
      </div>
      <div className="mb-2 flex items-center gap-2">
        <span className="rounded-full bg-primary-500/15 px-2.5 py-0.5 text-xs font-medium text-primary-700 dark:bg-primary-500/30 dark:text-primary-200">
          {profile!.role}
        </span>
        <span className="text-sm ink-muted">{profile!.department}</span>
      </div>
      <p className="mb-3 text-gray-700 dark:text-gray-200">{profile!.bio}</p>
      <div className="mb-3">
        <p className="mb-1 text-xs font-medium ink-muted">Expertise</p>
        <div className="flex flex-wrap gap-1.5">
          {profile!.expertise.map((s: string) => (
            <span
              key={s}
              className="rounded-full bg-primary-500/15 px-2 py-0.5 text-xs text-primary-700 dark:bg-primary-500/30 dark:text-primary-200"
            >
              {s}
            </span>
          ))}
        </div>
      </div>
      <div className="mb-3">
        <p className="mb-1 text-xs font-medium ink-muted">Interests</p>
        <div className="flex flex-wrap gap-1.5">
          {profile!.interests.map((s: string) => (
            <span
              key={s}
              className="rounded-full bg-white/70 px-2 py-0.5 text-xs ink-muted dark:bg-white/10"
            >
              {s}
            </span>
          ))}
        </div>
      </div>
      <div className="text-sm ink-muted">
        <p>
          {profile!.yearsOfExperience} years experience ·{" "}
          {profile!.availability?.replace(/_/g, " ")}
        </p>
        {profile!.rating > 0 && (
          <p className="mt-1">
            Rating: {profile!.rating.toFixed(1)} ({profile!.ratingCount}{" "}
            reviews)
          </p>
        )}
      </div>
    </div>
  );
}
