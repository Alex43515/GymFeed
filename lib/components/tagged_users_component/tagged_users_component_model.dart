import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_timer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'tagged_users_component_widget.dart' show TaggedUsersComponentWidget;
import 'package:flutter/material.dart';

class TaggedUsersComponentModel
    extends FlutterFlowModel<TaggedUsersComponentWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Timer widget.
  final timerInitialTimeMs = 200;
  int timerMilliseconds = 200;
  String timerValue = StopWatchTimer.getDisplayTime(
    200,
    hours: false,
    minute: false,
    milliSecond: false,
  );
  FlutterFlowTimerController timerController =
      FlutterFlowTimerController(StopWatchTimer(mode: StopWatchMode.countDown));

  // Stores action output result for [Backend Call - Create Document] action in Timer widget.
  NotificationsRecord? notification;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    timerController.dispose();
  }
}
