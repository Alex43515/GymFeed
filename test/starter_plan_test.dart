import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_feed/ai_workout/starter_plan/starter_plan_service.dart';
import 'package:gym_feed/backend/supabase/repositories/starter_plan_repository.dart';
import 'package:gym_feed/workout/routines/workout_routine_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('workout frequency ranges use their lower weekly value', () {
    StarterPlanProfile profile(String workouts) => StarterPlanProfile(
          age: 29,
          heightCm: 180,
          weightKg: 82,
          gender: 'male',
          goal: 'muscle gain',
          workoutLevel: 'intermediate',
          workoutsPerWeek: workouts,
          workoutLength: '60 minutes',
          workoutPeriod: 'evening',
          workoutWhere: 'gym',
          mealsPerDay: '3-4',
          snacksPerDay: 1,
          foodAllergies: 'none',
        );

    expect(profile('1').minimumWorkoutsPerWeek, 1);
    expect(profile('3-4').minimumWorkoutsPerWeek, 3);
    expect(profile('5+').minimumWorkoutsPerWeek, 5);
  });

  test('allergy safety removes negated labels and rejects ingredients', () {
    final safe = sanitizeStarterPlanMealText(
      'Mixed nuts and dried fruit, no peanuts included.',
      'Peanuts',
    );
    expect(safe.toLowerCase(), isNot(contains('peanut')));
    expect(safe, contains('Mixed nuts and dried fruit'));

    expect(
      () => sanitizeStarterPlanMealText(
        'Whole-grain toast with peanut butter.',
        'Peanuts',
      ),
      throwsFormatException,
    );
  });

  test('ready starter plan materializes editable routines and calendar dates',
      () async {
    final plan = StarterPlan.fromRow({
      'user_id': 'user-1',
      'status': 'ready',
      'period_start': '2026-08-12',
      'period_end': '2026-09-08',
      'generated_at': '2026-08-12T10:00:00Z',
      'plan': {
        'nutrition_goals': {
          'calories': 2100,
          'protein_g': 160,
          'carbs_g': 230,
          'fat_g': 70,
        },
        'workouts': [
          {
            'id': 'starter-workout-0',
            'day_index': 0,
            'name': 'Upper strength',
            'category': 'Chest · Back',
            'estimated_minutes': 45,
            'exercises': [
              {
                'name': 'Bench Press',
                'sets': [
                  {'weight_kg': 50, 'reps': 10},
                  {'weight_kg': 55, 'reps': 8},
                ],
              },
            ],
          },
        ],
        'meals': [
          {
            'id': 'starter-meal-0-0',
            'day_index': 0,
            'meal_type': 'Breakfast',
            'name': 'Protein oats',
            'description': 'Mix oats, yogurt and berries.',
            'calories': 450,
            'protein_g': 32,
            'carbs_g': 55,
            'fat_g': 10,
          },
        ],
      },
    });

    expect(
        plan.mealsForDate(DateTime(2026, 8, 12)).single.name, 'Protein oats');
    expect(plan.mealsForDate(DateTime(2026, 9, 9)), isEmpty);

    final imported = await StarterPlanService().syncWorkoutPlan(plan);
    expect(imported, isTrue);
    final routines = await WorkoutRoutineStore.loadRoutines();
    final routine =
        routines.singleWhere((item) => item.name == 'Upper strength');
    expect(routine.exercises.single.setTargets, hasLength(2));
    expect(routine.exercises.single.setTargets.first.weightKg, 50);
    expect(routine.exercises.single.setTargets[1].reps, 8);
    final schedule = await WorkoutRoutineStore.loadSchedule();
    expect(schedule['2026-08-12'], contains(routine.id));

    expect(await StarterPlanService().syncWorkoutPlan(plan), isFalse);
  });
}
