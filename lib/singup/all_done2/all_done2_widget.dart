import 'dart:async';

import '/ai_workout/starter_plan/starter_plan_service.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/auth/supabase_auth/email_verification_service.dart';
import '/backend/supabase/repositories/profile_repository.dart';
import '/backend/supabase/supabase.dart';
import '/custom_code/widgets/upload_progress_screen.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';

import 'all_done2_model.dart';
export 'all_done2_model.dart';

const _background = Color(0xFF090909);
const _surface = Color(0xFF151515);
const _border = Color(0xFF292929);
const _green = Color(0xFF1FE276);
const _muted = Color(0xFF929292);

enum _PlanBuildState { preview, building, ready, deferred, error }

class AllDone2Widget extends StatefulWidget {
  const AllDone2Widget({
    super.key,
    this.completionRunner,
    this.verificationOpener,
    this.reviewOpener,
    this.generationTimeout = const Duration(minutes: 1),
  });

  static String routeName = 'allDone2';
  static String routePath = 'allDone2';

  /// Test seam for the account/profile/plan pipeline. A `true` result means
  /// the 28-day plan is ready; `false` means it will be retried in-app.
  final Future<bool> Function()? completionRunner;

  /// Test seam for the ready/deferred destination.
  final VoidCallback? verificationOpener;

  /// Test seam for returning to the questionnaire after invalid generation.
  final VoidCallback? reviewOpener;
  final Duration generationTimeout;

  @override
  State<AllDone2Widget> createState() => _AllDone2WidgetState();
}

class _AllDone2WidgetState extends State<AllDone2Widget> {
  late AllDone2Model _model;
  _PlanBuildState _state = _PlanBuildState.preview;
  Timer? _stepTimer;
  int _generationStep = 0;
  bool _accountReady = false;

