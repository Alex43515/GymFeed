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
import 'dart:io'; // For File operations

Future<FFUploadedFile?> compressVideo2(String filePath) async {
  var subscription;
  try {
    // Initialize the progress to 0
    FFAppState().uploadProgress = 0.0;

    // Get video info
    final MediaInfo info = await VideoCompress.getMediaInfo(filePath);
    final duration = info.duration;

    if (duration == null) {
      throw Exception('Unable to read video duration.');
    }

    // Check if video is longer than 60 seconds
    final durationInSeconds = (duration / 1000).floor();
    if (durationInSeconds > 60) {
      throw Exception('Video is too long (> 60 seconds).');
    }

    // Define max size (5 MB)
    final maxBytes = 5 * 1024 * 1024; // 5 MB in bytes

    // Subscribe to the compression progress stream
    subscription = VideoCompress.compressProgress$.subscribe((progress) {
      // Update the App State variable with the current progress
      FFAppState().uploadProgress = progress / 100.0;
    });

    // Start the compression with 480p resolution
    MediaInfo? compressedVideo = await VideoCompress.compressVideo(
      filePath,
      quality: VideoQuality.Res640x480Quality, // Lower resolution to 480p
      deleteOrigin: false,
      includeAudio: true,
    );

    // If the compressed video is still larger than 5 MB, try with the lowest quality
    if (compressedVideo != null && compressedVideo.path != null) {
      final File compressedFile = File(compressedVideo.path!);
      final int compressedSize = compressedFile.lengthSync();

      if (compressedSize > maxBytes) {
        // Try compressing with LowQuality setting
        compressedVideo = await VideoCompress.compressVideo(
          filePath,
          quality: VideoQuality.LowQuality,
          deleteOrigin: false,
          includeAudio: true,
        );
      }
    }

    // Unsubscribe from the progress stream
    subscription?.unsubscribe();
    VideoCompress.dispose();

    if (compressedVideo == null || compressedVideo.path == null) {
      throw Exception('Video compression failed.');
    }

    final File finalCompressedFile = File(compressedVideo.path!);
    final int finalCompressedSize = finalCompressedFile.lengthSync();

    if (finalCompressedSize > maxBytes) {
      throw Exception('Cannot compress below 5 MB with available presets.');
    }

    // Read the compressed file bytes
    final Uint8List compressedBytes = await finalCompressedFile.readAsBytes();

    // Reset progress to 1 (100%)
    FFAppState().uploadProgress = 1.0;

    return FFUploadedFile(
      name: finalCompressedFile.uri.pathSegments.last,
      bytes: compressedBytes,
    );
  } catch (e) {
    print('Error compressing video: $e');
    rethrow;
  }
}
