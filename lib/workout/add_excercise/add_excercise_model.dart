import '/flutter_flow/flutter_flow_util.dart';
import 'add_excercise_widget.dart' show AddExcerciseWidget;
import 'package:flutter/material.dart';

class AddExcerciseModel extends FlutterFlowModel<AddExcerciseWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for ExerciseNameFirst widget.
  FocusNode? exerciseNameFirstFocusNode;
  TextEditingController? exerciseNameFirstTextController;
  String? Function(BuildContext, String?)?
      exerciseNameFirstTextControllerValidator;
  // State field(s) for day widget.
  FocusNode? dayFocusNode;
  TextEditingController? dayTextController;
  String? Function(BuildContext, String?)? dayTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    exerciseNameFirstFocusNode?.dispose();
    exerciseNameFirstTextController?.dispose();

    dayFocusNode?.dispose();
    dayTextController?.dispose();
  }
}
