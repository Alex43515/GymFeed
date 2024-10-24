import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'create_food_post_widget.dart' show CreateFoodPostWidget;
import 'package:flutter/material.dart';

class CreateFoodPostModel extends FlutterFlowModel<CreateFoodPostWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;

  // State field(s) for postTitle widget.
  FocusNode? postTitleFocusNode;
  TextEditingController? postTitleTextController;
  String? Function(BuildContext, String?)? postTitleTextControllerValidator;
  // State field(s) for recipe widget.
  FocusNode? recipeFocusNode;
  TextEditingController? recipeTextController;
  String? Function(BuildContext, String?)? recipeTextControllerValidator;
  // State field(s) for cookingTime widget.
  FocusNode? cookingTimeFocusNode;
  TextEditingController? cookingTimeTextController;
  String? Function(BuildContext, String?)? cookingTimeTextControllerValidator;
  // State field(s) for nutrition widget.
  FocusNode? nutritionFocusNode;
  TextEditingController? nutritionTextController;
  String? Function(BuildContext, String?)? nutritionTextControllerValidator;
  // State field(s) for mealType widget.
  String? mealTypeValue;
  FormFieldController<String>? mealTypeValueController;
  // State field(s) for Calories widget.
  FocusNode? caloriesFocusNode;
  TextEditingController? caloriesTextController;
  String? Function(BuildContext, String?)? caloriesTextControllerValidator;
  // State field(s) for Protein widget.
  FocusNode? proteinFocusNode;
  TextEditingController? proteinTextController;
  String? Function(BuildContext, String?)? proteinTextControllerValidator;
  // State field(s) for Switch widget.
  bool? switchValue1;
  // State field(s) for Switch widget.
  bool? switchValue2;
  bool isDataUploading1 = false;
  FFUploadedFile uploadedLocalFile1 =
      FFUploadedFile(bytes: Uint8List.fromList([]));
  String uploadedFileUrl1 = '';

  bool isDataUploading2 = false;
  FFUploadedFile uploadedLocalFile2 =
      FFUploadedFile(bytes: Uint8List.fromList([]));
  String uploadedFileUrl2 = '';

  // Stores action output result for [Backend Call - Create Document] action in Button widget.
  PostsRecord? post;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tabBarController?.dispose();
    postTitleFocusNode?.dispose();
    postTitleTextController?.dispose();

    recipeFocusNode?.dispose();
    recipeTextController?.dispose();

    cookingTimeFocusNode?.dispose();
    cookingTimeTextController?.dispose();

    nutritionFocusNode?.dispose();
    nutritionTextController?.dispose();

    caloriesFocusNode?.dispose();
    caloriesTextController?.dispose();

    proteinFocusNode?.dispose();
    proteinTextController?.dispose();
  }
}
