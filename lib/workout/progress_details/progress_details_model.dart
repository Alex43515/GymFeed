import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'progress_details_widget.dart' show ProgressDetailsWidget;
import 'package:flutter/material.dart';

class ProgressDetailsModel extends FlutterFlowModel<ProgressDetailsWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for Checkbox widget.
  Map<ExerciseRecord, bool> checkboxValueMap = {};
  List<ExerciseRecord> get checkboxCheckedItems =>
      checkboxValueMap.entries.where((e) => e.value).map((e) => e.key).toList();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
