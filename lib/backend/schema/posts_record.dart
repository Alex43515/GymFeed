import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import 'users_record.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/supabase/supabase_records.dart';

class PostsRecord extends FirestoreRecord {
  PostsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "post_photo" field.
  String? _postPhoto;
  String get postPhoto => _postPhoto ?? '';
  bool hasPostPhoto() => _postPhoto != null;

  // "post_user" field.
  DocumentReference? _postUser;
  DocumentReference? get postUser => _postUser;
  bool hasPostUser() => _postUser != null;

  // "time_posted" field.
  DateTime? _timePosted;
  DateTime? get timePosted => _timePosted;
  bool hasTimePosted() => _timePosted != null;

  // "likes" field.
  List<DocumentReference>? _likes;
  List<DocumentReference> get likes => _likes ?? const [];
  bool hasLikes() => _likes != null;

  // "num_comments" field.
  int? _numComments;
  int get numComments => _numComments ?? 0;
  bool hasNumComments() => _numComments != null;

  // "post_caption" field.
  String? _postCaption;
  String get postCaption => _postCaption ?? '';
  bool hasPostCaption() => _postCaption != null;

  // "allow_comments" field.
  bool? _allowComments;
  bool get allowComments => _allowComments ?? false;
  bool hasAllowComments() => _allowComments != null;

  // "allow_likes" field.
  bool? _allowLikes;
  bool get allowLikes => _allowLikes ?? false;
  bool hasAllowLikes() => _allowLikes != null;

  // "location" field.
  String? _location;
  String get location => _location ?? '';
  bool hasLocation() => _location != null;

  // "call_to_action_enabled" field.
  bool? _callToActionEnabled;
  bool get callToActionEnabled => _callToActionEnabled ?? false;
  bool hasCallToActionEnabled() => _callToActionEnabled != null;

  // "call_to_action_text" field.
  String? _callToActionText;
  String get callToActionText => _callToActionText ?? '';
  bool hasCallToActionText() => _callToActionText != null;

  // "call_to_action_link" field.
  String? _callToActionLink;
  String get callToActionLink => _callToActionLink ?? '';
  bool hasCallToActionLink() => _callToActionLink != null;

  // "tagged_users" field.
  List<DocumentReference>? _taggedUsers;
  List<DocumentReference> get taggedUsers => _taggedUsers ?? const [];
  bool hasTaggedUsers() => _taggedUsers != null;

  // "labels" field.
  String? _labels;
  String get labels => _labels ?? '';
  bool hasLabels() => _labels != null;

  // "deleted" field.
  bool? _deleted;
  bool get deleted => _deleted ?? false;
  bool hasDeleted() => _deleted != null;

  // "post_video" field.
  String? _postVideo;
  String get postVideo => _postVideo ?? '';
  bool hasPostVideo() => _postVideo != null;

  // "postPhotoFood" field.
  String? _postPhotoFood;
  String get postPhotoFood => _postPhotoFood ?? '';
  bool hasPostPhotoFood() => _postPhotoFood != null;

  // "postTitleFood" field.
  String? _postTitleFood;
  String get postTitleFood => _postTitleFood ?? '';
  bool hasPostTitleFood() => _postTitleFood != null;

  // "postDescriptionFood" field.
  String? _postDescriptionFood;
  String get postDescriptionFood => _postDescriptionFood ?? '';
  bool hasPostDescriptionFood() => _postDescriptionFood != null;

  // "timePostedFood" field.
  DateTime? _timePostedFood;
  DateTime? get timePostedFood => _timePostedFood;
  bool hasTimePostedFood() => _timePostedFood != null;

  // "postOwnerFood" field.
  bool? _postOwnerFood;
  bool get postOwnerFood => _postOwnerFood ?? false;
  bool hasPostOwnerFood() => _postOwnerFood != null;

