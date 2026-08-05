import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MealScannerRecord extends FirestoreRecord {
  MealScannerRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "protein" field.
  int? _protein;
  int get protein => _protein ?? 0;
  bool hasProtein() => _protein != null;

  // "carbs" field.
  int? _carbs;
  int get carbs => _carbs ?? 0;
  bool hasCarbs() => _carbs != null;

  // "fats" field.
  int? _fats;
  int get fats => _fats ?? 0;
  bool hasFats() => _fats != null;

  // "calories" field.
  int? _calories;
  int get calories => _calories ?? 0;
  bool hasCalories() => _calories != null;

  // "dishName" field.
  String? _dishName;
  String get dishName => _dishName ?? '';
  bool hasDishName() => _dishName != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "mealScannerUser" field.
  DocumentReference? _mealScannerUser;
  DocumentReference? get mealScannerUser => _mealScannerUser;
  bool hasMealScannerUser() => _mealScannerUser != null;

  // "geminiParse" field.
  String? _geminiParse;
  String get geminiParse => _geminiParse ?? '';
  bool hasGeminiParse() => _geminiParse != null;

  // "isChecked" field.
  bool? _isChecked;
  bool get isChecked => _isChecked ?? false;
  bool hasIsChecked() => _isChecked != null;

  // "isMarked" field.
  bool? _isMarked;
  bool get isMarked => _isMarked ?? false;
  bool hasIsMarked() => _isMarked != null;

  // "date" field.
  DateTime? _date;
  DateTime? get date => _date;
  bool hasDate() => _date != null;

  void _initializeFields() {
    _protein = castToType<int>(snapshotData['protein']);
    _carbs = castToType<int>(snapshotData['carbs']);
    _fats = castToType<int>(snapshotData['fats']);
    _calories = castToType<int>(snapshotData['calories']);
    _dishName = snapshotData['dishName'] as String?;
    _description = snapshotData['description'] as String?;
    _mealScannerUser = snapshotData['mealScannerUser'] as DocumentReference?;
    _geminiParse = snapshotData['geminiParse'] as String?;
    _isChecked = snapshotData['isChecked'] as bool?;
    _isMarked = snapshotData['isMarked'] as bool?;
    _date = snapshotData['date'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('mealScanner');

  static Stream<MealScannerRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => MealScannerRecord.fromSnapshot(s));

  static Future<MealScannerRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => MealScannerRecord.fromSnapshot(s));

  static MealScannerRecord fromSnapshot(DocumentSnapshot snapshot) =>
      MealScannerRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static MealScannerRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      MealScannerRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'MealScannerRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is MealScannerRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createMealScannerRecordData({
  int? protein,
  int? carbs,
  int? fats,
  int? calories,
  String? dishName,
  String? description,
  DocumentReference? mealScannerUser,
  String? geminiParse,
  bool? isChecked,
  bool? isMarked,
  DateTime? date,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'calories': calories,
      'dishName': dishName,
      'description': description,
      'mealScannerUser': mealScannerUser,
      'geminiParse': geminiParse,
      'isChecked': isChecked,
      'isMarked': isMarked,
      'date': date,
    }.withoutNulls,
  );

  return firestoreData;
}

class MealScannerRecordDocumentEquality implements Equality<MealScannerRecord> {
  const MealScannerRecordDocumentEquality();

  @override
  bool equals(MealScannerRecord? e1, MealScannerRecord? e2) {
    return e1?.protein == e2?.protein &&
        e1?.carbs == e2?.carbs &&
        e1?.fats == e2?.fats &&
        e1?.calories == e2?.calories &&
        e1?.dishName == e2?.dishName &&
        e1?.description == e2?.description &&
        e1?.mealScannerUser == e2?.mealScannerUser &&
        e1?.geminiParse == e2?.geminiParse &&
        e1?.isChecked == e2?.isChecked &&
        e1?.isMarked == e2?.isMarked &&
        e1?.date == e2?.date;
  }

  @override
  int hash(MealScannerRecord? e) => const ListEquality().hash([
        e?.protein,
        e?.carbs,
        e?.fats,
        e?.calories,
        e?.dishName,
        e?.description,
        e?.mealScannerUser,
        e?.geminiParse,
        e?.isChecked,
        e?.isMarked,
        e?.date
      ]);

  @override
  bool isValidKey(Object? o) => o is MealScannerRecord;
}
