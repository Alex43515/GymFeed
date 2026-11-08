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

  testWidgets('Coach hub shows free Premium days, invites, and nutrition diary',
      (tester) async {
    configurePhone(tester);
    var upgradeOpens = 0;
    var inviteOpens = 0;
    await tester.pumpWidget(phoneApp(CoachHomeWidget(
      statsLoader: () async => const CoachStats(),
      premiumStatusLoader: () async => PremiumStatus.fromServer(const {
        'seconds_left': 5 * 86400 - 3600,
        'trial_days': 7,
        'invites_used': 1,
        'invites_max': 4,
        'referral_bonus_days': 7,
        'can_redeem_invite': false,
      }, paid: false),
      upgradeOpener: () async => upgradeOpens += 1,
      inviteOpener: () async => inviteOpens += 1,
    )));
    await tester.pumpAndSettle();

    expect(find.text('Pro · 5 days left'), findsOneWidget);
    expect(find.text('Premium · 5 days left'), findsOneWidget);
    expect(find.text('Invite friends: +7 days each · 1 of 4 used'),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('coach-invite-friend')));
    await tester.pumpAndSettle();
    expect(inviteOpens, 1);
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

  testWidgets('Coach hub explains when the free Premium days have ended',
      (tester) async {
    configurePhone(tester);
    await tester.pumpWidget(phoneApp(CoachHomeWidget(
      statsLoader: () async => const CoachStats(),
      premiumStatusLoader: () async => PremiumStatus.fromServer(const {
        'seconds_left': 0,
        'trial_days': 7,
        'invites_used': 4,
        'invites_max': 4,
        'can_redeem_invite': false,
      }, paid: false),
      upgradeOpener: () async {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('Free plan'), findsOneWidget);
    expect(find.text('Your free Premium has ended'), findsOneWidget);
    expect(find.text('Invite friends: +7 days each · 4 of 4 used'),
        findsOneWidget);
    // All four invites are used, so there is nothing left to share.
    expect(find.byKey(const ValueKey('coach-invite-friend')), findsNothing);
    expect(find.byKey(const ValueKey('coach-upgrade')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('paid subscribers see Pro active instead of days',
      (tester) async {
    configurePhone(tester);
    await tester.pumpWidget(phoneApp(CoachHomeWidget(
      statsLoader: () async => const CoachStats(),
      premiumStatusLoader: () async =>
          PremiumStatus.fromServer(const {'seconds_left': 0}, paid: true),
      upgradeOpener: () async {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('Pro active'), findsOneWidget);
    expect(find.text('GymFeed Pro active · All AI tools'), findsOneWidget);
    expect(find.byKey(const ValueKey('coach-premium-banner')), findsNothing);
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
    expect(find.text('Subscribe'), findsOneWidget);
    expect(find.text('Per month'), findsOneWidget);
    expect(find.text('Auto-renews monthly. Cancel anytime.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('paywall lists what Premium includes and its daily limit',
      (tester) async {
    configurePhone(tester);
    await tester.pumpWidget(phoneApp(
      const Scaffold(body: PaymentWidget(initialPremium: true)),
    ));
    await tester.pump();

    expect(find.text('Food scanner'), findsOneWidget);
    expect(find.text('Equipment scanner'), findsOneWidget);
    expect(find.text('AI Trainer'), findsOneWidget);
    expect(find.text('Includes up to 40 scans and AI Trainer messages a day.'),
        findsOneWidget);
    expect(find.textContaining(RegExp('unlimited', caseSensitive: false)),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('free tab describes the free plan and leads to Premium',
      (tester) async {
    configurePhone(tester);
    await tester.pumpWidget(phoneApp(const Scaffold(body: PaymentWidget())));
    await tester.pump();

    expect(find.text('Free plan'), findsOneWidget);
    expect(find.text('Feed and community'), findsOneWidget);
    expect(find.textContaining('free Premium days'), findsOneWidget);
    expect(find.textContaining('3 shared uses'), findsNothing);
    expect(find.textContaining(RegExp('unlimited', caseSensitive: false)),
        findsNothing);

    await tester.tap(find.text('Try Premium'));
    await tester.pumpAndSettle();
    expect(find.text('Premium plan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
