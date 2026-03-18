import type { NotificationResponse } from "../../types";
import { formatRelativeTime } from "../../utils/formatDate";

interface NotificationItemProps {
  notification: NotificationResponse;
  onMarkRead?: (id: string) => void;
  onDelete?: (id: string) => void;
}

const typeIcons: Record<string, string> = {
  POST_LIKED: "❤️",
  COMMENT: "💬",
  MENTORSHIP_REQUEST: "🤝",
  JOB_APPLICATION: "💼",
  EVENT_CREATED: "📅",
  EVENT_RSVP: "✅",
  SYSTEM: "🔔",
};

export default function NotificationItem({
  notification,
  onMarkRead,
  onDelete,
}: NotificationItemProps) {
  return (
    <div
      className={`flex items-start gap-3 rounded-xl border p-4 transition-colors ${
        notification.read
          ? "subtle-border bg-white/70 dark:bg-white/5"
          : "border-primary-300/50 bg-primary-500/10 dark:bg-primary-500/20"
      }`}
    >
      <span className="text-xl">{typeIcons[notification.type] || "🔔"}</span>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-gray-900 dark:text-white">
          {notification.title}
        </p>
        <p className="mt-0.5 text-sm ink-muted">{notification.message}</p>
        <p className="mt-1 text-xs ink-muted">
          {formatRelativeTime(notification.createdAt)}
        </p>
      </div>
      <div className="flex flex-shrink-0 gap-1">
        {!notification.read && onMarkRead && (
          <button
            onClick={() => onMarkRead(notification.id)}
            className="rounded p-1 text-xs text-primary-600 hover:bg-primary-50"
            title="Mark as read"
          >
            ✓
          </button>
        )}
        {onDelete && (
          <button
            onClick={() => onDelete(notification.id)}
            className="rounded p-1 text-xs ink-muted hover:bg-white/70 hover:text-red-500 dark:hover:bg-white/10"
            title="Delete"
          >
            ✕
          </button>
        )}
      </div>
    </div>
  );
}
