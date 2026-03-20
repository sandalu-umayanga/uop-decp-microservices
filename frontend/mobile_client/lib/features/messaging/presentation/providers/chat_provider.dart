import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/messaging_remote_datasource.dart';
import '../../data/datasources/messaging_websocket_datasource.dart';
import '../../data/models/messaging_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/storage/secure_storage_service.dart';

// ─── Chat State ────────────────────────────────────────────────────────────────
class ChatState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isConnected;
  final bool someoneTyping;
  final String? typingUser;
  final String? connectionError;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isConnected = false,
    this.someoneTyping = false,
    this.typingUser,
    this.connectionError,
  });

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isConnected,
    bool? someoneTyping,
    String? typingUser,
    String? connectionError,
    bool clearTyping = false,
    bool clearError  = false,
  }) {
    return ChatState(
      messages:        messages        ?? this.messages,
      isLoading:       isLoading       ?? this.isLoading,
      isConnected:     isConnected     ?? this.isConnected,
      someoneTyping:   clearTyping ? false : (someoneTyping ?? this.someoneTyping),
      typingUser:      clearTyping ? null  : (typingUser    ?? this.typingUser),
      connectionError: clearError  ? null  : (connectionError ?? this.connectionError),
    );
  }
}

// ─── Chat Notifier ─────────────────────────────────────────────────────────────
class ChatNotifier extends Notifier<ChatState> {
  final String conversationId;
  late final MessagingWebSocketDatasource _ws;

  ChatNotifier(this.conversationId);

  @override
  ChatState build() {
    _init();
    return const ChatState(isLoading: true);
  }

  Future<void> _init() async {
    // ── 1. Fetch message history ─────────────────────────────────────────────
    try {
      final messages = await ref
          .read(messagingDatasourceProvider)
          .getMessages(conversationId);
      await ref.read(messagingDatasourceProvider).markRead(conversationId);
      state = state.copyWith(messages: messages, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }

    // ── 2. Build WebSocket datasource ────────────────────────────────────────
    final user = ref.read(currentUserProvider);

    _ws = MessagingWebSocketDatasource(
      storage: ref.read(secureStorageProvider),
      onMessage: (msg) {
        // Skip duplicates (e.g. the server echo of our own optimistic message)
        final alreadyExists = state.messages.any((m) => m.id == msg.id);
        if (!alreadyExists) {
          // Replace optimistic temp message if content matches
          final tempIndex = state.messages.indexWhere(
            (m) =>
                m.id.startsWith('temp_') &&
                m.content == msg.content &&
                m.senderId == msg.senderId,
          );
          if (tempIndex != -1) {
            final updated = List<MessageModel>.from(state.messages);
            updated[tempIndex] = msg;
            state = state.copyWith(messages: updated);
          } else {
            state = state.copyWith(messages: [...state.messages, msg]);
          }
        }
      },
      onTyping: (data) {
        final isTyping = data['typing'] as bool? ?? false;
        state = state.copyWith(
          someoneTyping: isTyping,
          typingUser:    data['userName'] as String?,
          clearTyping:   !isTyping,
        );
      },
    );

    // ── 3. Connect and await the STOMP handshake ─────────────────────────────
    try {
      await _ws.connect(conversationId: conversationId);
      // waitUntilConnected resolves once onConnect fires (subscriptions ready)
      await _ws.waitUntilConnected();

      if (user != null) _ws.sendOnline(user.id);
      state = state.copyWith(isConnected: true, clearError: true);
    } catch (e) {
      // Connection failed — the datasource will keep retrying in the background.
      // The UI will show "Connecting…" and the send button will queue messages.
      state = state.copyWith(
        isConnected:     false,
        connectionError: 'Could not connect. Retrying…',
      );
    }

    // ── 4. Cleanup on provider dispose ───────────────────────────────────────
    ref.onDispose(() {
      if (user != null) _ws.sendOffline(user.id);
      _ws.disconnect();
    });
  }

  // ── sendMessage ─────────────────────────────────────────────────────────────
  // Safe to call at any time — the datasource queues the message internally
  // if the connection isn't ready yet, and flushes it on (re)connect.
  void sendMessage(String content) {
    final user = ref.read(currentUserProvider);
    if (user == null || content.trim().isEmpty) return;

    // Optimistic UI update — show message immediately regardless of WS state
    final optimistic = MessageModel(
      id:             'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId:       user.id,
      senderName:     user.fullName,
      content:        content,
      readBy:         [user.id],
      createdAt:      DateTime.now().toIso8601String(),
    );
    state = state.copyWith(messages: [...state.messages, optimistic]);

    // Delegate to datasource — queues internally if not yet connected
    _ws.sendMessage(
      conversationId: conversationId,
      content:        content,
      userId:         user.id,
      userName:       user.fullName,
    );
  }

  // ── sendTyping ──────────────────────────────────────────────────────────────
  void sendTyping(bool typing) {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    // Silently dropped if not connected (fire-and-forget, non-critical)
    _ws.sendTyping(
      conversationId: conversationId,
      userId:         user.id,
      userName:       user.fullName,
      typing:         typing,
    );
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────
final chatProvider =
    NotifierProvider.family<ChatNotifier, ChatState, String>(
        (arg) => ChatNotifier(arg));