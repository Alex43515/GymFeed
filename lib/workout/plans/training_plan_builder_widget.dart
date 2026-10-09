import 'package:flutter/material.dart';

import '/backend/supabase/repositories/training_plan_repository.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/upload_progress_screen.dart';
import '/flutter_flow/upload_data.dart';
import '/workout/routines/exercise_video_sheet.dart';
import '/workout/routines/workout_routine_flow.dart';
import '/workout/routines/workout_routine_models.dart';

import 'training_plan_models.dart';
import 'training_plan_ui.dart';

typedef PlanVideoUploader = Future<PlanExerciseVideo?> Function(
    BuildContext context, String label);
typedef PlanImageUploader = Future<String?> Function(BuildContext context);

/// Picks a video from the gallery and uploads it to Bunny Stream through the
/// same upload screen as posts and workouts. Returns null when cancelled.
Future<PlanExerciseVideo?> uploadPlanExerciseVideo(
    BuildContext context, String label) async {
  final file = await actions.pickAndPrepareVideo();
  final bytes = file?.bytes;
  if (bytes == null || bytes.isEmpty || !context.mounted) return null;
  final upload = await showUploadProgress(
    context,
    videoBytes: bytes,
    videoTitle: 'GymFeed plan · $label',
    videoFileName: file?.name ?? 'gymfeed-plan-video.mp4',
  );
  final assetId = upload?.videoAssetId;
  if (upload == null || !upload.success || assetId == null) return null;
  return PlanExerciseVideo(
    exerciseName: label,
    assetId: assetId,
    playbackUrl: upload.videoPlaylistUrl ?? '',
    thumbnailUrl: upload.videoThumbnailUrl ?? '',
    status: 'processing',
  );
}

/// Picks a photo and uploads it to the `images` bucket, like post photos.
Future<String?> uploadPlanCoverImage(BuildContext context) async {
  final selection = await selectMedia(
    mediaSource: MediaSource.photoGallery,
    imageQuality: 85,
    maxWidth: 1600,
  );
  final file = (selection == null || selection.isEmpty) ? null : selection.first;
  final bytes = file?.bytes;
  if (file == null || bytes == null || bytes.isEmpty || !context.mounted) {
    return null;
  }
  final name = file.storagePath.split('/').last;
  final upload = await showUploadProgress(
    context,
    imageBytes: bytes,
    imageFileName: name.contains('.') ? name : 'plan-cover.jpg',
  );
  return upload?.imageUrl;
}

/// Creates or edits a plan: cover image, intro video, details, then 1-31
/// days where each day is a workout (built with the regular routine builder)
/// or a rest day. Every exercise gets its explanation video right on its day.
/// Pops `true` after the draft is saved.
class TrainingPlanBuilderWidget extends StatefulWidget {
  const TrainingPlanBuilderWidget({
    super.key,
    this.plan,
    this.repository,
    this.videoUploader,
    this.imageUploader,
  });

  final TrainingPlan? plan;
  final TrainingPlanRepository? repository;

  /// Override the gallery pickers + uploads in tests.
  final PlanVideoUploader? videoUploader;
  final PlanImageUploader? imageUploader;

  @override
  State<TrainingPlanBuilderWidget> createState() =>
      _TrainingPlanBuilderWidgetState();
}

class _TrainingPlanBuilderWidgetState extends State<TrainingPlanBuilderWidget> {
  static const _introLabel = 'Intro';

  late final TrainingPlanRepository _repository =
      widget.repository ?? TrainingPlanRepository();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late String _goal;
  late String _level;
  late String _equipment;
  late List<TrainingPlanDay> _days;
  late Map<String, PlanExerciseVideo> _videos;
  late String _coverUrl;
  PlanExerciseVideo? _intro;

  /// Exercise name, [_introLabel] or 'cover' while an upload is running.
  String? _uploading;
  bool _saving = false;

