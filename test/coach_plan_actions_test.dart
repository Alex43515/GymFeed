import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_feed/ai_workout/coach_tools/coach_tools_widget.dart';
import 'package:gym_feed/ai_workout/premium/ai_usage_gate.dart';
import 'package:gym_feed/backend/supabase/repositories/ai_coach_repository.dart';
import 'package:gym_feed/backend/supabase/repositories/coach_plan_actions.dart';
import 'package:gym_feed/backend/supabase/repositories/coach_plan_repository.dart';
import 'package:gym_feed/backend/supabase/repositories/meal_repository.dart';
import 'package:gym_feed/backend/supabase/repositories/starter_plan_repository.dart';
import 'package:gym_feed/workout/routines/workout_routine_models.dart';
import 'package:gym_feed/workout/routines/workout_routine_store.dart';

const actionId = '684dcb81-7cd6-4115-8a79-d5e1c5e35901';
final today = DateTime(2026, 10, 12);

Map<String, dynamic> planJson({String intent = 'propose'}) => {
      'intent': intent,
      'assistant_text': 'Plan prepared.',
      'workouts': [
        {
          'date': '2026-10-13',
          'name': 'Upper body',
          'category': 'Strength',
          'exercises': [
            {
              'name': 'Push-up',
              'sets': [
                {'weight_kg': 0, 'reps': 10},
                {'weight_kg': 0, 'reps': 8}
              ],
            }
          ],
        }
      ],
      'meals': [
        for (final date in ['2026-10-13', '2026-10-14'])
          {
            'date': date,
            'meal_type': 'Lunch',
            'name': 'Rice bowl',
            'description':
                'Cook 80g rice and combine with 150g beans and vegetables.',
            'calories': 600,
            'protein_g': 25,
            'carbs_g': 90,
            'fat_g': 15,
          },
      ],
    };

CoachPlanAction prepared() => parseCoachPlanDecision(jsonEncode(planJson()),
        now: today, actionId: actionId)
    .proposal!;

class MemoryPlans extends CoachPlanRepository {
  CoachPlanAction? saved;
  var saves = 0;
  var implementations = 0;
  @override
  Future<CoachPlanAction> saveProposal(CoachPlanAction action) async {
    saves++;
    return saved = action;
  }

  @override
  Future<CoachPlanAction> implement(CoachPlanAction action) async {
    if (saved?.id == action.id && saved!.implemented) return saved!;
    implementations++;
    return saved = action.withStatus('implemented');
  }

  @override
  Future<CoachPlanAction> setStatus(String id, String status) async =>
      saved = saved!.withStatus(status);
  @override
  Future<List<StarterPlannedMeal>> mealsForDate(DateTime date) async => [
        if (saved?.implemented == true)
          for (final entry in saved!.meals)
            if (entry.date == date) entry.meal,
      ];
}

class EmptyStarter extends StarterPlanRepository {
  @override
  Future<List<StarterPlannedMeal>> mealsForDate(DateTime date) async => [];
}

class TestMeals extends MealRepository {
  TestMeals(CoachPlanRepository plans)
      : super(coachPlans: plans, starterPlans: EmptyStarter());
  @override
  Future<List<MealScan>> forDate(DateTime date) async => [];
  @override
  Future<NutritionGoals> loadGoals() async => const NutritionGoals();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('one proposal preserves exact dates, sets and distinct planned meals',
      () {
    final action = prepared();
    expect(action.workouts.single.date, DateTime(2026, 10, 13));
    expect(action.workouts.single.routine.exercises.single.setTargets.last.reps,
        8);
    expect(action.meals.map((item) => item.date),
        [DateTime(2026, 10, 13), DateTime(2026, 10, 14)]);
    expect(action.meals.map((item) => item.meal.id).toSet(), hasLength(2));
    expect(
        CoachPlanAction.fromRow({
          'id': action.id,
          'status': 'pending',
          'payload': action.toJson(),
        }).toJson(),
        action.toJson());
  });

