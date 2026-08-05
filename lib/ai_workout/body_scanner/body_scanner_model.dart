import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'body_scanner_widget.dart' show BodyScannerWidget;
import 'package:flutter/material.dart';

class BodyScannerModel extends FlutterFlowModel<BodyScannerWidget> {
  ///  Local state fields for this page.

  String query = 'no string';

  String imageUrl = 'false';

  DateTime? date;

  ///  State fields for stateful widgets in this page.

  bool isDataUploading = false;
  FFUploadedFile uploadedLocalFile =
      FFUploadedFile(bytes: Uint8List.fromList([]));
  String uploadedFileUrl = '';

  // State field(s) for alwayspopulated widget.
  FocusNode? alwayspopulatedFocusNode;
  TextEditingController? alwayspopulatedTextController;
  String? Function(BuildContext, String?)?
      alwayspopulatedTextControllerValidator;
  // Stores action output result for [Backend Call - API (createChatCompletion)] action in Button widget.
  ApiCallResponse? openaiRes;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    alwayspopulatedFocusNode?.dispose();
    alwayspopulatedTextController?.dispose();
  }
}
