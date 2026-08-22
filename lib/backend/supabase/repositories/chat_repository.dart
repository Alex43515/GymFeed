import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '/backend/supabase/supabase.dart';

const _uuid = Uuid();
const _sharePrefix = '__gymfeed_share__:';
const _reactionPrefix = '__gymfeed_reaction__:';
const _readPrefix = '__gymfeed_read__:';

class Chat {
  Chat(this.data);

  final Map<String, dynamic> data;

  String get id => (data['id'] ?? '').toString();
  String get lastMessage => (data['last_message'] ?? '').toString();
  String get lastMessageSentBy =>
      (data['last_message_sent_by'] ?? '').toString();
  DateTime? get createdAt => _date(data['created_at']);
  DateTime? get lastMessageAt => _date(data['last_message_at']);
}

class ChatMessage {
  ChatMessage(this.data);

  final Map<String, dynamic> data;

  String get id => (data['id'] ?? '').toString();
  String get chatId => (data['chat_id'] ?? '').toString();
  String get senderId => (data['user_id'] ?? '').toString();
  String get body => (data['text'] ?? '').toString();
  String get imageUrl => (data['image_url'] ?? '').toString();
  String get videoUrl => (data['video_url'] ?? '').toString();
  String get postId => (data['post_id'] ?? '').toString();
  DateTime? get createdAt => _date(data['created_at']);

  bool get isReaction => body.startsWith(_reactionPrefix);
  bool get isReadReceipt => body.startsWith(_readPrefix);
  bool get isShare => body.startsWith(_sharePrefix);

  Map<String, dynamic> get sharePayload =>
      isShare ? _decodeMap(body.substring(_sharePrefix.length)) : const {};
  Map<String, dynamic> get reactionPayload => isReaction
      ? _decodeMap(body.substring(_reactionPrefix.length))
      : const {};

  String get previewText {
    if (isReaction) return 'Reacted ${reactionPayload['emoji'] ?? '❤'}';
    if (isReadReceipt) return '';
    if (isShare) {
      final type = sharePayload['type']?.toString();
      return type == 'meal' ? 'Shared a meal' : 'Shared a workout';
    }
    if (body.trim().isNotEmpty) return body.trim();
    if (imageUrl.isNotEmpty) return 'Photo';
    if (videoUrl.isNotEmpty) return 'Video';
    return 'Message';
  }
}

class ChatMember {
  ChatMember(this.data);

  final Map<String, dynamic> data;

  String get chatId => (data['chat_id'] ?? '').toString();
  String get userId => (data['user_id'] ?? '').toString();
  DateTime? get joinedAt => _date(data['joined_at']);
  DateTime? get lastSeenAt => _date(data['last_seen_at']);

  Map<String, dynamic> get _profile =>
      (data['profile'] as Map<String, dynamic>?) ?? const {};
  String get username => (_profile['username'] ?? '').toString();
  String get displayName => (_profile['display_name'] ?? '').toString();
  String get photoUrl => (_profile['photo_url'] ?? '').toString();
}

class ConversationSummary {
  const ConversationSummary({
    required this.chat,
    required this.other,
    required this.unreadCount,
  });

  final Chat chat;
  final ChatMember other;
  final int unreadCount;
}

/// Direct-message persistence for GymFeed.
///
/// It deliberately uses the deployed schema's `user_id`, `text`, `image_url`
/// and `video_url` columns. Structured workout/meal shares and reactions are
/// encoded into the text column, so every feature works without a destructive
/// database migration and remains visible to both participants in real time.
class ChatRepository {
  SupabaseClient get _db => supabase;
  String? get _uid => _db.auth.currentUser?.id;

  static String _seenKey(String uid, String chatId) =>
      'gymfeed_chat_seen_v1_${uid}_$chatId';

