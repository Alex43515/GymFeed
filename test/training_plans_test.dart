import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_feed/backend/supabase/repositories/training_plan_repository.dart';
import 'package:gym_feed/workout/plans/add_plan_to_train_widget.dart';
import 'package:gym_feed/workout/plans/training_plan_models.dart';
import 'package:gym_feed/workout/plans/training_plan_schedule.dart';
import 'package:gym_feed/workout/plans/training_plan_service.dart';
import 'package:gym_feed/workout/routines/workout_routine_models.dart';
import 'package:gym_feed/workout/routines/workout_routine_store.dart';

TrainingPlanDay workout(int day, String title) => TrainingPlanDay(
      day: day,
      title: title,
      exercises: const [
        RoutineExercise(name: 'Squat', setCount: 3, defaultWeightKg: 60),
      ],
    );

TrainingPlan plan({String id = 'p1', int version = 1}) => TrainingPlan(
      id: id,
      sellerId: 'seller',
      title: 'Leg Focus',
      dayCount: 5,
      version: version,
      status: 'published',
      days: [
        workout(1, 'Legs A'),
        const TrainingPlanDay(day: 2, isRest: true),
        workout(3, 'Legs B'),
        workout(4, 'Legs C'),
        workout(5, 'Legs D'),
      ],
    );

class FakePlanRepository extends TrainingPlanRepository {
  FakePlanRepository({this.enrollments = const []});

  final List<TrainingPlanEnrollment> enrollments;
  final enrolled = <String>[];
  final left = <String>[];

  @override
  Future<void> enroll({
    required TrainingPlan plan,
    required DateTime startDate,
    required PlanScheduleMode mode,
    Set<int> weekdays = const {},
  }) async =>
      enrolled.add('${plan.id}:${WorkoutRoutineStore.dateKey(startDate)}:${mode.name}');

  @override
  Future<void> leave(String planId) async => left.add(planId);

  @override
  Future<List<TrainingPlanEnrollment>> activeEnrollments() async => enrollments;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('scheduling', () {
    test('day by day puts plan day N on start + N - 1 and skips rest days', () {
      final dates = planWorkoutDates(
          days: plan().days, start: DateTime(2027, 1, 1, 18, 30));

      expect(dates.keys, [1, 3, 4, 5]);
      expect(dates[1], DateTime(2027, 1, 1));
      expect(dates[3], DateTime(2027, 1, 3));
      expect(dates[5], DateTime(2027, 1, 5));
    });

    test('training-days mode places workouts in order on the chosen weekdays', () {
      // 1 Jan 2027 is a Friday.
      final dates = planWorkoutDates(
        days: plan().days,
        start: DateTime(2027, 1, 1),
        mode: PlanScheduleMode.weekdays,
        weekdays: {DateTime.monday, DateTime.wednesday, DateTime.friday},
      );

      expect(dates[1], DateTime(2027, 1, 1));
      expect(dates[3], DateTime(2027, 1, 4));
      expect(dates[4], DateTime(2027, 1, 6));
      expect(dates[5], DateTime(2027, 1, 8));
    });

    test('scheduling crosses month and year boundaries', () {
      final dates = planWorkoutDates(
          days: plan().days, start: DateTime(2026, 12, 30));

      expect(dates[5], DateTime(2027, 1, 3));
    });

    test('import builds one routine per workout day and a calendar', () {
      final import = buildTrainingPlanImport(
          plan: plan(), start: DateTime(2027, 1, 1));

      expect(import.planKey, 'plan-p1');
      expect(import.routines.map((r) => r.id),
          ['plan-p1-v1-d1', 'plan-p1-v1-d3', 'plan-p1-v1-d4', 'plan-p1-v1-d5']);
      expect(import.routines.first.name, 'Legs A');
      expect(import.schedule['2027-01-03'], ['plan-p1-v1-d3']);
      expect(import.schedule.containsKey('2027-01-02'), isFalse);
      expect(isTrainingPlanRoutine(import.routines.first.id), isTrue);
    });

    test('sync key changes with version, start date and schedule style', () {
      String key(TrainingPlan p, DateTime start,
              [PlanScheduleMode mode = PlanScheduleMode.consecutive,
              Set<int> days = const {}]) =>
          buildTrainingPlanImport(
                  plan: p, start: start, mode: mode, weekdays: days)
              .syncKey;
      final base = key(plan(), DateTime(2027, 1, 1));

      expect(key(plan(), DateTime(2027, 1, 1)), base);
      expect(key(plan(version: 2), DateTime(2027, 1, 1)), isNot(base));
      expect(key(plan(), DateTime(2027, 1, 2)), isNot(base));
      expect(
          key(plan(), DateTime(2027, 1, 1), PlanScheduleMode.weekdays, {1, 3}),
          isNot(key(plan(), DateTime(2027, 1, 1), PlanScheduleMode.weekdays, {1, 5})));
    });
  });

