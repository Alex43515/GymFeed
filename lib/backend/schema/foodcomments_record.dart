import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class FoodcommentsRecord extends FirestoreRecord {
  FoodcommentsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "foodAssositaion" field.
  DocumentReference? _foodAssositaion;
  DocumentReference? get foodAssositaion => _foodAssositaion;
  bool hasFoodAssositaion() => _foodAssositaion != null;

  // "commentUser" field.
  DocumentReference? _commentUser;
  DocumentReference? get commentUser => _commentUser;
  bool hasCommentUser() => _commentUser != null;

  // "comment" field.
  String? _comment;
  String get comment => _comment ?? '';
  bool hasComment() => _comment != null;

  // "timePosted" field.
  DateTime? _timePosted;
  DateTime? get timePosted => _timePosted;
  bool hasTimePosted() => _timePosted != null;

  void _initializeFields() {
    _foodAssositaion = snapshotData['foodAssositaion'] as DocumentReference?;
    _commentUser = snapshotData['commentUser'] as DocumentReference?;
    _comment = snapshotData['comment'] as String?;
    _timePosted = snapshotData['timePosted'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('foodcomments');

  static Stream<FoodcommentsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => FoodcommentsRecord.fromSnapshot(s));

  static Future<FoodcommentsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => FoodcommentsRecord.fromSnapshot(s));

  static FoodcommentsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      FoodcommentsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static FoodcommentsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      FoodcommentsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'FoodcommentsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is FoodcommentsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createFoodcommentsRecordData({
  DocumentReference? foodAssositaion,
  DocumentReference? commentUser,
  String? comment,
  DateTime? timePosted,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'foodAssositaion': foodAssositaion,
      'commentUser': commentUser,
      'comment': comment,
      'timePosted': timePosted,
    }.withoutNulls,
  );

  return firestoreData;
}

class FoodcommentsRecordDocumentEquality
    implements Equality<FoodcommentsRecord> {
  const FoodcommentsRecordDocumentEquality();

  @override
  bool equals(FoodcommentsRecord? e1, FoodcommentsRecord? e2) {
    return e1?.foodAssositaion == e2?.foodAssositaion &&
        e1?.commentUser == e2?.commentUser &&
        e1?.comment == e2?.comment &&
        e1?.timePosted == e2?.timePosted;
  }

  @override
  int hash(FoodcommentsRecord? e) => const ListEquality()
      .hash([e?.foodAssositaion, e?.commentUser, e?.comment, e?.timePosted]);

  @override
  bool isValidKey(Object? o) => o is FoodcommentsRecord;
}
