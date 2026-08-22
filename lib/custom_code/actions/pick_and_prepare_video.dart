// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart';
import '/flutter_flow/custom_functions.dart';
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Picks a video and returns bytes that can be sent to the shared Bunny
/// upload pipeline.
///
/// Native builds retain the existing duration check/compression. Flutter Web
/// cannot use `video_compress` (its picker path is a browser blob URL), so the
/// browser reads the selected XFile bytes directly instead of trying to open
/// the blob through `dart:io`.
Future<FFUploadedFile?> pickAndPrepareVideo() async {
  final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
  if (picked == null) return null;

  if (!kIsWeb) return compressVideo(picked.path);

  final bytes = await picked.readAsBytes();
  if (bytes.isEmpty) {
    throw StateError('The selected video is empty.');
  }

  return FFUploadedFile(
    name: picked.name.isEmpty ? 'gymfeed-video.mp4' : picked.name,
    bytes: bytes,
  );
}
