import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_feed/ai_workout/coach_tools/coach_tools_widget.dart';
import 'package:gym_feed/ai_workout/premium/ai_usage_gate.dart';
import 'package:gym_feed/backend/supabase/repositories/ai_coach_repository.dart';
import 'package:gym_feed/workout/routines/workout_routine_models.dart';
import 'package:gym_feed/workout/routines/workout_routine_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AiCoachContext context() => const AiCoachContext(
        profile: {
          'name': 'Alex',
          'height_cm': 182,
          'weight_kg': 84,
          'primary_goal': 'Build muscle',
          'food_allergies_and_exclusions': 'Peanuts',
        },
        starterPlan: {
          'workouts': [
            {
              'day_index': 0,
              'name': 'Push A',
              'exercises': [
                {
                  'name': 'Bench Press',
                  'sets': [
                    {'weight_kg': 70, 'reps': 8}
                  ],
                }
              ],
            }
          ],
          'meals': [
            {
              'day_index': 0,
              'name': 'Chicken rice bowl',
              'calories': 620,
            }
          ],
        },
        currentRoutines: [
          {
            'name': 'Edited Push A',
            'exercises': [
              {
                'name': 'Bench Press',
                'setTargets': [
                  {'weightKg': 72.5, 'reps': 8}
                ],
              }
            ],
          }
        ],
        workoutSchedule: {
          '2026-08-13': ['push-a']
        },
        recentWorkouts: [],
        recentMeals: [],
        latestProgress: {
          'weight_kg': 83.5,
          'body_fat_percentage': 17,
        },
      );

  test('coach prompt contains profile, exact plans, memory, and strict scope',
      () {
    final prompt = buildAiCoachSystemPrompt(
      context: context(),
      memorySummary: 'Alex reported mild shoulder discomfort last week.',
    );

    expect(prompt, contains('Alex'));
    expect(prompt, contains('182'));
    expect(prompt, contains('72.5'));
    expect(prompt, contains('Chicken rice bowl'));
    expect(prompt, contains('mild shoulder discomfort'));
    expect(prompt, contains('If a request is outside that scope'));
    expect(prompt, contains('prior grip/exercise preferences'));
    expect(prompt, contains('Respect every allergy'));
    expect(prompt, contains('Never infer that a routine is scheduled'));
    expect(prompt, contains('status "unscheduled"'));
  });

  const testExercise = RoutineExercise(
    name: 'Bench Press',
    setCount: 3,
    defaultWeightKg: 70,
    defaultReps: 8,
    setTargets: [
      RoutineSetTarget(weightKg: 70, reps: 8),
      RoutineSetTarget(weightKg: 72.5, reps: 8),
      RoutineSetTarget(weightKg: 75, reps: 6),
    ],
  );
  final pushRoutine = WorkoutRoutine(
    id: 'push-a',
    name: 'Push A',
    category: 'Chest · Shoulders · Triceps',
    exercises: const [testExercise],
    createdAt: DateTime(2026, 8, 1),
    lastPerformedAt: DateTime(2026, 8, 8),
  );
  final legRoutine = WorkoutRoutine(
    id: 'legs-a',
    name: 'Legs A',
    category: 'Quads · Glutes',
    exercises: const [
      RoutineExercise(
        name: 'Squat',
        setCount: 3,
        defaultWeightKg: 90,
        defaultReps: 6,
      ),
    ],
    createdAt: DateTime(2026, 8, 1),
    lastPerformedAt: DateTime(2026, 8, 4),
  );

  AiCoachContext scheduleContext({
    required Map<String, List<String>> schedule,
    dynamic weeklyTarget = '5 workouts',
    List<WorkoutHistoryItem> history = const [],
  }) {
    final routines = [pushRoutine, legRoutine];
    return AiCoachContext(
      profile: {
        'name': 'Alex',
        'workouts_per_week': weeklyTarget,
      },
      starterPlan: const {},
      currentRoutines: routines.map((routine) => routine.toJson()).toList(),
      workoutSchedule: buildAiCoachScheduleWindow(
        routines: routines,
        schedule: schedule,
        history: history,
        workoutsPerWeek: weeklyTarget,
        now: DateTime(2026, 8, 13, 14, 30),
      ),
      recentWorkouts: history.map((item) => item.toJson()).toList(),
      recentMeals: const [],
      latestProgress: const {},
    );
  }

  test('dated workout context contains exactly 14 resolved calendar days', () {
    final history = WorkoutHistoryItem(
      id: 'history-1',
      routineId: 'push-a',
      name: 'Push A',
      startedAt: DateTime(2026, 8, 11, 18, 15),
      durationSeconds: 2700,
      exercises: const [],
    );
    final window = buildAiCoachScheduleWindow(
      routines: [pushRoutine, legRoutine],
      schedule: const {
        '2026-08-13': ['push-a'],
        '2026-08-15': ['legs-a'],
      },
      history: [history],
      workoutsPerWeek: '5+',
      now: DateTime(2026, 8, 13, 23, 59),
    );

    final days = (window['days'] as List).cast<Map<String, dynamic>>();
    expect(days, hasLength(14));
    expect(window['local_today'], '2026-08-13');
    expect(window['window_start'], '2026-08-10');
    expect(window['window_end'], '2026-08-23');
    expect(window['weekly_target'], 5);
    final today = days.singleWhere((day) => day['date'] == '2026-08-13');
    expect(today['relative_day'], 'today');
    expect(
      ((today['scheduled_workouts'] as List).first
          as Map<String, dynamic>)['name'],
      'Push A',
    );
    final completed = days.singleWhere((day) => day['date'] == '2026-08-11');
    expect(
      ((completed['completed_workouts'] as List).first
          as Map<String, dynamic>)['started_at'],
      contains('2026-08-11T18:15:00'),
    );
  });

  test('today lookup returns only the exact scheduled workout and sets', () {
    final reply = answerScheduleAwareQuestion(
      scheduleContext(schedule: const {
        '2026-08-13': ['push-a'],
      }),
      'What is my workout today?',
      now: DateTime(2026, 8, 13, 9),
    );

    expect(reply, isNotNull);
    expect(reply!.text, contains('Push A'));
    expect(reply.text, contains('72.5 kg x 8'));
    expect(reply.text, isNot(contains('Legs A')));
    expect(reply.proposal, isNull);
  });

  test('implicit today-plan wording uses the dated Train source of truth', () {
    final reply = answerScheduleAwareQuestion(
      scheduleContext(schedule: const {
        '2026-08-10': ['push-a'],
      }),
      'What do we have in store for today?',
      now: DateTime(2026, 8, 13, 9),
    );

    expect(reply, isNotNull);
    expect(reply!.text, contains('no workout scheduled'));
    expect(reply.proposal, isNotNull);
    expect(reply.proposal!.scheduledDate, DateTime(2026, 8, 13));
  });

  test('empty day is a rest day when the weekly goal is already covered', () {
    final reply = answerScheduleAwareQuestion(
      scheduleContext(schedule: const {
        '2026-08-10': ['push-a'],
        '2026-08-11': ['legs-a'],
        '2026-08-12': ['push-a'],
        '2026-08-14': ['legs-a'],
        '2026-08-15': ['push-a'],
      }),
      'Do I train today?',
      now: DateTime(2026, 8, 13, 9),
    );

    expect(reply!.text, contains('no workout scheduled'));
    expect(reply.text, contains('5 of 5'));
    expect(reply.text, contains('rest or recovery day'));
    expect(reply.proposal, isNull);
  });

  test('underfilled week proposes a saved workout for the requested date', () {
    final reply = answerScheduleAwareQuestion(
      scheduleContext(schedule: const {
        '2026-08-10': ['push-a'],
      }),
      'Do I have a workout tomorrow?',
      now: DateTime(2026, 8, 13, 9),
    );

    expect(reply!.text, contains('no workout scheduled'));
    expect(reply.text, contains('Only 1 of your 5'));
    expect(reply.proposal, isNotNull);
    expect(reply.proposal!.scheduledDate, DateTime(2026, 8, 14));
    // Legs A is chosen deterministically because Push A is already represented
    // during the week; the coach does not invent an unrelated workout.
    expect(reply.proposal!.routine.id, 'legs-a');
  });

  test('past empty dates never produce an implementation proposal', () {
    final reply = answerScheduleAwareQuestion(
      scheduleContext(schedule: const {}),
      'What was my workout yesterday?',
      now: DateTime(2026, 8, 13, 9),
    );

    expect(reply!.text, contains('no workout scheduled'));
    expect(reply.text, contains('will not substitute'));
    expect(reply.proposal, isNull);
  });

  test('missing weekly target never creates a workout', () {
    final reply = answerScheduleAwareQuestion(
      scheduleContext(schedule: const {}, weeklyTarget: ''),
      'Do I train today?',
      now: DateTime(2026, 8, 13, 9),
    );

    expect(reply!.text, contains('weekly workout target is not set'));
    expect(reply.proposal, isNull);
  });

  test('next session returns the next timestamped booking, not history', () {
    final reply = answerScheduleAwareQuestion(
      scheduleContext(schedule: const {
        '2026-08-12': ['push-a'],
        '2026-08-15': ['legs-a'],
      }),
      'What is my next workout?',
      now: DateTime(2026, 8, 13, 9),
    );

    expect(reply!.text, contains('Saturday, 2026-08-15'));
    expect(reply.text, contains('Legs A'));
    expect(reply.text, isNot(contains('Push A')));
  });

  test('workout proposal metadata survives persisted conversation rows', () {
    final proposal = AiCoachWorkoutProposal(
      scheduledDate: DateTime(2026, 8, 14),
      routine: legRoutine,
      reason: 'Weekly target is underfilled.',
    );
    final encoded = base64Url.encode(
      utf8.encode(jsonEncode(proposal.toJson())),
    );
    final message = AiCoachMessage.fromRow({
      'id': 7,
      'role': 'assistant',
      'content': 'Would you like to add Legs A?\n\n'
          '[[GYMFEED_WORKOUT_PROPOSAL:$encoded]]',
      'created_at': '2026-08-13T10:00:00Z',
    });

    expect(message.content, 'Would you like to add Legs A?');
    expect(message.workoutProposal!.routine.name, 'Legs A');
    expect(message.workoutProposal!.scheduledDate, DateTime(2026, 8, 14));
    expect(message.toAiMessage()['content'], isNot(contains('GYMFEED')));
  });

  test('schedule commands understand Croatian and resolve the exact date', () {
    final today = DateTime(2026, 8, 13, 20, 15);
    final todayCommand = detectWorkoutScheduleCommand(
      'Ubaci ga u raspored za danas',
      now: today,
    );
    final tomorrowCommand = detectWorkoutScheduleCommand(
      'Dodaj ovaj trening u Train za sutra',
      now: today,
    );
    final datedCommand = detectWorkoutScheduleCommand(
      'Schedule this workout for 17.08.2026',
      now: today,
    );

    expect(todayCommand, isNotNull);
    expect(todayCommand!.scheduledDate, DateTime(2026, 8, 13));
    expect(tomorrowCommand!.scheduledDate, DateTime(2026, 8, 14));
    expect(datedCommand!.scheduledDate, DateTime(2026, 8, 17));
    expect(
      detectWorkoutScheduleCommand('Add more reps to this set', now: today),
      isNull,
    );
  });

  test('private workout JSON is validated into editable sets', () {
    final reply = parseWorkoutActionResponse(
      jsonEncode({
        'assistant_text': 'Pregledaj trening i potvrdi ispod.',
        'action': {
          'type': 'schedule_workout',
          'requires_confirmation': true,
          // The app-resolved date is authoritative even if a model emits a
          // different date in its private payload.
          'scheduled_date': '2099-01-01',
          'reason': 'Requested by the athlete.',
          'routine': {
            'name': 'Upper Body Strength',
            'category': 'Chest · Back',
            'exercises': [
              {
                'name': 'Bench Press',
                'sets': [
                  {'weight_kg': 60, 'reps': 10},
                  {'weight_kg': 62.5, 'reps': 8},
                ],
              },
              {
                'name': 'Barbell Row',
                'sets': [
                  {'weight_kg': 55, 'reps': 10},
                ],
              },
            ],
          },
        },
      }),
      scheduledDate: DateTime(2026, 8, 13),
      now: DateTime(2026, 8, 13, 20, 15),
    );

    expect(reply.proposal, isNotNull);
    expect(reply.proposal!.scheduledDate, DateTime(2026, 8, 13));
    expect(reply.proposal!.routine.exercises, hasLength(2));
    expect(reply.proposal!.routine.exercises.first.setTargets, hasLength(2));
    expect(
      reply.proposal!.routine.exercises.first.setTargets.last.weightKg,
      62.5,
    );
    expect(reply.proposal!.routine.exercises.first.setTargets.last.reps, 8);
  });

  test('unsafe workout action JSON is rejected before any calendar write', () {
    expect(
      () => parseWorkoutActionResponse(
        jsonEncode({
          'assistant_text': 'Added.',
          'action': {
            'type': 'schedule_workout',
            'requires_confirmation': false,
            'routine': {
              'name': 'Unsafe',
              'exercises': const [],
            },
          },
        }),
        scheduledDate: DateTime(2026, 8, 13),
      ),
      throwsFormatException,
    );
  });

  test('Croatian follow-up converts a prior plain-text workout to a proposal',
      () async {
    List<Map<String, dynamic>>? compilerMessages;
    final repository = AiCoachRepository(
      workoutActionAiCall: (messages) async {
        compilerMessages = messages;
        return jsonEncode({
          'assistant_text':
              'Pripremio sam trening za danas. Odaberi Implement ili Skip.',
          'action': {
            'type': 'schedule_workout',
            'requires_confirmation': true,
            'scheduled_date': '2026-08-13',
            'reason': 'Korisnik je zatražio prethodno opisani trening.',
            'routine': {
              'name': 'Full Upper Body',
              'category': 'Strength',
              'exercises': [
                {
                  'name': 'Bench Press',
                  'sets': [
                    {'weight_kg': 60, 'reps': 10},
                    {'weight_kg': 60, 'reps': 10},
                    {'weight_kg': 60, 'reps': 8},
                  ],
                },
              ],
            },
          },
        });
      },
    );
    final reply = await repository.createWorkoutActionProposal(
      context: scheduleContext(schedule: const {}),
      recentHistory: [
        AiCoachMessage(
          id: 8,
          role: 'assistant',
          content: 'Bench Press — 3 sets at 60 kg: 10, 10, 8 reps.',
          createdAt: DateTime(2026, 8, 13, 19),
        ),
      ],
      question: 'ubaci ga u raspored za danas',
      now: DateTime(2026, 8, 13, 20, 15),
    );

    expect(compilerMessages, isNotNull);
    expect(compilerMessages!.last['content'], contains('raspored za danas'));
    expect(reply!.proposal, isNotNull);
    expect(reply.proposal!.scheduledDate, DateTime(2026, 8, 13));
    expect(reply.proposal!.routine.exercises.first.setTargets, hasLength(3));
    expect(reply.text, contains('Implement'));
  });

  test('natural confirmation reuses a prior hidden proposal and its date',
      () async {
    var compilerCalls = 0;
    final repository = AiCoachRepository(
      workoutActionAiCall: (_) async {
        compilerCalls += 1;
        return null;
      },
    );
    final previous = AiCoachWorkoutProposal(
      scheduledDate: DateTime(2026, 8, 15),
      routine: legRoutine,
      reason: 'Underfilled week.',
    );
    final reply = await repository.createWorkoutActionProposal(
      context: scheduleContext(schedule: const {}),
      recentHistory: [
        AiCoachMessage(
          id: 9,
          role: 'assistant',
          content: 'Would you like to add Legs A?',
          createdAt: DateTime(2026, 8, 13),
          workoutProposal: previous,
        ),
      ],
      question: 'Yes, add it to Train',
      now: DateTime(2026, 8, 13),
    );

    expect(compilerCalls, 0);
    expect(reply!.proposal!.routine.id, legRoutine.id);
    expect(reply.proposal!.scheduledDate, DateTime(2026, 8, 15));
  });

  test('date-only reply completes the immediately pending schedule action',
      () async {
    var compilerCalls = 0;
    final repository = AiCoachRepository(
      workoutActionAiCall: (_) async {
        compilerCalls += 1;
        return jsonEncode({
          'assistant_text': 'Review the workout and confirm it below.',
          'action': {
            'type': 'schedule_workout',
            'requires_confirmation': true,
            'scheduled_date': '2026-08-14',
            'reason': 'The athlete selected today.',
            'routine': {
              'name': 'Full Upper Body',
              'category': 'Strength',
              'exercises': [
                {
                  'name': 'Bench Press',
                  'sets': [
                    {'weight_kg': 60, 'reps': 10},
                    {'weight_kg': 60, 'reps': 8},
                  ],
                },
              ],
            },
          },
        });
      },
    );
    final now = DateTime(2026, 8, 14, 11);
    final history = [
      AiCoachMessage(
        id: 20,
        role: 'assistant',
        content: 'Full Upper Body: Bench Press 60 kg for 10 and 8 reps.',
        createdAt: now,
      ),
      AiCoachMessage(
        id: 21,
        role: 'user',
        content: 'add this to my calendar I like this workout',
        createdAt: now,
      ),
      AiCoachMessage(
        id: 22,
        role: 'assistant',
        content: 'Which date should I add the workout to in Train?',
        createdAt: now,
      ),
      // This mirrors ask(): the current message is already persisted when the
      // action resolver receives the recent conversation.
      AiCoachMessage(
        id: 23,
        role: 'user',
        content: 'today',
        createdAt: now,
      ),
    ];

    final reply = await repository.createWorkoutActionProposal(
      context: scheduleContext(schedule: const {}),
      recentHistory: history,
      question: 'today',
      now: now,
    );

    expect(compilerCalls, 1);
    expect(reply, isNotNull);
    expect(reply!.proposal, isNotNull);
    expect(reply.proposal!.scheduledDate, DateTime(2026, 8, 14));
    expect(reply.proposal!.routine.name, 'Full Upper Body');
  });

  test('Croatian date-only reply also completes its pending action', () async {
    final repository = AiCoachRepository(
      workoutActionAiCall: (_) async => jsonEncode({
        'assistant_text': 'Pregledaj trening i potvrdi ispod.',
        'action': {
          'type': 'schedule_workout',
          'requires_confirmation': true,
          'scheduled_date': '2026-08-14',
          'reason': 'Korisnik je odabrao danas.',
          'routine': {
            'name': 'Trening za danas',
            'category': 'Cijelo tijelo',
            'exercises': [
              {
                'name': 'Čučanj',
                'sets': [
                  {'weight_kg': 70, 'reps': 8},
                ],
              },
            ],
          },
        },
      }),
    );
    final now = DateTime(2026, 8, 14, 11);
    final reply = await repository.createWorkoutActionProposal(
      context: scheduleContext(schedule: const {}),
      recentHistory: [
        AiCoachMessage(
          id: 30,
          role: 'assistant',
          content: 'Čučanj — 70 kg x 8.',
          createdAt: now,
        ),
        AiCoachMessage(
          id: 31,
          role: 'user',
          content: 'dodaj mi u kalendar',
          createdAt: now,
        ),
        AiCoachMessage(
          id: 32,
          role: 'assistant',
          content: 'Na koji datum želiš dodati trening?',
          createdAt: now,
        ),
        AiCoachMessage(
          id: 33,
          role: 'user',
          content: 'danas',
          createdAt: now,
        ),
      ],
      question: 'danas',
      now: now,
    );

    expect(reply!.proposal, isNotNull);
    expect(reply.proposal!.scheduledDate, DateTime(2026, 8, 14));
    expect(reply.proposal!.routine.exercises.first.name, 'Čučanj');
  });

  test('date-only text without a pending action remains normal conversation',
      () async {
    var compilerCalls = 0;
    final repository = AiCoachRepository(
      workoutActionAiCall: (_) async {
        compilerCalls += 1;
        return null;
      },
    );
    final reply = await repository.createWorkoutActionProposal(
      context: scheduleContext(schedule: const {}),
      recentHistory: const [],
      question: 'today',
      now: DateTime(2026, 8, 14),
    );

    expect(reply, isNull);
    expect(compilerCalls, 0);
  });

  test('implementing a proposal writes the routine and exact Train date',
      () async {
    final proposal = AiCoachWorkoutProposal(
      scheduledDate: DateTime(2026, 8, 14),
      routine: WorkoutRoutine(
        id: 'ai-legs-a',
        name: 'AI Legs A',
        category: 'Lower body',
        exercises: const [
          RoutineExercise(name: 'Squat', setCount: 3),
        ],
        createdAt: DateTime(2026, 8, 13),
      ),
      reason: 'Weekly target is underfilled.',
    );

    await AiCoachRepository().implementWorkoutProposal(proposal);
    final routines = await WorkoutRoutineStore.loadRoutines();
    final schedule = await WorkoutRoutineStore.loadSchedule();
    expect(routines.map((routine) => routine.id), contains('ai-legs-a'));
    expect(schedule['2026-08-14'], contains('ai-legs-a'));
  });

  test('canonical disclosure is always the final text and is not duplicated',
      () {
    final once =
        ensureAiCoachDisclosure('Keep your ribs down during the press.');
    final twice = ensureAiCoachDisclosure(once);

    expect(once, endsWith(aiCoachDisclosure));
    expect(twice, once);
    expect(RegExp(RegExp.escape(aiCoachDisclosure)).allMatches(twice),
        hasLength(1));
  });

  test('recent persisted messages are sent before the current question', () {
    final history = [
      AiCoachMessage(
        id: 1,
        role: 'user',
        content: 'My shoulder felt tight after benching.',
        createdAt: DateTime(2026, 8, 12),
      ),
      AiCoachMessage(
        id: 2,
        role: 'assistant',
        content: 'Reduce the load and check your range.',
        createdAt: DateTime(2026, 8, 12),
      ),
    ];
    final messages = buildAiCoachMessages(
      context: context(),
      recentHistory: history,
      question: 'What should I change today?',
    );

    expect(messages[1]['content'], contains('shoulder felt tight'));
    expect(messages[2]['role'], 'assistant');
    expect(messages.last['content'], 'What should I change today?');
  });

  test('exact meal questions receive deterministic saved-plan evidence', () {
    final messages = buildAiCoachMessages(
      context: context(),
      recentHistory: const [],
      question: 'What meal and calories are on day 1?',
    );

    final evidence = messages[messages.length - 2]['content'].toString();
    expect(evidence, contains('AUTHORITATIVE FACTS FOR THIS QUESTION'));
    expect(evidence, contains('Chicken rice bowl'));
    expect(evidence, contains('620'));
    expect(messages.last['role'], 'user');
  });

  test('exact meal-plan lookups are answered from saved facts', () {
    final answer = answerExactSavedPlanQuestion(
      context(),
      'What meal and calories are on day 1?',
    );

    expect(answer, contains('Chicken rice bowl'));
    expect(answer, contains('620 kcal'));
    expect(answer, contains('Day 1'));
  });

  test('exact workout set lookups use the editable routine values', () {
    final answer = answerExactSavedPlanQuestion(
      context(),
      'In my current Edited Push A routine, what kg and reps are in the first set of Bench Press?',
    );

    expect(answer, contains('72.5 kg'));
    expect(answer, contains('8 reps'));
    expect(answer, contains('set 1'));
  });

  test('fitness preference recall is explicitly classified in scope', () {
    final messages = buildAiCoachMessages(
      context: context(),
      recentHistory: const [],
      question: 'What grip preference did I tell you earlier?',
    );

    expect(messages[messages.length - 2]['content'],
        contains('in_scope_fitness_or_nutrition_recall'));
  });

  testWidgets('AI Coach restores history and sends through the new repository',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var sent = '';
    final now = DateTime(2026, 8, 12);

    await tester.pumpWidget(MaterialApp(
      home: CoachTrainerWidget(
        useGate: () async => const AiUseDecision(AiUseResult.premium),
        conversationLoader: () async => [
          AiCoachMessage(
            id: 1,
            role: 'user',
            content: 'Remember my push workout?',
            createdAt: now,
          ),
          AiCoachMessage(
            id: 2,
            role: 'assistant',
            content: ensureAiCoachDisclosure('Yes, Push A starts with bench.'),
            createdAt: now,
          ),
        ],
        questionSender: (question) async {
          sent = question;
          return AiCoachMessage(
            id: 4,
            role: 'assistant',
            content: ensureAiCoachDisclosure('Use 72.5 kg for 8 reps.'),
            createdAt: now,
          );
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Remember my push workout?'), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('trainer-input')), 'What weight today?');
    await tester.tap(find.byKey(const ValueKey('trainer-send')));
    await tester.pumpAndSettle();

    expect(sent, 'What weight today?');
    expect(find.textContaining('72.5 kg'), findsOneWidget);
    expect(find.textContaining('Disclosure: GymFeed AI Coach'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI Coach proposal requires Implement and then updates its state',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    AiCoachWorkoutProposal? implemented;
    final proposal = AiCoachWorkoutProposal(
      scheduledDate: DateTime(2026, 8, 14),
      routine: legRoutine,
      reason: 'Only 1 of your 5 workouts is committed.',
    );

    await tester.pumpWidget(MaterialApp(
      home: CoachTrainerWidget(
        useGate: () async => const AiUseDecision(AiUseResult.premium),
        conversationLoader: () async => const [],
        questionSender: (_) async => AiCoachMessage(
          id: 4,
          role: 'assistant',
          content: ensureAiCoachDisclosure(
              'You have no workout scheduled. I recommend Legs A.'),
          createdAt: DateTime(2026, 8, 13),
          workoutProposal: proposal,
        ),
        proposalImplementer: (value) async => implemented = value,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('trainer-input')),
      'Do I train tomorrow?',
    );
    await tester.tap(find.byKey(const ValueKey('trainer-send')));
    await tester.pumpAndSettle();

    final implement = find.byKey(const ValueKey('implement-workout-legs-a'));
    expect(implement, findsOneWidget);
    expect(find.byKey(const ValueKey('skip-workout-legs-a')), findsOneWidget);
    await tester.ensureVisible(implement);
    await tester.tap(implement);
    await tester.pumpAndSettle();

    expect(implemented, same(proposal));
    expect(find.text('Added to your Train calendar'), findsOneWidget);
    expect(
      find.textContaining('Legs A was added to Train for 2026-08-14'),
      findsOneWidget,
    );
    expect(
        find.byKey(const ValueKey('implement-workout-legs-a')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI Coach workout suggestion can be skipped without persistence',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var implementationCalls = 0;
    final proposal = AiCoachWorkoutProposal(
      scheduledDate: DateTime(2026, 8, 14),
      routine: legRoutine,
      reason: 'Weekly target is underfilled.',
    );

    await tester.pumpWidget(MaterialApp(
      home: CoachTrainerWidget(
        useGate: () async => const AiUseDecision(AiUseResult.premium),
        conversationLoader: () async => [
          AiCoachMessage(
            id: 4,
            role: 'assistant',
            content: ensureAiCoachDisclosure('I recommend Legs A.'),
            createdAt: DateTime(2026, 8, 13),
            workoutProposal: proposal,
          ),
        ],
        proposalImplementer: (_) async => implementationCalls += 1,
      ),
    ));
    await tester.pumpAndSettle();

    final skip = find.byKey(const ValueKey('skip-workout-legs-a'));
    await tester.ensureVisible(skip);
    await tester.tap(skip);
    await tester.pumpAndSettle();

    expect(implementationCalls, 0);
    expect(find.text('Suggestion skipped'), findsOneWidget);
    expect(find.byKey(const ValueKey('skip-workout-legs-a')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('implemented proposal remains implemented after chat reload',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final proposal = AiCoachWorkoutProposal(
      scheduledDate: DateTime(2026, 8, 15),
      routine: legRoutine,
      reason: 'Confirmed previously.',
    );
    await WorkoutRoutineStore.scheduleRoutine(
      proposal.scheduledDate,
      proposal.routine.id,
    );

    await tester.pumpWidget(MaterialApp(
      home: CoachTrainerWidget(
        useGate: () async => const AiUseDecision(AiUseResult.premium),
        conversationLoader: () async => [
          AiCoachMessage(
            id: 12,
            role: 'assistant',
            content: 'Review Legs A below.',
            createdAt: DateTime(2026, 8, 13),
            workoutProposal: proposal,
          ),
        ],
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Added to your Train calendar'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('implement-workout-legs-a')), findsNothing);
    expect(find.byKey(const ValueKey('skip-workout-legs-a')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
