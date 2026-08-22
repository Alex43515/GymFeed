import 'dart:convert';

import '/backend/supabase/ai_service.dart';
import '/backend/supabase/supabase.dart';

typedef StarterPlanAiCall = Future<String?> Function(
    List<Map<String, dynamic>> messages,
    {int? maxTokens,
    double? temperature,
    bool jsonObject});

class StarterPlanAllergyException extends FormatException {
  const StarterPlanAllergyException(super.message, this.allergen);

  final String allergen;
}

List<String> _starterPlanAllergenTerms(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty ||
      const {'none', 'no', 'n/a', 'nothing', 'no allergies'}
          .contains(normalized)) {
    return const [];
  }
  return normalized
      .split(RegExp(r'[,;/\n]|\band\b'))
      .map((term) => term.trim())
      .where((term) => term.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

/// Removes harmless provider disclaimers such as "no peanuts included", then
/// rejects the text if an excluded ingredient is still present. AI output is
/// never trusted as the final allergy-safety boundary.
String sanitizeStarterPlanMealText(
  String text,
  String foodAllergies,
) {
  var sanitized = text.trim();
  for (final allergen in _starterPlanAllergenTerms(foodAllergies)) {
    final forms = <String>{
      allergen,
      if (allergen.endsWith('s') && allergen.length > 1)
        allergen.substring(0, allergen.length - 1),
    }.map(RegExp.escape).join('|');
    final token = '(?:$forms)';
    sanitized = sanitized.replaceAll(
      RegExp(
        '(?:,\\s*)?(?:no|without)\\s+(?:any\\s+)?$token'
        '(?:\\s+(?:included|added))?[.!]?',
        caseSensitive: false,
      ),
      '',
    );
    sanitized = sanitized.replaceAll(
      RegExp('\\b$token[- ]free\\b', caseSensitive: false),
      'allergen-free',
    );
    if (RegExp('\\b$token\\b', caseSensitive: false).hasMatch(sanitized)) {
      throw StarterPlanAllergyException(
        'A generated meal contains an excluded allergen.',
        allergen,
      );
    }
  }
  return sanitized
      .replaceAll(RegExp(r'\s+([,.])'), r'$1')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();
}

int _intValue(dynamic value, [int fallback = 0]) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _doubleValue(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

String _text(dynamic value, [String fallback = '']) {
  final result = value?.toString().trim() ?? '';
  return result.isEmpty ? fallback : result;
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

List<dynamic> _list(dynamic value) => value is List ? value : const [];

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _dateKey(DateTime value) => '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

class StarterPlanProfile {
  const StarterPlanProfile({
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.gender,
    required this.goal,
    required this.workoutLevel,
    required this.workoutsPerWeek,
    required this.workoutLength,
    required this.workoutPeriod,
    required this.workoutWhere,
    required this.mealsPerDay,
    required this.snacksPerDay,
    required this.foodAllergies,
  });

  final int age;
  final int heightCm;
  final int weightKg;
  final String gender;
  final String goal;
  final String workoutLevel;
  final String workoutsPerWeek;
  final String workoutLength;
  final String workoutPeriod;
  final String workoutWhere;
  final String mealsPerDay;
  final int snacksPerDay;
  final String foodAllergies;

  int get minimumWorkoutsPerWeek {
    final match = RegExp(r'\d+').firstMatch(workoutsPerWeek);
    return _intValue(match?.group(0), 3).clamp(1, 7);
  }

  factory StarterPlanProfile.fromPrivateProfile(Map<String, dynamic> row) {
    final birthday = DateTime.tryParse(_text(row['age2']));
    final now = DateTime.now();
    final age = birthday == null
        ? _intValue(row['age'])
        : now.year -
            birthday.year -
            ((now.month < birthday.month ||
                    (now.month == birthday.month && now.day < birthday.day))
                ? 1
                : 0);
    return StarterPlanProfile(
      age: age.clamp(13, 100),
      heightCm: _intValue(row['height_cm']).clamp(100, 250),
      weightKg: _intValue(row['weight_kg']).clamp(30, 350),
      gender: _text(row['gender2'], 'not specified'),
      goal: _text(row['goals'], 'general fitness'),
      workoutLevel: _text(row['workout_level'], 'beginner'),
      workoutsPerWeek: _text(row['workouts'], '3 days'),
      workoutLength: _text(row['workout_length'], '45 minutes'),
      workoutPeriod: _text(row['workout_period'], 'flexible'),
      workoutWhere: _text(row['workout_where'], 'gym or home'),
      mealsPerDay: _text(row['meals'], '3'),
      snacksPerDay: _intValue(row['snacks']).clamp(0, 5),
      foodAllergies: _text(row['food_alergies'], 'none stated'),
    );
  }

  String get promptSummary => '''
Age: $age
Gender: $gender
Height: $heightCm cm
Weight: $weightKg kg
Primary goal: $goal
Training level: $workoutLevel
Training frequency: $workoutsPerWeek per week
Preferred session length: $workoutLength
Preferred training time: $workoutPeriod
Training location/equipment context: $workoutWhere
Meals per day: $mealsPerDay
Snacks per day: $snacksPerDay
Food allergies or exclusions: $foodAllergies''';
}

class StarterPlanSet {
  const StarterPlanSet({required this.weightKg, required this.reps});

  final double weightKg;
  final int reps;

  factory StarterPlanSet.fromJson(Map<String, dynamic> json) => StarterPlanSet(
        weightKg: _doubleValue(json['weight_kg']).clamp(0, 500),
        reps: _intValue(json['reps'], 10).clamp(1, 100),
      );
}

class StarterPlanExercise {
  const StarterPlanExercise({required this.name, required this.sets});

  final String name;
  final List<StarterPlanSet> sets;

  factory StarterPlanExercise.fromJson(Map<String, dynamic> json) =>
      StarterPlanExercise(
        name: _text(json['name'], 'Exercise'),
        sets: _list(json['sets'])
            .map(_map)
            .where((item) => item.isNotEmpty)
            .map(StarterPlanSet.fromJson)
            .toList(),
      );
}

class StarterPlanWorkout {
  const StarterPlanWorkout({
    required this.id,
    required this.dayIndex,
    required this.name,
    required this.category,
    required this.estimatedMinutes,
    required this.exercises,
  });

  final String id;
  final int dayIndex;
  final String name;
  final String category;
  final int estimatedMinutes;
  final List<StarterPlanExercise> exercises;

  factory StarterPlanWorkout.fromJson(Map<String, dynamic> json) =>
      StarterPlanWorkout(
        id: _text(json['id']),
        dayIndex: _intValue(json['day_index']).clamp(0, 27),
        name: _text(json['name'], 'AI workout'),
        category: _text(json['category'], 'Personalized plan'),
        estimatedMinutes:
            _intValue(json['estimated_minutes'], 45).clamp(10, 180),
        exercises: _list(json['exercises'])
            .map(_map)
            .where((item) => item.isNotEmpty)
            .map(StarterPlanExercise.fromJson)
            .where((item) => item.sets.isNotEmpty)
            .toList(),
      );
}

class StarterPlannedMeal {
  const StarterPlannedMeal({
    required this.id,
    required this.dayIndex,
    required this.mealType,
    required this.name,
    required this.description,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final String id;
  final int dayIndex;
  final String mealType;
  final String name;
  final String description;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;

  factory StarterPlannedMeal.fromJson(Map<String, dynamic> json) =>
      StarterPlannedMeal(
        id: _text(json['id']),
        dayIndex: _intValue(json['day_index']).clamp(0, 27),
        mealType: _text(json['meal_type'], 'Meal'),
        name: _text(json['name'], 'Planned meal'),
        description: _text(json['description']),
        calories: _intValue(json['calories']).clamp(0, 5000),
        proteinG: _intValue(json['protein_g']).clamp(0, 500),
        carbsG: _intValue(json['carbs_g']).clamp(0, 750),
        fatG: _intValue(json['fat_g']).clamp(0, 300),
      );
}

class StarterNutritionGoals {
  const StarterNutritionGoals({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;

  factory StarterNutritionGoals.fromJson(Map<String, dynamic> json) =>
      StarterNutritionGoals(
        calories: _intValue(json['calories'], 2200).clamp(800, 10000),
        proteinG: _intValue(json['protein_g'], 165).clamp(1, 1000),
        carbsG: _intValue(json['carbs_g'], 250).clamp(1, 1500),
        fatG: _intValue(json['fat_g'], 70).clamp(1, 500),
      );
}

class StarterPlan {
  const StarterPlan({
    required this.userId,
    required this.status,
    required this.periodStart,
    required this.periodEnd,
    required this.workouts,
    required this.meals,
    required this.nutritionGoals,
    required this.generatedAt,
  });

  final String userId;
  final String status;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<StarterPlanWorkout> workouts;
  final List<StarterPlannedMeal> meals;
  final StarterNutritionGoals nutritionGoals;
  final DateTime? generatedAt;

  String get syncKey =>
      '$userId:${_dateKey(periodStart)}:${generatedAt?.toUtc().toIso8601String() ?? 'ready'}';

  factory StarterPlan.fromRow(Map<String, dynamic> row) {
    final plan = _map(row['plan']);
    final start =
        DateTime.tryParse(_text(row['period_start'])) ?? DateTime.now();
    return StarterPlan(
      userId: _text(row['user_id']),
      status: _text(row['status'], 'requested'),
      periodStart: _dateOnly(start.toLocal()),
      periodEnd: _dateOnly(DateTime.tryParse(_text(row['period_end'])) ??
          start.add(const Duration(days: 27))),
      workouts: _list(plan['workouts'])
          .map(_map)
          .where((item) => item.isNotEmpty)
          .map(StarterPlanWorkout.fromJson)
          .where((item) => item.id.isNotEmpty && item.exercises.isNotEmpty)
          .toList(),
      meals: _list(plan['meals'])
          .map(_map)
          .where((item) => item.isNotEmpty)
          .map(StarterPlannedMeal.fromJson)
          .where((item) => item.id.isNotEmpty)
          .toList(),
      nutritionGoals:
          StarterNutritionGoals.fromJson(_map(plan['nutrition_goals'])),
      generatedAt: DateTime.tryParse(_text(row['generated_at']))?.toLocal(),
    );
  }

  List<StarterPlannedMeal> mealsForDate(DateTime date) {
    final index = _dateOnly(date).difference(periodStart).inDays;
    if (index < 0 || index > 27) return const [];
    return meals.where((meal) => meal.dayIndex == index).toList();
  }
}

class StarterPlanRepository {
  static const String _geminiPlanModel = 'gemini-3.5-flash-lite';

  StarterPlanRepository({AiService? aiService, StarterPlanAiCall? aiCall})
      : _aiService = aiService ?? AiService(),
        _aiCall = aiCall;

  final AiService _aiService;
  final StarterPlanAiCall? _aiCall;
  final Set<String> _providersUsed = <String>{};

  /// Providers that produced a response during the latest generation. This is
  /// primarily useful for diagnostics and live verification of fallback use.
  Set<String> get providersUsed => Set<String>.unmodifiable(_providersUsed);

  SupabaseClient get _db => supabase;
  String? get _uid => _db.auth.currentUser?.id;

  Future<StarterPlan?> load() async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final row = await _db
          .from('starter_plans')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      return row == null ? null : StarterPlan.fromRow(row);
    } on PostgrestException catch (error) {
      // A staged app rollout must not break Train/Diary before migration 0018
      // has been applied to the project.
      if (error.code == '42P01' || error.code == 'PGRST205') return null;
      rethrow;
    }
  }

  Future<StarterPlan?> loadReady() async {
    final plan = await load();
    return plan?.status == 'ready' ? plan : null;
  }

  Future<List<StarterPlannedMeal>> mealsForDate(DateTime date) async {
    final plan = await loadReady();
    return plan?.mealsForDate(date) ?? const [];
  }

  Future<StarterPlanProfile?> loadCurrentProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    final row =
        await _db.from('profile_private').select().eq('id', uid).maybeSingle();
    return row == null ? null : StarterPlanProfile.fromPrivateProfile(row);
  }

  Future<StarterPlan> requestAndGenerate(
    StarterPlanProfile profile, {
    DateTime? startDate,
    bool force = false,
  }) async {
    _providersUsed.clear();
    final uid = _requireUid();
    final existing = await load();
    if (!force && existing?.status == 'ready') return existing!;

    final start = _dateOnly(startDate ?? DateTime.now());
    final end = start.add(const Duration(days: 27));
    await _db.from('starter_plans').upsert({
      'user_id': uid,
      'status': 'generating',
      'prompt_version': 1,
      'period_start': _dateKey(start),
      'period_end': _dateKey(end),
      'last_error': '',
      'requested_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');

    String rawWorkout = '';
    String rawMeal = '';
    try {
      final responses = await Future.wait<String?>([
        _callAi(
          _workoutMessages(profile),
          maxTokens: 16000,
          temperature: 0.35,
          jsonObject: true,
        ),
        _callAi(
          _mealMessages(profile),
          maxTokens: 30000,
          temperature: 0.35,
          jsonObject: true,
        ),
      ]);
      rawWorkout = responses[0]?.trim() ?? '';
      rawMeal = responses[1]?.trim() ?? '';
      if (rawWorkout.isEmpty || rawMeal.isEmpty) {
        throw const FormatException('The AI returned an empty starter plan.');
      }

      final workoutJson = _decodeJsonObject(rawWorkout, listKey: 'workouts');
      var mealJson = _decodeJsonObject(rawMeal, listKey: 'meals');
      late Map<String, dynamic> normalized;
      try {
        normalized = _normalizePlan(
          workoutJson,
          mealJson,
          foodAllergies: profile.foodAllergies,
        );
      } on StarterPlanAllergyException catch (error) {
        // A provider response is not trusted merely because it is valid JSON.
        // Regenerate the nutrition half with the fallback provider and run the
        // exact same deterministic validator before persisting anything.
        rawMeal = (await _callAllergyRepairFallback(
              profile,
              allergen: error.allergen,
              maxTokens: 30000,
            ))
                ?.trim() ??
            '';
        if (rawMeal.isEmpty) {
          throw const FormatException(
            'The allergy-safe meal-plan fallback returned an empty response.',
          );
        }
        mealJson = _decodeJsonObject(rawMeal, listKey: 'meals');
        normalized = _normalizePlan(
          workoutJson,
          mealJson,
          foodAllergies: profile.foodAllergies,
        );
      }
      final workouts = _list(normalized['workouts']);
      final meals = _list(normalized['meals']);
      final expectedWorkouts = profile.minimumWorkoutsPerWeek * 4;
      if (workouts.length < expectedWorkouts ||
          !_coversEveryTrainingWeek(workouts, profile.minimumWorkoutsPerWeek)) {
        throw const FormatException(
            'The AI workout plan did not match the selected weekly frequency.');
      }
      if (!_coversEveryMealPlanDay(meals)) {
        throw const FormatException(
            'The AI meal plan did not cover the full four weeks.');
      }

      final generatedAt = DateTime.now().toUtc();
      final row = await _db
          .from('starter_plans')
          .update({
            'status': 'ready',
            'plan': normalized,
            'raw_workout': rawWorkout,
            'raw_meal': rawMeal,
            'last_error': '',
            'generated_at': generatedAt.toIso8601String(),
          })
          .eq('user_id', uid)
          .select()
          .single();

      final goals = _map(normalized['nutrition_goals']);
      await _db.from('profile_private').update({
        'workout_plan': rawWorkout,
        'meal_plan': rawMeal,
        'caloric_intake_per_day': _intValue(goals['calories']).toString(),
        'calories_intake': _intValue(goals['calories']).toString(),
        'protein_per_day': _intValue(goals['protein_g']).toString(),
        'carbs_per_day': _intValue(goals['carbs_g']).toString(),
        'fats_per_day': _intValue(goals['fat_g']).toString(),
      }).eq('id', uid);
      return StarterPlan.fromRow(row);
    } catch (error) {
      await _db.from('starter_plans').update({
        'status': 'failed',
        'raw_workout': rawWorkout,
        'raw_meal': rawMeal,
        'last_error': error
            .toString()
            .substring(0, error.toString().length.clamp(0, 1000)),
      }).eq('user_id', uid);
      rethrow;
    }
  }

  Future<String?> _callAi(
    List<Map<String, dynamic>> messages, {
    int? maxTokens,
    double? temperature,
    bool jsonObject = false,
  }) {
    final override = _aiCall;
    if (override != null) {
      _providersUsed.add('override');
      return override(messages,
          maxTokens: maxTokens,
          temperature: temperature,
          jsonObject: jsonObject);
    }
    return _callPrimaryThenFallback(
      messages,
      maxTokens: maxTokens,
      temperature: temperature,
      jsonObject: jsonObject,
    );
  }

  Future<String?> _callPrimaryThenFallback(
    List<Map<String, dynamic>> messages, {
    int? maxTokens,
    double? temperature,
    bool jsonObject = false,
  }) async {
    try {
      final result = await _aiService.openAiChat(
        messages,
        // gpt-4o-mini supports less output than Gemini. The monthly JSON fits
        // below this ceiling because meal descriptions are deliberately short.
        maxTokens: maxTokens?.clamp(1, 16000),
        temperature: temperature,
        jsonObject: jsonObject,
      );
      if (result == null || result.trim().isEmpty) {
        throw StateError('OpenAI returned an empty starter-plan response.');
      }
      _providersUsed.add('openai');
      return result;
    } catch (openAiError) {
      try {
        final result = await _aiService.geminiChat(
          messages,
          model: _geminiPlanModel,
          maxTokens: maxTokens,
          temperature: temperature,
          jsonObject: jsonObject,
        );
        if (result == null || result.trim().isEmpty) {
          throw StateError('Gemini returned an empty starter-plan response.');
        }
        _providersUsed.add('gemini');
        return result;
      } catch (geminiError) {
        throw Exception(
          'Starter-plan AI providers failed. '
          'OpenAI: $openAiError; Gemini: $geminiError',
        );
      }
    }
  }

  Future<String?> _callAllergyRepairFallback(
    StarterPlanProfile profile, {
    required String allergen,
    required int maxTokens,
  }) async {
    final messages = <Map<String, dynamic>>[
      ..._mealMessages(profile),
      {
        'role': 'system',
        'content': 'A previous provider violated the strict food exclusion. '
            'Regenerate the complete plan. Do not use or mention "$allergen" '
            'anywhere—not as an ingredient and not in phrases such as "no $allergen". '
            'Check every meal name and description before returning JSON.',
      },
    ];
    final override = _aiCall;
    if (override != null) {
      _providersUsed.add('override');
      return override(
        messages,
        maxTokens: maxTokens,
        temperature: 0.2,
        jsonObject: true,
      );
    }
    final result = await _aiService.geminiChat(
      messages,
      model: _geminiPlanModel,
      maxTokens: maxTokens,
      temperature: 0.2,
      jsonObject: true,
    );
    if (result == null || result.trim().isEmpty) {
      throw StateError('Gemini returned an empty allergy-repair response.');
    }
    _providersUsed.add('gemini');
    return result;
  }

  List<Map<String, dynamic>> _workoutMessages(StarterPlanProfile profile) => [
        {
          'role': 'system',
          'content': 'You create safe, practical four-week fitness plans for GymFeed. '
              'Return one valid JSON object only. Do not include markdown. '
              'Use conservative starting weights when experience/equipment is unclear; use 0 kg for bodyweight movements. '
              'Include rest/recovery days by omitting workouts for those day indexes.'
        },
        {
          'role': 'user',
          'content': '''Create a complete personalized 28-day workout plan.

${profile.promptSummary}

JSON schema:
{"workouts":[{"day_index":0,"name":"Upper body","category":"Chest · Shoulders · Triceps","estimated_minutes":45,"exercises":[{"name":"Bench Press","sets":[{"weight_kg":20,"reps":10}]}]}]}

Rules:
- day_index is an integer from 0 through 27, where 0 is the first plan day.
- Match the requested weekly training frequency for each of all four weeks.
- If the frequency is a range, use its lower number (for example, 3-4 means 3 days per week).
- Every workout must contain 3-6 exercises and every exercise 1-6 explicit sets.
- Set kg and reps individually for every set so the routine is ready to start and edit.
- Progress safely across weeks instead of duplicating identical sessions.
- Names and categories must be concise. No extra keys or prose outside JSON.'''
        }
      ];

  List<Map<String, dynamic>> _mealMessages(StarterPlanProfile profile) => [
        {
          'role': 'system',
          'content': 'You create practical four-week nutrition plans for GymFeed. '
              'Return one valid JSON object only. Do not include markdown. '
              'Food allergies and exclusions are strict. Nutrition numbers are realistic estimates, not medical claims.'
        },
        {
          'role': 'user',
          'content': '''Create a complete personalized 28-day meal plan.

${profile.promptSummary}

JSON schema:
{"nutrition_goals":{"calories":2200,"protein_g":165,"carbs_g":250,"fat_g":70},"meals":[{"day_index":0,"meal_type":"Breakfast","name":"Overnight oats","description":"Oats, yogurt, berries; mix and chill overnight.","calories":450,"protein_g":30,"carbs_g":55,"fat_g":12}]}

Rules:
- Cover every day_index from 0 through 27.
- Include Breakfast, Lunch and Dinner every day, plus the requested snacks when appropriate.
- Never include any listed allergen or excluded food.
- Do not mention excluded food names even in disclaimers such as "no peanuts" or "nut-free". Use a different safe meal instead.
- Before returning JSON, scan every meal name and description against the exclusions.
- Give a preparation description of at most 14 words and numeric calories/macros for each meal.
- Daily totals should stay reasonably close to nutrition_goals.
- Keep descriptions compact so the entire month fits. No extra keys or prose outside JSON.'''
        }
      ];

  Map<String, dynamic> _decodeJsonObject(
    String raw, {
    required String listKey,
  }) {
    var cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\s*```$'), '');
    }
    dynamic decoded = jsonDecode(cleaned);
    // Some providers occasionally JSON-encode the whole structured response as
    // a string. Decode that second layer instead of discarding a valid plan.
    if (decoded is String) {
      var nested = decoded.trim();
      nested = nested.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      nested = nested.replaceFirst(RegExp(r'\s*```$'), '');
      decoded = jsonDecode(nested);
    }
    if (decoded is Map) return _map(decoded);
    // A root array is also unambiguous because workout and meal calls are
    // separate. Normalize it to the canonical object used by the app.
    if (decoded is List) return {listKey: decoded};
    throw FormatException(
      'The starter plan JSON root was ${decoded.runtimeType}, not an object or array.',
    );
  }

  Map<String, dynamic> _normalizePlan(
    Map<String, dynamic> workout,
    Map<String, dynamic> meal, {
    required String foodAllergies,
  }) {
    final workouts = <Map<String, dynamic>>[];
    var workoutIndex = 0;
    for (final entry in _list(workout['workouts']).map(_map)) {
      final dayIndex = _intValue(entry['day_index']).clamp(0, 27);
      final exercises = <Map<String, dynamic>>[];
      for (final exercise in _list(entry['exercises']).map(_map).take(8)) {
        final sets = _list(exercise['sets'])
            .map(_map)
            .take(6)
            .map((set) => {
                  'weight_kg': _doubleValue(set['weight_kg']).clamp(0, 500),
                  'reps': _intValue(set['reps'], 10).clamp(1, 100),
                })
            .toList();
        if (sets.isEmpty) continue;
        exercises.add({
          'name': _text(exercise['name'], 'Exercise'),
          'sets': sets,
        });
      }
      if (exercises.isEmpty) continue;
      workouts.add({
        'id': 'starter-workout-$dayIndex-${workoutIndex++}',
        'day_index': dayIndex,
        'name': _text(entry['name'], 'AI workout'),
        'category': _text(entry['category'], 'Personalized plan'),
        'estimated_minutes':
            _intValue(entry['estimated_minutes'], 45).clamp(10, 180),
        'exercises': exercises,
      });
    }
    workouts.sort((a, b) =>
        _intValue(a['day_index']).compareTo(_intValue(b['day_index'])));

    final meals = <Map<String, dynamic>>[];
    var mealIndex = 0;
    for (final entry in _list(meal['meals']).map(_map)) {
      final dayIndex = _intValue(entry['day_index']).clamp(0, 27);
      final type = _text(entry['meal_type'], 'Meal');
      meals.add({
        'id': 'starter-meal-$dayIndex-${mealIndex++}',
        'day_index': dayIndex,
        'meal_type': type,
        'name': sanitizeStarterPlanMealText(
          _text(entry['name'], 'Planned meal'),
          foodAllergies,
        ),
        'description': sanitizeStarterPlanMealText(
          _text(entry['description']),
          foodAllergies,
        ),
        'calories': _intValue(entry['calories']).clamp(0, 5000),
        'protein_g': _intValue(entry['protein_g']).clamp(0, 500),
        'carbs_g': _intValue(entry['carbs_g']).clamp(0, 750),
        'fat_g': _intValue(entry['fat_g']).clamp(0, 300),
      });
    }
    meals.sort((a, b) =>
        _intValue(a['day_index']).compareTo(_intValue(b['day_index'])));

    final rawGoals = _map(meal['nutrition_goals']);
    return {
      'version': 1,
      'nutrition_goals': {
        'calories': _intValue(rawGoals['calories'], 2200).clamp(800, 10000),
        'protein_g': _intValue(rawGoals['protein_g'], 165).clamp(1, 1000),
        'carbs_g': _intValue(rawGoals['carbs_g'], 250).clamp(1, 1500),
        'fat_g': _intValue(rawGoals['fat_g'], 70).clamp(1, 500),
      },
      'workouts': workouts,
      'meals': meals,
    };
  }

  bool _coversEveryTrainingWeek(
    List<dynamic> workouts,
    int minimumPerWeek,
  ) {
    for (var week = 0; week < 4; week++) {
      final firstDay = week * 7;
      final lastDay = firstDay + 6;
      final days = workouts
          .map(_map)
          .map((item) => _intValue(item['day_index'], -1))
          .where((day) => day >= firstDay && day <= lastDay)
          .toSet();
      if (days.length < minimumPerWeek) return false;
    }
    return true;
  }

  bool _coversEveryMealPlanDay(List<dynamic> meals) {
    for (var day = 0; day < 28; day++) {
      final types = meals
          .map(_map)
          .where((item) => _intValue(item['day_index'], -1) == day)
          .map((item) => _text(item['meal_type']).toLowerCase())
          .toSet();
      if (!types.contains('breakfast') ||
          !types.contains('lunch') ||
          !types.contains('dinner')) {
        return false;
      }
    }
    return true;
  }

  String _requireUid() {
    final uid = _uid;
    if (uid == null) {
      throw StateError('No authenticated user for starter-plan generation.');
    }
    return uid;
  }
}
