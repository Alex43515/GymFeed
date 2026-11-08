import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/ai_workout/coach_events/coach_events_widget.dart';
import '/ai_workout/coach_home/coach_home_widget.dart';
import '/ai_workout/coach_tools/coach_tools_widget.dart';
import '/backend/supabase/repositories/starter_plan_repository.dart';
import '/backend/supabase/supabase.dart';
import '/components/first_run/first_run_flow.dart';
import '/components/first_run/tour_anchor.dart';
import '/flutter_flow/nav/nav.dart' show appNavigatorKey;
import '/pages/core_pages/feed/feed_widget.dart';
import '/pages/core_pages/profile/profile_widget.dart';
import '/workout/training_home/training_home_widget.dart';

class BubbleTourStep {
  const BubbleTourStep({
    required this.anchor,
    this.route,
    required this.title,
    required this.body,
  });

  /// The [TourAnchor] id this step points at.
  final String anchor;

  /// Screen to open first; null stays on the current screen.
  final String? route;
  final String title;
  final String body;
}

enum BubbleTourResult { completed, skipped }

/// Guided tour on the real screens: dims the page, highlights one thing with
/// a bubble next to it, and walks from screen to screen. Premium comes first.
class BubbleTour {
  BubbleTour._();

  static const _prefix = 'gymfeed_bubble_tour_done_v1_';
  static bool _running = false;

  static const planAddedTipId = 'train_calendar';
  static const mealPlanTipId = 'meal_diary';
  static const _planAddedTitle = 'Your 28-day plan is on your calendar';
  static const _planAddedBody =
      "Every workout is on its own day. Tap a day here to see that day's session.";

  /// Shown on Train once the 28-day plan is ready.
  static const planAddedTip = [
    BubbleTourStep(
      anchor: 'train-calendar',
      title: _planAddedTitle,
      body: _planAddedBody,
    ),
  ];

  /// Shown the first time the Meal Diary has plan meals to point at.
  static const mealPlanTip = [
    BubbleTourStep(
      anchor: 'diary-plan',
      title: 'Your meal plan is here',
      body:
          'Every day of your 28-day plan shows its meals in this section. Use the arrows at the top to move between days.',
    ),
    BubbleTourStep(
      anchor: 'diary-plan-meal',
      title: 'How it works',
      body:
          "Tap a meal to see its nutrition and how to prepare it. Tap Log when you eat it, and it counts toward today's calories and macros.",
    ),
  ];

  static List<BubbleTourStep> steps({bool planReady = false}) => [
        BubbleTourStep(
          anchor: 'coach-premium',
          route: CoachHomeWidget.routeName,
          title: 'Premium comes first',
          body:
              'See how many Premium days you have left. While Premium is active, every AI tool on this page is unlocked.',
        ),
        BubbleTourStep(
          anchor: 'coach-invite',
          route: CoachHomeWidget.routeName,
          title: 'Get more Premium days',
          body:
              'Invite a friend and you both get 7 more days, up to 4 friends.',
        ),
        BubbleTourStep(
          anchor: 'coach-tool-trainer',
          route: CoachHomeWidget.routeName,
          title: 'Your AI coach',
          body:
              'Ask about training and food. It can build workouts and meal plans around your week.',
        ),
        BubbleTourStep(
          anchor: 'coach-tool-equipment',
          route: CoachHomeWidget.routeName,
          title: 'Scan any gym machine',
          body:
              'Point your camera at a machine to see what it is, which muscles it works and how to use it.',
        ),
        BubbleTourStep(
          anchor: 'coach-tool-body',
          route: CoachHomeWidget.routeName,
          title: 'Body scan',
          body: 'Get a full body composition report from a photo.',
        ),
        BubbleTourStep(
          anchor: 'coach-tool-food',
          route: CoachHomeWidget.routeName,
          title: 'Scan your food',
          body: 'Snap a meal to log its calories and macros.',
        ),
        BubbleTourStep(
          anchor: 'coach-diary',
          route: CoachHomeWidget.routeName,
          title: 'Meal diary',
          body: 'See your calories, macros and meal plan for every day.',
        ),
        BubbleTourStep(
          anchor: 'coach-progress',
          route: CoachHomeWidget.routeName,
          title: 'My progress and plans',
          body: 'Your custom plans, stats and monthly photos are all here.',
        ),
        BubbleTourStep(
          anchor: 'coach-health',
          route: CoachHomeWidget.routeName,
          title: 'Connect your smart watch',
          body: 'Bring in your steps and daily activity from your watch.',
        ),
        BubbleTourStep(
          anchor: 'train-calendar',
          route: TrainingHomeWidget.routeName,
          title: planReady ? _planAddedTitle : 'Your training calendar',
          body: planReady
              ? _planAddedBody
              : "Your workouts go on this calendar. Tap a day to see that day's session.",
        ),
        BubbleTourStep(
          anchor: 'train-plans',
          route: TrainingHomeWidget.routeName,
          title: 'Training plans marketplace',
          body:
              'Follow ready-made plans from the community. They schedule themselves on your calendar.',
        ),
        BubbleTourStep(
          anchor: 'events-page',
          route: CoachEventsWidget.routeName,
          title: 'Events',
          body:
              'Find workouts and events near you, join them, or create your own.',
        ),
        BubbleTourStep(
          anchor: 'feed-create',
          route: FeedWidget.routeName,
          title: 'Share your progress',
          body:
              'Post your workouts and meals. People who follow you see them first.',
        ),
        BubbleTourStep(
          anchor: 'profile-share',
          route: ProfileWidget.routeName,
          title: 'Your profile',
          body:
              'Share it with a link or a QR code. One scan opens it on any phone.',
        ),
      ];

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

