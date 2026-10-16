import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_feed/workout/routines/workout_routine_flow.dart';
import 'package:gym_feed/workout/routines/workout_routine_models.dart';
import 'package:gym_feed/workout/routines/workout_routine_store.dart';

void main() {
  late DateTime now;
  late WorkoutRoutine routine;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 10, 16, 10);
    routine = WorkoutRoutine(
      id: 'chest-biceps',
      name: 'Chest and biceps',
      category: 'Strength',
      createdAt: now,
      exercises: const [
        RoutineExercise(name: 'Bench Press', setCount: 1),
        RoutineExercise(name: 'Bicep Curl', setCount: 1),
      ],
    );
  });

  Widget app(Widget child) => MaterialApp(home: child);
  Widget workout({Key? key}) => app(ActiveWorkoutWidget(
        key: key,
        routine: routine,
        now: () => now,
      ));

  String elapsed(WidgetTester tester) => tester
      .widget<Text>(find.byKey(const ValueKey('workout-elapsed-time')))
      .data!;

  Future<void> restart(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    final disk = {for (final key in prefs.getKeys()) key: prefs.get(key)!};
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    // Simulate OS termination: discard any writes made by widget.dispose,
    // then recreate the preference singleton/cache and the widget tree.
    SharedPreferences.setMockInitialValues(disk);
    await tester.pumpWidget(workout());
    await tester.pumpAndSettle();
  }

  testWidgets('saves the start before any sets are touched', (tester) async {
    await tester.pumpWidget(workout());
    await tester.pumpAndSettle();
    final saved = await WorkoutRoutineStore.loadWorkoutState(routine.id, now);
    expect(saved, isNotNull);
    expect(saved!.completed, false);
    expect(saved.workout.startedAt, now);
    expect(saved.workout.setsDone, 0);
    expect(await WorkoutRoutineStore.loadHistory(), isEmpty);
  });

  testWidgets('resume includes background time without timer ticks',
      (tester) async {
    await tester.pumpWidget(workout());
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(const Duration(minutes: 37, seconds: 12));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(elapsed(tester), '37:12');
    expect(tester.takeException(), isNull);
  });

  testWidgets('cold restart includes closed time and retains completed sets',
      (tester) async {
    await tester.pumpWidget(workout());
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('active-set-weight-Bench Press-1')), '75');
    await tester.tap(find.byKey(const ValueKey('complete-Bench Press-1')));
    await tester.pumpAndSettle();
    final saved = await WorkoutRoutineStore.loadWorkoutState(routine.id, now);
    now = now.add(const Duration(hours: 2, minutes: 3, seconds: 9));
    await restart(tester);
    expect(elapsed(tester), '123:09');
    final restored =
        await WorkoutRoutineStore.loadWorkoutState(routine.id, now);
    expect(restored!.workout.id, saved!.workout.id);
    expect(restored.workout.setsDone, 1);
    expect(restored.workout.exercises.first.sets.first.weightKg, 75);
  });

  testWidgets('untouched workout also survives restart and midnight',
      (tester) async {
    now = DateTime(2026, 10, 16, 23, 50);
    final start = now;
    await tester.pumpWidget(workout());
    await tester.pumpAndSettle();
    now = now.add(const Duration(minutes: 25));
    await restart(tester);
    expect(elapsed(tester), '25:00');
    final saved = await WorkoutRoutineStore.loadWorkoutState(routine.id, now);
    expect(saved!.workout.startedAt, start);
    expect(saved.completed, false);
  });

  testWidgets('reopening a finished workout never restarts its timer',
      (tester) async {
    await tester.pumpWidget(workout());
    await tester.pumpAndSettle();
    now = now.add(const Duration(minutes: 41, seconds: 8));
    // No timer tick before tapping Finish: capture the exact tap time.
    await tester.tap(find.byKey(const ValueKey('finish-workout')));
    await tester.pumpAndSettle();
    final history = await WorkoutRoutineStore.loadHistory();
    expect(history.single.durationSeconds, 2468);
    now = now.add(const Duration(hours: 3));
    await restart(tester);
    expect(elapsed(tester), '41:08');
    now = now.add(const Duration(minutes: 5));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 5));
    expect(elapsed(tester), '41:08');
    expect(
        (await WorkoutRoutineStore.loadWorkoutState(routine.id, now))!
            .completed,
        true);
    expect(await WorkoutRoutineStore.loadHistory(), hasLength(1));
  });

  testWidgets('removing an active exercise survives cold restart',
      (tester) async {
    await WorkoutRoutineStore.saveRoutine(routine);
    await tester.pumpWidget(workout());
    await tester.pumpAndSettle();
    now = now.add(const Duration(minutes: 10));
    await tester
        .tap(find.byKey(const ValueKey('remove-active-exercise-Bench Press')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-remove-exercise')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('active-exercise-Bench Press')),
        findsNothing);
    await restart(tester);
    expect(find.byKey(const ValueKey('active-exercise-Bench Press')),
        findsNothing);
    expect(find.byKey(const ValueKey('active-exercise-Bicep Curl')),
        findsOneWidget);
    expect(elapsed(tester), '10:00');
    final template = (await WorkoutRoutineStore.loadRoutines())
        .singleWhere((item) => item.id == routine.id);
    expect(
        template.exercises.map((e) => e.name), ['Bench Press', 'Bicep Curl']);
  });

  testWidgets('removing the last exercise remains empty after restart',
      (tester) async {
    await tester.pumpWidget(workout());
    await tester.pumpAndSettle();
    for (final name in ['Bench Press', 'Bicep Curl']) {
      await tester.tap(find.byKey(ValueKey('remove-active-exercise-$name')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-remove-exercise')));
      await tester.pumpAndSettle();
    }
    now = now.add(const Duration(minutes: 5));
    await restart(tester);
    expect(find.byKey(const ValueKey('active-exercise-Bench Press')),
        findsNothing);
    expect(
        find.byKey(const ValueKey('active-exercise-Bicep Curl')), findsNothing);
    expect(elapsed(tester), '5:00');
    expect(
        (await WorkoutRoutineStore.loadWorkoutState(routine.id, now))!
            .workout
            .exercises,
        isEmpty);
  });

  testWidgets('existing template supports removing a whole exercise',
      (tester) async {
    await WorkoutRoutineStore.saveRoutine(routine);
    await tester.pumpWidget(app(RoutineDetailWidget(routine: routine)));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('remove-detail-exercise-Bench Press')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-remove-exercise')));
    await tester.pumpAndSettle();
    final saved = (await WorkoutRoutineStore.loadRoutines())
        .singleWhere((item) => item.id == routine.id);
    expect(saved.id, routine.id);
    expect(saved.exercises.map((e) => e.name), ['Bicep Curl']);
    await tester.pumpWidget(app(
        RoutineDetailWidget(key: const ValueKey('reopen'), routine: saved)));
    await tester.pumpAndSettle();
    expect(find.text('Bench Press'), findsNothing);
    expect(find.text('Bicep Curl'), findsOneWidget);
  });

  testWidgets('canceling exercise removal preserves the workout',
      (tester) async {
    await tester.pumpWidget(workout());
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('remove-active-exercise-Bench Press')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('active-exercise-Bench Press')),
        findsOneWidget);
    expect(
        (await WorkoutRoutineStore.loadWorkoutState(routine.id, now))!
            .workout
            .exercises,
        hasLength(2));
  });

  test('template deletion updates an unfinished session without resetting it',
      () async {
    await WorkoutRoutineStore.saveRoutine(routine);
    final draft = WorkoutHistoryItem(
      id: 'unfinished-session',
      routineId: routine.id,
      name: routine.name,
      startedAt: now,
      durationSeconds: 123,
      exercises: const [
        CompletedExercise(
            name: 'Bench Press',
            sets: [CompletedSet(weightKg: 60, reps: 10, completed: true)]),
        CompletedExercise(
            name: 'Bicep Curl',
            sets: [CompletedSet(weightKg: 15, reps: 10, completed: false)]),
      ],
    );
    await WorkoutRoutineStore.saveWorkoutProgress(draft);
    await WorkoutRoutineStore.removeRoutineExercise(routine, 0);
    final saved = await WorkoutRoutineStore.loadWorkoutState(routine.id, now);
    expect(saved!.workout.id, draft.id);
    expect(saved.workout.startedAt, now);
    expect(saved.workout.durationSeconds, 123);
    expect(saved.workout.exercises.map((e) => e.name), ['Bicep Curl']);
  });

  test('a stale draft cannot revive a workout already saved by Finish',
      () async {
    final item = WorkoutHistoryItem(
        id: 'finished-session',
        routineId: routine.id,
        name: routine.name,
        startedAt: now,
        durationSeconds: 500,
        exercises: const []);
    await WorkoutRoutineStore.saveWorkoutProgress(item);
    await WorkoutRoutineStore.saveHistory(item);
    expect(
        (await WorkoutRoutineStore.loadWorkoutState(routine.id, now))!
            .completed,
        true);
  });

  test('a stale finished draft does not block the following day', () async {
    final item = WorkoutHistoryItem(
        id: 'finished-yesterday',
        routineId: routine.id,
        name: routine.name,
        startedAt: now,
        durationSeconds: 500,
        exercises: const []);
    await WorkoutRoutineStore.saveWorkoutProgress(item);
    await WorkoutRoutineStore.saveHistory(item);
    final tomorrow = now.add(const Duration(days: 1));
    expect(await WorkoutRoutineStore.loadWorkoutState(routine.id, tomorrow),
        isNull);
    expect(await WorkoutRoutineStore.loadWorkoutState(routine.id, tomorrow),
        isNull);
  });

  test('timestamps preserve the actual instant and support legacy local drafts',
      () {
    final item = WorkoutHistoryItem(
        id: 'codec',
        routineId: routine.id,
        name: routine.name,
        startedAt: now,
        durationSeconds: 0,
        exercises: const []);
    final json = item.toJson();
    expect((json['startedAt'] as String).endsWith('Z'), true);
    expect(WorkoutHistoryItem.fromJson(json).startedAt, now);
    json['startedAt'] = '2026-10-16T10:00:00.000';
    expect(WorkoutHistoryItem.fromJson(json).startedAt, now);
  });
}
