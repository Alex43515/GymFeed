// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:video_compress/video_compress.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<FFUploadedFile?> generateVideoThumbnail(FFUploadedFile videoFile) async {
  try {
    // Save FFUploadedFile.bytes to a temporary file
    final tempDir = await getTemporaryDirectory();
    final tempFilePath = '${tempDir.path}/${videoFile.name}';
    final tempFile = File(tempFilePath);
    await tempFile.writeAsBytes(videoFile.bytes!);

    // Generate thumbnail using the temporary file
    final File thumbFile = await VideoCompress.getFileThumbnail(
      tempFile.path,
      quality: 75,
      position: 1000, // 1 second into the video
    );

    final Uint8List thumbBytes = await thumbFile.readAsBytes();

    return FFUploadedFile(
      name: '${videoFile.name?.split('.').first}_thumbnail.jpg',
      bytes: thumbBytes,
    );
  } catch (e) {
    print('Thumbnail generation error: $e');
    return null;
  }
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
