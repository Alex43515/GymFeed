import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/supabase/supabase_records.dart';

class NotificationsRecord extends FirestoreRecord {
  NotificationsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "notification_type" field.
  String? _notificationType;
  String get notificationType => _notificationType ?? '';
  bool hasNotificationType() => _notificationType != null;

  // "userRef" field.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "postRef" field.
  DocumentReference? _postRef;
  DocumentReference? get postRef => _postRef;
  bool hasPostRef() => _postRef != null;

  // "commentRef" field.
  DocumentReference? _commentRef;
  DocumentReference? get commentRef => _commentRef;
  bool hasCommentRef() => _commentRef != null;

  // "time_created" field.
  DateTime? _timeCreated;
  DateTime? get timeCreated => _timeCreated;
  bool hasTimeCreated() => _timeCreated != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _notificationType = snapshotData['notification_type'] as String?;
    _userRef = snapshotData['userRef'] as DocumentReference?;
    _postRef = snapshotData['postRef'] as DocumentReference?;
    _commentRef = snapshotData['commentRef'] as DocumentReference?;
    _timeCreated = snapshotData['time_created'] as DateTime?;
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('notifications')
          : FirebaseFirestore.instance.collectionGroup('notifications');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('notifications').doc(id);

  static Stream<NotificationsRecord> getDocument(DocumentReference ref) =>
      Stream.fromFuture(getDocumentOnce(ref));

  static Future<NotificationsRecord> getDocumentOnce(
      DocumentReference ref) async {
    final row = await supaById('notifications', ref.id) ?? const {};
    return NotificationsRecord.fromSupabase({...row, 'id': ref.id});
  }

  /// Build from a Supabase `notifications` row. Nested under the recipient
  /// (`users/<recipientId>/notifications/<id>`) so `parentReference` resolves.
  static NotificationsRecord fromSupabase(Map<String, dynamic> row) {
    final id = (row['id'] ?? '').toString();
    final recipientId = (row['recipient_id'] ?? '').toString();
    final postId = (row['post_id'] ?? '').toString();
    final commentId = (row['comment_id'] ?? '').toString();
    final ref =
        FirebaseFirestore.instance.doc('users/$recipientId/notifications/$id');
    return NotificationsRecord.getDocumentFromData(
        <String, dynamic>{
          'notification_type': row['type'],
          'userRef': supaUserRef(row['actor_id']),
          'postRef': postId.isEmpty ? null : supaRef('posts', postId),
          'commentRef': (postId.isEmpty || commentId.isEmpty)
              ? null
              : FirebaseFirestore.instance
                  .doc('posts/$postId/comments/$commentId'),
          'time_created': supaDate(row['created_at']),
        }..removeWhere((_, v) => v == null),
        ref);
  }

  static NotificationsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      NotificationsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static NotificationsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      NotificationsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'NotificationsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is NotificationsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createNotificationsRecordData({
  String? notificationType,
  DocumentReference? userRef,
  DocumentReference? postRef,
  DocumentReference? commentRef,
  DateTime? timeCreated,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'notification_type': notificationType,
      'userRef': userRef,
      'postRef': postRef,
      'commentRef': commentRef,
      'time_created': timeCreated,
    }.withoutNulls,
  );

  return firestoreData;
}

class NotificationsRecordDocumentEquality
    implements Equality<NotificationsRecord> {
  const NotificationsRecordDocumentEquality();

  @override
  bool equals(NotificationsRecord? e1, NotificationsRecord? e2) {
    return e1?.notificationType == e2?.notificationType &&
        e1?.userRef == e2?.userRef &&
        e1?.postRef == e2?.postRef &&
        e1?.commentRef == e2?.commentRef &&
        e1?.timeCreated == e2?.timeCreated;
  }

  @override
  int hash(NotificationsRecord? e) => const ListEquality().hash([
        e?.notificationType,
        e?.userRef,
        e?.postRef,
        e?.commentRef,
        e?.timeCreated
      ]);

  @override
  bool isValidKey(Object? o) => o is NotificationsRecord;
}
