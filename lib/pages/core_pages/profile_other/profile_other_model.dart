import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_timer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'profile_other_widget.dart' show ProfileOtherWidget;
import 'package:flutter/material.dart';

class ProfileOtherModel extends FlutterFlowModel<ProfileOtherWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Create Document] action in NewChatButton widget.
  ChatsRecord? chat;
  // State field(s) for Timer_FollowButtonActions widget.
  final timerFollowButtonActionsInitialTimeMs = 200;
  int timerFollowButtonActionsMilliseconds = 200;
  String timerFollowButtonActionsValue =
      StopWatchTimer.getDisplayTime(200, milliSecond: false);
  FlutterFlowTimerController timerFollowButtonActionsController =
      FlutterFlowTimerController(StopWatchTimer(mode: StopWatchMode.countDown));

  // Stores action output result for [Backend Call - Create Document] action in Timer_FollowButtonActions widget.
  NotificationsRecord? notification;
  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    timerFollowButtonActionsController.dispose();
    tabBarController?.dispose();
  }
}
