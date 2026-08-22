import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_feed/app_state.dart';
import 'package:gym_feed/singup/onboarding/sign_up/sign_up_widget.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FFAppState.reset();
    await FFAppState().initializePersistedState();
  });

  testWidgets('username availability updates while the athlete types',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: SignUpWidget(
        usernameAvailabilityChecker: (username) async =>
            username.toLowerCase() != 'already_used',
      ),
    ));

    final usernameField = find.byType(TextFormField).at(1);
    await tester.enterText(usernameField, 'alex_available');
    await tester.pump(const Duration(milliseconds: 451));
    await tester.pump();
    expect(find.byKey(const ValueKey('username-available')), findsOneWidget);
    expect(find.text('Username is available'), findsOneWidget);

    await tester.enterText(usernameField, 'already_used');
    await tester.pump(const Duration(milliseconds: 451));
    await tester.pump();
    expect(find.byKey(const ValueKey('username-taken')), findsOneWidget);
    expect(find.text('Username is already taken'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
