import '/flutter_flow/flutter_flow_util.dart';
import 'story_upload_widget.dart' show StoryUploadWidget;
import 'package:flutter/material.dart';

class StoryUploadModel extends FlutterFlowModel<StoryUploadWidget> {
  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Custom Action - pickImage] action in Button widget.
  String? pickImage;
  // Stores action output result for [Custom Action - compressImage] action in Button widget.
  FFUploadedFile? compresssImage;
  bool isDataUploading1 = false;
  FFUploadedFile uploadedLocalFile1 =
      FFUploadedFile(bytes: Uint8List.fromList([]));
  String uploadedFileUrl1 = '';

  // Stores action output result for [Custom Action - pickVideo] action in Button widget.
  String? pickVideo;
  // Stores action output result for [Custom Action - compressVideo] action in Button widget.
  FFUploadedFile? compressVideo;
  bool isDataUploading2 = false;
  FFUploadedFile uploadedLocalFile2 =
      FFUploadedFile(bytes: Uint8List.fromList([]));
  String uploadedFileUrl2 = '';

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
