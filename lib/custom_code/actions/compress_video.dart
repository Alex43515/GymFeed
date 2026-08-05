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

Future<FFUploadedFile?> compressVideo(String filePath) async {
  try {
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

    // Define max size (10 MB)
    final maxBytes = 10 * 1024 * 1024;
    final originalSize = info.filesize ?? File(filePath).lengthSync();
    if (originalSize <= maxBytes) {
      // No compression needed, read file bytes
      final Uint8List originalBytes = await File(filePath).readAsBytes();
      return FFUploadedFile(
        name: File(filePath).uri.pathSegments.last,
        bytes: originalBytes,
      );
    }

    // Try MediumQuality compression
    final MediaInfo? compressedMedium = await VideoCompress.compressVideo(
      filePath,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
    );
    if (compressedMedium == null || compressedMedium.path == null) {
      throw Exception('MediumQuality compression failed.');
    }
    final File mediumFile = File(compressedMedium.path!);
    final int mediumSize = mediumFile.lengthSync();
    if (mediumSize <= maxBytes) {
      // Convert compressed file to bytes
      final Uint8List mediumBytes = await mediumFile.readAsBytes();
      return FFUploadedFile(
        name: mediumFile.uri.pathSegments.last,
        bytes: mediumBytes,
      );
    }

    // If still too large, try LowQuality compression
    final MediaInfo? compressedLow = await VideoCompress.compressVideo(
      filePath,
      quality: VideoQuality.LowQuality,
      deleteOrigin: false,
    );
    if (compressedLow == null || compressedLow.path == null) {
      throw Exception('LowQuality compression failed.');
    }
    final File lowFile = File(compressedLow.path!);
    final int lowSize = lowFile.lengthSync();
    if (lowSize <= maxBytes) {
      // Convert compressed file to bytes
      final Uint8List lowBytes = await lowFile.readAsBytes();
      return FFUploadedFile(
        name: lowFile.uri.pathSegments.last,
        bytes: lowBytes,
      );
    }

    // If still > 10 MB, throw an exception
    throw Exception('Cannot compress below 10 MB with available presets.');
  } catch (e) {
    print('Error compressing video: $e');
    rethrow;
  }
}
