import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_timer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:async';
import '/index.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'search_widget.dart' show SearchWidget;
import 'package:flutter/material.dart';

class SearchModel extends FlutterFlowModel<SearchWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for SearchField widget.
  FocusNode? searchFieldFocusNode;
  TextEditingController? searchFieldTextController;
  String? Function(BuildContext, String?)? searchFieldTextControllerValidator;
  List<UsersRecord> simpleSearchResults1 = [];
  // State field(s) for Timer_SearchFieldActions widget.
  final timerSearchFieldActionsInitialTimeMs = 200;
  int timerSearchFieldActionsMilliseconds = 200;
  String timerSearchFieldActionsValue = StopWatchTimer.getDisplayTime(
    200,
    hours: false,
    minute: false,
    milliSecond: false,
  );
  FlutterFlowTimerController timerSearchFieldActionsController =
      FlutterFlowTimerController(StopWatchTimer(mode: StopWatchMode.countDown));

  List<PostsRecord> simpleSearchResults2 = [];
  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;

  Completer<List<PostsRecord>>? firestoreRequestCompleter;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    searchFieldFocusNode?.dispose();
    searchFieldTextController?.dispose();

    timerSearchFieldActionsController.dispose();
    tabBarController?.dispose();
  }

  /// Additional helper methods.
  Future waitForFirestoreRequestCompleted({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = firestoreRequestCompleter?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
