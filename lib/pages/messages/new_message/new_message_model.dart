import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_timer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'new_message_widget.dart' show NewMessageWidget;
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:flutter/material.dart';

class NewMessageModel extends FlutterFlowModel<NewMessageWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for SearchInnput widget.
  FocusNode? searchInnputFocusNode;
  TextEditingController? searchInnputTextController;
  String? Function(BuildContext, String?)? searchInnputTextControllerValidator;
  List<UsersRecord> simpleSearchResults = [];
  // State field(s) for Timer widget.
  final timerInitialTimeMs = 100;
  int timerMilliseconds = 100;
  String timerValue = StopWatchTimer.getDisplayTime(
    100,
    hours: false,
    minute: false,
    milliSecond: false,
  );
  FlutterFlowTimerController timerController =
      FlutterFlowTimerController(StopWatchTimer(mode: StopWatchMode.countDown));

  // Stores action output result for [Backend Call - Create Document] action in ProfileDetails widget.
  ChatsRecord? chat;
  // Stores action output result for [Backend Call - Create Document] action in ProfileDetails widget.
  ChatsRecord? chat1;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    searchInnputFocusNode?.dispose();
    searchInnputTextController?.dispose();

    timerController.dispose();
  }
}
