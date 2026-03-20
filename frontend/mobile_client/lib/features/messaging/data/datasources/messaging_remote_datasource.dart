import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/messaging_models.dart';
import '../../../auth/data/models/user_model.dart';

abstract class MessagingRemoteDatasource {
  Future<List<ConversationModel>> getConversations();
  Future<List<MessageModel>> getMessages(String conversationId, {int page = 0, int size = 20});
  Future<void> markRead(String conversationId);
  Future<void> deleteConversation(String conversationId);
  Future<UserModel?> searchUser(String username);
  Future<ConversationModel> createConversation({
    required List<int> participantIds,
    required List<String> participantNames,
    String? groupName, // Added
    String? initialMessage,
  });
  
  Future<ConversationModel> addParticipants(
    String conversationId, 
    List<int> participantIds, 
    List<String> participantNames
  );
}

class MessagingRemoteDatasourceImpl implements MessagingRemoteDatasource {
  final Dio _dio;
  MessagingRemoteDatasourceImpl(this._dio);

  @override
  Future<List<ConversationModel>> getConversations() async {
    try {
      final resp = await _dio.get(ApiConstants.conversations);
      final list = resp.data as List;
      return list.map((e) => ConversationModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) { _handleError(e); }
  }

  @override
  Future<ConversationModel> createConversation({
    required List<int> participantIds,
    required List<String> participantNames,
    String? groupName,
    String? initialMessage,
  }) async {
    try {
      final resp = await _dio.post(ApiConstants.conversations, data: {
        'participantIds': participantIds,
        'participantNames': participantNames,
        'groupName': groupName,
        'initialMessage': initialMessage,
      });
      return ConversationModel.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) { _handleError(e); }
  }

  @override
  Future<ConversationModel> addParticipants(
      String conversationId, List<int> participantIds, List<String> participantNames) async {
    try {
      final resp = await _dio.put(
        '${ApiConstants.conversations}/$conversationId/participants',
        data: {
          'participantIds': participantIds,
          'participantNames': participantNames,
        },
      );
      return ConversationModel.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) { _handleError(e); }
  }

  @override
  Future<List<MessageModel>> getMessages(String conversationId,
      {int page = 0, int size = 20}) async {
    try {
      final resp = await _dio.get(
        '${ApiConstants.conversations}/$conversationId/messages',
        queryParameters: {'page': page, 'size': size},
      );
      final data = resp.data;
      final content = data['content'] as List? ?? [];
      return content
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) { _handleError(e); }
  }

  @override
  Future<void> markRead(String conversationId) async {
    try {
      await _dio.put('${ApiConstants.conversations}/$conversationId/read');
    } on DioException catch (e) { _handleError(e); }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _dio.delete('${ApiConstants.conversations}/$conversationId');
    } on DioException catch (e) { _handleError(e); }
  }

  @override
  Future<UserModel?> searchUser(String username) async {
    try {
      final resp = await _dio.get(
        ApiConstants.userByUsername,
        queryParameters: {'username': username},
      );
      if (resp.data == null) return null;
      return UserModel.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      _handleError(e);
    }
  }

  Never _handleError(DioException e) {
    if (e.response?.statusCode == 401) throw const AuthException();
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.unknown) {
      throw const NetworkException();
    }
    throw ServerException(e.response?.data?['message']?.toString() ?? 'Error');
  }
}

final messagingDatasourceProvider = Provider<MessagingRemoteDatasource>((ref) {
  return MessagingRemoteDatasourceImpl(ref.watch(dioProvider));
});
