import { useEffect, useRef, useState } from "react";
import { useAuth } from "../context/AuthContext";
import { useChat } from "../context/ChatContext";
import ConversationItem from "../components/chat/ConversationItem";
import MessageBubble from "../components/chat/MessageBubble";
import UserSearchModal from "../components/chat/UserSearchModal";
import type { User } from "../types";

export default function ChatPage() {
  const { user } = useAuth();
  const {
    conversations,
    currentConversation,
    messages,
    connected,
    loadConversations,
    selectConversation,
    sendMessage,
    startConversation,
    markConversationRead,
    clearCurrentConversation,
  } = useChat();
  const [input, setInput] = useState("");
  const [showUserSearch, setShowUserSearch] = useState(false);
  const [startingChat, setStartingChat] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    loadConversations();
  }, [loadConversations]);

  // Handle active conversation read status
  useEffect(() => {
    if (currentConversation) {
      markConversationRead(currentConversation.id);
    }
  }, [currentConversation?.id, markConversationRead]);

  // Cleanup active conversation on unmount
  useEffect(() => {
    return () => clearCurrentConversation();
  }, [clearCurrentConversation]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth", block: "nearest" });
  }, [messages]);

  const handleSend = (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim()) return;
    sendMessage(input.trim());
    setInput("");
  };

  const handleStartNew = async (selectedUser: User) => {
    if (!user) return;

    // Check if conversation already exists
    const existingConv = conversations.find(
      (conv) =>
        conv.participants.length === 2 &&
        conv.participants.includes(user.id) &&
        conv.participants.includes(selectedUser.id),
    );

    if (existingConv) {
      await selectConversation(existingConv);
      setShowUserSearch(false);
      return;
    }

    setStartingChat(true);
    try {
      const conv = await startConversation(
        [user.id, selectedUser.id],
        [user.fullName, selectedUser.fullName],
      );
      await selectConversation(conv);
      await loadConversations();
    } catch (err) {
      console.error("Failed to start conversation:", err);
    } finally {
      setStartingChat(false);
    }
  };

  if (!user) return null;

  return (
    <div className="mx-auto flex h-[calc(100vh-96px)] max-w-7xl px-4 pb-4 sm:px-6">
      {/* Sidebar */}
      <div className="glass-panel flex w-80 flex-shrink-0 flex-col rounded-l-2xl border-r subtle-border">
        <div className="flex items-center justify-between border-b subtle-border p-4">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Messages</h2>
          <div className="flex items-center gap-2">
            <span
              className={`h-2 w-2 rounded-full ${connected ? "bg-green-500" : "bg-red-400"}`}
            />
            <button
              onClick={() => setShowUserSearch(true)}
              className="rounded-xl bg-gradient-to-r from-primary-600 to-emerald-600 px-3 py-1.5 text-sm font-semibold text-white shadow-md shadow-primary-500/20 transition hover:brightness-110"
            >
              + New
            </button>
          </div>
        </div>
        <div className="flex-1 overflow-y-auto p-2">
          {conversations.length === 0 ? (
            <p className="p-4 text-center text-sm ink-muted">
              No conversations yet
            </p>
          ) : (
            conversations.map((conv) => (
              <ConversationItem
                key={conv.id}
                conversation={conv}
                currentUserId={user.id}
                selected={currentConversation?.id === conv.id}
                onClick={() => selectConversation(conv)}
              />
            ))
          )}
        </div>
      </div>

      {/* Chat Area */}
      <div className="glass-panel flex flex-1 flex-col rounded-r-2xl border-l-0">
        {currentConversation ? (
          <>
            {/* Chat Header */}
            <div className="border-b subtle-border bg-white/60 px-6 py-4 dark:bg-white/5">
              <h3 className="font-semibold text-gray-900 dark:text-white">
                {(currentConversation.participantNames || [])
                  .filter(
                    (_, i) => String(currentConversation.participants?.[i]) !== String(user.id),
                  )
                  .join(", ") || "Chat"}
              </h3>
            </div>

            {/* Messages */}
            <div className="flex-1 overflow-y-auto px-6 py-4">
              <div className="space-y-3">
                {(messages || []).map((msg) => (
                  <MessageBubble
                    key={msg.id}
                    message={msg}
                    isOwn={String(msg.senderId) === String(user.id)}
                  />
                ))}
                <div ref={messagesEndRef} />
              </div>
            </div>

            {/* Input */}
            <div className="border-t subtle-border bg-white/60 p-4 dark:bg-white/5">
              <form onSubmit={handleSend} className="flex gap-3">
                <input
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  placeholder="Type a message..."
                  className="flex-1 rounded-xl border subtle-border bg-white/80 px-4 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5 dark:text-white dark:placeholder-gray-400"
                  autoFocus
                />
                <button
                  type="submit"
                  disabled={!input.trim() || !connected}
                  className="rounded-xl bg-gradient-to-r from-primary-600 to-emerald-600 px-5 py-2.5 text-sm font-semibold text-white shadow-md shadow-primary-500/20 transition hover:brightness-110 disabled:opacity-50"
                >
                  Send
                </button>
              </form>
            </div>
          </>
        ) : (
          <div className="flex flex-1 items-center justify-center">
            <div className="text-center">
              <svg
                className="mx-auto h-16 w-16 text-gray-300 dark:text-gray-600"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                strokeWidth={1}
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                />
              </svg>
              <h3 className="mt-4 text-lg font-medium text-gray-900 dark:text-gray-300">
                Your Messages
              </h3>
              <p className="mt-1 text-sm ink-muted">
                Select a conversation or start a new one
              </p>
            </div>
          </div>
        )}
      </div>

      <UserSearchModal
        open={showUserSearch}
        onClose={() => setShowUserSearch(false)}
        onSelectUser={handleStartNew}
        title="Start New Conversation"
        loading={startingChat}
      />
    </div>
  );
}
