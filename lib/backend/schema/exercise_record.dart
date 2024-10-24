import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ExerciseRecord extends FirestoreRecord {
  ExerciseRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "exerciseSessionName" field.
  String? _exerciseSessionName;
  String get exerciseSessionName => _exerciseSessionName ?? '';
  bool hasExerciseSessionName() => _exerciseSessionName != null;

  // "sets" field.
  int? _sets;
  int get sets => _sets ?? 0;
  bool hasSets() => _sets != null;

  // "reps" field.
  int? _reps;
  int get reps => _reps ?? 0;
  bool hasReps() => _reps != null;

  // "kg" field.
  int? _kg;
  int get kg => _kg ?? 0;
  bool hasKg() => _kg != null;

  // "userExercise" field.
  DocumentReference? _userExercise;
  DocumentReference? get userExercise => _userExercise;
  bool hasUserExercise() => _userExercise != null;

  // "isChecked" field.
  bool? _isChecked;
  bool get isChecked => _isChecked ?? false;
  bool hasIsChecked() => _isChecked != null;

  void _initializeFields() {
    _exerciseSessionName = snapshotData['exerciseSessionName'] as String?;
    _sets = castToType<int>(snapshotData['sets']);
    _reps = castToType<int>(snapshotData['reps']);
    _kg = castToType<int>(snapshotData['kg']);
    _userExercise = snapshotData['userExercise'] as DocumentReference?;
    _isChecked = snapshotData['isChecked'] as bool?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('exercise');

  static Stream<ExerciseRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ExerciseRecord.fromSnapshot(s));

  static Future<ExerciseRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ExerciseRecord.fromSnapshot(s));

  static ExerciseRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ExerciseRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ExerciseRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ExerciseRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ExerciseRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ExerciseRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createExerciseRecordData({
  String? exerciseSessionName,
  int? sets,
  int? reps,
  int? kg,
  DocumentReference? userExercise,
  bool? isChecked,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'exerciseSessionName': exerciseSessionName,
      'sets': sets,
      'reps': reps,
      'kg': kg,
      'userExercise': userExercise,
      'isChecked': isChecked,
    }.withoutNulls,
  );

  return firestoreData;
}

class ExerciseRecordDocumentEquality implements Equality<ExerciseRecord> {
  const ExerciseRecordDocumentEquality();

  @override
  bool equals(ExerciseRecord? e1, ExerciseRecord? e2) {
    return e1?.exerciseSessionName == e2?.exerciseSessionName &&
        e1?.sets == e2?.sets &&
        e1?.reps == e2?.reps &&
        e1?.kg == e2?.kg &&
        e1?.userExercise == e2?.userExercise &&
        e1?.isChecked == e2?.isChecked;
  }

  @override
  int hash(ExerciseRecord? e) => const ListEquality().hash([
        e?.exerciseSessionName,
        e?.sets,
        e?.reps,
        e?.kg,
        e?.userExercise,
        e?.isChecked
      ]);

  @override
  bool isValidKey(Object? o) => o is ExerciseRecord;
}
