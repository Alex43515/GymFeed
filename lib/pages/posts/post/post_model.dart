import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'post_widget.dart' show PostWidget;
import 'package:flutter/material.dart';

class PostModel extends FlutterFlowModel<PostWidget> {
  ///  Local state fields for this component.

  String? linkGenerator;

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - Create Document] action in Container widget.
  NotificationsRecord? notification;
  // Stores action output result for [Backend Call - Create Document] action in ToggleIcon widget.
  NotificationsRecord? notification1Copy;
  String currentPageLink = '';

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