  Future<List<ConversationSummary>> conversations() async {
    final uid = _uid;
    if (uid == null) return const [];
    final memberships = await _db
        .from('chat_members')
        .select('chat_id,last_seen_at')
        .eq('user_id', uid);
    final membershipRows = (memberships as List).cast<Map<String, dynamic>>();
    final chatIds = membershipRows
        .map((row) => (row['chat_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList();
    if (chatIds.isEmpty) return const [];

    final results = await Future.wait<dynamic>([
      _db
          .from('chats')
          .select()
          .inFilter('id', chatIds)
          .order('last_message_at', ascending: false, nullsFirst: false),
      _db
          .from('chat_members')
          .select(
              '*, profile:profiles!chat_members_user_id_fkey(username,display_name,photo_url)')
          .inFilter('chat_id', chatIds),
      _db
          .from('chat_messages')
          .select('id,chat_id,user_id,text,created_at')
          .inFilter('chat_id', chatIds),
      SharedPreferences.getInstance(),
    ]);

    final memberRows = (results[1] as List).cast<Map<String, dynamic>>();
    final messageRows = (results[2] as List).cast<Map<String, dynamic>>();
    final preferences = results[3] as SharedPreferences;
    final dbSeenByChat = <String, DateTime?>{
      for (final row in membershipRows)
        (row['chat_id'] ?? '').toString(): _date(row['last_seen_at']),
    };

    final summaries = <ConversationSummary>[];
    for (final raw in (results[0] as List).cast<Map<String, dynamic>>()) {
      final chat = Chat(raw);
      final otherRaw = memberRows.cast<Map<String, dynamic>?>().firstWhere(
            (row) =>
                row?['chat_id'].toString() == chat.id &&
                row?['user_id'].toString() != uid,
            orElse: () => null,
          );
      if (otherRaw == null) continue;
      final localSeen = DateTime.tryParse(
          preferences.getString(_seenKey(uid, chat.id)) ?? '');
      final dbSeen = dbSeenByChat[chat.id];
      DateTime? receiptSeen;
      for (final row in messageRows) {
        if (row['chat_id'].toString() != chat.id ||
            row['user_id'].toString() != uid ||
            !(row['text'] ?? '').toString().startsWith(_readPrefix)) {
          continue;
        }
        receiptSeen = _latest(receiptSeen, _date(row['created_at']));
      }
      final seenAt = _latest(_latest(dbSeen, localSeen), receiptSeen);
      final unread = messageRows.where((row) {
        if (row['chat_id'].toString() != chat.id ||
            row['user_id'].toString() == uid) {
          return false;
        }
        final text = (row['text'] ?? '').toString();
        if (text.startsWith(_reactionPrefix) || text.startsWith(_readPrefix)) {
          return false;
        }
        final sentAt = _date(row['created_at']);
        return sentAt != null && (seenAt == null || sentAt.isAfter(seenAt));
      }).length;
      summaries.add(ConversationSummary(
        chat: chat,
        other: ChatMember(otherRaw),
        unreadCount: unread,
      ));
    }
    summaries.sort((a, b) => (b.chat.lastMessageAt ??
            b.chat.createdAt ??
            DateTime(0))
        .compareTo(a.chat.lastMessageAt ?? a.chat.createdAt ?? DateTime(0)));
    return summaries;
  }

  Stream<List<ConversationSummary>> watchConversations() {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    return _db
        .from('chats')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false)
        .asyncMap((_) => conversations());
  }

  /// Create a conversation without selecting the row before membership exists.
  /// The old `.insert().select()` path was filtered by the chat SELECT policy
  /// because the creator was not a member yet, causing New Message to fail.
  Future<String> createChat(List<String> memberIds) async {
    final uid = _requireUid();
    final chatId = _uuid.v4();
    await _db.from('chats').insert({'id': chatId});
    await _db.from('chat_members').insert({
      'chat_id': chatId,
      'user_id': uid,
      'last_seen_at': DateTime.now().toUtc().toIso8601String(),
    });
    for (final memberId in memberIds.toSet()) {
      if (memberId.isEmpty || memberId == uid) continue;
      await _db.from('chat_members').insert({
        'chat_id': chatId,
        'user_id': memberId,
      });
    }
    return chatId;
  }

  Future<String> getOrCreateDirectChat(String otherUserId) async {
    final uid = _requireUid();
    if (otherUserId.isEmpty || otherUserId == uid) {
      throw ArgumentError('Choose another GymFeed user.');
    }
    final mine =
        await _db.from('chat_members').select('chat_id').eq('user_id', uid);
    final myChatIds = (mine as List)
        .map((row) => (row['chat_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList();
    if (myChatIds.isNotEmpty) {
      final theirs = await _db
          .from('chat_members')
          .select('chat_id')
          .eq('user_id', otherUserId)
          .inFilter('chat_id', myChatIds);
      for (final row in (theirs as List)) {
        final chatId = (row['chat_id'] ?? '').toString();
        final members = await _db
            .from('chat_members')
            .select('user_id')
            .eq('chat_id', chatId);
        if ((members as List).length == 2) return chatId;
      }
    }
    return createChat([otherUserId]);
  }

  Future<List<ChatMember>> members(String chatId) async {
    if (chatId.isEmpty) return const [];
    final rows = await _db
        .from('chat_members')
        .select(
            '*, profile:profiles!chat_members_user_id_fkey(username,display_name,photo_url)')
        .eq('chat_id', chatId);
    return (rows as List)
        .map((row) => ChatMember(row as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMember?> otherMember(String chatId) async {
    final uid = _uid;
    if (uid == null) return null;
    final values = await members(chatId);
    return values.cast<ChatMember?>().firstWhere(
          (member) => member?.userId != uid,
          orElse: () => null,
        );
  }

  Future<List<ChatMessage>> messages(String chatId, {int limit = 100}) async {
    if (chatId.isEmpty) return const [];
    final rows = await _db
        .from('chat_messages')
        .select()
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .limit(limit);
    return (rows as List)
        .map((row) => ChatMessage(row as Map<String, dynamic>))
        .toList();
  }

  Stream<List<ChatMessage>> watchMessages(String chatId, {int limit = 100}) {
    if (chatId.isEmpty) return Stream.value(const []);
    return _db
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .limit(limit)
        .map((rows) => rows.map(ChatMessage.new).toList());
  }

  Future<void> sendMessage(
    String chatId,
    String text, {
    String? imageUrl,
    String? videoUrl,
    String? postId,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty &&
        (imageUrl == null || imageUrl.isEmpty) &&
        (videoUrl == null || videoUrl.isEmpty) &&
        postId == null) {
      return;
    }
    await _insertMessage(
      chatId,
      cleanText,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      postId: postId,
      summary: cleanText.isNotEmpty
          ? cleanText
          : imageUrl?.isNotEmpty == true
              ? 'Photo'
              : videoUrl?.isNotEmpty == true
                  ? 'Video'
                  : 'Shared a post',
    );
  }

  Future<void> shareWorkout(String chatId, Map<String, dynamic> routine) async {
    final title = (routine['name'] ?? 'Workout').toString();
    await _insertMessage(
      chatId,
      '$_sharePrefix${jsonEncode({
            'type': 'workout',
            'title': title,
            'routine': routine
          })}',
      summary: 'Shared a workout: $title',
    );
  }

  Future<void> shareMeal(String chatId, Map<String, dynamic> meal) async {
    final title = (meal['name'] ?? 'Meal').toString();
    await _insertMessage(
      chatId,
      '$_sharePrefix${jsonEncode({
            'type': 'meal',
            'title': title,
            'meal': meal
          })}',
      summary: 'Shared a meal: $title',
    );
  }

  Future<void> toggleHeartReaction(String chatId, String messageId) async {
    final uid = _requireUid();
    final rows = await _db
        .from('chat_messages')
        .select('id,text')
        .eq('chat_id', chatId)
        .eq('user_id', uid)
        .like('text', '$_reactionPrefix%');
    for (final raw in (rows as List)) {
      final row = raw as Map<String, dynamic>;
      final body = (row['text'] ?? '').toString();
      final payload = _decodeMap(body.substring(_reactionPrefix.length));
      if (payload['message_id']?.toString() == messageId) {
        await _db.from('chat_messages').delete().eq('id', row['id']);
        await _restoreConversationSummary(chatId);
        return;
      }
    }
    await _db.from('chat_messages').insert({
      'chat_id': chatId,
      'user_id': uid,
      'text': '$_reactionPrefix${jsonEncode({
            'message_id': messageId,
            'emoji': '❤'
          })}',
    });
    await _restoreConversationSummary(chatId);
  }

  Future<void> deleteMessage(String messageId) async {
    await _db.from('chat_messages').delete().eq('id', messageId);
  }

  Future<void> markSeen(String chatId) async {
    final uid = _uid;
    if (uid == null || chatId.isEmpty) return;
    final now = DateTime.now().toUtc();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_seenKey(uid, chatId), now.toIso8601String());
    try {
      await _db
          .from('chat_members')
          .update({'last_seen_at': now.toIso8601String()})
          .eq('chat_id', chatId)
          .eq('user_id', uid);
    } catch (_) {
      // Older deployments do not yet have the chat_members UPDATE policy.
      // The device-local read marker still keeps unread badges correct.
    }

    // A lightweight system message is the cross-device fallback for older
    // deployments where chat_members UPDATE is blocked by RLS. It also lets a
    // sender show an honest Seen state without a destructive schema change.
    try {
      final latestIncoming = await _db
          .from('chat_messages')
          .select('created_at,text')
          .eq('chat_id', chatId)
          .neq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(25);
      DateTime? incomingAt;
      for (final raw in (latestIncoming as List)) {
        final row = raw as Map<String, dynamic>;
        final text = (row['text'] ?? '').toString();
        if (text.startsWith(_reactionPrefix) || text.startsWith(_readPrefix)) {
          continue;
        }
        incomingAt = _date(row['created_at']);
        break;
      }
      if (incomingAt == null) return;

      final latestReceipts = await _db
          .from('chat_messages')
          .select('created_at')
          .eq('chat_id', chatId)
          .eq('user_id', uid)
          .like('text', '$_readPrefix%')
          .order('created_at', ascending: false)
          .limit(1);
      final receiptAt = (latestReceipts as List).isEmpty
          ? null
          : _date(latestReceipts.first['created_at']);
      if (receiptAt != null && !receiptAt.isBefore(incomingAt)) return;
      await _db.from('chat_messages').insert({
        'chat_id': chatId,
        'user_id': uid,
        'text': '$_readPrefix${jsonEncode({
              'read_at': now.toIso8601String(),
            })}',
      });
      await _restoreConversationSummary(chatId);
    } catch (_) {
      // A read receipt should never stop the user from reading or messaging.
    }
  }

  Future<void> _insertMessage(
    String chatId,
    String text, {
    String? imageUrl,
    String? videoUrl,
    String? postId,
    required String summary,
  }) async {
    final uid = _requireUid();
    await _db.from('chat_messages').insert({
      'chat_id': chatId,
      'user_id': uid,
      'text': text,
      if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
      if (videoUrl != null && videoUrl.isNotEmpty) 'video_url': videoUrl,
      if (postId != null && postId.isNotEmpty) 'post_id': postId,
    });
    await _db.from('chats').update({
      'last_message': summary,
      'last_message_at': DateTime.now().toUtc().toIso8601String(),
      'last_message_sent_by': uid,
    }).eq('id', chatId);
  }

  Future<void> _restoreConversationSummary(String chatId) async {
    final rows = await _db
        .from('chat_messages')
        .select('user_id,text,image_url,video_url,created_at')
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .limit(100);
    ChatMessage? latest;
    for (final raw in (rows as List)) {
      final message = ChatMessage(raw as Map<String, dynamic>);
      if (!message.isReaction && !message.isReadReceipt) {
        latest = message;
        break;
      }
    }
    if (latest == null) return;
    await _db.from('chats').update({
      'last_message': latest.previewText,
      'last_message_at': latest.createdAt?.toUtc().toIso8601String(),
      'last_message_sent_by': latest.senderId,
    }).eq('id', chatId);
  }

  String _requireUid() {
    final uid = _uid;
    if (uid == null) {
      throw StateError('No authenticated user for a chat write.');
    }
    return uid;
  }
}

DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString())?.toLocal();

DateTime? _latest(DateTime? a, DateTime? b) {
  if (a == null) return b;
  if (b == null) return a;
  return a.isAfter(b) ? a : b;
}

Map<String, dynamic> _decodeMap(String encoded) {
  try {
    final decoded = jsonDecode(encoded);
    return decoded is Map
        ? decoded.map((key, value) => MapEntry(key.toString(), value))
        : const {};
  } catch (_) {
    return const {};
  }
}
