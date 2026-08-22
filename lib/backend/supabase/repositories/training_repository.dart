import '/backend/supabase/supabase.dart';

class Training {
  Training(this.data);
  final Map<String, dynamic> data;

  String get id => (data['id'] ?? '').toString();
  String get userId => (data['user_id'] ?? '').toString();
  String get title => (data['title'] as String?) ?? '';
  String? get description => data['description'] as String?;
  String get category => (data['category'] as String?) ?? '';
  String get difficultyLevel => (data['difficulty_level'] as String?) ?? '';
  String get trainingDateRaw => (data['training_date_raw'] as String?) ?? '';
  String get trainingTimeRaw => (data['training_time_raw'] as String?) ?? '';
  DateTime? get startsAt => data['starts_at'] == null
      ? null
      : DateTime.tryParse(data['starts_at'].toString());
  int get duration =>
      (data['duration'] as num?)?.toInt() ??
      (data['session_duration'] as num?)?.toInt() ??
      0;
  String? get photoAssetId => data['photo_asset_id'] as String?;
  String? get videoAssetId => data['video_asset_id'] as String?;

  /// Workout covers are stored in `background_image`. `legacy_photo_url` is
  /// accepted for pre-Supabase rows so old events remain visible.
  String? get legacyPhotoUrl =>
      (data['background_image'] as String?) ??
      (data['legacy_photo_url'] as String?);
  String get backgroundImage => legacyPhotoUrl ?? '';
  String? get legacyVideoUrl => data['legacy_video_url'] as String?;
  String? get videoThumbnail => data['video_thumbnail'] as String?;
  int get likeCount => (data['like_count'] as num?)?.toInt() ?? 0;
  int get participantCount => (data['participant_count'] as num?)?.toInt() ?? 0;
  double? get locationLat => (data['location_lat'] as num?)?.toDouble();
  double? get locationLng => (data['location_lng'] as num?)?.toDouble();
  String get videoUrl {
    final direct = legacyVideoUrl?.trim() ?? '';
    if (direct.isNotEmpty) return direct;
    final asset = data['video_asset'];
    if (asset is Map) return (asset['playback_url'] ?? '').toString();
    return '';
  }

  String get coverUrl {
    if (backgroundImage.trim().isNotEmpty) return backgroundImage.trim();
    if ((videoThumbnail ?? '').trim().isNotEmpty) {
      return videoThumbnail!.trim();
    }
    final asset = data['video_asset'];
    if (asset is Map) return (asset['thumbnail_url'] ?? '').toString();
    return '';
  }

  DateTime? get createdAt => data['created_at'] == null
      ? null
      : DateTime.tryParse(data['created_at'].toString());

  Map<String, dynamic> get _author =>
      (data['author'] as Map<String, dynamic>?) ?? const {};
  String get authorId => (_author['id'] as String?) ?? userId;
  String get authorUsername => (_author['username'] as String?) ?? '';
  String get authorDisplayName => (_author['display_name'] as String?) ?? '';
  String get authorPhotoUrl => (_author['photo_url'] as String?) ?? '';

  bool get likedByMe {
    if (data['liked_by_me'] == true) return true;
    final likes = data['my_like'];
    if (likes is List) return likes.isNotEmpty;
    return false;
  }

  bool get joinedByMe {
    if (data['joined_by_me'] == true) return true;
    final parts = data['my_participation'];
    if (parts is List) return parts.isNotEmpty;
    return false;
  }
}

/// Training (reels) feed and participation.
class TrainingRepository {
  SupabaseClient get _db => supabase;
  String? get _uid => _db.auth.currentUser?.id;

  static const _select =
      '*, author:profiles!user_trainings_user_id_fkey(id,username,display_name,photo_url),'
      ' video_asset:media_assets!user_trainings_video_asset_id_fkey(playback_url,thumbnail_url,status)';

  /// Keyset-paginated training feed — newest first (reels scroll order).
  Future<List<Training>> feed({int limit = 10, DateTime? before}) async {
    var q = _db.from('user_trainings').select(_select);
    if (before != null)
      q = q.lt('created_at', before.toUtc().toIso8601String());
    final rows = await q.order('created_at', ascending: false).limit(limit);
    return _decorate(rows as List);
  }

  /// FitClips is a workout-video surface. It must never fall back to generic
  /// social posts, photos, or food posts.
  Future<List<Training>> videoFeed({int limit = 30}) async {
    final rows = await _db
        .from('user_trainings')
        .select(_select)
        .or('legacy_video_url.neq.,video_asset_id.not.is.null')
        .order('created_at', ascending: false)
        .limit(limit);
    final trainings = await _decorate(rows as List);
    return trainings
        .where((training) => training.videoUrl.trim().isNotEmpty)
        .toList(growable: false);
  }

  /// Trainings posted by a specific user.
  Future<List<Training>> byUser(String userId,
      {int limit = 20, DateTime? before}) async {
    var q = _db.from('user_trainings').select(_select).eq('user_id', userId);
    if (before != null)
      q = q.lt('created_at', before.toUtc().toIso8601String());
    final rows = await q.order('created_at', ascending: false).limit(limit);
    return _decorate(rows as List);
  }

