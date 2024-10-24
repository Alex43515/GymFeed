import '/backend/backend.dart';
import '/components/nav_bar/nav_bar_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
    show TutorialCoachMark;
import 'training_home_widget.dart' show TrainingHomeWidget;
import 'package:flutter/material.dart';

class TrainingHomeModel extends FlutterFlowModel<TrainingHomeWidget> {
  ///  State fields for stateful widgets in this page.

  TutorialCoachMark? trainingHomeWalkthroughController;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  List<UserTrainingsRecord> simpleSearchResults = [];
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
