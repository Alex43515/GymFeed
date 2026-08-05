import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'saved_posts_widget.dart' show SavedPostsWidget;
import 'package:flutter/material.dart';

class SavedPostsModel extends FlutterFlowModel<SavedPostsWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tabBarController?.dispose();
  }
}
