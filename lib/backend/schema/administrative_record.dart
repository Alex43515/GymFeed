import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AdministrativeRecord extends FirestoreRecord {
  AdministrativeRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "usernames" field.
  List<String>? _usernames;
  List<String> get usernames => _usernames ?? const [];
  bool hasUsernames() => _usernames != null;

  void _initializeFields() {
    _usernames = getDataList(snapshotData['usernames']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('administrative');

  static Stream<AdministrativeRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => AdministrativeRecord.fromSnapshot(s));

  static Future<AdministrativeRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => AdministrativeRecord.fromSnapshot(s));

  static AdministrativeRecord fromSnapshot(DocumentSnapshot snapshot) =>
      AdministrativeRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static AdministrativeRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      AdministrativeRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'AdministrativeRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is AdministrativeRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createAdministrativeRecordData() {
  final firestoreData = mapToFirestore(
    <String, dynamic>{}.withoutNulls,
  );

  return firestoreData;
}

class AdministrativeRecordDocumentEquality
    implements Equality<AdministrativeRecord> {
  const AdministrativeRecordDocumentEquality();

  @override
  bool equals(AdministrativeRecord? e1, AdministrativeRecord? e2) {
    const listEquality = ListEquality();
    return listEquality.equals(e1?.usernames, e2?.usernames);
  }

  @override
  int hash(AdministrativeRecord? e) =>
      const ListEquality().hash([e?.usernames]);

  @override
  bool isValidKey(Object? o) => o is AdministrativeRecord;
}
