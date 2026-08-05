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

import 'package:url_launcher/url_launcher.dart';

Future<void> shareViaWhatsApp(String message) async {
  final whatsappUrl = 'whatsapp://send?text=${Uri.encodeComponent(message)}';

  if (await canLaunch(whatsappUrl)) {
    await launch(whatsappUrl);
  } else {
    // WhatsApp is not installed; handle accordingly
    // You can show an alert or snackbar here
    throw 'Could not launch WhatsApp';
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
