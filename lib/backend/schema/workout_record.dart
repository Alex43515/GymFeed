import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class WorkoutRecord extends FirestoreRecord {
  WorkoutRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "exerciseFirstName" field.
  String? _exerciseFirstName;
  String get exerciseFirstName => _exerciseFirstName ?? '';
  bool hasExerciseFirstName() => _exerciseFirstName != null;

  // "userWorkout" field.
  DocumentReference? _userWorkout;
  DocumentReference? get userWorkout => _userWorkout;
  bool hasUserWorkout() => _userWorkout != null;

  // "isChecked" field.
  bool? _isChecked;
  bool get isChecked => _isChecked ?? false;
  bool hasIsChecked() => _isChecked != null;

  // "date" field.
  DateTime? _date;
  DateTime? get date => _date;
  bool hasDate() => _date != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "day" field.
  String? _day;
  String get day => _day ?? '';
  bool hasDay() => _day != null;

  // "kg" field.
  int? _kg;
  int get kg => _kg ?? 0;
  bool hasKg() => _kg != null;

  // "sets" field.
  int? _sets;
  int get sets => _sets ?? 0;
  bool hasSets() => _sets != null;

  // "reps" field.
  int? _reps;
  int get reps => _reps ?? 0;
  bool hasReps() => _reps != null;

  // "intensety" field.
  String? _intensety;
  String get intensety => _intensety ?? '';
  bool hasIntensety() => _intensety != null;

  // "estTime" field.
  int? _estTime;
  int get estTime => _estTime ?? 0;
  bool hasEstTime() => _estTime != null;

  void _initializeFields() {
    _exerciseFirstName = snapshotData['exerciseFirstName'] as String?;
    _userWorkout = snapshotData['userWorkout'] as DocumentReference?;
    _isChecked = snapshotData['isChecked'] as bool?;
    _date = snapshotData['date'] as DateTime?;
    _description = snapshotData['description'] as String?;
    _day = snapshotData['day'] as String?;
    _kg = castToType<int>(snapshotData['kg']);
    _sets = castToType<int>(snapshotData['sets']);
    _reps = castToType<int>(snapshotData['reps']);
    _intensety = snapshotData['intensety'] as String?;
    _estTime = castToType<int>(snapshotData['estTime']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('workout');

  static Stream<WorkoutRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => WorkoutRecord.fromSnapshot(s));

  static Future<WorkoutRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => WorkoutRecord.fromSnapshot(s));

  static WorkoutRecord fromSnapshot(DocumentSnapshot snapshot) =>
      WorkoutRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static WorkoutRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      WorkoutRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'WorkoutRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is WorkoutRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createWorkoutRecordData({
  String? exerciseFirstName,
  DocumentReference? userWorkout,
  bool? isChecked,
  DateTime? date,
  String? description,
  String? day,
  int? kg,
  int? sets,
  int? reps,
  String? intensety,
  int? estTime,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'exerciseFirstName': exerciseFirstName,
      'userWorkout': userWorkout,
      'isChecked': isChecked,
      'date': date,
      'description': description,
      'day': day,
      'kg': kg,
      'sets': sets,
      'reps': reps,
      'intensety': intensety,
      'estTime': estTime,
    }.withoutNulls,
  );

  return firestoreData;
}

class WorkoutRecordDocumentEquality implements Equality<WorkoutRecord> {
  const WorkoutRecordDocumentEquality();

  @override
  bool equals(WorkoutRecord? e1, WorkoutRecord? e2) {
    return e1?.exerciseFirstName == e2?.exerciseFirstName &&
        e1?.userWorkout == e2?.userWorkout &&
        e1?.isChecked == e2?.isChecked &&
        e1?.date == e2?.date &&
        e1?.description == e2?.description &&
        e1?.day == e2?.day &&
        e1?.kg == e2?.kg &&
        e1?.sets == e2?.sets &&
        e1?.reps == e2?.reps &&
        e1?.intensety == e2?.intensety &&
        e1?.estTime == e2?.estTime;
  }

  @override
  int hash(WorkoutRecord? e) => const ListEquality().hash([
        e?.exerciseFirstName,
        e?.userWorkout,
        e?.isChecked,
        e?.date,
        e?.description,
        e?.day,
        e?.kg,
        e?.sets,
        e?.reps,
        e?.intensety,
        e?.estTime
      ]);

  @override
  bool isValidKey(Object? o) => o is WorkoutRecord;
}
