import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/backend.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/schema/structs/index.dart';
import '/auth/firebase_auth/auth_util.dart';

DocumentReference returnUserFromLikes(List<DocumentReference> userLikes) {
  // Return an item from the list
  DocumentReference likedUser = userLikes[
      0]; // Put your method here and link with tag on run method in main.dart
  return likedUser;
}

String bunnyCDNVideoPath(String videoPathSource) {
// Check if imagePathSource is null or empty
  if (videoPathSource == null || videoPathSource.isEmpty) {
    return '';
  }

  // Define the Firebase Storage base URL
  const firebaseBaseUrl =
      'https://firebasestorage.googleapis.com/v0/b/gym-feed-official-27tdk3.appspot.com/o/';

  // Define the BunnyCDN base URL
  const bunnyCdnBaseUrl = 'https://gymfeed.b-cdn.net/';

  // Replace the Firebase URL with the BunnyCDN URL
  var newPath = videoPathSource.replaceFirst(firebaseBaseUrl, bunnyCdnBaseUrl);

  return newPath;
}

DateTime tomorrowTime(DateTime currentTime) {
  // Return the timestamp in the future 24 hours.
  var tomorrow = DateTime.now().add(Duration(days: 1));
  return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, currentTime.hour,
      currentTime.minute, 0);
}

int totalLikes(int numberoflikes) {
  // return the numberoflikes minus 1
  return numberoflikes - 1;
}

String listToString(List<String>? list) {
  // take list and convert to string with a ", " between each item
  String res = '';
  if (list != null) {
    for (String item in list) {
      res += ('${item.toString()}, ');
    }
  }
  return res;
}

List<DocumentReference>? reverseList(
    List<DocumentReference>? notificationsList) {
  // reverse the list
  if (notificationsList != null && notificationsList.length > 1) {
    if (notificationsList[0] == notificationsList.last)
      return notificationsList;

    // reverse and return
    return notificationsList.reversed.toList();
  } else
    return notificationsList;
}

DateTime returnThisMorning(DateTime currentTime) {
  // Return the start of today
  DateTime now = currentTime;
  DateTime _thisMorning = DateTime(now.year, now.month, now.day);
  return _thisMorning;
}

DateTime returnThisWeek(DateTime currentTime) {
  // Return the date 1 week ago
  return currentTime.subtract(Duration(days: 7));
}

DateTime returnThisMonth(DateTime currentTime) {
  // Return the date 1 week ago
  return DateTime(currentTime.year, currentTime.month - 1, currentTime.day);
}

String returnAllCaps(String username) {
  // Return string in all caps
  return username.toLowerCase();
}

DateTimeRange returnNext24Hours(DateTime currentTime) {
  // Create a range of time from now until 24 hours from now.
  Duration fromNowAcceptable = Duration(hours: 24);
  DateTime tomorrow = DateTime(
    currentTime.year,
    currentTime.month,
    currentTime.day,
    currentTime.hour,
    currentTime.minute,
  ).add(fromNowAcceptable);
  DateTimeRange dateTimeRangeFromNow =
      DateTimeRange(start: currentTime, end: tomorrow);
  return dateTimeRangeFromNow;
}

bool? usernameChecker(
  String textfield,
  List<String> usernames,
) {
  return !usernames.contains(textfield);
}

String? usernameCreator(String username) {
  return username.replaceAll(' ', '').toLowerCase();
}

String? generateChatGPT(
  int age,
  int height,
  int weight,
  String days,
  int snacks,
  bool gender,
  String goals,
  DateTime age2,
  String meals,
  String workouts,
  String workoutLength,
  String workoutPeriod,
  String workoutLevel,
  String gender2,
  String workoutWhere,
  String foodAlergies,
) {
  String genderText =
      gender ? 'male' : 'female'; // Assuming 'true' represents 'male'

  // Format the age properly, assuming age2 is the birthdate
  int currentYear = DateTime.now().year;
  int birthYear = age2.year;
  int calculatedAge = currentYear - birthYear;

  // Construct the prompt
  String prompt =
      "You are a highly renowned health and nutrition expert at FitnessGPT. "
      "Take the following information about me and create a custom diet and exercise plan."
      "I am ${calculatedAge} years old, ${gender2}, ${height} tall. My current weight is ${weight}. "
      "My primary fitness and health goals are ${goals}. "
      "I can commit to working out ${workouts} per week to work out ${workoutPeriod} per week. I usually workout ${workoutWhere}."
      "Create a detailed daily workout program for my ${workoutLength} exercise plan, include rest periods."
      "I want to have ${meals} meals, and this is the food I am alergic to ${foodAlergies}. "
      "Create a summary of my diet and exercise plan. Create a detailed workout program for my exercise plan. Create a detailed Meal Plan for my diet. Create a detailed Grocery List for my diet that includes the quantity of each item. Avoid any superfluous pre- and post-descriptive text. Don't break character under any circumstance. Include a list of 2 motivational quotes that will keep me inspired towards my goals.";

  return prompt;
}

