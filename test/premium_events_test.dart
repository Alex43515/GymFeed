import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_feed/ai_workout/coach_events/coach_events_widget.dart';
import 'package:gym_feed/ai_workout/coach_home/coach_home_widget.dart';
import 'package:gym_feed/ai_workout/coach_tools/coach_tools_widget.dart';
import 'package:gym_feed/ai_workout/payment/payment_widget.dart';
import 'package:gym_feed/ai_workout/premium/ai_usage_gate.dart';
import 'package:gym_feed/backend/supabase/repositories/training_repository.dart';

void main() {
  test('only the designated QA auth user receives unlimited premium usage', () {
    expect(
      hasPremiumTesterOverride('a9fd1bc3-61a8-43a0-b96e-b6e7f0c6d060'),
      isTrue,
    );
    expect(hasPremiumTesterOverride('another-user'), isFalse);
    expect(hasPremiumTesterOverride(null), isFalse);
  });

  void configurePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget phoneApp(Widget home) => MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.7),
          ),
          child: child!,
        ),
        home: home,
      );

  testWidgets('Coach hub shows shared uses, upgrade, and nutrition diary',
      (tester) async {
    configurePhone(tester);
    var upgradeOpens = 0;
    await tester.pumpWidget(phoneApp(CoachHomeWidget(
      statsLoader: () async => const CoachStats(),
      usageStatusLoader: () async =>
          const AiUsageStatus(isPremium: false, used: 0),
      upgradeOpener: () async => upgradeOpens += 1,
    )));
    await tester.pumpAndSettle();

    expect(find.text('3 free uses left'), findsOneWidget);
    expect(find.textContaining('3 free uses left'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('coach-upgrade')));
    await tester.pumpAndSettle();
    expect(upgradeOpens, 1);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('coach-nutrition-diary')),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Nutrition diary'), findsOneWidget);
    expect(find.text('Your logged meals, day by day'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('coach-progress')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('My Progress & plans'), findsOneWidget);
    expect(
        find.text('Your custom plans, stats & monthly photos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Coach hub shows zero free uses after the trial is exhausted',
      (tester) async {
    configurePhone(tester);
    await tester.pumpWidget(phoneApp(CoachHomeWidget(
      statsLoader: () async => const CoachStats(),
      usageStatusLoader: () async =>
          const AiUsageStatus(isPremium: false, used: 3),
      upgradeOpener: () async {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('0 free uses left'), findsOneWidget);
    expect(find.textContaining('0 uses left'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exhausted AI Trainer action opens the premium flow',
      (tester) async {
    configurePhone(tester);
    var upgradeOpens = 0;
    await tester.pumpWidget(phoneApp(CoachTrainerWidget(
      useGate: () async => const AiUseDecision(AiUseResult.exhausted),
      upgradeOpener: () async => upgradeOpens += 1,
    )));
    await tester.pump();

    await tester.enterText(
        find.byKey(const ValueKey('trainer-input')), 'Build a plan');
    await tester.tap(find.byKey(const ValueKey('trainer-send')));
    await tester.pumpAndSettle();
    expect(upgradeOpens, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Events search filters by title, description, and host',
      (tester) async {
    configurePhone(tester);
    final events = [
      Training({
        'id': 'strength',
        'title': 'Barbell Meetup',
        'description': 'Full body strength session',
        'author': {'username': 'alex'},
      }),
      Training({
        'id': 'yoga',
        'title': 'Sunrise Yoga',
        'description': 'Mobility and recovery',
        'author': {'username': 'maya'},
      }),
    ];
    await tester.pumpWidget(phoneApp(CoachEventsWidget(
      trainingsLoader: () async => events,
    )));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('event-card-strength')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('event-search-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('event-search-input')), 'maya recovery');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('event-card-strength')), findsNothing);
    expect(find.byKey(const ValueKey('event-card-yoga')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('premium page opens on the monthly GymFeed Pro plan',
      (tester) async {
    configurePhone(tester);
    await tester.pumpWidget(phoneApp(
      const Scaffold(body: PaymentWidget(initialPremium: true)),
    ));
    await tester.pump();

    expect(find.text('Premium plan'), findsOneWidget);
    expect(find.text('One month of GymFeed Pro access'), findsOneWidget);
    expect(find.text('Subscribe'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
