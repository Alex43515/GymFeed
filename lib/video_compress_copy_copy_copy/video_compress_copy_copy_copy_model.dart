import '/flutter_flow/flutter_flow_util.dart';
import 'video_compress_copy_copy_copy_widget.dart'
    show VideoCompressCopyCopyCopyWidget;
import 'package:flutter/material.dart';

class VideoCompressCopyCopyCopyModel
    extends FlutterFlowModel<VideoCompressCopyCopyCopyWidget> {
  ///  Local state fields for this page.

  FFUploadedFile? compressedVideoFile;

  String? compressedVidoe;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - pickVideo] action in Button widget.
  String? pickVideo;
  // Stores action output result for [Custom Action - compressVideo2] action in Button widget.
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
