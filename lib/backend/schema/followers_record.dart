import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/supabase/supabase.dart';
import '/backend/supabase/supabase_records.dart';

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
      Stream.fromFuture(getDocumentOnce(ref));

  static Future<FollowersRecord> getDocumentOnce(DocumentReference ref) async {
    // ref is `users/<userId>/followers/main`; parent user id is the followee.
    final userId = ref.parent.parent?.id ?? '';
    return FollowersRecord.forUser(userId);
  }

  /// Build a FollowersRecord whose `userRefs` are everyone following [userId].
  static Future<FollowersRecord> forUser(String userId) async {
    final refs = <DocumentReference>[];
    if (userId.isNotEmpty) {
      final rows = await supabase
          .from('follows')
          .select('follower_id')
          .eq('followee_id', userId);
      for (final r in (rows as List)) {
        final id = (r['follower_id'] ?? '').toString();
        if (id.isNotEmpty) refs.add(supaRef('users', id));
      }
    }
    return FollowersRecord.fromSupabase(userId, refs);
  }

  static FollowersRecord fromSupabase(
    String userId,
    List<DocumentReference> userRefs,
  ) {
    final ref = FirebaseFirestore.instance.doc('users/$userId/followers/main');
    return FollowersRecord.getDocumentFromData({'userRefs': userRefs}, ref);
  }

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
