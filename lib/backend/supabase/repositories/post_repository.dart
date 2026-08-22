import '/backend/supabase/supabase.dart';
import '/backend/supabase/database/feed_item.dart';
import '/backend/supabase/repositories/profile_repository.dart';

/// Feed, reels, and post writes. The read path uses the keyset-paginated
/// `feed_page()` RPC — one round-trip, no N+1 — replacing the old reels screen
/// that streamed the entire collection.
class PostRepository {
  SupabaseClient get _db => supabase;
  String? get _uid => _db.auth.currentUser?.id;

  /// Home feed / reels page. Pass the `createdAt` of the last item you have as
  /// `before` to fetch the next page (keyset pagination).
  Future<List<FeedItem>> feedPage({DateTime? before, int limit = 10}) async {
    final rows = await _db.rpc('feed_page', params: {
      'p_before': before?.toIso8601String(),
      'p_limit': limit,
    });
    return (rows as List)
        .map((r) => FeedItem(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> likePost(String postId) async {
    final uid = _requireUid();
    await _db.from('post_likes').upsert(
      {'post_id': postId, 'user_id': uid},
      onConflict: 'post_id,user_id',
      ignoreDuplicates: true,
    );
  }

  Future<void> unlikePost(String postId) async {
    final uid = _requireUid();
    await _db
        .from('post_likes')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', uid);
  }

  /// Soft delete (schema keeps posts with a `deleted` flag).
  Future<void> deletePost(String postId) async {
    final uid = _requireUid();
    final updated = await _db
        .from('posts')
        .update({'deleted': true})
        .eq('id', postId)
        .eq('user_id', uid)
        .select('id')
        .maybeSingle();
    if (updated == null) {
      throw StateError('Post was not found or is not owned by this user.');
    }
  }

  /// Enable or disable interactions on an owned post.
  ///
  /// The explicit owner filter mirrors RLS and the selected row makes a denied
  /// or stale write observable to the UI instead of silently looking successful.
  Future<void> updateInteractionPermissions(
    String postId, {
    bool? allowComments,
    bool? allowLikes,
  }) async {
    final uid = _requireUid();
    final fields = <String, dynamic>{
      if (allowComments != null) 'allow_comments': allowComments,
      if (allowLikes != null) 'allow_likes': allowLikes,
    };
    if (fields.isEmpty) return;

    final updated = await _db
        .from('posts')
        .update(fields)
        .eq('id', postId)
        .eq('user_id', uid)
        .select('id')
        .maybeSingle();
    if (updated == null) {
      throw StateError('Post was not found or is not owned by this user.');
    }
  }

  /// Create a post. Media is stored as direct URLs (Supabase Storage for photos,
  /// Bunny HLS for video) in `legacy_photo_url`/`legacy_video_url`; `feed_page`
  /// coalesces to these when no `media_assets` id is linked. NOT NULL text
  /// columns fall back to their DB defaults.
  Future<String> createPost({
    String caption = '',
    String? photoUrl,
    String? videoUrl,
    String? videoThumbnail,
    String? videoAssetId,
    bool foodPost = false,
    String? location,
    bool allowComments = true,
    bool allowLikes = true,
    // Food-post fields
    String? foodTitle,
    String? foodDescription,
    String? recipe,
    String? nutritionFacts,
    String? cookingTime,
    String? mealType,
    int? calories,
    int? protein,
    String? fats,
    String? carbs,
    // Call-to-action
    bool callToActionEnabled = false,
    String? callToActionText,
    String? callToActionLink,
    String? labels,
  }) async {
    final uid = _requireUid();
    final row = await _db
        .from('posts')
        .insert({
          'user_id': uid,
          'caption': caption,
          'food_post': foodPost,
          'allow_comments': allowComments,
          'allow_likes': allowLikes,
          if (photoUrl != null && photoUrl.isNotEmpty)
            'legacy_photo_url': photoUrl,
          if (videoUrl != null && videoUrl.isNotEmpty)
            'legacy_video_url': videoUrl,
          if (videoAssetId != null && videoAssetId.isNotEmpty)
            'video_asset_id': videoAssetId,
          if (videoThumbnail != null && videoThumbnail.isNotEmpty)
            'video_thumbnail': videoThumbnail,
          if (location != null && location.isNotEmpty) 'location': location,
          if (foodTitle != null) 'food_title': foodTitle,
          if (foodDescription != null) 'food_description': foodDescription,
          if (recipe != null) 'recipe': recipe,
          if (nutritionFacts != null) 'nutrition_facts': nutritionFacts,
          if (cookingTime != null) 'cooking_time': cookingTime,
          if (mealType != null) 'meal_type': mealType,
          if (calories != null) 'calories': calories,
          if (protein != null) 'protein': protein,
          if (fats != null) 'fats': fats,
          if (carbs != null) 'carbs': carbs,
          if (callToActionEnabled) 'call_to_action_enabled': true,
          if (callToActionText != null) 'call_to_action_text': callToActionText,
          if (callToActionLink != null) 'call_to_action_link': callToActionLink,
          if (labels != null) 'labels': labels,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  /// Edit an owned post. Food metadata lives on the same `posts` row, so the
  /// editor can update regular and food posts without a legacy split path.
  Future<void> updatePost(
    String postId, {
    String? caption,
    String? location,
    String? foodTitle,
    String? foodDescription,
    String? recipe,
    String? nutritionFacts,
    String? cookingTime,
    String? mealType,
    int? calories,
    int? protein,
    String? fats,
    String? carbs,
  }) async {
    final uid = _requireUid();
    final updated = await _db
        .from('posts')
        .update({
          if (caption != null) 'caption': caption,
          if (location != null) 'location': location,
          if (foodTitle != null) 'food_title': foodTitle,
          if (foodDescription != null) 'food_description': foodDescription,
          if (recipe != null) 'recipe': recipe,
          if (nutritionFacts != null) 'nutrition_facts': nutritionFacts,
          if (cookingTime != null) 'cooking_time': cookingTime,
          if (mealType != null) 'meal_type': mealType,
          if (calories != null) 'calories': calories,
          if (protein != null) 'protein': protein,
          if (fats != null) 'fats': fats,
          if (carbs != null) 'carbs': carbs,
        })
        .eq('id', postId)
        .eq('user_id', uid)
        .select('id')
        .maybeSingle();
    if (updated == null) {
      throw StateError('Post was not found or is not owned by this user.');
    }
  }

  /// Posts authored by a given user (their profile grid), newest first.
  Future<List<Map<String, dynamic>>> byUser(String userId,
      {int limit = 30, DateTime? before}) async {
    if (!await ProfileRepository().canViewAccount(userId)) return const [];
    var q =
        _db.from('posts').select().eq('user_id', userId).eq('deleted', false);
    if (before != null)
      q = q.lt('created_at', before.toUtc().toIso8601String());
    final rows = await q.order('created_at', ascending: false).limit(limit);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// A single post row by id (for the post detail screen).
  Future<Map<String, dynamic>?> getById(String postId) async {
    final row = await _db.from('posts').select().eq('id', postId).maybeSingle();
    if (row == null) return null;
    final authorId = (row['user_id'] ?? '').toString();
    if (!await ProfileRepository().canViewAccount(authorId)) return null;
    return row;
  }

  /// Whether the current user has liked a post.
  Future<bool> isLiked(String postId) async {
    final uid = _uid;
    if (uid == null) return false;
    final row = await _db
        .from('post_likes')
        .select('post_id')
        .eq('post_id', postId)
        .eq('user_id', uid)
        .maybeSingle();
    return row != null;
  }

  String _requireUid() {
    final uid = _uid;
    if (uid == null)
      throw StateError('No authenticated user for a post write.');
    return uid;
  }
}
