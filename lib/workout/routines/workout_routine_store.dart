import 'dart:convert';

import '/auth/firebase_auth/auth_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'workout_routine_models.dart';

class WorkoutRoutineStore {
  WorkoutRoutineStore._();

  static String get _scope => currentUserUid.isEmpty ? 'guest' : currentUserUid;
  static String get _routineKey => 'gymfeed_routines_v1_$_scope';
  static String get _historyKey => 'gymfeed_workout_history_v1_$_scope';
  static String get _scheduleKey => 'gymfeed_workout_schedule_v1_$_scope';
  static String get _starterPlanSyncKey =>
      'gymfeed_starter_plan_sync_v1_$_scope';
  static String get _legacyScheduleSeedCleanupKey =>
      'gymfeed_schedule_seed_cleanup_v1_$_scope';

  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static Future<List<WorkoutRoutine>> loadRoutines() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_routineKey);
    if (encoded == null || encoded.isEmpty) {
      final defaults = defaultRoutines();
      await _writeRoutines(preferences, defaults);
      return defaults;
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) throw const FormatException('Invalid routines');
      return decoded
          .whereType<Map>()
          .map((item) => WorkoutRoutine.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value))))
          .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
          .toList();
    } catch (_) {
      final defaults = defaultRoutines();
      await _writeRoutines(preferences, defaults);
      return defaults;
    }
  }

  static Future<void> saveRoutine(WorkoutRoutine routine) async {
    final preferences = await SharedPreferences.getInstance();
    final routines = await loadRoutines();
    final index = routines.indexWhere((item) => item.id == routine.id);
    if (index == -1) {
      routines.insert(0, routine);
    } else {
      routines[index] = routine;
    }
    await _writeRoutines(preferences, routines);
  }

  /// Materializes a cloud starter plan once per plan version on this device.
  /// Existing routine edits are preserved until a genuinely newer plan arrives.
  static Future<bool> importStarterPlan({
    required String syncKey,
    required List<WorkoutRoutine> routines,
    required Map<String, List<String>> schedule,
  }) async {
    if (syncKey.isEmpty || routines.isEmpty) return false;
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getString(_starterPlanSyncKey) == syncKey) return false;

    final current = await loadRoutines();
    final incomingIds = routines.map((item) => item.id).toSet();
    current.removeWhere((item) => incomingIds.contains(item.id));
    current.insertAll(0, routines);
    await _writeRoutines(preferences, current);

    final currentSchedule = await loadSchedule();
    for (final entry in schedule.entries) {
      final ids = currentSchedule.putIfAbsent(entry.key, () => <String>[]);
      for (final routineId in entry.value) {
        if (!ids.contains(routineId)) ids.add(routineId);
      }
    }
    await _writeSchedule(preferences, currentSchedule);
    await preferences.setString(_starterPlanSyncKey, syncKey);
    return true;
  }

  static Future<void> deleteRoutine(String routineId) async {
    final preferences = await SharedPreferences.getInstance();
    final routines = await loadRoutines();
    routines.removeWhere((item) => item.id == routineId);
    await _writeRoutines(preferences, routines);
    final schedule = await loadSchedule();
    for (final ids in schedule.values) {
      ids.removeWhere((id) => id == routineId);
    }
    schedule.removeWhere((_, ids) => ids.isEmpty);
    await _writeSchedule(preferences, schedule);
  }

  static Future<void> markRoutinePerformed(
      String routineId, DateTime performedAt) async {
    final preferences = await SharedPreferences.getInstance();
    final routines = await loadRoutines();
    final index = routines.indexWhere((item) => item.id == routineId);
    if (index != -1) {
      routines[index] = routines[index].copyWith(lastPerformedAt: performedAt);
      await _writeRoutines(preferences, routines);
    }
  }

  static Future<List<WorkoutHistoryItem>> loadHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_historyKey);
    if (encoded == null || encoded.isEmpty) return <WorkoutHistoryItem>[];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return <WorkoutHistoryItem>[];
      final items = decoded
          .whereType<Map>()
          .map((item) => WorkoutHistoryItem.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value))))
          .toList();
      items.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return items;
    } catch (_) {
      return <WorkoutHistoryItem>[];
    }
  }

  static Future<void> saveHistory(WorkoutHistoryItem item) async {
    final preferences = await SharedPreferences.getInstance();
    final history = await loadHistory();
    history.removeWhere((entry) => entry.id == item.id);
    history.insert(0, item);
    if (history.length > 100) history.removeRange(100, history.length);
    await preferences.setString(_historyKey,
        jsonEncode(history.map((entry) => entry.toJson()).toList()));
    await markRoutinePerformed(item.routineId, item.startedAt);
  }

  static Future<Map<String, List<String>>> loadSchedule() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_scheduleKey);
    if (encoded == null || encoded.isEmpty) {
      return <String, List<String>>{};
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return <String, List<String>>{};
      final schedule = decoded.map<String, List<String>>((key, value) {
        final ids = value is List
            ? value.map((item) => item.toString()).toSet().toList()
            : <String>[];
        return MapEntry(key.toString(), ids);
      });
      if (!(preferences.getBool(_legacyScheduleSeedCleanupKey) ?? false)) {
        final onlyLegacySeed = schedule.length == 1 &&
            schedule.values.single.length == 1 &&
            schedule.values.single.single == 'default-push-day-a';
        final history = preferences.getString(_historyKey);
        final hasHistory = history != null &&
            history.trim().isNotEmpty &&
            history.trim() != '[]';
        final hasImportedPlan =
            (preferences.getString(_starterPlanSyncKey) ?? '').isNotEmpty;
        if (onlyLegacySeed && !hasHistory && !hasImportedPlan) {
          schedule.clear();
          await _writeSchedule(preferences, schedule);
        }
        await preferences.setBool(_legacyScheduleSeedCleanupKey, true);
      }
      return schedule;
    } catch (_) {
      return <String, List<String>>{};
    }
  }

  static Future<void> scheduleRoutine(DateTime date, String routineId) async {
    final preferences = await SharedPreferences.getInstance();
    final schedule = await loadSchedule();
    final ids = schedule.putIfAbsent(dateKey(date), () => <String>[]);
    if (!ids.contains(routineId)) ids.add(routineId);
    await _writeSchedule(preferences, schedule);
  }

  static Future<void> unscheduleRoutine(DateTime date, String routineId) async {
    final preferences = await SharedPreferences.getInstance();
    final schedule = await loadSchedule();
    final key = dateKey(date);
    schedule[key]?.removeWhere((id) => id == routineId);
    if (schedule[key]?.isEmpty ?? false) schedule.remove(key);
    await _writeSchedule(preferences, schedule);
  }

  static Future<void> _writeRoutines(
    SharedPreferences preferences,
    List<WorkoutRoutine> routines,
  ) =>
      preferences.setString(_routineKey,
          jsonEncode(routines.map((item) => item.toJson()).toList()));

  static Future<void> _writeSchedule(
    SharedPreferences preferences,
    Map<String, List<String>> schedule,
  ) =>
      preferences.setString(_scheduleKey, jsonEncode(schedule));

  static List<WorkoutRoutine> defaultRoutines() {
    final created = DateTime(2026, 8, 1);
    return [
      WorkoutRoutine(
        id: 'default-push-day-a',
        name: 'Push Day A',
        category: 'Chest · Shoulders · Triceps',
        createdAt: created,
        lastPerformedAt: DateTime(2026, 8, 8),
        exercises: const [
          RoutineExercise(
              name: 'Bench Press',
              setCount: 3,
              defaultWeightKg: 60,
              defaultReps: 10),
          RoutineExercise(
              name: 'Incline DB Press',
              setCount: 3,
              defaultWeightKg: 24,
              defaultReps: 10),
          RoutineExercise(
              name: 'Shoulder Press',
              setCount: 3,
              defaultWeightKg: 40,
              defaultReps: 10),
          RoutineExercise(
              name: 'Cable Fly',
              setCount: 2,
              defaultWeightKg: 18,
              defaultReps: 12),
          RoutineExercise(
              name: 'Triceps Pushdown',
              setCount: 3,
              defaultWeightKg: 25,
              defaultReps: 12),
        ],
      ),
      WorkoutRoutine(
        id: 'default-pull-day-b',
        name: 'Pull Day B',
        category: 'Back · Biceps',
        createdAt: created,
        lastPerformedAt: DateTime(2026, 8, 9),
        exercises: const [
          RoutineExercise(name: 'Pull Up', setCount: 3, defaultReps: 8),
          RoutineExercise(
              name: 'Barbell Row',
              setCount: 3,
              defaultWeightKg: 55,
              defaultReps: 10),
          RoutineExercise(
              name: 'Lat Pulldown',
              setCount: 3,
              defaultWeightKg: 48,
              defaultReps: 10),
          RoutineExercise(
              name: 'Bicep Curl',
              setCount: 3,
              defaultWeightKg: 14,
              defaultReps: 12),
        ],
      ),
      WorkoutRoutine(
        id: 'default-leg-day',
        name: 'Leg Day',
        category: 'Quads · Glutes · Hamstrings',
        createdAt: created,
        lastPerformedAt: DateTime(2026, 8, 6),
        exercises: const [
          RoutineExercise(
              name: 'Squat', setCount: 4, defaultWeightKg: 70, defaultReps: 8),
          RoutineExercise(
              name: 'Leg Press',
              setCount: 3,
              defaultWeightKg: 120,
              defaultReps: 10),
          RoutineExercise(
              name: 'Deadlift',
              setCount: 3,
              defaultWeightKg: 80,
              defaultReps: 8),
        ],
      ),
    ];
  }
}