  /// Bumped on every upload change so the open day editor rebuilds its
  /// per-exercise video rows.
  final _videoRevision = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    _title = TextEditingController(text: plan?.title ?? '');
    _description = TextEditingController(text: plan?.description ?? '');
    _goal = plan?.goal ?? 'muscle';
    _level = plan?.level ?? 'intermediate';
    _equipment = plan?.equipment ?? 'gym';
    _days = List.of(plan?.days ?? const <TrainingPlanDay>[]);
    _videos = Map.of(plan?.videos ?? const <String, PlanExerciseVideo>{});
    _coverUrl = plan?.coverImageUrl ?? '';
    _intro = plan?.introVideo;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _videoRevision.dispose();
    super.dispose();
  }

  List<String> get _exerciseNames => distinctPlanExercises(_days);

  PlanExerciseVideo? _videoFor(String name) =>
      _videos[trainingPlanExerciseKey(name)];

  bool _hasVideo(String name) => _videoFor(name)?.failed == false;

  int get _videosDone => _exerciseNames.where(_hasVideo).length;

  void _message(String text) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(text)));

  Future<void> _runUpload(String slot, Future<void> Function() upload) async {
    if (_uploading != null) return;
    setState(() => _uploading = slot);
    _videoRevision.value++;
    try {
      await upload();
    } catch (error) {
      if (!mounted) return;
      _message(error.toString().contains('too long')
          ? 'Videos can be up to 60 seconds.'
          : 'The upload did not finish. Please try again.');
    } finally {
      if (mounted) setState(() => _uploading = null);
      _videoRevision.value++;
    }
  }

  Future<void> _uploadExerciseVideo(BuildContext uploadContext,
          String exerciseName) =>
      _runUpload(exerciseName, () async {
        final video = await (widget.videoUploader ?? uploadPlanExerciseVideo)(
            uploadContext, exerciseName);
        if (video != null && mounted) {
          setState(() => _videos[trainingPlanExerciseKey(exerciseName)] = video);
        }
      });

  Future<void> _uploadIntro() => _runUpload(_introLabel, () async {
        final video = await (widget.videoUploader ?? uploadPlanExerciseVideo)(
            context, _introLabel);
        if (video != null && mounted) setState(() => _intro = video);
      });

  Future<void> _uploadCover() => _runUpload('cover', () async {
        final url =
            await (widget.imageUploader ?? uploadPlanCoverImage)(context);
        if (url != null && url.isNotEmpty && mounted) {
          setState(() => _coverUrl = url);
        }
      });

  void _renumber() {
    _days = [
      for (var index = 0; index < _days.length; index++)
        _days[index].copyWith(day: index + 1),
    ];
  }

  Future<TrainingPlanDay?> _buildWorkout(TrainingPlanDay? existing) async {
    WorkoutRoutine? result;
    final day = existing?.day ?? _days.length + 1;
    await Navigator.of(context).push<bool>(MaterialPageRoute(
      settings: const RouteSettings(name: 'training-plan-day'),
      builder: (_) => RoutineBuilderWidget(
        title: 'Day $day workout',
        routine: existing == null || existing.isRest
            ? null
            : WorkoutRoutine(
                id: 'plan-day-draft',
                name: existing.displayTitle,
                category: 'Plan',
                exercises: existing.exercises,
                createdAt: DateTime.now(),
              ),
        onSaved: (routine) => result = routine,
        exerciseFooterBuilder: (editorContext, exercise) =>
            ValueListenableBuilder<int>(
          valueListenable: _videoRevision,
          builder: (context, _, __) =>
              _exerciseVideoFooter(editorContext, exercise.name),
        ),
      ),
    ));
    final routine = result;
    if (routine == null) return null;
    return TrainingPlanDay(
      day: day,
      title: routine.name,
      notes: existing?.notes ?? '',
      exercises: routine.exercises,
    );
  }

  Future<void> _addWorkout() async {
    if (_days.length >= trainingPlanMaxDays) return;
    final day = await _buildWorkout(null);
    if (day == null || !mounted) return;
    setState(() => _days.add(day));
  }

  void _addRest() {
    if (_days.length >= trainingPlanMaxDays) return;
    setState(
        () => _days.add(TrainingPlanDay(day: _days.length + 1, isRest: true)));
  }

  Future<void> _editDay(int index) async {
    final updated = await _buildWorkout(_days[index]);
    if (updated != null && mounted) setState(() => _days[index] = updated);
  }

  void _removeDay(int index) => setState(() {
        _days.removeAt(index);
        _renumber();
      });

  /// Appends a copy of the first week, the usual way multi-week plans repeat.
  void _repeatWeek() {
    final week = _days.take(7).toList();
    final room = trainingPlanMaxDays - _days.length;
    if (week.isEmpty || room <= 0) return;
    setState(() {
      _days.addAll(week.take(room));
      _renumber();
    });
  }

  String? _validate() {
    if (_title.text.trim().length < 3) {
      return 'Give your plan a name (3+ characters).';
    }
    if (_days.isEmpty) return 'Add at least one day.';
    if (_days.every((day) => day.isRest)) return 'Add at least one workout day.';
    return null;
  }

  Future<void> _save() async {
    if (_saving || _uploading != null) return;
    final problem = _validate();
    if (problem != null) {
      _message(problem);
      return;
    }
    setState(() => _saving = true);
    try {
      await _repository.saveDraft(
        planId: widget.plan?.id,
        title: _title.text,
        description: _description.text,
        goal: _goal,
        level: _level,
        equipment: _equipment,
        days: _days,
        videos: _exerciseNames
            .map(_videoFor)
            .whereType<PlanExerciseVideo>()
            .toList(),
        coverImageUrl: _coverUrl,
        introVideoAssetId: _intro?.assetId,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _message('Could not save the plan. Please try again.');
    }
  }

  Widget _sectionTitle(String text, {String? trailing, bool done = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(text,
                  style: planText(size: 14, weight: FontWeight.w700)),
            ),
            if (trailing != null)
              Flexible(
                child: Text(trailing,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: planText(
                        size: 11,
                        color: done ? planGreen : planAmber,
                        weight: FontWeight.w600)),
              ),
          ],
        ),
      );

  Widget _uploadButton(String slot, String label, VoidCallback onPressed,
          {Key? key}) =>
      TextButton(
        key: key,
        onPressed: _uploading == null ? onPressed : null,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: _uploading == slot
            ? const SizedBox(
                width: 16,
                height: 16,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: planGreen))
            : Text(label,
                style: planText(
                    size: 12, color: planGreen, weight: FontWeight.w700)),
      );

  Widget _coverCard() {
    final has = _coverUrl.isNotEmpty;
    return Material(
      color: planCard,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('plan-cover'),
        onTap: _uploading == null ? _uploadCover : null,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (has)
                Image.network(_coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) =>
                        const ColoredBox(color: Color(0xFF1B1B1B)))
              else
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF4A3A16)),
                  ),
                ),
              Center(
                child: _uploading == 'cover'
                    ? const CircularProgressIndicator(color: planGreen)
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                has
                                    ? Icons.edit_rounded
                                    : Icons.add_photo_alternate_outlined,
                                color: has ? Colors.white : planAmber,
                                size: 18),
                            const SizedBox(width: 8),
                            Text(has ? 'Change cover' : 'Add cover image',
                                style: planText(
                                    size: 12, weight: FontWeight.w700)),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumb(PlanExerciseVideo? video, {double width = 40, double height = 52}) {
    final ok = video != null && !video.failed;
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: SizedBox(
        width: width,
        height: height,
        child: ok && video.thumbnailUrl.isNotEmpty
            ? Image.network(video.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _placeholder(ok))
            : _placeholder(ok),
      ),
    );
  }

  Widget _placeholder(bool ok) => ColoredBox(
        color: const Color(0xFF1B1B1B),
        child: Icon(ok ? Icons.videocam_rounded : Icons.videocam_off_outlined,
            color: ok ? planGreen : planAmber, size: 18),
      );

  String _videoStatus(PlanExerciseVideo? video) {
    if (video == null) return 'Video needed';
    if (video.failed) return 'Upload failed, add it again';
    return video.status == 'ready' ? 'Video added' : 'Video added · processing';
  }

  Widget _introCard() {
    final intro = _intro;
    final ok = intro != null && !intro.failed;
    return Container(
      key: const ValueKey('plan-intro-row'),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: planCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ok ? planBorder : const Color(0xFF4A3A16)),
      ),
      child: Row(
        children: [
          _thumb(intro),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Intro video',
                    style: planText(size: 13, weight: FontWeight.w600)),
                Text(
                    ok
                        ? _videoStatus(intro)
                        : 'Up to 60 s: who the plan is for and what they will get',
                    style:
                        planText(size: 10, color: ok ? planMuted : planAmber)),
              ],
            ),
          ),
          if (ok && intro.playbackUrl.isNotEmpty)
            IconButton(
              tooltip: 'Watch intro',
              onPressed: () => showExerciseVideo(context,
                  exerciseName: 'Intro video', videoUrl: intro.playbackUrl),
              icon: const Icon(Icons.play_circle_outline_rounded,
                  color: planMuted, size: 22),
            ),
          _uploadButton(_introLabel, ok ? 'Replace' : 'Upload', _uploadIntro,
              key: const ValueKey('upload-plan-intro')),
        ],
      ),
    );
  }

  /// Shown under each exercise inside the day editor: its explanation video.
  Widget _exerciseVideoFooter(BuildContext editorContext, String name) {
    final video = _videoFor(name);
    final ok = video != null && !video.failed;
    final otherDays = _days
        .where((day) => day.exercises.any(
            (e) => trainingPlanExerciseKey(e.name) == trainingPlanExerciseKey(name)))
        .map((day) => day.day)
        .toList();
    return Container(
      key: ValueKey('exercise-video-footer-$name'),
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ok ? planBorder : const Color(0xFF4A3A16)),
      ),
      child: Row(
        children: [
          _thumb(video, width: 30, height: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Explanation video',
                    style: planText(size: 12, weight: FontWeight.w600)),
                Text(
                    ok && otherDays.isNotEmpty
                        ? '${_videoStatus(video)} · used on day ${otherDays.join(', ')}'
                        : _videoStatus(video),
                    maxLines: 2,
                    style:
                        planText(size: 10, color: ok ? planMuted : planAmber)),
              ],
            ),
          ),
          if (ok && video.playbackUrl.isNotEmpty)
            IconButton(
              tooltip: 'Watch video',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              onPressed: () => showExerciseVideo(editorContext,
                  exerciseName: name, videoUrl: video.playbackUrl),
              icon: const Icon(Icons.play_circle_outline_rounded,
                  color: planMuted, size: 21),
            ),
          _uploadButton(name, ok ? 'Replace' : 'Upload',
              () => _uploadExerciseVideo(editorContext, name),
              key: ValueKey('upload-exercise-video-$name')),
        ],
      ),
    );
  }

  /// Read-only line in the plan's day card; uploads happen in the day editor.
  Widget _exerciseSummary(TrainingPlanDay day, RoutineExercise exercise) {
    final ok = _hasVideo(exercise.name);
    return Padding(
      key: ValueKey('plan-exercise-row-d${day.day}-${exercise.name}'),
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle_rounded : Icons.videocam_off_outlined,
              color: ok ? planGreen : planAmber, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(exercise.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: planText(size: 12)),
          ),
          Text(
              ok
                  ? '${exercise.setCount} sets'
                  : '${exercise.setCount} sets · video needed',
              style: planText(size: 10, color: ok ? planMuted : planAmber)),
        ],
      ),
    );
  }

  Widget _dayCard(int index) {
    final day = _days[index];
    return Container(
      key: ValueKey('builder-day-${day.day}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 10),
      decoration: BoxDecoration(
        color: planCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: planBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Day ${day.day}',
                  style: planText(
                      size: 11,
                      color: day.isRest ? planMuted : planGreen,
                      weight: FontWeight.w700)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(day.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: planText(
                        size: 14,
                        color: day.isRest ? planMuted : Colors.white,
                        weight: FontWeight.w600)),
              ),
              if (!day.isRest)
                IconButton(
                  key: ValueKey('edit-plan-day-${day.day}'),
                  tooltip: 'Edit exercises',
                  onPressed: () => _editDay(index),
                  icon: const Icon(Icons.edit_outlined,
                      color: planMuted, size: 19),
                ),
              IconButton(
                key: ValueKey('remove-plan-day-${day.day}'),
                tooltip: 'Remove day',
                onPressed: () => _removeDay(index),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: planMuted, size: 19),
              ),
            ],
          ),
          ...day.exercises.map((exercise) => _exerciseSummary(day, exercise)),
          if (!day.isRest &&
              day.exercises.any((exercise) => !_hasVideo(exercise.name)))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                key: ValueKey('add-videos-day-${day.day}'),
                onPressed: () => _editDay(index),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.videocam_rounded,
                    color: planGreen, size: 17),
                label: Text('Open day to add exercise videos',
                    style: planText(
                        size: 12, color: planGreen, weight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _picker(String label, Map<String, String> options, String value,
      ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                planText(size: 12, color: planMuted, weight: FontWeight.w600)),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: options.entries.map((option) {
            final selected = option.key == value;
            return ChoiceChip(
              key: ValueKey('plan-$label-${option.key}'),
              label: Text(option.value),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => setState(() => onChanged(option.key)),
              labelStyle: planText(
                  size: 12,
                  color: selected ? planBg : Colors.white,
                  weight: FontWeight.w600),
              backgroundColor: planCard,
              selectedColor: planGreen,
              side: BorderSide(color: selected ? planGreen : planBorder),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final full = _days.length >= trainingPlanMaxDays;
    final total = _exerciseNames.length;
    return planScaled(
      context,
      Scaffold(
        backgroundColor: planBg,
        body: SafeArea(
          child: Column(
            children: [
              planTopBar(
                context,
                title: widget.plan == null ? 'New training plan' : 'Edit plan',
                subtitle: '${_days.length}/$trainingPlanMaxDays days',
                icon: Icons.close_rounded,
                action: TextButton(
                  key: const ValueKey('save-training-plan'),
                  onPressed: _saving || _uploading != null ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save',
                      style: planText(
                          size: 13, color: planGreen, weight: FontWeight.w700)),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    _sectionTitle('Cover image',
                        trailing: _coverUrl.isEmpty ? 'Required' : 'Added',
                        done: _coverUrl.isNotEmpty),
                    _coverCard(),
                    const SizedBox(height: 18),
                    _sectionTitle('Intro video',
                        trailing: _intro == null || _intro!.failed
                            ? 'Required'
                            : 'Added',
                        done: _intro != null && !_intro!.failed),
                    _introCard(),
                    const SizedBox(height: 18),
                    TextField(
                      key: const ValueKey('plan-title'),
                      controller: _title,
                      maxLength: 80,
                      textCapitalization: TextCapitalization.sentences,
                      style: planText(size: 16, weight: FontWeight.w600),
                      decoration:
                          planInput('Plan name, e.g. 4-Week Glute Builder')
                              .copyWith(counterText: ''),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const ValueKey('plan-description'),
                      controller: _description,
                      maxLength: 2000,
                      minLines: 3,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      style: planText(size: 13),
                      decoration: planInput(
                              'Who is it for, what will they achieve, how is it structured?')
                          .copyWith(counterText: ''),
                    ),
                    const SizedBox(height: 16),
                    _picker('Goal', trainingPlanGoals, _goal, (v) => _goal = v),
                    _picker(
                        'Level', trainingPlanLevels, _level, (v) => _level = v),
                    _picker('Equipment', trainingPlanEquipment, _equipment,
                        (v) => _equipment = v),
                    Row(
                      children: [
                        Expanded(
                          child: _sectionTitle('Days',
                              trailing: total == 0
                                  ? null
                                  : 'Videos $_videosDone/$total',
                              done: total > 0 && _videosDone == total),
                        ),
                        if (_days.length >= 2 && !full)
                          TextButton.icon(
                            key: const ValueKey('repeat-plan-week'),
                            onPressed: _repeatWeek,
                            icon: const Icon(Icons.repeat_rounded,
                                color: planGreen, size: 17),
                            label: Text(
                                _days.length >= 7 ? 'Repeat week' : 'Repeat days',
                                style: planText(size: 12, color: planGreen)),
                          ),
                      ],
                    ),
                    Text(
                      'Open a day to add its exercises. Every exercise gets a short video '
                      '(up to 60 s) right under it showing how to do it; an exercise used '
                      'on several days shares one video.',
                      style: planText(size: 11, color: planMuted),
                    ),
                    const SizedBox(height: 10),
                    if (_days.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Add workout and rest days in the order people should do them. A plan can be 1 to 31 days long.',
                          style: planText(size: 12, color: planMuted),
                        ),
                      ),
                    ...List.generate(_days.length, _dayCard),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const ValueKey('add-plan-workout-day'),
                            onPressed: full ? null : _addWorkout,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              side: const BorderSide(color: planBorder),
                            ),
                            icon: const Icon(Icons.add_rounded,
                                color: planGreen, size: 19),
                            label: Text('Workout day',
                                style: planText(
                                    size: 13,
                                    color: planGreen,
                                    weight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const ValueKey('add-plan-rest-day'),
                            onPressed: full ? null : _addRest,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              side: const BorderSide(color: planBorder),
                            ),
                            icon: const Icon(Icons.bedtime_outlined,
                                color: planMuted, size: 18),
                            label: Text('Rest day',
                                style: planText(size: 13, color: planMuted)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Plans are free for now. Paid plans are coming soon.',
                      style: planText(size: 11, color: planMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