  for (final mutate in <String, void Function(Map<String, dynamic>)>{
    'past date': (root) => root['meals'][0]['date'] = '2026-10-11',
    'invalid calendar day': (root) => root['meals'][0]['date'] = '2026-02-31',
    'negative macros': (root) => root['meals'][0]['protein_g'] = -5,
    'fractional reps': (root) =>
        root['workouts'][0]['exercises'][0]['sets'][0]['reps'] = 2.5,
    'empty sets': (root) => root['workouts'][0]['exercises'][0]['sets'] = [],
    'empty proposal': (root) {
      root['workouts'] = [];
      root['meals'] = [];
    },
    'confirmation with regenerated content': (root) =>
        root['intent'] = 'confirm',
  }.entries) {
    test('rejects ${mutate.key} before execution', () {
      final root =
          Map<String, dynamic>.from(jsonDecode(jsonEncode(planJson())));
      mutate.value(root);
      expect(() => parseCoachPlanDecision(jsonEncode(root), now: today),
          throwsFormatException);
    });
  }

  test('excluded ingredients are rejected before a meal proposal is saved', () {
    final root = planJson();
    root['meals'][0]['name'] = 'Peanut rice bowl';
    expect(
        () => parseCoachPlanDecision(jsonEncode(root),
            now: today, foodAllergies: 'Peanuts'),
        throwsFormatException);
  });

  test(
      'text confirmation executes the saved batch once without another proposal',
      () async {
    final plans = MemoryPlans();
    final action = prepared();
    await executeCoachPlanDecision(
        CoachPlanDecision('propose', '', proposal: action),
        plans: plans);
    final first = await executeCoachPlanDecision(
        const CoachPlanDecision('confirm', 'Confirm again?'),
        plans: plans,
        latestAction: action);
    final second = await executeCoachPlanDecision(
        const CoachPlanDecision('confirm', 'Confirm again?'),
        plans: plans,
        latestAction: first.action);
    expect(plans.saves, 1);
    expect(plans.implementations, 1);
    expect(first.action!.toJson(), action.toJson());
    expect(second.action!.toJson(), action.toJson());
    expect(first.text, contains('2 planned meals'));
    expect(first.text, isNot(contains('Confirm again')));
  });

  test(
      'approval of a prior text-only plan compiles and applies without a second prompt',
      () async {
    final decision = parseCoachPlanDecision(
        jsonEncode(planJson(intent: 'apply')),
        now: today,
        actionId: actionId);
    final plans = MemoryPlans();
    final reply = await executeCoachPlanDecision(decision, plans: plans);
    expect(plans.saves, 1);
    expect(plans.implementations, 1);
    expect(reply.action!.implemented, isTrue);
    expect(reply.text, startsWith('Added '));
  });

  test('confirmation cannot revive a skipped or superseded plan', () async {
    final plans = MemoryPlans();
    for (final status in ['skipped', 'superseded']) {
      final reply = await executeCoachPlanDecision(
          const CoachPlanDecision('confirm', ''),
          plans: plans,
          latestAction: prepared().withStatus(status));
      expect(reply.action, isNull);
      expect(plans.implementations, 0);
    }
  });

  test(
      'planned coach meals appear on their exact diary date without eaten totals',
      () async {
    final plans = MemoryPlans()..saved = prepared();
    final repository = TestMeals(plans);
    expect((await repository.loadDay(DateTime(2026, 10, 13))).plannedMeals,
        isEmpty);
    plans.saved = plans.saved!.withStatus('implemented');
    final day = await repository.loadDay(DateTime(2026, 10, 13));
    expect(day.plannedMeals.single.name, 'Rice bowl');
    expect(day.calories, 0);
    expect((await repository.loadDay(DateTime(2026, 10, 14))).plannedMeals,
        hasLength(1));
    expect((await repository.loadDay(DateTime(2026, 10, 15))).plannedMeals,
        isEmpty);
  });

