import '/backend/supabase/supabase.dart';

class AppNotification {
  AppNotification(this.data);
  final Map<String, dynamic> data;

  String get id => (data['id'] ?? '').toString();
  String get recipientId => (data['recipient_id'] ?? '').toString();
  String get type => (data['type'] as String?) ?? '';
  String? get actorId => data['actor_id'] as String?;
  String? get postId => data['post_id'] as String?;
  String? get commentId => data['comment_id'] as String?;
  bool get isRead => (data['read'] as bool?) ?? false;
  DateTime? get createdAt => data['created_at'] == null
      ? null
      : DateTime.tryParse(data['created_at'].toString());

  Map<String, dynamic> get _actor =>
      (data['actor'] as Map<String, dynamic>?) ?? const {};
  String get actorUsername => (_actor['username'] as String?) ?? '';
  String get actorDisplayName => (_actor['display_name'] as String?) ?? '';
  String get actorPhotoUrl => (_actor['photo_url'] as String?) ?? '';

  Map<String, dynamic> get _post =>
      (data['post'] as Map<String, dynamic>?) ?? const {};
  String get postThumbnail => [
        (_post['video_thumbnail'] ?? '').toString(),
        (_post['legacy_photo_url'] ?? '').toString(),
      ].firstWhere((value) => value.isNotEmpty, orElse: () => '');
}

/// In-app notifications with Realtime subscription.
class NotificationRepository {
  SupabaseClient get _db => supabase;
  String? get _uid => _db.auth.currentUser?.id;

  static const _select =
      '*, actor:profiles!notifications_actor_id_fkey(username,display_name,photo_url), post:posts!notifications_post_id_fkey(legacy_photo_url,video_thumbnail)';

  /// Page of notifications for the current user, newest first.
  Future<List<AppNotification>> page({int limit = 30, DateTime? before}) async {
    final uid = _uid;
    if (uid == null) return const [];
    var q = _db.from('notifications').select(_select).eq('recipient_id', uid);
    if (before != null)
      q = q.lt('created_at', before.toUtc().toIso8601String());
    final rows = await q.order('created_at', ascending: false).limit(limit);
    return (rows as List)
        .map((r) => AppNotification(r as Map<String, dynamic>))
        .toList();
  }

  /// Live stream of the most recent [limit] notifications.
  /// Subscribe in a top-level widget so the bell badge stays up to date.
  Stream<List<AppNotification>> watch({int limit = 30}) {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', uid)
        .order('created_at', ascending: false)
        .limit(limit)
        .asyncMap((_) => page(limit: limit));
  }

  /// Number of unread notifications — use for the badge count.
  Future<int> unreadCount() async {
    final uid = _uid;
    if (uid == null) return 0;
    final res = await _db
        .from('notifications')
        .select('id')
        .eq('recipient_id', uid)
        .eq('read', false);
    return (res as List).length;
  }

  Future<void> markRead(String notificationId) async {
    await _db
        .from('notifications')
        .update({'read': true}).eq('id', notificationId);
  }

  Future<void> markAllRead() async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .from('notifications')
        .update({'read': true})
        .eq('recipient_id', uid)
        .eq('read', false);
  }

  Future<void> delete(String notificationId) async {
    await _db.from('notifications').delete().eq('id', notificationId);
  }

  Future<void> clearAll() async {
    final uid = _uid;
    if (uid == null) return;
    await _db.from('notifications').delete().eq('recipient_id', uid);
  }
}
