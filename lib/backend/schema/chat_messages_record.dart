import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/supabase/supabase_records.dart';

class ChatMessagesRecord extends FirestoreRecord {
  ChatMessagesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "user" field.
  DocumentReference? _user;
  DocumentReference? get user => _user;
  bool hasUser() => _user != null;

  // "chat" field.
  DocumentReference? _chat;
  DocumentReference? get chat => _chat;
  bool hasChat() => _chat != null;

  // "text" field.
  String? _text;
  String get text => _text ?? '';
  bool hasText() => _text != null;

  // "timestamp" field.
  DateTime? _timestamp;
  DateTime? get timestamp => _timestamp;
  bool hasTimestamp() => _timestamp != null;

  // "postRef" field.
  DocumentReference? _postRef;
  DocumentReference? get postRef => _postRef;
  bool hasPostRef() => _postRef != null;

  // "commentRef" field.
  DocumentReference? _commentRef;
  DocumentReference? get commentRef => _commentRef;
  bool hasCommentRef() => _commentRef != null;

  // "image" field.
  String? _image;
  String get image => _image ?? '';
  bool hasImage() => _image != null;

  // "video" field.
  String? _video;
  String get video => _video ?? '';
  bool hasVideo() => _video != null;

  void _initializeFields() {
    _user = snapshotData['user'] as DocumentReference?;
    _chat = snapshotData['chat'] as DocumentReference?;
    _text = snapshotData['text'] as String?;
    _timestamp = snapshotData['timestamp'] as DateTime?;
    _postRef = snapshotData['postRef'] as DocumentReference?;
    _commentRef = snapshotData['commentRef'] as DocumentReference?;
    _image = snapshotData['image'] as String?;
    _video = snapshotData['video'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('chat_messages');

  static Stream<ChatMessagesRecord> getDocument(DocumentReference ref) =>
      Stream.fromFuture(getDocumentOnce(ref));

  static Future<ChatMessagesRecord> getDocumentOnce(
      DocumentReference ref) async {
    final row = await supaById('chat_messages', ref.id) ?? const {};
    return ChatMessagesRecord.fromSupabase({...row, 'id': ref.id});
  }

  /// Build from a Supabase `chat_messages` row.
  static ChatMessagesRecord fromSupabase(Map<String, dynamic> row) {
    final id = (row['id'] ?? '').toString();
    final chatId = (row['chat_id'] ?? '').toString();
    final postId = (row['post_id'] ?? '').toString();
    return ChatMessagesRecord.getDocumentFromData(
        <String, dynamic>{
          'user': supaUserRef(row['user_id']),
          'chat': chatId.isEmpty ? null : supaRef('chats', chatId),
          'text': row['text'],
          'timestamp': supaDate(row['created_at']),
          'image': row['image_url'],
          'video': row['video_url'],
          'postRef': postId.isEmpty ? null : supaRef('posts', postId),
        }..removeWhere((_, v) => v == null),
        supaRef('chat_messages', id));
  }

  static ChatMessagesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ChatMessagesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ChatMessagesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ChatMessagesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ChatMessagesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ChatMessagesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createChatMessagesRecordData({
  DocumentReference? user,
  DocumentReference? chat,
  String? text,
  DateTime? timestamp,
  DocumentReference? postRef,
  DocumentReference? commentRef,
  String? image,
  String? video,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'user': user,
      'chat': chat,
      'text': text,
      'timestamp': timestamp,
      'postRef': postRef,
      'commentRef': commentRef,
      'image': image,
      'video': video,
    }.withoutNulls,
  );

  return firestoreData;
}

class ChatMessagesRecordDocumentEquality
    implements Equality<ChatMessagesRecord> {
  const ChatMessagesRecordDocumentEquality();

  @override
  bool equals(ChatMessagesRecord? e1, ChatMessagesRecord? e2) {
    return e1?.user == e2?.user &&
        e1?.chat == e2?.chat &&
        e1?.text == e2?.text &&
        e1?.timestamp == e2?.timestamp &&
        e1?.postRef == e2?.postRef &&
        e1?.commentRef == e2?.commentRef &&
        e1?.image == e2?.image &&
        e1?.video == e2?.video;
  }

  @override
  int hash(ChatMessagesRecord? e) => const ListEquality().hash([
        e?.user,
        e?.chat,
        e?.text,
        e?.timestamp,
        e?.postRef,
        e?.commentRef,
        e?.image,
        e?.video
      ]);

  @override
  bool isValidKey(Object? o) => o is ChatMessagesRecord;
}
