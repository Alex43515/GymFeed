import 'dart:convert';

import 'package:uuid/uuid.dart';

import '/backend/supabase/ai_service.dart';
import '/workout/routines/workout_routine_models.dart';
import '/workout/routines/workout_routine_store.dart';
import 'coach_plan_repository.dart';
import 'starter_plan_repository.dart';

typedef CoachPlanAiCall = Future<String?> Function(
    List<Map<String, dynamic>> messages);

Map<String, dynamic> _object(Map<String, dynamic> properties) => {
      'type': 'object',
      'additionalProperties': false,
      'properties': properties,
      'required': properties.keys.toList(),
    };
Map<String, dynamic> _array(Map<String, dynamic> items) =>
    {'type': 'array', 'items': items};
const _string = {'type': 'string'};
const _number = {'type': 'number'};
const _integer = {'type': 'integer'};

/// One language-independent contract for conversation, proposals and decisions.
/// The model cannot execute writes or choose an arbitrary pending plan id.
final coachPlanResponseSchema = _object({
  'intent': {
    'type': 'string',
    'enum': ['chat', 'clarify', 'propose', 'apply', 'confirm', 'cancel'],
  },
  'assistant_text': _string,
  'workouts': _array(_object({
    'date': _string,
    'name': _string,
    'category': _string,
    'exercises': _array(_object({
      'name': _string,
      'sets': _array(_object({'weight_kg': _number, 'reps': _integer})),
    })),
  })),
  'meals': _array(_object({
    'date': _string,
    'meal_type': {
      'type': 'string',
      'enum': ['Breakfast', 'Lunch', 'Dinner', 'Snack'],
    },
    'name': _string,
    'description': _string,
    'calories': _integer,
    'protein_g': _integer,
    'carbs_g': _integer,
    'fat_g': _integer,
  })),
});

class CoachPlanDecision {
  const CoachPlanDecision(this.intent, this.text, {this.proposal});
  final String intent;
  final String text;
  final CoachPlanAction? proposal;
}

class CoachPlanOutcome {
  const CoachPlanOutcome(this.text, {this.action});
  final String text;
  final CoachPlanAction? action;
}

/// A confirmation never generates or saves another proposal. The only
/// executable target is the persisted current plan supplied by the app.
Future<CoachPlanOutcome> executeCoachPlanDecision(
  CoachPlanDecision decision, {
  required CoachPlanRepository plans,
  CoachPlanAction? latestAction,
}) async {
  switch (decision.intent) {
    case 'propose':
    case 'apply':
      var saved = await plans.saveProposal(decision.proposal!);
      if (decision.intent == 'apply') saved = await plans.implement(saved);
      return CoachPlanOutcome(
          saved.implemented
              ? saved.receipt
              : 'Your plan is ready below. Choose Implement or confirm in chat.',
          action: saved);
    case 'confirm':
      if (latestAction != null &&
          (latestAction.pending || latestAction.implemented)) {
        try {
          final saved = await plans.implement(latestAction);
          return CoachPlanOutcome(saved.receipt, action: saved);
        } on CoachPlanUnavailableException catch (error) {
          return CoachPlanOutcome(
              'This proposal is no longer pending. Review the current plan.',
              action: error.action);
        }
      }
      return const CoachPlanOutcome('There is no pending plan to confirm. '
          'Tell me which workout or meal plan you want to add.');
    case 'cancel':
      if (latestAction?.pending == true) {
        final saved = await plans.setStatus(latestAction!.id, 'skipped');
        return CoachPlanOutcome(
            saved.implemented ? saved.receipt : 'Plan skipped.',
            action: saved);
      }
      return const CoachPlanOutcome('There is no pending plan to skip.');
    default:
      return CoachPlanOutcome(decision.text);
  }
}

DateTime _planDate(dynamic raw, DateTime today) {
  final text = raw?.toString() ?? '';
  final date = DateTime.tryParse(text);
  if (date == null ||
      WorkoutRoutineStore.dateKey(date) != text ||
      date.isBefore(DateTime(today.year, today.month, today.day)) ||
      date.isAfter(today.add(const Duration(days: 366)))) {
    throw const FormatException(
        'Plan entries need valid future YYYY-MM-DD dates.');
  }
  return DateTime(date.year, date.month, date.day);
}

String _planText(dynamic value, int maximum) {
  if (value is! String || value.trim().isEmpty || value.length > maximum) {
    throw const FormatException('Plan has missing or overly long text.');
  }
  return value.trim();
}

int _planInt(dynamic value, int maximum, {int minimum = 0}) {
  if (value is! num ||
      !value.isFinite ||
      value != value.round() ||
      value < minimum ||
      value > maximum) {
    throw const FormatException('Plan has an invalid nutrition or reps value.');
  }
  return value.toInt();
}

List<Map<String, dynamic>> _planItems(dynamic value, int maximum) {
  if (value is! List ||
      value.length > maximum ||
      value.any((item) => item is! Map)) {
    throw const FormatException('Plan has an invalid entry list.');
  }
  return value.map((item) => Map<String, dynamic>.from(item as Map)).toList();
}