  static String _currentUserId() {
    try {
      return supabase.auth.currentUser?.id ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<bool> _tipDone(String id, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('gymfeed_tip_${id}_v1_$userId') ?? false;
    } catch (_) {
      return true;
    }
  }

  static Future<void> _markTipDone(String id, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('gymfeed_tip_${id}_v1_$userId', true);
    } catch (_) {}
  }

  /// Shows a one-time explanation on the current screen. Waits its turn: it
  /// never appears before the tour is over or on top of another flow.
  static Future<void> showTipOnce(
      String id, List<BubbleTourStep> tipSteps) async {
    final userId = _currentUserId();
    if (kIsWeb || userId.isEmpty) return;
    if (!await isDone(userId) || await _tipDone(id, userId)) return;
    if (_running || FirstRunFlow.isRunning) return;
    final overlay = appNavigatorKey.currentState?.overlay;
    if (overlay == null) return;
    _running = true;
    try {
      await run(overlay: overlay, steps: tipSteps, open: (_) async {});
      await _markTipDone(id, userId);
    } finally {
      _running = false;
    }
  }

  /// Runs the tour once per account.
  static Future<void> maybeStart(String userId) async {
    if (_running || await isDone(userId)) return;
    final overlay = appNavigatorKey.currentState?.overlay;
    final context = appNavigatorKey.currentContext;
    if (overlay == null || context == null) return;
    final router = GoRouter.of(context);
    _running = true;
    try {
      var planReady = false;
      try {
        planReady = await StarterPlanRepository()
                .loadReady()
                .timeout(const Duration(seconds: 3)) !=
            null;
      } catch (_) {}
      final result = await run(
        overlay: overlay,
        steps: steps(planReady: planReady),
        open: (route) async => router.goNamed(route),
        finishLabel: 'Try the AI coach',
      );
      await markDone(userId);
      if (planReady) await _markTipDone(planAddedTipId, userId);
      if (result == BubbleTourResult.completed) {
        router.goNamed(CoachHomeWidget.routeName);
        unawaited(router.pushNamed(CoachTrainerWidget.routeName));
      }
    } finally {
      _running = false;
    }
  }

  /// Shows the steps above everything else. Public for widget tests.
  static Future<BubbleTourResult> run({
    required OverlayState overlay,
    required List<BubbleTourStep> steps,
    required Future<void> Function(String route) open,
    String finishLabel = 'Got it',
  }) {
    final done = Completer<BubbleTourResult>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _BubbleTourOverlay(
        steps: steps,
        open: open,
        finishLabel: finishLabel,
        onDone: (result) {
          entry.remove();
          done.complete(result);
        },
      ),
    );
    overlay.insert(entry);
    return done.future;
  }
}

class _BubbleTourOverlay extends StatefulWidget {
  const _BubbleTourOverlay({
    required this.steps,
    required this.open,
    required this.finishLabel,
    required this.onDone,
  });

  final List<BubbleTourStep> steps;
  final Future<void> Function(String route) open;
  final String finishLabel;
  final ValueChanged<BubbleTourResult> onDone;

  @override
  State<_BubbleTourOverlay> createState() => _BubbleTourOverlayState();
}

class _BubbleTourOverlayState extends State<_BubbleTourOverlay> {
  static const _green = Color(0xFF16E77D);
  static const _pageTransition = Duration(milliseconds: 450);
  static const _searchAttempts = 50;

