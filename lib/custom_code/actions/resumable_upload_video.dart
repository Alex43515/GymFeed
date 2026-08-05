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
import 'package:firebase_storage/firebase_storage.dart';

Future<String> resumableUploadVideo(String filePath, String storagePath) async {
  File file = File(filePath);
  FirebaseStorage storage = FirebaseStorage.instance;
  Reference ref = storage.ref().child(storagePath);

  UploadTask uploadTask =
      ref.putFile(file, SettableMetadata(contentType: 'video/mp4'));

  // Await completion
  TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);

  // Get the download URL
  String downloadURL = await taskSnapshot.ref.getDownloadURL();
  return downloadURL;
}

UploadTask uploadTask2(UploadTask uploadTask) => uploadTask;

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
