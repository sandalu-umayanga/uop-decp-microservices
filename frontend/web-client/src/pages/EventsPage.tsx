import { useState, useEffect } from "react";
import { useAuth } from "../context/AuthContext";
import { eventService } from "../services/event";
import type { EventResponse, EventCategory, EventRequest } from "../types";
import EventCard from "../components/event/EventCard";
import EventDetailModal from "../components/event/EventDetailModal";
import LoadingSpinner from "../components/common/LoadingSpinner";
import ErrorAlert from "../components/common/ErrorAlert";

export default function EventsPage() {
  const { user } = useAuth();
  const [events, setEvents] = useState<EventResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [selectedEvent, setSelectedEvent] = useState<EventResponse | null>(
    null,
  );
  const [showDetail, setShowDetail] = useState(false);
  const [showCreate, setShowCreate] = useState(false);
  const [creating, setCreating] = useState(false);
  const [categoryFilter, setCategoryFilter] = useState("");

  // Create form
  const [form, setForm] = useState<EventRequest>({
    title: "",
    description: "",
    location: "",
    eventDate: "",
    startTime: "",
    endTime: "",
    category: "ACADEMIC",
    maxAttendees: 0,
  });

  useEffect(() => {
    loadEvents();
  }, []);

  const loadEvents = async () => {
    setLoading(true);
    try {
      const res = await eventService.getUpcoming();
      setEvents(res.data);
    } catch {
      setError("Failed to load events");
    }
    setLoading(false);
  };

  const filtered = categoryFilter
    ? events.filter((e) => e.category === categoryFilter)
    : events;

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    setCreating(true);
    try {
      await eventService.create(form);
      setShowCreate(false);
      setForm({
        title: "",
        description: "",
        location: "",
        eventDate: "",
        startTime: "",
        endTime: "",
        category: "ACADEMIC",
        maxAttendees: 0,
      });
      loadEvents();
    } catch {
      setError("Failed to create event");
    }
    setCreating(false);
  };

  const canCreate = user?.role === "ALUMNI" || user?.role === "ADMIN";
  const categories: EventCategory[] = [
    "ACADEMIC",
    "SOCIAL",
    "WORKSHOP",
    "NETWORKING",
    "CAREER",
    "ALUMNI",
  ];

  if (loading) return <LoadingSpinner />;

  return (
    <div className="mx-auto max-w-7xl px-4 py-6 sm:px-6">
      <div className="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Events</h1>
        {canCreate && (
          <button
            onClick={() => setShowCreate(!showCreate)}
            className="rounded-xl bg-gradient-to-r from-primary-600 to-emerald-600 px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-primary-500/20 transition hover:brightness-110"
          >
            + Create Event
          </button>
        )}
      </div>

      {/* Create Form */}
      {showCreate && (
        <div className="glass-panel stagger-in mb-6 rounded-2xl p-5">
          <h3 className="mb-4 text-xl font-semibold text-gray-900 dark:text-white">Create Event</h3>
          <form onSubmit={handleCreate} className="grid gap-4 sm:grid-cols-2">
            <input
              value={form.title}
              onChange={(e) => setForm({ ...form, title: e.target.value })}
              placeholder="Event Title *"
              required
              className="rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
            />
            <input
              value={form.location}
              onChange={(e) => setForm({ ...form, location: e.target.value })}
              placeholder="Location *"
              required
              className="rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
            />
            <input
              type="date"
              value={form.eventDate}
              onChange={(e) => setForm({ ...form, eventDate: e.target.value })}
              required
              className="rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
            />
            <select
              value={form.category}
              onChange={(e) =>
                setForm({ ...form, category: e.target.value as EventCategory })
              }
              className="rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
            >
              {categories.map((c) => (
                <option key={c} value={c}>
                  {c}
                </option>
              ))}
            </select>
            <input
              type="time"
              value={form.startTime}
              onChange={(e) => setForm({ ...form, startTime: e.target.value })}
              placeholder="Start Time"
              className="rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
            />
            <input
              type="time"
              value={form.endTime}
              onChange={(e) => setForm({ ...form, endTime: e.target.value })}
              placeholder="End Time"
              className="rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
            />
            <input
              type="number"
              value={form.maxAttendees || ""}
              onChange={(e) =>
                setForm({
                  ...form,
                  maxAttendees: parseInt(e.target.value) || 0,
                })
              }
              placeholder="Max Attendees (0 = unlimited)"
              className="rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
            />
            <textarea
              value={form.description}
              onChange={(e) =>
                setForm({ ...form, description: e.target.value })
              }
              placeholder="Description"
              rows={3}
              className="sm:col-span-2 rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
            />
            <div className="sm:col-span-2 flex justify-end gap-3">
              <button
                type="button"
                onClick={() => setShowCreate(false)}
                className="rounded-xl border subtle-border px-4 py-2 text-sm font-medium ink-muted hover:bg-white/70 dark:hover:bg-white/10"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={creating}
                className="rounded-xl bg-gradient-to-r from-primary-600 to-emerald-600 px-4 py-2 text-sm font-semibold text-white shadow-md shadow-primary-500/20 transition hover:brightness-110 disabled:opacity-50"
              >
                {creating ? "Creating..." : "Create Event"}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Category Filter */}
      <div className="mb-6 flex flex-wrap gap-2">
        <button
          onClick={() => setCategoryFilter("")}
          className={`rounded-full px-4 py-1.5 text-sm font-medium transition-colors ${!categoryFilter ? "bg-primary-600 text-white" : "bg-white/70 text-gray-600 hover:bg-white dark:bg-white/5 dark:text-gray-300 dark:hover:bg-white/10"}`}
        >
          All
        </button>
        {categories.map((cat) => (
          <button
            key={cat}
            onClick={() => setCategoryFilter(cat)}
            className={`rounded-full px-4 py-1.5 text-sm font-medium transition-colors ${categoryFilter === cat ? "bg-primary-600 text-white" : "bg-white/70 text-gray-600 hover:bg-white dark:bg-white/5 dark:text-gray-300 dark:hover:bg-white/10"}`}
          >
            {cat}
          </button>
        ))}
      </div>

      <ErrorAlert message={error} onClose={() => setError("")} />

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {filtered.length === 0 ? (
          <div className="glass-panel md:col-span-3 rounded-2xl p-8 text-center ink-muted">
            No events found
          </div>
        ) : (
          filtered.map((event) => (
            <EventCard
              key={event.id}
              event={event}
              onViewDetails={(e) => {
                setSelectedEvent(e);
                setShowDetail(true);
              }}
              onRsvp={(e) => {
                setSelectedEvent(e);
                setShowDetail(true);
              }}
            />
          ))
        )}
      </div>

      <EventDetailModal
        open={showDetail}
        event={selectedEvent}
        onClose={() => setShowDetail(false)}
        onRsvpChange={loadEvents}
      />
    </div>
  );
}
