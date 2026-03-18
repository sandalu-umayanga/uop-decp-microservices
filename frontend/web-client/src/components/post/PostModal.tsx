import { useState } from "react";
import { useAuth } from "../../context/AuthContext";
import { postService } from "../../services/post";
import type { Post } from "../../types";

interface PostModalProps {
  open: boolean;
  onClose: () => void;
  onCreated: (post: Post) => void;
}

export default function PostModal({
  open,
  onClose,
  onCreated,
}: PostModalProps) {
  const { user } = useAuth();
  const [content, setContent] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");

  if (!open || !user) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!content.trim()) return;
    setSubmitting(true);
    setError("");
    try {
      const res = await postService.create({
        userId: String(user.id),
        fullName: user.fullName,
        content: content.trim(),
      });
      onCreated(res.data);
      setContent("");
      onClose();
    } catch {
      setError("Failed to create post");
    }
    setSubmitting(false);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/45 p-4 backdrop-blur-sm">
      <div className="glass-panel w-full max-w-lg rounded-2xl p-6">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Create Post</h3>
          <button
            onClick={onClose}
            className="ink-muted hover:text-gray-800 dark:hover:text-gray-100"
          >
            ✕
          </button>
        </div>
        <form onSubmit={handleSubmit} className="mt-4">
          <textarea
            value={content}
            onChange={(e) => setContent(e.target.value)}
            placeholder="What's on your mind?"
            rows={4}
            className="w-full rounded-xl border subtle-border bg-white/80 p-3 text-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
            autoFocus
          />
          {error && <p className="mt-2 text-sm text-red-500">{error}</p>}
          <div className="mt-4 flex justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
              className="rounded-xl border subtle-border px-4 py-2 text-sm font-medium ink-muted hover:bg-white/70 dark:hover:bg-white/10"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={!content.trim() || submitting}
              className="rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white hover:bg-primary-700 disabled:opacity-50"
            >
              {submitting ? "Posting..." : "Post"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
