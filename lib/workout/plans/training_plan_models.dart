import '/workout/routines/workout_routine_models.dart';

const trainingPlanMaxDays = 31;

const trainingPlanGoals = <String, String>{
  'muscle': 'Build muscle',
  'strength': 'Strength',
  'fat_loss': 'Fat loss',
  'conditioning': 'Conditioning',
  'beginner': 'Beginner',
  'general': 'General fitness',
};

const trainingPlanLevels = <String, String>{
  'beginner': 'Beginner',
  'intermediate': 'Intermediate',
  'advanced': 'Advanced',
};

const trainingPlanEquipment = <String, String>{
  'gym': 'Full gym',
  'dumbbells': 'Dumbbells',
  'home': 'Home',
  'none': 'No equipment',
};

String _text(dynamic value, [String fallback = '']) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? fallback : text;
}

int _int(dynamic value, [int fallback = 0]) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

/// One explanation video per exercise per plan; matching ignores case and
/// surrounding spaces, the same way the database does.
String trainingPlanExerciseKey(String name) => name.trim().toLowerCase();

class PlanExerciseVideo {
  const PlanExerciseVideo({
    required this.exerciseName,
    required this.assetId,
    this.playbackUrl = '',
    this.thumbnailUrl = '',
    this.status = 'ready',
  });

  final String exerciseName;
  final String assetId;
  final String playbackUrl;
  final String thumbnailUrl;
  final String status;

  bool get isPlayable => playbackUrl.isNotEmpty && status != 'failed';
  bool get failed => status == 'failed' || status == 'quarantined';

  Map<String, dynamic> toRpcJson() =>
      {'exercise_name': exerciseName.trim(), 'video_asset_id': assetId};

  factory PlanExerciseVideo.fromRow(Map<String, dynamic> row) {
    final asset = row['asset'];
    return PlanExerciseVideo(
      exerciseName: _text(row['exercise_name']),
      assetId: _text(row['video_asset_id']),
      playbackUrl: asset is Map ? _text(asset['playback_url']) : '',
      thumbnailUrl: asset is Map ? _text(asset['thumbnail_url']) : '',
      status: asset is Map ? _text(asset['status'], 'ready') : 'ready',
    );
  }
}

class TrainingPlanDay {
  const TrainingPlanDay({
    required this.day,
    this.isRest = false,
    this.title = '',
    this.notes = '',
    this.exercises = const [],
  });

  /// 1-based position in the plan.
  final int day;
  final bool isRest;
  final String title;
  final String notes;
  final List<RoutineExercise> exercises;

  String get displayTitle => isRest
      ? 'Rest day'
      : (title.trim().isEmpty ? 'Day $day workout' : title.trim());

  TrainingPlanDay copyWith({
    int? day,
    bool? isRest,
    String? title,
    String? notes,
    List<RoutineExercise>? exercises,
  }) =>
      TrainingPlanDay(
        day: day ?? this.day,
        isRest: isRest ?? this.isRest,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        exercises: exercises ?? this.exercises,
      );

  /// Shape accepted by the save_training_plan RPC.
  Map<String, dynamic> toRpcJson() => {
        'kind': isRest ? 'rest' : 'workout',
        'title': title.trim(),
        'notes': notes.trim(),
        'exercises':
            isRest ? const [] : exercises.map((item) => item.toJson()).toList(),
      };

  factory TrainingPlanDay.fromRow(Map<String, dynamic> row) {
    final rawExercises = row['exercises'];
    return TrainingPlanDay(
      day: _int(row['day'], 1),
      isRest: row['kind'] == 'rest',
      title: _text(row['title']),
      notes: _text(row['notes']),
      exercises: rawExercises is List
          ? rawExercises
              .whereType<Map>()
              .map((item) => RoutineExercise.fromJson(
                  item.map((key, value) => MapEntry(key.toString(), value))))
              .where((item) => item.name.trim().isNotEmpty)
              .toList(growable: false)
          : const [],
    );
  }
}

class TrainingPlanSeller {
  const TrainingPlanSeller({
    required this.id,
    this.username = '',
    this.displayName = '',
    this.photoUrl = '',
  });

  final String id;
  final String username;
  final String displayName;
  final String photoUrl;

  String get label => displayName.trim().isNotEmpty
      ? displayName.trim()
      : (username.trim().isNotEmpty ? '@${username.trim()}' : 'GymFeed athlete');
}

