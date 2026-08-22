import 'dart:async';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/supabase_auth/social_auth_service.dart';
import '/backend/supabase/repositories/profile_repository.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';

class SocialAuthCallbackWidget extends StatefulWidget {
  const SocialAuthCallbackWidget({
    super.key,
    this.completionChecker,
    this.destinationOpener,
    this.timeout = const Duration(seconds: 20),
  });

  static String routeName = 'SocialAuthCallback';
  static String routePath = 'authCallback';

  final Future<bool> Function()? completionChecker;
  final void Function(String destination)? destinationOpener;
  final Duration timeout;

  @override
  State<SocialAuthCallbackWidget> createState() =>
      _SocialAuthCallbackWidgetState();
}

class _SocialAuthCallbackWidgetState extends State<SocialAuthCallbackWidget> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _completeCallback());
  }

  Future<bool> _waitForSession() async {
    if (supabase.auth.currentSession?.user != null) return true;
    try {
      final state = await supabase.auth.onAuthStateChange
          .firstWhere((event) => event.session?.user != null)
          .timeout(widget.timeout);
      return state.session?.user != null;
    } on TimeoutException {
      return false;
    }
  }

  Future<void> _completeCallback() async {
    final uri = GoRouterState.of(context).uri;
    final callbackError = socialAuthCallbackError(uri);
    if (callbackError != null) {
      if (mounted) setState(() => _error = callbackError);
      return;
    }

    try {
      final completed =
          await (widget.completionChecker?.call() ?? _waitForSession());
      if (!completed) {
        if (mounted) {
          setState(() => _error =
              'The sign-in response timed out. Please return and try again.');
        }
        return;
      }

      if (widget.completionChecker == null) {
        await authManager.refreshUser();
      }
      final destination = normalizeSocialAuthDestination(
        uri.queryParameters['next'],
      );
      if (destination == socialAuthSignupDestination &&
          widget.completionChecker == null) {
        final user = supabase.auth.currentUser;
        if (user != null) {
          final metadata = user.userMetadata ?? const <String, dynamic>{};
          final repository = ProfileRepository();
          final existingProfile = await repository.getMyProfile();
          FFAppState().signupEmail = user.email ?? FFAppState().signupEmail;
          if (FFAppState().signupName.isEmpty) {
            FFAppState().signupName = (metadata['full_name'] ??
                    metadata['name'] ??
                    existingProfile?.displayName ??
                    '')
                .toString()
                .trim();
          }
          if (FFAppState().signupUsername.isEmpty) {
            final savedUsername = existingProfile?.username.trim() ?? '';
            FFAppState().signupUsername = savedUsername.isNotEmpty
                ? savedUsername
                : await _availableSocialUsername(
                    repository,
                    socialSignupUsernameSeed(
                      metadata: metadata,
                      email: user.email ?? '',
                      displayName: FFAppState().signupName,
                    ),
                    user.id,
                  );
          }
          if (FFAppState().profileImage.isEmpty) {
            FFAppState().profileImage =
                (existingProfile?.photoUrl.isNotEmpty == true
                        ? existingProfile!.photoUrl
                        : metadata['avatar_url'] ?? metadata['picture'] ?? '')
                    .toString()
                    .trim();
          }
          FFAppState().update(() {});
        }
      }

      if (!mounted) return;
      final opener = widget.destinationOpener;
      if (opener != null) {
        opener(destination);
      } else {
        context.go(destination);
      }
    } catch (error) {
      debugPrint('Social auth callback failed: $error');
      if (mounted) {
        setState(() => _error =
            'Social sign-in could not be completed. Please try again.');
      }
    }
  }

  Future<String> _availableSocialUsername(
    ProfileRepository repository,
    String seed,
    String userId,
  ) async {
    try {
      if (await repository.isUsernameAvailable(seed)) return seed;
      for (var suffix = 2; suffix <= 20; suffix++) {
        final candidate = '${seed}_$suffix';
        if (await repository.isUsernameAvailable(candidate)) return candidate;
      }
    } catch (error) {
      debugPrint('Could not preflight a social username: $error');
    }
    final idSuffix = userId.replaceAll('-', '').substring(0, 8);
    final prefix = seed.length > 15 ? seed.substring(0, 15) : seed;
    return '${prefix}_$idSuffix';
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF090909);
    const green = Color(0xFF1FE276);
    final error = _error;
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: error == null
                          ? const Color(0xFF103523)
                          : const Color(0xFF3A1717),
                      shape: BoxShape.circle,
                    ),
                    child: error == null
                        ? const Padding(
                            padding: EdgeInsets.all(18),
                            child: CircularProgressIndicator(
                              color: green,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(Icons.error_outline_rounded,
                            color: Color(0xFFFF6B6B), size: 30),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    error == null ? 'Signing you in' : 'Sign-in interrupted',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    error ?? 'Securely returning you to GymFeed…',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF929292),
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        key: const ValueKey('return-to-sign-in'),
                        onPressed: () =>
                            context.goNamed(SignInWidget.routeName),
                        style: FilledButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: background,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          'Return to sign in',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
