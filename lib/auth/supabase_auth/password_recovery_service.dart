import 'package:flutter/foundation.dart';

import 'email_verification_service.dart'
    show gymFeedNativeAuthScheme, gymFeedWebOrigin;

const gymFeedPasswordRecoveryPath = '/changePassword';

/// Supabase sends password-recovery links here after it verifies the token.
/// The URLs must remain present in Auth > URL Configuration.
String passwordRecoveryRedirectUrl({bool? web}) {
  if (web ?? kIsWeb) {
    return '$gymFeedWebOrigin$gymFeedPasswordRecoveryPath';
  }
  return Uri(
    scheme: gymFeedNativeAuthScheme,
    host: gymFeedPasswordRecoveryPath.substring(1),
  ).toString();
}

String? passwordValidationError(String password, String confirmation) {
  if (password.isEmpty || confirmation.isEmpty) {
    return 'Enter and confirm your new password.';
  }
  if (password.length < 8) {
    return 'Use at least 8 characters.';
  }
  if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
      !RegExp(r'[0-9]').hasMatch(password)) {
    return 'Include at least one letter and one number.';
  }
  if (password != confirmation) {
    return 'The passwords do not match.';
  }
  return null;
}