class TrainingPlan {
  const TrainingPlan({
    required this.id,
    required this.sellerId,
    required this.title,
    this.description = '',
    this.goal = 'general',
    this.level = 'intermediate',
    this.equipment = 'gym',
    this.dayCount = 1,
    this.priceCents = 0,
    this.status = 'draft',
    this.reviewNote = '',
    this.version = 1,
    this.enrollmentCount = 0,
    this.seller,
    this.days = const [],
    this.videos = const {},
    this.coverImageUrl = '',
    this.introVideo,
    this.isFeatured = false,
    this.ratingAvg,
    this.ratingCount = 0,
    this.updatedAt,
  });

  final String id;
  final String sellerId;
  final String title;
  final String description;
  final String goal;
  final String level;
  final String equipment;
  final int dayCount;
  final int priceCents;
  final String status;
  final String reviewNote;
  final int version;
  final int enrollmentCount;
  final TrainingPlanSeller? seller;
  final List<TrainingPlanDay> days;

  /// Keyed by [trainingPlanExerciseKey].
  final Map<String, PlanExerciseVideo> videos;

  /// Public image in the `images` storage bucket.
  final String coverImageUrl;

  /// Bunny Stream video shown at the top of the plan page.
  final PlanExerciseVideo? introVideo;
  final bool isFeatured;
  final double? ratingAvg;
  final int ratingCount;
  final DateTime? updatedAt;

  bool get hasIntroVideo => introVideo != null && !introVideo!.failed;

  /// Everything a plan still needs before it can be submitted.
  List<String> get submitProblems => [
        if (coverImageUrl.isEmpty) 'a cover image',
        if (!hasIntroVideo) 'an intro video',
        if (exercisesMissingVideo.isNotEmpty)
          exercisesMissingVideo.length == 1
              ? 'a video for ${exercisesMissingVideo.first}'
              : 'videos for ${exercisesMissingVideo.length} exercises',
      ];

  String get ratingLabel => ratingCount == 0 || ratingAvg == null
      ? 'No ratings yet'
      : '${ratingAvg!.toStringAsFixed(1)} · $ratingCount '
          '${ratingCount == 1 ? 'rating' : 'ratings'}';

  PlanExerciseVideo? videoFor(String exerciseName) =>
      videos[trainingPlanExerciseKey(exerciseName)];

  /// Distinct exercise names across workout days, in first-use order.
  List<String> get exerciseNames => distinctPlanExercises(days);

  List<String> get exercisesMissingVideo => exerciseNames
      .where((name) => !(videoFor(name)?.failed == false))
      .toList(growable: false);

  /// The uploaded cover, falling back to a video thumbnail for older plans.
  String get coverUrl {
    if (coverImageUrl.isNotEmpty) return coverImageUrl;
    final intro = introVideo?.thumbnailUrl ?? '';
    if (intro.isNotEmpty) return intro;
    return exerciseNames
        .map((name) => videoFor(name)?.thumbnailUrl ?? '')
        .firstWhere((url) => url.isNotEmpty, orElse: () => '');
  }

  bool get isFree => priceCents == 0;
  bool get isPublished => status == 'published';
  bool get isEditable => status == 'draft' || status == 'rejected';
  int get workoutDayCount => days.where((day) => !day.isRest).length;

  String get goalLabel => trainingPlanGoals[goal] ?? 'General fitness';
  String get levelLabel => trainingPlanLevels[level] ?? 'Intermediate';
  String get equipmentLabel => trainingPlanEquipment[equipment] ?? 'Full gym';
  String get lengthLabel => dayCount == 1 ? '1 day' : '$dayCount days';
  String get priceLabel =>
      isFree ? 'Free' : '\$${(priceCents / 100).toStringAsFixed(2)}';

  String get statusLabel => switch (status) {
        'in_review' => 'In review',
        'published' => 'Published',
        'rejected' => 'Changes requested',
        'removed' => 'Removed',
        _ => 'Draft',
      };

