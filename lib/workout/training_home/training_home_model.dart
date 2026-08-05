import '/backend/backend.dart';
import '/components/nav_bar/nav_bar_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
    show TutorialCoachMark;
import 'training_home_widget.dart' show TrainingHomeWidget;
import 'package:flutter/material.dart';

class TrainingHomeModel extends FlutterFlowModel<TrainingHomeWidget> {
  ///  Local state fields for this page.

  String? category;

  bool search = true;

  ///  State fields for stateful widgets in this page.

  TutorialCoachMark? trainingHomeWalkthroughController;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  List<UserTrainingsRecord> simpleSearchResults1 = [];
  // State field(s) for ChoiceChips widget.
  FormFieldController<List<String>>? choiceChipsValueController;
  String? get choiceChipsValue =>
      choiceChipsValueController?.value?.firstOrNull;
  set choiceChipsValue(String? val) =>
      choiceChipsValueController?.value = val != null ? [val] : [];
  List<UserTrainingsRecord> simpleSearchResults2 = [];
  // Model for NavBar component.
  late NavBarModel navBarModel;

  @override
  void initState(BuildContext context) {
    navBarModel = createModel(context, () => NavBarModel());
  }

  @override
  void dispose() {
    trainingHomeWalkthroughController?.finish();
    textFieldFocusNode?.dispose();
    textController?.dispose();

    navBarModel.dispose();
  }
}
