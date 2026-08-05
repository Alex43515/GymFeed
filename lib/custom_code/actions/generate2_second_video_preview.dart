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

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:image/image.dart' as img;

/// Grabs 10 frames over the first 2s of [videoFile] and encodes them into a looping GIF.
Future<FFUploadedFile?> generate2SecondVideoPreview(
    FFUploadedFile videoFile) async {
  try {
    // 1) Write the uploaded video bytes to a temp file
    final tempDir = await getTemporaryDirectory();
    final originalName = videoFile.name ?? 'video';
    final videoPath = '${tempDir.path}/$originalName';
    final videoBytes = videoFile.bytes;
    if (videoBytes == null) {
      print('❌ No data in uploaded file.');
      return null;
    }
    await File(videoPath).writeAsBytes(videoBytes);

    // 2) Extract frames using video_thumbnail
    const int frameCount = 10;
    const int totalMs = 2000; // duration in ms
    final List<img.Image> frames = [];

    for (int i = 0; i < frameCount; i++) {
      final int timeMs = (i * (totalMs / (frameCount - 1))).round();
      final Uint8List? thumbData = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.PNG,
        maxWidth: 480, // scale to 480px width
        timeMs: timeMs,
        quality: 90,
      );
      if (thumbData != null) {
        final decoded = img.decodeImage(thumbData);
        if (decoded != null) frames.add(decoded);
      }
    }

    if (frames.isEmpty) {
      print('❌ No frames extracted.');
      return null;
    }

    // 3) Encode as animated GIF
    final encoder = img.GifEncoder(
      delay: (totalMs ~/ frameCount) ~/ 10, // in 1/100 s units
      repeat: 0, // loop indefinitely
      numColors: 128, // palette size
    );
    for (final frame in frames) {
      encoder.addFrame(frame);
    }
    final Uint8List? gifData = encoder.finish();
    if (gifData == null) {
      print('❌ GIF encoding failed.');
      return null;
    }

    // 4) Save GIF and wrap in FFUploadedFile
    final base = originalName.contains('.')
        ? originalName.split('.').first
        : originalName;
    final gifName = 'preview_${base}.gif';
    final gifPath = '${tempDir.path}/$gifName';
    await File(gifPath).writeAsBytes(gifData);

    return FFUploadedFile(
      name: gifName,
      bytes: gifData,
    );
  } catch (e) {
    print('🔥 Exception generating GIF preview: $e');
    return null;
  }
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
