import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/messaging_remote_datasource.dart';
import '../../data/datasources/messaging_websocket_datasource.dart';
import '../../data/models/messaging_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/storage/secure_storage_service.dart';

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
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      someoneTyping:
          clearTyping ? false : (someoneTyping ?? this.someoneTyping),
      typingUser: clearTyping ? null : (typingUser ?? this.typingUser),
      connectionError:
          clearError ? null : (connectionError ?? this.connectionError),
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  final String conversationId;
  late final MessagingWebSocketDatasource _ws;
  bool _disposed = false; // FIX Bug 1: guard state updates after dispose

  ChatNotifier(this.conversationId);

  @override
  ChatState build() {
    ref.onDispose(() => _disposed = true);
    _init(); // don't await — intentional fire-and-forget, but now guarded
    return const ChatState(isLoading: true);
  }

  // FIX Bug 1: wrap every state assignment so it never runs after dispose
  void _setState(ChatState Function(ChatState) updater) {
    if (_disposed) return;
    state = updater(state);
  }

  Future<void> _init() async {
    // ── 1. Fetch message history ─────────────────────────────────────────────
    try {
      final messages = await ref
          .read(messagingDatasourceProvider)
          .getMessages(conversationId);
      _setState((s) => s.copyWith(messages: messages, isLoading: false));
    } catch (e) {
      // FIX Bug 1: catch the error so _init continues to the WS connection
      _setState((s) => s.copyWith(isLoading: false));
    }

    // ── 2. Build WebSocket datasource ────────────────────────────────────────
    final user = ref.read(currentUserProvider);

    _ws = MessagingWebSocketDatasource(
      storage: ref.read(secureStorageProvider),
      onMessage: (msg) {
        _setState((current) {
          final msgs = current.messages;

          // Skip true duplicates (non-temp, same real ID)
          if (msgs.any((m) => !m.id.startsWith('temp_') && m.id == msg.id)) {
            return current;
          }

          // Replace optimistic: match on content + senderId (both int now, safe ==)
          final tempIndex = msgs.indexWhere(
            (m) =>
                m.id.startsWith('temp_') &&
                m.content == msg.content &&
                m.senderId ==
                    msg.senderId, // both int now, no toString() needed
          );

          final updated = List<MessageModel>.from(msgs);
          if (tempIndex != -1) {
            updated[tempIndex] = msg;
          } else {
            updated.add(msg);
          }

          return current.copyWith(messages: updated);
        });
      },
      onTyping: (data) {
        final isTyping = data['typing'] as bool? ?? false;
        _setState((current) => current.copyWith(
              someoneTyping: isTyping,
              typingUser: data['userName'] as String?,
              clearTyping: !isTyping,
            ));
      },
    );

    // ── 3. Connect ───────────────────────────────────────────────────────────
    try {
      await _ws.connect(conversationId: conversationId);
      await _ws.waitUntilConnected();

      if (user != null) {
  _ws.sendOnline(user.id);

  await ref
      .read(messagingDatasourceProvider)
      .markRead(conversationId);
}
      _setState((s) => s.copyWith(isConnected: true, clearError: true));
    } catch (e) {
      _setState((s) => s.copyWith(
            isConnected: false,
            connectionError: 'Could not connect. Retrying…',
          ));
    }

    // ── 4. Cleanup ───────────────────────────────────────────────────────────
    ref.onDispose(() {
      if (user != null) _ws.sendOffline(user.id);
      _ws.disconnect();
    });
  }

  void sendMessage(String content) {
    final user = ref.read(currentUserProvider);
    if (user == null || content.trim().isEmpty) return;

    // Parse user.id to int so the type matches MessageModel.senderId
    final senderIdInt = int.tryParse(user.id.toString()) ?? 0;

    final optimistic = MessageModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: senderIdInt, // ← now int, matches server response
      senderName: user.fullName,
      content: content,
      readBy: [senderIdInt],
      createdAt: DateTime.now().toIso8601String(),
    );

    _setState((s) => s.copyWith(messages: [...s.messages, optimistic]));

    _ws.sendMessage(
      conversationId: conversationId,
      content: content,
      userId: senderIdInt, // ← pass int, consistent everywhere
      userName: user.fullName,
    );
  }

  void sendTyping(bool typing) {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    _ws.sendTyping(
      conversationId: conversationId,
      userId: user.id,
      userName: user.fullName,
      typing: typing,
    );
  }
}

final chatProvider = NotifierProvider.family<ChatNotifier, ChatState, String>(
    (arg) => ChatNotifier(arg));
