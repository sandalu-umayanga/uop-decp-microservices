import { useState, useEffect } from "react";
import type { EventResponse, RsvpResponse, RsvpStatus } from "../../types";
import { eventService } from "../../services/event";
import { formatDate, formatTime } from "../../utils/formatDate";
import LoadingSpinner from "../common/LoadingSpinner";

interface EventDetailModalProps {
  open: boolean;
  event: EventResponse | null;
  onClose: () => void;
  onRsvpChange?: () => void;
}

export default function EventDetailModal({
  open,
  event,
  onClose,
  onRsvpChange,
}: EventDetailModalProps) {
  const [attendees, setAttendees] = useState<RsvpResponse[]>([]);
  const [loading, setLoading] = useState(false);
  const [rsvpStatus, setRsvpStatus] = useState<RsvpStatus | "">("");
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!open || !event) return;
    setLoading(true);
    eventService
      .getAttendees(event.id)
      .then((res) => setAttendees(res.data))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [open, event]);

  if (!open || !event) return null;

  const handleRsvp = async (status: RsvpStatus) => {
    setSubmitting(true);
    try {
      await eventService.rsvp(event.id, status);
      setRsvpStatus(status);
      const res = await eventService.getAttendees(event.id);
      setAttendees(res.data);
      onRsvpChange?.();
    } catch {
      /* ignore */
    }
    setSubmitting(false);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/45 p-4 backdrop-blur-sm">
      <div className="glass-panel max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-2xl p-6">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold text-gray-900 dark:text-white">{event.title}</h2>
          <button
            onClick={onClose}
            className="ink-muted hover:text-gray-800 dark:hover:text-gray-100"
          >
            ✕
          </button>
        </div>

        <div className="mt-4 space-y-3">
          <p className="text-gray-700 dark:text-gray-200">{event.description}</p>
          <div className="grid grid-cols-2 gap-3 text-sm ink-muted">
            <p>
              <strong>Date:</strong> {formatDate(event.eventDate)}
            </p>
            <p>
              <strong>Time:</strong> {formatTime(event.startTime)} -{" "}
              {formatTime(event.endTime)}
            </p>
            <p>
              <strong>Location:</strong> {event.location}
            </p>
            <p>
              <strong>Category:</strong> {event.category}
            </p>
            <p>
              <strong>Organizer:</strong> {event.organizerName}
            </p>
            <p>
              <strong>Max Attendees:</strong>{" "}
              {event.maxAttendees || "Unlimited"}
            </p>
          </div>
        </div>

        {/* RSVP Buttons */}
        <div className="mt-6">
          <h4 className="text-sm font-semibold text-gray-700 dark:text-gray-200">Your RSVP</h4>
          <div className="mt-2 flex gap-2">
            {(["GOING", "MAYBE", "NOT_GOING"] as RsvpStatus[]).map((status) => (
              <button
                key={status}
                onClick={() => handleRsvp(status)}
                disabled={submitting}
                className={`rounded-lg px-4 py-2 text-sm font-medium transition-colors ${
                  rsvpStatus === status
                    ? "bg-primary-600 text-white"
                    : "border subtle-border text-gray-700 hover:bg-white/70 dark:text-gray-200 dark:hover:bg-white/10"
                }`}
              >
                {status.replace("_", " ")}
              </button>
            ))}
          </div>
        </div>

        {/* Attendees */}
        <div className="mt-6">
          <h4 className="text-sm font-semibold text-gray-700 dark:text-gray-200">
            Attendees ({attendees.length})
          </h4>
          {loading ? (
            <LoadingSpinner />
          ) : (
            <div className="mt-2 max-h-40 overflow-y-auto">
              {attendees.map((a) => (
                <div
                  key={`${a.eventId}-${a.userId}`}
                  className="flex items-center justify-between py-2 text-sm"
                >
                  <span className="text-gray-700 dark:text-gray-200">{a.userName}</span>
                  <span
                    className={`rounded-full px-2 py-0.5 text-xs font-medium ${
                      a.status === "GOING"
                        ? "bg-green-50 text-green-700"
                        : a.status === "MAYBE"
                          ? "bg-yellow-50 text-yellow-700"
                          : "bg-red-50 text-red-700"
                    }`}
                  >
                    {a.status}
                  </span>
                </div>
              ))}
              {attendees.length === 0 && (
                <p className="text-sm ink-muted">No attendees yet</p>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
