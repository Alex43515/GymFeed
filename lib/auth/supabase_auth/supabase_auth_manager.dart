import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '/backend/supabase/supabase.dart';
import '/app_state.dart';
import '/flutter_flow/nav/nav.dart' show AppStateNotifier;
import '../auth_manager.dart';
import 'supabase_user_provider.dart';
import 'email_verification_service.dart';
import 'password_recovery_service.dart';
import 'social_auth_service.dart';

export '../base_auth_user_provider.dart';

/// Supabase implementation of the app's AuthManager.
enum SupabaseAuthFailureKind { emailNotConfirmed, other }

class SupabaseAuthManager extends AuthManager
    with
        EmailSignInManager,
        GoogleSignInManager,
        AppleSignInManager,
        FacebookSignInManager {
  SupabaseAuthFailureKind? lastFailure;
  Map<String, bool>? _providerAvailability;

  @override
  Future signOut() => supabase.auth.signOut();

  @override
  Future deleteUser(BuildContext context) async {
    try {
      if (!loggedIn) {
        debugPrint('Error: delete user attempted with no logged in user!');
        return;
      }
      await currentUser?.delete();
    } catch (e) {
      _showError(context, 'Could not delete account: $e');
    }
  }

  @override
  Future updateEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      if (!loggedIn) return;
      await currentUser?.updateEmail(email);
    } on AuthException catch (e) {
      _showError(context, e.message);
    }
  }

  @override
  Future updatePassword({
    required String newPassword,
    required BuildContext context,
  }) async {
    try {
      if (!loggedIn) return;
      await currentUser?.updatePassword(newPassword);
    } on AuthException catch (e) {
      _showError(context, e.message);
    }
  }

  @override
  Future resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: passwordRecoveryRedirectUrl(),
      );
    } on AuthException catch (e) {
      _showError(context, e.message);
      return null;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset email sent')),
    );
  }

  @override
  Future<BaseAuthUser?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) {
    lastFailure = null;
    FFAppState().pendingVerificationEmail = email;
    return _guard(context, () async {
      final res = await supabase.auth
          .signInWithPassword(email: email, password: password);
      FFAppState().pendingVerificationEmail = '';
      return _completeAuth(SupabaseAuthUser(
        res.user,
        hasSession: res.session != null,
      ));
    });
  }

  @override
  Future<BaseAuthUser?> createAccountWithEmail(
      BuildContext context, String email, String password,
      {Map<String, dynamic>? data}) {
    lastFailure = null;
    FFAppState().pendingVerificationEmail = email;
    return _guard(context, () async {
      // Migration 0025 reserves the username now, but provisions the public
      // profile only when Supabase marks the email as confirmed.
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: emailVerificationRedirectUrl(),
        data: data,
      );
      final user = SupabaseAuthUser(
        res.user,
        hasSession: res.session != null,
      );
      // With Confirm email enabled, Supabase returns a user but no session.
      // Never mark that pending identity as authenticated.
      if (!user.loggedIn) return user;
      FFAppState().pendingVerificationEmail = '';
      return _completeAuth(user);
    });
  }

  @override
  Future<void> sendEmailVerification() async {
    final email = currentUser?.email ?? FFAppState().pendingVerificationEmail;
    if (email.trim().isEmpty) {
      throw StateError('Enter your email again so we can resend verification.');
    }
    await supabase.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: emailVerificationRedirectUrl(),
    );
  }

  @override
  Future<void> refreshUser() async {
    if (supabase.auth.currentSession == null) return;
    final response = await supabase.auth.refreshSession();
    final user = response.user;
    if (user != null) {
      _completeAuth(SupabaseAuthUser(user, hasSession: true));
    }
  }

  BaseAuthUser _completeAuth(SupabaseAuthUser authenticatedUser) {
    // Keep provider-agnostic getters and GoRouter in sync immediately. The
    // Supabase auth stream remains the long-term source of truth.
    currentUser = authenticatedUser;
    AppStateNotifier.instance.completeAuthEvent(authenticatedUser);
    return authenticatedUser;
  }

  @override
  Future<BaseAuthUser?> signInWithGoogle(
    BuildContext context, {
    String nextPath = socialAuthLoginDestination,
  }) =>
      _signInWithOAuth(context, OAuthProvider.google, nextPath: nextPath);

  @override
  Future<BaseAuthUser?> signInWithApple(
    BuildContext context, {
    String nextPath = socialAuthLoginDestination,
  }) =>
      _signInWithOAuth(context, OAuthProvider.apple, nextPath: nextPath);

  @override
  Future<BaseAuthUser?> signInWithFacebook(
    BuildContext context, {
    String nextPath = socialAuthLoginDestination,
  }) =>
      _signInWithOAuth(context, OAuthProvider.facebook, nextPath: nextPath);

  Future<BaseAuthUser?> _signInWithOAuth(
    BuildContext context,
    OAuthProvider provider, {
    required String nextPath,
  }) async {
    lastFailure = null;
    try {
      final enabled = await _isProviderEnabled(provider);
      if (enabled == false) {
        _showError(
          context,
          '${_providerLabel(provider)} sign-in is not active yet. Its provider credentials must be enabled in Supabase.',
        );
        return null;
      }
      final launched = await supabase.auth.signInWithOAuth(
        provider,
        redirectTo: socialAuthRedirectUrl(nextPath: nextPath),
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
        queryParams: provider == OAuthProvider.google
            ? const {'prompt': 'select_account'}
            : null,
      );
      if (!launched) {
        _showError(context,
            'The ${_providerLabel(provider)} sign-in page could not be opened.');
        return null;
      }

      // On web the page navigates away. On native, the PKCE session is
      // completed by the callback deep link and SocialAuthCallbackWidget.
      final session = supabase.auth.currentSession;
      if (session?.user != null) {
        return _completeAuth(
          SupabaseAuthUser(session!.user, hasSession: true),
        );
      }
      return null;
    } on AuthException catch (error) {
      lastFailure = SupabaseAuthFailureKind.other;
      final unsupported = error.message.toLowerCase().contains('unsupported') ||
          error.message.toLowerCase().contains('not enabled');
      _showError(
        context,
        unsupported
            ? '${_providerLabel(provider)} sign-in still needs to be enabled in Supabase.'
            : error.message,
      );
      return null;
    } catch (error) {
      lastFailure = SupabaseAuthFailureKind.other;
      _showError(context,
          '${_providerLabel(provider)} sign-in failed. Please try again.');
      debugPrint('OAuth launch failed for ${_providerLabel(provider)}: $error');
      return null;
    }
  }

  String _providerLabel(OAuthProvider provider) => switch (provider) {
        OAuthProvider.google => 'Google',
        OAuthProvider.apple => 'Apple',
        OAuthProvider.facebook => 'Facebook',
        _ => 'Social',
      };

  Future<bool?> _isProviderEnabled(OAuthProvider provider) async {
    final cached = _providerAvailability;
    if (cached != null && cached.containsKey(provider.name)) {
      return cached[provider.name];
    }
    try {
      final response = await http.get(
        Uri.parse('${SupaFlow.supabaseUrl}/auth/v1/settings'),
        headers: const {'apikey': SupaFlow.supabaseKey},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final external = payload['external'] as Map<String, dynamic>?;
      if (external == null) return null;
      _providerAvailability = external.map(
        (key, value) => MapEntry(key, value == true),
      );
      return _providerAvailability?[provider.name];
    } catch (error) {
      debugPrint('Could not read Supabase provider settings: $error');
      // A temporary settings request failure should not block OAuth itself.
      return null;
    }
  }

  Future<BaseAuthUser?> _guard(
    BuildContext context,
    Future<BaseAuthUser?> Function() fn,
  ) async {
    try {
      return await fn();
    } on AuthException catch (e) {
      final confirmationRequired = isEmailConfirmationError(e);
      lastFailure = confirmationRequired
          ? SupabaseAuthFailureKind.emailNotConfirmed
          : SupabaseAuthFailureKind.other;
      final msg = confirmationRequired
          ? 'Verify your email before signing in. We can resend the link.'
          : switch (e.statusCode) {
              '422' => 'That email is already in use by a different account',
              '400' => 'The supplied credentials are incorrect or have expired',
              _ => e.message,
            };
      _showError(context, msg);
      return null;
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Error: $message')));
  }
}