  int _index = -1;
  Rect? _target;
  String? _route;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    unawaited(_show(0));
  }

  void _finish(BubbleTourResult result) {
    if (_finished) return;
    _finished = true;
    widget.onDone(result);
  }

  Future<void> _show(int index) async {
    if (index >= widget.steps.length) {
      _finish(BubbleTourResult.completed);
      return;
    }
    setState(() => _target = null);
    final step = widget.steps[index];
    final route = step.route;
    if (route != null && route != _route) {
      _route = route;
      await widget.open(route);
      await Future<void>.delayed(_pageTransition);
    }
    final rect = await _locate(step.anchor);
    if (!mounted || _finished) return;
    if (rect == null) {
      // Not on this account's screen, like Invite after all 4 invites.
      await _show(index + 1);
      return;
    }
    setState(() {
      _index = index;
      _target = rect;
    });
  }

  Future<Rect?> _locate(String id) async {
    for (var attempt = 0; attempt < _searchAttempts; attempt++) {
      if (!mounted || _finished) return null;
      final anchor = TourAnchor.find(id);
      if (anchor != null && anchor.mounted) {
        await Scrollable.ensureVisible(
          anchor,
          alignment: 0.35,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
        if (!mounted || !anchor.mounted) return null;
        final box = anchor.findRenderObject();
        final overlayBox = context.findRenderObject();
        if (box is RenderBox &&
            overlayBox is RenderBox &&
            box.attached &&
            box.hasSize &&
            !box.size.isEmpty) {
          return box.localToGlobal(Offset.zero, ancestor: overlayBox) &
              box.size;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return null;
  }

  Widget _bubble(BubbleTourStep step, bool last) {
    const ink = Color(0xFF101010);
    return Container(
      key: const Key('bubble-tour-bubble'),
      padding: const EdgeInsets.fromLTRB(18, 15, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.steps.length > 1) ...[
            Text(
              '${_index + 1} of ${widget.steps.length}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Color(0xFF777777),
              ),
            ),
            const SizedBox(height: 3),
          ],
          Text(
            step.title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              step.body,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13.5,
                height: 1.35,
                color: Color(0xFF333333),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                key: const Key('bubble-tour-skip'),
                onPressed: () => _finish(BubbleTourResult.skipped),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF777777),
                  ),
                ),
              ),
              Flexible(
                child: FilledButton(
                  key: const Key('bubble-tour-next'),
                  onPressed: () => unawaited(_show(_index + 1)),
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: ink,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      last ? widget.finishLabel : 'Next',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final target = _target;
    final hole = target?.inflate(6);
    final step = target == null ? null : widget.steps[_index];
    var bubbleBelow = true;
    if (hole != null) {
      final below = media.size.height - media.padding.bottom - hole.bottom;
      final above = hole.top - media.padding.top;
      bubbleBelow = below >= above;
    }
    return MediaQuery(
      data: media.copyWith(
        textScaler: media.textScaler.clamp(maxScaleFactor: 1.2),
      ),
      child: Material(
        key: const Key('bubble-tour'),
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: CustomPaint(painter: _ScrimPainter(hole)),
              ),
            ),
            if (hole != null && step != null) ...[
              Positioned(
                left: (hole.center.dx - 9).clamp(28.0, media.size.width - 46),
                top: bubbleBelow ? hole.bottom + 5 : null,
                bottom: bubbleBelow ? null : media.size.height - hole.top + 5,
                child: Transform.rotate(
                  angle: 0.785398,
                  child: Container(width: 18, height: 18, color: Colors.white),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: bubbleBelow ? hole.bottom + 13 : null,
                bottom: bubbleBelow ? null : media.size.height - hole.top + 13,
                child: _bubble(step, _index == widget.steps.length - 1),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScrimPainter extends CustomPainter {
  const _ScrimPainter(this.hole);

  final Rect? hole;

  static const _radius = Radius.circular(16);

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Path()..addRect(Offset.zero & size);
    final scrim = Paint()..color = const Color(0xC2000000);
    final rect = hole;
    if (rect == null) {
      canvas.drawPath(screen, scrim);
      return;
    }
    final highlight = RRect.fromRectAndRadius(rect, _radius);
    canvas.drawPath(
      Path.combine(
          PathOperation.difference, screen, Path()..addRRect(highlight)),
      scrim,
    );
    canvas.drawRRect(
      highlight,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF16E77D),
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter oldDelegate) => oldDelegate.hole != hole;
}
