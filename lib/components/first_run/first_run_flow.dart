import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/ai_workout/premium/premium_access.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/backend/share_links.dart';
import '/backend/supabase/repositories/founding_repository.dart';
import '/backend/supabase/supabase.dart';
import '/components/first_run/bubble_tour.dart';
import '/flutter_flow/flutter_flow_util.dart';

const _green = Color(0xFF16E77D);
const _gold = Color(0xFFE8B339);
const _surface = Color(0xFF141414);
const _muted = Color(0xFF9AA0A6);

/// Founding number and remaining spots, from the `founding_status()` RPC.
class FoundingStatus {
  const FoundingStatus({this.number, this.spotsLeft = 0});

  final int? number;
  final int spotsLeft;

  bool get isFounding => number != null;
}

/// First time a user lands on Home after creating a profile:
/// Founding popup → notification permission → short walkthrough → AI coach.
///
/// Runs once per account per device. Push permission is deliberately not
/// requested at login until this flow has run, so the system dialog appears
/// right after the popup with an explanation instead of on a cold start.
class FirstRunFlow {
  FirstRunFlow._();

  static const _prefix = 'gymfeed_first_run_done_v1_';
  static bool _running = false;

  static bool get isRunning => _running;

  /// Overridable in tests.
  @visibleForTesting
  static Future<FoundingStatus> Function() statusLoader = _loadStatus;

  @visibleForTesting
  static Future<bool> Function() pushRegistrar = registerCurrentDeviceForPush;

  static Future<FoundingStatus> _loadStatus() async {
    final rows = await supabase.rpc('founding_status');
    final row = (rows is List && rows.isNotEmpty)
        ? rows.first as Map<String, dynamic>
        : const <String, dynamic>{};
    return FoundingStatus(
      number: (row['founding_number'] as num?)?.toInt(),
      spotsLeft: (row['spots_left'] as num?)?.toInt() ?? 0,
    );
  }

  static Future<bool> isDone(String userId) async {
    if (userId.isEmpty) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('$_prefix$userId') ?? false;
    } catch (_) {
      return true;
    }
  }

  static Future<void> markDone(String userId) async {
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_prefix$userId', true);
    } catch (_) {}
  }

  // True from the plan-generation screen until the athlete leaves the plan
  // summary. The metadata stage cannot tell: it says answers_complete both
  // during generation and long after.
  static bool _finishingRegistration = false;

  static void beginFinishingRegistration() => _finishingRegistration = true;

  /// Registration runs from the email step through plan generation. Nothing
  /// from this flow may appear before it ends, even though the Feed is built
  /// underneath every signup screen (they are nested routes of '/').
  static bool registrationOpen(String? onboardingStage) =>
      _finishingRegistration ||
      onboardingStage == 'awaiting_email' ||
      onboardingStage == 'questions';

  /// Called when registration is over and the athlete has landed in the app.
  static void startAfterRegistration() {
    _finishingRegistration = false;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final context = appNavigatorKey.currentContext;
      if (context != null) unawaited(maybeStart(context));
    });
  }

  static User? _currentUser() {
    try {
      return supabase.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Called at login. Returning users keep today's behaviour (silent token
  /// refresh); new users get the permission prompt from the flow instead.
  static Future<void> registerPushUnlessDeferred(String userId) async {
    if (!await isDone(userId)) return;
    await pushRegistrar();
  }

  /// Starts the flow from Home if this account has not seen it yet.
  static Future<void> maybeStart(BuildContext context) async {
    final user = _currentUser();
    final userId = user?.id ?? '';
    if (_running || userId.isEmpty) return;
    if (registrationOpen(
        user?.userMetadata?['gymfeed_onboarding_stage']?.toString())) {
      return;
    }
    _running = true;
    try {
      if (!await isDone(userId)) {
        // The popup says the free Premium days start now, so start them: the
        // first status request creates the server row (and queues the welcome
        // email).
        unawaited(PremiumAccess.instance.status(refresh: true));
        FoundingStatus status;
        try {
          status = await statusLoader();
        } catch (_) {
          status = const FoundingStatus();
        }
        if (!context.mounted) return;
        await run(context, status: status);
        await markDone(userId);
        unawaited(FoundingRegistry.instance.ensureLoaded(force: true));
      }
      if (!kIsWeb) await BubbleTour.maybeStart(userId);
    } finally {
      _running = false;
    }
  }

  /// The whole sequence. Public so it can be exercised in widget tests.
  static Future<void> run(
    BuildContext context, {
    required FoundingStatus status,
    bool askForPush = true,
  }) async {
    final choice = await showDialog<WelcomeChoice>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FoundingWelcomeDialog(status: status),
    );
    if (!context.mounted) return;
    if (choice == WelcomeChoice.invite) {
      // The friend needs this user's username for the +7 days referral.
      unawaited(shareGymFeedInvite(
        username: valueOrDefault(currentUserDocument?.username, ''),
      ));
    }

    if (askForPush && _canAskForPush) {
      final allow = await showModalBottomSheet<bool>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: _surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => const NotificationPrimerSheet(),
      );
      if (allow == true) unawaited(pushRegistrar());
      if (!context.mounted) return;
    }

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const FirstRunWalkthrough(),
      ),
    );
  }

  static bool get _canAskForPush =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);
}

