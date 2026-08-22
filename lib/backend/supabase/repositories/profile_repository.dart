import '/backend/supabase/supabase.dart';
import '/backend/supabase/database/profile.dart';

/// A single, consistent snapshot of the social relationship around a profile.
/// Keeping these values together prevents the UI from mixing fresh Supabase
/// counts with the legacy Firestore `following` arrays.
class ProfileSocialState {
  const ProfileSocialState({
    required this.isFollowing,
    required this.followsYou,
    required this.followerCount,
    required this.followingCount,
  });

  final bool isFollowing;
  final bool followsYou;
  final int followerCount;
  final int followingCount;
}

enum AccountBlockRelationship { none, blockedByMe, blockedMe }

/// All reads/writes for user profiles, following, and blocking.
/// Replaces the Firestore `users` collection access scattered across widgets.
class ProfileRepository {
  SupabaseClient get _db => supabase;
  String? get _uid => _db.auth.currentUser?.id;

  // ---------------------------------------------------------------- reads

  /// The current user's full profile (public + private joined). Null if signed out.
  Future<Profile?> getMyProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    final row = await _db
        .from('profiles')
        .select('*, profile_private(*)')
        .eq('id', uid)
        .maybeSingle();
    if (row == null) return null;
    // Attach the set of users this account follows so `Profile.following`
    // (used by follow-state checks across the app) reflects reality.
    try {
      final follows = await _db
          .from('follows')
          .select('followee_id')
          .eq('follower_id', uid);
      row['_following_ids'] = (follows as List)
          .map((r) => (r['followee_id'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {}
    return Profile(row);
  }

  /// True when no existing profile uses [username] (case-insensitive).
  /// Used by the sign-up "Register Account" step to flag a taken username
  /// before the account is created. `profiles` is publicly readable, so this
  /// works pre-auth. Escapes LIKE wildcards so `_`/`%` are matched literally.
  Future<bool> isUsernameAvailable(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return false;
    if (!RegExp(r'^[A-Za-z0-9_]{3,30}$').hasMatch(trimmed)) return false;

    // The RPC checks both verified profiles and usernames reserved by pending
    // email-verification signups. It is also atomic with the auth trigger, so
    // this UI hint is backed by the same rule used when the account is made.
    try {
      final result = await _db.rpc(
        'is_username_available',
        params: {'candidate': trimmed},
      );
      if (result is bool) return result;
    } catch (_) {
      // Keep older/local schemas usable until migration 0025 is applied.
    }

    final escaped = trimmed
        .replaceAll('\\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    final row = await _db
        .from('profiles')
        .select('id')
        .ilike('username', escaped)
        .limit(1)
        .maybeSingle();
    return row == null;
  }

  /// Any user's public profile (private fields fall back to defaults via RLS).
  Future<Profile?> getPublicProfile(String userId) async {
    final row =
        await _db.from('profiles').select().eq('id', userId).maybeSingle();
    return row == null ? null : Profile(row);
  }

  /// Resolve a public profile by the username used in profile routes.
  Future<Profile?> getPublicProfileByUsername(String username) async {
    final normalized = username.trim().replaceFirst(RegExp(r'^@'), '');
    if (normalized.isEmpty) return null;
    final escaped = normalized
        .replaceAll('\\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    final row = await _db
        .from('profiles')
        .select()
        .ilike('username', escaped)
        .limit(1)
        .maybeSingle();
    return row == null ? null : Profile(row);
  }

  /// Live updates to the current user's public profile row.
  Stream<Profile?> watchMyProfile() {
    final uid = _uid;
    if (uid == null) return Stream.value(null);
    return _db
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', uid)
        .map((rows) => rows.isEmpty ? null : Profile(rows.first));
  }

  // --------------------------------------------------------------- writes

  /// Update public identity fields on `profiles`.
  Future<void> updatePublicProfile({
    String? username,
    String? displayName,
    String? photoUrl,
    String? bio,
    String? website,
    String? customLink,
  }) async {
    final uid = _requireUid();
    final patch = <String, dynamic>{
      if (username != null) 'username': username,
      if (displayName != null) 'display_name': displayName,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (bio != null) 'bio': bio,
      if (website != null) 'website': website,
      if (customLink != null) 'custom_link': customLink,
    };
    if (patch.isEmpty) return;
    await _db.from('profiles').update(patch).eq('id', uid);
  }

  /// Update private fields on `profile_private` (fitness data, AI outputs, UI
  /// state). Keys are snake_case column names.
  Future<void> updatePrivateProfile(Map<String, dynamic> fields) async {
    final uid = _requireUid();
    if (fields.isEmpty) return;
    await _db.from('profile_private').update(fields).eq('id', uid);
  }

  // --------------------------------------------------------------- follows

  Future<bool> isFollowing(String targetUserId) async {
    final uid = _uid;
    if (uid == null) return false;
    final row = await _db
        .from('follows')
        .select('follower_id')
        .eq('follower_id', uid)
        .eq('followee_id', targetUserId)
        .maybeSingle();
    return row != null;
  }

  Future<void> follow(String targetUserId) async {
    final uid = _requireUid();
    if (targetUserId.isEmpty || targetUserId == uid) return;
    if (!await canViewAccount(targetUserId)) {
      throw StateError('This account is unavailable.');
    }
    await _db.from('follows').upsert(
      {'follower_id': uid, 'followee_id': targetUserId},
      onConflict: 'follower_id,followee_id',
      ignoreDuplicates: true,
    );
  }

  Future<void> unfollow(String targetUserId) async {
    final uid = _requireUid();
    await _db
        .from('follows')
        .delete()
        .eq('follower_id', uid)
        .eq('followee_id', targetUserId);
  }

  /// Whether [targetUserId] follows the signed-in user.
  Future<bool> isFollowedBy(String targetUserId) async {
    final uid = _uid;
    if (uid == null || targetUserId.isEmpty) return false;
    final row = await _db
        .from('follows')
        .select('follower_id')
        .eq('follower_id', targetUserId)
        .eq('followee_id', uid)
        .maybeSingle();
    return row != null;
  }

  /// Load the button state and both visible counters from the same source.
  Future<ProfileSocialState> socialState(String userId) async {
    final values = await Future.wait<dynamic>([
      isFollowing(userId),
      isFollowedBy(userId),
      followerCount(userId),
      followingCount(userId),
    ]);
    return ProfileSocialState(
      isFollowing: values[0] as bool,
      followsYou: values[1] as bool,
      followerCount: values[2] as int,
      followingCount: values[3] as int,
    );
  }

  Future<int> followerCount(String userId) =>
      _count('follows', 'followee_id', userId);
  Future<int> followingCount(String userId) =>
      _count('follows', 'follower_id', userId);

  /// Profiles this user follows (paginated).
  Future<List<Profile>> following(String userId,
      {int limit = 30, int offset = 0}) async {
    final rows = await _db
        .from('follows')
        .select('profiles!follows_followee_id_fkey(*)')
        .eq('follower_id', userId)
        .range(offset, offset + limit - 1);
    return _profilesFromJoin(rows, 'profiles');
  }

  /// Profiles that follow this user (paginated).
  Future<List<Profile>> followers(String userId,
      {int limit = 30, int offset = 0}) async {
    final rows = await _db
        .from('follows')
        .select('profiles!follows_follower_id_fkey(*)')
        .eq('followee_id', userId)
        .range(offset, offset + limit - 1);
    return _profilesFromJoin(rows, 'profiles');
  }

  // --------------------------------------------------------------- blocking

  Future<void> block(String targetUserId) async {
    final uid = _requireUid();
    if (targetUserId.isEmpty || targetUserId == uid) {
      throw ArgumentError('You cannot block this account.');
    }
    try {
      await _db.rpc('block_user', params: {'p_blocked_id': targetUserId});
    } catch (_) {
      // Works before the hardening migration is deployed. The RPC additionally
      // removes follows in both directions; this fallback removes the edge the
      // signed-in user owns and still enforces content filtering immediately.
      await _db.from('user_blocks').upsert(
        {'blocker_id': uid, 'blocked_id': targetUserId},
        onConflict: 'blocker_id,blocked_id',
        ignoreDuplicates: true,
      );
      await _db
          .from('follows')
          .delete()
          .eq('follower_id', uid)
          .eq('followee_id', targetUserId);
    }
  }

  Future<void> unblock(String targetUserId) async {
    final uid = _requireUid();
    try {
      await _db.rpc('unblock_user', params: {'p_blocked_id': targetUserId});
    } catch (_) {
      await _db
          .from('user_blocks')
          .delete()
          .eq('blocker_id', uid)
          .eq('blocked_id', targetUserId);
    }
  }

  /// Returns which side of a block the signed-in user is on. The RPC is needed
  /// because RLS intentionally prevents clients from enumerating other users'
  /// block lists.
  Future<AccountBlockRelationship> blockRelationship(
      String targetUserId) async {
    final uid = _uid;
    if (uid == null || targetUserId.isEmpty || targetUserId == uid) {
      return AccountBlockRelationship.none;
    }
    try {
      final value = await _db.rpc(
        'account_block_relationship',
        params: {'p_account_id': targetUserId},
      );
      switch (value?.toString()) {
        case 'blocked_by_me':
          return AccountBlockRelationship.blockedByMe;
        case 'blocked_me':
          return AccountBlockRelationship.blockedMe;
      }
    } catch (_) {
      // Compatibility with installations before migration 0027. RLS permits
      // checking only the signed-in user's own block rows.
      final row = await _db
          .from('user_blocks')
          .select('blocked_id')
          .eq('blocker_id', uid)
          .eq('blocked_id', targetUserId)
          .maybeSingle();
      if (row != null) return AccountBlockRelationship.blockedByMe;
    }
    return AccountBlockRelationship.none;
  }

  Future<bool> canViewAccount(String targetUserId) async {
    return await blockRelationship(targetUserId) ==
        AccountBlockRelationship.none;
  }

  /// Accounts blocked by the signed-in user, for Settings > Blocked accounts.
  Future<List<Profile>> blockedAccounts() async {
    final uid = _requireUid();
    try {
      final rows = await _db
          .from('user_blocks')
          .select('profiles!user_blocks_blocked_id_fkey(*)')
          .eq('blocker_id', uid)
          .order('created_at', ascending: false);
      return _profilesFromJoin(rows, 'profiles');
    } catch (_) {
      final rows = await _db
          .from('user_blocks')
          .select('blocked_id')
          .eq('blocker_id', uid)
          .order('created_at', ascending: false);
      final profiles = await Future.wait((rows as List).map((row) =>
          getPublicProfile(
              (row as Map<String, dynamic>)['blocked_id'].toString())));
      return profiles.whereType<Profile>().toList();
    }
  }

  // --------------------------------------------------------------- search

  Future<List<Profile>> search(String query, {int limit = 20}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final rows = await _db
        .from('profiles')
        .select()
        .or('username.ilike.%$q%,display_name.ilike.%$q%')
        .limit(limit);
    final profiles =
        (rows as List).map((r) => Profile(r as Map<String, dynamic>)).toList();
    return _withoutBlocked(profiles);
  }

  /// Suggested people for New Message when no search query is entered.
  Future<List<Profile>> suggested({int limit = 20}) async {
    final uid = _uid;
    var query = _db.from('profiles').select();
    if (uid != null) query = query.neq('id', uid);
    final rows = await query.order('created_at', ascending: false).limit(limit);
    final profiles = (rows as List)
        .map((row) => Profile(row as Map<String, dynamic>))
        .toList();
    return _withoutBlocked(profiles);
  }

  // --------------------------------------------------------------- helpers

  String _requireUid() {
    final uid = _uid;
    if (uid == null) {
      throw StateError('No authenticated user for a profile write.');
    }
    return uid;
  }

  Future<int> _count(String table, String column, String value) async {
    final res =
        await _db.from(table).count(CountOption.exact).eq(column, value);
    return res;
  }

  List<Profile> _profilesFromJoin(dynamic rows, String key) {
    return (rows as List)
        .map((r) => (r as Map<String, dynamic>)[key])
        .whereType<Map<String, dynamic>>()
        .map((m) => Profile(m))
        .toList();
  }

  Future<List<Profile>> _withoutBlocked(List<Profile> profiles) async {
    if (_uid == null || profiles.isEmpty) return profiles;
    final visible = await Future.wait(
      profiles.map((profile) => canViewAccount(profile.id)),
    );
    return <Profile>[
      for (var i = 0; i < profiles.length; i++)
        if (visible[i]) profiles[i],
    ];
  }
}