  test(
      'cloud workout import retries without duplicates or overwriting user edits',
      () async {
    final action = prepared().withStatus('implemented');
    await CoachPlanRepository.materializeWorkouts(action);
    final original = action.workouts.single.routine;
    await WorkoutRoutineStore.saveRoutine(WorkoutRoutine(
      id: original.id,
      name: 'My edited session',
      category: original.category,
      exercises: original.exercises,
      createdAt: original.createdAt,
    ));
    await CoachPlanRepository.materializeWorkouts(action);
    final routines = await WorkoutRoutineStore.loadRoutines();
    expect(routines.where((item) => item.id == original.id), hasLength(1));
    expect(routines.singleWhere((item) => item.id == original.id).name,
        'My edited session');
    expect((await WorkoutRoutineStore.loadSchedule())['2026-10-13'],
        [original.id]);
  });

  test('invalid structured output is repaired once with the same request',
      () async {
    var calls = 0;
    final engine = CoachPlanAssistant(aiCall: (messages) async {
      calls++;
      if (calls == 1)
        return '{"intent":"propose","assistant_text":"Confirm?","workouts":[],"meals":[]}';
      expect(messages.last['content'], contains('No writes have occurred'));
      return jsonEncode(planJson());
    });
    final reply = await engine.respond(
        systemPrompt: 'Coach',
        history: [],
        question: 'Ubaci obroke i trening po danima',
        now: today);
    expect(calls, 2);
    expect(reply.proposal, isNotNull);
  });

  test('persisted action reference is hidden from chat text and attaches by id',
      () {
    final message = AiCoachMessage.fromRow({
      'id': 1,
      'role': 'assistant',
      'content': 'Ready.\n\n[[GYMFEED_PLAN_ACTION:$actionId]]',
    }).withPlanAction(prepared());
    expect(message.content, 'Ready.');
    expect(message.planActionId, actionId);
    expect(message.planAction!.pending, isTrue);
  });

  test(
      'confirmation without a saved payload is compiled internally, not asked again',
      () async {
    var calls = 0;
    final engine = CoachPlanAssistant(aiCall: (messages) async {
      calls++;
      if (calls == 1)
        return jsonEncode({
          'intent': 'confirm',
          'assistant_text': 'Confirmed.',
          'workouts': [],
          'meals': []
        });
      expect(
          messages.last['content'], contains('no persisted current proposal'));
      return jsonEncode(planJson(intent: 'apply'));
    });
    final decision = await engine.respond(
        systemPrompt: 'Coach',
        history: [
          {'role': 'assistant', 'content': 'A complete dated plan.'}
        ],
        question: 'Da, potvrđujem.',
        now: today);
    final plans = MemoryPlans();
    final result = await executeCoachPlanDecision(decision, plans: plans);
    expect(calls, 2);
    expect(plans.implementations, 1);
    expect(result.action!.implemented, isTrue);
    expect(result.text, startsWith('Added '));
  });

  test('user marker text and invalid references cannot create plan metadata',
      () {
    final literal = 'Test\n\n[[GYMFEED_PLAN_ACTION:$actionId]]';
    final user = AiCoachMessage.fromRow({'role': 'user', 'content': literal});
    expect(user.planActionId, isNull);
    expect(user.content, literal);
    final invalid = AiCoachMessage.fromRow({
      'role': 'assistant',
      'content': 'Test\n\n[[GYMFEED_PLAN_ACTION:invalid]]'
    });
    expect(invalid.planActionId, isNull);
  });

  test('recovered proposal does not duplicate the current question in AI input',
      () {
    const context = AiCoachContext(
        profile: {},
        starterPlan: {},
        currentRoutines: [],
        workoutSchedule: {},
        recentWorkouts: [],
        recentMeals: [],
        latestProgress: {});
    final input = buildAiCoachMessages(
        context: context,
        question: 'Potvrđujem.',
        recentHistory: [
          AiCoachMessage(
              id: 1, role: 'user', content: 'Potvrđujem.', createdAt: today),
          AiCoachMessage(
              id: 0,
              role: 'assistant',
              content: 'Recovered plan.',
              createdAt: today,
              planAction: prepared()),
        ]);
    expect(
        input.where((item) =>
            item['role'] == 'user' && item['content'] == 'Potvrđujem.'),
        hasLength(1));
    expect(input.last['content'], 'Potvrđujem.');
  });

