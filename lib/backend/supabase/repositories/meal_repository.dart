import 'dart:convert';

import '/backend/supabase/supabase.dart';
import 'starter_plan_repository.dart';

double _number(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(value?.toString() ?? '');
  return double.tryParse(match?.group(0) ?? '') ?? fallback;
}

class MealScan {
  MealScan(this.data);

  final Map<String, dynamic> data;

  String get id => (data['id'] ?? '').toString();
  String get userId => (data['user_id'] ?? '').toString();
  String get foodName => (data['dish_name'] ?? '').toString();
  String get description => (data['description'] ?? '').toString();
  double get calories => _number(data['calories']);
  double get proteinG => _number(data['protein']);
  double get carbsG => _number(data['carbs']);
  double get fatG => _number(data['fats']);
  DateTime? get scannedAt => data['scanned_on'] == null
      ? null
      : DateTime.tryParse(data['scanned_on'].toString())?.toLocal();
  DateTime? get createdAt => data['created_at'] == null
      ? null
      : DateTime.tryParse(data['created_at'].toString())?.toLocal();

  Map<String, dynamic> get metadata {
    try {
      final decoded = jsonDecode((data['gemini_parse'] ?? '').toString());
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  String? get photoUrl {
    final value = metadata['photo_url']?.toString();
    return value == null || value.isEmpty ? null : value;
  }

  String get portionSize => (metadata['portion_size'] ?? '').toString();
  String get starterPlanMealId =>
      (metadata['starter_plan_meal_id'] ?? '').toString();
  String get mealType {
    final stored = metadata['meal_type']?.toString();
    if (stored != null && stored.isNotEmpty) return stored;
    final hour = scannedAt?.hour ?? 12;
    if (hour < 11) return 'Breakfast';
    if (hour < 15) return 'Lunch';
    if (hour < 18) return 'Snack';
    return 'Dinner';
  }
}

class NutritionGoals {
  const NutritionGoals({
    this.calories = 2200,
    this.proteinG = 165,
    this.carbsG = 250,
    this.fatG = 70,
  });

  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;

  factory NutritionGoals.fromRow(Map<String, dynamic>? row) => NutritionGoals(
        calories: _number(row?['caloric_intake_per_day'], 2200)
            .round()
            .clamp(800, 10000),
        proteinG: _number(row?['protein_per_day'], 165).round().clamp(1, 1000),
        carbsG: _number(row?['carbs_per_day'], 250).round().clamp(1, 1500),
        fatG: _number(row?['fats_per_day'], 70).round().clamp(1, 500),
      );
}

class NutritionDay {
  const NutritionDay({
    required this.meals,
    required this.goals,
    this.plannedMeals = const [],
  });

  final List<MealScan> meals;
  final NutritionGoals goals;
  final List<StarterPlannedMeal> plannedMeals;

  double get calories => meals.fold(0, (sum, meal) => sum + meal.calories);
  double get proteinG => meals.fold(0, (sum, meal) => sum + meal.proteinG);
  double get carbsG => meals.fold(0, (sum, meal) => sum + meal.carbsG);
  double get fatG => meals.fold(0, (sum, meal) => sum + meal.fatG);
}

/// Supabase-backed nutrition diary. The deployed `meal_scans` table uses the
/// original scanner column names, so all food UI goes through this repository
/// instead of mixing the legacy and proposed schemas.
class MealRepository {
  MealRepository({StarterPlanRepository? starterPlans})
      : _starterPlans = starterPlans ?? StarterPlanRepository();

  final StarterPlanRepository _starterPlans;
  SupabaseClient get _db => supabase;
  String? get _uid => _db.auth.currentUser?.id;

  Future<List<MealScan>> myScans({int limit = 30, DateTime? before}) async {
    final uid = _uid;
    if (uid == null) return const [];
    var query = _db.from('meal_scans').select().eq('user_id', uid);
    if (before != null) {
      query = query.lt('created_at', before.toUtc().toIso8601String());
    }
    final rows = await query.order('created_at', ascending: false).limit(limit);
    return (rows as List)
        .map((row) => MealScan(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<MealScan>> forDate(DateTime date) async {
    final uid = _uid;
    if (uid == null) return const [];
    final localStart = DateTime(date.year, date.month, date.day);
    final localEnd = localStart.add(const Duration(days: 1));
    final rows = await _db
        .from('meal_scans')
        .select()
        .eq('user_id', uid)
        .gte('scanned_on', localStart.toUtc().toIso8601String())
        .lt('scanned_on', localEnd.toUtc().toIso8601String())
        .order('scanned_on', ascending: true);
    return (rows as List)
        .map((row) => MealScan(row as Map<String, dynamic>))
        .toList();
  }

  Future<NutritionGoals> loadGoals() async {
    final uid = _uid;
    if (uid == null) return const NutritionGoals();
    final row = await _db
        .from('profile_private')
        .select(
            'caloric_intake_per_day,protein_per_day,carbs_per_day,fats_per_day')
        .eq('id', uid)
        .maybeSingle();
    return NutritionGoals.fromRow(row);
  }

  Future<NutritionDay> loadDay(DateTime date) async {
    final results = await Future.wait<dynamic>(
        [forDate(date), loadGoals(), _starterPlans.mealsForDate(date)]);
    return NutritionDay(
      meals: results[0] as List<MealScan>,
      goals: results[1] as NutritionGoals,
      plannedMeals: results[2] as List<StarterPlannedMeal>,
    );
  }

  Future<void> saveGoals(NutritionGoals goals) async {
    final uid = _requireUid();
    await _db.from('profile_private').update({
      'caloric_intake_per_day': goals.calories.toString(),
      'calories_intake': goals.calories.toString(),
      'protein_per_day': goals.proteinG.toString(),
      'carbs_per_day': goals.carbsG.toString(),
      'fats_per_day': goals.fatG.toString(),
    }).eq('id', uid);
  }

  Future<MealScan> save({
    required String foodName,
    String description = '',
    required double calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
    String? portionSize,
    String? photoUrl,
    String? mealType,
    Map<String, dynamic>? analysis,
    DateTime? scannedAt,
  }) async {
    final uid = _requireUid();
    final metadata = <String, dynamic>{
      ...?analysis,
      if (photoUrl != null && photoUrl.isNotEmpty) 'photo_url': photoUrl,
      if (portionSize != null && portionSize.isNotEmpty)
        'portion_size': portionSize,
      if (mealType != null && mealType.isNotEmpty) 'meal_type': mealType,
    };
    final row = await _db
        .from('meal_scans')
        .insert({
          'user_id': uid,
          'dish_name': foodName.trim(),
          'description': description.trim(),
          'gemini_parse': jsonEncode(metadata),
          'calories': calories.round().clamp(0, 20000),
          'protein': proteinG.round().clamp(0, 2000),
          'carbs': carbsG.round().clamp(0, 3000),
          'fats': fatG.round().clamp(0, 2000),
          'is_checked': true,
          'scanned_on': (scannedAt ?? DateTime.now()).toUtc().toIso8601String(),
        })
        .select()
        .single();
    return MealScan(row);
  }

  Future<MealScan> logPlannedMeal(
    StarterPlannedMeal meal,
    DateTime date,
  ) {
    final hour = switch (meal.mealType.toLowerCase()) {
      'breakfast' => 8,
      'lunch' => 13,
      'dinner' => 19,
      _ => 16,
    };
    return save(
      foodName: meal.name,
      description: meal.description,
      calories: meal.calories.toDouble(),
      proteinG: meal.proteinG.toDouble(),
      carbsG: meal.carbsG.toDouble(),
      fatG: meal.fatG.toDouble(),
      mealType: meal.mealType,
      scannedAt: DateTime(date.year, date.month, date.day, hour),
      analysis: {
        'starter_plan_meal_id': meal.id,
        'source': 'starter_plan',
      },
    );
  }

  Future<void> delete(String scanId) async {
    final uid = _requireUid();
    await _db.from('meal_scans').delete().eq('id', scanId).eq('user_id', uid);
  }

  String _requireUid() {
    final uid = _uid;
    if (uid == null)
      throw StateError('No authenticated user for a meal write.');
    return uid;
  }
}
