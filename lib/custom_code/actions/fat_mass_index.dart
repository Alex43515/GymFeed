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

Future<int> fatMassIndex(String? geminiParse) async {
  // Use regex to extract the value for Lean Mass Index
  final fatMassIndexMatch =
      RegExp(r'Fat Mass Index:\s*([\d.]+)').firstMatch(geminiParse!);

  // Convert the extracted value to an integer or return 0 if not found
  if (fatMassIndexMatch != null) {
    final fatMassValue = double.parse(fatMassIndexMatch.group(1)!);
    return fatMassValue.toInt(); // Convert to integer
  }

  return 0; // Default value if no match is found
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
