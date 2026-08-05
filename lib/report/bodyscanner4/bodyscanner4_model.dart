import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'bodyscanner4_widget.dart' show Bodyscanner4Widget;
import 'package:flutter/material.dart';

class Bodyscanner4Model extends FlutterFlowModel<Bodyscanner4Widget> {
  ///  Local state fields for this page.

  bool check = false;

  bool waitCheck = false;

  bool waitCheck2 = false;

  ///  State fields for stateful widgets in this page.

  bool isDataUploading1 = false;
  FFUploadedFile uploadedLocalFile1 =
      FFUploadedFile(bytes: Uint8List.fromList([]));

  bool isDataUploading2 = false;
  FFUploadedFile uploadedLocalFile2 =
      FFUploadedFile(bytes: Uint8List.fromList([]));

  // Stores action output result for [Gemini - Text From Image] action in Button6 widget.
  String? geminiOutput;
  // Stores action output result for [Custom Action - bFat] action in Button6 widget.
  String? bfat2;
  // Stores action output result for [Custom Action - uFat] action in Button6 widget.
  String? ufat2;
  // Stores action output result for [Custom Action - eFat] action in Button6 widget.
  String? efat2;
  // Stores action output result for [Custom Action - leanMass] action in Button6 widget.
  String? leanmass2;
  // Stores action output result for [Custom Action - bFat2] action in Button6 widget.
  double? bFat;
  // Stores action output result for [Custom Action - eFat2] action in Button6 widget.
  double? efat;
  // Stores action output result for [Custom Action - leanMass2] action in Button6 widget.
  double? leanmass;
  // Stores action output result for [Custom Action - uFat2] action in Button6 widget.
  double? ufat;
  // Stores action output result for [Custom Action - leanMassIndex] action in Button6 widget.
  int? leanMassIndex;
  // Stores action output result for [Custom Action - fatMassIndex] action in Button6 widget.
  int? fatMassIndex;
  // Stores action output result for [Custom Action - caloriesBurnt] action in Button6 widget.
  String? caloriesBurnt;
  // Stores action output result for [Gemini - Text From Image] action in Button6 widget.
  String? geminiOutput2;
  // Stores action output result for [Custom Action - caloriesBurn] action in Button6 widget.
  String? caloriesBurn;
  // Stores action output result for [Custom Action - caloriesIntake] action in Button6 widget.
  String? caloriesIntake;
  // Stores action output result for [Custom Action - workoutPlan] action in Button6 widget.
  String? workoutPlan;
  // Stores action output result for [Custom Action - caloriesIntakeNumber] action in Button6 widget.
  String? caloricIntakePerDay;
  // Stores action output result for [Gemini - Text From Image] action in Button6 widget.
  String? cusotmMealPlan;
  // Stores action output result for [Custom Action - carbsPerDay] action in Button6 widget.
  String? carbsPerDay;
  // Stores action output result for [Custom Action - fatsPerDay] action in Button6 widget.
  String? fatsPerDay;
  // Stores action output result for [Custom Action - proteinsPerDay] action in Button6 widget.
  String? proteinPerDay;
  // Stores action output result for [Custom Action - mealPlan] action in Button6 widget.
  String? customMealPlanOutput;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
