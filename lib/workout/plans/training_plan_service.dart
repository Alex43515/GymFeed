import '/backend/supabase/repositories/training_plan_repository.dart';
import '/workout/routines/workout_routine_store.dart';

import 'training_plan_models.dart';
import 'training_plan_schedule.dart';

/// Keeps enrolled plans in the local Train calendar and the server in step.
class TrainingPlanService {
  TrainingPlanService({TrainingPlanRepository? repository})
      : _repository = repository ?? TrainingPlanRepository();

  final TrainingPlanRepository _repository;

  TrainingPlanRepository get repository => _repository;

  /// Schedules [plan] locally first so it works offline, then records the
  /// enrollment so the calendar can be rebuilt on another device.
  Future<TrainingPlanImport> addToTrain({
    required TrainingPlan plan,
    required DateTime startDate,
    PlanScheduleMode mode = PlanScheduleMode.consecutive,
    Set<int> weekdays = const {},
  }) async {
    final import = buildTrainingPlanImport(
        plan: plan, start: startDate, mode: mode, weekdays: weekdays);
    await WorkoutRoutineStore.importPlan(
      planKey: import.planKey,
      syncKey: import.syncKey,
      routines: import.routines,
      schedule: import.schedule,
      force: true,
    );
    await _repository.enroll(
        plan: plan, startDate: startDate, mode: mode, weekdays: weekdays);
    return import;
  }

  Future<void> removeFromTrain(String planId) async {
    await WorkoutRoutineStore.removePlan(trainingPlanKey(planId));
    await _repository.leave(planId);
  }

  /// Imports enrollments that are not on this device yet (new phone, reinstall).
  /// Plans already on the device are left alone: a seller's later edits never
  /// reshuffle someone's calendar until they add the plan again.
  /// Returns true when the local calendar changed.
  Future<bool> syncEnrollments() async {
    final enrollments = await _repository.activeEnrollments();
    final local = await WorkoutRoutineStore.loadPlanSyncKeys();
    var changed = false;
    for (final enrollment in enrollments) {
      if (local.containsKey(trainingPlanKey(enrollment.planId))) continue;
      final plan = enrollment.plan;
      // An unpublished plan returns no days; keep whatever is already local.
      if (plan == null || plan.days.isEmpty) continue;
      final import = buildTrainingPlanImport(
        plan: plan,
        start: enrollment.startDate,
        mode: enrollment.mode,
        weekdays: enrollment.weekdays,
      );
      changed = await WorkoutRoutineStore.importPlan(
            planKey: import.planKey,
            syncKey: import.syncKey,
            routines: import.routines,
            schedule: import.schedule,
          ) ||
          changed;
    }
    return changed;
  }
}
