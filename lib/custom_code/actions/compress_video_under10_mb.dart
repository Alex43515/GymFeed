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
import 'package:video_compress/video_compress.dart';

Future<FFUploadedFile?> compressVideoUnder10Mb(
    FFUploadedFile uploadedFile) async {
  try {
    // Ensure the uploadedFile has bytes
    if (uploadedFile.bytes == null || uploadedFile.bytes!.isEmpty) {
      throw Exception('No valid bytes found in FFUploadedFile.');
    }

    // Write the bytes to a temporary file
    final tempDir = Directory.systemTemp;
    final tempFile =
        await File('${tempDir.path}/${uploadedFile.name}').create();
    await tempFile.writeAsBytes(uploadedFile.bytes!);

    // Get video info
    final info = await VideoCompress.getMediaInfo(tempFile.path);
    final duration = info.duration;
    if (duration == null) {
      throw Exception('Unable to read video duration.');
    }

    // Check if > 60s
    final durationInSeconds = (duration / 1000).floor();
    if (durationInSeconds > 60) {
      throw Exception('Video is too long (> 60 seconds).');
    }

    // Define max size (10 MB)
    final maxBytes = 10 * 1024 * 1024;
    final originalSize = info.filesize ?? tempFile.lengthSync();
    if (originalSize <= maxBytes) {
      // No compression needed
      return uploadedFile;
    }

    // Try MediumQuality compression
    final compressedMedium = await VideoCompress.compressVideo(
      tempFile.path,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
    );
    if (compressedMedium == null || compressedMedium.path == null) {
      throw Exception('MediumQuality compression failed.');
    }
    final mediumFile = File(compressedMedium.path!);
    final mediumSize = mediumFile.lengthSync();
    if (mediumSize <= maxBytes) {
      // Convert compressed file to bytes
      final mediumBytes = await mediumFile.readAsBytes();
      return FFUploadedFile(
        name: uploadedFile.name ?? 'compressed_medium.mp4',
        bytes: mediumBytes,
      );
    }

    // If still too large, try LowQuality compression
    final compressedLow = await VideoCompress.compressVideo(
      tempFile.path,
      quality: VideoQuality.LowQuality,
      deleteOrigin: false,
    );
    if (compressedLow == null || compressedLow.path == null) {
      throw Exception('LowQuality compression failed.');
    }
    final lowFile = File(compressedLow.path!);
    final lowSize = lowFile.lengthSync();
    if (lowSize <= maxBytes) {
      // Convert compressed file to bytes
      final lowBytes = await lowFile.readAsBytes();
      return FFUploadedFile(
        name: uploadedFile.name ?? 'compressed_low.mp4',
        bytes: lowBytes,
      );
    }

    // If still > 10 MB, throw an exception
    throw Exception('Cannot compress below 10 MB with available presets.');
  } catch (e) {
    print('Error compressing: $e');
    rethrow;
  }
}
