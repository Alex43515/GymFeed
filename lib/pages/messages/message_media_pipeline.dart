import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';
import 'package:flutter/foundation.dart';

typedef MessageVideoCompressor = Future<FFUploadedFile?> Function(
    String filePath);

/// Compresses a selected chat video before it can enter the upload pipeline.
///
/// Keeping this as a mandatory, testable boundary prevents a future messaging
/// UI change from accidentally uploading the original gallery file. The shared
/// compressor enforces the same one-minute and ten-megabyte limits used by the
/// app's post, story, food-post, and training upload flows.
Future<FFUploadedFile> compressSelectedMessageVideo(
  SelectedFile selected, {
  MessageVideoCompressor? compressor,
}) async {
  if (kIsWeb) {
    if (selected.bytes.isEmpty) {
      throw StateError('The selected browser video is empty.');
    }
    return FFUploadedFile(
      name: selected.storagePath.split('/').last,
      bytes: selected.bytes,
    );
  }
  final path = selected.filePath;
  if (path == null || path.trim().isEmpty) {
    throw StateError('Video compression requires a local video file.');
  }
  final result = await (compressor ?? actions.compressVideo)(path);
  if (result?.bytes == null || result!.bytes!.isEmpty) {
    throw StateError('Video compression did not produce a playable file.');
  }
  return result;
}
