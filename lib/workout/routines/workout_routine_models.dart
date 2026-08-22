class RoutineSetTarget {
  const RoutineSetTarget({
    required this.weightKg,
    required this.reps,
  });

  final double weightKg;
  final int reps;

  Map<String, dynamic> toJson() => {
        'weightKg': weightKg,
        'reps': reps,
      };

  factory RoutineSetTarget.fromJson(Map<String, dynamic> json) =>
      RoutineSetTarget(
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
        reps: (json['reps'] as num?)?.toInt() ?? 10,
      );
}

class RoutineExercise {
  const RoutineExercise({
    required this.name,
    this.setCount = 3,
    this.defaultWeightKg = 0,
    this.defaultReps = 10,
    this.setTargets = const [],
  });

  final String name;
  final int setCount;
  final double defaultWeightKg;
  final int defaultReps;
  final List<RoutineSetTarget> setTargets;

  List<RoutineSetTarget> get plannedSets => setTargets.isNotEmpty
      ? List<RoutineSetTarget>.unmodifiable(setTargets)
      : List<RoutineSetTarget>.generate(
          setCount,
          (_) => RoutineSetTarget(
            weightKg: defaultWeightKg,
            reps: defaultReps,
          ),
        );

  RoutineExercise copyWith({
    String? name,
    int? setCount,
    double? defaultWeightKg,
    int? defaultReps,
    List<RoutineSetTarget>? setTargets,
  }) =>
      RoutineExercise(
        name: name ?? this.name,
        setCount: setCount ?? this.setCount,
        defaultWeightKg: defaultWeightKg ?? this.defaultWeightKg,
        defaultReps: defaultReps ?? this.defaultReps,
        setTargets: setTargets ?? this.setTargets,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'setCount': setCount,
        'defaultWeightKg': defaultWeightKg,
        'defaultReps': defaultReps,
        'setTargets': setTargets.map((item) => item.toJson()).toList(),
      };

  factory RoutineExercise.fromJson(Map<String, dynamic> json) {
    final rawTargets = json['setTargets'];
    final targets = rawTargets is List
        ? rawTargets
            .whereType<Map>()
            .map((item) => RoutineSetTarget.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value))))
            .toList()
        : <RoutineSetTarget>[];
    final legacySetCount = (json['setCount'] as num?)?.toInt() ?? 3;
    return RoutineExercise(
      name: (json['name'] ?? '').toString(),
      setCount: targets.isEmpty ? legacySetCount : targets.length,
      defaultWeightKg: (json['defaultWeightKg'] as num?)?.toDouble() ?? 0,
      defaultReps: (json['defaultReps'] as num?)?.toInt() ?? 10,
      setTargets: targets,
    );
  }
}

class WorkoutRoutine {
  const WorkoutRoutine({
    required this.id,
    required this.name,
    required this.category,
    required this.exercises,
    required this.createdAt,
    this.lastPerformedAt,
  });

  final String id;
  final String name;
  final String category;
  final List<RoutineExercise> exercises;
  final DateTime createdAt;
  final DateTime? lastPerformedAt;

  int get estimatedMinutes => exercises.isEmpty
      ? 0
      : exercises.fold<int>(0, (sum, item) => sum + item.setCount * 3);

  WorkoutRoutine copyWith({
    String? id,
    String? name,
    String? category,
    List<RoutineExercise>? exercises,
    DateTime? createdAt,
    DateTime? lastPerformedAt,
  }) =>
      WorkoutRoutine(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        exercises: exercises ?? this.exercises,
        createdAt: createdAt ?? this.createdAt,
        lastPerformedAt: lastPerformedAt ?? this.lastPerformedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'exercises': exercises.map((item) => item.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'lastPerformedAt': lastPerformedAt?.toIso8601String(),
      };

  factory WorkoutRoutine.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'];
    return WorkoutRoutine(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? 'Custom').toString(),
      exercises: rawExercises is List
          ? rawExercises
              .whereType<Map>()
              .map((item) => RoutineExercise.fromJson(
                  item.map((key, value) => MapEntry(key.toString(), value))))
              .toList()
          : const [],
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      lastPerformedAt:
          DateTime.tryParse((json['lastPerformedAt'] ?? '').toString()),
    );
  }
}

class CompletedSet {
  const CompletedSet({
    required this.weightKg,
    required this.reps,
    required this.completed,
  });

  final double weightKg;
  final int reps;
  final bool completed;

  double get volume => completed ? weightKg * reps : 0;

  Map<String, dynamic> toJson() => {
        'weightKg': weightKg,
        'reps': reps,
        'completed': completed,
      };

  factory CompletedSet.fromJson(Map<String, dynamic> json) => CompletedSet(
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
        reps: (json['reps'] as num?)?.toInt() ?? 0,
        completed: json['completed'] == true,
      );
}

class CompletedExercise {
  const CompletedExercise({required this.name, required this.sets});

  final String name;
  final List<CompletedSet> sets;

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets.map((item) => item.toJson()).toList(),
      };

  factory CompletedExercise.fromJson(Map<String, dynamic> json) {
    final rawSets = json['sets'];
    return CompletedExercise(
      name: (json['name'] ?? '').toString(),
      sets: rawSets is List
          ? rawSets
              .whereType<Map>()
              .map((item) => CompletedSet.fromJson(
                  item.map((key, value) => MapEntry(key.toString(), value))))
              .toList()
          : const [],
    );
  }
}

class WorkoutHistoryItem {
  const WorkoutHistoryItem({
    required this.id,
    required this.routineId,
    required this.name,
    required this.startedAt,
    required this.durationSeconds,
    required this.exercises,
  });

  final String id;
  final String routineId;
  final String name;
  final DateTime startedAt;
  final int durationSeconds;
  final List<CompletedExercise> exercises;

  int get setsDone => exercises.fold<int>(
      0,
      (sum, exercise) =>
          sum + exercise.sets.where((item) => item.completed).length);

  double get totalVolume => exercises.fold<double>(
      0,
      (sum, exercise) =>
          sum + exercise.sets.fold<double>(0, (s, item) => s + item.volume));

  Map<String, dynamic> toJson() => {
        'id': id,
        'routineId': routineId,
        'name': name,
        'startedAt': startedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
        'exercises': exercises.map((item) => item.toJson()).toList(),
      };

  factory WorkoutHistoryItem.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'];
    return WorkoutHistoryItem(
      id: (json['id'] ?? '').toString(),
      routineId: (json['routineId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      startedAt: DateTime.tryParse((json['startedAt'] ?? '').toString()) ??
          DateTime.now(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      exercises: rawExercises is List
          ? rawExercises
              .whereType<Map>()
              .map((item) => CompletedExercise.fromJson(
                  item.map((key, value) => MapEntry(key.toString(), value))))
              .toList()
          : const [],
    );
  }
}
