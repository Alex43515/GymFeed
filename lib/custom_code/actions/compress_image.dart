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
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

Future<FFUploadedFile?> compressImage(String filePath) async {
  try {
    // Retrieve the original file
    final originalFile = File(filePath);

    // Ensure the file exists
    if (!await originalFile.exists()) {
      throw Exception('File does not exist.');
    }

    // Get the temporary directory
    final tempDir = await getTemporaryDirectory();

    // Define the target path for the compressed image
    final targetPath =
        '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Compress the image
    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      originalFile.absolute.path,
      targetPath,
      quality: 85, // Adjust quality as needed
    );

    if (compressedFile == null) {
      throw Exception('Image compression failed.');
    }

    // Read the compressed file as bytes
    final compressedBytes = await compressedFile.readAsBytes();

    // Return the compressed image as FFUploadedFile
    return FFUploadedFile(
      name: originalFile.uri.pathSegments.last, // Extracts the file name
      bytes: compressedBytes,
    );
  } catch (e) {
    print('Error compressing image: $e');
    return null;
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
