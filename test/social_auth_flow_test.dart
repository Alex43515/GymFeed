import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_feed/auth/supabase_auth/social_auth_service.dart';
import 'package:gym_feed/backend/firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:gym_feed/singup/social_auth_callback/social_auth_callback_widget.dart';

void main() {
  test('social redirects return to the current web origin or native app', () {
    expect(
      socialAuthRedirectUrl(
        web: true,
        webBase: Uri.parse('https://gymfeed.io/signIn'),
      ),
      'https://gymfeed.io/authCallback?next=%2Ffeed',
    );
    expect(
      socialAuthRedirectUrl(
        web: false,
        nextPath: socialAuthSignupDestination,
      ),
      'com.flutterflow.gymfeedofficial:/authCallback?next=%2FallMostDone',
    );
  });

  test('callback destinations cannot be turned into an open redirect', () {
    expect(
      normalizeSocialAuthDestination('https://attacker.example'),
      socialAuthLoginDestination,
    );
    expect(
      normalizeSocialAuthDestination(socialAuthSignupDestination),
      socialAuthSignupDestination,
    );
  });

  test('native callback is converted into the matching app route', () {
    final uri = Uri.parse(
      'com.flutterflow.gymfeedofficial:/authCallback?next=%2FallMostDone&code=abc',
    );
    expect(
      appLocationFromIncomingLink(uri),
      '/authCallback?next=%2FallMostDone&code=abc',
    );
  });

  test('provider cancellation returns an actionable non-fatal message', () {
    final error = socialAuthCallbackError(Uri.parse(
      'https://gymfeed.io/authCallback?error=access_denied&error_description=User+cancelled',
    ));
    expect(error, contains('cancelled'));
    expect(error, contains('No changes'));
  });

  test('Google identity produces a safe username when the field is skipped',
      () {
    expect(
      socialSignupUsernameSeed(
        metadata: const {'full_name': 'Aleksandar Živković'},
        email: 'Aleksandar.Zivkovic+gym@gmail.com',
        displayName: 'Aleksandar Živković',
      ),
      'aleksandar_zivkovic_gym',
    );
    expect(
      socialSignupUsernameSeed(
        metadata: const {},
        email: '',
        displayName: 'Živković Test',
      ),
      'ivkovi_test',
    );
  });

  testWidgets('successful callback opens its allow-listed destination',
      (tester) async {
    String? opened;
    final router = GoRouter(
      initialLocation: '/authCallback?next=%2FallMostDone',
      routes: [
        GoRoute(
          path: '/authCallback',
          builder: (_, __) => SocialAuthCallbackWidget(
            completionChecker: () async => true,
            destinationOpener: (destination) => opened = destination,
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump();

    expect(opened, socialAuthSignupDestination);
    expect(tester.takeException(), isNull);
  });
}
