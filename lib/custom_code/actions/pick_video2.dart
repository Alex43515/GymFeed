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

import 'package:image_picker/image_picker.dart';

Future<String?> pickVideo2() async {
  final ImagePicker _picker = ImagePicker();

  // First, try picking from the gallery
  XFile? video = await _picker.pickVideo(source: ImageSource.gallery);

  if (video == null) {
    // If the user didn't pick a video, try using the camera
    video = await _picker.pickVideo(source: ImageSource.camera);
  }

  return video?.path;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
