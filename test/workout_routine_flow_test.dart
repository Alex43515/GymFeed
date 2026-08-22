import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_feed/workout/routines/workout_routine_flow.dart';
import 'package:gym_feed/workout/routines/workout_routine_models.dart';
import 'package:gym_feed/workout/routines/workout_routine_store.dart';
import 'package:gym_feed/workout/training_home/training_home_widget.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  void configurePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget phoneApp(Widget home) => MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
          ),
          child: child!,
        ),
        home: home,
      );

  test('an empty Train calendar stays empty instead of inventing Push Day A',
      () async {
    final schedule = await WorkoutRoutineStore.loadSchedule();

    expect(schedule, isEmpty);
  });

  test('legacy automatic Push Day A schedule seed is removed once', () async {
    SharedPreferences.setMockInitialValues({
      'gymfeed_workout_schedule_v1_guest':
          '{"2026-08-13":["default-push-day-a"]}',
    });

    final schedule = await WorkoutRoutineStore.loadSchedule();

    expect(schedule, isEmpty);
  });

  testWidgets('Train page shows design routines and has no floating add button',
      (tester) async {
    configurePhone(tester);

    await tester.pumpWidget(phoneApp(
      TrainingHomeWidget(trainingsLoader: () async => const []),
    ));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Push Day A'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Push Day A'), findsWidgets);
    final routines = await WorkoutRoutineStore.loadRoutines();
    expect(routines.map((item) => item.name),
        containsAll(const ['Push Day A', 'Pull Day B', 'Leg Day']));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('new-routine')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('new-routine')), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('routine builder adds an exercise and persists the new routine',
      (tester) async {
    configurePhone(tester);

    await tester.pumpWidget(phoneApp(Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const RoutineBuilderWidget(),
            )),
            child: const Text('Open builder'),
          ),
        ),
      ),
    )));

    await tester.tap(find.text('Open builder'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('routine-name')), 'Upper Power');
    await tester.tap(find.byKey(const ValueKey('add-routine-exercise')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('exercise-library-Bench Press')));
    await tester.pumpAndSettle();

    expect(find.text('Bench Press'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('increase-sets-Bench Press')));
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    expect(find.text('Set targets'), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('routine-set-weight-1')), '62.5');
    await tester.enterText(
        find.byKey(const ValueKey('routine-set-reps-1')), '8');
    await tester.enterText(
        find.byKey(const ValueKey('routine-set-weight-2')), '60');
    await tester.enterText(
        find.byKey(const ValueKey('routine-set-reps-2')), '10');
    await tester.tap(find.byKey(const ValueKey('save-routine-sets')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-routine-exercise')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('custom-exercise-name')), 'Sled March');
    await tester.tap(find.byKey(const ValueKey('add-custom-exercise')));
    await tester.pumpAndSettle();
    expect(find.text('Sled March'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('save-routine')));
    await tester.pumpAndSettle();

    final routines = await WorkoutRoutineStore.loadRoutines();
    final saved = routines.singleWhere((item) => item.name == 'Upper Power');
    expect(saved.exercises.map((item) => item.name),
        containsAll(const ['Bench Press', 'Sled March']));
    expect(saved.exercises.first.setCount, 4);
    expect(saved.exercises.first.setTargets, hasLength(4));
    expect(saved.exercises.first.setTargets.first.weightKg, 62.5);
    expect(saved.exercises.first.setTargets.first.reps, 8);
    expect(saved.exercises.first.setTargets[1].weightKg, 60);
    expect(saved.exercises.first.setTargets[1].reps, 10);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'calendar schedules and removes workouts on future and past dates',
      (tester) async {
    configurePhone(tester);
    await tester.pumpWidget(phoneApp(
      TrainingHomeWidget(trainingsLoader: () async => const []),
    ));
    await tester.pumpAndSettle();

    final today = DateTime.now();
    final monday = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
    final futureDate = monday.add(const Duration(days: 7));

    await tester.tap(find.byKey(const ValueKey('calendar-next-week')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('add-scheduled-workout-empty')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('add-scheduled-workout-empty')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('schedule-routine-default-pull-day-b')));
    await tester.pumpAndSettle();

    var schedule = await WorkoutRoutineStore.loadSchedule();
    expect(schedule[WorkoutRoutineStore.dateKey(futureDate)],
        contains('default-pull-day-b'));

    await tester
        .tap(find.byKey(const ValueKey('remove-scheduled-default-pull-day-b')));
    await tester.pumpAndSettle();
    schedule = await WorkoutRoutineStore.loadSchedule();
    expect(schedule[WorkoutRoutineStore.dateKey(futureDate)] ?? const [],
        isNot(contains('default-pull-day-b')));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('calendar-previous-week')),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('calendar-previous-week')));
    await tester.tap(find.byKey(const ValueKey('calendar-previous-week')));
    await tester.pumpAndSettle();
    final pastDate = monday.subtract(const Duration(days: 7));
    expect(
      find.byKey(
          ValueKey('calendar-date-${WorkoutRoutineStore.dateKey(pastDate)}')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('add-scheduled-workout-empty')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('add-scheduled-workout-empty')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('schedule-routine-default-push-day-a')));
    await tester.pumpAndSettle();
    schedule = await WorkoutRoutineStore.loadSchedule();
    expect(schedule[WorkoutRoutineStore.dateKey(pastDate)],
        contains('default-push-day-a'));
    await tester
        .tap(find.byKey(const ValueKey('remove-scheduled-default-push-day-a')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('active workout logs sets, runs rest controls, and saves history',
      (tester) async {
    configurePhone(tester);
    final routine = WorkoutRoutineStore.defaultRoutines().first;

    await tester.pumpWidget(phoneApp(ActiveWorkoutWidget(routine: routine)));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('complete-Bench Press-1')));
    await tester.pump();
    expect(find.text('REST'), findsOneWidget);
    expect(find.text('1:30'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('rest-plus-15')));
    await tester.pump();
    expect(find.text('1:45'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('skip-rest')));
    await tester.pump();
    expect(find.text('REST'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('finish-workout')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Workout complete'), findsOneWidget);

    final history = await WorkoutRoutineStore.loadHistory();
    expect(history, hasLength(1));
    expect(history.single.name, 'Push Day A');
    expect(history.single.setsDone, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved routine exercise opens its set editor and persists edits',
      (tester) async {
    configurePhone(tester);
    final routine = WorkoutRoutine(
      id: 'editable-routine',
      name: 'Editable routine',
      category: 'Custom',
      createdAt: DateTime(2026, 8, 12),
      exercises: const [
        RoutineExercise(name: 'Bench Press', setCount: 3),
      ],
    );
    await WorkoutRoutineStore.saveRoutine(routine);

    await tester.pumpWidget(phoneApp(RoutineDetailWidget(routine: routine)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();

    expect(find.text('Set targets'), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('routine-set-weight-1')), '75');
    await tester.enterText(
        find.byKey(const ValueKey('routine-set-reps-1')), '6');
    await tester.tap(find.byKey(const ValueKey('save-routine-sets')));
    await tester.pumpAndSettle();

    final saved = (await WorkoutRoutineStore.loadRoutines())
        .singleWhere((item) => item.id == routine.id);
    expect(saved.exercises.single.setTargets.first.weightKg, 75);
    expect(saved.exercises.single.setTargets.first.reps, 6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active workout prefills each saved set target', (tester) async {
    configurePhone(tester);
    final routine = WorkoutRoutine(
      id: 'target-routine',
      name: 'Target routine',
      category: 'Custom',
      createdAt: DateTime(2026, 8, 11),
      exercises: const [
        RoutineExercise(
          name: 'Bench Press',
          setCount: 2,
          defaultWeightKg: 62.5,
          defaultReps: 8,
          setTargets: [
            RoutineSetTarget(weightKg: 62.5, reps: 8),
            RoutineSetTarget(weightKg: 60, reps: 10),
          ],
        ),
      ],
    );

    await tester.pumpWidget(phoneApp(ActiveWorkoutWidget(routine: routine)));
    await tester.pump();

    TextField field(String key) =>
        tester.widget<TextField>(find.byKey(ValueKey(key)));
    expect(field('active-set-weight-Bench Press-1').controller?.text, '62.5');
    expect(field('active-set-reps-Bench Press-1').controller?.text, '8');
    expect(field('active-set-weight-Bench Press-2').controller?.text, '60');
    expect(field('active-set-reps-Bench Press-2').controller?.text, '10');

    await tester.tap(find.byKey(const ValueKey('delete-set-Bench Press-2')));
    await tester.pump();
    expect(
        find.byKey(const ValueKey('delete-set-Bench Press-2')), findsNothing);
    expect(find.text('1 sets'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
