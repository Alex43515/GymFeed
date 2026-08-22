/// One hydrated feed row as returned by the `feed_page()` RPC — post + author +
/// like/comment counts + whether the current user liked it, in a single round-trip
/// (no N+1). Used by the home feed and reels.
class FeedItem {
  FeedItem(this.data);
  final Map<String, dynamic> data;

  factory FeedItem.fromMap(Map<String, dynamic> map) => FeedItem(map);

  String get postId => (data['post_id'] ?? '').toString();
  DateTime? get createdAt => data['created_at'] == null
      ? null
      : DateTime.tryParse(data['created_at'].toString());
  String get caption => (data['caption'] as String?) ?? '';
  String get photoUrl => (data['photo_url'] as String?) ?? '';
  String get videoUrl => (data['video_url'] as String?) ?? '';
  String get videoThumbnail => (data['video_thumbnail'] as String?) ?? '';
  String get blurhash => (data['blurhash'] as String?) ?? '';
  bool get foodPost => (data['food_post'] as bool?) ?? false;
  int get likeCount => (data['like_count'] as num?)?.toInt() ?? 0;
  int get commentCount => (data['comment_count'] as num?)?.toInt() ?? 0;
  bool get likedByMe => (data['liked_by_me'] as bool?) ?? false;

  String get authorId => (data['author_id'] ?? '').toString();
  String get authorUsername => (data['author_username'] as String?) ?? '';
  String get authorDisplayName =>
      (data['author_display_name'] as String?) ?? '';
  String get authorPhotoUrl => (data['author_photo_url'] as String?) ?? '';

  bool get hasVideo => videoUrl.isNotEmpty;
}
