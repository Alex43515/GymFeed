import '/backend/supabase/supabase.dart';
import '/workout/plans/training_plan_models.dart';

/// Community training plans: browse, build, publish and enroll.
class TrainingPlanRepository {
  SupabaseClient get _db => supabase;
  String? get _uid => _db.auth.currentUser?.id;

  static const _listSelect =
      '*, seller:profiles!training_plans_seller_id_fkey(id,username,display_name,photo_url)';
  static const _detailSelect = '$_listSelect, days:training_plan_days(*), '
      'videos:training_plan_exercise_videos(exercise_name,video_asset_id,'
      'asset:media_assets(playback_url,thumbnail_url,status))';

  String _requireUid() {
    final uid = _uid;
    if (uid == null) throw StateError('Sign in to use training plans.');
    return uid;
  }

  List<TrainingPlan> _plans(dynamic rows) => (rows as List)
      .whereType<Map<String, dynamic>>()
      .map(TrainingPlan.fromRow)
      .toList(growable: false);

  /// Published plans, most followed first.
  Future<List<TrainingPlan>> browse({
    String? goal,
    String? search,
    int limit = 40,
  }) async {
    var query =
        _db.from('training_plans').select(_listSelect).eq('status', 'published');
    if (goal != null && goal.isNotEmpty) query = query.eq('goal', goal);
    final term = search?.trim() ?? '';
    if (term.isNotEmpty) {
      query = query.ilike('title', '%${term.replaceAll('%', '')}%');
    }
    final rows = await query
        .order('enrollment_count', ascending: false)
        .order('published_at', ascending: false)
        .limit(limit);
    return _plans(rows);
  }

  Future<List<TrainingPlan>> bySeller(String sellerId, {int limit = 40}) async {
    final rows = await _db
        .from('training_plans')
        .select(_listSelect)
        .eq('seller_id', sellerId)
        .eq('status', 'published')
        .order('published_at', ascending: false)
        .limit(limit);
    return _plans(rows);
  }

  /// Every plan the current user created, including drafts.
  Future<List<TrainingPlan>> mine() async {
    final rows = await _db
        .from('training_plans')
        .select(_listSelect)
        .eq('seller_id', _requireUid())
        .neq('status', 'removed')
        .order('updated_at', ascending: false);
    return _plans(rows);
  }

  Future<TrainingPlan?> get(String planId) async {
    final row = await _db
        .from('training_plans')
        .select(_detailSelect)
        .eq('id', planId)
        .maybeSingle();
    return row == null ? null : TrainingPlan.fromRow(row);
  }

  /// Creates ([planId] null) or replaces a draft with all of its days.
  Future<String> saveDraft({
    String? planId,
    required String title,
    required String description,
    required String goal,
    required String level,
    required String equipment,
    required List<TrainingPlanDay> days,
    Iterable<PlanExerciseVideo> videos = const [],
  }) async {
    _requireUid();
    final id = await _db.rpc('save_training_plan', params: {
      'p_plan_id': planId,
      'p_fields': {
        'title': title.trim(),
        'description': description.trim(),
        'goal': goal,
        'level': level,
        'equipment': equipment,
      },
      'p_days': days.map((day) => day.toRpcJson()).toList(),
      'p_videos': videos.map((video) => video.toRpcJson()).toList(),
    });
    return id.toString();
  }

  /// Returns 'published' or 'in_review'.
  Future<String> submit(String planId) async {
    final status =
        await _db.rpc('submit_training_plan', params: {'p_plan_id': planId});
    return status.toString();
  }

  /// Takes a published plan off the store so it can be edited and resubmitted.
  Future<void> unpublishForEditing(String planId) async {
    await _db
        .from('training_plans')
        .update({'status': 'draft'})
        .eq('id', planId)
        .eq('seller_id', _requireUid());
  }

  /// Drafts are deleted; published plans are removed from the store but stay
  /// in the calendars of people who already follow them.
  Future<void> delete(TrainingPlan plan) async {
    final uid = _requireUid();
    if (plan.isEditable) {
      await _db.from('training_plans').delete().eq('id', plan.id).eq('seller_id', uid);
    } else {
      await _db
          .from('training_plans')
          .update({'status': 'removed'})
          .eq('id', plan.id)
          .eq('seller_id', uid);
    }
  }

  /// GymFeed admins review creators' first plans in the app.
  Future<bool> isAdmin() async {
    if (_uid == null) return false;
    return await _db.rpc('is_app_admin') == true;
  }

  Future<List<TrainingPlan>> reviewQueue() async {
    final rows = await _db
        .from('training_plans')
        .select(_listSelect)
        .eq('status', 'in_review')
        .order('updated_at', ascending: true);
    return _plans(rows);
  }

  /// Approves, or sends back with [note] telling the creator what to change.
  Future<String> review(String planId,
      {required bool approve, String note = ''}) async {
    final status = await _db.rpc('review_training_plan', params: {
      'p_plan_id': planId,
      'p_approve': approve,
      'p_note': note.trim(),
    });
    return status.toString();
  }

  Future<void> enroll({
    required TrainingPlan plan,
    required DateTime startDate,
    required PlanScheduleMode mode,
    Set<int> weekdays = const {},
  }) async {
    final uid = _requireUid();
    final sortedWeekdays = weekdays.toList()..sort();
    await _db.from('training_plan_enrollments').upsert({
      'user_id': uid,
      'plan_id': plan.id,
      'version': plan.version,
      'start_date':
          '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'mode': mode.name,
      'weekdays': mode == PlanScheduleMode.weekdays ? sortedWeekdays : <int>[],
      'status': 'active',
    }, onConflict: 'user_id,plan_id');
  }

  Future<void> leave(String planId) async {
    await _db
        .from('training_plan_enrollments')
        .update({'status': 'removed'})
        .eq('user_id', _requireUid())
        .eq('plan_id', planId);
  }

  /// Active enrollments with the full plan, used to rebuild the calendar on a
  /// new device. Plans the seller has since unpublished come back without days.
  Future<List<TrainingPlanEnrollment>> activeEnrollments() async {
    final rows = await _db
        .from('training_plan_enrollments')
        .select('*, plan:training_plans($_detailSelect)')
        .eq('user_id', _requireUid())
        .eq('status', 'active')
        .order('updated_at', ascending: false);
    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(TrainingPlanEnrollment.fromRow)
        .toList(growable: false);
  }
}
