import '/flutter_flow/flutter_flow_util.dart';
import 'video_compress_copy_widget.dart' show VideoCompressCopyWidget;
import 'package:flutter/material.dart';

class VideoCompressCopyModel extends FlutterFlowModel<VideoCompressCopyWidget> {
  ///  Local state fields for this page.

  FFUploadedFile? compressedVideoFile;

  String? compressedVidoe;

  ///  State fields for stateful widgets in this page.

  bool isDataUploading = false;
  FFUploadedFile uploadedLocalFile =
      FFUploadedFile(bytes: Uint8List.fromList([]));
  String uploadedFileUrl = '';

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
