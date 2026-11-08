import '/backend/supabase/supabase.dart';
import '/workout/routines/workout_routine_models.dart';
import '/workout/routines/workout_routine_store.dart';
import 'starter_plan_repository.dart';

class CoachScheduledWorkout {
  const CoachScheduledWorkout({required this.date, required this.routine});
  final DateTime date;
  final WorkoutRoutine routine;

  Map<String, dynamic> toJson() => {
        'date': WorkoutRoutineStore.dateKey(date),
        'routine': routine.toJson(),
      };

  factory CoachScheduledWorkout.fromJson(Map<String, dynamic> json) =>
      CoachScheduledWorkout(
        date: DateTime.parse(json['date'] as String),
        routine: WorkoutRoutine.fromJson(
            Map<String, dynamic>.from(json['routine'] as Map)),
      );
}

class CoachScheduledMeal {
  const CoachScheduledMeal({required this.date, required this.meal});
  final DateTime date;
  final StarterPlannedMeal meal;

  Map<String, dynamic> toJson() => {
        'date': WorkoutRoutineStore.dateKey(date),
        'meal': {
          'id': meal.id,
          'meal_type': meal.mealType,
          'name': meal.name,
          'description': meal.description,
          'calories': meal.calories,
          'protein_g': meal.proteinG,
          'carbs_g': meal.carbsG,
          'fat_g': meal.fatG,
        },
      };

  factory CoachScheduledMeal.fromJson(Map<String, dynamic> json) =>
      CoachScheduledMeal(
        date: DateTime.parse(json['date'] as String),
        meal: StarterPlannedMeal.fromJson(
            Map<String, dynamic>.from(json['meal'] as Map)),
      );
}

/// The exact reviewed plan is persisted separately from the conversational text.
/// Stable ids let retries and other devices apply it without creating copies.
class CoachPlanAction {
  const CoachPlanAction({
    required this.id,
    required this.workouts,
    required this.meals,
    this.status = 'pending',
  });
  final String id;
  final List<CoachScheduledWorkout> workouts;
  final List<CoachScheduledMeal> meals;
  final String status;
  bool get pending => status == 'pending';
  bool get implemented => status == 'implemented';

  List<DateTime> get dates => [
        ...workouts.map((item) => item.date),
        ...meals.map((item) => item.date),
      ]..sort();

  String get receipt {
    final destinations = [
      if (workouts.isNotEmpty)
        '${workouts.length} ${workouts.length == 1 ? 'workout' : 'workouts'} to Train',
      if (meals.isNotEmpty)
        '${meals.length} planned ${meals.length == 1 ? 'meal' : 'meals'} to Meal Diary',
    ];
    return 'Added ${destinations.join(' and ')} '
        '(${WorkoutRoutineStore.dateKey(dates.first)}'
        '${dates.first == dates.last ? '' : ' – ${WorkoutRoutineStore.dateKey(dates.last)}'}).';
  }

  CoachPlanAction withStatus(String value) =>
      CoachPlanAction(id: id, workouts: workouts, meals: meals, status: value);

  Map<String, dynamic> toJson() => {
        'workouts': workouts.map((item) => item.toJson()).toList(),
        'meals': meals.map((item) => item.toJson()).toList(),
      };