CoachPlanDecision parseCoachPlanDecision(
  String raw, {
  required DateTime now,
  String foodAllergies = '',
  String? actionId,
}) {
  final root = jsonDecode(raw);
  if (root is! Map)
    throw const FormatException('Coach response must be an object.');
  final intent = root['intent'];
  if (!const {'chat', 'clarify', 'propose', 'apply', 'confirm', 'cancel'}
      .contains(intent)) {
    throw const FormatException('Unknown coach action.');
  }
  final text = _planText(root['assistant_text'], 16000);
  final rawWorkouts = _planItems(root['workouts'], 28);
  final rawMeals = _planItems(root['meals'], 168);
  if (intent != 'propose' && intent != 'apply') {
    if (rawWorkouts.isNotEmpty || rawMeals.isNotEmpty) {
      throw const FormatException(
          'Only proposals may contain new plan entries.');
    }
    return CoachPlanDecision(intent as String, text);
  }
  if (rawWorkouts.isEmpty && rawMeals.isEmpty) {
    throw const FormatException('A proposal must include workouts or meals.');
  }
  final id = actionId ?? const Uuid().v4();
  final workouts = <CoachScheduledWorkout>[];
  for (var index = 0; index < rawWorkouts.length; index++) {
    final item = rawWorkouts[index];
    final rawExercises = _planItems(item['exercises'], 12);
    if (rawExercises.isEmpty)
      throw const FormatException('Workout has no exercises.');
    final exercises = <RoutineExercise>[];
    for (final exercise in rawExercises) {
      final rawSets = _planItems(exercise['sets'], 10);
      if (rawSets.isEmpty) throw const FormatException('Exercise has no sets.');
      final targets = rawSets.map((set) {
        final weight = set['weight_kg'];
        if (weight is! num || !weight.isFinite || weight < 0 || weight > 500) {
          throw const FormatException('Invalid workout weight.');
        }
        return RoutineSetTarget(
            weightKg: weight.toDouble(),
            reps: _planInt(set['reps'], 100, minimum: 1));
      }).toList();
      exercises.add(RoutineExercise(
        name: _planText(exercise['name'], 80),
        setCount: targets.length,
        defaultWeightKg: targets.first.weightKg,
        defaultReps: targets.first.reps,
        setTargets: targets,
      ));
    }
    workouts.add(CoachScheduledWorkout(
      date: _planDate(item['date'], now),
      routine: WorkoutRoutine(
        id: 'coach-$id-workout-$index',
        name: _planText(item['name'], 100),
        category: _planText(item['category'], 120),
        exercises: exercises,
        createdAt: now,
      ),
    ));
  }
  final meals = <CoachScheduledMeal>[];
  for (var index = 0; index < rawMeals.length; index++) {
    final item = rawMeals[index];
    final type = item['meal_type'];
    if (!const {'Breakfast', 'Lunch', 'Dinner', 'Snack'}.contains(type)) {
      throw const FormatException('Unknown meal type.');
    }
    meals.add(CoachScheduledMeal(
      date: _planDate(item['date'], now),
      meal: StarterPlannedMeal(
        id: 'coach-$id-meal-$index',
        dayIndex: 0,
        mealType: type as String,
        name: sanitizeStarterPlanMealText(
            _planText(item['name'], 160), foodAllergies),
        description: sanitizeStarterPlanMealText(
            _planText(item['description'], 2000), foodAllergies),
        calories: _planInt(item['calories'], 5000, minimum: 1),
        proteinG: _planInt(item['protein_g'], 500),
        carbsG: _planInt(item['carbs_g'], 750),
        fatG: _planInt(item['fat_g'], 300),
      ),
    ));
  }
  final proposal = CoachPlanAction(id: id, workouts: workouts, meals: meals);
  if (proposal.dates.last.difference(proposal.dates.first).inDays > 27) {
    throw const FormatException('Each proposal covers at most 28 days.');
  }
  return CoachPlanDecision(intent as String, text, proposal: proposal);
}

class CoachPlanAssistant {
  CoachPlanAssistant({AiService? aiService, CoachPlanAiCall? aiCall})
      : _ai = aiService ?? AiService(),
        _override = aiCall;
  final AiService _ai;
  final CoachPlanAiCall? _override;

