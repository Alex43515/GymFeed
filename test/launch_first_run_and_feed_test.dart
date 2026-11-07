import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_feed/backend/schema/posts_record.dart';
import 'package:gym_feed/components/first_run/first_run_flow.dart';
import 'package:gym_feed/pages/core_pages/feed/feed_sections.dart';

// ignore: subtype_of_sealed_class
class _Ref implements DocumentReference<Map<String, dynamic>> {
  _Ref(this.id);

  @override
  final String id;

  @override
  String get path => 'posts/$id';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PostsRecord _post(String id, String section) => PostsRecord.getDocumentFromData(
      {'feed_section': section},
      _Ref(id),
    );

Widget _host(Future<void> Function(BuildContext) onPressed) => MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              key: const Key('start'),
              onPressed: () => onPressed(context),
              child: const Text('start'),
            ),
          ),
        ),
      ),
    );

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(() => GoogleFonts.config.allowRuntimeFetching = true);

  group('Feed: following first, then Suggested', () {
    test('header appears once, where followed posts run out', () {
      final items = [
        _post('a', 'following'),
        _post('b', 'following'),
        _post('c', 'suggested'),
        _post('d', 'suggested'),
      ];
      expect(feedSectionHeaderFor(items, 0), FeedSectionHeader.none);
      expect(feedSectionHeaderFor(items, 1), FeedSectionHeader.none);
      expect(feedSectionHeaderFor(items, 2),
          FeedSectionHeader.caughtUpThenSuggested);
      expect(feedSectionHeaderFor(items, 3), FeedSectionHeader.none);
    });

    test('a feed with only suggested posts starts with "Suggested for you"',
        () {
      final items = [_post('a', 'suggested'), _post('b', 'suggested')];
      expect(feedSectionHeaderFor(items, 0), FeedSectionHeader.suggestedOnly);
      expect(feedSectionHeaderFor(items, 1), FeedSectionHeader.none);
    });

    test('posts without a section (old server) never show a header', () {
      final items = [_post('a', ''), _post('b', '')];
      expect(feedSectionHeaderFor(items, 0), FeedSectionHeader.none);
      expect(feedSectionHeaderFor(items, 1), FeedSectionHeader.none);
      expect(feedSectionHeaderFor(items, 5), FeedSectionHeader.none);
    });

    testWidgets('divider shows caught-up text and the Suggested title',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(children: const [
            FeedSectionDivider(
                header: FeedSectionHeader.caughtUpThenSuggested),
            FeedSectionDivider(header: FeedSectionHeader.suggestedOnly),
          ]),
        ),
      ));
      expect(find.text("You're all caught up"), findsOneWidget);
      expect(find.text('Suggested for you'), findsNWidgets(2));
      expect(find.byKey(const Key('feed-caught-up')), findsOneWidget);
    });

    test('feed rows carry the section and in-place refresh keeps it', () {
      final model =
          File('lib/backend/schema/posts_record.dart').readAsStringSync();
      expect(model, contains("data['feed_section'] = row['feed_section'];"));
      final feed = File('lib/pages/core_pages/feed/feed_widget.dart')
          .readAsStringSync();
      expect(feed, contains('feedSection: updatedItems[index].feedSection'));
      expect(feed, contains('FeedSectionDivider('));
      final sql = File(
        'supabase/migrations/20261107210000_feed_following_then_suggested.sql',
      ).readAsStringSync();
      expect(sql, contains("then 'following' else 'suggested'"));
      expect(sql, contains('order by p.section_rank, p.score desc'));
      expect(sql, contains('revoke all on function public.feed_page'));
    });
  });

  group('First run: Founding popup, permission, walkthrough', () {
    testWidgets('founding member sees their number and all perks',
        (tester) async {
      await tester.pumpWidget(_host((context) => showDialog(
            context: context,
            builder: (_) => const FoundingWelcomeDialog(
                status: FoundingStatus(number: 142, spotsLeft: 858)),
          )));
      await tester.tap(find.byKey(const Key('start')));
      await tester.pumpAndSettle();

      expect(find.text('Welcome, Founding Member #0142'), findsOneWidget);
      expect(find.text("You're one of the first 1,000 people on GymFeed."),
          findsOneWidget);
      expect(find.text('7 days of Premium, starting now'), findsOneWidget);
      expect(find.text('Founding badge on your profile, forever'),
          findsOneWidget);
      expect(find.text('Invite a friend'), findsOneWidget);
      expect(find.text("Let's go"), findsOneWidget);
    });

    testWidgets('after the first 1,000 the popup promises 3 days, no badge',
        (tester) async {
      await tester.pumpWidget(_host((context) => showDialog(
            context: context,
            builder: (_) =>
                const FoundingWelcomeDialog(status: FoundingStatus()),
          )));
      await tester.tap(find.byKey(const Key('start')));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to GymFeed'), findsOneWidget);
      expect(find.text('3 days of Premium, starting now'), findsOneWidget);
      expect(find.textContaining('Founding'), findsNothing);
    });

    testWidgets('full sequence: popup → permission → 3 screens → AI coach',
        (tester) async {
      var pushRequests = 0;
      FirstRunFlow.pushRegistrar = () async {
        pushRequests++;
        return true;
      };
      addTearDown(() => FirstRunFlow.pushRegistrar = () async => false);
      await tester.pumpWidget(_host((context) => FirstRunFlow.run(
            context,
            status: const FoundingStatus(number: 7, spotsLeft: 993),
          )));
      // Web/desktop test hosts skip the push step; force the mobile path.
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.tap(find.byKey(const Key('start')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('founding-welcome')), findsOneWidget);

      await tester.tap(find.byKey(const Key('founding-welcome-go')));
      await tester.pumpAndSettle();
      expect(find.text("We'll remind you before your Premium ends."),
          findsOneWidget);

      await tester.tap(find.byKey(const Key('notification-primer-allow')));
      await tester.pumpAndSettle();
      expect(pushRequests, 1);

      expect(find.byKey(const Key('first-run-walkthrough')), findsOneWidget);
      expect(find.text('AI coach'), findsOneWidget);
      await tester.tap(find.byKey(const Key('walkthrough-next')));
      await tester.pumpAndSettle();
      expect(find.text('Not sure how a machine works? Scan it.'),
          findsOneWidget);
      await tester.tap(find.byKey(const Key('walkthrough-next')));
      await tester.pumpAndSettle();
      expect(find.text('Training Plans'), findsOneWidget);
      expect(find.text('Try the AI coach'), findsOneWidget);
      expect(find.byKey(const Key('walkthrough-skip')), findsOneWidget);

      // The last button leads to the AI coach; the test host has no router,
      // so stop at the walkthrough result instead of navigating.
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('"Not now" skips the system prompt; Skip ends the walkthrough',
        (tester) async {
      var pushRequests = 0;
      FirstRunFlow.pushRegistrar = () async {
        pushRequests++;
        return true;
      };
      addTearDown(() => FirstRunFlow.pushRegistrar = () async => false);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      var finished = false;

      await tester.pumpWidget(_host((context) async {
        await FirstRunFlow.run(context,
            status: const FoundingStatus(number: 1, spotsLeft: 999));
        finished = true;
      }));
      await tester.tap(find.byKey(const Key('start')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('founding-welcome-go')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('notification-primer-later')));
      await tester.pumpAndSettle();
      expect(pushRequests, 0);

      await tester.tap(find.byKey(const Key('walkthrough-skip')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('first-run-walkthrough')), findsNothing);
      expect(finished, isTrue);
      debugDefaultTargetPlatformOverride = null;
    });

    test('runs once per account and defers the login push prompt', () async {
      SharedPreferences.setMockInitialValues({});
      var pushRequests = 0;
      FirstRunFlow.pushRegistrar = () async {
        pushRequests++;
        return true;
      };
      addTearDown(() => FirstRunFlow.pushRegistrar = () async => false);

      expect(await FirstRunFlow.isDone('new-user'), isFalse);
      await FirstRunFlow.registerPushUnlessDeferred('new-user');
      expect(pushRequests, 0, reason: 'new users are asked after the popup');

      await FirstRunFlow.markDone('new-user');
      expect(await FirstRunFlow.isDone('new-user'), isTrue);
      expect(await FirstRunFlow.isDone('someone-else'), isFalse);
      await FirstRunFlow.registerPushUnlessDeferred('new-user');
      expect(pushRequests, 1, reason: 'returning users refresh silently');
    });

    test('Home starts the flow and login no longer prompts directly', () {
      final feed = File('lib/pages/core_pages/feed/feed_widget.dart')
          .readAsStringSync();
      expect(feed, contains('FirstRunFlow.maybeStart(context)'));
      final main = File('lib/main.dart').readAsStringSync();
      expect(main, contains('FirstRunFlow.registerPushUnlessDeferred('));
      expect(main, isNot(contains('unawaited(registerCurrentDeviceForPush());')));
    });

    test('server assigns Founding numbers; clients cannot', () {
      final sql = File('supabase/migrations/20261107200000_founding_numbers.sql')
          .readAsStringSync();
      expect(sql, contains('pg_advisory_xact_lock'));
      expect(sql, contains('if next_number > 1000 then'));
      expect(sql, contains('founding_is_test_email'));
      expect(sql, contains('founding_exclusions'));
      expect(
          sql,
          contains('revoke all on function public.assign_founding_number(uuid) '
              'from public, anon, authenticated;'));
      expect(sql, contains('after insert or update of username on public.profiles'));
    });
  });
}
