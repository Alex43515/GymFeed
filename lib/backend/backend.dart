import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../flutter_flow/flutter_flow_util.dart';
import 'schema/util/firestore_util.dart';
// Firebase's `User` is used elsewhere in this file; hide Supabase's to avoid a
// name clash. Only the `supabase` client getter is needed here.
import 'supabase/supabase.dart' hide User;

import 'schema/users_record.dart';
import 'schema/posts_record.dart';
import 'schema/comments_record.dart';
import 'schema/stories_record.dart';
import 'schema/bookmarks_record.dart';
import 'schema/chats_record.dart';
import 'schema/chat_messages_record.dart';
import 'schema/followers_record.dart';
import 'schema/administrative_record.dart';
import 'schema/recent_searches_record.dart';
import 'schema/notifications_record.dart';
import 'schema/chat_refs_record.dart';
import 'schema/user_trainings_record.dart';
import 'schema/workout_record.dart';
import 'schema/exercise_record.dart';
import 'schema/reports_record.dart';
import 'schema/foodcomments_record.dart';
import 'schema/verification_dash_record.dart';
import 'schema/meal_scanner_record.dart';
import 'profile_post_scope.dart';
import 'dart:async';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

export 'dart:async' show StreamSubscription;
export 'package:cloud_firestore/cloud_firestore.dart' hide Order;
export 'package:firebase_core/firebase_core.dart';
export 'schema/index.dart';
export 'schema/util/firestore_util.dart';
export 'schema/util/schema_util.dart';

export 'schema/users_record.dart';
export 'schema/posts_record.dart';
export 'schema/comments_record.dart';
export 'schema/stories_record.dart';
export 'schema/bookmarks_record.dart';
export 'schema/chats_record.dart';
export 'schema/chat_messages_record.dart';
export 'schema/followers_record.dart';
export 'schema/administrative_record.dart';
export 'schema/recent_searches_record.dart';
export 'schema/notifications_record.dart';
export 'schema/chat_refs_record.dart';
export 'schema/user_trainings_record.dart';
export 'schema/workout_record.dart';
export 'schema/exercise_record.dart';
export 'schema/reports_record.dart';
export 'schema/foodcomments_record.dart';
export 'schema/verification_dash_record.dart';
export 'schema/meal_scanner_record.dart';

/// Functions to query UsersRecords (as a Stream and as a Future).
Future<int> queryUsersRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      UsersRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<UsersRecord>> queryUsersRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  // Supabase: public profiles (used by user pickers / search that then filter
  // client-side). Firestore `queryBuilder` filters can't be introspected, so
  // callers needing a specific user should use UsersRecord.getDocumentOnce.
  final future = supabase
      .from('profiles')
      .select('*')
      .limit(limit > 0 ? limit : 200)
      .then((rows) => (rows as List)
          .map((r) => UsersRecord.fromSupabase(r as Map<String, dynamic>))
          .toList());
  return Stream.fromFuture(future);
}

Future<List<UsersRecord>> queryUsersRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) async {
  // Supabase: profiles for client-side search.
  final rows = await supabase
      .from('profiles')
      .select('*')
      .limit(limit > 0 ? limit : 500);
  return (rows as List)
      .map((r) => UsersRecord.fromSupabase(r as Map<String, dynamic>))
      .toList();
}

Future<FFFirestorePage<UsersRecord>> queryUsersRecordPage({
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
  required PagingController<DocumentSnapshot?, UsersRecord> controller,
  List<StreamSubscription?>? streamSubscriptions,
}) =>
    queryCollectionPage(
      UsersRecord.collection,
      UsersRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      nextPageMarker: nextPageMarker,
      pageSize: pageSize,
      isStream: isStream,
    ).then((page) {
      controller.appendPage(
        page.data,
        page.nextPageMarker,
      );
      if (isStream) {
        final streamSubscription =
            (page.dataStream)?.listen((List<UsersRecord> data) {
          data.forEach((item) {
            final itemIndexes = controller.itemList!
                .asMap()
                .map((k, v) => MapEntry(v.reference.id, k));
            final index = itemIndexes[item.reference.id];
            final items = controller.itemList!;
            if (index != null) {
              items.replaceRange(index, index + 1, [item]);
              controller.itemList = {
                for (var item in items) item.reference: item
              }.values.toList();
            }
          });
        });
        streamSubscriptions?.add(streamSubscription);
      }
      return page;
    });

/// Functions to query PostsRecords (as a Stream and as a Future).
Future<int> queryPostsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      PostsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<PostsRecord>> queryPostsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  // Supabase: recent non-deleted posts (used by search grids that filter
  // client-side). Per-user grids use queryPostsByUserStream.
  final future = supabase
      .from('posts')
      .select()
      .eq('deleted', false)
      .order('created_at', ascending: false)
      .limit(limit > 0 ? limit : 200)
      .then((rows) => (rows as List)
          .map((r) => PostsRecord.fromSupabase(r as Map<String, dynamic>))
          .toList());
  return Stream.fromFuture(future);
}

/// Supabase: a user's own posts (newest first). Used by the profile grids —
/// the Firestore `queryBuilder` closures can't be introspected, so profile
/// screens call this explicit query instead.
Stream<List<PostsRecord>> queryPostsByUserStream(
  String userId, {
  bool? foodPost,
}) {
  final normalizedUserId = userId.trim();
  if (normalizedUserId.isEmpty) return Stream.value(const []);
  var filter = supabase
      .from('posts')
      .select()
      .eq('user_id', normalizedUserId)
      .eq('deleted', false);
  if (foodPost != null) filter = filter.eq('food_post', foodPost);
  final future = filter.order('created_at', ascending: false).then((rows) {
    final normalizedRows = (rows as List)
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row));
    return retainProfilePostRows(normalizedRows, normalizedUserId)
        .map(PostsRecord.fromSupabase)
        .toList(growable: false);
  });
  return Stream.fromFuture(future);
}

