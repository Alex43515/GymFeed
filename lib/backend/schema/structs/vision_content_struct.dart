// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class VisionContentStruct extends FFFirebaseStruct {
  VisionContentStruct({
    String? type,
    TextStruct? text,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _type = type,
        _text = text,
        super(firestoreUtilData);

  // "type" field.
  String? _type;
  String get type => _type ?? '';
  set type(String? val) => _type = val;

  bool hasType() => _type != null;

  // "text" field.
  TextStruct? _text;
  TextStruct get text => _text ?? TextStruct();
  set text(TextStruct? val) => _text = val;

  void updateText(Function(TextStruct) updateFn) {
    updateFn(_text ??= TextStruct());
  }

  bool hasText() => _text != null;

  static VisionContentStruct fromMap(Map<String, dynamic> data) =>
      VisionContentStruct(
        type: data['type'] as String?,
        text: data['text'] is TextStruct
            ? data['text']
            : TextStruct.maybeFromMap(data['text']),
      );

  static VisionContentStruct? maybeFromMap(dynamic data) => data is Map
      ? VisionContentStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'type': _type,
        'text': _text?.toMap(),
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'type': serializeParam(
          _type,
          ParamType.String,
        ),
        'text': serializeParam(
          _text,
          ParamType.DataStruct,
        ),
      }.withoutNulls;

  static VisionContentStruct fromSerializableMap(Map<String, dynamic> data) =>
      VisionContentStruct(
        type: deserializeParam(
          data['type'],
          ParamType.String,
          false,
        ),
        text: deserializeStructParam(
          data['text'],
          ParamType.DataStruct,
          false,
          structBuilder: TextStruct.fromSerializableMap,
        ),
      );

  @override
  String toString() => 'VisionContentStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is VisionContentStruct &&
        type == other.type &&
        text == other.text;
  }

  @override
  int get hashCode => const ListEquality().hash([type, text]);
}

VisionContentStruct createVisionContentStruct({
  String? type,
  TextStruct? text,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    VisionContentStruct(
      type: type,
      text: text ?? (clearUnsetFields ? TextStruct() : null),
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

VisionContentStruct? updateVisionContentStruct(
  VisionContentStruct? visionContent, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    visionContent
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addVisionContentStructData(
  Map<String, dynamic> firestoreData,
  VisionContentStruct? visionContent,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (visionContent == null) {
    return;
  }
  if (visionContent.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && visionContent.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final visionContentData =
      getVisionContentFirestoreData(visionContent, forFieldValue);
  final nestedData =
      visionContentData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = visionContent.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getVisionContentFirestoreData(
  VisionContentStruct? visionContent, [
  bool forFieldValue = false,
]) {
  if (visionContent == null) {
    return {};
  }
  final firestoreData = mapToFirestore(visionContent.toMap());

  // Handle nested data for "text" field.
  addTextStructData(
    firestoreData,
    visionContent.hasText() ? visionContent.text : null,
    'text',
    forFieldValue,
  );

  // Add any Firestore field values
  visionContent.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getVisionContentListFirestoreData(
  List<VisionContentStruct>? visionContents,
) =>
    visionContents
        ?.map((e) => getVisionContentFirestoreData(e, true))
        .toList() ??
    [];
