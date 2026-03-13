import 'package:decp_mobile_app/features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'package:decp_mobile_app/features/messaging/presentation/providers/conversations_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../core/utils/date_utils.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(conversationsProvider.notifier).loadConversations());
  }

  Future<void> _showNewConversationPopup() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return const _NewConversationDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationsProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewConversationPopup,
        child: const Icon(Icons.edit_outlined),
      ),
      body: Builder(builder: (_) {
        if (state.isLoading && state.conversations.isEmpty) {
          return const AppLoadingWidget(message: 'Loading conversations...');
        }
        if (state.error != null && state.conversations.isEmpty) {
          return AppErrorWidget(
              message: state.error!,
              onRetry: () =>
                  ref.read(conversationsProvider.notifier).loadConversations());
        }
        if (state.conversations.isEmpty) {
          return Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 60, color: Color(0xFFBDBDBD)),
              const SizedBox(height: 16),
              const Text('No conversations yet',
                  style: TextStyle(color: Color(0xFF9E9E9E))),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showNewConversationPopup,
                icon: const Icon(Icons.add),
                label: const Text('Start a Conversation'),
              ),
            ]),
          );
        }
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(conversationsProvider.notifier).loadConversations(),
          child: ListView.builder(
            itemCount: state.conversations.length,
            itemBuilder: (_, i) {
              final conv = state.conversations[i];
              // Show the other participant's name (not our own)
              final otherNames = currentUser == null
                  ? conv.participantNames
                  : conv.participantNames
                      .where((name) => name != currentUser.username)
                      .toList();
              final displayName = otherNames.isNotEmpty
                  ? otherNames.join(', ')
                  : conv.participantNames.join(', ');
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      const Color(0xFF1565C0).withValues(alpha: 0.15),
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                  ),
                ),
                title: Text(displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(conv.lastMessage ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (conv.lastMessageAt != null)
                      Text(timeAgo(conv.lastMessageAt!),
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFFBDBDBD))),
                    if (conv.unreadCount > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            borderRadius: BorderRadius.circular(12)),
                        child: Text('${conv.unreadCount}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                onTap: () => context.push('/chat/${conv.id}'),
              );
            },
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// New Conversation Bottom Sheet
// ---------------------------------------------------------------------------

class _NewConversationDialog extends ConsumerStatefulWidget {
  const _NewConversationDialog({super.key});

  @override
  ConsumerState<_NewConversationDialog> createState() =>
      _NewConversationDialogState();
}

class _NewConversationDialogState
    extends ConsumerState<_NewConversationDialog> {
  final _searchCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  UserModel? _foundUser;
  bool _searching = false;
  bool _sending = false;
  String? _searchError;

  Future<void> _searchUser() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _searching = true;
      _searchError = null;
      _foundUser = null;
    });

    try {
      final user =
          await ref.read(messagingDatasourceProvider).searchUser(query);

      setState(() {
        _searching = false;
        _foundUser = user;
        if (user == null) {
          _searchError = "User not found";
        }
      });
    } catch (_) {
      setState(() {
        _searching = false;
        _searchError = "Search failed";
      });
    }
  }

  Future<void> _startConversation() async {
    final user = _foundUser;
    final me = ref.read(currentUserProvider);
    final message = _messageCtrl.text.trim();

    if (user == null || me == null || message.isEmpty) return;

    setState(() => _sending = true);

    final conv =
        await ref.read(conversationsProvider.notifier).startConversation(
      [me.id, user.id],
      [me.username, user.username],
      message,
    );

    if (!mounted) return;

    setState(() => _sending = false);

    if (conv != null) {
      Navigator.pop(context);
      context.push('/chat/${conv.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Start Conversation",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                  errorText: _searchError,
                ),
                onSubmitted: (_) => _searchUser(),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _searching ? null : _searchUser,
                child: _searching
                    ? const CircularProgressIndicator()
                    : const Text("Search"),
              ),
              if (_foundUser != null) ...[
                const SizedBox(height: 20),
                Text(
                  _foundUser!.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("@${_foundUser!.username}"),
                const SizedBox(height: 15),
                TextField(
                  controller: _messageCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Write first message",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: _sending ? null : _startConversation,
                  child: _sending
                      ? const CircularProgressIndicator()
                      : const Text("Send Message"),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
