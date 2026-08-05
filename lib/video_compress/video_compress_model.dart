import '/flutter_flow/flutter_flow_util.dart';
import 'video_compress_widget.dart' show VideoCompressWidget;
import 'package:flutter/material.dart';

class VideoCompressModel extends FlutterFlowModel<VideoCompressWidget> {
  ///  Local state fields for this page.

  FFUploadedFile? localcompress;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - pickImage] action in Button widget.
  String? pickedImage;
  // Stores action output result for [Custom Action - compressImage] action in Button widget.
  FFUploadedFile? imagecompress;
  bool isDataUploading = false;
  FFUploadedFile uploadedLocalFile =
      FFUploadedFile(bytes: Uint8List.fromList([]));
  String uploadedFileUrl = '';

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
