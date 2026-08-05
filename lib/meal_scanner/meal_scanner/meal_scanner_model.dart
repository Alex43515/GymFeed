import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'meal_scanner_widget.dart' show MealScannerWidget;
import 'package:flutter/material.dart';

class MealScannerModel extends FlutterFlowModel<MealScannerWidget> {
  ///  Local state fields for this page.

  String query = 'no string';

  String imageUrl = 'false';

  DateTime? date;

  ///  State fields for stateful widgets in this page.

  DateTime? datePicked;
  bool isDataUploading = false;
  FFUploadedFile uploadedLocalFile =
      FFUploadedFile(bytes: Uint8List.fromList([]));

  // State field(s) for FoodItems widget.
  FocusNode? foodItemsFocusNode;
  TextEditingController? foodItemsTextController;
  String? Function(BuildContext, String?)? foodItemsTextControllerValidator;
  // State field(s) for PortionSizes widget.
  FocusNode? portionSizesFocusNode;
  TextEditingController? portionSizesTextController;
  String? Function(BuildContext, String?)? portionSizesTextControllerValidator;
  // State field(s) for CookingMethods widget.
  FocusNode? cookingMethodsFocusNode;
  TextEditingController? cookingMethodsTextController;
  String? Function(BuildContext, String?)?
      cookingMethodsTextControllerValidator;
  // State field(s) for IngredientDetails widget.
  FocusNode? ingredientDetailsFocusNode;
  TextEditingController? ingredientDetailsTextController;
  String? Function(BuildContext, String?)?
      ingredientDetailsTextControllerValidator;
  // Stores action output result for [Gemini - Text From Image] action in Button widget.
  String? geminiOutput;
  // Stores action output result for [Backend Call - Create Document] action in Button widget.
  MealScannerRecord? mealdocument;
  // Stores action output result for [Custom Action - fatsScanner2] action in Button widget.
  int? fatsScanner;
  // Stores action output result for [Custom Action - dishNameScanner] action in Button widget.
  String? dishName;
  // Stores action output result for [Custom Action - carbsScanner] action in Button widget.
  int? carbsScanner;
  // Stores action output result for [Custom Action - proteinScanner] action in Button widget.
  int? proteinScanner;
  // Stores action output result for [Custom Action - caloriesScanner] action in Button widget.
  int? caloriesScanner;
  // Stores action output result for [Custom Action - descriptionScanner] action in Button widget.
  String? descriptionScanner;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    foodItemsFocusNode?.dispose();
    foodItemsTextController?.dispose();

    portionSizesFocusNode?.dispose();
    portionSizesTextController?.dispose();

    cookingMethodsFocusNode?.dispose();
    cookingMethodsTextController?.dispose();

    ingredientDetailsFocusNode?.dispose();
    ingredientDetailsTextController?.dispose();
  }
}
