import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_timer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'new_follower_notification_widget.dart'
    show NewFollowerNotificationWidget;
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:flutter/material.dart';

class NewFollowerNotificationModel
    extends FlutterFlowModel<NewFollowerNotificationWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Timer widget.
  final timerInitialTimeMs = 200;
  int timerMilliseconds = 200;
  String timerValue = StopWatchTimer.getDisplayTime(200, milliSecond: false);
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