  // "postVideoFood" field.
  String? _postVideoFood;
  String get postVideoFood => _postVideoFood ?? '';
  bool hasPostVideoFood() => _postVideoFood != null;

  // "recepie" field.
  String? _recepie;
  String get recepie => _recepie ?? '';
  bool hasRecepie() => _recepie != null;

  // "nutritionFacts" field.
  String? _nutritionFacts;
  String get nutritionFacts => _nutritionFacts ?? '';
  bool hasNutritionFacts() => _nutritionFacts != null;

  // "cookingTime" field.
  String? _cookingTime;
  String get cookingTime => _cookingTime ?? '';
  bool hasCookingTime() => _cookingTime != null;

  // "mealType" field.
  String? _mealType;
  String get mealType => _mealType ?? '';
  bool hasMealType() => _mealType != null;

  // "calories" field.
  int? _calories;
  int get calories => _calories ?? 0;
  bool hasCalories() => _calories != null;

  // "protein" field.
  int? _protein;
  int get protein => _protein ?? 0;
  bool hasProtein() => _protein != null;

  // "numCommentsFood" field.
  int? _numCommentsFood;
  int get numCommentsFood => _numCommentsFood ?? 0;
  bool hasNumCommentsFood() => _numCommentsFood != null;

  // "foodPost" field.
  bool? _foodPost;
  bool get foodPost => _foodPost ?? false;
  bool hasFoodPost() => _foodPost != null;

  // "exactLocation" field.
  LatLng? _exactLocation;
  LatLng? get exactLocation => _exactLocation;
  bool hasExactLocation() => _exactLocation != null;

  // "fats" field.
  String? _fats;
  String get fats => _fats ?? '';
  bool hasFats() => _fats != null;

  // "carbs" field.
  String? _carbs;
  String get carbs => _carbs ?? '';
  bool hasCarbs() => _carbs != null;

  // "videoThumbnail" field.
  String? _videoThumbnail;
  String get videoThumbnail => _videoThumbnail ?? '';
  bool hasVideoThumbnail() => _videoThumbnail != null;

  // "videoPreview" field.
  String? _videoPreview;
  String get videoPreview => _videoPreview ?? '';
  bool hasVideoPreview() => _videoPreview != null;

  // Author fields supplied by feed_page(). Keeping these on the post lets the
  // Home list render at its final height immediately instead of collapsing to
  // a loading spinner every time an off-screen item is rebuilt.
  String? _feedAuthorUsername;
  String get feedAuthorUsername => _feedAuthorUsername ?? '';
  String? _feedAuthorDisplayName;
  String get feedAuthorDisplayName => _feedAuthorDisplayName ?? '';
  String? _feedAuthorPhotoUrl;
  String get feedAuthorPhotoUrl => _feedAuthorPhotoUrl ?? '';

  UsersRecord? get feedAuthor {
    final reference = postUser;
    if (reference == null ||
        (feedAuthorUsername.isEmpty &&
            feedAuthorDisplayName.isEmpty &&
            feedAuthorPhotoUrl.isEmpty)) {
      return null;
    }
    return UsersRecord.getDocumentFromData(
      <String, dynamic>{
        'uid': reference.id,
        'username': feedAuthorUsername,
        'display_name': feedAuthorDisplayName,
        'photo_url': feedAuthorPhotoUrl,
      },
      reference,
    );
  }

