import '/app_state.dart';
import '/backend/supabase/repositories/starter_plan_repository.dart';
import '/workout/routines/workout_routine_models.dart';
import '/workout/routines/workout_routine_store.dart';

class StarterPlanService {
  StarterPlanService({StarterPlanRepository? repository})
      : _repository = repository ?? StarterPlanRepository();

  final StarterPlanRepository _repository;
  static Future<StarterPlan?>? _ensureInFlight;
  static Future<StarterPlan>? _generationInFlight;

  Future<StarterPlan> generateForOnboarding(
    StarterPlanProfile profile, {
    DateTime? startDate,
    bool force = false,
  }) {
    // The signup screen may stop waiting and let the athlete verify their
    // email while the plan finishes. Keep one shared generation alive so a
    // landing-page retry cannot start a second expensive AI request.
    final running = _generationInFlight;
    if (running != null) return running;
    final future = _generateForOnboarding(
      profile,
      startDate: startDate,
      force: force,
    );
    _generationInFlight = future;
    return future.whenComplete(() {
      if (identical(_generationInFlight, future)) {
        _generationInFlight = null;
      }
    });
  }

  Future<StarterPlan> _generateForOnboarding(
    StarterPlanProfile profile, {
    DateTime? startDate,
    bool force = false,
  }) async {
    final plan = await _repository.requestAndGenerate(
      profile,
      startDate: startDate,
      force: force,
    );
    await syncWorkoutPlan(plan);
    return plan;
  }

  /// Retries only plans that were already requested during signup. Existing
  /// users are not silently enrolled in a paid AI generation.
  Future<StarterPlan?> ensureRequestedPlan() {
    final running = _ensureInFlight;
    if (running != null) return running;
    final future = _ensureRequestedPlan();
    _ensureInFlight = future;
    return future.whenComplete(() => _ensureInFlight = null);
  }

  Future<StarterPlan?> _ensureRequestedPlan() async {
    final existing = await _repository.load();
    if (existing == null) return null;
    if (existing.status == 'ready') {
      await syncWorkoutPlan(existing);
      return existing;
    }
    final profile = await _repository.loadCurrentProfile();
    if (profile == null) return existing;
    return generateForOnboarding(profile, startDate: existing.periodStart);
  }

  Future<bool> syncWorkoutPlan(StarterPlan plan) async {
    if (plan.status != 'ready' || plan.workouts.isEmpty) return false;
    final routines = <WorkoutRoutine>[];
    final schedule = <String, List<String>>{};
    for (final workout in plan.workouts) {
      final scheduledDate =
          plan.periodStart.add(Duration(days: workout.dayIndex));
      final routineId =
          'ai-${WorkoutRoutineStore.dateKey(plan.periodStart)}-${workout.id}';
      final exercises = workout.exercises
          .map((exercise) {
            final targets = exercise.sets
                .map((set) => RoutineSetTarget(
                      weightKg: set.weightKg,
                      reps: set.reps,
                    ))
                .toList();
            if (targets.isEmpty) return null;
            return RoutineExercise(
              name: exercise.name,
              setCount: targets.length,
              defaultWeightKg: targets.first.weightKg,
              defaultReps: targets.first.reps,
              setTargets: List<RoutineSetTarget>.unmodifiable(targets),
            );
          })
          .whereType<RoutineExercise>()
          .toList();
      if (exercises.isEmpty) continue;
      routines.add(WorkoutRoutine(
        id: routineId,
        name: workout.name,
        category: '${workout.category} · AI plan',
        exercises: exercises,
        createdAt: plan.generatedAt ?? plan.periodStart,
      ));
      schedule
          .putIfAbsent(WorkoutRoutineStore.dateKey(scheduledDate), () => [])
          .add(routineId);
    }
    return WorkoutRoutineStore.importStarterPlan(
      syncKey: plan.syncKey,
      routines: routines,
      schedule: schedule,
    );
  }
}

StarterPlanProfile starterPlanProfileFromOnboarding() {
  final state = FFAppState();
  final birthday = state.age2;
  final today = DateTime.now();
  final age = birthday == null
      ? 18
      : today.year -
          birthday.year -
          ((today.month < birthday.month ||
                  (today.month == birthday.month && today.day < birthday.day))
              ? 1
              : 0);
  return StarterPlanProfile(
    age: age,
    heightCm: state.height,
    weightKg: state.weight,
    gender: state.gender2,
    goal: state.goals,
    workoutLevel: state.workoutLevel,
    workoutsPerWeek: state.workouts,
    workoutLength: state.workoutLenght,
    workoutPeriod: state.workoutPeriod,
    workoutWhere: state.workoutWhere,
    mealsPerDay: state.meals,
    snacksPerDay: state.snacks,
    foodAllergies: state.foodAlergies,
  );
}
