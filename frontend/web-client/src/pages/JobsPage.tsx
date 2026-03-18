import { useState, useEffect } from "react";
import { useAuth } from "../context/AuthContext";
import { jobService } from "../services/job";
import type { Job } from "../types";
import JobCard from "../components/job/JobCard";
import JobApplicationModal from "../components/job/JobApplicationModal";
import LoadingSpinner from "../components/common/LoadingSpinner";
import ErrorAlert from "../components/common/ErrorAlert";

export default function JobsPage() {
  const { user } = useAuth();
  const [jobs, setJobs] = useState<Job[]>([]);
  const [filtered, setFiltered] = useState<Job[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [search, setSearch] = useState("");
  const [typeFilter, setTypeFilter] = useState("");
  const [selectedJob, setSelectedJob] = useState<Job | null>(null);
  const [showApplyModal, setShowApplyModal] = useState(false);
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [showEditForm, setShowEditForm] = useState(false);
  const [showApplications, setShowApplications] = useState(false);
  const [applications, setApplications] = useState<any[]>([]);
  const [loadingApps, setLoadingApps] = useState(false);
  const [userAppliedJobIds, setUserAppliedJobIds] = useState<number[]>([]);

  // Create job fields
  const [newTitle, setNewTitle] = useState("");
  const [newCompany, setNewCompany] = useState("");
  const [newLocation, setNewLocation] = useState("");
  const [newType, setNewType] = useState("FULL_TIME");
  const [newDescription, setNewDescription] = useState("");
  const [creating, setCreating] = useState(false);

  useEffect(() => {
    loadJobs();
    if (user?.id) {
      loadUserApplications();
    }
  }, [user?.id]);

  useEffect(() => {
    let result = jobs;
    if (search.trim()) {
      const q = search.toLowerCase();
      result = result.filter(
        (j) =>
          j.title.toLowerCase().includes(q) ||
          j.company.toLowerCase().includes(q),
      );
    }
    if (typeFilter) {
      result = result.filter((j) => j.type === typeFilter);
    }
    setFiltered(result);
  }, [jobs, search, typeFilter]);

  const loadJobs = async () => {
    setLoading(true);
    setError("");
    try {
      const res = await jobService.getAll();
      setJobs(res.data);
    } catch {
      setError("Failed to load jobs");
    }
    setLoading(false);
  };

  const loadUserApplications = async () => {
    if (!user?.id) return;
    try {
      const res = await jobService.getUserApplications(String(user.id));
      const appliedJobIds = res.data.map((app: any) => app.jobId);
      setUserAppliedJobIds(appliedJobIds);
    } catch (err: any) {
      console.error("Failed to load user applications:", err);
    }
  };

  const handleApply = (job: Job) => {
    setSelectedJob(job);
    setShowApplyModal(true);
  };

  const handleEdit = (job: Job) => {
    setSelectedJob(job);
    setNewTitle(job.title);
    setNewCompany(job.company);
    setNewLocation(job.location);
    setNewType(job.type);
    setNewDescription(job.description);
    setShowEditForm(true);
  };

  const handleSaveEdit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedJob || !newTitle.trim() || !newCompany.trim()) return;
    setCreating(true);
    try {
      await jobService.update(selectedJob.id, {
        title: newTitle.trim(),
        company: newCompany.trim(),
        location: newLocation.trim(),
        type: newType,
        description: newDescription.trim(),
      });
      setShowEditForm(false);
      setSelectedJob(null);
      loadJobs();
    } catch (err: any) {
      const errorMsg = err.response?.data?.message || "Failed to update job";
      setError(errorMsg);
      console.error("Job update error:", err);
    }
    setCreating(false);
  };

  const handleToggleStatus = async (
    jobId: number,
    action: "close" | "open",
  ) => {
    try {
      const updated = await jobService.toggleStatus(jobId, action);
      setJobs(jobs.map((j) => (j.id === jobId ? updated.data : j)));
      setSelectedJob(updated.data);
    } catch (err: any) {
      const errorMsg =
        err.response?.data?.message || "Failed to update job status";
      setError(errorMsg);
      console.error("Job status update error:", err);
    }
  };

  const handleViewApplications = async (job: Job) => {
    setSelectedJob(job);
    setLoadingApps(true);
    try {
      const res = await jobService.getApplications(job.id);
      setApplications(res.data);
      setShowApplications(true);
    } catch {
      setError("Failed to load applications");
    }
    setLoadingApps(false);
  };

  const handleDeleteJob = async (jobId: number) => {
    try {
      await jobService.delete(jobId);
      setJobs(jobs.filter((j) => j.id !== jobId));
      setSelectedJob(null);
      loadJobs();
    } catch (err: any) {
      const errorMsg =
        err.response?.data?.message ||
        err.response?.data?.error ||
        err.message ||
        "Failed to delete job";
      setError(errorMsg);
      console.error("Job deletion error:", {
        status: err.response?.status,
        message: errorMsg,
        data: err.response?.data,
        headers: err.config?.headers,
      });
    }
  };

  const handleCreateJob = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTitle.trim() || !newCompany.trim()) return;
    setCreating(true);
    try {
      await jobService.create({
        title: newTitle.trim(),
        company: newCompany.trim(),
        location: newLocation.trim(),
        type: newType,
        description: newDescription.trim(),
        postedBy: String(user?.id),
        posterName: user?.fullName || "",
      });
      setShowCreateForm(false);
      setNewTitle("");
      setNewCompany("");
      setNewLocation("");
      setNewDescription("");
      loadJobs();
    } catch {
      setError("Failed to create job");
    }
    setCreating(false);
  };

  if (loading) return <LoadingSpinner />;

  return (
    <div className="mx-auto max-w-7xl px-4 py-6 sm:px-6">
      <div className="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Job Board</h1>
        {(user?.role === "ALUMNI" || user?.role === "ADMIN") && (
          <button
            onClick={() => setShowCreateForm(!showCreateForm)}
            className="rounded-xl bg-gradient-to-r from-primary-600 to-emerald-600 px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-primary-500/20 transition hover:brightness-110"
          >
            + Post a Job
          </button>
        )}
      </div>

      {/* Create Job Form */}
      {showCreateForm && (
        <div className="glass-panel stagger-in mb-6 rounded-2xl p-5">
          <h3 className="mb-4 text-xl font-semibold text-gray-900 dark:text-white">Post New Job</h3>
          <form
            onSubmit={handleCreateJob}
            className="grid gap-4 sm:grid-cols-2"
          >
            <input
              value={newTitle}
              onChange={(e) => setNewTitle(e.target.value)}
              placeholder="Job Title *"
              required
              className="rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
            />
            <input
              value={newCompany}
              onChange={(e) => setNewCompany(e.target.value)}
              placeholder="Company *"
              required
              className="rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
            />
            <input
              value={newLocation}
              onChange={(e) => setNewLocation(e.target.value)}
              placeholder="Location"
              className="rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
            />
            <select
              value={newType}
              onChange={(e) => setNewType(e.target.value)}
              className="rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
            >
              <option value="FULL_TIME">Full Time</option>
              <option value="PART_TIME">Part Time</option>
              <option value="INTERNSHIP">Internship</option>
              <option value="CONTRACT">Contract</option>
            </select>
            <textarea
              value={newDescription}
              onChange={(e) => setNewDescription(e.target.value)}
              placeholder="Description"
              rows={3}
              className="sm:col-span-2 rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
            />
            <div className="sm:col-span-2 flex justify-end gap-3">
              <button
                type="button"
                onClick={() => setShowCreateForm(false)}
                className="rounded-xl border subtle-border px-4 py-2 text-sm font-medium ink-muted hover:bg-white/70 dark:hover:bg-white/10"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={creating}
                className="rounded-xl bg-gradient-to-r from-primary-600 to-emerald-600 px-4 py-2 text-sm font-semibold text-white shadow-md shadow-primary-500/20 transition hover:brightness-110 disabled:opacity-50"
              >
                {creating ? "Posting..." : "Post Job"}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Filters */}
      <div className="mb-6 flex flex-col gap-3 sm:flex-row">
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search jobs by title or company..."
          className="flex-1 rounded-xl border subtle-border bg-white/80 px-4 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
        />
        <select
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value)}
          className="rounded-xl border subtle-border bg-white/80 px-4 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
        >
          <option value="">All Types</option>
          <option value="FULL_TIME">Full Time</option>
          <option value="PART_TIME">Part Time</option>
          <option value="INTERNSHIP">Internship</option>
          <option value="CONTRACT">Contract</option>
        </select>
      </div>

      <ErrorAlert message={error} onClose={() => setError("")} />

      {/* Jobs Grid */}
      <div className="grid gap-4 md:grid-cols-2">
        {filtered.length === 0 ? (
          <div className="glass-panel md:col-span-2 rounded-2xl p-8 text-center ink-muted">
            No jobs found
          </div>
        ) : (
          filtered.map((job) => (
            <JobCard
              key={job.id}
              job={job}
              currentUserId={user?.id}
              hasApplied={userAppliedJobIds.includes(job.id)}
              onApply={user?.role === "STUDENT" ? handleApply : undefined}
              onEdit={
                user?.role === "ALUMNI" || user?.role === "ADMIN"
                  ? handleEdit
                  : undefined
              }
              onToggleStatus={
                user?.role === "ALUMNI" || user?.role === "ADMIN"
                  ? handleToggleStatus
                  : undefined
              }
              onViewApplications={
                user?.role === "ALUMNI" || user?.role === "ADMIN"
                  ? handleViewApplications
                  : undefined
              }
              onDelete={
                user?.role === "ALUMNI" || user?.role === "ADMIN"
                  ? handleDeleteJob
                  : undefined
              }
            />
          ))
        )}
      </div>

      <JobApplicationModal
        open={showApplyModal}
        job={selectedJob}
        onClose={() => setShowApplyModal(false)}
        onApplied={() => {
          if (selectedJob) {
            setUserAppliedJobIds([...userAppliedJobIds, selectedJob.id]);
          }
        }}
      />

      {/* Edit Job Modal */}
      {showEditForm && selectedJob && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/45 p-4 backdrop-blur-sm">
          <div className="glass-panel w-full max-w-2xl rounded-2xl p-6">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                Edit Job: {selectedJob.title}
              </h3>
              <button
                onClick={() => setShowEditForm(false)}
                className="ink-muted hover:text-gray-800 dark:hover:text-gray-100"
              >
                ✕
              </button>
            </div>
            <form
              onSubmit={handleSaveEdit}
              className="mt-4 grid gap-4 sm:grid-cols-2"
            >
              <input
                value={newTitle}
                onChange={(e) => setNewTitle(e.target.value)}
                placeholder="Job Title *"
                required
                className="rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
              />
              <input
                value={newCompany}
                onChange={(e) => setNewCompany(e.target.value)}
                placeholder="Company *"
                required
                className="rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
              />
              <input
                value={newLocation}
                onChange={(e) => setNewLocation(e.target.value)}
                placeholder="Location"
                className="rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
              />
              <select
                value={newType}
                onChange={(e) => setNewType(e.target.value)}
                className="rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
              >
                <option value="FULL_TIME">Full Time</option>
                <option value="PART_TIME">Part Time</option>
                <option value="INTERNSHIP">Internship</option>
                <option value="CONTRACT">Contract</option>
              </select>
              <textarea
                value={newDescription}
                onChange={(e) => setNewDescription(e.target.value)}
                placeholder="Description"
                rows={3}
                className="sm:col-span-2 rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
              />
              <div className="sm:col-span-2 flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setShowEditForm(false)}
                  className="rounded-xl border subtle-border px-4 py-2 text-sm font-medium ink-muted hover:bg-white/70 dark:hover:bg-white/10"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={creating}
                  className="rounded-xl bg-gradient-to-r from-primary-600 to-emerald-600 px-4 py-2 text-sm font-semibold text-white shadow-md shadow-primary-500/20 transition hover:brightness-110 disabled:opacity-50"
                >
                  {creating ? "Saving..." : "Save Changes"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* View Applications Modal */}
      {showApplications && selectedJob && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/45 p-4 backdrop-blur-sm">
          <div className="glass-panel max-h-[90vh] w-full max-w-3xl overflow-y-auto rounded-2xl p-6">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                Applications for {selectedJob.title}
              </h3>
              <button
                onClick={() => setShowApplications(false)}
                className="ink-muted hover:text-gray-800 dark:hover:text-gray-100"
              >
                ✕
              </button>
            </div>
            {loadingApps ? (
              <div className="py-8 text-center ink-muted">Loading...</div>
            ) : applications.length === 0 ? (
              <div className="py-8 text-center ink-muted">
                No applications yet
              </div>
            ) : (
              <div className="space-y-3">
                {applications.map((app) => (
                  <div
                    key={app.id}
                    className="rounded-xl border subtle-border bg-white/70 p-4 dark:bg-white/5"
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <h4 className="font-semibold text-gray-900 dark:text-white">
                          {app.applicantName}
                        </h4>
                        <p className="mt-1 text-sm ink-muted">
                          {app.whyInterested}
                        </p>
                        {app.resumeUrl && (
                          <a
                            href={app.resumeUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="mt-2 inline-block text-sm font-medium text-primary-600 hover:text-primary-700"
                          >
                            View Resume →
                          </a>
                        )}
                      </div>
                      <div className="text-right text-xs ink-muted">
                        {new Date(app.appliedAt).toLocaleDateString()}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