  void _initializeFields() {
    _postPhoto = snapshotData['post_photo'] as String?;
    _postUser = snapshotData['post_user'] as DocumentReference?;
    _timePosted = snapshotData['time_posted'] as DateTime?;
    _likes = getDataList(snapshotData['likes']);
    _numComments = castToType<int>(snapshotData['num_comments']);
    _postCaption = snapshotData['post_caption'] as String?;
    _allowComments = snapshotData['allow_comments'] as bool?;
    _allowLikes = snapshotData['allow_likes'] as bool?;
    _location = snapshotData['location'] as String?;
    _callToActionEnabled = snapshotData['call_to_action_enabled'] as bool?;
    _callToActionText = snapshotData['call_to_action_text'] as String?;
    _callToActionLink = snapshotData['call_to_action_link'] as String?;
    _taggedUsers = getDataList(snapshotData['tagged_users']);
    _labels = snapshotData['labels'] as String?;
    _deleted = snapshotData['deleted'] as bool?;
    _postVideo = snapshotData['post_video'] as String?;
    _postPhotoFood = snapshotData['postPhotoFood'] as String?;
    _postTitleFood = snapshotData['postTitleFood'] as String?;
    _postDescriptionFood = snapshotData['postDescriptionFood'] as String?;
    _timePostedFood = snapshotData['timePostedFood'] as DateTime?;
    _postOwnerFood = snapshotData['postOwnerFood'] as bool?;
    _postVideoFood = snapshotData['postVideoFood'] as String?;
    _recepie = snapshotData['recepie'] as String?;
    _nutritionFacts = snapshotData['nutritionFacts'] as String?;
    _cookingTime = snapshotData['cookingTime'] as String?;
    _mealType = snapshotData['mealType'] as String?;
    _calories = castToType<int>(snapshotData['calories']);
    _protein = castToType<int>(snapshotData['protein']);
    _numCommentsFood = castToType<int>(snapshotData['numCommentsFood']);
    _foodPost = snapshotData['foodPost'] as bool?;
    _exactLocation = snapshotData['exactLocation'] as LatLng?;
    _fats = snapshotData['fats'] as String?;
    _carbs = snapshotData['carbs'] as String?;
    _videoThumbnail = snapshotData['videoThumbnail'] as String?;
    _videoPreview = snapshotData['videoPreview'] as String?;
    _feedAuthorUsername = snapshotData['feed_author_username'] as String?;
    _feedAuthorDisplayName =
        snapshotData['feed_author_display_name'] as String?;
    _feedAuthorPhotoUrl = snapshotData['feed_author_photo_url'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('posts');

  // ── Supabase-backed reads ─────────────────────────────────────────────────

  static Stream<PostsRecord> getDocument(DocumentReference ref) =>
      Stream.fromFuture(getDocumentOnce(ref));

  static Future<PostsRecord> getDocumentOnce(DocumentReference ref) async {
    final row = await supaById('posts', ref.id) ?? const {};
    return PostsRecord.getDocumentFromData(_supaPostData(row), ref);
  }

  /// Build a PostsRecord straight from a Supabase `posts` row.
  static PostsRecord fromSupabase(Map<String, dynamic> row) {
    final id = (row['id'] ?? '').toString();
    return PostsRecord.getDocumentFromData(
        _supaPostData(row), supaRef('posts', id));
  }

  /// Build a PostsRecord from a `feed_page()` RPC row (carries like_count and
  /// liked_by_me, so the like display is accurate).
  static PostsRecord fromFeedRow(Map<String, dynamic> row) {
    final id = (row['post_id'] ?? '').toString();
    final data = _supaPostData({
      'id': id,
      'user_id': row['author_id'],
      'created_at': row['created_at'],
      'caption': row['caption'],
      'legacy_photo_url': row['photo_url'],
      'legacy_video_url': row['video_url'],
      'video_thumbnail': row['video_thumbnail'],
      'food_post': row['food_post'],
      'comment_count': row['comment_count'],
      'like_count': row['like_count'],
      // Older feed_page() deployments do not return these columns. Treat the
      // missing values as enabled until migration 0010 is applied.
      'allow_comments': row['allow_comments'] ?? true,
      'allow_likes': row['allow_likes'] ?? true,
    });
    final likeCount = castToType<int>(row['like_count']) ?? 0;
    data['likes'] = likePlaceholders(
      likeCount,
      likedByUid: (row['liked_by_me'] == true) ? supaCurrentUid() : null,
    );
    data['feed_author_username'] = row['author_username'];
    data['feed_author_display_name'] = row['author_display_name'];
    data['feed_author_photo_url'] = row['author_photo_url'];
    return PostsRecord.getDocumentFromData(data, supaRef('posts', id));
  }

  static PostsRecord fromSnapshot(DocumentSnapshot snapshot) => PostsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static PostsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      PostsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'PostsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is PostsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

/// Maps a Supabase `posts` row to the Firestore field names PostsRecord expects.
/// Media is read from `legacy_photo_url`/`legacy_video_url` (direct URLs).
Map<String, dynamic> _supaPostData(Map<String, dynamic> row) {
  final photo = row['legacy_photo_url'] ?? row['photo_url'];
  final video = row['legacy_video_url'] ?? row['video_url'];
  final likeCount = castToType<int>(row['like_count']) ?? 0;
  return <String, dynamic>{
    'post_photo': photo,
    'post_video': video,
    'post_user': supaUserRef(row['user_id']),
    'time_posted': supaDate(row['created_at']),
    'num_comments': row['comment_count'],
    'post_caption': row['caption'],
    'allow_comments': row['allow_comments'],
    'allow_likes': row['allow_likes'],
    'location': row['location'],
    'deleted': row['deleted'],
    'call_to_action_enabled': row['call_to_action_enabled'],
    'call_to_action_text': row['call_to_action_text'],
    'call_to_action_link': row['call_to_action_link'],
    'labels': row['labels'],
    'foodPost': row['food_post'],
    'videoThumbnail': row['video_thumbnail'],
    'videoPreview': row['video_preview'],
    'postPhotoFood': photo,
    'postVideoFood': video,
    'postTitleFood': row['food_title'],
    'postDescriptionFood': row['food_description'],
    'timePostedFood': supaDate(row['created_at']),
    'recepie': row['recipe'],
    'nutritionFacts': row['nutrition_facts'],
    'cookingTime': row['cooking_time'],
    'mealType': row['meal_type'],
    'calories': row['calories'],
    'protein': row['protein'],
    'fats': row['fats'],
    'carbs': row['carbs'],
    'numCommentsFood': row['comment_count'],
    'likes': likePlaceholders(likeCount),
  }..removeWhere((key, value) => value == null);
}

Map<String, dynamic> createPostsRecordData({
  String? postPhoto,
  DocumentReference? postUser,
  DateTime? timePosted,
  int? numComments,
  String? postCaption,
  bool? allowComments,
  bool? allowLikes,
  String? location,
  bool? callToActionEnabled,
  String? callToActionText,
  String? callToActionLink,
  String? labels,
  bool? deleted,
  String? postVideo,
  String? postPhotoFood,
  String? postTitleFood,
  String? postDescriptionFood,
  DateTime? timePostedFood,
  bool? postOwnerFood,
  String? postVideoFood,
  String? recepie,
  String? nutritionFacts,
  String? cookingTime,
  String? mealType,
  int? calories,
  int? protein,
  int? numCommentsFood,
  bool? foodPost,
  LatLng? exactLocation,
  String? fats,
  String? carbs,
  String? videoThumbnail,
  String? videoPreview,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'post_photo': postPhoto,
      'post_user': postUser,
      'time_posted': timePosted,
      'num_comments': numComments,
      'post_caption': postCaption,
      'allow_comments': allowComments,
      'allow_likes': allowLikes,
      'location': location,
      'call_to_action_enabled': callToActionEnabled,
      'call_to_action_text': callToActionText,
      'call_to_action_link': callToActionLink,
      'labels': labels,
      'deleted': deleted,
      'post_video': postVideo,
      'postPhotoFood': postPhotoFood,
      'postTitleFood': postTitleFood,
      'postDescriptionFood': postDescriptionFood,
      'timePostedFood': timePostedFood,
      'postOwnerFood': postOwnerFood,
      'postVideoFood': postVideoFood,
      'recepie': recepie,
      'nutritionFacts': nutritionFacts,
      'cookingTime': cookingTime,
      'mealType': mealType,
      'calories': calories,
      'protein': protein,
      'numCommentsFood': numCommentsFood,
      'foodPost': foodPost,
      'exactLocation': exactLocation,
      'fats': fats,
      'carbs': carbs,
      'videoThumbnail': videoThumbnail,
      'videoPreview': videoPreview,
    }.withoutNulls,
  );

  return firestoreData;
}

class PostsRecordDocumentEquality implements Equality<PostsRecord> {
  const PostsRecordDocumentEquality();

  @override
  bool equals(PostsRecord? e1, PostsRecord? e2) {
    const listEquality = ListEquality();
    return e1?.postPhoto == e2?.postPhoto &&
        e1?.postUser == e2?.postUser &&
        e1?.timePosted == e2?.timePosted &&
        listEquality.equals(e1?.likes, e2?.likes) &&
        e1?.numComments == e2?.numComments &&
        e1?.postCaption == e2?.postCaption &&
        e1?.allowComments == e2?.allowComments &&
        e1?.allowLikes == e2?.allowLikes &&
        e1?.location == e2?.location &&
        e1?.callToActionEnabled == e2?.callToActionEnabled &&
        e1?.callToActionText == e2?.callToActionText &&
        e1?.callToActionLink == e2?.callToActionLink &&
        listEquality.equals(e1?.taggedUsers, e2?.taggedUsers) &&
        e1?.labels == e2?.labels &&
        e1?.deleted == e2?.deleted &&
        e1?.postVideo == e2?.postVideo &&
        e1?.postPhotoFood == e2?.postPhotoFood &&
        e1?.postTitleFood == e2?.postTitleFood &&
        e1?.postDescriptionFood == e2?.postDescriptionFood &&
        e1?.timePostedFood == e2?.timePostedFood &&
        e1?.postOwnerFood == e2?.postOwnerFood &&
        e1?.postVideoFood == e2?.postVideoFood &&
        e1?.recepie == e2?.recepie &&
        e1?.nutritionFacts == e2?.nutritionFacts &&
        e1?.cookingTime == e2?.cookingTime &&
        e1?.mealType == e2?.mealType &&
        e1?.calories == e2?.calories &&
        e1?.protein == e2?.protein &&
        e1?.numCommentsFood == e2?.numCommentsFood &&
        e1?.foodPost == e2?.foodPost &&
        e1?.exactLocation == e2?.exactLocation &&
        e1?.fats == e2?.fats &&
        e1?.carbs == e2?.carbs &&
        e1?.videoThumbnail == e2?.videoThumbnail &&
        e1?.videoPreview == e2?.videoPreview;
  }

  @override
  int hash(PostsRecord? e) => const ListEquality().hash([
        e?.postPhoto,
        e?.postUser,
        e?.timePosted,
        e?.likes,
        e?.numComments,
        e?.postCaption,
        e?.allowComments,
        e?.allowLikes,
        e?.location,
        e?.callToActionEnabled,
        e?.callToActionText,
        e?.callToActionLink,
        e?.taggedUsers,
        e?.labels,
        e?.deleted,
        e?.postVideo,
        e?.postPhotoFood,
        e?.postTitleFood,
        e?.postDescriptionFood,
        e?.timePostedFood,
        e?.postOwnerFood,
        e?.postVideoFood,
        e?.recepie,
        e?.nutritionFacts,
        e?.cookingTime,
        e?.mealType,
        e?.calories,
        e?.protein,
        e?.numCommentsFood,
        e?.foodPost,
        e?.exactLocation,
        e?.fats,
        e?.carbs,
        e?.videoThumbnail,
        e?.videoPreview
      ]);

  @override
  bool isValidKey(Object? o) => o is PostsRecord;
}
