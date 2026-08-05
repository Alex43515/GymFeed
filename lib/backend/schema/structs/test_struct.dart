// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class TestStruct extends FFFirebaseStruct {
  TestStruct({
    String? efat,
    String? ufat,
    String? bFatMatch,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _efat = efat,
        _ufat = ufat,
        _bFatMatch = bFatMatch,
        super(firestoreUtilData);

  // "Efat" field.
  String? _efat;
  String get efat => _efat ?? '';
  set efat(String? val) => _efat = val;

  bool hasEfat() => _efat != null;

  // "Ufat" field.
  String? _ufat;
  String get ufat => _ufat ?? '';
  set ufat(String? val) => _ufat = val;

  bool hasUfat() => _ufat != null;

  // "bFatMatch" field.
  String? _bFatMatch;
  String get bFatMatch => _bFatMatch ?? '';
  set bFatMatch(String? val) => _bFatMatch = val;

  bool hasBFatMatch() => _bFatMatch != null;

  static TestStruct fromMap(Map<String, dynamic> data) => TestStruct(
        efat: data['Efat'] as String?,
        ufat: data['Ufat'] as String?,
        bFatMatch: data['bFatMatch'] as String?,
      );

  static TestStruct? maybeFromMap(dynamic data) =>
      data is Map ? TestStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'Efat': _efat,
        'Ufat': _ufat,
        'bFatMatch': _bFatMatch,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'Efat': serializeParam(
          _efat,
          ParamType.String,
        ),
        'Ufat': serializeParam(
          _ufat,
          ParamType.String,
        ),
        'bFatMatch': serializeParam(
          _bFatMatch,
          ParamType.String,
        ),
      }.withoutNulls;

  static TestStruct fromSerializableMap(Map<String, dynamic> data) =>
      TestStruct(
        efat: deserializeParam(
          data['Efat'],
          ParamType.String,
          false,
        ),
        ufat: deserializeParam(
          data['Ufat'],
          ParamType.String,
          false,
        ),
        bFatMatch: deserializeParam(
          data['bFatMatch'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'TestStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is TestStruct &&
        efat == other.efat &&
        ufat == other.ufat &&
        bFatMatch == other.bFatMatch;
  }

  @override
  int get hashCode => const ListEquality().hash([efat, ufat, bFatMatch]);
}

TestStruct createTestStruct({
  String? efat,
  String? ufat,
  String? bFatMatch,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    TestStruct(
      efat: efat,
      ufat: ufat,
      bFatMatch: bFatMatch,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

TestStruct? updateTestStruct(
  TestStruct? test, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    test
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addTestStructData(
  Map<String, dynamic> firestoreData,
  TestStruct? test,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (test == null) {
    return;
  }
  if (test.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields = !forFieldValue && test.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final testData = getTestFirestoreData(test, forFieldValue);
  final nestedData = testData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = test.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getTestFirestoreData(
  TestStruct? test, [
  bool forFieldValue = false,
]) {
  if (test == null) {
    return {};
  }
  final firestoreData = mapToFirestore(test.toMap());

  // Add any Firestore field values
  test.firestoreUtilData.fieldValues.forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getTestListFirestoreData(
  List<TestStruct>? tests,
) =>
    tests?.map((e) => getTestFirestoreData(e, true)).toList() ?? [];
