import { useState } from "react";
import type { Job } from "../../types";
import { useAuth } from "../../context/AuthContext";
import { jobService } from "../../services/job";

interface JobApplicationModalProps {
  open: boolean;
  job: Job | null;
  onClose: () => void;
  onApplied: () => void;
}

export default function JobApplicationModal({
  open,
  job,
  onClose,
  onApplied,
}: JobApplicationModalProps) {
  const { user } = useAuth();
  const [whyInterested, setWhyInterested] = useState("");
  const [resumeUrl, setResumeUrl] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");

  if (!open || !job || !user) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!whyInterested.trim()) return;
    setSubmitting(true);
    setError("");
    try {
      await jobService.apply(job.id, {
        userId: String(user.id),
        applicantName: user.fullName,
        whyInterested: whyInterested.trim(),
        resumeUrl: resumeUrl.trim() || undefined,
      });
      setWhyInterested("");
      setResumeUrl("");
      onApplied();
      onClose();
    } catch (err: any) {
      setError(err.response?.data?.message || "Failed to apply");
    }
    setSubmitting(false);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/45 p-4 backdrop-blur-sm">
      <div className="glass-panel w-full max-w-lg rounded-2xl p-6">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
            Apply for {job.title}
          </h3>
          <button
            onClick={onClose}
            className="ink-muted hover:text-gray-800 dark:hover:text-gray-100"
          >
            ✕
          </button>
        </div>
        <p className="mt-1 text-sm ink-muted">{job.company}</p>
        <form onSubmit={handleSubmit} className="mt-4 space-y-4">
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-200">
              Why are you interested in this position? *
            </label>
            <textarea
              value={whyInterested}
              onChange={(e) => setWhyInterested(e.target.value)}
              rows={5}
              className="w-full rounded-xl border subtle-border bg-white/80 p-3 text-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
              placeholder="Tell us why you're a great fit..."
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-200">
              Resume URL
            </label>
            <input
              value={resumeUrl}
              onChange={(e) => setResumeUrl(e.target.value)}
              className="w-full rounded-xl border subtle-border bg-white/80 px-3 py-2 text-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
              placeholder="https://drive.google.com/..."
            />
          </div>
          {error && <p className="text-sm text-red-500">{error}</p>}
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
              disabled={!whyInterested.trim() || submitting}
              className="rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white hover:bg-primary-700 disabled:opacity-50"
            >
              {submitting ? "Submitting..." : "Submit Application"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
