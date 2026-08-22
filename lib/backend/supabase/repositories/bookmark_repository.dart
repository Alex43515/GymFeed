import '/backend/supabase/supabase.dart';

/// What type of content is bookmarked.
enum BookmarkKind { post, foodPost, training }

extension BookmarkKindX on BookmarkKind {
  String get value {
    switch (this) {
      case BookmarkKind.post:
        return 'post';
      case BookmarkKind.foodPost:
        return 'food_post';
      case BookmarkKind.training:
        return 'training';
    }
  }

  static BookmarkKind fromString(String s) {
    switch (s) {
      case 'food_post':
        return BookmarkKind.foodPost;
      case 'training':
        return BookmarkKind.training;
      default:
        return BookmarkKind.post;
    }
  }
}

class Bookmark {
  Bookmark(this.data);
  final Map<String, dynamic> data;

  String get id => (data['id'] ?? '').toString();
  String get userId => (data['user_id'] ?? '').toString();
  String get targetId =>
      (data['post_id'] ?? data['training_id'] ?? '').toString();
  BookmarkKind get kind =>
      BookmarkKindX.fromString((data['kind'] as String?) ?? 'post');
  DateTime? get createdAt => data['created_at'] == null
      ? null
      : DateTime.tryParse(data['created_at'].toString());
}

/// Save / unsave posts, food posts, and trainings (one table with a `kind` enum).
class BookmarkRepository {
  SupabaseClient get _db => supabase;
  String? get _uid => _db.auth.currentUser?.id;

  /// All bookmarks for the current user, newest first.
  Future<List<Bookmark>> myBookmarks(
      {BookmarkKind? kind, int limit = 30, DateTime? before}) async {
    final uid = _uid;
    if (uid == null) return const [];
    var q = _db.from('bookmarks').select().eq('user_id', uid);
    if (kind != null) q = q.eq('kind', kind.value);
    if (before != null)
      q = q.lt('created_at', before.toUtc().toIso8601String());
    final rows = await q.order('created_at', ascending: false).limit(limit);
    return (rows as List)
        .map((r) => Bookmark(r as Map<String, dynamic>))
        .toList();
  }

  // The bookmarks table stores the target in `post_id` (post/food_post) or
  // `training_id` (training) — not a single `target_id` column.
  String _col(BookmarkKind kind) =>
      kind == BookmarkKind.training ? 'training_id' : 'post_id';

  /// IDs the user has bookmarked for a given [kind] — used for set-membership checks.
  Future<Set<String>> bookmarkedIds(BookmarkKind kind) async {
    final uid = _uid;
    if (uid == null) return const {};
    final col = _col(kind);
    final rows = await _db
        .from('bookmarks')
        .select(col)
        .eq('user_id', uid)
        .eq('kind', kind.value);
    return (rows as List)
        .map((r) => (r[col] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  Future<bool> isBookmarked(String targetId, BookmarkKind kind) async {
    final uid = _uid;
    if (uid == null) return false;
    final row = await _db
        .from('bookmarks')
        .select('id')
        .eq('user_id', uid)
        .eq(_col(kind), targetId)
        .eq('kind', kind.value)
        .maybeSingle();
    return row != null;
  }

  Future<void> add(String targetId, BookmarkKind kind) async {
    final uid = _requireUid();
    try {
      await _db.from('bookmarks').insert({
        'user_id': uid,
        'kind': kind.value,
        _col(kind): targetId,
      });
    } catch (_) {
      // already bookmarked (unique constraint) — ignore.
    }
  }

  Future<void> remove(String targetId, BookmarkKind kind) async {
    final uid = _requireUid();
    await _db
        .from('bookmarks')
        .delete()
        .eq('user_id', uid)
        .eq(_col(kind), targetId)
        .eq('kind', kind.value);
  }

  /// Toggle: adds if absent, removes if present. Returns `true` if now bookmarked.
  Future<bool> toggle(String targetId, BookmarkKind kind) async {
    if (await isBookmarked(targetId, kind)) {
      await remove(targetId, kind);
      return false;
    } else {
      await add(targetId, kind);
      return true;
    }
  }

  String _requireUid() {
    final uid = _uid;
    if (uid == null)
      throw StateError('No authenticated user for a bookmark write.');
    return uid;
  }
}
