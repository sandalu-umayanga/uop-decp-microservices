import { useState, useEffect } from "react";
import { useAuth } from "../context/AuthContext";
import { postService } from "../services/post";
import { eventService } from "../services/event";
import type { Post, EventResponse } from "../types";
import PostCard from "../components/post/PostCard";
import PostModal from "../components/post/PostModal";
import LoadingSpinner from "../components/common/LoadingSpinner";
import ErrorAlert from "../components/common/ErrorAlert";
import { formatDate } from "../utils/formatDate";

export default function DashboardPage() {
  const { user } = useAuth();
  const [posts, setPosts] = useState<Post[]>([]);
  const [upcomingEvents, setUpcomingEvents] = useState<EventResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [showPostModal, setShowPostModal] = useState(false);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    setError("");
    try {
      const [postsRes, eventsRes] = await Promise.all([
        postService.getAll(),
        eventService.getUpcoming().catch(() => ({ data: [] })),
      ]);
      setPosts(postsRes.data);
      setUpcomingEvents(eventsRes.data.slice(0, 5));
    } catch {
      setError("Failed to load feed");
    }
    setLoading(false);
  };

  const handlePostCreated = (post: Post) => {
    setPosts((prev) => [post, ...prev]);
  };

  const handlePostUpdate = (updated: Post) => {
    setPosts((prev) => prev.map((p) => (p.id === updated.id ? updated : p)));
  };

  if (loading) return <LoadingSpinner />;

  return (
    <div className="mx-auto max-w-7xl px-4 py-6 sm:px-6">
      <div className="grid gap-6 lg:grid-cols-3">
        {/* Main Feed */}
        <div className="lg:col-span-2">
          {/* Create Post */}
          <div className="glass-panel stagger-in mb-6 rounded-2xl p-4">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary-500/15 text-sm font-semibold text-primary-700 dark:bg-primary-500/30 dark:text-primary-200">
                {user?.fullName?.charAt(0).toUpperCase()}
              </div>
              <button
                onClick={() => setShowPostModal(true)}
                className="flex-1 rounded-xl bg-white/70 px-4 py-2.5 text-left text-sm ink-muted outline-none transition hover:bg-white dark:bg-white/5 dark:hover:bg-white/10"
              >
                What's on your mind, {user?.fullName?.split(" ")[0]}?
              </button>
            </div>
          </div>

          <ErrorAlert message={error} onClose={() => setError("")} />

          {/* Posts */}
          <div className="space-y-4">
            {posts.length === 0 && !loading && (
              <div className="glass-panel stagger-in stagger-in-delay-1 rounded-2xl p-8 text-center ink-muted">
                <p className="text-lg">No posts yet</p>
                <p className="text-sm">Be the first to share something!</p>
              </div>
            )}
            {posts.map((post) => (
              <PostCard key={post.id} post={post} onUpdate={handlePostUpdate} />
            ))}
          </div>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Profile Card */}
          <div className="glass-panel stagger-in stagger-in-delay-1 rounded-2xl p-5">
            <div className="flex items-center gap-3">
              <div className="flex h-12 w-12 items-center justify-center rounded-full bg-primary-500/15 text-lg font-bold text-primary-700 dark:bg-primary-500/30 dark:text-primary-200">
                {user?.fullName?.charAt(0).toUpperCase()}
              </div>
              <div>
                <p className="font-semibold text-gray-900 dark:text-white">
                  {user?.fullName}
                </p>
                <p className="text-sm ink-muted">
                  @{user?.username} · {user?.role}
                </p>
              </div>
            </div>
          </div>

          {/* Upcoming Events */}
          <div className="glass-panel stagger-in stagger-in-delay-2 rounded-2xl p-5">
            <h3 className="mb-3 text-xl font-semibold text-gray-900 dark:text-white">
              Upcoming Events
            </h3>
            {upcomingEvents.length === 0 ? (
              <p className="text-sm ink-muted">No upcoming events</p>
            ) : (
              <div className="space-y-3">
                {upcomingEvents.map((event) => (
                  <div
                    key={event.id}
                    className="flex items-start gap-3 rounded-xl bg-white/60 p-2.5 dark:bg-white/5"
                  >
                    <div className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-xl bg-primary-500/15 text-xs font-medium text-primary-700 dark:bg-primary-500/30 dark:text-primary-200">
                      {new Date(event.eventDate).getDate()}
                    </div>
                    <div className="min-w-0">
                      <p className="truncate text-sm font-medium text-gray-900 dark:text-white">
                        {event.title}
                      </p>
                      <p className="text-xs ink-muted">
                        {formatDate(event.eventDate)}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>

      <PostModal
        open={showPostModal}
        onClose={() => setShowPostModal(false)}
        onCreated={handlePostCreated}
      />
    </div>
  );
}
