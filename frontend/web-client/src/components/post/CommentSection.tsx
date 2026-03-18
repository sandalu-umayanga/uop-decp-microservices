import { useState } from "react";
import type { Post } from "../../types";
import { useAuth } from "../../context/AuthContext";
import { postService } from "../../services/post";
import { formatRelativeTime } from "../../utils/formatDate";

interface CommentSectionProps {
  post: Post;
  onCommentAdded?: (updated: Post) => void;
}

export default function CommentSection({
  post,
  onCommentAdded,
}: CommentSectionProps) {
  const { user } = useAuth();
  const [text, setText] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!text.trim() || !user || submitting) return;
    setSubmitting(true);
    try {
      const res = await postService.addComment(post.id, {
        userId: String(user.id),
        username: user.username,
        text: text.trim(),
      });
      onCommentAdded?.(res.data);
      setText("");
    } catch {
      /* ignore */
    }
    setSubmitting(false);
  };

  return (
    <div className="mt-3 border-t subtle-border pt-3">
      {/* Comment list */}
      <div className="max-h-60 space-y-3 overflow-y-auto">
        {post.comments.map((c, i) => (
          <div key={i} className="flex gap-2">
            <div className="flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-full bg-white/70 text-xs font-medium text-gray-700 dark:bg-white/10 dark:text-gray-200">
              {c.username?.charAt(0).toUpperCase()}
            </div>
            <div>
              <p className="text-sm">
                <span className="font-medium text-gray-900 dark:text-white">{c.username}</span>{" "}
                <span className="text-gray-700 dark:text-gray-200">{c.text}</span>
              </p>
              <p className="text-xs ink-muted">
                {formatRelativeTime(c.timestamp)}
              </p>
            </div>
          </div>
        ))}
      </div>

      {/* Add comment */}
      {user && (
        <form onSubmit={handleSubmit} className="mt-3 flex gap-2">
          <input
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder="Write a comment..."
            className="flex-1 rounded-lg border subtle-border bg-white/80 px-3 py-2 text-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
          />
          <button
            type="submit"
            disabled={!text.trim() || submitting}
            className="rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white hover:bg-primary-700 disabled:opacity-50"
          >
            Post
          </button>
        </form>
      )}
    </div>
  );
}
