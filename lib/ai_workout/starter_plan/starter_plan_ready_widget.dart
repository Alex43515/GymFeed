import '/ai_workout/starter_plan/starter_plan_service.dart';
import '/backend/supabase/repositories/starter_plan_repository.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';

const _readyBg = Color(0xFF090909);
const _readySurface = Color(0xFF151515);
const _readyBorder = Color(0xFF292929);
const _readyGreen = Color(0xFF1FE276);
const _readyMuted = Color(0xFF929292);

class StarterPlanReadyWidget extends StatefulWidget {
  const StarterPlanReadyWidget({
    super.key,
    this.planLoader,
    this.workoutOpener,
    this.mealOpener,
    this.coachOpener,
  });

  static String routeName = 'starterPlanReady';
  static String routePath = 'starterPlanReady';

  final Future<StarterPlan?> Function()? planLoader;
  final VoidCallback? workoutOpener;
  final VoidCallback? mealOpener;
  final VoidCallback? coachOpener;

  @override
  State<StarterPlanReadyWidget> createState() => _StarterPlanReadyWidgetState();
}

class _StarterPlanReadyWidgetState extends State<StarterPlanReadyWidget> {
  StarterPlan? _plan;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final plan = await (widget.planLoader?.call() ??
          StarterPlanService().ensureRequestedPlan());
      if (!mounted) return;
      setState(() {
        _plan = plan?.status == 'ready' ? plan : null;
        _loading = false;
        if (_plan == null) {
          _error = 'Your plan is still being prepared. Tap retry in a moment.';
        }
      });
    } catch (error) {
      debugPrint('Starter plan landing failed to load: $error');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'We could not load your plan. Check your connection and retry.';
      });
    }
  }

  void _openWorkouts() {
    final callback = widget.workoutOpener;
    if (callback != null) {
      callback();
    } else {
      context.goNamed(TrainingHomeWidget.routeName);
    }
  }

  void _openMeals() {
    final callback = widget.mealOpener;
    if (callback != null) {
      callback();
    } else {
      context.goNamed(
        NutritionDiaryWidget.routeName,
        queryParameters: {
          'date': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  void _openCoach() {
    final callback = widget.coachOpener;
    if (callback != null) {
      callback();
    } else {
      context.goNamed(CoachHomeWidget.routeName);
    }
  }

  String _date(DateTime value) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[value.month - 1]} ${value.day}';
  }

  Widget _metric(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: _text(
                    size: 21, color: _readyGreen, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: _text(size: 9, color: _readyMuted)),
          ],
        ),
      );

  Widget _planCard({
    required Key key,
    required IconData icon,
    required String eyebrow,
    required String title,
    required String description,
    required String button,
    required VoidCallback onPressed,
    bool primary = false,
  }) =>
      Container(
        key: key,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: _readySurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: primary ? const Color(0xFF246440) : _readyBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF103523),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: _readyGreen, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(eyebrow.toUpperCase(),
                          style: _text(
                              size: 9,
                              color: _readyGreen,
                              weight: FontWeight.w700)),
                      Text(title,
                          style: _text(size: 15, weight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(description,
                style: _text(size: 11, color: _readyMuted, height: 1.5)),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: primary
                  ? FilledButton(
                      key: ValueKey('${key.toString()}-button'),
                      onPressed: onPressed,
                      style: FilledButton.styleFrom(
                        backgroundColor: _readyGreen,
                        foregroundColor: _readyBg,
                      ),
                      child: Text(button,
                          style: _text(
                              size: 12,
                              color: _readyBg,
                              weight: FontWeight.w700)),
                    )
                  : OutlinedButton(
                      key: ValueKey('${key.toString()}-button'),
                      onPressed: onPressed,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: _readyBorder),
                      ),
                      child: Text(button,
                          style: _text(size: 12, weight: FontWeight.w700)),
                    ),
            ),
          ],
        ),
      );

  Widget _loadingView() => Center(
        key: const ValueKey('starter-plan-ready-loading'),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: _readyGreen),
              const SizedBox(height: 20),
              Text('Opening your 28-day plan…',
                  textAlign: TextAlign.center,
                  style: _text(size: 16, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Syncing workouts and meals with Coach',
                  textAlign: TextAlign.center,
                  style: _text(size: 11, color: _readyMuted)),
            ],
          ),
        ),
      );

  Widget _errorView() => Center(
        key: const ValueKey('starter-plan-ready-error'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule_rounded,
                  color: Color(0xFFFFB84D), size: 52),
              const SizedBox(height: 16),
              Text('Your plan is almost ready',
                  textAlign: TextAlign.center,
                  style: _text(size: 22, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(_error ?? '',
                  textAlign: TextAlign.center,
                  style: _text(size: 12, color: _readyMuted)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  key: const ValueKey('retry-starter-plan-ready'),
                  onPressed: _load,
                  style: FilledButton.styleFrom(
                    backgroundColor: _readyGreen,
                    foregroundColor: _readyBg,
                  ),
                  child: const Text('Retry'),
                ),
              ),
              TextButton(
                onPressed: _openCoach,
                child: const Text('Go to Coach hub',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );

  Widget _readyView(StarterPlan plan) => SingleChildScrollView(
        key: const ValueKey('starter-plan-ready-content'),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: _readyGreen, size: 58),
            const SizedBox(height: 12),
            Text('Your 28-day plan is ready',
                textAlign: TextAlign.center,
                style: _text(size: 27, weight: FontWeight.w700)),
            const SizedBox(height: 7),
            Text(
              '${_date(plan.periodStart)} – ${_date(plan.periodEnd)} · Personalized from your signup answers',
              textAlign: TextAlign.center,
              style: _text(size: 11, color: _readyMuted),
            ),
            const SizedBox(height: 21),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 17),
              decoration: BoxDecoration(
                color: const Color(0xFF102019),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF225A3A)),
              ),
              child: Row(
                children: [
                  _metric('${plan.workouts.length}', 'workouts'),
                  Container(width: 1, height: 36, color: _readyBorder),
                  _metric('${plan.meals.length}', 'planned meals'),
                  Container(width: 1, height: 36, color: _readyBorder),
                  _metric('${plan.nutritionGoals.calories}', 'kcal goal'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _planCard(
              key: const ValueKey('open-workout-plan-card'),
              icon: Icons.fitness_center_rounded,
              eyebrow: 'Train calendar',
              title: 'Your workout plan',
              description:
                  'Every scheduled session includes exercises and editable sets, reps and starting weights.',
              button: 'Open workout plan',
              onPressed: _openWorkouts,
              primary: true,
            ),
            const SizedBox(height: 12),
            _planCard(
              key: const ValueKey('open-meal-plan-card'),
              icon: Icons.restaurant_menu_rounded,
              eyebrow: 'Nutrition diary',
              title: 'Your meal plan',
              description:
                  'See today’s planned meals, calories and macros, then log them directly into your diary.',
              button: 'Open meal plan',
              onPressed: _openMeals,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _openCoach,
              child: Text('Explore Coach hub',
                  style: _text(
                      size: 12, color: _readyGreen, weight: FontWeight.w700)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _readyBg,
        body: SafeArea(
          child: _loading
              ? _loadingView()
              : _plan == null
                  ? _errorView()
                  : _readyView(_plan!),
        ),
      );
}