enum WelcomeChoice { invite, go }

class FoundingWelcomeDialog extends StatelessWidget {
  const FoundingWelcomeDialog({super.key, required this.status});

  final FoundingStatus status;

  @override
  Widget build(BuildContext context) {
    final founding = status.isFounding;
    final perks = founding
        ? const [
            'Founding badge on your profile, forever',
            '7 days of Premium, starting now',
            '+7 more days for every friend you invite (up to 4)',
            'First access to everything we build',
            'A vote on what we build next',
            'More Founding perks as we grow',
          ]
        : const [
            '3 days of Premium, starting now',
            '+7 more days for every friend you invite (up to 4)',
          ];
    return Dialog(
      backgroundColor: _surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
        child: Column(
          key: const Key('founding-welcome'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: (founding ? _gold : _green).withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(
                founding ? Icons.star_rounded : Icons.waving_hand_rounded,
                color: founding ? _gold : _green,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              founding
                  ? 'Welcome, Founding Member ${formatFoundingNumber(status.number!)}'
                  : 'Welcome to GymFeed',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 21,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            if (founding) ...[
              const SizedBox(height: 6),
              const Text(
                "You're one of the first 1,000 people on GymFeed.",
                style: TextStyle(
                    color: _muted, fontFamily: 'Poppins', fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            for (final perk in perks)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(Icons.check_rounded, color: _green, size: 18),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        perk,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('founding-welcome-invite'),
                    onPressed: () =>
                        Navigator.of(context).pop(WelcomeChoice.invite),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0x55FFFFFF)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Invite a friend'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    key: const Key('founding-welcome-go'),
                    onPressed: () =>
                        Navigator.of(context).pop(WelcomeChoice.go),
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text("Let's go",
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Explains why we ask before the system permission dialog appears.
class NotificationPrimerSheet extends StatelessWidget {
  const NotificationPrimerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        key: const Key('notification-primer'),
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_active_rounded,
                color: _green, size: 40),
            const SizedBox(height: 14),
            const Text(
              "We'll remind you before your Premium ends.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Plus new followers, likes and event updates. No spam.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: _muted, fontFamily: 'Poppins', fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('notification-primer-allow'),
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Turn on notifications',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            TextButton(
              key: const Key('notification-primer-later'),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now', style: TextStyle(color: _muted)),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalkthroughPage {
  const _WalkthroughPage(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

const _walkthroughPages = [
  _WalkthroughPage(
    Icons.auto_awesome_rounded,
    'AI coach',
    'Tell the coach your goal and how much time you have. It builds your plan.',
  ),
  _WalkthroughPage(
    Icons.center_focus_strong_rounded,
    'Scan',
    'Not sure how a machine works? Scan it.',
  ),
  _WalkthroughPage(
    Icons.calendar_month_rounded,
    'Training Plans',
    'Follow a ready-made plan. It schedules itself in Train.',
  ),
];

/// Three short screens. "Skip" any time; the guided tour comes next.
/// Pops `true` when the user taps "Try the AI coach".
class FirstRunWalkthrough extends StatefulWidget {
  const FirstRunWalkthrough({super.key});

  @override
  State<FirstRunWalkthrough> createState() => _FirstRunWalkthroughState();
}

class _FirstRunWalkthroughState extends State<FirstRunWalkthrough> {
  final _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == _walkthroughPages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      Navigator.of(context).pop(true);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('first-run-walkthrough'),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('walkthrough-skip'),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Skip', style: TextStyle(color: _muted)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _walkthroughPages.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) {
                  final page = _walkthroughPages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page.icon, color: _green, size: 56),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFD0D3D6),
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _walkthroughPages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? _green : const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('walkthrough-next'),
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _isLast ? 'Show me around' : 'Next',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
