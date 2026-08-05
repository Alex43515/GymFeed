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

import 'package:share_plus/share_plus.dart';
import 'dart:io';

Future<void> sharePost(
    String postId, String postTitle, String imagePath) async {
  // Construct the deep link URL for the specific post
  final String deepLinkUrl = 'https://yourdomain.com/posts/$postId';

  // Prepare the content to share
  final String content = '$postTitle\nCheck out this post: $deepLinkUrl';

  // Check if the image file exists
  final File imageFile = File(imagePath);
  if (await imageFile.exists()) {
    final XFile xFile = XFile(imagePath);
    await Share.shareXFiles([xFile], text: content);
  } else {
    await Share.share(content);
  }
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
