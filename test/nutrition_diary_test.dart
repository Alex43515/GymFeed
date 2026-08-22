import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_feed/ai_workout/nutrition_diary/nutrition_diary_widget.dart';
import 'package:gym_feed/backend/supabase/repositories/meal_repository.dart';
import 'package:gym_feed/backend/supabase/repositories/starter_plan_repository.dart';

void main() {
  void configurePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
      'nutrition diary shows real totals, changes dates, and saves goals',
      (tester) async {
    configurePhone(tester);
    final loadedDates = <DateTime>[];
    NutritionGoals? savedGoals;
    var scannerOpens = 0;
    final meals = [
      MealScan({
        'id': 'oats',
        'dish_name': 'Overnight oats',
        'description': 'Oats, berries and yoghurt',
        'calories': 340,
        'protein': 18,
        'carbs': 52,
        'fats': 9,
        'scanned_on': '2026-08-10T07:40:00Z',
        'gemini_parse': '{"meal_type":"Breakfast"}',
      }),
      MealScan({
        'id': 'shake',
        'dish_name': 'Whey shake + banana',
        'description': 'Whey and banana',
        'calories': 280,
        'protein': 32,
        'carbs': 30,
        'fats': 4,
        'scanned_on': '2026-08-10T10:15:00Z',
        'gemini_parse': '{"meal_type":"Snack"}',
      }),
    ];

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
          ),
          child: child!,
        ),
        home: NutritionDiaryWidget(
          initialDate: DateTime(2026, 8, 10),
          dayLoader: (date) async {
            loadedDates.add(date);
            return NutritionDay(
              meals: meals,
              goals: savedGoals ?? const NutritionGoals(),
            );
          },
          goalSaver: (goals) async => savedGoals = goals,
          mealDeleter: (_) async {},
          scannerOpener: (_, __) async => scannerOpens += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nutrition diary'), findsOneWidget);
    expect(find.text('620'), findsOneWidget);
    expect(find.text('Overnight oats'), findsOneWidget);
    expect(find.text('Whey shake + banana'), findsOneWidget);
    expect(find.text('50 / 165g'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nutrition-next-day')));
    await tester.pumpAndSettle();
    expect(loadedDates.last, DateTime(2026, 8, 11));

    await tester.tap(find.byKey(const ValueKey('edit-nutrition-goals')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('nutrition-goal-calories')),
        matching: find.byType(TextField),
      ),
      '2400',
    );
    await tester.tap(find.byKey(const ValueKey('save-nutrition-goals')));
    await tester.pumpAndSettle();
    expect(savedGoals?.calories, 2400);
    expect(find.text('2400'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nutrition-scan-meal')));
    await tester.pumpAndSettle();
    expect(scannerOpens, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('planned meals appear separately and can be logged',
      (tester) async {
    configurePhone(tester);
    const planned = StarterPlannedMeal(
      id: 'plan-breakfast',
      dayIndex: 0,
      mealType: 'Breakfast',
      name: 'Protein oats',
      description: 'Mix and chill overnight.',
      calories: 450,
      proteinG: 32,
      carbsG: 55,
      fatG: 10,
    );
    var logged = false;

    await tester.pumpWidget(MaterialApp(
      home: NutritionDiaryWidget(
        initialDate: DateTime(2026, 8, 12),
        dayLoader: (_) async => NutritionDay(
          meals: logged
              ? [
                  MealScan({
                    'id': 'logged-breakfast',
                    'dish_name': planned.name,
                    'calories': planned.calories,
                    'protein': planned.proteinG,
                    'carbs': planned.carbsG,
                    'fats': planned.fatG,
                    'scanned_on': '2026-08-12T08:00:00Z',
                    'gemini_parse':
                        '{"starter_plan_meal_id":"plan-breakfast","meal_type":"Breakfast"}',
                  }),
                ]
              : const [],
          goals: const NutritionGoals(),
          plannedMeals: const [planned],
        ),
        plannedMealLogger: (_, __) async => logged = true,
        scannerOpener: (_, __) async {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Wednesday meal plan'), findsOneWidget);
    expect(find.text('Protein oats'), findsOneWidget);
    expect(find.text('Log'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('log-planned-meal-plan-breakfast')));
    await tester.pumpAndSettle();
    expect(logged, isTrue);
    expect(find.text('Logged'), findsOneWidget);
    expect(find.text('450'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('planned meal card opens details and logs from recipe page',
      (tester) async {
    configurePhone(tester);
    const planned = StarterPlannedMeal(
      id: 'plan-parfait',
      dayIndex: 3,
      mealType: 'Breakfast',
      name: 'Greek yogurt parfait',
      description:
          'Layer Greek yogurt, berries and granola, then serve immediately.',
      calories: 400,
      proteinG: 30,
      carbsG: 50,
      fatG: 10,
    );
    var logged = false;

    await tester.pumpWidget(MaterialApp(
      home: NutritionDiaryWidget(
        initialDate: DateTime(2026, 8, 15),
        dayLoader: (_) async => NutritionDay(
          meals: logged
              ? [
                  MealScan({
                    'id': 'logged-parfait',
                    'dish_name': planned.name,
                    'calories': planned.calories,
                    'protein': planned.proteinG,
                    'carbs': planned.carbsG,
                    'fats': planned.fatG,
                    'scanned_on': '2026-08-15T08:00:00Z',
                    'gemini_parse':
                        '{"starter_plan_meal_id":"plan-parfait","meal_type":"Breakfast"}',
                  }),
                ]
              : const [],
          goals: const NutritionGoals(),
          plannedMeals: const [planned],
        ),
        plannedMealLogger: (_, __) async => logged = true,
      ),
    ));
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('open-planned-meal-plan-parfait')));
    await tester.pumpAndSettle();
    expect(find.text('Meal details'), findsOneWidget);
    expect(find.text('Greek yogurt parfait'), findsOneWidget);
    expect(find.text('How to prepare'), findsOneWidget);
    expect(
      find.text(
          'Layer Greek yogurt, berries and granola, then serve immediately.'),
      findsOneWidget,
    );
    expect(find.text('400'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('log-planned-meal-from-detail')));
    await tester.pumpAndSettle();
    expect(logged, isTrue);
    expect(find.text('Nutrition diary'), findsOneWidget);
    expect(find.text('Logged'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
