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

Future<String?> caloriesIntake(String? geminiParse) async {
  // Use regex to extract the value for Calories burned at rest
  final caloriesIntakeMatch =
      RegExp(r'Calories Intake:\D*(\d+)').firstMatch(geminiParse!);
  // Return only the number or "0" if not found
  return caloriesIntakeMatch != null ? caloriesIntakeMatch.group(1)! : "0";
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