/// Supabase: posts in which a user has been tagged, newest first.
///
/// Tags are stored in the `post_tags` join table, so they cannot be represented
/// by the old Firestore `arrayContains` query used by generated pages.
Stream<List<PostsRecord>> queryTaggedPostsByUserStream(String userId) {
  final normalizedUserId = userId.trim();
  if (normalizedUserId.isEmpty) return Stream.value(const []);

  final future = () async {
    final tagRows = await supabase
        .from('post_tags')
        .select('post_id')
        .eq('user_id', normalizedUserId);
    final postIds = (tagRows as List)
        .whereType<Map>()
        .map((row) => (row['post_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (postIds.isEmpty) return const <PostsRecord>[];

    final rows = await supabase
        .from('posts')
        .select()
        .inFilter('id', postIds)
        .eq('deleted', false)
        .order('created_at', ascending: false);
    return (rows as List)
        .whereType<Map>()
        .map((row) => PostsRecord.fromSupabase(
              Map<String, dynamic>.from(row),
            ))
        .toList(growable: false);
  }();

  return Stream.fromFuture(future);
}

/// Supabase: a user's active (non-expired) stories, newest first.
Stream<List<StoriesRecord>> queryStoriesByUserStream(String userId) {
  if (userId.isEmpty) return Stream.value(const []);
  final nowIso = DateTime.now().toUtc().toIso8601String();
  final future = supabase
      .from('stories')
      .select()
      .eq('user_id', userId)
      .gt('expires_at', nowIso)
      .order('created_at', ascending: false)
      .then((rows) => (rows as List)
          .map((r) => StoriesRecord.fromSupabase(r as Map<String, dynamic>))
          .toList());
  return Stream.fromFuture(future);
}

/// Supabase: active stories from people the current user follows (+ self),
/// newest first — the feed story tray.
Stream<List<StoriesRecord>> queryFollowingStoriesStream() {
  final me = supabase.auth.currentUser?.id;
  if (me == null) return Stream.value(const []);
  final nowIso = DateTime.now().toUtc().toIso8601String();
  final future = () async {
    final follows = await supabase
        .from('follows')
        .select('followee_id')
        .eq('follower_id', me);
    final ids = (follows as List)
        .map((r) => (r['followee_id'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toList()
      ..add(me);
    final rows = await supabase
        .from('stories')
        .select()
        .inFilter('user_id', ids)
        .gt('expires_at', nowIso)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => StoriesRecord.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }();
  return Stream.fromFuture(future);
}

Future<List<PostsRecord>> queryPostsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) async {
  // Supabase: recent non-deleted posts for client-side search.
  final rows = await supabase
      .from('posts')
      .select()
      .eq('deleted', false)
      .order('created_at', ascending: false)
      .limit(limit > 0 ? limit : 500);
  return (rows as List)
      .map((r) => PostsRecord.fromSupabase(r as Map<String, dynamic>))
      .toList();
}

Future<FFFirestorePage<PostsRecord>> queryPostsRecordPage({
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
  required PagingController<DocumentSnapshot?, PostsRecord> controller,
  List<StreamSubscription?>? streamSubscriptions,
}) =>
    queryCollectionPage(
      PostsRecord.collection,
      PostsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      nextPageMarker: nextPageMarker,
      pageSize: pageSize,
      isStream: isStream,
    ).then((page) {
      controller.appendPage(
        page.data,
        page.nextPageMarker,
      );
      if (isStream) {
        final streamSubscription =
            (page.dataStream)?.listen((List<PostsRecord> data) {
          data.forEach((item) {
            final itemIndexes = controller.itemList!
                .asMap()
                .map((k, v) => MapEntry(v.reference.id, k));
            final index = itemIndexes[item.reference.id];
            final items = controller.itemList!;
            if (index != null) {
              items.replaceRange(index, index + 1, [item]);
              controller.itemList = {
                for (var item in items) item.reference: item
              }.values.toList();
            }
          });
        });
        streamSubscriptions?.add(streamSubscription);
      }
      return page;
    });

/// Functions to query CommentsRecords (as a Stream and as a Future).
Future<int> queryCommentsRecordCount({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      CommentsRecord.collection(parent),
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<CommentsRecord>> queryCommentsRecord({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
  bool descending = false,
}) {
  // Supabase: comments for a post, oldest first. `parent` carries the post id.
  final postId = parent?.id ?? '';
  if (postId.isEmpty) return Stream.value(const []);
  var request = supabase
      .from('comments')
      .select()
      .eq('post_id', postId)
      .order('created_at', ascending: !descending);
  if (limit > 0) request = request.limit(limit);
  final future = request.then((rows) => (rows as List)
      .map((r) => CommentsRecord.fromSupabase(r as Map<String, dynamic>))
      .toList());
  return Stream.fromFuture(future);
}

Future<List<CommentsRecord>> queryCommentsRecordOnce({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      CommentsRecord.collection(parent),
      CommentsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );
Future<FFFirestorePage<CommentsRecord>> queryCommentsRecordPage({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
  required PagingController<DocumentSnapshot?, CommentsRecord> controller,
  List<StreamSubscription?>? streamSubscriptions,
}) =>
    queryCollectionPage(
      CommentsRecord.collection(parent),
      CommentsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      nextPageMarker: nextPageMarker,
      pageSize: pageSize,
      isStream: isStream,
    ).then((page) {
      controller.appendPage(
        page.data,
        page.nextPageMarker,
      );
      if (isStream) {
        final streamSubscription =
            (page.dataStream)?.listen((List<CommentsRecord> data) {
          data.forEach((item) {
            final itemIndexes = controller.itemList!
                .asMap()
                .map((k, v) => MapEntry(v.reference.id, k));
            final index = itemIndexes[item.reference.id];
            final items = controller.itemList!;
            if (index != null) {
              items.replaceRange(index, index + 1, [item]);
              controller.itemList = {
                for (var item in items) item.reference: item
              }.values.toList();
            }
          });
        });
        streamSubscriptions?.add(streamSubscription);
      }
      return page;
    });

/// Functions to query StoriesRecords (as a Stream and as a Future).
Future<int> queryStoriesRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      StoriesRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<StoriesRecord>> queryStoriesRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      StoriesRecord.collection,
      StoriesRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<StoriesRecord>> queryStoriesRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      StoriesRecord.collection,
      StoriesRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );
Future<FFFirestorePage<StoriesRecord>> queryStoriesRecordPage({
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
  required PagingController<DocumentSnapshot?, StoriesRecord> controller,
  List<StreamSubscription?>? streamSubscriptions,
}) =>
    queryCollectionPage(
      StoriesRecord.collection,
      StoriesRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      nextPageMarker: nextPageMarker,
      pageSize: pageSize,
      isStream: isStream,
    ).then((page) {
      controller.appendPage(
        page.data,
        page.nextPageMarker,
      );
      if (isStream) {
        final streamSubscription =
            (page.dataStream)?.listen((List<StoriesRecord> data) {
          data.forEach((item) {
            final itemIndexes = controller.itemList!
                .asMap()
                .map((k, v) => MapEntry(v.reference.id, k));
            final index = itemIndexes[item.reference.id];
            final items = controller.itemList!;
            if (index != null) {
              items.replaceRange(index, index + 1, [item]);
              controller.itemList = {
                for (var item in items) item.reference: item
              }.values.toList();
            }
          });
        });
        streamSubscriptions?.add(streamSubscription);
      }
      return page;
    });

/// Functions to query BookmarksRecords (as a Stream and as a Future).
Future<int> queryBookmarksRecordCount({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      BookmarksRecord.collection(parent),
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<BookmarksRecord>> queryBookmarksRecord({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  // Supabase: one BookmarksRecord per user, grouping their saved items.
  final userId = parent?.id ?? supabase.auth.currentUser?.id ?? '';
  if (userId.isEmpty) return Stream.value(const []);
  return Stream.fromFuture(BookmarksRecord.forUser(userId).then((r) => [r]));
}

Future<List<BookmarksRecord>> queryBookmarksRecordOnce({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      BookmarksRecord.collection(parent),
      BookmarksRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );
Future<FFFirestorePage<BookmarksRecord>> queryBookmarksRecordPage({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
  required PagingController<DocumentSnapshot?, BookmarksRecord> controller,
  List<StreamSubscription?>? streamSubscriptions,
}) =>
    queryCollectionPage(
      BookmarksRecord.collection(parent),
      BookmarksRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      nextPageMarker: nextPageMarker,
      pageSize: pageSize,
      isStream: isStream,
    ).then((page) {
      controller.appendPage(
        page.data,
        page.nextPageMarker,
      );
      if (isStream) {
        final streamSubscription =
            (page.dataStream)?.listen((List<BookmarksRecord> data) {
          data.forEach((item) {
            final itemIndexes = controller.itemList!
                .asMap()
                .map((k, v) => MapEntry(v.reference.id, k));
            final index = itemIndexes[item.reference.id];
            final items = controller.itemList!;
            if (index != null) {
              items.replaceRange(index, index + 1, [item]);
              controller.itemList = {
                for (var item in items) item.reference: item
              }.values.toList();
            }
          });
        });
        streamSubscriptions?.add(streamSubscription);
      }
      return page;
    });

/// Functions to query ChatsRecords (as a Stream and as a Future).
Future<int> queryChatsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      ChatsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<ChatsRecord>> queryChatsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  // Supabase: the current user's chats (via chat_members), most-recent first.
  final me = supabase.auth.currentUser?.id;
  if (me == null) return Stream.value(const []);
  final future = () async {
    final myMemberships =
        await supabase.from('chat_members').select('chat_id').eq('user_id', me);
    final chatIds = (myMemberships as List)
        .map((r) => (r['chat_id'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toList();
    if (chatIds.isEmpty) return <ChatsRecord>[];
    final chats = await supabase
        .from('chats')
        .select()
        .inFilter('id', chatIds)
        .order('last_message_at', ascending: false, nullsFirst: false);
    final allMembers = await supabase
        .from('chat_members')
        .select('chat_id, user_id')
        .inFilter('chat_id', chatIds);
    final membersByChat = <String, List<String>>{};
    for (final m in (allMembers as List)) {
      final cid = (m['chat_id'] ?? '').toString();
      (membersByChat[cid] ??= []).add((m['user_id'] ?? '').toString());
    }
    return (chats as List).map((c) {
      final cm = c as Map<String, dynamic>;
      return ChatsRecord.fromSupabase(
          cm, membersByChat[(cm['id']).toString()] ?? const [], me);
    }).toList();
  }();
  return Stream.fromFuture(future);
}

/// Supabase: the one direct chat shared with [otherUserId], if it exists.
Stream<List<ChatsRecord>> queryDirectChatWithUserStream(String otherUserId) {
  final me = supabase.auth.currentUser?.id;
  final normalizedOtherId = otherUserId.trim();
  if (me == null || normalizedOtherId.isEmpty || normalizedOtherId == me) {
    return Stream.value(const []);
  }

  final future = () async {
    final mine =
        await supabase.from('chat_members').select('chat_id').eq('user_id', me);
    final myChatIds = (mine as List)
        .whereType<Map>()
        .map((row) => (row['chat_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (myChatIds.isEmpty) return const <ChatsRecord>[];

    final shared = await supabase
        .from('chat_members')
        .select('chat_id')
        .eq('user_id', normalizedOtherId)
        .inFilter('chat_id', myChatIds);
    for (final row in (shared as List).whereType<Map>()) {
      final chatId = (row['chat_id'] ?? '').toString();
      if (chatId.isEmpty) continue;
      final members = await supabase
          .from('chat_members')
          .select('user_id')
          .eq('chat_id', chatId);
      final memberIds = (members as List)
          .whereType<Map>()
          .map((member) => (member['user_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList(growable: false);
      if (memberIds.length != 2 ||
          !memberIds.contains(me) ||
          !memberIds.contains(normalizedOtherId)) {
        continue;
      }
      final chat =
          await supabase.from('chats').select().eq('id', chatId).maybeSingle();
      if (chat == null) continue;
      return <ChatsRecord>[
        ChatsRecord.fromSupabase(chat, memberIds, me),
      ];
    }
    return const <ChatsRecord>[];
  }();

  return Stream.fromFuture(future);
}

/// Supabase Realtime: live messages in a chat, newest first (matches the
/// screen's reversed list layout).
Stream<List<ChatMessagesRecord>> queryMessagesByChatStream(String chatId) {
  if (chatId.isEmpty) return Stream.value(const []);
  return supabase
      .from('chat_messages')
      .stream(primaryKey: ['id'])
      .eq('chat_id', chatId)
      .order('created_at', ascending: false)
      .map((rows) =>
          rows.map((r) => ChatMessagesRecord.fromSupabase(r)).toList());
}

/// Supabase: trainings that have a video — the reels feed, newest first.
Stream<List<UserTrainingsRecord>> queryTrainingsFeedStream() {
  final future = supabase
      .from('user_trainings')
      .select()
      .neq('legacy_video_url', '')
      .order('created_at', ascending: false)
      .then((rows) => (rows as List)
          .map((r) =>
              UserTrainingsRecord.fromSupabase(r as Map<String, dynamic>))
          .toList());
  return Stream.fromFuture(future);
}

/// Supabase: a user's trainings, newest first (profile trainings grid).
Stream<List<UserTrainingsRecord>> queryTrainingsByUserStream(String userId) {
  final normalizedUserId = userId.trim();
  if (normalizedUserId.isEmpty) return Stream.value(const []);
  final future = supabase
      .from('user_trainings')
      .select()
      .eq('user_id', normalizedUserId)
      .order('created_at', ascending: false)
      .then((rows) {
    final normalizedRows = (rows as List)
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row));
    return retainRowsOwnedBy(normalizedRows, normalizedUserId)
        .map(UserTrainingsRecord.fromSupabase)
        .toList(growable: false);
  });
  return Stream.fromFuture(future);
}

/// Supabase: trainings joined by [userId], newest first.
Stream<List<UserTrainingsRecord>> queryJoinedTrainingsStream(String userId) {
  final normalizedUserId = userId.trim();
  if (normalizedUserId.isEmpty) return Stream.value(const []);

  final future = () async {
    final participantRows = await supabase
        .from('training_participants')
        .select('training_id')
        .eq('user_id', normalizedUserId);
    final trainingIds = (participantRows as List)
        .whereType<Map>()
        .map((row) => (row['training_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (trainingIds.isEmpty) return const <UserTrainingsRecord>[];

    final rows = await supabase
        .from('user_trainings')
        .select()
        .inFilter('id', trainingIds)
        .order('created_at', ascending: false);
    return (rows as List)
        .whereType<Map>()
        .map((row) => UserTrainingsRecord.fromSupabase(
              Map<String, dynamic>.from(row),
            ))
        .toList(growable: false);
  }();

  return Stream.fromFuture(future);
}

/// Supabase: create a training (schedule/edit screens). Media is stored as a
/// direct URL in legacy_video_url / background_image.
Future<String> createTrainingSupabase({
  String? title,
  String? description,
  String? category,
  String? difficultyLevel,
  String? trainingDateRaw,
  String? trainingTimeRaw,
  int? duration,
  String? backgroundImage,
  String? videoUrl,
  String? videoAssetId,
  LatLng? location,
  DateTime? startsAt,
}) async {
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) {
    throw StateError('Sign in before scheduling a workout.');
  }
  final row = await supabase.from('user_trainings').insert(<String, dynamic>{
    'user_id': uid,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (category != null) 'category': category,
    if (difficultyLevel != null) 'difficulty_level': difficultyLevel,
    if (trainingDateRaw != null) 'training_date_raw': trainingDateRaw,
    if (trainingTimeRaw != null) 'training_time_raw': trainingTimeRaw,
    if (startsAt != null) 'starts_at': startsAt.toUtc().toIso8601String(),
    if (duration != null) 'duration': duration,
    if (backgroundImage != null && backgroundImage.isNotEmpty)
      'background_image': backgroundImage,
    if (videoUrl != null && videoUrl.isNotEmpty) 'legacy_video_url': videoUrl,
    if (videoAssetId != null && videoAssetId.isNotEmpty)
      'video_asset_id': videoAssetId,
    if (location != null) 'location_lat': location.latitude,
    if (location != null) 'location_lng': location.longitude,
  }).select('id').single();
  return row['id'].toString();
}

/// Supabase: update a training (edit screen; owner-scoped).
Future<void> updateTrainingSupabase(
  String trainingId, {
  String? title,
  String? description,
  String? category,
  String? difficultyLevel,
  String? trainingDateRaw,
  String? trainingTimeRaw,
  int? duration,
  String? backgroundImage,
  String? videoUrl,
}) async {
  final uid = supabase.auth.currentUser?.id;
  if (uid == null || trainingId.isEmpty) return;
  await supabase
      .from('user_trainings')
      .update(<String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (difficultyLevel != null) 'difficulty_level': difficultyLevel,
        if (trainingDateRaw != null) 'training_date_raw': trainingDateRaw,
        if (trainingTimeRaw != null) 'training_time_raw': trainingTimeRaw,
        if (duration != null) 'duration': duration,
        if (backgroundImage != null && backgroundImage.isNotEmpty)
          'background_image': backgroundImage,
        if (videoUrl != null && videoUrl.isNotEmpty)
          'legacy_video_url': videoUrl,
      })
      .eq('id', trainingId)
      .eq('user_id', uid);
}

Future<List<ChatsRecord>> queryChatsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      ChatsRecord.collection,
      ChatsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );
Future<FFFirestorePage<ChatsRecord>> queryChatsRecordPage({
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
  required PagingController<DocumentSnapshot?, ChatsRecord> controller,
  List<StreamSubscription?>? streamSubscriptions,
}) =>
    queryCollectionPage(
      ChatsRecord.collection,
      ChatsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      nextPageMarker: nextPageMarker,
      pageSize: pageSize,
      isStream: isStream,
    ).then((page) {
      controller.appendPage(
        page.data,
        page.nextPageMarker,
      );
      if (isStream) {
        final streamSubscription =
            (page.dataStream)?.listen((List<ChatsRecord> data) {
          data.forEach((item) {
            final itemIndexes = controller.itemList!
                .asMap()
                .map((k, v) => MapEntry(v.reference.id, k));
            final index = itemIndexes[item.reference.id];
            final items = controller.itemList!;
            if (index != null) {
              items.replaceRange(index, index + 1, [item]);
              controller.itemList = {
                for (var item in items) item.reference: item
              }.values.toList();
            }
          });
        });
        streamSubscriptions?.add(streamSubscription);
      }
      return page;
    });

/// Functions to query ChatMessagesRecords (as a Stream and as a Future).
Future<int> queryChatMessagesRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      ChatMessagesRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<ChatMessagesRecord>> queryChatMessagesRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      ChatMessagesRecord.collection,
      ChatMessagesRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<ChatMessagesRecord>> queryChatMessagesRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      ChatMessagesRecord.collection,
      ChatMessagesRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );
Future<FFFirestorePage<ChatMessagesRecord>> queryChatMessagesRecordPage({
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
  required PagingController<DocumentSnapshot?, ChatMessagesRecord> controller,
  List<StreamSubscription?>? streamSubscriptions,
}) =>
    queryCollectionPage(
      ChatMessagesRecord.collection,
      ChatMessagesRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      nextPageMarker: nextPageMarker,
      pageSize: pageSize,
      isStream: isStream,
    ).then((page) {
      controller.appendPage(
        page.data,
        page.nextPageMarker,
      );
      if (isStream) {
        final streamSubscription =
            (page.dataStream)?.listen((List<ChatMessagesRecord> data) {
          data.forEach((item) {
            final itemIndexes = controller.itemList!
                .asMap()
                .map((k, v) => MapEntry(v.reference.id, k));
            final index = itemIndexes[item.reference.id];
            final items = controller.itemList!;
            if (index != null) {
              items.replaceRange(index, index + 1, [item]);
              controller.itemList = {
                for (var item in items) item.reference: item
              }.values.toList();
            }
          });
        });
        streamSubscriptions?.add(streamSubscription);
      }
      return page;
    });

/// Functions to query FollowersRecords (as a Stream and as a Future).
Future<int> queryFollowersRecordCount({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      FollowersRecord.collection(parent),
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<FollowersRecord>> queryFollowersRecord({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  // Supabase: one FollowersRecord per user carrying all their followers
  // (userRefs), sourced from the `follows` table.
  final userId = parent?.id ?? '';
  if (userId.isEmpty) return Stream.value(const []);
  return Stream.fromFuture(FollowersRecord.forUser(userId).then((r) => [r]));
}

Future<List<FollowersRecord>> queryFollowersRecordOnce({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      FollowersRecord.collection(parent),
      FollowersRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );
Future<FFFirestorePage<FollowersRecord>> queryFollowersRecordPage({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
  required PagingController<DocumentSnapshot?, FollowersRecord> controller,
  List<StreamSubscription?>? streamSubscriptions,
}) =>
    queryCollectionPage(
      FollowersRecord.collection(parent),
      FollowersRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      nextPageMarker: nextPageMarker,
      pageSize: pageSize,
      isStream: isStream,
    ).then((page) {
      controller.appendPage(
        page.data,
        page.nextPageMarker,
      );
      if (isStream) {
        final streamSubscription =
            (page.dataStream)?.listen((List<FollowersRecord> data) {
          data.forEach((item) {
            final itemIndexes = controller.itemList!
                .asMap()
                .map((k, v) => MapEntry(v.reference.id, k));
            final index = itemIndexes[item.reference.id];
            final items = controller.itemList!;
            if (index != null) {
              items.replaceRange(index, index + 1, [item]);
              controller.itemList = {
                for (var item in items) item.reference: item
              }.values.toList();
            }
          });
        });
        streamSubscriptions?.add(streamSubscription);
      }
      return page;
    });

/// Functions to query AdministrativeRecords (as a Stream and as a Future).
Future<int> queryAdministrativeRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      AdministrativeRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<AdministrativeRecord>> queryAdministrativeRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      AdministrativeRecord.collection,
      AdministrativeRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<AdministrativeRecord>> queryAdministrativeRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      AdministrativeRecord.collection,
      AdministrativeRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );
Future<FFFirestorePage<AdministrativeRecord>> queryAdministrativeRecordPage({
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
  required PagingController<DocumentSnapshot?, AdministrativeRecord> controller,
  List<StreamSubscription?>? streamSubscriptions,
}) =>
    queryCollectionPage(
      AdministrativeRecord.collection,
      AdministrativeRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      nextPageMarker: nextPageMarker,
      pageSize: pageSize,
      isStream: isStream,
    ).then((page) {
      controller.appendPage(
        page.data,
        page.nextPageMarker,
      );
      if (isStream) {
        final streamSubscription =
            (page.dataStream)?.listen((List<AdministrativeRecord> data) {
          data.forEach((item) {
            final itemIndexes = controller.itemList!
                .asMap()
                .map((k, v) => MapEntry(v.reference.id, k));
            final index = itemIndexes[item.reference.id];
            final items = controller.itemList!;
            if (index != null) {
              items.replaceRange(index, index + 1, [item]);
              controller.itemList = {
                for (var item in items) item.reference: item
              }.values.toList();
            }
          });
        });
        streamSubscriptions?.add(streamSubscription);
      }
      return page;
    });

/// Functions to query RecentSearchesRecords (as a Stream and as a Future).
Future<int> queryRecentSearchesRecordCount({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      RecentSearchesRecord.collection(parent),
      queryBuilder: queryBuilder,
      limit: limit,
    );

/// Supabase: record that the current user searched for [searchedUserId].
Future<void> addRecentSearchSupabase(String searchedUserId) async {
  final me = supabase.auth.currentUser?.id;
  if (me == null || searchedUserId.isEmpty) return;
  try {
    await supabase.from('recent_searches').upsert({
      'owner_id': me,
      'searched_user_id': searchedUserId,
      'searched_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'owner_id,searched_user_id');
  } catch (_) {}
}

/// Supabase: remove a recent search entry.
Future<void> removeRecentSearchSupabase(String searchedUserId) async {
  final me = supabase.auth.currentUser?.id;
  if (me == null) return;
  await supabase
      .from('recent_searches')
      .delete()
      .eq('owner_id', me)
      .eq('searched_user_id', searchedUserId);
}

Stream<List<RecentSearchesRecord>> queryRecentSearchesRecord({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  // Supabase: a user's recent searches, newest first.
  final ownerId = parent?.id ?? supabase.auth.currentUser?.id ?? '';
  if (ownerId.isEmpty) return Stream.value(const []);
  final future = supabase
      .from('recent_searches')
      .select()
      .eq('owner_id', ownerId)
      .order('searched_at', ascending: false)
      .then((rows) => (rows as List)
          .map((r) =>
              RecentSearchesRecord.fromSupabase(r as Map<String, dynamic>))
          .toList());
  return Stream.fromFuture(future);
}

Future<List<RecentSearchesRecord>> queryRecentSearchesRecordOnce({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      RecentSearchesRecord.collection(parent),
      RecentSearchesRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );
Future<FFFirestorePage<RecentSearchesRecord>> queryRecentSearchesRecordPage({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
  required PagingController<DocumentSnapshot?, RecentSearchesRecord> controller,
  List<StreamSubscription?>? streamSubscriptions,
}) =>
    queryCollectionPage(
      RecentSearchesRecord.collection(parent),
      RecentSearchesRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      nextPageMarker: nextPageMarker,
      pageSize: pageSize,
      isStream: isStream,
    ).then((page) {
      controller.appendPage(
        page.data,
        page.nextPageMarker,
      );
      if (isStream) {
        final streamSubscription =
            (page.dataStream)?.listen((List<RecentSearchesRecord> data) {
          data.forEach((item) {
            final itemIndexes = controller.itemList!
                .asMap()
                .map((k, v) => MapEntry(v.reference.id, k));
            final index = itemIndexes[item.reference.id];
            final items = controller.itemList!;
            if (index != null) {
              items.replaceRange(index, index + 1, [item]);
              controller.itemList = {
                for (var item in items) item.reference: item
              }.values.toList();
            }
          });
        });
        streamSubscriptions?.add(streamSubscription);
      }
      return page;
    });

/// Functions to query NotificationsRecords (as a Stream and as a Future).
Future<int> queryNotificationsRecordCount({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      NotificationsRecord.collection(parent),
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<NotificationsRecord>> queryNotificationsRecord({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  // Supabase: notifications for a recipient (parent = the user), newest first.
  final recipientId = parent?.id ?? supabase.auth.currentUser?.id ?? '';
  if (recipientId.isEmpty) return Stream.value(const []);
  var q = supabase
      .from('notifications')
      .select()
      .eq('recipient_id', recipientId)
      .order('created_at', ascending: false);
  final capped = limit > 0 ? q.limit(limit) : q;
  final future = capped.then((rows) => (rows as List)
      .map((r) => NotificationsRecord.fromSupabase(r as Map<String, dynamic>))
      .toList());
  return Stream.fromFuture(future);
}

Future<List<NotificationsRecord>> queryNotificationsRecordOnce({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      NotificationsRecord.collection(parent),
      NotificationsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );
Future<FFFirestorePage<NotificationsRecord>> queryNotificationsRecordPage({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
  required PagingController<DocumentSnapshot?, NotificationsRecord> controller,
  List<StreamSubscription?>? streamSubscriptions,
}) =>
    queryCollectionPage(
      NotificationsRecord.collection(parent),
      NotificationsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      nextPageMarker: nextPageMarker,
      pageSize: pageSize,
      isStream: isStream,
    ).then((page) {
      controller.appendPage(
        page.data,
        page.nextPageMarker,
      );
      if (isStream) {
        final streamSubscription =
            (page.dataStream)?.listen((List<NotificationsRecord> data) {
          data.forEach((item) {
            final itemIndexes = controller.itemList!
                .asMap()
                .map((k, v) => MapEntry(v.reference.id, k));
            final index = itemIndexes[item.reference.id];
            final items = controller.itemList!;
            if (index != null) {
              items.replaceRange(index, index + 1, [item]);
              controller.itemList = {
                for (var item in items) item.reference: item
              }.values.toList();
            }
          });
        });
        streamSubscriptions?.add(streamSubscription);
      }
      return page;
    });

/// Functions to query ChatRefsRecords (as a Stream and as a Future).
Future<int> queryChatRefsRecordCount({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      ChatRefsRecord.collection(parent),
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<ChatRefsRecord>> queryChatRefsRecord({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      ChatRefsRecord.collection(parent),
      ChatRefsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<ChatRefsRecord>> queryChatRefsRecordOnce({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      ChatRefsRecord.collection(parent),
      ChatRefsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );
Future<FFFirestorePage<ChatRefsRecord>> queryChatRefsRecordPage({
  DocumentReference? parent,
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
  required PagingController<DocumentSnapshot?, ChatRefsRecord> controller,
  List<StreamSubscription?>? streamSubscriptions,
}) =>
    queryCollectionPage(
      ChatRefsRecord.collection(parent),
      ChatRefsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      nextPageMarker: nextPageMarker,
      pageSize: pageSize,
      isStream: isStream,
    ).then((page) {
      controller.appendPage(
        page.data,
        page.nextPageMarker,
      );
      if (isStream) {
        final streamSubscription =
            (page.dataStream)?.listen((List<ChatRefsRecord> data) {
          data.forEach((item) {
            final itemIndexes = controller.itemList!
                .asMap()
                .map((k, v) => MapEntry(v.reference.id, k));
            final index = itemIndexes[item.reference.id];
            final items = controller.itemList!;
            if (index != null) {
              items.replaceRange(index, index + 1, [item]);
              controller.itemList = {
                for (var item in items) item.reference: item
              }.values.toList();
            }
          });
        });
        streamSubscriptions?.add(streamSubscription);
      }
      return page;
    });

/// Functions to query UserTrainingsRecords (as a Stream and as a Future).
Future<int> queryUserTrainingsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      UserTrainingsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<UserTrainingsRecord>> queryUserTrainingsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  // Supabase: all trainings, newest first (training list screens). Screens
  // needing a user's own trainings use queryTrainingsByUserStream.
  final future = supabase
      .from('user_trainings')
      .select()
      .order('created_at', ascending: false)
      .limit(limit > 0 ? limit : 200)
      .then((rows) => (rows as List)
          .map((r) =>
              UserTrainingsRecord.fromSupabase(r as Map<String, dynamic>))
          .toList());
  return Stream.fromFuture(future);
}

Future<List<UserTrainingsRecord>> queryUserTrainingsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      UserTrainingsRecord.collection,
      UserTrainingsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );
Future<FFFirestorePage<UserTrainingsRecord>> queryUserTrainingsRecordPage({
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
  required PagingController<DocumentSnapshot?, UserTrainingsRecord> controller,
  List<StreamSubscription?>? streamSubscriptions,
}) =>
    queryCollectionPage(
      UserTrainingsRecord.collection,
      UserTrainingsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      nextPageMarker: nextPageMarker,
      pageSize: pageSize,
      isStream: isStream,
    ).then((page) {
      controller.appendPage(
        page.data,
        page.nextPageMarker,
      );
      if (isStream) {
        final streamSubscription =
            (page.dataStream)?.listen((List<UserTrainingsRecord> data) {
          data.forEach((item) {
            final itemIndexes = controller.itemList!
                .asMap()
                .map((k, v) => MapEntry(v.reference.id, k));
            final index = itemIndexes[item.reference.id];
            final items = controller.itemList!;
            if (index != null) {
              items.replaceRange(index, index + 1, [item]);
              controller.itemList = {
                for (var item in items) item.reference: item
              }.values.toList();
            }
          });
        });
        streamSubscriptions?.add(streamSubscription);
      }
      return page;
    });

/// Functions to query WorkoutRecords (as a Stream and as a Future).
Future<int> queryWorkoutRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      WorkoutRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<WorkoutRecord>> queryWorkoutRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  // Supabase: the current user's workout entries (screens filter by day
  // client-side). Ordered oldest first for the plan layout.
  final me = supabase.auth.currentUser?.id;
  if (me == null) return Stream.value(const []);
  final future = supabase
      .from('workout_entries')
      .select()
      .eq('user_id', me)
      .order('created_at', ascending: true)
      .then((rows) => (rows as List)
          .map((r) => WorkoutRecord.fromSupabase(r as Map<String, dynamic>))
          .toList());
  return Stream.fromFuture(future);
}

/// Supabase: the signed-in user's workout entries for one calendar day.
Stream<List<WorkoutRecord>> queryWorkoutsByDateStream(DateTime? date) {
  final me = supabase.auth.currentUser?.id;
  if (me == null || date == null) return Stream.value(const []);
  final start = DateTime(date.year, date.month, date.day);
  final end = start.add(const Duration(days: 1));
  final future = supabase
      .from('workout_entries')
      .select()
      .eq('user_id', me)
      .gte('date', start.toUtc().toIso8601String())
      .lt('date', end.toUtc().toIso8601String())
      .order('created_at', ascending: true)
      .then((rows) {
    final normalizedRows = (rows as List)
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row));
    return retainRowsOwnedBy(normalizedRows, me)
        .map(WorkoutRecord.fromSupabase)
        .toList(growable: false);
  });
  return Stream.fromFuture(future);
}

/// Supabase: toggle a workout entry's checked state.
Future<void> setWorkoutCheckedSupabase(String workoutId, bool isChecked) async {
  if (workoutId.isEmpty) return;
  await supabase
      .from('workout_entries')
      .update({'is_checked': isChecked}).eq('id', workoutId);
}

/// Supabase: create a workout entry (exercise) for the current user.
Future<void> createWorkoutSupabase({
  String? exerciseName,
  String? description,
  String? day,
  int? kg,
  int? sets,
  int? reps,
  String? intensity,
  int? estTime,
}) async {
  final me = supabase.auth.currentUser?.id;
  if (me == null) return;
  await supabase.from('workout_entries').insert(<String, dynamic>{
    'user_id': me,
    if (exerciseName != null) 'exercise_name': exerciseName,
    if (description != null) 'description': description,
    if (day != null) 'day': day,
    if (kg != null) 'kg': kg,
    if (sets != null) 'sets': sets,
    if (reps != null) 'reps': reps,
    if (intensity != null) 'intensity': intensity,
    if (estTime != null) 'est_time': estTime,
  });
}

/// Supabase: create an exercise session for the current user.
Future<void> createExerciseSupabase({
  String? name,
  String? description,
  int? sets,
  int? reps,
  int? kg,
  String? intensity,
  int? restTime,
}) async {
  final me = supabase.auth.currentUser?.id;
  if (me == null) return;
  await supabase.from('exercise_sessions').insert(<String, dynamic>{
    'user_id': me,
    if (name != null) 'name': name,
    if (description != null) 'description': description,
    if (sets != null) 'sets': sets,
    if (reps != null) 'reps': reps,
    if (kg != null) 'kg': kg,
    if (intensity != null) 'intensity': intensity,
    if (restTime != null) 'rest_time': restTime,
  });
}

Future<List<WorkoutRecord>> queryWorkoutRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      WorkoutRecord.collection,
      WorkoutRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );
Future<FFFirestorePage<WorkoutRecord>> queryWorkoutRecordPage({
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
  required PagingController<DocumentSnapshot?, WorkoutRecord> controller,
  List<StreamSubscription?>? streamSubscriptions,
}) =>
    queryCollectionPage(
      WorkoutRecord.collection,
      WorkoutRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      nextPageMarker: nextPageMarker,
      pageSize: pageSize,
      isStream: isStream,
    ).then((page) {
      controller.appendPage(
        page.data,
        page.nextPageMarker,
      );
      if (isStream) {
        final streamSubscription =
            (page.dataStream)?.listen((List<WorkoutRecord> data) {
          data.forEach((item) {
            final itemIndexes = controller.itemList!
                .asMap()
                .map((k, v) => MapEntry(v.reference.id, k));
            final index = itemIndexes[item.reference.id];
            final items = controller.itemList!;
            if (index != null) {
              items.replaceRange(index, index + 1, [item]);
              controller.itemList = {
                for (var item in items) item.reference: item
              }.values.toList();
            }
          });
        });
        streamSubscriptions?.add(streamSubscription);
      }
      return page;
    });

/// Functions to query ExerciseRecords (as a Stream and as a Future).
Future<int> queryExerciseRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      ExerciseRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<ExerciseRecord>> queryExerciseRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      ExerciseRecord.collection,
      ExerciseRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<ExerciseRecord>> queryExerciseRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      ExerciseRecord.collection,
      ExerciseRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );
Future<FFFirestorePage<ExerciseRecord>> queryExerciseRecordPage({
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
  required PagingController<DocumentSnapshot?, ExerciseRecord> controller,
  List<StreamSubscription?>? streamSubscriptions,
}) =>
    queryCollectionPage(
      ExerciseRecord.collection,
      ExerciseRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      nextPageMarker: nextPageMarker,
      pageSize: pageSize,
      isStream: isStream,
    ).then((page) {
      controller.appendPage(
        page.data,
        page.nextPageMarker,
      );
      if (isStream) {
        final streamSubscription =
            (page.dataStream)?.listen((List<ExerciseRecord> data) {
          data.forEach((item) {
            final itemIndexes = controller.itemList!
                .asMap()
                .map((k, v) => MapEntry(v.reference.id, k));
            final index = itemIndexes[item.reference.id];
            final items = controller.itemList!;
            if (index != null) {
              items.replaceRange(index, index + 1, [item]);
              controller.itemList = {
                for (var item in items) item.reference: item
              }.values.toList();
            }
          });
        });
        streamSubscriptions?.add(streamSubscription);
      }
      return page;
    });

/// Functions to query ReportsRecords (as a Stream and as a Future).
Future<int> queryReportsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      ReportsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<ReportsRecord>> queryReportsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      ReportsRecord.collection,
      ReportsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<ReportsRecord>> queryReportsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      ReportsRecord.collection,
      ReportsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );
Future<FFFirestorePage<ReportsRecord>> queryReportsRecordPage({
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
  required PagingController<DocumentSnapshot?, ReportsRecord> controller,
  List<StreamSubscription?>? streamSubscriptions,
}) =>
    queryCollectionPage(
      ReportsRecord.collection,
      ReportsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      nextPageMarker: nextPageMarker,
      pageSize: pageSize,
      isStream: isStream,
    ).then((page) {
      controller.appendPage(
        page.data,
        page.nextPageMarker,
      );
      if (isStream) {
        final streamSubscription =
            (page.dataStream)?.listen((List<ReportsRecord> data) {
          data.forEach((item) {
            final itemIndexes = controller.itemList!
                .asMap()
                .map((k, v) => MapEntry(v.reference.id, k));
            final index = itemIndexes[item.reference.id];
            final items = controller.itemList!;
            if (index != null) {
              items.replaceRange(index, index + 1, [item]);
              controller.itemList = {
                for (var item in items) item.reference: item
              }.values.toList();
            }
          });
        });
        streamSubscriptions?.add(streamSubscription);
      }
      return page;
    });

/// Functions to query FoodcommentsRecords (as a Stream and as a Future).
Future<int> queryFoodcommentsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      FoodcommentsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<FoodcommentsRecord>> queryFoodcommentsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      FoodcommentsRecord.collection,
      FoodcommentsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<FoodcommentsRecord>> queryFoodcommentsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      FoodcommentsRecord.collection,
      FoodcommentsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );
Future<FFFirestorePage<FoodcommentsRecord>> queryFoodcommentsRecordPage({
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
  required PagingController<DocumentSnapshot?, FoodcommentsRecord> controller,
  List<StreamSubscription?>? streamSubscriptions,
}) =>
    queryCollectionPage(
      FoodcommentsRecord.collection,
      FoodcommentsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      nextPageMarker: nextPageMarker,
      pageSize: pageSize,
      isStream: isStream,
    ).then((page) {
      controller.appendPage(
        page.data,
        page.nextPageMarker,
      );
      if (isStream) {
        final streamSubscription =
            (page.dataStream)?.listen((List<FoodcommentsRecord> data) {
          data.forEach((item) {
            final itemIndexes = controller.itemList!
                .asMap()
                .map((k, v) => MapEntry(v.reference.id, k));
            final index = itemIndexes[item.reference.id];
            final items = controller.itemList!;
            if (index != null) {
              items.replaceRange(index, index + 1, [item]);
              controller.itemList = {
                for (var item in items) item.reference: item
              }.values.toList();
            }
          });
        });
        streamSubscriptions?.add(streamSubscription);
      }
      return page;
    });

/// Functions to query VerificationDashRecords (as a Stream and as a Future).
Future<int> queryVerificationDashRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      VerificationDashRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<VerificationDashRecord>> queryVerificationDashRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      VerificationDashRecord.collection,
      VerificationDashRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<VerificationDashRecord>> queryVerificationDashRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      VerificationDashRecord.collection,
      VerificationDashRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );
Future<FFFirestorePage<VerificationDashRecord>>
    queryVerificationDashRecordPage({
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
  required PagingController<DocumentSnapshot?, VerificationDashRecord>
      controller,
  List<StreamSubscription?>? streamSubscriptions,
}) =>
        queryCollectionPage(
          VerificationDashRecord.collection,
          VerificationDashRecord.fromSnapshot,
          queryBuilder: queryBuilder,
          nextPageMarker: nextPageMarker,
          pageSize: pageSize,
          isStream: isStream,
        ).then((page) {
          controller.appendPage(
            page.data,
            page.nextPageMarker,
          );
          if (isStream) {
            final streamSubscription =
                (page.dataStream)?.listen((List<VerificationDashRecord> data) {
              data.forEach((item) {
                final itemIndexes = controller.itemList!
                    .asMap()
                    .map((k, v) => MapEntry(v.reference.id, k));
                final index = itemIndexes[item.reference.id];
                final items = controller.itemList!;
                if (index != null) {
                  items.replaceRange(index, index + 1, [item]);
                  controller.itemList = {
                    for (var item in items) item.reference: item
                  }.values.toList();
                }
              });
            });
            streamSubscriptions?.add(streamSubscription);
          }
          return page;
        });

/// Functions to query MealScannerRecords (as a Stream and as a Future).
Future<int> queryMealScannerRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      MealScannerRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<MealScannerRecord>> queryMealScannerRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      MealScannerRecord.collection,
      MealScannerRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<MealScannerRecord>> queryMealScannerRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      MealScannerRecord.collection,
      MealScannerRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );
Future<FFFirestorePage<MealScannerRecord>> queryMealScannerRecordPage({
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
  required PagingController<DocumentSnapshot?, MealScannerRecord> controller,
  List<StreamSubscription?>? streamSubscriptions,
}) =>
    queryCollectionPage(
      MealScannerRecord.collection,
      MealScannerRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      nextPageMarker: nextPageMarker,
      pageSize: pageSize,
      isStream: isStream,
    ).then((page) {
      controller.appendPage(
        page.data,
        page.nextPageMarker,
      );
      if (isStream) {
        final streamSubscription =
            (page.dataStream)?.listen((List<MealScannerRecord> data) {
          data.forEach((item) {
            final itemIndexes = controller.itemList!
                .asMap()
                .map((k, v) => MapEntry(v.reference.id, k));
            final index = itemIndexes[item.reference.id];
            final items = controller.itemList!;
            if (index != null) {
              items.replaceRange(index, index + 1, [item]);
              controller.itemList = {
                for (var item in items) item.reference: item
              }.values.toList();
            }
          });
        });
        streamSubscriptions?.add(streamSubscription);
      }
      return page;
    });

Future<int> queryCollectionCount(
  Query collection, {
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(collection);
  if (limit > 0) {
    query = query.limit(limit);
  }

  return query.count().get().catchError((err) {
    print('Error querying $collection: $err');
  }).then((value) => value.count!);
}

Stream<List<T>> queryCollection<T>(
  Query collection,
  RecordBuilder<T> recordBuilder, {
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(collection);
  if (limit > 0 || singleRecord) {
    query = query.limit(singleRecord ? 1 : limit);
  }
  return query.snapshots().handleError((err) {
    print('Error querying $collection: $err');
  }).map((s) => s.docs
      .map(
        (d) => safeGet(
          () => recordBuilder(d),
          (e) => print('Error serializing doc ${d.reference.path}:\n$e'),
        ),
      )
      .where((d) => d != null)
      .map((d) => d!)
      .toList());
}

Future<List<T>> queryCollectionOnce<T>(
  Query collection,
  RecordBuilder<T> recordBuilder, {
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(collection);
  if (limit > 0 || singleRecord) {
    query = query.limit(singleRecord ? 1 : limit);
  }
  return query.get().then((s) => s.docs
      .map(
        (d) => safeGet(
          () => recordBuilder(d),
          (e) => print('Error serializing doc ${d.reference.path}:\n$e'),
        ),
      )
      .where((d) => d != null)
      .map((d) => d!)
      .toList());
}

Filter filterIn(String field, List? list) => (list?.isEmpty ?? true)
    ? Filter(field, whereIn: null)
    : Filter(field, whereIn: list);

Filter filterArrayContainsAny(String field, List? list) =>
    (list?.isEmpty ?? true)
        ? Filter(field, arrayContainsAny: null)
        : Filter(field, arrayContainsAny: list);

extension QueryExtension on Query {
  Query whereIn(String field, List? list) => (list?.isEmpty ?? true)
      ? where(field, whereIn: null)
      : where(field, whereIn: list);

  Query whereNotIn(String field, List? list) => (list?.isEmpty ?? true)
      ? where(field, whereNotIn: null)
      : where(field, whereNotIn: list);

  Query whereArrayContainsAny(String field, List? list) =>
      (list?.isEmpty ?? true)
          ? where(field, arrayContainsAny: null)
          : where(field, arrayContainsAny: list);
}

class FFFirestorePage<T> {
  final List<T> data;
  final Stream<List<T>>? dataStream;
  final QueryDocumentSnapshot? nextPageMarker;

  FFFirestorePage(this.data, this.dataStream, this.nextPageMarker);
}

Future<FFFirestorePage<T>> queryCollectionPage<T>(
  Query collection,
  RecordBuilder<T> recordBuilder, {
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
}) async {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(collection).limit(pageSize);
  if (nextPageMarker != null) {
    query = query.startAfterDocument(nextPageMarker);
  }
  Stream<QuerySnapshot>? docSnapshotStream;
  QuerySnapshot docSnapshot;
  if (isStream) {
    docSnapshotStream = query.snapshots();
    docSnapshot = await docSnapshotStream.first;
  } else {
    docSnapshot = await query.get();
  }
  final getDocs = (QuerySnapshot s) => s.docs
      .map(
        (d) => safeGet(
          () => recordBuilder(d),
          (e) => print('Error serializing doc ${d.reference.path}:\n$e'),
        ),
      )
      .where((d) => d != null)
      .map((d) => d!)
      .toList();
  final data = getDocs(docSnapshot);
  final dataStream = docSnapshotStream?.map(getDocs);
  final nextPageToken = docSnapshot.docs.isEmpty ? null : docSnapshot.docs.last;
  return FFFirestorePage(data, dataStream, nextPageToken);
}

// Legacy Firebase user creation — superseded by the Supabase `handle_new_user()`
// trigger, which inserts the profiles / profile_private rows on sign-up. Kept as
// a no-op so any lingering caller still compiles.
Future maybeCreateUser(User user) async {
  return;
}

// Email changes now go through Supabase auth (SupabaseAuthUser.updateEmail).
Future updateUserDocument({String? email}) async {
  return;
}