  factory CoachPlanAction.fromRow(Map<String, dynamic> row) {
    final payload = Map<String, dynamic>.from(row['payload'] as Map);
    return CoachPlanAction(
      id: row['id'] as String,
      status: row['status'] as String? ?? 'pending',
      workouts: (payload['workouts'] as List? ?? const [])
          .map((item) => CoachScheduledWorkout.fromJson(
              Map<String, dynamic>.from(item as Map)))
          .toList(),
      meals: (payload['meals'] as List? ?? const [])
          .map((item) => CoachScheduledMeal.fromJson(
              Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

class CoachPlanUnavailableException implements Exception {
  const CoachPlanUnavailableException(this.action);
  final CoachPlanAction action;
}

class CoachPlanRepository {
  SupabaseClient get _db => supabase;
  String? get _uid => _db.auth.currentUser?.id;

  Future<CoachPlanAction?> latest() async {
    if (_uid == null) return null;
    final rows = await _db
        .from('ai_coach_plan_actions')
        .select()
        .eq('user_id', _uid!)
        .order('created_at', ascending: false)
        .limit(1);
    return rows.isEmpty ? null : CoachPlanAction.fromRow(rows.first);
  }

  Future<Map<String, CoachPlanAction>> byIds(List<String> ids) async {
    if (_uid == null || ids.isEmpty) return {};
    final rows = await _db
        .from('ai_coach_plan_actions')
        .select()
        .eq('user_id', _uid!)
        .inFilter('id', ids);
    return {
      for (final row in rows) row['id'] as String: CoachPlanAction.fromRow(row)
    };
  }

  Future<CoachPlanAction> saveProposal(CoachPlanAction action) async {
    final row = await _db.rpc('save_coach_plan_action', params: {
      'p_id': action.id,
      'p_payload': action.toJson(),
      'p_start_date': WorkoutRoutineStore.dateKey(action.dates.first),
      'p_end_date': WorkoutRoutineStore.dateKey(action.dates.last),
    });
    return CoachPlanAction.fromRow(Map<String, dynamic>.from(row as Map));
  }

  Future<CoachPlanAction> setStatus(String id, String status) async {
    final row = await _db.rpc('set_coach_plan_action_status', params: {
      'p_id': id,
      'p_status': status,
    });
    return CoachPlanAction.fromRow(Map<String, dynamic>.from(row as Map));
  }

  Future<CoachPlanAction> implement(CoachPlanAction action) async {
    // Commit the cloud plan first. If local materialization fails, the same
    // action remains implemented and Train can retry its import on next open.
    final saved = await setStatus(action.id, 'implemented');
    if (!saved.implemented) throw CoachPlanUnavailableException(saved);
    await materializeWorkouts(saved);
    return saved;
  }

  static Future<void> materializeWorkouts(CoachPlanAction action) async {
    if (!action.implemented || action.workouts.isEmpty) return;
    await WorkoutRoutineStore.importPlan(
      planKey: 'coach-${action.id}',
      syncKey: action.id,
      routines: action.workouts.map((item) => item.routine).toList(),
      schedule: {
        for (final date in action.workouts.map((item) => item.date).toSet())
          WorkoutRoutineStore.dateKey(date): action.workouts
              .where((item) => item.date == date)
              .map((item) => item.routine.id)
              .toList(),
      },
    );
  }

  Future<void> syncWorkouts() async {
    if (_uid == null) return;
    final rows = await _db
        .from('ai_coach_plan_actions')
        .select()
        .eq('user_id', _uid!)
        .eq('status', 'implemented')
        .order('created_at', ascending: true);
    for (final row in rows) {
      await materializeWorkouts(CoachPlanAction.fromRow(row));
    }
  }

  Future<List<StarterPlannedMeal>> mealsForDate(DateTime date) async {
    if (_uid == null) return const [];
    final key = WorkoutRoutineStore.dateKey(date);
    final rows = await _db
        .from('ai_coach_plan_actions')
        .select()
        .eq('user_id', _uid!)
        .eq('status', 'implemented')
        .lte('start_date', key)
        .gte('end_date', key)
        .order('created_at', ascending: true);
    return [
      for (final row in rows)
        for (final item in CoachPlanAction.fromRow(row).meals)
          if (WorkoutRoutineStore.dateKey(item.date) == key) item.meal,
    ];
  }

  Future<List<Map<String, dynamic>>> mealsForWindow(
      DateTime start, DateTime end) async {
    if (_uid == null) return const [];
    final first = WorkoutRoutineStore.dateKey(start);
    final last = WorkoutRoutineStore.dateKey(end);
    final rows = await _db
        .from('ai_coach_plan_actions')
        .select()
        .eq('user_id', _uid!)
        .eq('status', 'implemented')
        .lte('start_date', last)
        .gte('end_date', first);
    return [
      for (final row in rows)
        for (final item in CoachPlanAction.fromRow(row).meals)
          if (!item.date.isBefore(start) && !item.date.isAfter(end))
            item.toJson(),
    ];
  }
}