  Future<CoachPlanDecision> respond({
    required String systemPrompt,
    required List<Map<String, dynamic>> history,
    required String question,
    required DateTime now,
    CoachPlanAction? latestAction,
    String foodAllergies = '',
  }) async {
    final today = WorkoutRoutineStore.dateKey(now);
    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': '''$systemPrompt

APP ACTION CONTRACT (authoritative):
Interpret requests, dates, follow-ups and confirmations semantically in ANY language/script, including mixed-language messages, Cyrillic and transliteration. Do not require English keywords. UI labels may be English.
Today's LOCAL calendar date is $today. Resolve relative dates against this date. Use YYYY-MM-DD, never UTC conversion. If a new plan has no start date, start today and state that choice. Preserve explicitly stated dates. A plan may span at most 28 days; for a longer request offer the first 28 days clearly.
Return the JSON schema only. intent is:
- chat: normal coaching or a question about a plan, with empty arrays. Answer the question, do not propose an unwanted write.
- clarify: ONE essential question only if the intended action is genuinely ambiguous. Do not ask for profile information already provided or a date we can default to today. Missing repetitions, starting weights, portion sizes, calorie estimates or preparation details are NOT essential ambiguities: choose sensible conservative defaults from the athlete context and show them in the proposal.
- propose: a concrete request to prepare/add/save/change a workout or meal plan. Always include COMPLETE dated entries so the app can show Implement. Reuse an earlier described plan when the user refers to it; preserve exercises and portions, do not invent a different plan. Build both arrays when both are requested. Do not return a prose-only plan or ask permission to prepare a plan.
- confirm: the user clearly approves the current pending plan (yes, I confirm, go ahead, do it, add it, etc., in any language). Return empty arrays: the app applies the EXACT persisted payload. NEVER ask for confirmation again.
- apply: the user clearly approves a prior fully described workout/meal plan in the transcript but no persisted pending proposal exists. Compile that EXACT approved plan into complete dated entries for immediate application, without another confirmation. Do not use apply for initial requests or vague/conditional agreement. Do not reuse a skipped, superseded or already implemented plan.
- cancel: the user declines the current pending proposal. Negations, questions and conditional/uncertain approvals must never be interpreted as confirm.
A changed date, scope, exercise, food or portion is propose with the revised COMPLETE entries, not confirm of the old payload. Unrelated chat preserves the pending proposal. Confirm/cancel refer only to the CURRENT app state below, never an old proposal in the transcript. Repeated approval after status implemented should acknowledge it was already added and create no new proposal. If no pending plan exists, ask which plan to add, once.
No model response may claim a write succeeded. Only the app's persisted action receipt can do that. Do not ask the user to type a particular keyword: the Implement button and clear natural-language confirmation are equivalent.
For workouts use 1-12 exercises, each with 1-10 explicit sets, weight_kg 0-500 (convert pounds to kg), integer reps 1-100. Use 0 for bodyweight/unspecified loads. If repetitions are unspecified choose a conservative 8-10 reps, never ask the user to supply reps or choose training to failure. Preserve the requested number of sets; default to 3 only when no set count is given. Training must respect injuries, equipment, level and requested duration/frequency; include rest days by omitting workouts on those dates.
For meals include requested meals per day, English canonical meal_type, concise English names and descriptions with actual ingredients/portions and preparation instructions, calories 1-5000, protein_g 0-500, carbs_g 0-750, fat_g 0-300. Respect allergies and exclusions in any language. These are planned meals, NEVER logged as already eaten. Do not replace existing plans unless explicitly requested; current action support adds dated entries.
For chat, clarify, confirm and cancel both arrays MUST be empty.
CURRENT APP ACTION STATE:
${jsonEncode(latestAction == null ? null : {
                'id': latestAction.id,
                'status': latestAction.status,
                ...latestAction.toJson()
              })}'''
      },
      ...history,
      {'role': 'user', 'content': question},
    ];
    for (var attempt = 0; attempt < 2; attempt++) {
      final raw = await (_override?.call(messages) ?? _call(messages));
      if (raw == null || raw.trim().isEmpty) {
        throw StateError('The coach returned no structured response.');
      }
      try {
        final decision =
            parseCoachPlanDecision(raw, now: now, foodAllergies: foodAllergies);
        if (decision.intent == 'confirm' &&
            latestAction == null &&
            history.any((message) => message['role'] == 'assistant')) {
          throw const FormatException('There is no persisted current proposal. '
              'confirm cannot execute a missing payload. If the athlete clearly '
              'approved a fully described plan in the transcript, return apply '
              'with that exact plan in workouts/meals. Otherwise use clarify.');
        }
        if (decision.intent == 'apply' && latestAction?.pending == true) {
          throw const FormatException(
              'A persisted pending plan already exists. '
              'Use confirm to execute its exact payload, or propose for a change.');
        }
        return decision;
      } on FormatException catch (error) {
        if (attempt == 1) rethrow;
        messages.add({'role': 'assistant', 'content': raw});
        messages.add({
          'role': 'user',
          'content':
              'The app rejected that response: ${error.message}. Repair the JSON '
                  'for the same request, preserving intent and valid entries. Do not '
                  'ask the athlete to confirm again. No writes have occurred.'
        });
      }
    }
    throw StateError('Unable to compile coach action.');
  }

  Future<String?> _call(List<Map<String, dynamic>> messages) async {
    try {
      return await _ai.openAiChat(messages,
          model: 'gpt-5-mini',
          maxTokens: 24000,
          reasoningEffort: 'low',
          jsonSchema: coachPlanResponseSchema);
    } catch (_) {
      return _ai.geminiChat(messages,
          model: 'gemini-3.6-flash',
          maxTokens: 24000,
          temperature: 0.1,
          jsonSchema: coachPlanResponseSchema);
    }
  }
}
