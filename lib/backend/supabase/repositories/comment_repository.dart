import '/backend/supabase/supabase.dart';

/// A comment plus its author and like count (from an embedded aggregate).
class Comment {
  Comment(this.data);
  final Map<String, dynamic> data;

  String get id => (data['id'] ?? '').toString();
  String get postId => (data['post_id'] ?? '').toString();
  String get userId => (data['user_id'] ?? '').toString();
  String get body => (data['body'] as String?) ?? '';
  bool get isFood => (data['is_food'] as bool?) ?? false;
  DateTime? get createdAt => data['created_at'] == null
      ? null
      : DateTime.tryParse(data['created_at'].toString());

  Map<String, dynamic> get _author =>
      (data['author'] as Map<String, dynamic>?) ?? const {};
  String get authorUsername => (_author['username'] as String?) ?? '';
  String get authorDisplayName => (_author['display_name'] as String?) ?? '';
  String get authorPhotoUrl => (_author['photo_url'] as String?) ?? '';

  int get likeCount {
    final likes = data['likes'];
    if (likes is List && likes.isNotEmpty) {
      return (likes.first['count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }
}

/// Comments on posts and food posts (one table, distinguished by `is_food`).
class CommentRepository {
  SupabaseClient get _db => supabase;
  String? get _uid => _db.auth.currentUser?.id;

  static const _select =
      '*, author:profiles!comments_user_id_fkey(username,display_name,photo_url), likes:comment_likes(count)';

  Future<List<Comment>> forPost(
    String postId, {
    bool? isFood,
    int limit = 30,
    int offset = 0,
  }) async {
    var query = _db.from('comments').select(_select).eq('post_id', postId);
    if (isFood != null) query = query.eq('is_food', isFood);
    final rows = await query
        .order('created_at', ascending: true)
        .range(offset, offset + limit - 1);
    return (rows as List)
        .map((r) => Comment(r as Map<String, dynamic>))
        .toList();
  }

  Future<Comment> add(String postId, String body, {bool isFood = false}) async {
    final uid = _requireUid();
    final row = await _db
        .from('comments')
        .insert({
          'post_id': postId,
          'user_id': uid,
          'body': body,
          'is_food': isFood,
        })
        .select(_select)
        .single();
    return Comment(row);
  }

  Future<void> delete(String commentId) async {
    await _db.from('comments').delete().eq('id', commentId);
  }

  Future<void> like(String commentId) async {
    final uid = _requireUid();
    await _db.from('comment_likes').upsert(
      {'comment_id': commentId, 'user_id': uid},
      onConflict: 'comment_id,user_id',
      ignoreDuplicates: true,
    );
  }

  Future<void> unlike(String commentId) async {
    final uid = _requireUid();
    await _db
        .from('comment_likes')
        .delete()
        .eq('comment_id', commentId)
        .eq('user_id', uid);
  }

  Future<bool> isLiked(String commentId) async {
    final uid = _uid;
    if (uid == null) return false;
    final row = await _db
        .from('comment_likes')
        .select('comment_id')
        .eq('comment_id', commentId)
        .eq('user_id', uid)
        .maybeSingle();
    return row != null;
  }

  String _requireUid() {
    final uid = _uid;
    if (uid == null)
      throw StateError('No authenticated user for a comment write.');
    return uid;
  }
}