  static const _generationSteps = <String>[
    'Reading your goals and preferences',
    'Building four weeks of workouts',
    'Setting your exercises, sets, reps and weights',
    'Preparing 28 days of meals and macro targets',
    'Adding everything to Coach and Train',
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AllDone2Model());
    _accountReady = currentUserUid.isNotEmpty && currentUserEmailVerified;
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _model.dispose();
    super.dispose();
  }

  TextStyle _text({
    double size = 14,
    Color color = Colors.white,
    FontWeight weight = FontWeight.w400,
    double height = 1.35,
  }) =>
      TextStyle(
        fontFamily: 'Poppins',
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
      );

  Future<bool> _completeSignupAndPlan() async {
    if (currentUserUid.isEmpty || !currentUserEmailVerified) {
      throw StateError(
          'A verified GymFeed account is required before plan generation.');
    }

    final liveMetadata = Map<String, dynamic>.from(
        supabase.auth.currentUser?.userMetadata ?? const {});
    await supabase.auth.updateUser(UserAttributes(data: {
      ...liveMetadata,
      ...signupMetadataFromOnboarding(),
    }));

    String photoUrl = FFAppState().profileImage;
    final profileBytes = FFAppState().signupProfileBytes;
    if (profileBytes != null && profileBytes.isNotEmpty) {
      final upload = await showUploadProgress(
        context,
        imageBytes: profileBytes,
        imageFileName: 'profile.jpg',
      );
      photoUrl = upload?.imageUrl ?? '';
    }

    await ProfileRepository().updatePublicProfile(
      username: FFAppState().signupUsername,
      displayName: FFAppState().signupName,
      bio: FFAppState().bio,
      photoUrl: photoUrl.isEmpty ? null : photoUrl,
    );
    await ProfileRepository().updatePrivateProfile({
      'email': FFAppState().signupEmail,
      'workout_level': FFAppState().workoutLevel,
      'days': FFAppState().days,
      'snacks': FFAppState().snacks,
      'goals': FFAppState().goals,
      'workouts': FFAppState().workouts,
      'workout_length': FFAppState().workoutLenght,
      'workout_period': FFAppState().workoutPeriod,
      'workout_where': FFAppState().workoutWhere,
      'meals': FFAppState().meals,
      'food_alergies': FFAppState().foodAlergies,
      'height_cm': FFAppState().height,
      'weight_kg': FFAppState().weight,
      'gender2': FFAppState().gender2,
      if (FFAppState().age2 != null)
        'age2': dateTimeFormat('yyyy-MM-dd', FFAppState().age2!),
    });

    FFAppState().profileImage = photoUrl;
    FFAppState().signupProfileBytes = null;
    if (mounted) setState(() => _accountReady = true);

    final plan = await StarterPlanService().generateForOnboarding(
      starterPlanProfileFromOnboarding(),
    );
    return plan.status == 'ready';
  }

  Future<void> _startGeneration() async {
    if (_state == _PlanBuildState.building) return;
    setState(() {
      _state = _PlanBuildState.building;
      _generationStep = 0;
    });
    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _state != _PlanBuildState.building) return;
      if (_generationStep < _generationSteps.length - 1) {
        setState(() => _generationStep += 1);
      }
    });
    try {
      final runner =
          widget.completionRunner?.call() ?? _completeSignupAndPlan();
      late final bool ready;
      try {
        ready = await runner.timeout(widget.generationTimeout);
      } on TimeoutException {
        if (!mounted) return;
        _stepTimer?.cancel();
        setState(() {
          _state = (_accountReady || widget.completionRunner != null)
              ? _PlanBuildState.deferred
              : _PlanBuildState.error;
        });
        return;
      }
      if (!mounted) return;
      _stepTimer?.cancel();
      setState(() {
        _state = ready ? _PlanBuildState.ready : _PlanBuildState.deferred;
      });
    } catch (error) {
      debugPrint('Signup completion failed: $error');
      if (!mounted) return;
      _stepTimer?.cancel();
      setState(() => _state = _PlanBuildState.error);
    }
  }

  void _continueAfterGeneration() {
    final callback = widget.verificationOpener;
    if (callback != null) {
      callback();
      return;
    }
    if (_state == _PlanBuildState.ready) {
      context.goNamed(StarterPlanReadyWidget.routeName);
    } else {
      context.goNamed(FeedWidget.routeName);
    }
  }

  void _reviewAnswers() {
    final callback = widget.reviewOpener;
    if (callback != null) {
      callback();
      return;
    }
    context.goNamed(AllMostDoneWidget.routeName);
  }

  Widget _brand() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: _background, size: 20),
          ),
          const SizedBox(width: 10),
          Text('GymFeed', style: _text(size: 21, weight: FontWeight.w700)),
        ],
      );

  Widget _planItem({
    required IconData icon,
    required String title,
    required String description,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF103523),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _green, size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _text(size: 14, weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(description,
                      style: _text(size: 11, color: _muted, height: 1.45)),
                ],
              ),
            ),
            const Icon(Icons.check_circle_rounded, color: _green, size: 19),
          ],
        ),
      );

  Widget _status() {
    switch (_state) {
      case _PlanBuildState.preview:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF121D16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF215F3B)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_open_rounded, color: _green, size: 18),
              const SizedBox(width: 9),
              Expanded(
                child: Text('Email verified — ready to build both plans',
                    style: _text(size: 11, color: const Color(0xFFD8F7E5))),
              ),
            ],
          ),
        );
      case _PlanBuildState.building:
        return Container(
          key: const ValueKey('starter-plan-building'),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF245F3D)),
          ),
          child: Column(
            children: [
              const SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(
                  color: _green,
                  strokeWidth: 4,
                  backgroundColor: Color(0xFF23422F),
                ),
              ),
              const SizedBox(height: 14),
              Text('Building your 28-day plan',
                  style: _text(size: 15, weight: FontWeight.w700)),
              const SizedBox(height: 5),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  _generationSteps[_generationStep],
                  key: ValueKey(_generationStep),
                  textAlign: TextAlign.center,
                  style: _text(size: 11, color: _muted),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                  _accountReady
                      ? 'If this takes longer than one minute, you can continue to Feed while we finish.'
                      : 'Checking your verified account before generation.',
                  textAlign: TextAlign.center,
                  style: _text(size: 10, color: const Color(0xFF666666))),
            ],
          ),
        );
      case _PlanBuildState.ready:
        return _resultStatus(
          key: const ValueKey('starter-plan-ready'),
          icon: Icons.check_circle_rounded,
          title: 'Your 28-day plan is ready',
          description:
              'Your workouts are in Train and meals are in Nutrition Diary.',
          color: _green,
        );
      case _PlanBuildState.deferred:
        return _resultStatus(
          key: const ValueKey('starter-plan-deferred'),
          icon: Icons.schedule_rounded,
          title: 'Your plan is finishing in the background',
          description:
              'This is taking longer than one minute. You can continue to Feed now while GymFeed finishes it for you.',
          color: const Color(0xFFFFB84D),
        );
      case _PlanBuildState.error:
        return _resultStatus(
          key: const ValueKey('starter-plan-error'),
          icon: Icons.fact_check_outlined,
          title: 'Let’s review your answers',
          description:
              'We could not build a valid meal and training plan from these answers. Review them, then regenerate both plans.',
          color: const Color(0xFFFF6B6B),
        );
    }
  }

  Widget _resultStatus({
    required Key key,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) =>
      Container(
        key: key,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: .55)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _text(size: 13, weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(description,
                      style: _text(size: 10, color: _muted, height: 1.45)),
                ],
              ),
            ),
          ],
        ),
      );

  String get _buttonText {
    switch (_state) {
      case _PlanBuildState.preview:
        return 'Create my 28-day plan';
      case _PlanBuildState.building:
        return _accountReady
            ? 'Continue — finish plan in background'
            : 'Building your plan…';
      case _PlanBuildState.ready:
        return 'View my 28-day plan';
      case _PlanBuildState.deferred:
        return 'Continue to Feed';
      case _PlanBuildState.error:
        return 'Review answers';
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue =
        _state == _PlanBuildState.ready || _state == _PlanBuildState.deferred;
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _brand(),
                    const SizedBox(height: 31),
                    Text('FINAL STEP',
                        textAlign: TextAlign.center,
                        style: _text(
                            size: 10, color: _green, weight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      'Your personalized\n28-day plan is next',
                      textAlign: TextAlign.center,
                      style: _text(
                          size: 29, weight: FontWeight.w700, height: 1.15),
                    ),
                    const SizedBox(height: 11),
                    Text(
                      'We’ll use your goal, experience, schedule, measurements and food preferences to build both plans.',
                      textAlign: TextAlign.center,
                      style: _text(size: 12, color: _muted, height: 1.5),
                    ),
                    const SizedBox(height: 25),
                    _planItem(
                      icon: Icons.fitness_center_rounded,
                      title: '4-week workout plan',
                      description:
                          'Dated sessions with exercises, sets, reps and starting weights in Train.',
                    ),
                    const SizedBox(height: 11),
                    _planItem(
                      icon: Icons.restaurant_menu_rounded,
                      title: '28-day meal plan',
                      description:
                          'Daily meals, calories and macro goals in your Nutrition Diary.',
                    ),
                    const SizedBox(height: 16),
                    _status(),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: const BoxDecoration(
                color: _background,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  key: const ValueKey('create-starter-plan'),
                  onPressed: canContinue
                      ? _continueAfterGeneration
                      : _state == _PlanBuildState.error
                          ? _reviewAnswers
                          : _state == _PlanBuildState.building
                              ? null
                              : _startGeneration,
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    disabledBackgroundColor: const Color(0xFF215F3B),
                    foregroundColor: _background,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text(
                    _buttonText,
                    style: _text(
                        size: 14, color: _background, weight: FontWeight.w700),
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
