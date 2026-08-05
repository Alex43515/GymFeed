import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class BookmarksRecord extends FirestoreRecord {
  BookmarksRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "postRefs" field.
  List<DocumentReference>? _postRefs;
  List<DocumentReference> get postRefs => _postRefs ?? const [];
  bool hasPostRefs() => _postRefs != null;

  // "postTrainingRef" field.
  List<DocumentReference>? _postTrainingRef;
  List<DocumentReference> get postTrainingRef => _postTrainingRef ?? const [];
  bool hasPostTrainingRef() => _postTrainingRef != null;

  // "foodPostRef" field.
  List<DocumentReference>? _foodPostRef;
  List<DocumentReference> get foodPostRef => _foodPostRef ?? const [];
  bool hasFoodPostRef() => _foodPostRef != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _postRefs = getDataList(snapshotData['postRefs']);
    _postTrainingRef = getDataList(snapshotData['postTrainingRef']);
    _foodPostRef = getDataList(snapshotData['foodPostRef']);
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('bookmarks')
          : FirebaseFirestore.instance.collectionGroup('bookmarks');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('bookmarks').doc(id);

  static Stream<BookmarksRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => BookmarksRecord.fromSnapshot(s));

  static Future<BookmarksRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => BookmarksRecord.fromSnapshot(s));

  static BookmarksRecord fromSnapshot(DocumentSnapshot snapshot) =>
      BookmarksRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static BookmarksRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      BookmarksRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'BookmarksRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is BookmarksRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createBookmarksRecordData() {
  final firestoreData = mapToFirestore(
    <String, dynamic>{}.withoutNulls,
  );

  return firestoreData;
}

class BookmarksRecordDocumentEquality implements Equality<BookmarksRecord> {
  const BookmarksRecordDocumentEquality();

  @override
  bool equals(BookmarksRecord? e1, BookmarksRecord? e2) {
    const listEquality = ListEquality();
    return listEquality.equals(e1?.postRefs, e2?.postRefs) &&
        listEquality.equals(e1?.postTrainingRef, e2?.postTrainingRef) &&
        listEquality.equals(e1?.foodPostRef, e2?.foodPostRef);
  }

  @override
  int hash(BookmarksRecord? e) => const ListEquality()
      .hash([e?.postRefs, e?.postTrainingRef, e?.foodPostRef]);

  @override
  bool isValidKey(Object? o) => o is BookmarksRecord;
}
