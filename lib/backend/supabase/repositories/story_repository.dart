import '/backend/supabase/supabase.dart';

class StoryItem {
  const StoryItem({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.expiresAt,
    this.photoUrl = '',
    this.videoUrl = '',
    this.photoAssetId,
    this.videoAssetId,
    this.seenByMe = false,
  });

  final String id;
  final String userId;
  final String photoUrl;
  final String videoUrl;
  final String? photoAssetId;
  final String? videoAssetId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool seenByMe;

  bool get isVideo => videoUrl.isNotEmpty;
  bool get isPhoto => !isVideo && photoUrl.isNotEmpty;
  bool get hasMedia => isVideo || isPhoto;

  StoryItem copyWith({bool? seenByMe}) => StoryItem(
        id: id,
        userId: userId,
        createdAt: createdAt,
        expiresAt: expiresAt,
        photoUrl: photoUrl,
        videoUrl: videoUrl,
        photoAssetId: photoAssetId,
        videoAssetId: videoAssetId,
        seenByMe: seenByMe ?? this.seenByMe,
      );
}

class StoryAuthor {
  const StoryAuthor({
    required this.id,
    required this.username,
    required this.displayName,
    required this.photoUrl,
  });

  final String id;
  final String username;
  final String displayName;
  final String photoUrl;

  String get label => username.trim().isNotEmpty
      ? username.trim()
      : displayName.trim().isNotEmpty
          ? displayName.trim()
          : 'GymFeed user';
}

class StoryGroup {
  const StoryGroup({required this.author, required this.stories});

  final StoryAuthor author;
  final List<StoryItem> stories;

  bool get allSeen =>
      stories.isNotEmpty && stories.every((story) => story.seenByMe);
  bool get hasUnseen => stories.any((story) => !story.seenByMe);
  DateTime get latestAt => stories.fold<DateTime>(
        DateTime.fromMillisecondsSinceEpoch(0),
        (latest, story) =>
            story.createdAt.isAfter(latest) ? story.createdAt : latest,
      );

  StoryGroup copyWith({List<StoryItem>? stories}) =>
      StoryGroup(author: author, stories: stories ?? this.stories);
}

class StoryViewerProfile {
  const StoryViewerProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.photoUrl,
    required this.viewedAt,
  });

  final String id;
  final String username;
  final String displayName;
  final String photoUrl;
  final DateTime viewedAt;

  String get label => username.isNotEmpty
      ? username
      : displayName.isNotEmpty
          ? displayName
          : 'GymFeed user';
}

abstract class StoryDataSource {
  String? get currentUserId;

  Future<List<StoryGroup>> loadTray();
  Future<StoryGroup?> loadForUser(String userId);

  Future<StoryItem> create({
    String? photoAssetId,
    String? videoAssetId,
    String? photoUrl,
    String? videoUrl,
    DateTime? expiresAt,
  });

  Future<void> delete(String storyId);
  Future<void> recordView(String storyId);
  Future<List<StoryViewerProfile>> viewerProfiles(String storyId);
}

class StoryRepository implements StoryDataSource {
  SupabaseClient get _db => supabase;

  @override
  String? get currentUserId => _db.auth.currentUser?.id;

  String get _nowIso => DateTime.now().toUtc().toIso8601String();

