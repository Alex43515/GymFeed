import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'add_excercise_copy_widget.dart' show AddExcerciseCopyWidget;
import 'package:flutter/material.dart';

class AddExcerciseCopyModel extends FlutterFlowModel<AddExcerciseCopyWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for ExerciseNameFirst widget.
  FocusNode? exerciseNameFirstFocusNode;
  TextEditingController? exerciseNameFirstTextController;
  String? Function(BuildContext, String?)?
      exerciseNameFirstTextControllerValidator;
  DateTime? datePicked;
  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  // State field(s) for rest widget.
  FocusNode? restFocusNode;
  TextEditingController? restTextController;
  String? Function(BuildContext, String?)? restTextControllerValidator;
  // State field(s) for description widget.
  FocusNode? descriptionFocusNode;
  TextEditingController? descriptionTextController;
  String? Function(BuildContext, String?)? descriptionTextControllerValidator;
  // State field(s) for sets widget.
  FocusNode? setsFocusNode;
  TextEditingController? setsTextController;
  String? Function(BuildContext, String?)? setsTextControllerValidator;
  // State field(s) for reps widget.
  FocusNode? repsFocusNode;
  TextEditingController? repsTextController;
  String? Function(BuildContext, String?)? repsTextControllerValidator;
  // State field(s) for kg widget.
  FocusNode? kgFocusNode;
  TextEditingController? kgTextController;
  String? Function(BuildContext, String?)? kgTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    exerciseNameFirstFocusNode?.dispose();
    exerciseNameFirstTextController?.dispose();

    restFocusNode?.dispose();
    restTextController?.dispose();

    descriptionFocusNode?.dispose();
    descriptionTextController?.dispose();

    setsFocusNode?.dispose();
    setsTextController?.dispose();

    repsFocusNode?.dispose();
    repsTextController?.dispose();

    kgFocusNode?.dispose();
    kgTextController?.dispose();
  }
}
