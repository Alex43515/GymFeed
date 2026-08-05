import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'post_food_widget.dart' show PostFoodWidget;
import 'package:flutter/material.dart';

class PostFoodModel extends FlutterFlowModel<PostFoodWidget> {
  ///  Local state fields for this component.

  String? linkGenerator;

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - Create Document] action in Container widget.
  NotificationsRecord? notificationCopy;
  // Stores action output result for [Backend Call - Create Document] action in ToggleIcon widget.
  NotificationsRecord? notification1Copy;
  String currentPageLink = '';

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
