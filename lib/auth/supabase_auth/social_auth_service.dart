import 'package:flutter/foundation.dart';

const socialAuthCallbackPath = '/authCallback';
const socialAuthLoginDestination = '/feed';
const socialAuthSignupDestination = '/allMostDone';

const _nativeAuthScheme = 'com.flutterflow.gymfeedofficial';

/// Only destinations owned by the authentication flow may be restored after
/// OAuth. Keeping this list closed prevents an untrusted `next` query value
/// from turning the callback into an open redirect.
String normalizeSocialAuthDestination(String? value) {
  return switch (value) {
    socialAuthSignupDestination => socialAuthSignupDestination,
    socialAuthLoginDestination => socialAuthLoginDestination,
    _ => socialAuthLoginDestination,
  };
}

/// Builds the URL Supabase sends the browser back to after social login.
///
/// Web uses the origin that launched the flow (production or localhost).
/// Android/iOS use GymFeed's registered custom scheme, which is handled by
/// app_links and Supabase's PKCE callback listener.
String socialAuthRedirectUrl({
  String nextPath = socialAuthLoginDestination,
  bool? web,
  Uri? webBase,
}) {
  final destination = normalizeSocialAuthDestination(nextPath);
  final useWeb = web ?? kIsWeb;
  if (!useWeb) {
    return Uri(
      scheme: _nativeAuthScheme,
      path: socialAuthCallbackPath,
      queryParameters: {'next': destination},
    ).toString();
  }

  final base = webBase ?? Uri.base;
  return Uri(
    scheme: base.scheme,
    host: base.host,
    port: base.hasPort ? base.port : null,
    path: socialAuthCallbackPath,
    queryParameters: {'next': destination},
  ).toString();
}

String? socialAuthCallbackError(Uri uri) {
  final raw = uri.queryParameters['error_description'] ??
      uri.queryParameters['error'] ??
      uri.queryParameters['error_code'];
  if (raw == null || raw.trim().isEmpty) return null;

  final message = raw.replaceAll('+', ' ').trim();
  final lower = message.toLowerCase();
  if (lower.contains('access_denied') ||
      lower.contains('cancel') ||
      lower.contains('denied')) {
    return 'Sign-in was cancelled. No changes were made.';
  }
  return 'Social sign-in could not be completed. $message';
}

/// Turns the identity returned by a social provider into a safe username seed.
///
/// Google does not provide a GymFeed username, so signup must not force users
/// to fill that field before opening OAuth. The callback uses this seed and
/// adds a suffix when another profile already owns it.
String socialSignupUsernameSeed({
  required Map<String, dynamic> metadata,
  required String email,
  required String displayName,
}) {
  final emailPrefix = email.split('@').first;
  final raw = <Object?>[
    metadata['preferred_username'],
    metadata['user_name'],
    emailPrefix,
    displayName,
  ].map((value) => value?.toString().trim() ?? '').firstWhere(
        (value) => value.isNotEmpty,
        orElse: () => 'gymfeed_user',
      );

  var normalized = raw
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_{2,}'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  if (normalized.isEmpty) normalized = 'gymfeed_user';
  if (normalized.length < 3) normalized = '${normalized}_gf';
  if (normalized.length > 24) normalized = normalized.substring(0, 24);
  return normalized;
}
