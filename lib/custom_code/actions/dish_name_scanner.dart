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

Future<String> dishNameScanner(String? geminiParse) async {
  // Use regex to extract the value after "DishName:"
  final dishNameMatch =
      RegExp(r'Name of the dish:\s*(.*)').firstMatch(geminiParse ?? '');

  if (dishNameMatch != null) {
    // Return the matched name, trimming any extra whitespace
    return dishNameMatch.group(1)!.trim();
  }

  // If no name was found, return a short guess
  return "Unknown";
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
