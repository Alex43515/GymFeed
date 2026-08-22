import '/backend/supabase/supabase.dart';

class RecentSearch {
  RecentSearch(this.data);
  final Map<String, dynamic> data;

  String get id => (data['id'] ?? '').toString();
  String get query => (data['query'] as String?) ?? '';
  DateTime? get searchedAt => data['searched_at'] == null
      ? null
      : DateTime.tryParse(data['searched_at'].toString());
}

/// Search across profiles and posts, plus a per-user recent-search history.
class SearchRepository {
  SupabaseClient get _db => supabase;
  String? get _uid => _db.auth.currentUser?.id;

  // ── Recent searches ───────────────────────────────────────────────────────

  Future<List<RecentSearch>> recentSearches({int limit = 10}) async {
    final uid = _uid;
    if (uid == null) return const [];
    final rows = await _db
        .from('recent_searches')
        .select()
        .eq('user_id', uid)
        .order('searched_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => RecentSearch(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSearch(String query) async {
    final uid = _uid;
    if (uid == null || query.trim().isEmpty) return;
    await _db.from('recent_searches').upsert(
      {
        'user_id': uid,
        'query': query.trim(),
        'searched_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,query',
      ignoreDuplicates: false,
    );
  }

  Future<void> deleteSearch(String searchId) async {
    await _db.from('recent_searches').delete().eq('id', searchId);
  }

  Future<void> clearSearchHistory() async {
    final uid = _uid;
    if (uid == null) return;
    await _db.from('recent_searches').delete().eq('user_id', uid);
  }

  // ── Profile search ────────────────────────────────────────────────────────

  /// Full-text search on username + display_name. Returns public profile fields.
  /// Persists to recent_searches automatically when [save] is true.
  Future<List<Map<String, dynamic>>> searchProfiles(
    String query, {
    int limit = 20,
    bool save = true,
  }) async {
    if (query.trim().isEmpty) return const [];
    if (save) unawaited(saveSearch(query.trim()));
    final rows = await _db
        .from('profiles')
        .select('id,username,display_name,photo_url,bio')
        .or('username.ilike.%${query.trim()}%,display_name.ilike.%${query.trim()}%')
        .limit(limit);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  // ── Post search ───────────────────────────────────────────────────────────

  /// Caption-based post search (ilike). Keyset-paginated.
  Future<List<Map<String, dynamic>>> searchPosts(
    String query, {
    int limit = 20,
    DateTime? before,
    bool save = false,
  }) async {
    if (query.trim().isEmpty) return const [];
    if (save) unawaited(saveSearch(query.trim()));
    var q = _db
        .from('posts')
        .select(
            'id,caption,photo_url,video_thumbnail,like_count,comment_count,created_at,'
            'author:profiles!posts_user_id_fkey(username,photo_url)')
        .ilike('caption', '%${query.trim()}%');
    if (before != null)
      q = q.lt('created_at', before.toUtc().toIso8601String());
    final rows = await q.order('created_at', ascending: false).limit(limit);
    return (rows as List).cast<Map<String, dynamic>>();
  }
}

/// Fire-and-forget helper — callers don't need to await side-effectful saves.
void unawaited(Future<void> future) {
  future.catchError((_) {});
}
