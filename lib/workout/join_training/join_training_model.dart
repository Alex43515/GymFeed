import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_calendar.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'join_training_widget.dart' show JoinTrainingWidget;
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
    show TutorialCoachMark;
import 'package:flutter/material.dart';

class JoinTrainingModel extends FlutterFlowModel<JoinTrainingWidget> {
  ///  State fields for stateful widgets in this page.

  TutorialCoachMark? joinTrainingPageWalkthroughController;
  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;

  // State field(s) for Calendar widget.
  DateTimeRange? calendarSelectedDay;
  // State field(s) for Checkbox widget.
  Map<WorkoutRecord, bool> checkboxValueMap = {};
  List<WorkoutRecord> get checkboxCheckedItems =>
      checkboxValueMap.entries.where((e) => e.value).map((e) => e.key).toList();

  @override
  void initState(BuildContext context) {
    calendarSelectedDay = DateTimeRange(
      start: DateTime.now().startOfDay,
      end: DateTime.now().endOfDay,
    );
  }

  @override
  void dispose() {
    joinTrainingPageWalkthroughController?.finish();
    tabBarController?.dispose();
  }
}
