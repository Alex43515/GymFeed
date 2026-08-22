import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/backend/supabase/repositories/chat_repository.dart';
import '/backend/supabase/supabase_records.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/messages/individual_message/individual_message_widget.dart';
import '/pages/messages/new_message/new_message_widget.dart';
import '../messaging_shared.dart';

class MessagesWidget extends StatefulWidget {
  const MessagesWidget({super.key});

  static String routeName = 'Messages';
  static String routePath = 'messages';

  @override
  State<MessagesWidget> createState() => _MessagesWidgetState();
}

class _MessagesWidgetState extends State<MessagesWidget> {
  final _repository = ChatRepository();
  final _searchController = TextEditingController();
  final _typingTimers = <String, Timer>{};
  late Stream<List<ConversationSummary>> _conversations;
  RealtimeChannel? _presenceChannel;
  Set<String> _onlineUserIds = const {};
  Set<String> _typingChatIds = const {};

  @override
  void initState() {
    super.initState();
    _conversations = _repository.watchConversations();
    _searchController.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectPresence());
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _connectPresence() {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null || _presenceChannel != null) return;
    final channel = supabase.channel(
      'gymfeed-messaging',
      opts: RealtimeChannelConfig(key: uid, enabled: true),
    );
    _presenceChannel = channel;
    channel
        .onPresenceSync((_) {
          if (!mounted) return;
          setState(() {
            _onlineUserIds = channel
                .presenceState()
                .map((presence) => presence.key)
                .where((id) => id.isNotEmpty)
                .toSet();
          });
        })
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            final senderId = payload['user_id']?.toString() ?? '';
            final chatId = payload['chat_id']?.toString() ?? '';
            if (senderId.isEmpty || senderId == uid || chatId.isEmpty) return;
            final isTyping = payload['is_typing'] == true;
            _typingTimers.remove(chatId)?.cancel();
            if (!mounted) return;
            setState(() {
              final next = Set<String>.from(_typingChatIds);
              isTyping ? next.add(chatId) : next.remove(chatId);
              _typingChatIds = next;
            });
            if (isTyping) {
              _typingTimers[chatId] = Timer(const Duration(seconds: 3), () {
                if (!mounted) return;
                setState(() {
                  _typingChatIds = Set<String>.from(_typingChatIds)
                    ..remove(chatId);
                });
              });
            }
          },
        )
        .subscribe((status, _) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            unawaited(channel.track({
              'user_id': uid,
              'online_at': DateTime.now().toUtc().toIso8601String(),
            }));
          }
        });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    final channel = _presenceChannel;
    if (channel != null) unawaited(supabase.removeChannel(channel));
    super.dispose();
  }

  void _openCompose() => context.pushNamed(NewMessageWidget.routeName);

  Future<void> _openConversation(ConversationSummary summary) async {
    await _repository.markSeen(summary.chat.id);
    if (!mounted) return;
    await context.pushNamed(
      IndividualMessageWidget.routeName,
      queryParameters: {
        'chat': serializeParam(
          supaRef('chats', summary.chat.id),
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );
    if (!mounted) return;
    setState(() => _conversations = _repository.watchConversations());
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
          textScaler: media.textScaler.clamp(maxScaleFactor: 1.3)),
      child: Scaffold(
        backgroundColor: messageBackground,
        body: SafeArea(
          child: StreamBuilder<List<ConversationSummary>>(
            stream: _conversations,
            builder: (context, snapshot) {
              if (!snapshot.hasData &&
                  snapshot.connectionState == ConnectionState.waiting) {
                return const MessageLoading();
              }
              final all = snapshot.data ?? const <ConversationSummary>[];
              final query = _searchController.text.trim().toLowerCase();
              final conversations = all.where((summary) {
                if (query.isEmpty) return true;
                final other = summary.other;
                return other.displayName.toLowerCase().contains(query) ||
                    other.username.toLowerCase().contains(query) ||
                    summary.chat.lastMessage.toLowerCase().contains(query);
              }).toList();
              final active = all
                  .where((summary) =>
                      _onlineUserIds.contains(summary.other.userId))
                  .map((summary) => summary.other)
                  .toList();
              return Column(
                children: [
                  _Header(onCompose: _openCompose),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 3, 16, 0),
                    child: TextField(
                      controller: _searchController,
                      cursorColor: messageGreen,
                      style: messageText(),
                      decoration: InputDecoration(
                        hintText: 'Search messages',
                        hintStyle: messageText(color: const Color(0xFF62656B)),
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 20, color: messageMuted),
                        filled: true,
                        fillColor: messageSurface,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 13),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: messageBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: messageGreen),
                        ),
                      ),
                    ),
                  ),
                  if (active.isNotEmpty) _ActivePeople(people: active),
                  Expanded(
                    child: snapshot.hasError
                        ? _ErrorState(
                            onRetry: () => setState(() => _conversations =
                                _repository.watchConversations()),
                          )
                        : conversations.isEmpty
                            ? _EmptyState(
                                searching: query.isNotEmpty,
                                onCompose: _openCompose,
                              )
                            : ListView.separated(
                                padding: EdgeInsets.fromLTRB(
                                    16, active.isEmpty ? 18 : 5, 16, 30),
                                itemCount: conversations.length,
                                separatorBuilder: (_, __) => const Divider(
                                  height: 1,
                                  indent: 70,
                                  color: Color(0xFF171717),
                                ),
                                itemBuilder: (context, index) {
                                  final summary = conversations[index];
                                  return _ConversationRow(
                                    summary: summary,
                                    online: _onlineUserIds
                                        .contains(summary.other.userId),
                                    typing: _typingChatIds
                                        .contains(summary.chat.id),
                                    onTap: () => _openConversation(summary),
                                  );
                                },
                              ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onCompose});
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 76,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
            ),
            Text('Messages',
                style: messageText(size: 24, weight: FontWeight.w700)),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Material(
                color: messageGreen,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'New message',
                  onPressed: onCompose,
                  icon: const Icon(Icons.edit_outlined,
                      color: Color(0xFF042313), size: 21),
                ),
              ),
            ),
          ],
        ),
      );
}

