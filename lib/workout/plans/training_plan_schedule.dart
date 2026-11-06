import '/workout/routines/workout_routine_models.dart';
import '/workout/routines/workout_routine_store.dart';

import 'training_plan_models.dart';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Local routine ids of an enrolled plan all start with this key, so the plan
/// can be rescheduled or removed without touching the user's own routines.
String trainingPlanKey(String planId) => 'plan-$planId';

bool isTrainingPlanRoutine(String routineId) => routineId.startsWith('plan-');

/// Calendar date for every workout day of [plan]; rest days get no date.
///
/// consecutive: plan day N lands on start + (N - 1) days.
/// weekdays: workout days are placed in order on the chosen weekdays from
/// [start] onward, so a 4-workout plan on Mon/Wed/Fri finishes the next Monday.
Map<int, DateTime> planWorkoutDates({
  required List<TrainingPlanDay> days,
  required DateTime start,
  PlanScheduleMode mode = PlanScheduleMode.consecutive,
  Set<int> weekdays = const {},
}) {
  final first = _dateOnly(start);
  final workouts = days.where((day) => !day.isRest).toList()
    ..sort((a, b) => a.day.compareTo(b.day));
  final dates = <int, DateTime>{};
  if (mode == PlanScheduleMode.consecutive || weekdays.isEmpty) {
    for (final day in workouts) {
      dates[day.day] = DateTime(first.year, first.month, first.day + day.day - 1);
    }
    return dates;
  }
  var cursor = first;
  for (final day in workouts) {
    while (!weekdays.contains(cursor.weekday)) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
    }
    dates[day.day] = cursor;
    cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
  }
  return dates;
}

class TrainingPlanImport {
  const TrainingPlanImport({
    required this.planKey,
    required this.syncKey,
    required this.routines,
    required this.schedule,
    this.videos = const {},
  });

  final String planKey;

  /// Changes whenever the plan version or the chosen schedule changes.
  final String syncKey;
  final List<WorkoutRoutine> routines;
  final Map<String, List<String>> schedule;

  /// Exercise name → explanation video URL, for the "How to" button.
  final Map<String, String> videos;
}

TrainingPlanImport buildTrainingPlanImport({
  required TrainingPlan plan,
  required DateTime start,
  PlanScheduleMode mode = PlanScheduleMode.consecutive,
  Set<int> weekdays = const {},
}) {
  final planKey = trainingPlanKey(plan.id);
  final dates = planWorkoutDates(
      days: plan.days, start: start, mode: mode, weekdays: weekdays);
  final routines = <WorkoutRoutine>[];
  final schedule = <String, List<String>>{};
  for (final day in plan.days) {
    final date = dates[day.day];
    if (day.isRest || date == null || day.exercises.isEmpty) continue;
    final routineId = '$planKey-v${plan.version}-d${day.day}';
    routines.add(WorkoutRoutine(
      id: routineId,
      name: day.displayTitle,
      category: 'Plan · ${plan.title} · Day ${day.day}',
      exercises: List.unmodifiable(day.exercises),
      createdAt: _dateOnly(start),
    ));
    schedule
        .putIfAbsent(WorkoutRoutineStore.dateKey(date), () => <String>[])
        .add(routineId);
  }
  final sortedWeekdays = weekdays.toList()..sort();
  return TrainingPlanImport(
    planKey: planKey,
    syncKey: [
      plan.id,
      plan.version,
      WorkoutRoutineStore.dateKey(start),
      mode.name,
      if (mode == PlanScheduleMode.weekdays) sortedWeekdays.join(','),
    ].join(':'),
    routines: routines,
    schedule: schedule,
    videos: {
      for (final video in plan.videos.values)
        if (video.isPlayable) video.exerciseName: video.playbackUrl,
    },
  );
}
