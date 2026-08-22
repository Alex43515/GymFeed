import '/backend/supabase/supabase.dart';

class WorkoutEntry {
  WorkoutEntry(this.data);
  final Map<String, dynamic> data;

  String get id => (data['id'] ?? '').toString();
  String get userId => (data['user_id'] ?? '').toString();
  String get name => (data['name'] as String?) ?? '';
  String? get notes => data['notes'] as String?;
  int? get durationMinutes => (data['duration_minutes'] as num?)?.toInt();
  DateTime? get performedAt => data['performed_at'] == null
      ? null
      : DateTime.tryParse(data['performed_at'].toString());
  DateTime? get createdAt => data['created_at'] == null
      ? null
      : DateTime.tryParse(data['created_at'].toString());

  List<ExerciseSession> get exercises {
    final list = data['exercise_sessions'];
    if (list is! List) return const [];
    return list.map((e) => ExerciseSession(e as Map<String, dynamic>)).toList();
  }
}

class ExerciseSession {
  ExerciseSession(this.data);
  final Map<String, dynamic> data;

  String get id => (data['id'] ?? '').toString();
  String get workoutEntryId => (data['workout_entry_id'] ?? '').toString();
  String get exerciseName => (data['exercise_name'] as String?) ?? '';
  int? get sets => (data['sets'] as num?)?.toInt();
  int? get reps => (data['reps'] as num?)?.toInt();
  double? get weightKg => (data['weight_kg'] as num?)?.toDouble();
  int? get durationSeconds => (data['duration_seconds'] as num?)?.toInt();
  String? get notes => data['notes'] as String?;
  int get sortOrder => (data['sort_order'] as num?)?.toInt() ?? 0;
}

/// Workout log: entries (sessions) with nested exercise sets.
class WorkoutRepository {
  SupabaseClient get _db => supabase;
  String? get _uid => _db.auth.currentUser?.id;

  static const _entrySelect = '*, exercise_sessions(* order sort_order asc)';

  /// Recent entries for the current user, newest first.
  Future<List<WorkoutEntry>> myEntries(
      {int limit = 20, DateTime? before}) async {
    final uid = _uid;
    if (uid == null) return const [];
    var q = _db.from('workout_entries').select(_entrySelect).eq('user_id', uid);
    if (before != null)
      q = q.lt('created_at', before.toUtc().toIso8601String());
    final rows = await q.order('created_at', ascending: false).limit(limit);
    return (rows as List)
        .map((r) => WorkoutEntry(r as Map<String, dynamic>))
        .toList();
  }

  Future<WorkoutEntry?> get(String entryId) async {
    final row = await _db
        .from('workout_entries')
        .select(_entrySelect)
        .eq('id', entryId)
        .maybeSingle();
    return row == null ? null : WorkoutEntry(row);
  }

  /// Create an entry with optional exercises in one round-trip.
  Future<WorkoutEntry> create({
    required String name,
    String? notes,
    int? durationMinutes,
    DateTime? performedAt,
    List<Map<String, dynamic>> exercises = const [],
  }) async {
    final uid = _requireUid();
    final entryRow = await _db
        .from('workout_entries')
        .insert({
          'user_id': uid,
          'name': name,
          if (notes != null) 'notes': notes,
          if (durationMinutes != null) 'duration_minutes': durationMinutes,
          'performed_at':
              (performedAt ?? DateTime.now().toUtc()).toIso8601String(),
        })
        .select()
        .single();

    if (exercises.isNotEmpty) {
      await _db.from('exercise_sessions').insert(
            exercises
                .asMap()
                .entries
                .map((e) => {
                      ...e.value,
                      'workout_entry_id': entryRow['id'],
                      'sort_order': e.key,
                    })
                .toList(),
          );
    }

    return (await get(entryRow['id'] as String))!;
  }

  Future<void> update(String entryId, Map<String, dynamic> fields) async {
    await _db.from('workout_entries').update(fields).eq('id', entryId);
  }

  Future<void> delete(String entryId) async {
    await _db.from('workout_entries').delete().eq('id', entryId);
  }

  // ── Exercise sessions ─────────────────────────────────────────────────────

  Future<ExerciseSession> addExercise(
    String entryId, {
    required String exerciseName,
    int? sets,
    int? reps,
    double? weightKg,
    int? durationSeconds,
    String? notes,
    int sortOrder = 0,
  }) async {
    final row = await _db
        .from('exercise_sessions')
        .insert({
          'workout_entry_id': entryId,
          'exercise_name': exerciseName,
          if (sets != null) 'sets': sets,
          if (reps != null) 'reps': reps,
          if (weightKg != null) 'weight_kg': weightKg,
          if (durationSeconds != null) 'duration_seconds': durationSeconds,
          if (notes != null) 'notes': notes,
          'sort_order': sortOrder,
        })
        .select()
        .single();
    return ExerciseSession(row);
  }

  Future<void> deleteExercise(String exerciseSessionId) async {
    await _db.from('exercise_sessions').delete().eq('id', exerciseSessionId);
  }

  String _requireUid() {
    final uid = _uid;
    if (uid == null)
      throw StateError('No authenticated user for a workout write.');
    return uid;
  }
}
