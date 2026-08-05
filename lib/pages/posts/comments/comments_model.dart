import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'comments_widget.dart' show CommentsWidget;
import 'package:flutter/material.dart';

class CommentsModel extends FlutterFlowModel<CommentsWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Create Document] action in Icon widget.
  NotificationsRecord? notification;
  // State field(s) for Comment widget.
  FocusNode? commentFocusNode;
  TextEditingController? commentTextController;
  String? Function(BuildContext, String?)? commentTextControllerValidator;
  // Stores action output result for [Backend Call - Create Document] action in Text widget.
  CommentsRecord? comment;
  // Stores action output result for [Backend Call - Create Document] action in Text widget.
  NotificationsRecord? notification1;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    commentFocusNode?.dispose();
    commentTextController?.dispose();
  }
}
