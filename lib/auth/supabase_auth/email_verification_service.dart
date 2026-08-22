import 'package:flutter/foundation.dart';

import '/app_state.dart';
import '/backend/supabase/repositories/profile_repository.dart';
import '/backend/supabase/supabase.dart';
import 'auth_util.dart' show refreshCurrentUserProfile;

const gymFeedWebOrigin = 'https://gymfeed.io';
const gymFeedAuthCallbackPath = '/emailVerification';
const gymFeedNativeAuthScheme = 'com.flutterflow.gymfeedofficial';

/// Supabase requires this exact URL to be present in Auth > URL Configuration.
String emailVerificationRedirectUrl({bool? web}) {
  if (web ?? kIsWeb) {
    return '$gymFeedWebOrigin$gymFeedAuthCallbackPath';
  }
  return '$gymFeedNativeAuthScheme://emailVerification';
}

bool isEmailConfirmationError(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('email not confirmed') ||
      text.contains('email_not_confirmed');
}

String? verificationLinkError(Uri uri) {
  final raw = uri.queryParameters['error_description'] ??
      uri.queryParameters['error'] ??
      uri.queryParameters['error_code'];
  if (raw == null || raw.trim().isEmpty) return null;
  final message = raw.replaceAll('+', ' ').trim();
  if (message.toLowerCase().contains('expired')) {
    return 'This verification link has expired. Request a new email below.';
  }
  return 'This verification link could not be used. $message';
}

/// Identity metadata sent with the initial pending Supabase Auth signup.
/// This is deliberately limited to account identity: the questionnaire starts
/// only after the email-confirmation callback creates a verified session.
Map<String, dynamic> signupIdentityMetadata() {
  final state = FFAppState();
  return <String, dynamic>{
    'gymfeed_onboarding': true,
    'gymfeed_onboarding_stage': 'awaiting_email',
    'full_name': state.signupName.trim(),
    'display_name': state.signupName.trim(),
    'username': state.signupUsername.trim(),
  };
}

/// Everything needed to generate and persist the plans after the verified
/// athlete completes the questionnaire. Passwords and image bytes are never
/// placed in auth metadata.
Map<String, dynamic> signupMetadataFromOnboarding() {
  final state = FFAppState();
  return <String, dynamic>{
    'gymfeed_onboarding': true,
    'gymfeed_onboarding_stage': 'answers_complete',
    'full_name': state.signupName.trim(),
    'display_name': state.signupName.trim(),
    'username': state.signupUsername.trim(),
    'bio': state.bio.trim(),
    if (state.profileImage.trim().isNotEmpty)
      'avatar_url': state.profileImage.trim(),
    'workout_level': state.workoutLevel,
    'days': state.days,
    'snacks': state.snacks,
    'goals': state.goals,
    'workouts': state.workouts,
    'workout_length': state.workoutLenght,
    'workout_period': state.workoutPeriod,
    'workout_where': state.workoutWhere,
    'meals': state.meals,
    'food_alergies': state.foodAlergies,
    'height_cm': state.height,
    'weight_kg': state.weight,
    'gender2': state.gender2,
    if (state.age2 != null)
      'age2': state.age2!.toIso8601String().split('T').first,
  };
}

String _text(dynamic value) => value?.toString().trim() ?? '';

int _integer(dynamic value) {
  if (value is num) return value.round();
  return int.tryParse(_text(value)) ?? 0;
}

Map<String, dynamic> privateProfilePatchFromMetadata(
  Map<String, dynamic> metadata, {
  required String email,
}) =>
    <String, dynamic>{
      'email': email,
      'workout_level': _text(metadata['workout_level']),
      'days': _integer(metadata['days']),
      'snacks': _integer(metadata['snacks']),
      'goals': _text(metadata['goals']),
      'workouts': _text(metadata['workouts']),
      'workout_length': _text(metadata['workout_length']),
      'workout_period': _text(metadata['workout_period']),
      'workout_where': _text(metadata['workout_where']),
      'meals': _text(metadata['meals']),
      'food_alergies': _text(metadata['food_alergies']),
      'height_cm': _integer(metadata['height_cm']),
      'weight_kg': _integer(metadata['weight_kg']),
      'gender2': _text(metadata['gender2']),
      if (_text(metadata['age2']).isNotEmpty) 'age2': _text(metadata['age2']),
    };

/// Claims the reserved username and activates the public GymFeed identity only
/// after the confirmation link has produced a verified session. Questionnaire
/// answers and plan generation intentionally happen later.
Future<void> completeVerifiedOnboarding() async {
  final user = supabase.auth.currentUser;
  if (user == null || user.emailConfirmedAt == null) {
    throw StateError('A verified Supabase session is required.');
  }

  final metadata = Map<String, dynamic>.from(user.userMetadata ?? const {});
  if (metadata['gymfeed_onboarding'] != true) {
    FFAppState().pendingVerificationEmail = '';
    return;
  }

  final state = FFAppState();
  final username = _text(metadata['username']);
  final displayName = _text(
      metadata['display_name'] ?? metadata['full_name'] ?? state.signupName);
  final repository = ProfileRepository();
  await repository.updatePublicProfile(
    username: username.isEmpty ? null : username,
    displayName: displayName.isEmpty ? null : displayName,
  );
  await repository.updatePrivateProfile({
    'email': user.email ?? state.pendingVerificationEmail,
  });
  await refreshCurrentUserProfile();

  await supabase.auth.updateUser(UserAttributes(data: {
    ...metadata,
    'gymfeed_onboarding_stage': 'questions',
  }));
  state.pendingVerificationEmail = '';
}
