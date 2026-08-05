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

Future<void> shareViaFacebookMessenger(String link) async {
  final messengerUrlScheme =
      'fb-messenger://share?link=${Uri.encodeComponent(link)}';
  final fallbackUrl = 'https://www.facebook.com/dialog/send'
      '?app_id=YOUR_FACEBOOK_APP_ID'
      '&link=${Uri.encodeComponent(link)}'
      '&redirect_uri=${Uri.encodeComponent('https://www.facebook.com')}';

  if (await canLaunch(messengerUrlScheme)) {
    await launch(messengerUrlScheme);
  } else if (await canLaunch(fallbackUrl)) {
    await launch(fallbackUrl);
  } else {
    // Messenger is not installed; handle accordingly
    throw 'Could not launch Facebook Messenger';
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
