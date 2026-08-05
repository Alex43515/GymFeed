import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'food_alergies_widget.dart' show FoodAlergiesWidget;
import 'package:flutter/material.dart';

class FoodAlergiesModel extends FlutterFlowModel<FoodAlergiesWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  String? _textControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        '106pj2va' /* Field is required */,
      );
    }

    return null;
  }

  @override
  void initState(BuildContext context) {
    textControllerValidator = _textControllerValidator;
  }

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
