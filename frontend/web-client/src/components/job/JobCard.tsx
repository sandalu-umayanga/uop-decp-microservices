import { useState } from "react";
import type { Job } from "../../types";
import { formatDate } from "../../utils/formatDate";

interface JobCardProps {
  job: Job;
  currentUserId?: number;
  onApply?: (job: Job) => void;
  onEdit?: (job: Job) => void;
  onToggleStatus?: (jobId: number, action: "close" | "open") => void;
  onViewApplications?: (job: Job) => void;
}

export default function JobCard({
  job,
  currentUserId,
  onApply,
  onEdit,
  onToggleStatus,
  onViewApplications,
}: JobCardProps) {
  const [isLoading, setIsLoading] = useState(false);
  const isOwner = String(currentUserId) === String(job.postedBy);
  const isClosed = job.status === "CLOSED";

  return (
    <div className="rounded-xl border border-gray-200 bg-white p-5 shadow-sm transition-shadow hover:shadow-md">
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <div className="flex items-center gap-2">
            <h3 className="text-lg font-semibold text-gray-900">{job.title}</h3>
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
          <p className="mt-1 text-sm text-gray-600">{job.company}</p>
        </div>
        {job.type && (
          <span className="rounded-full bg-primary-50 px-3 py-1 text-xs font-medium text-primary-700">
            {job.type.replace("_", " ")}
          </span>
        )}
      </div>
      <div className="mt-3 flex flex-wrap gap-4 text-sm text-gray-500">
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
            📊 {job.applicationCount ?? 0} application
            {(job.applicationCount ?? 0) !== 1 ? "s" : ""}
          </span>
        )}
      </div>
      <p className="mt-3 line-clamp-2 text-sm text-gray-600">
        {job.description}
      </p>
      <div className="mt-4 flex items-center justify-between gap-2">
        <span className="text-xs text-gray-400">
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
                  className="rounded-lg bg-gray-100 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-200 disabled:opacity-50"
                  title={isClosed ? "Cannot edit closed jobs" : ""}
                >
                  Edit
                </button>
              )}
              {onToggleStatus && (
                <button
                  onClick={async () => {
                    setIsLoading(true);
                    await onToggleStatus(
                      job.id,
                      isClosed ? "open" : "close"
                    );
                    setIsLoading(false);
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
            </>
          )}
          {!isOwner && onApply && (
            <button
              onClick={() => onApply(job)}
              disabled={isLoading || isClosed}
              className="rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white hover:bg-primary-700 disabled:opacity-50"
              title={isClosed ? "This job posting is closed" : ""}
            >
              Apply
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
