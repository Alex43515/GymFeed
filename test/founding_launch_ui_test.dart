import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gym_feed/ai_workout/coach_events/coach_events_widget.dart';
import 'package:gym_feed/backend/share_links.dart';
import 'package:gym_feed/backend/supabase/repositories/founding_repository.dart';
import 'package:gym_feed/backend/supabase/repositories/training_repository.dart';
import 'package:gym_feed/components/founding_badge/founding_badge.dart';

Widget _app(Widget child) => MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(() => GoogleFonts.config.allowRuntimeFetching = true);

  group('Founding badge', () {
    test('numbers are shown with four digits', () {
      expect(formatFoundingNumber(1), '#0001');
      expect(formatFoundingNumber(142), '#0142');
      expect(formatFoundingNumber(1000), '#1000');
    });

    testWidgets('full badge shows the member number on a profile',
        (tester) async {
      FoundingRegistry.overrideForTesting({'user-142': 142});
      await tester.pumpWidget(_app(const FoundingBadge(userId: 'user-142')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('founding-badge-full')), findsOneWidget);
      expect(find.text('Founding Member #0142'), findsOneWidget);
    });

    testWidgets('compact badge is a small star next to a feed name',
        (tester) async {
      FoundingRegistry.overrideForTesting({'user-7': 7});
      await tester.pumpWidget(
          _app(const FoundingBadge(userId: 'user-7', compact: true)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('founding-badge-compact')), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.byTooltip('Founding Member #0007'), findsOneWidget);
    });

    testWidgets('non-founding users and empty ids show nothing',
        (tester) async {
      FoundingRegistry.overrideForTesting({'someone-else': 3});
      await tester.pumpWidget(_app(const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FoundingBadge(
            userId: 'regular-user',
            padding: EdgeInsets.only(top: 6),
          ),
          FoundingBadge(userId: '', compact: true),
        ],
      )));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('founding-badge-full')), findsNothing);
      expect(find.byKey(const Key('founding-badge-compact')), findsNothing);
      // Padding is applied only when the badge is visible.
      expect(
          tester.getSize(find.byType(FoundingBadge).first), const Size(0, 0));
    });

    test('feed posts, food posts and both profile views show the badge', () {
      for (final path in [
        'lib/pages/posts/post/post_widget.dart',
        'lib/pages/posts/post_food/post_food_widget.dart',
        'lib/pages/core_pages/profile/mobile_profile_view.dart',
        'lib/pages/core_pages/profile/desktop_profile_view.dart',
      ]) {
        expect(File(path).readAsStringSync(), contains('FoundingBadge('),
            reason: path);
      }
    });

    test('founding_members is public read and server-only write', () {
      final sql = File(
        'supabase/migrations/20261107180000_founding_members.sql',
      ).readAsStringSync();
      expect(sql, contains('enable row level security'));
      expect(sql, contains('for select'));
      expect(sql, contains('revoke insert, update, delete, truncate'));
      expect(sql, isNot(contains('for insert')));
      expect(sql, isNot(contains('for update')));
      expect(sql, contains('between 1 and 1000'));
    });
  });

  group('Empty screens', () {
    testWidgets('Events with no events invites the user to host the first',
        (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: CoachEventsWidget(
          trainingsLoader: () async => const <Training>[],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('events-empty-host-first')), findsOneWidget);
      expect(
          find.text(
              'No events near you yet. Founding members can host the first one.'),
          findsOneWidget);
      expect(find.byKey(const Key('events-empty-create-button')),
          findsOneWidget);
      expect(find.text('Create event'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Events that exist but do not match keep the filter message',
        (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: CoachEventsWidget(
          trainingsLoader: () async => [
            Training(const {
              'id': 'strength-1',
              'title': 'Heavy day',
              'category': 'Strength',
            }),
          ],
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('event-filter-Cardio')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('events-empty-host-first')), findsNothing);
      expect(find.text('No events match this filter.'), findsOneWidget);
    });

    test('own empty followers list invites a gym partner', () {
      final source = File(
        'lib/components/profile_follow_list/profile_follow_list_widget.dart',
      ).readAsStringSync();
      expect(
          source,
          contains(
              "You're early. Invite your gym partner while Founding spots last."));
      expect(source, contains('widget.userId == currentUserUid'));
      expect(source, contains('shareGymFeedInvite('));
      // Other people's empty lists keep the neutral label.
      expect(source, contains("'No followers yet'"));
    });

    test('empty notifications point to Suggested people in Explore', () {
      final source = File(
        'lib/pages/misc/notifications/notifications_widget.dart',
      ).readAsStringSync();
      expect(
          source,
          contains(
              'Nothing here yet. Follow a few people from Suggested and this fills up fast.'));
      expect(source, contains("queryParameters: {'tab': '1'}"));
      final nav = File('lib/flutter_flow/nav/nav.dart').readAsStringSync();
      expect(nav, matches(RegExp(r'ExplorePageWidget\(\s+initialTab:')));
    });

    test('invite text links to the store download page', () {
      final text = gymFeedInviteText(username: 'alexZ');
      expect(text, contains('https://gymfeed.io/download'));
      expect(text, contains('enter @alexZ under "Who invited you?"'));
      expect(text, contains('7 extra days of Premium'));
      expect(gymFeedInviteText(username: '@alexZ'), text);
      expect(text, contains('Founding'));
      expect(gymFeedInviteText(), isNot(contains('@')));
    });
  });
}
