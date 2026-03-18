import { useState } from "react";
import type { Job } from "../../types";
import { formatDate } from "../../utils/formatDate";

interface JobCardProps {
  job: Job;
  currentUserId?: number;
  hasApplied?: boolean;
  onApply?: (job: Job) => void;
  onEdit?: (job: Job) => void;
  onToggleStatus?: (jobId: number, action: "close" | "open") => void;
  onViewApplications?: (job: Job) => void;
  onDelete?: (jobId: number) => Promise<void>;
}

export default function JobCard({
  job,
  currentUserId,
  hasApplied,
  onApply,
  onEdit,
  onToggleStatus,
  onViewApplications,
  onDelete,
}: JobCardProps) {
  const [isLoading, setIsLoading] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const isOwner = String(currentUserId) === String(job.postedBy);
  const isClosed = job.status === "CLOSED";

  return (
    <div className="glass-panel rounded-2xl p-5 transition-shadow hover:shadow-md">
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <div className="flex items-center gap-2">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">{job.title}</h3>
            <span
              className={`rounded-full px-2 py-1 text-xs font-medium ${
                isClosed
                  ? "bg-red-50 text-red-700"
                  : "bg-green-50 text-green-700"
              }`}
            >
              {job.status || "OPEN"}
            </span>
          </div>
          <p className="mt-1 text-sm ink-muted">{job.company}</p>
        </div>
        {job.type && (
          <span className="rounded-full bg-primary-50 px-3 py-1 text-xs font-medium text-primary-700">
            {job.type.replace("_", " ")}
          </span>
        )}
      </div>
      <div className="mt-3 flex flex-wrap gap-4 text-sm ink-muted">
        {job.location && (
          <span className="flex items-center gap-1">
            <svg
              className="h-4 w-4"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2}
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
              />
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
              />
            </svg>
            {job.location}
          </span>
        )}
        <span className="flex items-center gap-1">
          <svg
            className="h-4 w-4"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
            />
          </svg>
          {formatDate(job.createdAt)}
        </span>
        {isOwner && (
          <span className="flex items-center gap-1 font-medium text-primary-600">
            <svg
              className="h-4 w-4"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2}
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              />
            </svg>
            Posted by you
          </span>
        )}
        <span className="flex items-center gap-1 font-medium text-blue-600">
          <svg
            className="h-4 w-4"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M17 20h5v-2a3 3 0 00-5.856-1.487M15 10a3 3 0 11-6 0 3 3 0 016 0zM6 20a9 9 0 0118 0v2h2v-2a11 11 0 10-20 0v2h2v-2z"
            />
          </svg>
          {job.applicationCount ?? 0} application
          {(job.applicationCount ?? 0) !== 1 ? "s" : ""}
        </span>
      </div>
      <p className="mt-3 line-clamp-2 text-sm ink-muted">
        {job.description}
      </p>
      <div className="mt-4 flex items-center justify-between gap-2">
        <span className="text-xs ink-muted">
          Posted by {job.posterName}
        </span>
        <div className="flex gap-2">
          {isOwner && (
            <>
              {onViewApplications && (job.applicationCount ?? 0) > 0 && (
                <button
                  onClick={() => onViewApplications(job)}
                  disabled={isLoading}
                  className="rounded-lg bg-blue-50 px-3 py-2 text-sm font-medium text-blue-600 hover:bg-blue-100 disabled:opacity-50"
                >
                  View Apps
                </button>
              )}
              {onEdit && (
                <button
                  onClick={() => onEdit(job)}
                  disabled={isLoading || isClosed}
                  className="rounded-lg bg-white/70 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-white dark:bg-white/10 dark:text-gray-200 dark:hover:bg-white/15 disabled:opacity-50"
                  title={isClosed ? "Cannot edit closed jobs" : ""}
                >
                  Edit
                </button>
              )}
              {onToggleStatus && (
                <button
                  onClick={async () => {
                    setIsLoading(true);
                    try {
                      await onToggleStatus(job.id, isClosed ? "open" : "close");
                    } finally {
                      setIsLoading(false);
                    }
                  }}
                  disabled={isLoading}
                  className={`rounded-lg px-3 py-2 text-sm font-medium disabled:opacity-50 ${
                    isClosed
                      ? "bg-green-50 text-green-600 hover:bg-green-100"
                      : "bg-yellow-50 text-yellow-600 hover:bg-yellow-100"
                  }`}
                >
                  {isClosed ? "Reopen" : "Close"}
                </button>
              )}
              {onDelete && (
                <button
                  onClick={() => setShowDeleteConfirm(true)}
                  disabled={isLoading}
                  className="rounded-lg bg-red-50 px-3 py-2 text-sm font-medium text-red-600 hover:bg-red-100 disabled:opacity-50"
                >
                  Delete
                </button>
              )}
            </>
          )}
          {!isOwner &&
            onApply &&
            (hasApplied ? (
              <span className="rounded-lg bg-green-50 px-4 py-2 text-sm font-medium text-green-600">
                ✓ Already Applied
              </span>
            ) : (
              <button
                onClick={() => onApply(job)}
                disabled={isLoading || isClosed}
                className="rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white hover:bg-primary-700 disabled:opacity-50"
                title={isClosed ? "This job posting is closed" : ""}
              >
                Apply
              </button>
            ))}
        </div>
      </div>

      {/* Delete Confirmation Modal */}
      {showDeleteConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/45 p-4 backdrop-blur-sm">
          <div className="glass-panel w-full max-w-sm rounded-2xl p-6">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
              Delete Job Post?
            </h3>
            <p className="mt-2 text-sm ink-muted">
              This action cannot be undone. All applications for this job will
              also be deleted.
            </p>
            <div className="mt-6 flex justify-end gap-3">
              <button
                onClick={() => setShowDeleteConfirm(false)}
                disabled={isLoading}
                className="rounded-lg border subtle-border px-4 py-2 text-sm font-medium ink-muted hover:bg-white/70 dark:hover:bg-white/10 disabled:opacity-50"
              >
                Cancel
              </button>
              <button
                onClick={async () => {
                  setIsLoading(true);
                  try {
                    await onDelete?.(job.id);
                    setShowDeleteConfirm(false);
                  } finally {
                    setIsLoading(false);
                  }
                }}
                disabled={isLoading}
                className="rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-50"
              >
                {isLoading ? "Deleting..." : "Delete Job"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
