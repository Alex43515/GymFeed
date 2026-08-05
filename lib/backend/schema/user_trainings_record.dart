import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UserTrainingsRecord extends FirestoreRecord {
  UserTrainingsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "SessionDuration" field.
  int? _sessionDuration;
  int get sessionDuration => _sessionDuration ?? 0;
  bool hasSessionDuration() => _sessionDuration != null;

  // "TrainingAttendees" field.
  List<DocumentReference>? _trainingAttendees;
  List<DocumentReference> get trainingAttendees =>
      _trainingAttendees ?? const [];
  bool hasTrainingAttendees() => _trainingAttendees != null;

  // "userTraining" field.
  DocumentReference? _userTraining;
  DocumentReference? get userTraining => _userTraining;
  bool hasUserTraining() => _userTraining != null;

  // "TrainingTitle" field.
  String? _trainingTitle;
  String get trainingTitle => _trainingTitle ?? '';
  bool hasTrainingTitle() => _trainingTitle != null;

  // "TrainingTime" field.
  String? _trainingTime;
  String get trainingTime => _trainingTime ?? '';
  bool hasTrainingTime() => _trainingTime != null;

  // "TrainingDate" field.
  String? _trainingDate;
  String get trainingDate => _trainingDate ?? '';
  bool hasTrainingDate() => _trainingDate != null;

  // "TrainingCategory" field.
  String? _trainingCategory;
  String get trainingCategory => _trainingCategory ?? '';
  bool hasTrainingCategory() => _trainingCategory != null;

  // "IdTrainings" field.
  int? _idTrainings;
  int get idTrainings => _idTrainings ?? 0;
  bool hasIdTrainings() => _idTrainings != null;

  // "TrainingVideo" field.
  String? _trainingVideo;
  String get trainingVideo => _trainingVideo ?? '';
  bool hasTrainingVideo() => _trainingVideo != null;

  // "TrainingDescription" field.
  String? _trainingDescription;
  String get trainingDescription => _trainingDescription ?? '';
  bool hasTrainingDescription() => _trainingDescription != null;

  // "TrainingBackgroundImage" field.
  String? _trainingBackgroundImage;
  String get trainingBackgroundImage => _trainingBackgroundImage ?? '';
  bool hasTrainingBackgroundImage() => _trainingBackgroundImage != null;

  // "difficultyLevel" field.
  String? _difficultyLevel;
  String get difficultyLevel => _difficultyLevel ?? '';
  bool hasDifficultyLevel() => _difficultyLevel != null;

  // "likes" field.
  List<DocumentReference>? _likes;
  List<DocumentReference> get likes => _likes ?? const [];
  bool hasLikes() => _likes != null;

  // "duration" field.
  int? _duration;
  int get duration => _duration ?? 0;
  bool hasDuration() => _duration != null;

  // "trainingLocation" field.
  LatLng? _trainingLocation;
  LatLng? get trainingLocation => _trainingLocation;
  bool hasTrainingLocation() => _trainingLocation != null;

  void _initializeFields() {
    _sessionDuration = castToType<int>(snapshotData['SessionDuration']);
    _trainingAttendees = getDataList(snapshotData['TrainingAttendees']);
    _userTraining = snapshotData['userTraining'] as DocumentReference?;
    _trainingTitle = snapshotData['TrainingTitle'] as String?;
    _trainingTime = snapshotData['TrainingTime'] as String?;
    _trainingDate = snapshotData['TrainingDate'] as String?;
    _trainingCategory = snapshotData['TrainingCategory'] as String?;
    _idTrainings = castToType<int>(snapshotData['IdTrainings']);
    _trainingVideo = snapshotData['TrainingVideo'] as String?;
    _trainingDescription = snapshotData['TrainingDescription'] as String?;
    _trainingBackgroundImage =
        snapshotData['TrainingBackgroundImage'] as String?;
    _difficultyLevel = snapshotData['difficultyLevel'] as String?;
    _likes = getDataList(snapshotData['likes']);
    _duration = castToType<int>(snapshotData['duration']);
    _trainingLocation = snapshotData['trainingLocation'] as LatLng?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('userTrainings');

  static Stream<UserTrainingsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UserTrainingsRecord.fromSnapshot(s));

  static Future<UserTrainingsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => UserTrainingsRecord.fromSnapshot(s));

  static UserTrainingsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      UserTrainingsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UserTrainingsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UserTrainingsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UserTrainingsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UserTrainingsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createUserTrainingsRecordData({
  int? sessionDuration,
  DocumentReference? userTraining,
  String? trainingTitle,
  String? trainingTime,
  String? trainingDate,
  String? trainingCategory,
  int? idTrainings,
  String? trainingVideo,
  String? trainingDescription,
  String? trainingBackgroundImage,
  String? difficultyLevel,
  int? duration,
  LatLng? trainingLocation,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'SessionDuration': sessionDuration,
      'userTraining': userTraining,
      'TrainingTitle': trainingTitle,
      'TrainingTime': trainingTime,
      'TrainingDate': trainingDate,
      'TrainingCategory': trainingCategory,
      'IdTrainings': idTrainings,
      'TrainingVideo': trainingVideo,
      'TrainingDescription': trainingDescription,
      'TrainingBackgroundImage': trainingBackgroundImage,
      'difficultyLevel': difficultyLevel,
      'duration': duration,
      'trainingLocation': trainingLocation,
    }.withoutNulls,
  );

  return firestoreData;
}

class UserTrainingsRecordDocumentEquality
    implements Equality<UserTrainingsRecord> {
  const UserTrainingsRecordDocumentEquality();

  @override
  bool equals(UserTrainingsRecord? e1, UserTrainingsRecord? e2) {
    const listEquality = ListEquality();
    return e1?.sessionDuration == e2?.sessionDuration &&
        listEquality.equals(e1?.trainingAttendees, e2?.trainingAttendees) &&
        e1?.userTraining == e2?.userTraining &&
        e1?.trainingTitle == e2?.trainingTitle &&
        e1?.trainingTime == e2?.trainingTime &&
        e1?.trainingDate == e2?.trainingDate &&
        e1?.trainingCategory == e2?.trainingCategory &&
        e1?.idTrainings == e2?.idTrainings &&
        e1?.trainingVideo == e2?.trainingVideo &&
        e1?.trainingDescription == e2?.trainingDescription &&
        e1?.trainingBackgroundImage == e2?.trainingBackgroundImage &&
        e1?.difficultyLevel == e2?.difficultyLevel &&
        listEquality.equals(e1?.likes, e2?.likes) &&
        e1?.duration == e2?.duration &&
        e1?.trainingLocation == e2?.trainingLocation;
  }

  @override
  int hash(UserTrainingsRecord? e) => const ListEquality().hash([
        e?.sessionDuration,
        e?.trainingAttendees,
        e?.userTraining,
        e?.trainingTitle,
        e?.trainingTime,
        e?.trainingDate,
        e?.trainingCategory,
        e?.idTrainings,
        e?.trainingVideo,
        e?.trainingDescription,
        e?.trainingBackgroundImage,
        e?.difficultyLevel,
        e?.likes,
        e?.duration,
        e?.trainingLocation
      ]);

  @override
  bool isValidKey(Object? o) => o is UserTrainingsRecord;
}
