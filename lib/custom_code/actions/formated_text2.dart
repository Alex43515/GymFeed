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

String formatedText2(String newText) {
  /// MODIFY CODE ONLY BELOW THIS LINE

// Replace newline characters with the literal \n
  String formatedText2 = newText.replaceAll('\n', '\\n');

  // Escape double quotes
  formatedText2 = formatedText2.replaceAll('"', '\\"');

  // Return the prepared JSON string
  return '{"plan": "$formatedText2"}';

  /// MODIFY CODE ONLY ABOVE THIS LINE
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
