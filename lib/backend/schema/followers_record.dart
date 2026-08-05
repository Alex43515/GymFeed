import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class FollowersRecord extends FirestoreRecord {
  FollowersRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "userRefs" field.
  List<DocumentReference>? _userRefs;
  List<DocumentReference> get userRefs => _userRefs ?? const [];
  bool hasUserRefs() => _userRefs != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _userRefs = getDataList(snapshotData['userRefs']);
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('followers')
          : FirebaseFirestore.instance.collectionGroup('followers');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('followers').doc(id);

  static Stream<FollowersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => FollowersRecord.fromSnapshot(s));

  static Future<FollowersRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => FollowersRecord.fromSnapshot(s));

  static FollowersRecord fromSnapshot(DocumentSnapshot snapshot) =>
      FollowersRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static FollowersRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      FollowersRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'FollowersRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is FollowersRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createFollowersRecordData() {
  final firestoreData = mapToFirestore(
    <String, dynamic>{}.withoutNulls,
  );

  return firestoreData;
}

class FollowersRecordDocumentEquality implements Equality<FollowersRecord> {
  const FollowersRecordDocumentEquality();

  @override
  bool equals(FollowersRecord? e1, FollowersRecord? e2) {
    const listEquality = ListEquality();
    return listEquality.equals(e1?.userRefs, e2?.userRefs);
  }

  @override
  int hash(FollowersRecord? e) => const ListEquality().hash([e?.userRefs]);

  @override
  bool isValidKey(Object? o) => o is FollowersRecord;
}
