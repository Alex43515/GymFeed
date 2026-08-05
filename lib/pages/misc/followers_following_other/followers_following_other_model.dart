import '/flutter_flow/flutter_flow_util.dart';
import 'followers_following_other_widget.dart'
    show FollowersFollowingOtherWidget;
import 'package:flutter/material.dart';

class FollowersFollowingOtherModel
    extends FlutterFlowModel<FollowersFollowingOtherWidget> {
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
