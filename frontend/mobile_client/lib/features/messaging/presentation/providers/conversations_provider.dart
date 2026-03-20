import 'package:decp_mobile_app/features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/messaging_models.dart';

class ConversationsState {
  final List<ConversationModel> conversations;
  final bool isLoading;
  final String? error;

  const ConversationsState({this.conversations = const [], this.isLoading = false, this.error});

  ConversationsState copyWith({List<ConversationModel>? conversations, bool? isLoading, String? error, bool clearError = false}) =>
      ConversationsState(
        conversations: conversations ?? this.conversations,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class ConversationsNotifier extends Notifier<ConversationsState> {
  @override
  ConversationsState build() {
    // Initial load
    Future.microtask(() => loadConversations());
    return const ConversationsState(isLoading: true);
  }

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final convs = await ref.read(messagingDatasourceProvider).getConversations();
      state = state.copyWith(conversations: convs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Updated to support Group Chats
  Future<ConversationModel?> startConversation({
    required List<int> participantIds,
    required List<String> participantNames,
    String? groupName, // Added for groups
    String? msg,
  }) async {
    try {
      final conv = await ref.read(messagingDatasourceProvider).createConversation(
            participantIds: participantIds,
            participantNames: participantNames,
            groupName: groupName,
            initialMessage: msg,
          );
      
      // Add the new conversation to the top of the list
      state = state.copyWith(
        conversations: [conv, ...state.conversations.where((c) => c.id != conv.id)],
      );
      return conv;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// New: Add participants to an existing group
  Future<void> addParticipantsToGroup(
    String conversationId, 
    List<int> newIds, 
    List<String> newNames
  ) async {
    try {
      final updatedConv = await ref.read(messagingDatasourceProvider)
          .addParticipants(conversationId, newIds, newNames);
      
      // Update the specific conversation in the state list
      final newConversations = state.conversations.map((c) {
        return c.id == conversationId ? updatedConv : c;
      }).toList();
      
      state = state.copyWith(conversations: newConversations);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final conversationsProvider = NotifierProvider<ConversationsNotifier, ConversationsState>(ConversationsNotifier.new);
