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

// Extract the value for Calories Burned at Rest
Future<String?> proTips(String? geminiParse) async {
  // Use regex to extract the value for Calories burned at rest
  final proTipsMatch = RegExp(
          r'Pro Tips.*?:\s*(.+?)(?=Calories Intake|Meal Plan|Workout Plan|Pro Tips|Motivational Quotes)')
      .firstMatch(geminiParse!);
  // Return only the number or "0" if not found
  return proTipsMatch != null ? proTipsMatch.group(1)! : "0";
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
