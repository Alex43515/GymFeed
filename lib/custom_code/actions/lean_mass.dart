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

Future<String?> leanMass(String? geminiParse) async {
  // Use regex to extract the value for Leanmass
  final leanMassMatch = RegExp(r'Leanmass:\s*(\d+)').firstMatch(geminiParse!);
  // Return only the number or "0" if not found
  return leanMassMatch != null ? leanMassMatch.group(1)! : "0";
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
