import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_feed/backend/firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:gym_feed/backend/share_links.dart';
import 'package:gym_feed/components/first_run/bubble_tour.dart';
import 'package:gym_feed/components/first_run/first_run_flow.dart';
import 'package:gym_feed/components/first_run/tour_anchor.dart';
import 'package:gym_feed/components/profile_share/profile_share_sheet.dart';

void main() {
  group('registration gate', () {
    test('the first-run flow waits for the whole registration', () {
      expect(FirstRunFlow.registrationOpen('awaiting_email'), isTrue);
      expect(FirstRunFlow.registrationOpen('questions'), isTrue);
      expect(FirstRunFlow.registrationOpen('answers_complete'), isFalse);
      expect(FirstRunFlow.registrationOpen(null), isFalse);
    });

    test('plan generation counts as registration until the athlete leaves', () {
      FirstRunFlow.beginFinishingRegistration();
      expect(FirstRunFlow.registrationOpen('answers_complete'), isTrue);
      FirstRunFlow.startAfterRegistration();
      expect(FirstRunFlow.registrationOpen('answers_complete'), isFalse);
    });
  });

  group('bubble tour', () {
    const steps = [
      BubbleTourStep(
          anchor: 'one', route: 'coach', title: 'Premium', body: 'First'),
      BubbleTourStep(
          anchor: 'missing', route: 'coach', title: 'Gone', body: 'Skipped'),
      BubbleTourStep(
          anchor: 'two', route: 'train', title: 'Train', body: 'Second'),
    ];

    Future<NavigatorState> host(
        WidgetTester tester, ValueNotifier<String> page) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<String>(
            valueListenable: page,
            builder: (_, value, __) => Center(
              child: TourAnchor(
                id: value == 'coach' ? 'one' : 'two',
                child: const SizedBox(width: 120, height: 60),
              ),
            ),
          ),
        ),
      ));
      return tester.state<NavigatorState>(find.byType(Navigator));
    }

    test('every other tour step has its target on the real screen', () {
      const screens = {
        'train-plans': 'lib/workout/training_home/training_home_widget.dart',
        'train-calendar': 'lib/workout/training_home/training_home_widget.dart',
        'events-page': 'lib/ai_workout/coach_events/coach_events_widget.dart',
        'diary-plan':
            'lib/ai_workout/nutrition_diary/nutrition_diary_widget.dart',
        'diary-plan-meal':
            'lib/ai_workout/nutrition_diary/nutrition_diary_widget.dart',
        'feed-create': 'lib/pages/core_pages/feed/feed_widget.dart',
        'profile-share':
            'lib/pages/core_pages/profile/mobile_profile_view.dart',
      };
      screens.forEach((id, path) {
        expect(File(path).readAsStringSync(), contains("'$id'"), reason: path);
      });
    });

    test('the tour covers everything that was asked for, Premium first', () {
      final anchors = BubbleTour.steps().map((s) => s.anchor).toList();
      expect(
          anchors,
          containsAllInOrder(const [
            'coach-premium',
            'coach-tool-trainer',
            'coach-tool-equipment',
            'coach-tool-body',
            'coach-tool-food',
            'coach-diary',
            'coach-progress',
            'coach-health',
            'train-calendar',
            'train-plans',
            'events-page',
          ]));
    });

    test('the Train step announces the plan once it is ready', () {
      String title(bool ready) => BubbleTour.steps(planReady: ready)
          .firstWhere((s) => s.anchor == 'train-calendar')
          .title;
      expect(title(false), 'Your training calendar');
      expect(title(true), 'Your 28-day plan is on your calendar');
      expect(BubbleTour.planAddedTip.single.anchor, 'train-calendar');
      expect(BubbleTour.mealPlanTip.map((s) => s.anchor),
          ['diary-plan', 'diary-plan-meal']);
    });

    test('tips never show without a signed-in account', () async {
      await BubbleTour.showTipOnce('any', BubbleTour.planAddedTip);
    });

    testWidgets('Premium is the first thing the tour shows', (tester) async {
      expect(BubbleTour.steps().first.title, 'Premium comes first');
      expect(BubbleTour.steps().first.anchor, 'coach-premium');
      expect(BubbleTour.steps().map((s) => s.route).toSet().length,
          greaterThanOrEqualTo(3),
          reason: 'the tour walks from screen to screen');
    });

    testWidgets('walks screen to screen and skips what is not there',
        (tester) async {
      final page = ValueNotifier('coach');
      final opened = <String>[];
      final navigator = await host(tester, page);
      BubbleTourResult? result;
      BubbleTour.run(
        overlay: navigator.overlay!,
        steps: steps,
        finishLabel: 'Finish now',
        open: (route) async {
          opened.add(route);
          page.value = route;
        },
      ).then((value) => result = value);

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Premium'), findsOneWidget);
      expect(find.text('1 of 3'), findsOneWidget);

      await tester.tap(find.byKey(const Key('bubble-tour-next')));
      // The missing anchor is searched for, then passed over.
      for (var i = 0; i < 14; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.text('Train'), findsOneWidget);
      expect(find.text('Gone'), findsNothing);
      expect(find.text('Finish now'), findsOneWidget);
      expect(opened, ['coach', 'train']);

      await tester.tap(find.byKey(const Key('bubble-tour-next')));
      await tester.pump();
      expect(result, BubbleTourResult.completed);
      expect(find.byKey(const Key('bubble-tour')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Skip ends the tour at once', (tester) async {
      final page = ValueNotifier('coach');
      final navigator = await host(tester, page);
      BubbleTourResult? result;
      BubbleTour.run(
        overlay: navigator.overlay!,
        steps: steps,
        open: (route) async => page.value = route,
      ).then((value) => result = value);

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const Key('bubble-tour-skip')));
      await tester.pump();
      expect(result, BubbleTourResult.skipped);
      expect(find.byKey(const Key('bubble-tour')), findsNothing);
    });
  });

  group('profile share', () {
    test('profile links open the profile in the app', () {
      expect(
          appLocationFromIncomingLink(
              Uri.parse('https://gymfeed.io/u/alex_fit')),
          '/profileOther?username=alex_fit');
      expect(
          appLocationFromIncomingLink(
              Uri.parse('https://gymfeed.io/u/alex_fit/')),
          '/profileOther?username=alex_fit');
      expect(
          appLocationFromIncomingLink(Uri.parse(
              'com.flutterflow.gymfeedofficial:/profileOther?username=alex_fit')),
          '/profileOther?username=alex_fit');
    });

    test('the phone is told to open /u/ links in GymFeed', () {
      expect(
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
          contains('android:pathPrefix="/u/"'));
      expect(File('ios/Runner/Runner.entitlements').readAsStringSync(),
          contains('applinks:gymfeed.io'));
      final site =
          File('website/public_html/.well-known/apple-app-site-association')
              .readAsStringSync();
      expect(site, contains('Z9ZWB3L4QL.com.flutterflow.gymfeedofficial'));
      expect(site, contains('/u/*'));
      expect(File('website/public_html/.htaccess').readAsStringSync(),
          contains('profile.php?u=\$1'));
      expect(File('.github/workflows/deploy-website.yml').readAsStringSync(),
          contains('website/public_html/profile.php'));
    });

    test('share links use the handle, with or without @', () {
      expect(
          gymFeedProfileShareUrl('alex_fit'), 'https://gymfeed.io/u/alex_fit');
      expect(
          gymFeedProfileShareUrl('@alex_fit'), 'https://gymfeed.io/u/alex_fit');
    });

    testWidgets('iOS always gets a non-empty rectangle for the share sheet',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late BuildContext button;
      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: Builder(builder: (context) {
            button = context;
            return const SizedBox(width: 100, height: 40);
          }),
        ),
      ));

      expect(shareSheetOrigin(button), const Rect.fromLTWH(145, 402, 100, 40));
      final fallback = shareSheetOrigin();
      expect(fallback.isEmpty, isFalse);
      expect(const Rect.fromLTWH(0, 0, 390, 844).contains(fallback.center),
          isTrue);
    });

    testWidgets('the sheet shows a QR code for the profile link',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ProfileShareSheet(username: 'alex_fit', displayName: 'Alex'),
        ),
      ));
      await tester.pump();

      expect(find.byKey(const ValueKey('profile-qr-code')), findsOneWidget);
      expect(find.text('@alex_fit'), findsOneWidget);
      expect(find.text('Share link'), findsOneWidget);
      expect(find.text('Copy link'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
