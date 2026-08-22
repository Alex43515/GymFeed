import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_feed/ai_workout/starter_plan/starter_plan_ready_widget.dart';
import 'package:gym_feed/backend/supabase/repositories/starter_plan_repository.dart';
import 'package:gym_feed/singup/all_done2/all_done2_widget.dart';

void main() {
  void configurePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  StarterPlan readyPlan() => StarterPlan(
        userId: 'signup-user',
        status: 'ready',
        periodStart: DateTime(2026, 8, 17),
        periodEnd: DateTime(2026, 9, 13),
        workouts: List.generate(
          12,
          (index) => StarterPlanWorkout(
            id: 'workout-$index',
            dayIndex: index * 2,
            name: 'Workout ${index + 1}',
            category: 'Personalized',
            estimatedMinutes: 45,
            exercises: const [
              StarterPlanExercise(
                name: 'Squat',
                sets: [StarterPlanSet(weightKg: 60, reps: 8)],
              ),
            ],
          ),
        ),
        meals: List.generate(
          84,
          (index) => StarterPlannedMeal(
            id: 'meal-$index',
            dayIndex: index ~/ 3,
            mealType: const ['Breakfast', 'Lunch', 'Dinner'][index % 3],
            name: 'Meal ${index + 1}',
            description: 'Personalized meal',
            calories: 600,
            proteinG: 40,
            carbsG: 65,
            fatG: 18,
          ),
        ),
        nutritionGoals: const StarterNutritionGoals(
          calories: 2400,
          proteinG: 180,
          carbsG: 260,
          fatG: 70,
        ),
        generatedAt: DateTime(2026, 8, 16),
      );

  testWidgets(
      'final signup explains both 28-day plans and shows generation progress',
      (tester) async {
    configurePhone(tester);
    final result = Completer<bool>();
    var verificationOpened = false;

    await tester.pumpWidget(MaterialApp(
      home: AllDone2Widget(
        completionRunner: () => result.future,
        verificationOpener: () => verificationOpened = true,
      ),
    ));

    expect(find.textContaining('28-day plan is next'), findsOneWidget);
    expect(find.text('4-week workout plan'), findsOneWidget);
    expect(find.text('28-day meal plan'), findsOneWidget);
    expect(find.text('Create my 28-day plan'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('create-starter-plan')));
    await tester.pump();
    expect(find.byKey(const ValueKey('starter-plan-building')), findsOneWidget);
    expect(find.text('Building your 28-day plan'), findsOneWidget);

    result.complete(true);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('starter-plan-ready')), findsOneWidget);
    expect(find.text('Your 28-day plan is ready'), findsOneWidget);
    expect(find.text('View my 28-day plan'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('create-starter-plan')));
    expect(verificationOpened, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('generation fallback clearly says the plan will finish later',
      (tester) async {
    configurePhone(tester);

    await tester.pumpWidget(MaterialApp(
      home: AllDone2Widget(
        completionRunner: () async => false,
        verificationOpener: () {},
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('create-starter-plan')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('starter-plan-deferred')), findsOneWidget);
    expect(
        find.text('Your plan is finishing in the background'), findsOneWidget);
    expect(find.text('Continue to Feed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('generation timeout never leaves final signup spinning forever',
      (tester) async {
    configurePhone(tester);
    final neverCompletes = Completer<bool>();
    var verificationOpened = false;

    await tester.pumpWidget(MaterialApp(
      home: AllDone2Widget(
        completionRunner: () => neverCompletes.future,
        verificationOpener: () => verificationOpened = true,
        generationTimeout: const Duration(seconds: 2),
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('create-starter-plan')));
    await tester.pump();
    expect(find.byKey(const ValueKey('starter-plan-building')), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.byKey(const ValueKey('starter-plan-deferred')), findsOneWidget);
    expect(find.text('Continue to Feed'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('create-starter-plan')));
    expect(verificationOpened, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid generation sends the athlete back to review answers',
      (tester) async {
    configurePhone(tester);
    var reviewed = false;

    await tester.pumpWidget(MaterialApp(
      home: AllDone2Widget(
        completionRunner: () => Future<bool>.error(StateError('invalid plan')),
        reviewOpener: () => reviewed = true,
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('create-starter-plan')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('starter-plan-error')), findsOneWidget);
    expect(find.text('Let’s review your answers'), findsOneWidget);
    expect(find.text('We could not finish signup'), findsNothing);
    expect(find.text('Review answers'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('create-starter-plan')));
    expect(reviewed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ready landing opens workout and meal plan destinations',
      (tester) async {
    configurePhone(tester);
    var workoutOpened = false;
    var mealsOpened = false;
    var coachOpened = false;

    await tester.pumpWidget(MaterialApp(
      home: StarterPlanReadyWidget(
        planLoader: () async => readyPlan(),
        workoutOpener: () => workoutOpened = true,
        mealOpener: () => mealsOpened = true,
        coachOpener: () => coachOpened = true,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('starter-plan-ready-content')),
        findsOneWidget);
    expect(find.text('Your 28-day plan is ready'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('84'), findsOneWidget);
    expect(find.text('2400'), findsOneWidget);

    final workoutButton = find.text('Open workout plan');
    await tester.ensureVisible(workoutButton);
    await tester.tap(workoutButton);
    expect(workoutOpened, isTrue);

    final mealButton = find.text('Open meal plan');
    await tester.ensureVisible(mealButton);
    await tester.tap(mealButton);
    expect(mealsOpened, isTrue);

    final coachButton = find.text('Explore Coach hub');
    await tester.ensureVisible(coachButton);
    await tester.tap(coachButton);
    expect(coachOpened, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('plan landing retries when generation is still pending',
      (tester) async {
    configurePhone(tester);
    var loads = 0;

    await tester.pumpWidget(MaterialApp(
      home: StarterPlanReadyWidget(
        planLoader: () async {
          loads += 1;
          return loads == 1 ? null : readyPlan();
        },
      ),
    ));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('starter-plan-ready-error')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('retry-starter-plan-ready')));
    await tester.pumpAndSettle();
    expect(loads, 2);
    expect(find.byKey(const ValueKey('starter-plan-ready-content')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