  group('models', () {
    test('rows from Supabase parse into a plan with ordered days', () {
      final parsed = TrainingPlan.fromRow({
        'id': 'p9',
        'seller_id': 's1',
        'title': 'Upper Lower',
        'goal': 'strength',
        'day_count': 2,
        'status': 'in_review',
        'enrollment_count': 4,
        'seller': {'id': 's1', 'username': 'mia', 'display_name': ''},
        'days': [
          {'day': 2, 'kind': 'rest'},
          {
            'day': 1,
            'kind': 'workout',
            'title': 'Upper',
            'exercises': [
              {'name': 'Bench Press', 'setCount': 3, 'defaultWeightKg': 50, 'defaultReps': 8, 'setTargets': []}
            ],
          },
        ],
      });

      expect(parsed.days.map((d) => d.day), [1, 2]);
      expect(parsed.days.first.exercises.single.name, 'Bench Press');
      expect(parsed.days.last.isRest, isTrue);
      expect(parsed.seller!.label, '@mia');
      expect(parsed.goalLabel, 'Strength');
      expect(parsed.statusLabel, 'In review');
      expect(parsed.isFree, isTrue);
      expect(parsed.workoutDayCount, 1);
    });

    test('rest days are sent to the server without exercises', () {
      final json = const TrainingPlanDay(day: 2, isRest: true, title: 'Off')
          .toRpcJson();

      expect(json['kind'], 'rest');
      expect(json['exercises'], isEmpty);
      expect(workout(1, 'A').toRpcJson()['exercises'], hasLength(1));
    });
  });

  group('local calendar', () {
    test('adding a plan schedules it and rescheduling replaces upcoming days', () async {
      final service = TrainingPlanService(repository: FakePlanRepository());
      await service.addToTrain(plan: plan(), startDate: DateTime(2030, 1, 1));

      var schedule = await WorkoutRoutineStore.loadSchedule();
      expect(schedule['2030-01-01'], ['plan-p1-v1-d1']);

      await service.addToTrain(plan: plan(), startDate: DateTime(2030, 2, 1));
      schedule = await WorkoutRoutineStore.loadSchedule();
      expect(schedule.containsKey('2030-01-01'), isFalse);
      expect(schedule['2030-02-01'], ['plan-p1-v1-d1']);
      final routines = await WorkoutRoutineStore.loadRoutines();
      expect(routines.where((r) => r.id.startsWith('plan-p1-')), hasLength(4));
    });

    test('removing a plan keeps past days and the user\'s own workouts', () async {
      final repository = FakePlanRepository();
      final service = TrainingPlanService(repository: repository);
      final import = buildTrainingPlanImport(plan: plan(), start: DateTime(2027, 1, 1));
      await WorkoutRoutineStore.importPlan(
        planKey: import.planKey,
        syncKey: import.syncKey,
        routines: import.routines,
        schedule: import.schedule,
      );
      await WorkoutRoutineStore.scheduleRoutine(DateTime(2027, 1, 4), 'default-leg-day');

      await WorkoutRoutineStore.removePlan('plan-p1', today: DateTime(2027, 1, 3));
      await service.removeFromTrain('other');

      final schedule = await WorkoutRoutineStore.loadSchedule();
      expect(schedule['2027-01-01'], ['plan-p1-v1-d1']);
      expect(schedule.containsKey('2027-01-03'), isFalse);
      expect(schedule['2027-01-04'], ['default-leg-day']);
      final ids = (await WorkoutRoutineStore.loadRoutines()).map((r) => r.id);
      expect(ids, contains('plan-p1-v1-d1'));
      expect(ids, isNot(contains('plan-p1-v1-d4')));
      expect(repository.left, ['other']);
    });

    test('sync restores followed plans on a new device but never reshuffles existing ones', () async {
      final enrollment = TrainingPlanEnrollment(
        planId: 'p1',
        version: 1,
        startDate: DateTime(2030, 3, 2),
        plan: plan(),
      );
      final service = TrainingPlanService(
          repository: FakePlanRepository(enrollments: [enrollment]));

      expect(await service.syncEnrollments(), isTrue);
      expect((await WorkoutRoutineStore.loadSchedule())['2030-03-02'], ['plan-p1-v1-d1']);

      final updated = TrainingPlanService(
          repository: FakePlanRepository(enrollments: [
        TrainingPlanEnrollment(
            planId: 'p1', version: 2, startDate: DateTime(2030, 3, 2), plan: plan(version: 2)),
      ]));
      expect(await updated.syncEnrollments(), isFalse);
      expect((await WorkoutRoutineStore.loadSchedule())['2030-03-02'], ['plan-p1-v1-d1']);
    });
  });

  group('add to Train screen', () {
    Widget app(Widget child) => MaterialApp(home: child);

    testWidgets('previews the calendar and adds on the chosen training days', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      DateTime? start;
      PlanScheduleMode? mode;
      Set<int>? weekdays;

      await tester.pumpWidget(app(Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AddPlanToTrainWidget(
                plan: plan(),
                initialStart: DateTime(2027, 1, 1),
                onConfirm: (s, m, w) async {
                  start = s;
                  mode = m;
                  weekdays = w;
                },
              ),
            )),
            child: const Text('open'),
          ),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Add 4 workouts to my Train'), findsOneWidget);
      expect(find.text('Fri, Jan 1'), findsWidgets);
      expect(find.text('Sun, Jan 3'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('plan-mode-weekdays')));
      await tester.pumpAndSettle();
      expect(find.text('Mon, Jan 4'), findsOneWidget);
      expect(find.byKey(const ValueKey('plan-preview-day-2')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('plan-weekday-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-add-plan')));
      await tester.pumpAndSettle();

      expect(start, DateTime(2027, 1, 1));
      expect(mode, PlanScheduleMode.weekdays);
      expect(weekdays, {1, 5});
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('warns when plan days overlap workouts already in the calendar', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await WorkoutRoutineStore.scheduleRoutine(DateTime(2027, 1, 3), 'default-leg-day');

      await tester.pumpWidget(app(AddPlanToTrainWidget(
        plan: plan(),
        initialStart: DateTime(2027, 1, 1),
        onConfirm: (_, __, ___) async {},
      )));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('plan-conflict-warning')), findsOneWidget);
    });
  });
}
