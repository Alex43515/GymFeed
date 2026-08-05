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

Future<String?> parser(String? geminiParse) async {
  // Use regex patterns to extract the values
  final eFatMatch = RegExp(r'E\.fat:\s*(\d+)').firstMatch(geminiParse!);
  final bFatMatch = RegExp(r'B\.fat:\s*(\d+)').firstMatch(geminiParse!);
  final uFatMatch = RegExp(r'U\.fat:\s*(\d+)').firstMatch(geminiParse!);
  final leanMassMatch = RegExp(r'Leanmass:\s*(\d+)').firstMatch(geminiParse!);

  // Extract the numbers or set defaults if not found
  final eFat = eFatMatch != null ? eFatMatch.group(1)! : "0";
  final bFat = bFatMatch != null ? bFatMatch.group(1)! : "0";
  final uFat = uFatMatch != null ? uFatMatch.group(1)! : "0";
  final leanMass = leanMassMatch != null ? leanMassMatch.group(1)! : "0";

  // Construct and return the formatted string
  return "E.fat: $eFat B.fat: $bFat U.fat: $uFat Leanmass: $leanMass";
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
