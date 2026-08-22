import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_feed/backend/supabase/repositories/content_safety_repository.dart';
import 'package:gym_feed/backend/supabase/repositories/profile_repository.dart';
import 'package:gym_feed/components/content_safety/blocked_account_view.dart';
import 'package:gym_feed/components/content_safety/report_content_sheet.dart';

Widget _app(Widget child) => MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(body: child),
    );

void main() {
  group('complete content safety workflow', () {
    test('Supabase migration enforces blocks in both directions', () {
      final sql = File(
        'supabase/migrations/0027_content_safety_workflow.sql',
      ).readAsStringSync();

      expect(sql, contains('account_block_relationship'));
      expect(sql, contains('blocked_by_me'));
      expect(sql, contains('blocked_me'));
      expect(sql, contains('b.blocker_id = auth.uid()'));
      expect(sql, contains('b.blocker_id = p_account_id'));
      expect(sql, contains('delete from public.follows'));
      expect(sql, contains('delete from public.chat_members'));
      expect(sql, contains('posts readable without blocked accounts'));
      expect(sql, contains('comments readable without blocked accounts'));
      expect(sql, contains('p.allow_likes'));
      expect(sql, contains('p.allow_comments'));
      expect(sql, contains('notify visible recipient as actor'));
      expect(sql, contains('send message to visible chat members'));
    });

    test('reports are durable, categorized, and notify moderation securely',
        () {
      final sql = File(
        'supabase/migrations/0027_content_safety_workflow.sql',
      ).readAsStringSync();
      final repository = File(
        'lib/backend/supabase/repositories/content_safety_repository.dart',
      ).readAsStringSync();
      final relay = File(
        'website/public_html/report-mail.php',
      ).readAsStringSync();

      for (final field in [
        'reported_user_id',
        'content_type',
        'reason',
        'status',
        'metadata',
        'notified_at',
      ]) {
        expect(sql, contains(field));
      }
      expect(repository, contains("from('reports')"));
      expect(repository, contains('https://gymfeed.io/report-mail.php'));
      expect(repository, contains("'Authorization': 'Bearer \$accessToken'"));
      expect(relay, contains('/auth/v1/user'));
      expect(relay, contains('official@gymfeed.io'));
      expect(relay, contains('Too many reports. Try again later.'));
    });

    test('legacy Firestore block and report writes are gone', () {
      final blocked = File(
        'lib/components/blocked/blocked_widget.dart',
      ).readAsStringSync();
      final unblock = File(
        'lib/pages/misc/unblock_list/unblock_list_widget.dart',
      ).readAsStringSync();
      final reports = [
        'lib/components/report_status/report_status_widget.dart',
        'lib/components/report_status_food/report_status_food_widget.dart',
        'lib/components/report_status_reel/report_status_reel_widget.dart',
      ].map((path) => File(path).readAsStringSync()).join('\n');

      expect(blocked, contains('ProfileRepository().block(targetId)'));
      expect(blocked, isNot(contains("'user_blocked'")));
      expect(unblock, contains('ProfileRepository().blockedAccounts()'));
      expect(unblock, isNot(contains('currentUserDocument')));
      expect(reports, contains('ReportContentSheet'));
      expect(reports, isNot(contains('ReportsRecord.collection')));
    });

    test('direct profile and post routes enforce account visibility', () {
      final profile = File(
        'lib/pages/core_pages/profile_other/profile_other_widget.dart',
      ).readAsStringSync();
      final postRepo = File(
        'lib/backend/supabase/repositories/post_repository.dart',
      ).readAsStringSync();
      final profileRepo = File(
        'lib/backend/supabase/repositories/profile_repository.dart',
      ).readAsStringSync();

      expect(profile, contains('BlockedAccountView'));
      expect(profile, contains('blockRelationship'));
      expect(postRepo, contains('canViewAccount'));
      expect(profileRepo, contains('account_block_relationship'));
      expect(profileRepo, contains('_withoutBlocked'));
      expect(
        File('lib/pages/core_pages/explore_page/explore_page_widget.dart')
            .readAsStringSync(),
        isNot(contains('.userBlocked')),
      );
      expect(
        File('lib/pages/posts/post/post_widget.dart').readAsStringSync(),
        isNot(contains('.userBlocked')),
      );
      expect(
        File('lib/pages/posts/post_food/post_food_widget.dart')
            .readAsStringSync(),
        isNot(contains('.userBlocked')),
      );
    });

    testWidgets('blocked-by-me view offers recovery without exposing content',
        (tester) async {
      await tester.pumpWidget(_app(const BlockedAccountView(
        relationship: AccountBlockRelationship.blockedByMe,
        onBack: _noop,
      )));

      expect(find.text('You blocked this account'), findsOneWidget);
      expect(find.text('Unblock account'), findsOneWidget);
      expect(find.text('Posts'), findsNothing);
    });

    testWidgets('blocked-me view does not expose blocker identity',
        (tester) async {
      await tester.pumpWidget(_app(const BlockedAccountView(
        relationship: AccountBlockRelationship.blockedMe,
        onBack: _noop,
      )));

      expect(find.text('Profile unavailable'), findsOneWidget);
      expect(find.text('Go back'), findsOneWidget);
    });

    testWidgets('report sheet has private reasons and disables empty submit',
        (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(const ReportContentSheet(
        contentId: 'post-id',
        authorId: 'author-id',
        contentType: ReportedContentType.foodPost,
      )));

      expect(find.text('Report content'), findsOneWidget);
      expect(find.textContaining('food post'), findsOneWidget);
      expect(find.text('Spam or unwanted content'), findsOneWidget);
      final submit = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Submit report'),
      );
      expect(submit.onPressed, isNull);
    });
  });
}

void _noop() {}
