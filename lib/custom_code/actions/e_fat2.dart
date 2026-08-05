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

Future<double> eFat2(String? geminiParse) async {
  final eFatMatch =
      RegExp(r'E\.fat:\s*(\d+(?:\.\d+)?)').firstMatch(geminiParse ?? '');
  if (eFatMatch != null) {
    double value = double.parse(eFatMatch.group(1)!);
    double fraction = value / 100.0;
    // Clamp fraction to [0, 1]
    if (fraction < 0.0) fraction = 0.0;
    if (fraction > 1.0) fraction = 1.0;
    return fraction;
  }
  return 0.0;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
