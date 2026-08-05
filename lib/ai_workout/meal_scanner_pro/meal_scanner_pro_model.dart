import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'meal_scanner_pro_widget.dart' show MealScannerProWidget;
import 'package:flutter/material.dart';

class MealScannerProModel extends FlutterFlowModel<MealScannerProWidget> {
  ///  Local state fields for this page.

  String query = 'no string';

  String imageUrl = 'false';

  DateTime? date;

  ///  State fields for stateful widgets in this page.

  bool isDataUploading = false;
  FFUploadedFile uploadedLocalFile =
      FFUploadedFile(bytes: Uint8List.fromList([]));
  String uploadedFileUrl = '';

  // State field(s) for alwayspopulated widget.
  FocusNode? alwayspopulatedFocusNode;
  TextEditingController? alwayspopulatedTextController;
  String? Function(BuildContext, String?)?
      alwayspopulatedTextControllerValidator;
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
  // Stores action output result for [Backend Call - API (createChatCompletion)] action in Button widget.
  ApiCallResponse? openaiRes;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    alwayspopulatedFocusNode?.dispose();
    alwayspopulatedTextController?.dispose();

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