  @override
  Future<List<StoryGroup>> loadTray() async {
    final uid = currentUserId;
    if (uid == null) return const [];

    final followRows =
        await _db.from('follows').select('followee_id').eq('follower_id', uid);
    final userIds = <String>{
      uid,
      for (final row in followRows)
        if ((row['followee_id'] ?? '').toString().isNotEmpty)
          row['followee_id'].toString(),
    }.toList();

    final storyRows = (await _db
            .from('stories')
            .select()
            .inFilter('user_id', userIds)
            .gt('expires_at', _nowIso)
            .order('created_at', ascending: true) as List)
        .cast<Map<String, dynamic>>();
    if (storyRows.isEmpty) return const [];

    final storyIds = storyRows.map((row) => row['id'].toString()).toList();
    final profileRows = (await _db
            .from('profiles')
            .select('id, username, display_name, photo_url')
            .inFilter('id', userIds) as List)
        .cast<Map<String, dynamic>>();

    var seenIds = <String>{};
    try {
      final viewRows = await _db
          .from('story_views')
          .select('story_id')
          .eq('viewer_id', uid)
          .inFilter('story_id', storyIds);
      seenIds = {
        for (final row in viewRows) (row['story_id'] ?? '').toString(),
      }..remove('');
    } catch (_) {
      // Migration 0015 gives viewers access to their own receipts. Until then,
      // Stories remain usable and are simply presented as unseen.
    }

    final videoAssetIds = storyRows
        .map((row) => (row['video_asset_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    var playbackByAsset = <String, String>{};
    if (videoAssetIds.isNotEmpty) {
      try {
        final mediaRows = await _db
            .from('media_assets')
            .select('id, playback_url')
            .inFilter('id', videoAssetIds);
        playbackByAsset = {
          for (final row in mediaRows)
            (row['id'] ?? '').toString():
                (row['playback_url'] ?? '').toString(),
        };
      } catch (_) {}
    }

    return groupStoryRows(
      storyRows: storyRows,
      profileRows: profileRows,
      seenStoryIds: seenIds,
      playbackByAsset: playbackByAsset,
      currentUserId: uid,
    );
  }

  @override
  Future<StoryGroup?> loadForUser(String userId) async {
    final uid = currentUserId;
    if (uid == null || userId.isEmpty) return null;
    final storyRows = (await _db
            .from('stories')
            .select()
            .eq('user_id', userId)
            .gt('expires_at', _nowIso)
            .order('created_at', ascending: true) as List)
        .cast<Map<String, dynamic>>();
    if (storyRows.isEmpty) return null;
    final profile = await _db
        .from('profiles')
        .select('id, username, display_name, photo_url')
        .eq('id', userId)
        .maybeSingle();
    final storyIds = storyRows.map((row) => row['id'].toString()).toList();
    var seenIds = <String>{};
    try {
      final views = await _db
          .from('story_views')
          .select('story_id')
          .eq('viewer_id', uid)
          .inFilter('story_id', storyIds);
      seenIds = {
        for (final row in views) (row['story_id'] ?? '').toString(),
      }..remove('');
    } catch (_) {}
    final assetIds = storyRows
        .map((row) => (row['video_asset_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    var playback = <String, String>{};
    if (assetIds.isNotEmpty) {
      try {
        final assets = await _db
            .from('media_assets')
            .select('id, playback_url')
            .inFilter('id', assetIds);
        playback = {
          for (final row in assets)
            (row['id'] ?? '').toString():
                (row['playback_url'] ?? '').toString(),
        };
      } catch (_) {}
    }
    final groups = groupStoryRows(
      storyRows: storyRows,
      profileRows: [if (profile != null) profile],
      seenStoryIds: seenIds,
      playbackByAsset: playback,
      currentUserId: uid,
    );
    return groups.isEmpty ? null : groups.first;
  }

  @override
  Future<StoryItem> create({
    String? photoAssetId,
    String? videoAssetId,
    String? photoUrl,
    String? videoUrl,
    DateTime? expiresAt,
  }) async {
    final uid = _requireUid();
    if ((photoUrl ?? '').isEmpty && (videoUrl ?? '').isEmpty) {
      throw ArgumentError('A Story needs a photo or video.');
    }
    final row = await _db
        .from('stories')
        .insert({
          'user_id': uid,
          if (photoAssetId != null && photoAssetId.isNotEmpty)
            'photo_asset_id': photoAssetId,
          if (videoAssetId != null && videoAssetId.isNotEmpty)
            'video_asset_id': videoAssetId,
          if (photoUrl != null && photoUrl.isNotEmpty)
            'legacy_photo_url': photoUrl,
          if (videoUrl != null && videoUrl.isNotEmpty)
            'legacy_video_url': videoUrl,
          'expires_at': (expiresAt ??
                  DateTime.now().toUtc().add(const Duration(hours: 24)))
              .toIso8601String(),
        })
        .select()
        .single();
    return _itemFromRow(row, seen: false, playbackByAsset: const {});
  }

  @override
  Future<void> delete(String storyId) async {
    final uid = _requireUid();
    await _db.from('stories').delete().eq('id', storyId).eq('user_id', uid);
  }

  @override
  Future<void> recordView(String storyId) async {
    final uid = _requireUid();
    await _db.from('story_views').upsert(
      {
        'story_id': storyId,
        'viewer_id': uid,
        'viewed_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'story_id,viewer_id',
    );
  }

  @override
  Future<List<StoryViewerProfile>> viewerProfiles(String storyId) async {
    final rows = (await _db
            .from('story_views')
            .select('viewer_id, viewed_at')
            .eq('story_id', storyId)
            .order('viewed_at', ascending: false) as List)
        .cast<Map<String, dynamic>>();
    if (rows.isEmpty) return const [];
    final ids = rows.map((row) => row['viewer_id'].toString()).toList();
    final profiles = (await _db
            .from('profiles')
            .select('id, username, display_name, photo_url')
            .inFilter('id', ids) as List)
        .cast<Map<String, dynamic>>();
    final profileById = {for (final row in profiles) row['id'].toString(): row};
    return rows.map((row) {
      final id = row['viewer_id'].toString();
      final profile = profileById[id] ?? const <String, dynamic>{};
      return StoryViewerProfile(
        id: id,
        username: (profile['username'] ?? '').toString(),
        displayName: (profile['display_name'] ?? '').toString(),
        photoUrl: (profile['photo_url'] ?? '').toString(),
        viewedAt: DateTime.tryParse((row['viewed_at'] ?? '').toString()) ??
            DateTime.now(),
      );
    }).toList();
  }

  String _requireUid() {
    final uid = currentUserId;
    if (uid == null) throw StateError('Sign in to use Stories.');
    return uid;
  }
}

List<StoryGroup> groupStoryRows({
  required List<Map<String, dynamic>> storyRows,
  required List<Map<String, dynamic>> profileRows,
  required Set<String> seenStoryIds,
  required Map<String, String> playbackByAsset,
  required String currentUserId,
}) {
  final profiles = {
    for (final row in profileRows) (row['id'] ?? '').toString(): row,
  };
  final byUser = <String, List<StoryItem>>{};
  for (final row in storyRows) {
    final id = (row['id'] ?? '').toString();
    final userId = (row['user_id'] ?? '').toString();
    if (id.isEmpty || userId.isEmpty) continue;
    final item = _itemFromRow(
      row,
      seen: seenStoryIds.contains(id),
      playbackByAsset: playbackByAsset,
    );
    if (!item.hasMedia) continue;
    byUser.putIfAbsent(userId, () => []).add(item);
  }

  final groups = byUser.entries.map((entry) {
    entry.value.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final profile = profiles[entry.key] ?? const <String, dynamic>{};
    return StoryGroup(
      author: StoryAuthor(
        id: entry.key,
        username: (profile['username'] ?? '').toString(),
        displayName: (profile['display_name'] ?? '').toString(),
        photoUrl: (profile['photo_url'] ?? '').toString(),
      ),
      stories: List.unmodifiable(entry.value),
    );
  }).toList();

  groups.sort((a, b) {
    if (a.author.id == currentUserId) return -1;
    if (b.author.id == currentUserId) return 1;
    if (a.hasUnseen != b.hasUnseen) return a.hasUnseen ? -1 : 1;
    return b.latestAt.compareTo(a.latestAt);
  });
  return groups;
}

StoryItem _itemFromRow(
  Map<String, dynamic> row, {
  required bool seen,
  required Map<String, String> playbackByAsset,
}) {
  final videoAssetId = (row['video_asset_id'] ?? '').toString();
  final legacyVideoUrl = (row['legacy_video_url'] ?? '').toString();
  return StoryItem(
    id: (row['id'] ?? '').toString(),
    userId: (row['user_id'] ?? '').toString(),
    photoUrl: (row['legacy_photo_url'] ?? '').toString(),
    videoUrl: playbackByAsset[videoAssetId]?.isNotEmpty == true
        ? playbackByAsset[videoAssetId]!
        : legacyVideoUrl,
    photoAssetId: (row['photo_asset_id'] as String?),
    videoAssetId: videoAssetId.isEmpty ? null : videoAssetId,
    createdAt: DateTime.tryParse((row['created_at'] ?? '').toString()) ??
        DateTime.now(),
    expiresAt: DateTime.tryParse((row['expires_at'] ?? '').toString()) ??
        DateTime.now().add(const Duration(hours: 24)),
    seenByMe: seen,
  );
}
