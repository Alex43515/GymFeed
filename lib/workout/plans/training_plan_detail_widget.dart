import 'dart:async';

import 'package:flutter/material.dart';

import '/backend/share_links.dart';
import '/backend/supabase/repositories/content_safety_repository.dart';
import '/backend/supabase/supabase.dart';
import '/components/content_safety/report_content_sheet.dart';
import '/flutter_flow/flutter_flow_video_player.dart';
import '/workout/routines/exercise_video_sheet.dart';
import '/workout/routines/workout_routine_store.dart';

import 'add_plan_to_train_widget.dart';
import 'training_plan_builder_widget.dart';
import 'training_plan_models.dart';
import 'training_plan_schedule.dart';
import 'training_plan_service.dart';
import 'training_plan_ui.dart';

/// Plan page: what the plan contains, who made it, and the Train actions.
/// Sellers also manage their own plan here (edit, submit, delete).
class TrainingPlanDetailWidget extends StatefulWidget {
  const TrainingPlanDetailWidget({
    super.key,
    required this.planId,
    this.service,
    this.currentUserId,
    this.introPlayerBuilder,
  });

  final String planId;
  final TrainingPlanService? service;
  final String? currentUserId;

  /// Replaces the network video player in tests.
  final Widget Function(String videoUrl)? introPlayerBuilder;

  /// Shared links open https://gymfeed.io/trainingPlan?id=<plan id>.
  static String routeName = 'trainingPlan';
  static String routePath = 'trainingPlan';

  @override
  State<TrainingPlanDetailWidget> createState() =>
      _TrainingPlanDetailWidgetState();
}

class _TrainingPlanDetailWidgetState extends State<TrainingPlanDetailWidget> {
  late final TrainingPlanService _service =
      widget.service ?? TrainingPlanService();
  late Future<TrainingPlan?> _planFuture;
  late Future<List<TrainingPlanRating>> _ratingsFuture;
  bool _onMyTrain = false;
  bool _isAdmin = false;
  bool _busy = false;
  bool _changed = false;

