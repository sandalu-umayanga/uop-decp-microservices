import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/messaging_models.dart';

/// Manages a STOMP WebSocket connection for real-time chat.
///
/// Fixes applied vs the original:
///   1. [_isConnected] flag — send calls are dropped (not thrown) when not ready.
///   2. [_pendingQueue] — messages queued while connecting are flushed on connect.
///   3. Auto-reconnect with exponential back-off (max 30 s).
///   4. [waitUntilConnected] — callers can await readiness before sending.
class MessagingWebSocketDatasource {
  StompClient? _client;
  final SecureStorageService _storage;
  final void Function(MessageModel) onMessage;
  final void Function(Map<String, dynamic>) onTyping;

  // ── Connection state ───────────────────────────────────────────────────────
  bool _isConnected = false;
  bool _disposed    = false;
  String? _conversationId;

  /// Completes when the STOMP session is fully established (onConnect fired).
  Completer<void> _readyCompleter = Completer<void>();

  /// Messages queued while the connection is being established.
  final List<_QueuedMessage> _pendingQueue = [];

  // ── Reconnect state ────────────────────────────────────────────────────────
  int  _reconnectAttempt = 0;
  Timer? _reconnectTimer;
  static const _maxBackoffSeconds = 30;

  MessagingWebSocketDatasource({
    required SecureStorageService storage,
    required this.onMessage,
    required this.onTyping,
  }) : _storage = storage;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns a Future that resolves once the STOMP session is active.
  /// Useful for callers that want to await before sending the first message.
  Future<void> waitUntilConnected() => _readyCompleter.future;

  Future<void> connect({required String conversationId}) async {
    _conversationId = conversationId;
    await _doConnect();
  }

  void sendMessage({
    required String conversationId,
    required String content,
    required int userId,
    required String userName,
  }) {
    final msg = _QueuedMessage(
      destination: '/app/chat/send',
      headers: {'X-User-Id': '$userId', 'X-User-Name': userName},
      body: jsonEncode({'conversationId': conversationId, 'content': content}),
    );

    if (_isConnected && _client != null) {
      _safeSend(msg);
    } else {
      // Queue and wait — will be flushed in _onConnect
      _pendingQueue.add(msg);
    }
  }

  void sendTyping({
    required String conversationId,
    required int userId,
    required String userName,
    required bool typing,
  }) {
    if (!_isConnected) return; // typing indicators are fire-and-forget
    _safeSend(_QueuedMessage(
      destination: '/app/chat/typing',
      body: jsonEncode({
        'conversationId': conversationId,
        'userId': userId,
        'userName': userName,
        'typing': typing,
      }),
    ));
  }

  void sendOnline(int userId) {
    if (!_isConnected) return;
    _safeSend(_QueuedMessage(
      destination: '/app/chat/online',
      headers: {'X-User-Id': '$userId'},
      body: '',
    ));
  }

  void sendOffline(int userId) {
    // Best-effort even if connection is shaky
    _safeSend(_QueuedMessage(
      destination: '/app/chat/offline',
      headers: {'X-User-Id': '$userId'},
      body: '',
    ));
  }

  void disconnect() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _client?.deactivate();
    _client = null;
    _isConnected = false;
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<void> _doConnect() async {
    if (_disposed) return;

    final token = await _storage.readToken();

    _client = StompClient(
      config: StompConfig(
        url: '${ApiConstants.wsUrl}?token=$token',
        onConnect: _onConnect,
        onDisconnect: _onDisconnect,
        onWebSocketError: _onError,
        onStompError: _onError,
        stompConnectHeaders: token != null
            ? {'Authorization': 'Bearer $token'}
            : {},
        webSocketConnectHeaders: token != null
            ? {'Authorization': 'Bearer $token'}
            : {},
        // Built-in reconnect is disabled — we handle it ourselves so we can
        // reset subscriptions and flush the pending queue on each reconnect.
        reconnectDelay: Duration.zero,
      ),
    );

    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    if (_disposed) return;

    _isConnected      = true;
    _reconnectAttempt = 0;

    // Resolve any awaiters
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete();
    }

    final convId = _conversationId;
    if (convId == null) return;

    // Subscribe to messages
    _client!.subscribe(
      destination: '/topic/messages/$convId',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;
          onMessage(MessageModel.fromJson(data));
        } catch (_) {}
      },
    );

    // Subscribe to typing indicators
    _client!.subscribe(
      destination: '/topic/typing/$convId',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;
          onTyping(data);
        } catch (_) {}
      },
    );

    // Flush queued messages
    final queued = List<_QueuedMessage>.from(_pendingQueue);
    _pendingQueue.clear();
    for (final msg in queued) {
      _safeSend(msg);
    }
  }

  void _onDisconnect(StompFrame frame) {
    if (_disposed) return;
    _markDisconnected();
    _scheduleReconnect();
  }

  void _onError(dynamic error) {
    if (_disposed) return;
    _markDisconnected();
    _scheduleReconnect();
  }

  void _markDisconnected() {
    _isConnected = false;
    // Reset so new awaiters can wait for the next connect
    if (_readyCompleter.isCompleted) {
      _readyCompleter = Completer<void>();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_disposed) return;

    // Exponential back-off: 1 s, 2 s, 4 s, 8 s, 16 s, 30 s (cap)
    final delaySeconds = (_reconnectAttempt == 0)
        ? 1
        : (1 << _reconnectAttempt).clamp(1, _maxBackoffSeconds);
    _reconnectAttempt++;

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      if (!_disposed) await _doConnect();
    });
  }

  /// Wraps _client.send in a try/catch so a stale StompClient can never
  /// throw an unhandled StompBadStateException up to the UI.
  void _safeSend(_QueuedMessage msg) {
    try {
      _client?.send(
        destination: msg.destination,
        headers: msg.headers,
        body: msg.body,
      );
    } catch (_) {
      // Connection was lost between the isConnected check and the send.
      // Queue the message so it's retried on reconnect (only for chat msgs).
      if (msg.destination == '/app/chat/send') {
        _pendingQueue.add(msg);
      }
    }
  }
}

/// Simple value object for queued outbound frames.
class _QueuedMessage {
  final String destination;
  final Map<String, String> headers;
  final String body;

  const _QueuedMessage({
    required this.destination,
    this.headers = const {},
    this.body = '',
  });
}