int resizeFontBasedOnScreenSize(
  double screenWidth,
  int? initialFontSize,
) {
  // I want to resize font size based on screen width breakpoints, where each time a breaktpoint is reached the font size increments by 10
  int fontSize = initialFontSize ?? 20;
  int breakpoint = 768;
  if (screenWidth >= breakpoint) {
    fontSize += 10;
  }
  return fontSize;
}

String twicPicImagePath(
  String imagePathSource,
  String params,
) {
  ///Check if imagePatchSource is null or empty

  if (imagePathSource == null || imagePathSource.isEmpty) {
    return '';
  }

  /// Replace firebase URL with twicPic URL

  var newPath = imagePathSource.replaceFirst(
      'https://firebasestorage.googleapis.com/v0/b/gym-feed-official-27tdk3.appspot.com/o/',
      'https://gymfeed.twic.pics/');

  /// Check if params is null

  if (params == null) {
    params = '';
  }

  return newPath + params;
}

String twicPicVideoPath(
  String videoPathSource,
  String params,
) {
  ///Check if imagePatchSource is null or empty

  if (videoPathSource == null || videoPathSource.isEmpty) {
    return '';
  }

  /// Replace firebase URL with twicPic URL

  var newPath = videoPathSource.replaceFirst(
      'https://firebasestorage.googleapis.com/v0/b/gym-feed-official-27tdk3.appspot.com/o/',
      'https://gymfeed.twic.pics/video/');

  /// Check if params is null

  if (params == null) {
    params = '';
  }

  return '$newPath?alt=media';
}

String formatedText(String newText) {
// Replace newline characters with the literal \n
  String formatedText = newText.replaceAll('\n', '\\n');

  // Escape double quotes
  formatedText = formatedText.replaceAll('"', '\\"');

  // Return the prepared JSON string
  return '{"plan": "$formatedText"}';
}

String formattedText(String newText) {
  // Create a map representing the JSON object
  Map<String, String> jsonMap = {'plan': newText};

  // Use jsonEncode to ensure proper JSON encoding
  String formattedJson = jsonEncode(jsonMap);

  // Return the formatted JSON string
  return formattedJson;
}

String escapeString(String newText) {
  // Replace newline characters with escape sequences
  String escapeString = newText.replaceAll('\n', '\\n');

  // Escape double quotes
  escapeString = escapeString.replaceAll('"', '\\"');

  // Return the formatted text
  return escapeString;
}

double? sumCalories(List<int> caloriesList) {
  double totalCalories = 0;
  for (int calories in caloriesList) {
    totalCalories += calories;
  }
  return totalCalories;
}

int calculateTotalCalories(List<int> caloriesList) {
  int totalCalories = 0;
  for (int calories in caloriesList) {
    totalCalories += calories;
  }
  return totalCalories;
}

String? extractPathFromUrl(String url) {
  final String baseUrl =
      'https://firebasestorage.googleapis.com/v0/b/gym-feed-official-27tdk3.appspot.com/o/';

  final pattern = RegExp(r'^https?://[^\s/$.?#].[^\s]*$');

  final match = pattern.firstMatch(url);

  if (match != null && match.group(0) == url) {
    final extractedPath = url.substring(baseUrl.length);

    return extractedPath;
  }
  return null;
}

String bunnyCDNImagePath(String imagePathSource) {
// Check if imagePathSource is null or empty
  if (imagePathSource == null || imagePathSource.isEmpty) {
    return '';
  }

  // Define the Firebase Storage base URL
  const firebaseBaseUrl =
      'https://firebasestorage.googleapis.com/v0/b/gym-feed-official-27tdk3.appspot.com/o/';

  // Define the BunnyCDN base URL
  const bunnyCdnBaseUrl = 'https://gymfeed.b-cdn.net/';

  // Replace the Firebase URL with the BunnyCDN URL
  var newPath = imagePathSource.replaceFirst(firebaseBaseUrl, bunnyCdnBaseUrl);

  return newPath;
}