  Widget app(CoachTrainerWidget child) =>
      MaterialApp(theme: ThemeData.dark(useMaterial3: true), home: child);
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
      'meal-only proposal shows Implement regardless of assistant language',
      (tester) async {
    phone(tester);
    final action =
        CoachPlanAction(id: actionId, workouts: [], meals: prepared().meals);
    var writes = 0;
    await tester.pumpWidget(app(CoachTrainerWidget(
      conversationLoader: () async => [
        AiCoachMessage(
            id: 1,
            role: 'assistant',
            content: 'План је спреман.',
            createdAt: today,
            planAction: action)
      ],
      planImplementer: (_) async => writes++,
    )));
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('implement-plan-$actionId'));
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(writes, 1);
    expect(button, findsNothing);
    expect(find.text('Plan added'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'written approval updates existing card and leaves no second Implement',
      (tester) async {
    phone(tester);
    final action = prepared();
    await tester.pumpWidget(app(CoachTrainerWidget(
      useGate: () async => const AiUseDecision(AiUseResult.premium),
      conversationLoader: () async => [
        AiCoachMessage(
            id: 1,
            role: 'assistant',
            content: 'Ready.',
            createdAt: today,
            planAction: action)
      ],
      questionSender: (question) async {
        expect(question, 'Sí, confirmo');
        return AiCoachMessage(
            id: 2,
            role: 'assistant',
            content: action.receipt,
            createdAt: today,
            planAction: action.withStatus('implemented'));
      },
    )));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('trainer-input')), 'Sí, confirmo');
    await tester.tap(find.byKey(const ValueKey('trainer-send')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('implement-plan-$actionId')), findsNothing);
    expect(find.byKey(const ValueKey('coach-plan-action-$actionId')),
        findsOneWidget);
    expect(find.text(action.receipt), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'failed application keeps one retry and successful retry removes Implement',
      (tester) async {
    phone(tester);
    final action = prepared();
    var attempts = 0;
    await tester.pumpWidget(app(CoachTrainerWidget(
      conversationLoader: () async => [
        AiCoachMessage(
            id: 1,
            role: 'assistant',
            content: 'Ready.',
            createdAt: today,
            planAction: action)
      ],
      planImplementer: (_) async {
        attempts++;
        if (attempts == 1)
          throw StateError('Simulated interrupted local import');
      },
    )));
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('implement-plan-$actionId'));
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(button, findsNothing);
    expect(find.text('Plan added'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reloaded proposal and receipt share one completed card',
      (tester) async {
    phone(tester);
    final action = prepared().withStatus('implemented');
    await tester.pumpWidget(app(CoachTrainerWidget(
      conversationLoader: () async => [
        AiCoachMessage(
            id: 1,
            role: 'assistant',
            content: 'Ready.',
            createdAt: today,
            planAction: action),
        AiCoachMessage(
            id: 2,
            role: 'assistant',
            content: action.receipt,
            createdAt: today,
            planAction: action),
      ],
    )));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('implement-plan-$actionId')), findsNothing);
    expect(find.byKey(const ValueKey('coach-plan-action-$actionId')),
        findsOneWidget);
    expect(find.text(action.receipt), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'rapid repeated Send only claims one use and submits one confirmation',
      (tester) async {
    phone(tester);
    final gate = Completer<AiUseDecision>();
    var claims = 0;
    var questions = 0;
    await tester.pumpWidget(app(CoachTrainerWidget(
      conversationLoader: () async => [],
      useGate: () {
        claims++;
        return gate.future;
      },
      questionSender: (_) async {
        questions++;
        return AiCoachMessage(
            id: 1, role: 'assistant', content: 'Done.', createdAt: today);
      },
    )));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('trainer-input')), 'Potvrđujem.');
    final send = find.byKey(const ValueKey('trainer-send'));
    await tester.tap(send);
    await tester.tap(send);
    expect(claims, 1);
    gate.complete(const AiUseDecision(AiUseResult.premium));
    await tester.pumpAndSettle();
    expect(questions, 1);
    expect(tester.takeException(), isNull);
  });
}
