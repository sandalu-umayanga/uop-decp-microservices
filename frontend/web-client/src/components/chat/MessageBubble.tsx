import type { MessageResponse } from "../../types";
import { formatRelativeTime } from "../../utils/formatDate";

interface MessageBubbleProps {
  message: MessageResponse;
  isOwn: boolean;
}

export default function MessageBubble({ message, isOwn }: MessageBubbleProps) {
  return (
    <div className={`flex ${isOwn ? "justify-end" : "justify-start"}`}>
      <div
        className={`max-w-[70%] rounded-2xl px-4 py-2.5 ${isOwn
          ? "rounded-br-md bg-primary-600 text-white"
          : "rounded-bl-md bg-white/80 text-gray-900 dark:bg-white/10 dark:text-gray-100"
          }`}
      >

        <p className="text-sm">{message.content}</p>
        <p
          className={`mt-1 text-right text-[10px] ${isOwn ? "text-primary-100" : "ink-muted"}`}
        >
          {formatRelativeTime(message.createdAt)}
        </p>
      </div>
    </div>
  );
}
