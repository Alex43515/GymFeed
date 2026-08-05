import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'gpt_vision_widget.dart' show GptVisionWidget;
import 'package:flutter/material.dart';

class GptVisionModel extends FlutterFlowModel<GptVisionWidget> {
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
  // State field(s) for TextField2 widget.
  FocusNode? textField2FocusNode;
  TextEditingController? textField2TextController;
  String? Function(BuildContext, String?)? textField2TextControllerValidator;
  // Stores action output result for [Backend Call - API (createChatCompletion)] action in Button widget.
  ApiCallResponse? openaiRes;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    alwayspopulatedFocusNode?.dispose();
    alwayspopulatedTextController?.dispose();

    textField2FocusNode?.dispose();
    textField2TextController?.dispose();
  }
}
