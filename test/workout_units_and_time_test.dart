import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_feed/workout/routines/workout_routine_flow.dart';
import 'package:gym_feed/workout/routines/workout_routine_models.dart';
import 'package:gym_feed/workout/routines/workout_routine_store.dart';
import 'package:gym_feed/workout/routines/workout_unit_selector.dart';
import 'package:gym_feed/workout/routines/workout_units.dart';
import 'package:gym_feed/ai_workout/starter_plan/starter_plan_service.dart';
import 'package:gym_feed/backend/supabase/repositories/starter_plan_repository.dart';
import 'package:gym_feed/backend/supabase/repositories/ai_coach_repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  WorkoutRoutine routine(RoutineExercise exercise) => WorkoutRoutine(
      id: 'timed-routine',
      name: 'Mixed training',
      category: 'Custom',
      exercises: [exercise],
      createdAt: DateTime(2026, 10, 17));

  test('new users default to pounds and can persist kilograms', () async {
    expect(await WorkoutRoutineStore.loadWeightUnit(), WorkoutWeightUnit.lb);
    await WorkoutRoutineStore.saveWeightUnit(WorkoutWeightUnit.kg);
    expect(await WorkoutRoutineStore.loadWeightUnit(), WorkoutWeightUnit.kg);
  });

  test('unit changes preserve the original kilograms without rounding drift',
      () {
    final controller = WorkoutWeightController(62.5, WorkoutWeightUnit.lb);
    for (var i = 0; i < 10; i++) {
      expect(controller.kilograms, 62.5);
      controller.changeUnit(WorkoutWeightUnit.kg);
      expect(controller.text, '62.5');
      controller.changeUnit(WorkoutWeightUnit.lb);
    }
    controller.text = '135';
    expect(controller.kilograms, closeTo(61.23496995, 0.000001));
    controller.changeUnit(WorkoutWeightUnit.kg);
    expect(controller.kilograms, closeTo(61.23496995, 0.000001));
    controller.dispose();
  });

  test('editing invalid weight after a unit change uses the new unit', () {
    final controller = WorkoutWeightController(60, WorkoutWeightUnit.kg);
    controller.text = '';
    controller.changeUnit(WorkoutWeightUnit.lb);
    expect(controller.kilograms, isNull);
    controller.text = '60';
    expect(controller.kilograms, closeTo(27.2155422, 0.000001));
    controller.dispose();
  });

  test('timed sets round trip and never count as lifting volume', () {
    final legacy = RoutineExercise.fromJson(
        {'name': 'Squat', 'defaultWeightKg': 50, 'defaultReps': 8});
    expect(legacy.plannedSets.first.isTimed, isFalse);
    final timed = routine(const RoutineExercise(name: 'Plank', setTargets: [
      RoutineSetTarget(weightKg: 0, reps: 0, durationSeconds: 90),
    ]));
    final restored = WorkoutRoutine.fromJson(timed.toJson());
    expect(restored.exercises.single.plannedSets.single.durationSeconds, 90);
    final completed = CompletedSet.fromJson(const CompletedSet(
            weightKg: 10, reps: 100, completed: true, durationSeconds: 90)
        .toJson());
    expect(completed.volume, 0);
    expect(completed.durationSeconds, 90);
    expect(workoutDurationFromMinutes('0.5'), 30);
    expect(workoutDurationFromMinutes('1.5'), 90);
    expect(workoutDurationFromMinutes('NaN'), isNull);
    expect(workoutDurationFromMinutes('0'), isNull);
    expect(workoutDurationFromMinutes('-1'), isNull);
  });

  testWidgets('set editor saves minutes on a narrow screen with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    List<RoutineSetTarget>? result;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!),
      home: Builder(
          builder: (context) => Scaffold(
              body: TextButton(
                  onPressed: () async {
                    result = await Navigator.of(context)
                        .push<List<RoutineSetTarget>>(MaterialPageRoute(
                            builder: (_) => const RoutineSetEditorWidget(
                                    exerciseName: 'Plank',
                                    initialSets: [
                                      RoutineSetTarget(weightKg: 0, reps: 10)
                                    ])));
                  },
                  child: const Text('Edit')))),
    ));
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('routine-set-minutes-1')), '1.5');
    await tester.tap(find.byKey(const ValueKey('save-routine-sets')));
    await tester.pumpAndSettle();
    expect(result?.single.durationSeconds, 90);
    expect(result?.single.reps, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active timed values survive restart and are recorded in history',
      (tester) async {
    final plan = routine(const RoutineExercise(name: 'Plank', setTargets: [
      RoutineSetTarget(weightKg: 0, reps: 0, durationSeconds: 60)
    ]));
    await tester
        .pumpWidget(MaterialApp(home: ActiveWorkoutWidget(routine: plan)));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('active-set-minutes-Plank-1')), '1.5');
    await tester.tap(find.byKey(const ValueKey('complete-Plank-1')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester
        .pumpWidget(MaterialApp(home: ActiveWorkoutWidget(routine: plan)));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
        find.byKey(const ValueKey('active-set-minutes-Plank-1')));
    expect(field.controller?.text, '1.5');
    expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('complete-Plank-1')))
            .tooltip,
        'Set complete');
    await tester.tap(find.byKey(const ValueKey('finish-workout')));
    await tester.pumpAndSettle();
    final history = await WorkoutRoutineStore.loadHistory();
    expect(history.single.timedSeconds, 90);
    expect(history.single.totalVolume, 0);
    expect(history.single.exercises.single.sets.single.durationSeconds, 90);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('changing active kg to lb converts fields and saves canonical kg',
      (tester) async {
    await WorkoutRoutineStore.saveWeightUnit(WorkoutWeightUnit.kg);
    final plan = routine(const RoutineExercise(
        name: 'Bench Press',
        setTargets: [RoutineSetTarget(weightKg: 60, reps: 10)]));
    await tester
        .pumpWidget(MaterialApp(home: ActiveWorkoutWidget(routine: plan)));
    await tester.pumpAndSettle();
    final key = find.byKey(const ValueKey('active-set-weight-Bench Press-1'));
    expect(tester.widget<TextField>(key).controller?.text, '60');
    await tester.tap(find.text('lb'));
    await tester.pumpAndSettle();
    expect(double.parse(tester.widget<TextField>(key).controller!.text),
        closeTo(132.277, 0.001));
    await tester.enterText(key, '135');
    await tester.tap(find.byKey(const ValueKey('complete-Bench Press-1')));
    await tester.pumpAndSettle();
    final saved =
        await WorkoutRoutineStore.loadWorkoutProgress(plan.id, DateTime.now());
    expect(saved?.exercises.single.sets.single.weightKg,
        closeTo(61.23496995, 0.000001));
    expect(await WorkoutRoutineStore.loadWeightUnit(), WorkoutWeightUnit.lb);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('active mode switch validates minutes and clears completed reps',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final plan = routine(const RoutineExercise(
        name: 'Plank', setTargets: [RoutineSetTarget(weightKg: 0, reps: 10)]));
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: ActiveWorkoutWidget(routine: plan)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('complete-Plank-1')));
    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();
    final complete = find.byKey(const ValueKey('complete-Plank-1'));
    expect(tester.widget<IconButton>(complete).tooltip, 'Complete set');
    final minutes = find.byKey(const ValueKey('active-set-minutes-Plank-1'));
    await tester.enterText(minutes, '0');
    await tester.tap(complete);
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(complete).tooltip, 'Complete set');
    await tester.enterText(minutes, '0.5');
    await tester.tap(complete);
    await tester.pumpAndSettle();
    final saved =
        await WorkoutRoutineStore.loadWorkoutProgress(plan.id, DateTime.now());
    expect(saved?.exercises.single.sets.single.durationSeconds, 30);
    expect(saved?.timedSeconds, 30);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  test('timed starter sets import into Train without becoming repetitions',
      () async {
    final plan = StarterPlan.fromRow({
      'status': 'ready',
      'period_start': '2026-10-17',
      'period_end': '2026-11-13',
      'plan': {
        'workouts': [
          {
            'id': 'core',
            'day_index': 0,
            'name': 'Core',
            'exercises': [
              {
                'name': 'Plank',
                'sets': [
                  {'duration_seconds': 90}
                ]
              }
            ]
          }
        ]
      }
    });
    await StarterPlanService().syncWorkoutPlan(plan);
    final imported = (await WorkoutRoutineStore.loadRoutines())
        .singleWhere((routine) => routine.name == 'Core');
    expect(imported.exercises.single.plannedSets.single.durationSeconds, 90);
    expect(imported.exercises.single.plannedSets.single.reps, 0);
  });

  test('Coach preserves timed sets and honors pounds in saved-plan answers',
      () {
    final payload = {
      'assistant_text': 'Review this workout.',
      'action': {
        'type': 'schedule_workout',
        'requires_confirmation': true,
        'routine': {
          'name': 'Core',
          'exercises': [
            {
              'name': 'Plank',
              'sets': [
                {'duration_seconds': 90}
              ]
            },
            {
              'name': 'Squat',
              'sets': [
                {'weight_kg': 50, 'reps': 8}
              ]
            }
          ]
        }
      }
    };
    final reply = parseWorkoutActionResponse(jsonEncode(payload),
        scheduledDate: DateTime(2026, 10, 17));
    final plan = reply.proposal!.routine;
    expect(plan.exercises.first.plannedSets.single.durationSeconds, 90);
    final context = AiCoachContext(
        profile: const {},
        starterPlan: const {},
        currentRoutines: [plan.toJson()],
        workoutSchedule: buildAiCoachScheduleWindow(routines: [
          plan
        ], schedule: {
          '2026-10-17': [plan.id]
        }, history: const [], workoutsPerWeek: 3, now: DateTime(2026, 10, 17)),
        recentWorkouts: const [],
        recentMeals: const [],
        latestProgress: const {});
    expect(
        answerExactSavedPlanQuestion(
            context, 'How long is set 1 of Plank in Core?'),
        contains('1.5 min'));
    expect(
        answerExactSavedPlanQuestion(
            context, 'What weight is set 1 of Squat in Core?'),
        contains('110.231 lb'));
    final scheduled = answerScheduleAwareQuestion(
        context, 'What workout is scheduled today?',
        now: DateTime(2026, 10, 17));
    expect(scheduled?.text, contains('Plank: 1.5 min'));
    expect(scheduled?.text, contains('110.231 lb x 8'));
    final firstExercise =
        (((payload['action'] as Map)['routine'] as Map)['exercises'] as List)
            .first as Map;
    firstExercise['sets'] = [
      {'duration_seconds': 90},
      {'weight_kg': 0, 'reps': 10}
    ];
    expect(
        () => parseWorkoutActionResponse(jsonEncode(payload),
            scheduledDate: DateTime(2026, 10, 17)),
        throwsFormatException);
  });
}
