import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_feed/backend/supabase/repositories/progress_repository.dart';
import 'package:gym_feed/workout/my_info/my_info_widget.dart';

void main() {
  void configurePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('progress page displays and edits overview and monthly data',
      (tester) async {
    configurePhone(tester);
    var overview = const ProgressOverview(
      weightKg: 80,
      bodyFatPercentage: 18,
      workoutsPerWeek: '5+',
      sessionLength: '40–50',
      workoutLevel: 'Advanced',
      workoutPlan: '4-day upper/lower split · updated weekly',
      mealPlan: '2,200 kcal · high-protein',
      trainerSuggestion:
          'You are 92% to your goal. Keep the current plan for two more weeks.',
    );
    var entries = <ProgressEntry>[
      ProgressEntry(
        id: 'march',
        month: DateTime(2026, 3),
        weightKg: 92,
        bodyFatPercentage: 26,
      ),
      ProgressEntry(
        id: 'june',
        month: DateTime(2026, 6),
        weightKg: 80,
        bodyFatPercentage: 18,
      ),
    ];
    ProgressOverview? savedOverview;
    ProgressEntry? savedEntry;
    var workoutPlanOpens = 0;
    var mealPlanOpens = 0;

    Future<ProgressData> load() async =>
        ProgressData(overview: overview, entries: entries);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.5),
          ),
          child: child!,
        ),
        home: MyInfoWidget(
          loader: load,
          overviewSaver: (value) async {
            savedOverview = value;
            overview = value;
          },
          entrySaver: (value) async {
            savedEntry = value;
            entries = [
              ...entries.where((item) => item.monthKey != value.monthKey),
              value,
            ];
            return value;
          },
          entryDeleter: (_) async {},
          workoutPlanOpener: () => workoutPlanOpens++,
          mealPlanOpener: () => mealPlanOpens++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Progress'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('progress-overview-card')), findsOneWidget);
    expect(find.text('Advanced'), findsOneWidget);
    expect(find.text('5+'), findsOneWidget);
    expect(find.text(overview.workoutPlan), findsNothing);
    expect(find.text(overview.mealPlan), findsNothing);
    final weightValue =
        tester.getRect(find.byKey(const ValueKey('progress-Weight-value')));
    final weightUnit =
        tester.getRect(find.byKey(const ValueKey('progress-Weight-unit')));
    final fatValue =
        tester.getRect(find.byKey(const ValueKey('progress-Body fat-value')));
    final fatUnit =
        tester.getRect(find.byKey(const ValueKey('progress-Body fat-unit')));
    expect(weightUnit.left - weightValue.right, lessThanOrEqualTo(6));
    expect(fatUnit.left - fatValue.right, lessThanOrEqualTo(6));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('progress-edit-overview')));
    await tester.pumpAndSettle();
    final overviewFields = find.byType(TextField);
    expect(overviewFields, findsNWidgets(7));
    await tester.enterText(overviewFields.at(0), '81.5');
    await tester.enterText(overviewFields.at(1), '17.5');
    await tester.tap(find.byKey(const ValueKey('progress-save-overview')));
    await tester.pumpAndSettle();
    expect(savedOverview?.weightKg, 81.5);
    expect(savedOverview?.bodyFatPercentage, 17.5);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('progress-workout-plan')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('progress-workout-plan')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('progress-meal-plan')));
    await tester.pump();
    expect(workoutPlanOpens, 1);
    expect(mealPlanOpens, 1);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('progress-month-2026-06')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('progress-month-2026-06')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-pick-photo')), findsOneWidget);
    final monthFields = find.byType(TextField);
    expect(monthFields, findsNWidgets(3));
    await tester.enterText(monthFields.at(0), '79.5');
    await tester.enterText(monthFields.at(1), '17');
    await tester.enterText(monthFields.at(2), 'Waist measurement improved');
    await tester.tap(find.byKey(const ValueKey('progress-save-month')));
    await tester.pumpAndSettle();

    expect(savedEntry?.weightKg, 79.5);
    expect(savedEntry?.bodyFatPercentage, 17);
    expect(savedEntry?.note, 'Waist measurement improved');
    expect(tester.takeException(), isNull);
  });
}
