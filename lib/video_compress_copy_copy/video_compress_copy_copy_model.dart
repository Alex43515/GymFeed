import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'video_compress_copy_copy_widget.dart' show VideoCompressCopyCopyWidget;
import 'package:flutter/material.dart';

class VideoCompressCopyCopyModel
    extends FlutterFlowModel<VideoCompressCopyCopyWidget> {
  ///  Local state fields for this page.

  FFUploadedFile? compressedVideoFile;

  String? compressedVidoe;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - pickVideo] action in Button widget.
  String? pickVideo;
  // Stores action output result for [Custom Action - compressVideoWithProgress] action in Button widget.
  FFUploadedFile? compressVideo;
  bool isDataUploading = false;
  FFUploadedFile uploadedLocalFile =
      FFUploadedFile(bytes: Uint8List.fromList([]));
  String uploadedFileUrl = '';

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
