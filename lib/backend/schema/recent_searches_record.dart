import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/supabase/supabase_records.dart';

class RecentSearchesRecord extends FirestoreRecord {
  RecentSearchesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "userRef" field.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "time_searched" field.
  DateTime? _timeSearched;
  DateTime? get timeSearched => _timeSearched;
  bool hasTimeSearched() => _timeSearched != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _userRef = snapshotData['userRef'] as DocumentReference?;
    _timeSearched = snapshotData['time_searched'] as DateTime?;
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('recent_searches')
          : FirebaseFirestore.instance.collectionGroup('recent_searches');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('recent_searches').doc(id);

  static Stream<RecentSearchesRecord> getDocument(DocumentReference ref) =>
      Stream.fromFuture(getDocumentOnce(ref));

  static Future<RecentSearchesRecord> getDocumentOnce(
      DocumentReference ref) async {
    // ref is users/<owner>/recent_searches/<searchedUserId>.
    return RecentSearchesRecord.getDocumentFromData(
        <String, dynamic>{'userRef': supaUserRef(ref.id)}, ref);
  }

  /// Build from a Supabase `recent_searches` row (owner_id, searched_user_id).
  static RecentSearchesRecord fromSupabase(Map<String, dynamic> row) {
    final ownerId = (row['owner_id'] ?? '').toString();
    final searchedId = (row['searched_user_id'] ?? '').toString();
    final ref = FirebaseFirestore.instance
        .doc('users/$ownerId/recent_searches/$searchedId');
    return RecentSearchesRecord.getDocumentFromData(
        <String, dynamic>{
          'userRef': supaUserRef(searchedId),
          'time_searched': supaDate(row['searched_at']),
        }..removeWhere((_, v) => v == null),
        ref);
  }

  static RecentSearchesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      RecentSearchesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static RecentSearchesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      RecentSearchesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'RecentSearchesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is RecentSearchesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createRecentSearchesRecordData({
  DocumentReference? userRef,
  DateTime? timeSearched,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'userRef': userRef,
      'time_searched': timeSearched,
    }.withoutNulls,
  );

  return firestoreData;
}

class RecentSearchesRecordDocumentEquality
    implements Equality<RecentSearchesRecord> {
  const RecentSearchesRecordDocumentEquality();

  @override
  bool equals(RecentSearchesRecord? e1, RecentSearchesRecord? e2) {
    return e1?.userRef == e2?.userRef && e1?.timeSearched == e2?.timeSearched;
  }

  @override
  int hash(RecentSearchesRecord? e) =>
      const ListEquality().hash([e?.userRef, e?.timeSearched]);

  @override
  bool isValidKey(Object? o) => o is RecentSearchesRecord;
}