class _ActivePeople extends StatelessWidget {
  const _ActivePeople({required this.people});
  final List<ChatMember> people;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Active now',
                  style: messageText(size: 12, color: messageMuted)),
            ),
            const SizedBox(height: 9),
            SizedBox(
              height: 84,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: people.length,
                separatorBuilder: (_, __) => const SizedBox(width: 17),
                itemBuilder: (_, index) {
                  final person = people[index];
                  return SizedBox(
                    width: 58,
                    child: Column(
                      children: [
                        MessageAvatar(
                          displayName: person.displayName,
                          username: person.username,
                          photoUrl: person.photoUrl,
                          online: true,
                          size: 54,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          messageDisplayName(
                                  person.displayName, person.username)
                              .split(' ')
                              .first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: messageText(size: 11),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    required this.summary,
    required this.online,
    required this.typing,
    required this.onTap,
  });

  final ConversationSummary summary;
  final bool online;
  final bool typing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final other = summary.other;
    final name = messageDisplayName(other.displayName, other.username);
    final sentByMe =
        summary.chat.lastMessageSentBy == supabase.auth.currentUser?.id;
    final preview = typing
        ? 'typing...'
        : summary.chat.lastMessage.isEmpty
            ? 'Start the conversation'
            : '${sentByMe ? 'You: ' : ''}${summary.chat.lastMessage}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            MessageAvatar(
              displayName: other.displayName,
              username: other.username,
              photoUrl: other.photoUrl,
              online: online,
              size: 54,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: messageText(size: 14.5, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: messageText(
                      size: 12,
                      color: typing ? messageGreen : messageMuted,
                      weight: typing ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(conversationTime(summary.chat.lastMessageAt),
                    style: messageText(size: 10, color: messageMuted)),
                const SizedBox(height: 8),
                if (summary.unreadCount > 0)
                  Container(
                    constraints: const BoxConstraints(minWidth: 34),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: messageGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      summary.unreadCount > 99
                          ? '99+'
                          : '${summary.unreadCount}',
                      textAlign: TextAlign.center,
                      style: messageText(
                        size: 10,
                        color: const Color(0xFF042313),
                        weight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 22),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searching, required this.onCompose});
  final bool searching;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  color: messageMuted, size: 42),
              const SizedBox(height: 15),
              Text(
                searching ? 'No matching messages' : 'Your messages live here',
                textAlign: TextAlign.center,
                style: messageText(size: 17, weight: FontWeight.w700),
              ),
              if (!searching) ...[
                const SizedBox(height: 7),
                Text('Find someone and start a conversation.',
                    textAlign: TextAlign.center,
                    style: messageText(size: 12, color: messageMuted)),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: onCompose,
                  style: FilledButton.styleFrom(
                    backgroundColor: messageGreen,
                    foregroundColor: const Color(0xFF042313),
                  ),
                  child: Text('New message',
                      style: messageText(
                          color: const Color(0xFF042313),
                          weight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, color: messageGreen),
          label: Text('Could not load messages. Try again.',
              style: messageText(color: messageMuted)),
        ),
      );
}