  Future<List<Training>> joinedByCurrentUser({int limit = 100}) async {
    final uid = _requireUid();
    final participantRows = await _db
        .from('training_participants')
        .select('training_id')
        .eq('user_id', uid)
        .limit(limit);
    final ids = (participantRows as List)
        .map((row) => (row as Map<String, dynamic>)['training_id'].toString())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (ids.isEmpty) return const [];
    final rows = await _db
        .from('user_trainings')
        .select(_select)
        .inFilter('id', ids)
        .order('created_at', ascending: false);
    return _decorate(rows as List, forcedJoinedIds: ids.toSet());
  }

  Future<Training?> get(String trainingId) async {
    final row = await _db
        .from('user_trainings')
        .select(_select)
        .eq('id', trainingId)
        .maybeSingle();
    if (row == null) return null;
    final decorated = await _decorate(<dynamic>[row]);
    return decorated.isEmpty ? null : decorated.first;
  }

  Future<Training> create({
    required String title,
    String? description,
    String? photoAssetId,
    String? videoAssetId,
    String? legacyPhotoUrl,
    String? legacyVideoUrl,
    String? videoThumbnail,
  }) async {
    final uid = _requireUid();
    final row = await _db
        .from('user_trainings')
        .insert({
          'user_id': uid,
          'title': title,
          if (description != null) 'description': description,
          if (photoAssetId != null) 'photo_asset_id': photoAssetId,
          if (videoAssetId != null) 'video_asset_id': videoAssetId,
          if (legacyPhotoUrl != null) 'background_image': legacyPhotoUrl,
          if (legacyVideoUrl != null) 'legacy_video_url': legacyVideoUrl,
          if (videoThumbnail != null) 'video_thumbnail': videoThumbnail,
        })
        .select(_select)
        .single();
    return Training(row);
  }

  Future<void> delete(String trainingId) async {
    await _db.from('user_trainings').delete().eq('id', trainingId);
  }

  // ── Likes ─────────────────────────────────────────────────────────────────

  Future<void> like(String trainingId) async {
    final uid = _requireUid();
    await _db.from('training_likes').upsert(
      {'training_id': trainingId, 'user_id': uid},
      onConflict: 'training_id,user_id',
      ignoreDuplicates: true,
    );
  }

  Future<void> unlike(String trainingId) async {
    final uid = _requireUid();
    await _db
        .from('training_likes')
        .delete()
        .eq('training_id', trainingId)
        .eq('user_id', uid);
  }

  // ── Participation ─────────────────────────────────────────────────────────

  Future<void> join(String trainingId) async {
    final uid = _requireUid();
    await _db.from('training_participants').upsert(
      {'training_id': trainingId, 'user_id': uid},
      onConflict: 'training_id,user_id',
      ignoreDuplicates: true,
    );
  }

  Future<void> leave(String trainingId) async {
    final uid = _requireUid();
    await _db
        .from('training_participants')
        .delete()
        .eq('training_id', trainingId)
        .eq('user_id', uid);
  }

  Future<List<Map<String, dynamic>>> participants(String trainingId) async {
    final rows = await _db
        .from('training_participants')
        .select(
            'user_id, profile:profiles!training_participants_user_id_fkey(username,photo_url)')
        .eq('training_id', trainingId);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<List<Training>> _decorate(
    List<dynamic> rows, {
    Set<String> forcedJoinedIds = const {},
  }) async {
    final copied = rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
    final uid = _uid;
    if (uid == null || copied.isEmpty) {
      return copied.map(Training.new).toList(growable: false);
    }
    final ids = copied.map((row) => row['id'].toString()).toList();
    final results = await Future.wait<dynamic>([
      _db
          .from('training_likes')
          .select('training_id')
          .eq('user_id', uid)
          .inFilter('training_id', ids),
      _db
          .from('training_participants')
          .select('training_id')
          .eq('user_id', uid)
          .inFilter('training_id', ids),
      _db.from('user_blocks').select('blocked_id').eq('blocker_id', uid),
    ]);
    final liked = (results[0] as List)
        .map((row) => (row as Map)['training_id'].toString())
        .toSet();
    final joined = <String>{
      ...forcedJoinedIds,
      ...(results[1] as List)
          .map((row) => (row as Map)['training_id'].toString()),
    };
    final blockedIds = (results[2] as List)
        .map((row) => (row as Map)['blocked_id'].toString())
        .toSet();
    final visible = copied
        .where((row) => !blockedIds.contains(row['user_id'].toString()))
        .toList(growable: false);
    for (final row in visible) {
      final id = row['id'].toString();
      row['liked_by_me'] = liked.contains(id);
      row['joined_by_me'] = joined.contains(id);
    }
    return visible.map(Training.new).toList(growable: false);
  }

  String _requireUid() {
    final uid = _uid;
    if (uid == null)
      throw StateError('No authenticated user for a training write.');
    return uid;
  }
}