  factory TrainingPlan.fromRow(Map<String, dynamic> row) {
    final seller = row['seller'];
    final rawDays = row['days'];
    final days = rawDays is List
        ? (rawDays
            .whereType<Map>()
            .map((item) => TrainingPlanDay.fromRow(
                item.map((key, value) => MapEntry(key.toString(), value))))
            .toList()
          ..sort((a, b) => a.day.compareTo(b.day)))
        : <TrainingPlanDay>[];
    final rawVideos = row['videos'];
    final videos = <String, PlanExerciseVideo>{
      if (rawVideos is List)
        for (final item in rawVideos.whereType<Map>())
          trainingPlanExerciseKey(_text(item['exercise_name'])):
              PlanExerciseVideo.fromRow(
                  item.map((key, value) => MapEntry(key.toString(), value))),
    }..remove('');
    final intro = row['intro'];
    final rating = row['rating_avg'];
    return TrainingPlan(
      id: _text(row['id']),
      sellerId: _text(row['seller_id']),
      title: _text(row['title'], 'Training plan'),
      description: _text(row['description']),
      goal: _text(row['goal'], 'general'),
      level: _text(row['level'], 'intermediate'),
      equipment: _text(row['equipment'], 'gym'),
      dayCount: _int(row['day_count'], days.isEmpty ? 1 : days.length),
      priceCents: _int(row['price_cents']),
      status: _text(row['status'], 'draft'),
      reviewNote: _text(row['review_note']),
      version: _int(row['version'], 1),
      enrollmentCount: _int(row['enrollment_count']),
      seller: seller is Map
          ? TrainingPlanSeller(
              id: _text(seller['id']),
              username: _text(seller['username']),
              displayName: _text(seller['display_name']),
              photoUrl: _text(seller['photo_url']),
            )
          : null,
      days: List.unmodifiable(days),
      videos: Map.unmodifiable(videos),
      coverImageUrl: _text(row['cover_image_url']),
      introVideo: intro is Map && _text(intro['id']).isNotEmpty
          ? PlanExerciseVideo(
              exerciseName: 'Intro',
              assetId: _text(intro['id']),
              playbackUrl: _text(intro['playback_url']),
              thumbnailUrl: _text(intro['thumbnail_url']),
              status: _text(intro['status'], 'ready'),
            )
          : null,
      isFeatured: row['is_featured'] == true,
      ratingAvg: rating is num ? rating.toDouble() : double.tryParse('$rating'),
      ratingCount: _int(row['rating_count']),
      updatedAt: DateTime.tryParse(_text(row['updated_at']))?.toLocal(),
    );
  }
}

List<String> distinctPlanExercises(Iterable<TrainingPlanDay> days) {
  final seen = <String>{};
  final names = <String>[];
  for (final day in days) {
    if (day.isRest) continue;
    for (final exercise in day.exercises) {
      final name = exercise.name.trim();
      if (name.isNotEmpty && seen.add(trainingPlanExerciseKey(name))) {
        names.add(name);
      }
    }
  }
  return names;
}

enum PlanScheduleMode { consecutive, weekdays }

class TrainingPlanEnrollment {
  const TrainingPlanEnrollment({
    required this.planId,
    required this.version,
    required this.startDate,
    this.mode = PlanScheduleMode.consecutive,
    this.weekdays = const {},
    this.status = 'active',
    this.plan,
  });

  final String planId;
  final int version;
  final DateTime startDate;
  final PlanScheduleMode mode;

  /// DateTime.weekday values (1 = Monday … 7 = Sunday).
  final Set<int> weekdays;
  final String status;
  final TrainingPlan? plan;

  factory TrainingPlanEnrollment.fromRow(Map<String, dynamic> row) {
    final plan = row['plan'];
    final weekdays = row['weekdays'];
    return TrainingPlanEnrollment(
      planId: _text(row['plan_id']),
      version: _int(row['version'], 1),
      startDate: DateTime.tryParse(_text(row['start_date'])) ?? DateTime.now(),
      mode: row['mode'] == 'weekdays'
          ? PlanScheduleMode.weekdays
          : PlanScheduleMode.consecutive,
      weekdays: weekdays is List
          ? weekdays.map((item) => _int(item)).where((d) => d >= 1 && d <= 7).toSet()
          : const {},
      status: _text(row['status'], 'active'),
      plan: plan is Map
          ? TrainingPlan.fromRow(
              plan.map((key, value) => MapEntry(key.toString(), value)))
          : null,
    );
  }
}

class TrainingPlanRating {
  const TrainingPlanRating({
    required this.userId,
    required this.rating,
    this.comment = '',
    this.authorName = '',
    this.updatedAt,
  });

  final String userId;
  final int rating;
  final String comment;
  final String authorName;
  final DateTime? updatedAt;

  factory TrainingPlanRating.fromRow(Map<String, dynamic> row) {
    final author = row['author'];
    String name = '';
    if (author is Map) {
      final display = _text(author['display_name']).trim();
      final username = _text(author['username']).trim();
      name = display.isNotEmpty ? display : (username.isNotEmpty ? '@$username' : '');
    }
    return TrainingPlanRating(
      userId: _text(row['user_id']),
      rating: _int(row['rating']).clamp(1, 5),
      comment: _text(row['comment']),
      authorName: name.isEmpty ? 'GymFeed athlete' : name,
      updatedAt: DateTime.tryParse(_text(row['updated_at']))?.toLocal(),
    );
  }
}
