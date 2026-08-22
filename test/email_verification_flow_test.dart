import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_feed/app_state.dart';
import 'package:gym_feed/auth/supabase_auth/email_verification_service.dart';
import 'package:gym_feed/auth/supabase_auth/supabase_user_provider.dart';
import 'package:gym_feed/backend/supabase/supabase.dart';
import 'package:gym_feed/singup/email_verification/email_verification_widget.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FFAppState.reset();
    await FFAppState().initializePersistedState();
  });

  test('verification redirects target the web app and native callback', () {
    expect(
      emailVerificationRedirectUrl(web: true),
      'https://gymfeed.io/emailVerification',
    );
    expect(
      emailVerificationRedirectUrl(web: false),
      'com.flutterflow.gymfeedofficial://emailVerification',
    );
  });

  test('a signup user without a Supabase session is not logged in', () {
    const user = User(
      id: 'pending-user',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      email: 'athlete@example.com',
      createdAt: '2026-08-15T12:00:00Z',
    );

    expect(SupabaseAuthUser(user, hasSession: false).loggedIn, isFalse);
    expect(SupabaseAuthUser(user, hasSession: true).loggedIn, isTrue);
  });

  test('expired callbacks return an actionable message', () {
    final message = verificationLinkError(Uri.parse(
      'https://gymfeed.io/emailVerification?error_description=Email+link+is+expired',
    ));
    expect(message, contains('expired'));
    expect(message, contains('Request a new email'));
  });

  test('pending signup metadata contains identity but no questionnaire data',
      () {
    FFAppState().signupName = 'Alex Athlete';
    FFAppState().signupUsername = 'alex_athlete';
    FFAppState().workoutLevel = 'advanced';

    final metadata = signupIdentityMetadata();

    expect(metadata['gymfeed_onboarding_stage'], 'awaiting_email');
    expect(metadata['full_name'], 'Alex Athlete');
    expect(metadata['username'], 'alex_athlete');
    expect(metadata.containsKey('workout_level'), isFalse);
    expect(metadata.containsKey('meals'), isFalse);
  });

  test('profile metadata is normalized before the verified write', () {
    final patch = privateProfilePatchFromMetadata({
      'height_cm': '181',
      'weight_kg': 82.4,
      'days': '4',
      'snacks': 2,
      'goals': 'strength',
      'age2': '1998-04-12',
    }, email: 'athlete@example.com');

    expect(patch['email'], 'athlete@example.com');
    expect(patch['height_cm'], 181);
    expect(patch['weight_kg'], 82);
    expect(patch['days'], 4);
    expect(patch['age2'], '1998-04-12');
  });

  testWidgets('verification check activates identity and opens questions once',
      (tester) async {
    var checks = 0;
    var completions = 0;
    var opened = 0;

    await tester.pumpWidget(MaterialApp(
      home: EmailVerificationWidget(
        email: 'athlete@example.com',
        verificationEvents: const Stream<bool>.empty(),
        verificationChecker: () async => ++checks > 1,
        onboardingCompleter: () async => completions += 1,
        verifiedOpener: () => opened += 1,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('athlete@example.com'), findsOneWidget);
    expect(opened, 0);

    await tester.tap(find.byKey(const ValueKey('check-verification')));
    await tester.pumpAndSettle();

    expect(completions, 1);
    expect(opened, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resend reports success and enforces its cooldown',
      (tester) async {
    var sends = 0;
    final events = StreamController<bool>();
    addTearDown(events.close);

    await tester.pumpWidget(MaterialApp(
      home: EmailVerificationWidget(
        email: 'athlete@example.com',
        verificationEvents: events.stream,
        verificationChecker: () async => false,
        resendAction: () async => sends += 1,
        resendCooldown: const Duration(seconds: 2),
      ),
    ));
    await tester.pumpAndSettle();

    final resend = find.byKey(const ValueKey('resend-verification'));
    await tester.ensureVisible(resend);
    await tester.tap(resend);
    await tester.pump();
    expect(sends, 1);
    expect(
        find.textContaining('new verification email was sent'), findsOneWidget);
    expect(find.text('Resend in 2s'), findsOneWidget);

    await tester.tap(resend, warnIfMissed: false);
    expect(sends, 1);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Resend email'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
