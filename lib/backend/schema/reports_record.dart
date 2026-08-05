import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ReportsRecord extends FirestoreRecord {
  ReportsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "userID" field.
  String? _userID;
  String get userID => _userID ?? '';
  bool hasUserID() => _userID != null;

  // "postImage" field.
  String? _postImage;
  String get postImage => _postImage ?? '';
  bool hasPostImage() => _postImage != null;

  // "postRef" field.
  String? _postRef;
  String get postRef => _postRef ?? '';
  bool hasPostRef() => _postRef != null;

  // "timeOfReport" field.
  DateTime? _timeOfReport;
  DateTime? get timeOfReport => _timeOfReport;
  bool hasTimeOfReport() => _timeOfReport != null;

  // "details" field.
  String? _details;
  String get details => _details ?? '';
  bool hasDetails() => _details != null;

  void _initializeFields() {
    _userID = snapshotData['userID'] as String?;
    _postImage = snapshotData['postImage'] as String?;
    _postRef = snapshotData['postRef'] as String?;
    _timeOfReport = snapshotData['timeOfReport'] as DateTime?;
    _details = snapshotData['details'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('reports');

  static Stream<ReportsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ReportsRecord.fromSnapshot(s));

  static Future<ReportsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ReportsRecord.fromSnapshot(s));

  static ReportsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ReportsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ReportsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ReportsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ReportsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ReportsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createReportsRecordData({
  String? userID,
  String? postImage,
  String? postRef,
  DateTime? timeOfReport,
  String? details,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'userID': userID,
      'postImage': postImage,
      'postRef': postRef,
      'timeOfReport': timeOfReport,
      'details': details,
    }.withoutNulls,
  );

  return firestoreData;
}

class ReportsRecordDocumentEquality implements Equality<ReportsRecord> {
  const ReportsRecordDocumentEquality();

  @override
  bool equals(ReportsRecord? e1, ReportsRecord? e2) {
    return e1?.userID == e2?.userID &&
        e1?.postImage == e2?.postImage &&
        e1?.postRef == e2?.postRef &&
        e1?.timeOfReport == e2?.timeOfReport &&
        e1?.details == e2?.details;
  }

  @override
  int hash(ReportsRecord? e) => const ListEquality()
      .hash([e?.userID, e?.postImage, e?.postRef, e?.timeOfReport, e?.details]);

  @override
  bool isValidKey(Object? o) => o is ReportsRecord;
}
