import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ChatRefsRecord extends FirestoreRecord {
  ChatRefsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "userRef" field.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "chatRef" field.
  DocumentReference? _chatRef;
  DocumentReference? get chatRef => _chatRef;
  bool hasChatRef() => _chatRef != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _userRef = snapshotData['userRef'] as DocumentReference?;
    _chatRef = snapshotData['chatRef'] as DocumentReference?;
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('chatRefs')
          : FirebaseFirestore.instance.collectionGroup('chatRefs');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('chatRefs').doc(id);

  static Stream<ChatRefsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ChatRefsRecord.fromSnapshot(s));

  static Future<ChatRefsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ChatRefsRecord.fromSnapshot(s));

  static ChatRefsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ChatRefsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ChatRefsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ChatRefsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ChatRefsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ChatRefsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createChatRefsRecordData({
  DocumentReference? userRef,
  DocumentReference? chatRef,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'userRef': userRef,
      'chatRef': chatRef,
    }.withoutNulls,
  );

  return firestoreData;
}

class ChatRefsRecordDocumentEquality implements Equality<ChatRefsRecord> {
  const ChatRefsRecordDocumentEquality();

  @override
  bool equals(ChatRefsRecord? e1, ChatRefsRecord? e2) {
    return e1?.userRef == e2?.userRef && e1?.chatRef == e2?.chatRef;
  }

  @override
  int hash(ChatRefsRecord? e) =>
      const ListEquality().hash([e?.userRef, e?.chatRef]);

  @override
  bool isValidKey(Object? o) => o is ChatRefsRecord;
}
