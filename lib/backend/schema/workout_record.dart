import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class WorkoutRecord extends FirestoreRecord {
  WorkoutRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "exerciseFirstName" field.
  String? _exerciseFirstName;
  String get exerciseFirstName => _exerciseFirstName ?? '';
  bool hasExerciseFirstName() => _exerciseFirstName != null;

  // "day" field.
  String? _day;
  String get day => _day ?? '';
  bool hasDay() => _day != null;

  // "userWorkout" field.
  DocumentReference? _userWorkout;
  DocumentReference? get userWorkout => _userWorkout;
  bool hasUserWorkout() => _userWorkout != null;

  // "isChecked" field.
  bool? _isChecked;
  bool get isChecked => _isChecked ?? false;
  bool hasIsChecked() => _isChecked != null;

  void _initializeFields() {
    _exerciseFirstName = snapshotData['exerciseFirstName'] as String?;
    _day = snapshotData['day'] as String?;
    _userWorkout = snapshotData['userWorkout'] as DocumentReference?;
    _isChecked = snapshotData['isChecked'] as bool?;
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
  String? day,
  DocumentReference? userWorkout,
  bool? isChecked,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'exerciseFirstName': exerciseFirstName,
      'day': day,
      'userWorkout': userWorkout,
      'isChecked': isChecked,
    }.withoutNulls,
  );

  return firestoreData;
}

class WorkoutRecordDocumentEquality implements Equality<WorkoutRecord> {
  const WorkoutRecordDocumentEquality();

  @override
  bool equals(WorkoutRecord? e1, WorkoutRecord? e2) {
    return e1?.exerciseFirstName == e2?.exerciseFirstName &&
        e1?.day == e2?.day &&
        e1?.userWorkout == e2?.userWorkout &&
        e1?.isChecked == e2?.isChecked;
  }

  @override
  int hash(WorkoutRecord? e) => const ListEquality()
      .hash([e?.exerciseFirstName, e?.day, e?.userWorkout, e?.isChecked]);

  @override
  bool isValidKey(Object? o) => o is WorkoutRecord;
}
