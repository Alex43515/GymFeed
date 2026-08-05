import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class StoriesRecord extends FirestoreRecord {
  StoriesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "user" field.
  DocumentReference? _user;
  DocumentReference? get user => _user;
  bool hasUser() => _user != null;

  // "storyPhoto" field.
  String? _storyPhoto;
  String get storyPhoto => _storyPhoto ?? '';
  bool hasStoryPhoto() => _storyPhoto != null;

  // "storyVideo" field.
  String? _storyVideo;
  String get storyVideo => _storyVideo ?? '';
  bool hasStoryVideo() => _storyVideo != null;

  // "time_created" field.
  DateTime? _timeCreated;
  DateTime? get timeCreated => _timeCreated;
  bool hasTimeCreated() => _timeCreated != null;

  // "views" field.
  List<DocumentReference>? _views;
  List<DocumentReference> get views => _views ?? const [];
  bool hasViews() => _views != null;

  // "expire_time" field.
  DateTime? _expireTime;
  DateTime? get expireTime => _expireTime;
  bool hasExpireTime() => _expireTime != null;

  void _initializeFields() {
    _user = snapshotData['user'] as DocumentReference?;
    _storyPhoto = snapshotData['storyPhoto'] as String?;
    _storyVideo = snapshotData['storyVideo'] as String?;
    _timeCreated = snapshotData['time_created'] as DateTime?;
    _views = getDataList(snapshotData['views']);
    _expireTime = snapshotData['expire_time'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('stories');

  static Stream<StoriesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => StoriesRecord.fromSnapshot(s));

  static Future<StoriesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => StoriesRecord.fromSnapshot(s));

  static StoriesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      StoriesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static StoriesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      StoriesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'StoriesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is StoriesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createStoriesRecordData({
  DocumentReference? user,
  String? storyPhoto,
  String? storyVideo,
  DateTime? timeCreated,
  DateTime? expireTime,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'user': user,
      'storyPhoto': storyPhoto,
      'storyVideo': storyVideo,
      'time_created': timeCreated,
      'expire_time': expireTime,
    }.withoutNulls,
  );

  return firestoreData;
}

class StoriesRecordDocumentEquality implements Equality<StoriesRecord> {
  const StoriesRecordDocumentEquality();

  @override
  bool equals(StoriesRecord? e1, StoriesRecord? e2) {
    const listEquality = ListEquality();
    return e1?.user == e2?.user &&
        e1?.storyPhoto == e2?.storyPhoto &&
        e1?.storyVideo == e2?.storyVideo &&
        e1?.timeCreated == e2?.timeCreated &&
        listEquality.equals(e1?.views, e2?.views) &&
        e1?.expireTime == e2?.expireTime;
  }

  @override
  int hash(StoriesRecord? e) => const ListEquality().hash([
        e?.user,
        e?.storyPhoto,
        e?.storyVideo,
        e?.timeCreated,
        e?.views,
        e?.expireTime
      ]);

  @override
  bool isValidKey(Object? o) => o is StoriesRecord;
}
