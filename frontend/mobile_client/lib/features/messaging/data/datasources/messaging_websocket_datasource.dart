import 'dart:async';
import 'dart:convert';

import 'package:decp_mobile_app/core/constants/api_constants.dart';
import 'package:decp_mobile_app/core/storage/secure_storage_service.dart';
import 'package:decp_mobile_app/features/messaging/data/models/messaging_models.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class MessagingWebSocketDatasource {
  StompClient? _client;
  final SecureStorageService _storage;
  final void Function(MessageModel) onMessage;
  final void Function(Map<String, dynamic>) onTyping;

  bool _isConnected = false;
  bool _disposed = false;
  String? _conversationId;
  String? _token; // ← store token so send frames can include it

  Completer<void> _readyCompleter = Completer<void>();
  final List<_QueuedMessage> _pendingQueue = [];

  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;
  static const _maxBackoffSeconds = 30;

  MessagingWebSocketDatasource({
    required SecureStorageService storage,
    required this.onMessage,
    required this.onTyping,
  }) : _storage = storage;

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
    // FIX: include Authorization on every SEND frame
    final msg = _QueuedMessage(
      destination: '/app/chat/send',
      headers: {
        'X-User-Id': '$userId',
        'X-User-Name': userName,
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({'conversationId': conversationId, 'content': content}),
    );

    if (_isConnected && _client != null) {
      _safeSend(msg);
    } else {
      _pendingQueue.add(msg);
    }
  }

  void sendTyping({
    required String conversationId,
    required int userId,
    required String userName,
    required bool typing,
  }) {
    if (!_isConnected) return;
    _safeSend(_QueuedMessage(
      destination: '/app/chat/typing',
      headers: {
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
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
      headers: {
        'X-User-Id': '$userId',
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
      body: '',
    ));
  }

  void sendOffline(int userId) {
    _safeSend(_QueuedMessage(
      destination: '/app/chat/offline',
      headers: {
        'X-User-Id': '$userId',
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
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

  Future<void> _doConnect() async {
    if (_disposed) return;

    // FIX: cache token so it's available to all subsequent send frames
    _token = await _storage.readToken();
    print('TOKEN: $_token');
    print('WS URL: ${ApiConstants.wsUrl}?token=$_token');

    _client = StompClient(
      config: StompConfig(
        url: '${ApiConstants.wsUrl}?token=$_token',
        onConnect: _onConnect,
        onDisconnect: _onDisconnect,
        onWebSocketError: _onError,
        onStompError: _onError,
        stompConnectHeaders:
            _token != null ? {'Authorization': 'Bearer $_token'} : {},
        webSocketConnectHeaders:
            _token != null ? {'Authorization': 'Bearer $_token'} : {},
        reconnectDelay: Duration.zero,
      ),
    );

    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    print('STOMP CONNECTED: ${frame.headers}');
    
    if (_disposed) return;

    _isConnected = true;
    _reconnectAttempt = 0;

    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete();
    }

    final convId = _conversationId;
    if (convId == null) return;

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

    // Re-build queued messages with the fresh token before flushing,
    // in case the token was null when the message was originally queued
    final queued = List<_QueuedMessage>.from(_pendingQueue);
    _pendingQueue.clear();
    for (final msg in queued) {
      _safeSend(msg.withAuth(_token));
    }
  }

  void _onDisconnect(StompFrame frame) {
    print('STOMP DISCONNECT: ${frame.headers}');
    
    if (_disposed) return;
    _markDisconnected();
    _scheduleReconnect();
  }

  void _onError(dynamic error) {
    print('STOMP ERROR: $error');
    if (_disposed) return;
    _markDisconnected();
    _scheduleReconnect();
  }

  void _markDisconnected() {
    _isConnected = false;
    if (_readyCompleter.isCompleted) {
      _readyCompleter = Completer<void>();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_disposed) return;

    final delaySeconds = (_reconnectAttempt == 0)
        ? 1
        : (1 << _reconnectAttempt).clamp(1, _maxBackoffSeconds);
    _reconnectAttempt++;

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      if (!_disposed) await _doConnect();
    });
  }

  void _safeSend(_QueuedMessage msg) {
    try {
      _client?.send(
        destination: msg.destination,
        headers: msg.headers,
        body: msg.body,
      );
    } catch (_) {
      if (msg.destination == '/app/chat/send') {
        _pendingQueue.add(msg);
      }
    }
  }
}

class _QueuedMessage {
  final String destination;
  final Map<String, String> headers;
  final String body;

  const _QueuedMessage({
    required this.destination,
    this.headers = const {},
    this.body = '',
  });

  // FIX: returns a copy with Authorization injected/updated
  _QueuedMessage withAuth(String? token) {
    if (token == null) return this;
    return _QueuedMessage(
      destination: destination,
      headers: {...headers, 'Authorization': 'Bearer $token'},
      body: body,
    );
  }
}
