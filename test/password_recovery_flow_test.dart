import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_feed/auth/supabase_auth/password_recovery_service.dart';
import 'package:gym_feed/backend/firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:gym_feed/singup/change_password/change_password_widget.dart';

void main() {
  test('password recovery redirects target web and the native app', () {
    expect(
      passwordRecoveryRedirectUrl(web: true),
      'https://gymfeed.io/changePassword',
    );
    expect(
      passwordRecoveryRedirectUrl(web: false),
      'com.flutterflow.gymfeedofficial://changepassword',
    );
    expect(
      appLocationFromIncomingLink(Uri.parse(
        'com.flutterflow.gymfeedofficial://changePassword?code=recovery-code',
      )),
      '/changePassword?code=recovery-code',
    );
    expect(
      appLocationFromIncomingLink(Uri.parse(
        'com.flutterflow.gymfeedofficial://emailVerification?code=verify-code',
      )),
      '/emailVerification?code=verify-code',
    );
    expect(
      appLocationFromIncomingLink(Uri.parse(
        'https://gymfeed.io/changePassword?code=recovery-code',
      )),
      '/changePassword?code=recovery-code',
    );
  });

  test('new password validation rejects weak and mismatched values', () {
    expect(passwordValidationError('', ''), isNotNull);
    expect(passwordValidationError('short1', 'short1'), contains('8'));
    expect(
      passwordValidationError('letters-only', 'letters-only'),
      contains('number'),
    );
    expect(
      passwordValidationError('GymFeed123', 'GymFeed124'),
      contains('do not match'),
    );
    expect(passwordValidationError('GymFeed123', 'GymFeed123'), isNull);
  });

  testWidgets('recovery page validates and updates the password once',
      (tester) async {
    String? updatedPassword;
    var completed = 0;
    await tester.pumpWidget(MaterialApp(
      home: ChangePasswordWidget(
        sessionChecker: () => true,
        updateAction: (password) async => updatedPassword = password,
        completionOpener: () => completed += 1,
      ),
    ));

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('new-password')),
        matching: find.byType(TextFormField),
      ),
      'GymFeed123',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('confirm-password')),
        matching: find.byType(TextFormField),
      ),
      'GymFeed124',
    );
    await tester.tap(find.byKey(const ValueKey('save-new-password')));
    await tester.pump();
    expect(find.text('The passwords do not match.'), findsOneWidget);
    expect(updatedPassword, isNull);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('confirm-password')),
        matching: find.byType(TextFormField),
      ),
      'GymFeed123',
    );
    await tester.tap(find.byKey(const ValueKey('save-new-password')));
    await tester.pumpAndSettle();

    expect(updatedPassword, 'GymFeed123');
    expect(completed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expired recovery session is rejected before updating',
      (tester) async {
    var updates = 0;
    await tester.pumpWidget(MaterialApp(
      home: ChangePasswordWidget(
        sessionChecker: () => false,
        updateAction: (_) async => updates += 1,
      ),
    ));

    for (final entry in const {
      'new-password': 'GymFeed123',
      'confirm-password': 'GymFeed123',
    }.entries) {
      await tester.enterText(
        find.descendant(
          of: find.byKey(ValueKey(entry.key)),
          matching: find.byType(TextFormField),
        ),
        entry.value,
      );
    }
    await tester.tap(find.byKey(const ValueKey('save-new-password')));
    await tester.pump();

    expect(find.textContaining('invalid or expired'), findsOneWidget);
    expect(updates, 0);
    expect(tester.takeException(), isNull);
  });
}
