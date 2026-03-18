import { useState } from "react";
import type { Post } from "../../types";
import { useAuth } from "../../context/AuthContext";
import { postService } from "../../services/post";
import { formatRelativeTime } from "../../utils/formatDate";
import CommentSection from "./CommentSection";

interface PostCardProps {
  post: Post;
  onUpdate?: (updated: Post) => void;
}

export default function PostCard({ post, onUpdate }: PostCardProps) {
  const { user } = useAuth();
  const [showComments, setShowComments] = useState(false);
  const [liking, setLiking] = useState(false);
  const [optimisticLiked, setOptimisticLiked] = useState<boolean | null>(null);

  const isLiked =
    optimisticLiked !== null
      ? optimisticLiked
      : user
        ? post.likedBy.some((id) => String(id) === String(user.id))
        : false;

  const handleLike = async () => {
    if (!user || liking) return;

    // Optimistic update: show like immediately (Instagram style)
    const newLikedState = !isLiked;
    setOptimisticLiked(newLikedState);
    setLiking(true);

    try {
      // Backend handles toggle: if already liked, it removes; if not liked, it adds
      const res = await postService.like(post.id, String(user.id));

      // Keep optimistic state - heart stays colored
      // Update parent so they get the updated like count
      onUpdate?.(res.data);
    } catch (error) {
      console.error("Failed to toggle like:", error);
      // Revert on error only
      setOptimisticLiked(null);
    }
    setLiking(false);
  };

  const handleCommentAdded = (updated: Post) => {
    onUpdate?.(updated);
  };

  return (
    <div className="glass-panel rounded-2xl p-5">
      {/* Header */}
      <div className="flex items-center gap-3">
        <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary-100 text-sm font-semibold text-primary-700">
          {post.fullName?.charAt(0).toUpperCase() ||
            post.username?.charAt(0).toUpperCase()}
        </div>
        <div className="flex-1">
          <p className="text-sm font-semibold text-gray-900 dark:text-white">
            {post.fullName || post.username}
          </p>
          <p className="text-xs ink-muted">
            @{post.username} · {formatRelativeTime(post.createdAt)}
          </p>
        </div>
      </div>

      {/* Content */}
      <p className="mt-3 whitespace-pre-wrap text-gray-800 dark:text-gray-100">{post.content}</p>

      {/* Media */}
      {post.mediaUrls && post.mediaUrls.length > 0 && (
        <div className="mt-3 flex gap-2 overflow-x-auto">
          {post.mediaUrls.map((url, i) => (
            <img
              key={i}
              src={url}
              alt=""
              className="h-48 rounded-lg object-cover"
            />
          ))}
        </div>
      )}

      {/* Actions */}
      <div className="mt-4 flex items-center gap-6 border-t subtle-border pt-3">
        <button
          onClick={handleLike}
          disabled={liking}
          className={`flex items-center gap-1.5 text-sm font-medium transition-colors ${
            isLiked ? "text-red-500" : "ink-muted hover:text-red-500"
          }`}
        >
          <svg
            className="h-5 w-5"
            fill={isLiked ? "currentColor" : "none"}
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
            />
          </svg>
          {post.likedBy.length}
        </button>
        <button
          onClick={() => setShowComments(!showComments)}
          className="flex items-center gap-1.5 text-sm font-medium ink-muted hover:text-primary-600"
        >
          <svg
            className="h-5 w-5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
            />
          </svg>
          {post.comments.length}
        </button>
      </div>

      {/* Comments */}
      {showComments && (
        <CommentSection post={post} onCommentAdded={handleCommentAdded} />
      )}
    </div>
  );
}
