import {
  createContext,
  useContext,
  useState,
  useEffect,
  useCallback,
  useRef,
  type ReactNode,
} from "react";
import { Client } from "@stomp/stompjs";
import type {
  ConversationResponse,
  MessageResponse,
  TypingIndicator,
} from "../types";
import { chatService } from "../services/chat";
import { useAuth } from "./AuthContext";
import { getToken } from "../utils/localStorage";

interface ChatContextType {
  conversations: ConversationResponse[];
  currentConversation: ConversationResponse | null;
  messages: MessageResponse[];
  connected: boolean;
  totalUnreadCount: number;
  typingUsers: Map<string, string>;
  loadConversations: () => Promise<void>;
  selectConversation: (conv: ConversationResponse) => Promise<void>;
  markConversationRead: (conversationId: string) => Promise<void>;
  clearCurrentConversation: () => void;
  sendMessage: (content: string) => void;
  startConversation: (
    participantIds: number[],
    participantNames: string[],
  ) => Promise<ConversationResponse>;
}

const ChatContext = createContext<ChatContextType | undefined>(undefined);

export function ChatProvider({ children }: { children: ReactNode }) {
  const { user, isAuthenticated } = useAuth();
  const [conversations, setConversations] = useState<ConversationResponse[]>(
    [],
  );
  const [currentConversation, setCurrentConversation] =
    useState<ConversationResponse | null>(null);
  const [messages, setMessages] = useState<MessageResponse[]>([]);
  const [connected, setConnected] = useState(false);
  const [typingUsers] = useState<Map<string, string>>(new Map());
  const clientRef = useRef<Client | null>(null);
  const subsRef = useRef<{ unsubscribe: () => void }[]>([]);
  const currentConversationIdRef = useRef<string | null>(null);

  useEffect(() => {
    currentConversationIdRef.current = currentConversation?.id || null;
  }, [currentConversation]);

  const totalUnreadCount = conversations.reduce(
    (acc, conv) => acc + (conv.unreadCount || 0),
    0,
  );

  // Connect to WebSocket
  useEffect(() => {
    if (!isAuthenticated || !user) return;

    const token = getToken();
    const stompClient = new Client({
      brokerURL: `ws://localhost:8080/ws/chat/websocket?token=${encodeURIComponent(token || "")}`,
      reconnectDelay: 5000,
      onConnect: () => {
        setConnected(true);
        // Announce online
        stompClient.publish({
          destination: "/app/chat/online",
          body: String(user.id),
          headers: {
            "X-User-Id": String(user.id),
            "X-User-Name": user.fullName,
          },
        });
      },
      onDisconnect: () => setConnected(false),
      onStompError: () => setConnected(false),
    });

    stompClient.activate();
    clientRef.current = stompClient;

    return () => {
      if (stompClient.connected) {
        stompClient.publish({
          destination: "/app/chat/offline",
          body: String(user.id),
          headers: {
            "X-User-Id": String(user.id),
            "X-User-Name": user.fullName,
          },
        });
      }
      stompClient.deactivate();
    };
  }, [isAuthenticated, user]);

  // Subscribe to ALL user conversations messages
  useEffect(() => {
    const client = clientRef.current;
    if (!client || !connected || conversations.length === 0) return;

    // Unsubscribe previous
    subsRef.current.forEach((s) => s.unsubscribe());
    subsRef.current = [];

    conversations.forEach((conv) => {
      const msgSub = client.subscribe(
        `/topic/messages/${conv.id}`,
        (frame) => {
          const msg: MessageResponse = JSON.parse(frame.body);

          // If this message belongs to the currently active conversation
          if (currentConversationIdRef.current === conv.id) {
            setMessages((prev) => [...prev, msg]);
            // If we are actively looking at it, it should technically be marked as read here too
            // Either by calling chatService.markRead or the user scrolling.
          } else {
            // Update unread count for other conversations
            setConversations((prev) =>
              prev
                .map((c) =>
                  c.id === conv.id
                    ? {
                      ...c,
                      lastMessage: msg.content,
                      lastMessageAt: msg.createdAt,
                      unreadCount: (c.unreadCount || 0) + 1,
                    }
                    : c,
                )
                .sort(
                  (a, b) =>
                    new Date(b.lastMessageAt || b.createdAt).getTime() -
                    new Date(a.lastMessageAt || a.createdAt).getTime(),
                ),
            );
          }
        },
      );
      subsRef.current.push(msgSub);
    });

    return () => {
      subsRef.current.forEach((s) => s.unsubscribe());
      subsRef.current = [];
    };
  }, [connected, conversations.length]);

  const loadConversations = useCallback(async () => {
    if (!isAuthenticated) return;
    const res = await chatService.getConversations();
    setConversations(res.data);
  }, [isAuthenticated]);

  const markConversationRead = useCallback(async (conversationId: string) => {
    setConversations((prev) =>
      prev.map((c) => (c.id === conversationId ? { ...c, unreadCount: 0 } : c)),
    );
    try {
      await chatService.markRead(conversationId);
    } catch (err) {
      console.error("Failed to mark read", err);
    }
  }, []);

  const clearCurrentConversation = useCallback(() => {
    setCurrentConversation(null);
  }, []);

  const selectConversation = useCallback(async (conv: ConversationResponse) => {
    setCurrentConversation(conv);
    const res = await chatService.getMessages(conv.id);
    setMessages(res.data.content?.reverse() || []);

    // Clear unread indicator locally
    await markConversationRead(conv.id);
  }, [markConversationRead]);

  const sendMessage = useCallback(
    (content: string) => {
      const client = clientRef.current;
      if (!client || !connected || !currentConversation || !user) return;
      client.publish({
        destination: "/app/chat/send",
        headers: {
          "X-User-Id": String(user.id),
          "X-User-Name": user.fullName,
        },
        body: JSON.stringify({
          conversationId: currentConversation.id,
          content,
        }),
      });
    },
    [connected, currentConversation, user],
  );

  const startConversation = useCallback(async (participantIds: number[], participantNames: string[]) => {
    const res = await chatService.createConversation(participantIds, participantNames);
    setConversations((prev) => [res.data, ...prev]);
    return res.data;
  }, []);

  return (
    <ChatContext.Provider
      value={{
        conversations,
        currentConversation,
        messages,
        connected,
        totalUnreadCount,
        typingUsers,
        loadConversations,
        selectConversation,
        clearCurrentConversation,
        markConversationRead,
        sendMessage,
        startConversation,
      }}
    >
      {children}
    </ChatContext.Provider>
  );
}

export function useChat(): ChatContextType {
  const ctx = useContext(ChatContext);
  if (!ctx) throw new Error("useChat must be used within ChatProvider");
  return ctx;
}