  String? get _uid =>
      widget.currentUserId ?? supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _planFuture = _service.repository.get(widget.planId);
    _ratingsFuture = _service.repository
        .ratings(widget.planId)
        .catchError((_) => const <TrainingPlanRating>[]);
    _service.repository.isAdmin().then((admin) {
      if (mounted && admin != _isAdmin) setState(() => _isAdmin = admin);
    }).catchError((_) {});
    WorkoutRoutineStore.loadPlanSyncKeys().then((keys) {
      if (mounted) {
        setState(() =>
            _onMyTrain = keys.containsKey(trainingPlanKey(widget.planId)));
      }
    });
  }

  void _reload() => setState(_load);

  void _message(String text) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(text)));

  Future<void> _addToTrain(TrainingPlan plan) async {
    final added = await Navigator.of(context).push<bool>(MaterialPageRoute(
      settings: const RouteSettings(name: 'add-plan-to-train'),
      builder: (_) => AddPlanToTrainWidget(
        plan: plan,
        onConfirm: (start, mode, weekdays) => _service
            .addToTrain(
                plan: plan, startDate: start, mode: mode, weekdays: weekdays)
            .then((_) {}),
      ),
    ));
    if (added == true && mounted) {
      _changed = true;
      setState(() => _onMyTrain = true);
      _message('Added to your Train calendar.');
    }
  }

  Future<void> _removeFromTrain() async {
    final confirmed = await _confirm('Remove from your Train?',
        'Upcoming workouts from this plan are removed. Workouts you already did stay in your history.');
    if (!confirmed) return;
    await _guard(() async {
      await _service.removeFromTrain(widget.planId);
      _changed = true;
      setState(() => _onMyTrain = false);
      _message('Plan removed from your Train.');
    });
  }

  Future<void> _edit(TrainingPlan plan) async {
    if (!plan.isEditable) {
      final confirmed = await _confirm('Edit this plan?',
          'The plan leaves the store while you edit it. People who already follow it keep their calendar. Submit again when you are done.');
      if (!confirmed) return;
      final ok = await _guard(
          () => _service.repository.unpublishForEditing(plan.id));
      if (!ok) return;
    }
    if (!mounted) return;
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
      settings: const RouteSettings(name: 'edit-training-plan'),
      builder: (_) => TrainingPlanBuilderWidget(
          plan: plan, repository: _service.repository),
    ));
    if (mounted) {
      if (saved == true) _changed = true;
      _reload();
    }
  }

  Future<void> _submit(TrainingPlan plan) async {
    final problems = plan.submitProblems;
    if (problems.isNotEmpty) {
      _message('Still needed: ${problems.join(', ')}. Tap Edit to add it.');
      return;
    }
    await _guard(() async {
      final status = await _service.repository.submit(plan.id);
      _changed = true;
      _message(status == 'published'
          ? 'Your plan is live in the store.'
          : 'Submitted. We review first plans before they go live.');
      _reload();
    });
  }

  Future<void> _delete(TrainingPlan plan) async {
    final confirmed = await _confirm(
        plan.isEditable ? 'Delete this draft?' : 'Remove from the store?',
        plan.isEditable
            ? 'This cannot be undone.'
            : 'Nobody new can add it. People who follow it keep their calendar.');
    if (!confirmed) return;
    final ok = await _guard(() => _service.repository.delete(plan));
    if (ok && mounted) Navigator.pop(context, true);
  }

  Future<bool> _guard(Future<void> Function() action) async {
    if (_busy) return false;
    setState(() => _busy = true);
    try {
      await action();
      return true;
    } catch (error) {
      final text = error.toString();
      _message(text.contains('cover image')
          ? 'Add a cover image first.'
          : text.contains('intro video')
          ? 'Add an intro video first.'
          : text.contains('video')
          ? 'Every exercise needs an explanation video.'
          : text.contains('exercise') || text.contains('workout day')
              ? 'Every workout day needs at least one exercise.'
              : text.contains('what to change')
                  ? 'Write what the creator should change.'
                  : 'Something went wrong. Please try again.');
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review(TrainingPlan plan, {required bool approve}) async {
    var note = '';
    if (!approve) {
      final controller = TextEditingController();
      final entered = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: planCard,
          title: Text('Request changes',
              style: planText(size: 16, weight: FontWeight.w700)),
          content: TextField(
            key: const ValueKey('review-note'),
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            style: planText(size: 13),
            decoration: planInput('What should the creator change?'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: planText(color: planMuted))),
            TextButton(
                key: const ValueKey('send-review-note'),
                onPressed: () => Navigator.pop(context, controller.text),
                child: Text('Send',
                    style: planText(color: planGreen, weight: FontWeight.w700))),
          ],
        ),
      );
      // The dialog keeps building during its closing animation.
      unawaited(Future<void>.delayed(
          const Duration(milliseconds: 500), controller.dispose));
      if (entered == null || entered.trim().isEmpty) return;
      note = entered.trim();
    }
    final ok = await _guard(() async {
      await _service.repository.review(plan.id, approve: approve, note: note);
    });
    if (!ok || !mounted) return;
    _changed = true;
    _message(approve ? 'Plan approved and live.' : 'Sent back to the creator.');
    _reload();
  }

  List<Widget> _adminSection(TrainingPlan plan) => [
        Container(
          key: const ValueKey('admin-review-card'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1A0E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: planAmber),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Admin review',
                  style: planText(
                      size: 13, color: planAmber, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                  'Watch every exercise video below. Approve to publish it, or send it back with what to fix.',
                  style: planText(size: 12, color: planMuted)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('review-request-changes'),
                      onPressed:
                          _busy ? null : () => _review(plan, approve: false),
                      child: Text('Request changes',
                          style: planText(size: 12, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      key: const ValueKey('review-approve'),
                      onPressed:
                          _busy ? null : () => _review(plan, approve: true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: planGreen, foregroundColor: planBg),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ];

  Future<void> _toggleFeatured(TrainingPlan plan) async {
    final ok = await _guard(
        () => _service.repository.setFeatured(plan.id, !plan.isFeatured));
    if (!ok || !mounted) return;
    _message(plan.isFeatured
        ? 'Removed from featured plans.'
        : 'Featured at the top of the store.');
    _reload();
  }

  Future<void> _share(TrainingPlan plan) async {
    final box = context.findRenderObject() as RenderBox?;
    await shareGymFeedTrainingPlan(
      planId: plan.id,
      title: plan.title,
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  }

  Future<void> _report(TrainingPlan plan) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ReportContentSheet(
          contentId: plan.id,
          authorId: plan.sellerId,
          authorUsername: plan.seller?.username ?? '',
          imageUrl: plan.coverUrl,
          contentType: ReportedContentType.trainingPlan,
        ),
      );

  Future<void> _rate(TrainingPlan plan, TrainingPlanRating? mine) async {
    var stars = mine?.rating ?? 5;
    final comment = TextEditingController(text: mine?.comment ?? '');
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: planCard,
          title: Text('Rate this plan',
              style: planText(size: 16, weight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return InkResponse(
                    key: ValueKey('rate-star-$value'),
                    radius: 22,
                    onTap: () => setDialogState(() => stars = value),
                    child: SizedBox(
                      width: 42,
                      height: 44,
                      child: Icon(
                          value <= stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: planAmber,
                          size: 32),
                    ),
                  );
                }),
              ),
              TextField(
                key: const ValueKey('rate-comment'),
                controller: comment,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                style: planText(size: 13),
                decoration: planInput('What did you like? (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: planText(color: planMuted))),
            TextButton(
                key: const ValueKey('save-rating'),
                onPressed: () => Navigator.pop(context, true),
                child: Text('Save',
                    style: planText(color: planGreen, weight: FontWeight.w700))),
          ],
        ),
      ),
    );
    final text = comment.text;
    // The dialog keeps building during its closing animation.
    unawaited(Future<void>.delayed(
        const Duration(milliseconds: 500), comment.dispose));
    if (save != true) return;
    final ok = await _guard(() => _service.repository
        .rate(plan.id, rating: stars, comment: text));
    if (!ok || !mounted) return;
    _message('Thanks for rating this plan.');
    _reload();
  }

  Widget _stars(double value, {double size = 15}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final filled = value >= index + 0.75;
          final half = !filled && value >= index + 0.25;
          return Icon(
              filled
                  ? Icons.star_rounded
                  : half
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded,
              color: planAmber,
              size: size);
        }),
      );

  Widget _ratingsSection(TrainingPlan plan, bool isOwner) {
    return FutureBuilder<List<TrainingPlanRating>>(
      future: _ratingsFuture,
      builder: (context, snapshot) {
        final ratings = snapshot.data ?? const <TrainingPlanRating>[];
        final mine = ratings.where((r) => r.userId == _uid).firstOrNull;
        final canRate = _onMyTrain && !isOwner && plan.isPublished;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Ratings',
                      style: planText(
                          size: 13,
                          color: planMuted,
                          weight: FontWeight.w600)),
                ),
                if (canRate)
                  TextButton(
                    key: const ValueKey('rate-plan'),
                    onPressed: _busy ? null : () => _rate(plan, mine),
                    child: Text(mine == null ? 'Rate this plan' : 'Edit my rating',
                        style: planText(
                            size: 12,
                            color: planGreen,
                            weight: FontWeight.w700)),
                  ),
              ],
            ),
            Row(
              children: [
                _stars(plan.ratingAvg ?? 0, size: 18),
                const SizedBox(width: 8),
                Text(plan.ratingLabel,
                    key: const ValueKey('plan-rating-label'),
                    style: planText(size: 12, color: planMuted)),
              ],
            ),
            ...ratings.where((r) => r.comment.trim().isNotEmpty).take(5).map(
                  (rating) => Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: planCard,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: planBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(rating.authorName,
                                  style: planText(
                                      size: 12, weight: FontWeight.w600)),
                            ),
                            _stars(rating.rating.toDouble(), size: 13),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(rating.comment,
                            style: planText(
                                size: 12, color: const Color(0xFFCFCFCF))),
                      ],
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  Widget _cover(TrainingPlan plan) {
    final cover = plan.coverUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cover.isNotEmpty)
              Image.network(cover,
                  key: const ValueKey('plan-cover-image'),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) =>
                      const ColoredBox(color: planCard))
            else
              const ColoredBox(
                color: Color(0xFF123821),
                child: Center(
                    child: Icon(Icons.event_note_rounded,
                        color: planGreen, size: 42)),
              ),
            if (plan.isFeatured)
              Positioned(
                left: 10,
                top: 10,
                child: planChip('Featured',
                    color: planBg, background: planAmber),
              ),
          ],
        ),
      ),
    );
  }

  Widget _creator(TrainingPlan plan) {
    final seller = plan.seller;
    final photo = seller?.photoUrl ?? '';
    final name = seller?.label ?? 'GymFeed athlete';
    return Row(
      key: const ValueKey('plan-creator'),
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFF123821),
          foregroundImage: photo.isEmpty ? null : NetworkImage(photo),
          child: Text(name.replaceAll('@', '').characters.first.toUpperCase(),
              style: planText(
                  size: 15, color: planGreen, weight: FontWeight.w700)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: planText(size: 14, weight: FontWeight.w700)),
              Text('Plan creator',
                  style: planText(size: 11, color: planMuted)),
            ],
          ),
        ),
      ],
    );
  }

  /// The creator's intro video takes the top of the page and plays as soon
  /// as it opens; the cover image is only used when there is no intro.
  Widget _topMedia(TrainingPlan plan) {
    final intro = plan.introVideo;
    if (intro == null || !intro.isPlayable) return _cover(plan);
    final player = widget.introPlayerBuilder?.call(intro.playbackUrl) ??
        FlutterFlowVideoPlayer(
          path: intro.playbackUrl,
          aspectRatio: 9 / 16,
          autoPlay: true,
          looping: false,
          showControls: true,
          allowFullScreen: true,
        );
    return ClipRRect(
      key: const ValueKey('plan-intro-video'),
      borderRadius: BorderRadius.circular(18),
      child: ColoredBox(
        color: Colors.black,
        child: SizedBox(
          height: 460,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(child: player),
              if (plan.isFeatured)
                Positioned(
                  left: 10,
                  top: 10,
                  child: planChip('Featured',
                      color: planBg, background: planAmber),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirm(String title, String body) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: planCard,
        title: Text(title, style: planText(size: 16, weight: FontWeight.w700)),
        content: Text(body, style: planText(size: 13, color: planMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: planText(color: planMuted))),
          TextButton(
              key: const ValueKey('confirm-dialog'),
              onPressed: () => Navigator.pop(context, true),
              child: Text('Continue',
                  style: planText(color: planGreen, weight: FontWeight.w700))),
        ],
      ),
    );
    return result == true;
  }

  bool _canWatchExercises(TrainingPlan plan) =>
      _onMyTrain || _isAdmin || plan.sellerId == _uid;

  Widget _dayTile(TrainingPlan plan, TrainingPlanDay day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: planCard,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: planBorder),
      ),
      child: day.isRest
          ? ListTile(
              dense: true,
              leading: Text('Day ${day.day}',
                  style: planText(size: 11, color: planMuted, weight: FontWeight.w700)),
              title: Text('Rest day', style: planText(size: 13, color: planMuted)),
            )
          : Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: ValueKey('plan-day-${day.day}'),
                iconColor: planGreen,
                collapsedIconColor: planMuted,
                leading: Text('Day ${day.day}',
                    style: planText(
                        size: 11, color: planGreen, weight: FontWeight.w700)),
                title: Text(day.displayTitle,
                    style: planText(size: 14, weight: FontWeight.w700)),
                subtitle: Text('${day.exercises.length} exercises',
                    style: planText(size: 10, color: planMuted)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: [
                  if (day.notes.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(day.notes,
                            style: planText(size: 12, color: planMuted)),
                      ),
                    ),
                  ...day.exercises.map((exercise) {
                    final sets = exercise.plannedSets;
                    final reps = sets.map((set) => set.reps).toSet();
                    final video = plan.videoFor(exercise.name);
                    final playable =
                        video?.isPlayable == true && _canWatchExercises(plan);
                    return InkWell(
                      key: ValueKey('plan-exercise-${day.day}-${exercise.name}'),
                      onTap: playable
                          ? () => showExerciseVideo(context,
                              exerciseName: exercise.name,
                              videoUrl: video!.playbackUrl,
                              subtitle: plan.title)
                          : null,
                      child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Icon(
                              playable
                                  ? Icons.play_circle_fill_rounded
                                  : Icons.fitness_center_rounded,
                              color: playable ? planGreen : planMuted,
                              size: playable ? 19 : 15),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(exercise.name,
                                style: planText(size: 13)),
                          ),
                          Text(
                              '${sets.length} × ${reps.length == 1 ? reps.first : '${reps.reduce((a, b) => a < b ? a : b)}-${reps.reduce((a, b) => a > b ? a : b)}'}',
                              style: planText(size: 12, color: planMuted)),
                        ],
                      ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  List<Widget> _ownerSection(TrainingPlan plan) => [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: planCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: planStatusColor(plan.status)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your plan · ${plan.statusLabel}',
                  style: planText(
                      size: 13,
                      color: planStatusColor(plan.status),
                      weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                switch (plan.status) {
                  'published' =>
                    '${plan.enrollmentCount} people follow this plan.',
                  'in_review' =>
                    'We review first plans before they go live. This usually takes a day.',
                  'rejected' => plan.reviewNote.isEmpty
                      ? 'Please update the plan and submit it again.'
                      : plan.reviewNote,
                  _ => 'Only you can see this draft. Submit it to publish.',
                },
                style: planText(size: 12, color: planMuted),
              ),
              if (plan.isEditable && plan.submitProblems.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Still needed: ${plan.submitProblems.join(', ')}',
                  key: const ValueKey('owner-missing-videos'),
                  style: planText(size: 12, color: planAmber),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (plan.isEditable)
                    ElevatedButton(
                      key: const ValueKey('submit-plan'),
                      onPressed: _busy ? null : () => _submit(plan),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: planGreen, foregroundColor: planBg),
                      child: const Text('Submit'),
                    ),
                  OutlinedButton(
                    key: const ValueKey('edit-plan'),
                    onPressed: _busy ? null : () => _edit(plan),
                    child: Text('Edit', style: planText(size: 13)),
                  ),
                  TextButton(
                    key: const ValueKey('delete-plan'),
                    onPressed: _busy ? null : () => _delete(plan),
                    child: Text(plan.isEditable ? 'Delete' : 'Remove',
                        style: planText(size: 13, color: const Color(0xFFFF6B6B))),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: planScaled(
        context,
        Scaffold(
          backgroundColor: planBg,
          body: SafeArea(
            child: FutureBuilder<TrainingPlan?>(
              future: _planFuture,
              builder: (context, snapshot) {
                final plan = snapshot.data;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: planGreen));
                }
                if (plan == null) {
                  return Column(children: [
                    planTopBar(context, title: 'Training plan'),
                    Expanded(
                      child: Center(
                        child: Text('This plan is no longer available.',
                            style: planText(color: planMuted)),
                      ),
                    ),
                  ]);
                }
                final isOwner = plan.sellerId == _uid;
                return Column(
                  children: [
                    planTopBar(
                      context,
                      title: plan.title,
                      action: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (plan.isPublished)
                            IconButton(
                              key: const ValueKey('share-plan'),
                              tooltip: 'Share plan',
                              onPressed: () => _share(plan),
                              icon: const Icon(Icons.ios_share_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          if (!isOwner)
                            IconButton(
                              key: const ValueKey('report-plan'),
                              tooltip: 'Report plan',
                              onPressed: () => _report(plan),
                              icon: const Icon(Icons.flag_outlined,
                                  color: planMuted, size: 20),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                        children: [
                          if (_isAdmin && plan.status == 'in_review')
                            ..._adminSection(plan),
                          if (_isAdmin && plan.isPublished) ...[
                            OutlinedButton.icon(
                              key: const ValueKey('toggle-featured'),
                              onPressed: _busy ? null : () => _toggleFeatured(plan),
                              icon: Icon(
                                  plan.isFeatured
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: planAmber,
                                  size: 18),
                              label: Text(
                                  plan.isFeatured
                                      ? 'Admin: remove from featured'
                                      : 'Admin: feature in store',
                                  style: planText(size: 12)),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (isOwner) ..._ownerSection(plan),
                          _topMedia(plan),
                          const SizedBox(height: 14),
                          Text(plan.title,
                              style: planText(size: 22, weight: FontWeight.w800)),
                          const SizedBox(height: 10),
                          _creator(plan),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              planChip(plan.lengthLabel, color: planGreen),
                              planChip('${plan.workoutDayCount} workouts'),
                              planChip(plan.goalLabel),
                              planChip(plan.levelLabel),
                              planChip(plan.equipmentLabel),
                              planChip(plan.priceLabel, color: planGreen),
                            ],
                          ),
                          if (plan.description.trim().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(plan.description,
                                style: planText(size: 13, color: const Color(0xFFCFCFCF))),
                          ],
                          const SizedBox(height: 20),
                          Text(
                              _canWatchExercises(plan)
                                  ? 'Plan days · tap an exercise to watch how'
                                  : 'Plan days · exercise videos unlock when you add the plan to your Train',
                              key: const ValueKey('plan-days-heading'),
                              style: planText(
                                  size: 13,
                                  color: planMuted,
                                  weight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ...plan.days.map((day) => _dayTile(plan, day)),
                          const SizedBox(height: 16),
                          if (plan.isPublished) ...[
                            _ratingsSection(plan, isOwner),
                            const SizedBox(height: 16),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'Consult a doctor before starting a new training program.',
                            style: planText(size: 10, color: planMuted),
                          ),
                        ],
                      ),
                    ),
                    if (plan.isPublished || isOwner)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                        child: _onMyTrain
                            ? Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      key: const ValueKey('remove-plan-from-train'),
                                      onPressed: _busy ? null : _removeFromTrain,
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(52),
                                        side: const BorderSide(color: planBorder),
                                      ),
                                      child: Text('Remove',
                                          style: planText(size: 13, color: planMuted)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton(
                                      key: const ValueKey('reschedule-plan'),
                                      onPressed: _busy ? null : () => _addToTrain(plan),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(52),
                                        backgroundColor: planGreen,
                                        foregroundColor: planBg,
                                      ),
                                      child: Text('Reschedule',
                                          style: planText(
                                              size: 14,
                                              color: planBg,
                                              weight: FontWeight.w700)),
                                    ),
                                  ),
                                ],
                              )
                            : ElevatedButton(
                                key: const ValueKey('add-plan-to-train'),
                                onPressed: _busy || plan.workoutDayCount == 0
                                    ? null
                                    : () => _addToTrain(plan),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(54),
                                  backgroundColor: planGreen,
                                  foregroundColor: planBg,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(17)),
                                ),
                                child: Text('Add to my Train',
                                    style: planText(
                                        size: 15,
                                        color: planBg,
                                        weight: FontWeight.w700)),
                              ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
