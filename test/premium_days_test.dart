import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_feed/ai_workout/premium/ai_usage_gate.dart';
import 'package:gym_feed/ai_workout/premium/invite_friends.dart';
import 'package:gym_feed/ai_workout/premium/premium_access.dart';
import 'package:gym_feed/app_state.dart';
import 'package:gym_feed/backend/share_links.dart';
import 'package:gym_feed/backend/supabase/repositories/notification_repository.dart';
import 'package:gym_feed/pages/misc/notifications/notifications_widget.dart';
import 'package:gym_feed/singup/onboarding/sign_up/sign_up_widget.dart';

void main() {
  group('PremiumStatus', () {
    test('free days count as premium and round up to whole days', () {
      final status = PremiumStatus.fromServer(const {
        'seconds_left': 6 * 86400 + 3600,
        'trial_days': 7,
        'invites_used': 2,
        'invites_max': 4,
        'invited_by': 'alice',
        'can_redeem_invite': true,
      }, paid: false);

      expect(status.isPremium, isTrue);
      expect(status.freeDaysActive, isTrue);
      expect(status.daysLeft, 7);
      expect(status.invitesLeft, 2);
      expect(status.canInvite, isTrue);
      expect(status.invitedBy, 'alice');
      expect(status.canRedeemInvite, isTrue);
      expect(status.freeDaysEnded, isFalse);
    });

    test('counts down from the server figure, not the device clock', () {
      final fetched = DateTime(2026, 12, 1, 9);
      final status = PremiumStatus.fromServer(const {'seconds_left': 3600},
          paid: false, now: fetched);

      expect(status.secondsLeftAt(fetched.add(const Duration(minutes: 30))),
          1800);
      expect(status.secondsLeftAt(fetched.add(const Duration(hours: 2))), 0);
    });

    test('ended free days are not premium unless the user pays', () {
      final ended =
          PremiumStatus.fromServer(const {'seconds_left': 0}, paid: false);
      expect(ended.isPremium, isFalse);
      expect(ended.freeDaysEnded, isTrue);
      expect(ended.daysLeft, 0);

      final paid =
          PremiumStatus.fromServer(const {'seconds_left': 0}, paid: true);
      expect(paid.isPremium, isTrue);
      expect(paid.freeDaysEnded, isFalse);
    });

    test('without the server only a paid plan is known', () {
      const unknown = PremiumStatus.paidOnly(false);
      expect(unknown.isPremium, isFalse);
      expect(unknown.serverKnown, isFalse);
      expect(unknown.freeDaysEnded, isFalse);
    });
  });

  group('PremiumAccess', () {
    test('combines RevenueCat and free days, and caches the result', () async {
      var serverCalls = 0;
      final access = PremiumAccess(
        userId: () => 'user-1',
        paidLoader: () async => false,
        statusLoader: () async {
          serverCalls++;
          return {'seconds_left': 86400};
        },
      );

      expect(await access.isPremium(), isTrue);
      expect(await access.isPremium(), isTrue);
      expect(serverCalls, 1);
      expect(await access.isPremium(refresh: true), isTrue);
      expect(serverCalls, 2);
    });

    test('a server failure still recognises paid users and is retried',
        () async {
      var serverCalls = 0;
      final access = PremiumAccess(
        userId: () => 'user-1',
        paidLoader: () async => true,
        statusLoader: () async {
          serverCalls++;
          throw Exception('offline');
        },
      );

      final status = await access.status();
      expect(status.isPremium, isTrue);
      expect(status.serverKnown, isFalse);
      await access.status();
      expect(serverCalls, 2);
    });

    test('signed-out users are never premium', () async {
      final access = PremiumAccess(
        userId: () => null,
        paidLoader: () async => true,
        statusLoader: () async => {'seconds_left': 86400},
      );
      expect(await access.isPremium(), isFalse);
    });

    test('the QA tester account is always paid', () async {
      final access = PremiumAccess(
        userId: () => 'a9fd1bc3-61a8-43a0-b96e-b6e7f0c6d060',
        paidLoader: () async => false,
        statusLoader: () async => {'seconds_left': 0},
      );
      expect(await access.hasPaidSubscription(), isTrue);
      expect(await access.isPremium(), isTrue);
    });

    test('redeemInvite strips @ and refreshes the cached status', () async {
      final redeemed = <String>[];
      var secondsLeft = 3600;
      final access = PremiumAccess(
        userId: () => 'user-1',
        paidLoader: () async => false,
        statusLoader: () async => {'seconds_left': secondsLeft},
        inviteRedeemer: (username) async {
          redeemed.add(username);
          secondsLeft += 7 * 86400;
          return {'ok': true, 'code': 'ok', 'inviter': 'Alice', 'bonus_days': 7};
        },
      );

      expect((await access.status()).daysLeft, 1);
      final result = await access.redeemInvite('  @Alice ');
      expect(result.ok, isTrue);
      expect(redeemed, ['Alice']);
      expect(result.message, contains('7 more days'));
      expect((await access.status()).daysLeft, 8);
    });

    test('redeemInvite maps server refusals and errors', () async {
      Future<InviteRedeemResult> redeem(Object response) => PremiumAccess(
            userId: () => 'user-1',
            paidLoader: () async => false,
            statusLoader: () async => const {},
            inviteRedeemer: (_) async {
              if (response is Exception) throw response;
              return Map<String, dynamic>.from(response as Map);
            },
          ).redeemInvite('bob');

      expect((await redeem({'ok': false, 'code': 'not_found'})).code,
          InviteRedeemCode.notFound);
      expect((await redeem({'ok': false, 'code': 'self'})).code,
          InviteRedeemCode.self);
      expect((await redeem({'ok': false, 'code': 'too_late'})).code,
          InviteRedeemCode.tooLate);
      expect(
          (await redeem({'ok': false, 'code': 'inviter_limit', 'inviter': 'bob'}))
              .message,
          '@bob already invited 4 friends.');
      expect((await redeem(Exception('offline'))).code, InviteRedeemCode.failed);

      final empty = await PremiumAccess(
        userId: () => 'user-1',
        inviteRedeemer: (_) async => throw StateError('must not be called'),
      ).redeemInvite(' @ ');
      expect(empty.code, InviteRedeemCode.empty);
    });
  });

  group('AiUsageGate', () {
    PremiumAccess access({required bool paid}) => PremiumAccess(
          userId: () => 'user-1',
          paidLoader: () async => paid,
          statusLoader: () async => {'seconds_left': 0},
        );

    test('allowed claims are counted so failures can be refunded', () async {
      bool? sentPaid;
      final gate = AiUsageGate(
        access: access(paid: true),
        claimer: (clientPaid) async {
          sentPaid = clientPaid;
          return {'allowed': true, 'reason': 'paid'};
        },
      );
      final decision = await gate.claimUse();
      expect(decision.allowed, isTrue);
      expect(decision.counted, isTrue);
      expect(sentPaid, isTrue);
    });

    test('daily limit and missing premium are refused differently', () async {
      final limited = await AiUsageGate(
        access: access(paid: false),
        claimer: (_) async => {'allowed': false, 'reason': 'daily_limit'},
      ).claimUse();
      expect(limited.result, AiUseResult.dailyLimit);

      final notPremium = await AiUsageGate(
        access: access(paid: false),
        claimer: (_) async => {'allowed': false, 'reason': 'not_premium'},
      ).claimUse();
      expect(notPremium.result, AiUseResult.exhausted);
    });

    test('a counting error never blocks a paying user', () async {
      final paid = await AiUsageGate(
        access: access(paid: true),
        claimer: (_) async => throw Exception('offline'),
      ).claimUse();
      expect(paid.allowed, isTrue);
      expect(paid.counted, isFalse);

      final unpaid = await AiUsageGate(
        access: access(paid: false),
        claimer: (_) async => throw Exception('offline'),
      ).claimUse();
      expect(unpaid.result, AiUseResult.unavailable);
    });

    test('refund failures are swallowed', () async {
      final gate = AiUsageGate(
        access: access(paid: false),
        refunder: () async => throw Exception('offline'),
      );
      await gate.refundUse();
    });
  });

  group('Invites', () {
    test('share text tells the friend which username to enter', () {
      final text = referralInviteText(username: '@alex_fit');
      expect(text, contains('@alex_fit'));
      expect(text, contains('Who invited you?'));
      expect(text, contains('7 extra days of Premium'));
      expect(text, contains('https://gymfeed.io/download'));
    });

    test('every invite button sends the referral text with the username', () {
      expect(gymFeedInviteText(username: 'alex_fit'),
          referralInviteText(username: 'alex_fit'));
      final popup =
          File('lib/components/first_run/first_run_flow.dart').readAsStringSync();
      expect(popup, contains('shareGymFeedInvite('));
      expect(popup, contains('currentUserDocument?.username'));
      final followers = File(
              'lib/components/profile_follow_list/profile_follow_list_widget.dart')
          .readAsStringSync();
      expect(followers, contains('username: username,'));
    });

    test('the Founding popup starts the free days', () {
      final popup =
          File('lib/components/first_run/first_run_flow.dart').readAsStringSync();
      expect(popup, contains('PremiumAccess.instance.status(refresh: true)'));
    });

    test('pending invite usernames are normalised', () {
      expect(PendingInvite.normalize('  @@alice '), 'alice');
      expect(PendingInvite.normalize(''), '');
    });

    testWidgets('signup offers an optional "Who invited you?" field',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      FFAppState.reset();
      await FFAppState().initializePersistedState();
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: SignUpWidget(usernameAvailabilityChecker: (_) async => true),
      ));
      await tester.pump();

      expect(find.byKey(const ValueKey('signup-invited-by')), findsOneWidget);
      expect(find.text('Who invited you? (optional)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the redeem sheet shows refusals and closes on success',
        (tester) async {
      InviteRedeemResult? closedWith;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                closedWith = await showRedeemInviteSheet(
                  context,
                  redeemer: (username) async => username == 'alice'
                      ? const InviteRedeemResult(InviteRedeemCode.ok,
                          inviter: 'alice')
                      : const InviteRedeemResult(InviteRedeemCode.notFound),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const ValueKey('redeem-invite-input')), 'nobody');
      await tester.tap(find.byKey(const ValueKey('redeem-invite-submit')));
      await tester.pumpAndSettle();
      expect(find.text('We could not find that username.'), findsOneWidget);

      await tester.enterText(
          find.byKey(const ValueKey('redeem-invite-input')), 'alice');
      await tester.tap(find.byKey(const ValueKey('redeem-invite-submit')));
      await tester.pumpAndSettle();
      expect(closedWith?.ok, isTrue);
      expect(find.byKey(const ValueKey('redeem-invite-input')), findsNothing);
    });
  });

  group('Premium reminder', () {
    test('server reminder items are recognised and explained', () {
      expect(
          NotificationsWidget.isPremiumReminder(
              AppNotification({'type': 'premium_reminder'})),
          isTrue);
      expect(
          NotificationsWidget.isPremiumReminder(
              AppNotification({'type': 'like'})),
          isFalse);
      expect(NotificationsWidget.premiumReminderText,
          contains('Invite a friend and you both get 7 more days.'));
    });

    test('tapping the reminder opens the Coach page', () {
      final source = File('lib/pages/misc/notifications/notifications_widget.dart')
          .readAsStringSync();
      expect(source, contains('context.goNamed(CoachHomeWidget.routeName)'));
    });
  });
}
