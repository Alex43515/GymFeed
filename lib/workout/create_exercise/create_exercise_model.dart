import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'create_exercise_widget.dart' show CreateExerciseWidget;
import 'package:flutter/material.dart';

class CreateExerciseModel extends FlutterFlowModel<CreateExerciseWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for ExerciseNameSecond widget.
  FocusNode? exerciseNameSecondFocusNode;
  TextEditingController? exerciseNameSecondTextController;
  String? Function(BuildContext, String?)?
      exerciseNameSecondTextControllerValidator;
  // State field(s) for ExerciseDescriptionSecond widget.
  FocusNode? exerciseDescriptionSecondFocusNode;
  TextEditingController? exerciseDescriptionSecondTextController;
  String? Function(BuildContext, String?)?
      exerciseDescriptionSecondTextControllerValidator;
  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
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
  // State field(s) for rest widget.
  FocusNode? restFocusNode;
  TextEditingController? restTextController;
  String? Function(BuildContext, String?)? restTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    exerciseNameSecondFocusNode?.dispose();
    exerciseNameSecondTextController?.dispose();

    exerciseDescriptionSecondFocusNode?.dispose();
    exerciseDescriptionSecondTextController?.dispose();

    setsFocusNode?.dispose();
    setsTextController?.dispose();

    repsFocusNode?.dispose();
    repsTextController?.dispose();

    kgFocusNode?.dispose();
    kgTextController?.dispose();

    restFocusNode?.dispose();
    restTextController?.dispose();
  }
}
