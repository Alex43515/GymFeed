import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '/ai_workout/nutrition_diary/nutrition_diary_widget.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/firebase_storage/storage.dart';
import '/backend/supabase/repositories/progress_repository.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';
import '/workout/training_home/training_home_widget.dart';

const _progressBackground = Color(0xFF080808);
const _progressSurface = Color(0xFF151515);
const _progressBorder = Color(0xFF292929);
const _progressGreen = Color(0xFF1FE276);
const _progressMuted = Color(0xFF898989);

TextStyle _progressText({
  double size = 14,
  Color color = Colors.white,
  FontWeight weight = FontWeight.w400,
  double height = 1.3,
}) =>
    TextStyle(
      fontFamily: 'Poppins',
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
    );

String _metric(double? value, {int decimals = 0}) {
  if (value == null || value <= 0) return '—';
  return value.toStringAsFixed(decimals);
}

int _levelNumber(String value) {
  final level = value.toLowerCase();
  if (level.contains('advanced') || level.contains('napred')) return 3;
  if (level.contains('intermediate') || level.contains('sred')) return 2;
  if (level.contains('begin') ||
      level.contains('beggin') ||
      level.contains('počet') ||
      level.contains('pocet')) {
    return 1;
  }
  return 1;
}

class MyInfoWidget extends StatefulWidget {
  const MyInfoWidget({
    super.key,
    this.loader,
    this.overviewSaver,
    this.entrySaver,
    this.entryDeleter,
    this.photoUploader,
    this.workoutPlanOpener,
    this.mealPlanOpener,
  });

  static String routeName = 'myInfo';
  static String routePath = 'myInfo';

  final Future<ProgressData> Function()? loader;
  final Future<void> Function(ProgressOverview overview)? overviewSaver;
  final Future<ProgressEntry> Function(ProgressEntry entry)? entrySaver;
  final Future<void> Function(ProgressEntry entry)? entryDeleter;
  final Future<String?> Function(SelectedFile file)? photoUploader;
  final VoidCallback? workoutPlanOpener;
  final VoidCallback? mealPlanOpener;

  @override
  State<MyInfoWidget> createState() => _MyInfoWidgetState();
}

class _MyInfoWidgetState extends State<MyInfoWidget> {
  final _repository = ProgressRepository();
  late Future<ProgressData> _progressFuture;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _progressFuture = _load();
  }

  Future<ProgressData> _load() => widget.loader?.call() ?? _repository.load();

  Future<void> _refresh() async {
    setState(() {
      _progressFuture = _load();
    });
    await _progressFuture;
  }

  Future<void> _editOverview(ProgressOverview current) async {
    final edited = await showModalBottomSheet<ProgressOverview>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OverviewEditor(current: current),
    );
    if (edited == null || !mounted) return;
    setState(() => _saving = true);
    try {
      if (widget.overviewSaver != null) {
        await widget.overviewSaver!(edited);
      } else {
        await _repository.saveOverview(edited);
        await refreshCurrentUserProfile();
      }
      await _refresh();
    } catch (error) {
      if (mounted) _showError('Progress details were not saved', error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editMonth(DateTime month, ProgressEntry? current) async {
    final base = current ?? ProgressEntry(id: '', month: month);
    final draft = await showModalBottomSheet<_EntryDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EntryEditor(entry: base, canDelete: current != null),
    );
    if (draft == null || !mounted) return;
    setState(() => _saving = true);
    try {
      if (draft.delete) {
        if (widget.entryDeleter != null) {
          await widget.entryDeleter!(base);
        } else {
          await _repository.deleteEntry(base);
          await refreshCurrentUserProfile();
        }
      } else {
        var photoUrl = draft.removePhoto ? '' : base.photoUrl;
        if (draft.file != null) {
          photoUrl = widget.photoUploader != null
              ? await widget.photoUploader!(draft.file!) ?? ''
              : await uploadData(draft.file!.storagePath, draft.file!.bytes) ??
                  '';
          if (photoUrl.isEmpty) {
            throw StateError('The photo upload did not return a URL.');
          }
        }
        final entry = ProgressEntry(
          id: base.id,
          month: month,
          photoUrl: photoUrl,
          weightKg: draft.weightKg,
          bodyFatPercentage: draft.bodyFatPercentage,
          note: draft.note,
          legacySlot: base.legacySlot,
        );
        if (widget.entrySaver != null) {
          await widget.entrySaver!(entry);
        } else {
          await _repository.saveEntry(entry);
          await refreshCurrentUserProfile();
        }
      }
      await _refresh();
    } catch (error) {
      if (mounted) _showError('Monthly progress was not saved', error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addMonth(ProgressData data) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _progressGreen,
            surface: _progressSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    final month = DateTime(picked.year, picked.month);
    ProgressEntry? existing;
    for (final entry in data.entries) {
      if (entry.monthKey == progressMonthKey(month)) {
        existing = entry;
        break;
      }
    }
    await _editMonth(month, existing);
  }

  void _showError(String message, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$message: $error')),
    );
  }

  List<DateTime> _visibleMonths(List<ProgressEntry> entries) {
    final now = DateTime.now();
    final months = <String, DateTime>{
      for (var offset = 5; offset >= 0; offset--)
        progressMonthKey(DateTime(now.year, now.month - offset)):
            DateTime(now.year, now.month - offset),
    };
    for (final entry in entries) {
      months[entry.monthKey] = entry.month;
    }
    final values = months.values.toList()..sort();
    return values;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
          textScaler: media.textScaler.clamp(maxScaleFactor: 1.3)),
      child: Scaffold(
        backgroundColor: _progressBackground,
        body: SafeArea(
          child: Stack(
            children: [
              FutureBuilder<ProgressData>(
                future: _progressFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData &&
                      snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: _progressGreen,
                        strokeWidth: 2,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return _ProgressError(onRetry: _refresh);
                  }
                  final data = snapshot.data ??
                      const ProgressData(
                        overview: ProgressOverview(),
                        entries: [],
                      );
                  final entriesByMonth = {
                    for (final entry in data.entries) entry.monthKey: entry,
                  };
                  final months = _visibleMonths(data.entries);
                  return RefreshIndicator(
                    color: _progressGreen,
                    backgroundColor: _progressSurface,
                    onRefresh: _refresh,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _ProgressHeader(
                            onBack: context.safePop,
                            onEdit: () => _editOverview(data.overview),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 3, 20, 35),
                          sliver: SliverList.list(
                            children: [
                              _OverviewCard(
                                overview: data.overview,
                                entries: data.entries,
                                onTap: () => _editOverview(data.overview),
                              ),
                              const SizedBox(height: 19),
                              const _SectionTitle('Activity'),
                              const SizedBox(height: 9),
                              _ActivityCards(
                                overview: data.overview,
                                onTap: () => _editOverview(data.overview),
                              ),
                              const SizedBox(height: 19),
                              const _SectionTitle('Workout level'),
                              const SizedBox(height: 9),
                              _LevelCard(
                                value: data.overview.workoutLevel,
                                onTap: () => _editOverview(data.overview),
                              ),
                              const SizedBox(height: 19),
                              const _SectionTitle('Your plans'),
                              const SizedBox(height: 9),
                              _PlanCard(
                                key: const ValueKey('progress-workout-plan'),
                                icon: Icons.fitness_center_rounded,
                                iconColor: _progressGreen,
                                title: 'My workout plan',
                                subtitle: 'Open your workout plan in Train',
                                onTap: widget.workoutPlanOpener ??
                                    () => context.pushNamed(
                                          TrainingHomeWidget.routeName,
                                        ),
                              ),
                              const SizedBox(height: 10),
                              _PlanCard(
                                key: const ValueKey('progress-meal-plan'),
                                icon: Icons.restaurant_menu_rounded,
                                iconColor: const Color(0xFF4B9DFF),
                                title: 'My meal plan',
                                subtitle: 'Open your meals in Nutrition Diary',
                                onTap: widget.mealPlanOpener ??
                                    () => context.pushNamed(
                                          NutritionDiaryWidget.routeName,
                                        ),
                              ),
                              const SizedBox(height: 18),
                              _TrainerSuggestion(
                                value: data.overview.trainerSuggestion,
                                onTap: () => _editOverview(data.overview),
                              ),
                              const SizedBox(height: 23),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Progress by month',
                                            style: _progressText(
                                                size: 17,
                                                weight: FontWeight.w700)),
                                        Text(
                                          'Upload a photo and update your measurements each month',
                                          style: _progressText(
                                              size: 11, color: _progressMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    key: const ValueKey('progress-add-month'),
                                    tooltip: 'Add month',
                                    onPressed: () => _addMonth(data),
                                    icon: const Icon(Icons.add_circle_rounded,
                                        color: _progressGreen),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _PhotoComparison(entries: data.entries),
                              const SizedBox(height: 14),
                              for (var index = 0;
                                  index < months.length;
                                  index++) ...[
                                _MonthRow(
                                  index: index,
                                  month: months[index],
                                  entry: entriesByMonth[
                                      progressMonthKey(months[index])],
                                  onTap: () => _editMonth(
                                    months[index],
                                    entriesByMonth[
                                        progressMonthKey(months[index])],
                                  ),
                                ),
                                if (index != months.length - 1)
                                  const SizedBox(height: 9),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (_saving)
                Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(
                    color: _progressGreen,
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.onBack, required this.onEdit});

  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 67,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Back',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            Text('My Progress',
                style: _progressText(size: 17, weight: FontWeight.w700)),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 7),
                child: IconButton(
                  key: const ValueKey('progress-edit-overview'),
                  tooltip: 'Edit progress details',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined,
                      color: _progressGreen, size: 21),
                ),
              ),
            ),
          ],
        ),
      );
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.overview,
    required this.entries,
    required this.onTap,
  });

  final ProgressOverview overview;
  final List<ProgressEntry> entries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weights = entries
        .map((entry) => entry.weightKg)
        .whereType<double>()
        .where((value) => value > 0)
        .toList();
    final fats = entries
        .map((entry) => entry.bodyFatPercentage)
        .whereType<double>()
        .where((value) => value > 0)
        .toList();
    final weightDelta =
        weights.isEmpty ? null : overview.weightKg - weights.first;
    final fatDelta =
        fats.isEmpty ? null : overview.bodyFatPercentage - fats.first;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        key: const ValueKey('progress-overview-card'),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0A2014),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF12673A)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _OverviewMetric(
                label: 'Weight',
                value: _metric(overview.weightKg),
                unit: 'kg',
                delta: weightDelta == null
                    ? 'Tap to update'
                    : '${weightDelta > 0 ? '+' : ''}${weightDelta.toStringAsFixed(1)} kg total',
              ),
            ),
            Container(width: 1, height: 64, color: const Color(0xFF28523A)),
            const SizedBox(width: 14),
            Expanded(
              child: _OverviewMetric(
                label: 'Body fat',
                value: _metric(overview.bodyFatPercentage, decimals: 1),
                unit: '%',
                delta: fatDelta == null
                    ? 'Tap to update'
                    : '${fatDelta > 0 ? '+' : ''}${fatDelta.toStringAsFixed(1)}% total',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.delta,
  });

  final String label;
  final String value;
  final String unit;
  final String delta;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _progressText(size: 11, color: _progressMuted)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  alignment: Alignment.bottomLeft,
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(value,
                          key: ValueKey('progress-$label-value'),
                          maxLines: 1,
                          style: _progressText(
                              size: 27, weight: FontWeight.w700)),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(unit,
                            key: ValueKey('progress-$label-unit'),
                            style: _progressText(
                                size: 11, color: _progressMuted)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Text(delta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _progressText(
                  size: 10, color: _progressGreen, weight: FontWeight.w600)),
        ],
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.value);
  final String value;

  @override
  Widget build(BuildContext context) => Text(value,
      style: _progressText(
          size: 13, color: _progressMuted, weight: FontWeight.w600));
}

class _ActivityCards extends StatelessWidget {
  const _ActivityCards({required this.overview, required this.onTap});
  final ProgressOverview overview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: _ActivityCard(
              value: overview.workoutsPerWeek.isEmpty
                  ? '—'
                  : overview.workoutsPerWeek,
              label: 'Workouts / week',
              onTap: onTap,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: _ActivityCard(
              value:
                  overview.sessionLength.isEmpty ? '—' : overview.sessionLength,
              label: 'Min / session',
              onTap: onTap,
            ),
          ),
        ],
      );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.value,
    required this.label,
    required this.onTap,
  });
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _progressSurface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _progressBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _progressText(size: 20, weight: FontWeight.w700)),
              Text(label,
                  style: _progressText(size: 10, color: _progressMuted)),
            ],
          ),
        ),
      );
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.value, required this.onTap});
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final level = _levelNumber(value);
    final label = value.trim().isEmpty ? 'Beginner' : value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Ink(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: _progressSurface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: _progressBorder),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: _progressText(size: 14, weight: FontWeight.w700)),
                ),
                Text('Level $level of 3',
                    style: _progressText(
                        size: 10,
                        color: _progressGreen,
                        weight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: level / 3,
                minHeight: 8,
                backgroundColor: const Color(0xFF252525),
                color: _progressGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _progressSurface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _progressBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            _progressText(size: 13, weight: FontWeight.w700)),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _progressText(size: 10, color: _progressMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: _progressMuted, size: 22),
            ],
          ),
        ),
      );
}

class _TrainerSuggestion extends StatelessWidget {
  const _TrainerSuggestion({required this.value, required this.onTap});
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1D12),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFF12673A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: _progressGreen, size: 15),
                  const SizedBox(width: 8),
                  Text('Trainer suggestion',
                      style: _progressText(
                          size: 12,
                          color: _progressGreen,
                          weight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                value.trim().isEmpty
                    ? 'Add a trainer suggestion or coaching note.'
                    : value,
                style: _progressText(size: 12),
              ),
            ],
          ),
        ),
      );
}

class _PhotoComparison extends StatelessWidget {
  const _PhotoComparison({required this.entries});
  final List<ProgressEntry> entries;

  @override
  Widget build(BuildContext context) {
    final withPhotos = entries
        .where((entry) => entry.photoUrl.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => a.month.compareTo(b.month));
    final first = withPhotos.isEmpty ? null : withPhotos.first;
    final latest = withPhotos.isEmpty ? null : withPhotos.last;
    return Row(
      children: [
        Expanded(
          child: _ComparisonPhoto(label: 'FIRST', entry: first),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward_rounded,
              color: _progressGreen, size: 19),
        ),
        Expanded(
          child: _ComparisonPhoto(label: 'NOW', entry: latest),
        ),
      ],
    );
  }
}

class _ComparisonPhoto extends StatelessWidget {
  const _ComparisonPhoto({required this.label, required this.entry});
  final String label;
  final ProgressEntry? entry;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label · ${entry == null ? '—' : DateFormat('MMM').format(entry!.month)}',
            style: _progressText(
                size: 9,
                color: label == 'NOW' ? _progressGreen : _progressMuted,
                weight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Container(
            height: 174,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _progressSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: label == 'NOW' && entry != null
                    ? const Color(0xFF12673A)
                    : _progressBorder,
              ),
            ),
            child: entry?.photoUrl.isNotEmpty == true
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: entry!.photoUrl,
                        fit: BoxFit.cover,
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            entry!.weightKg == null
                                ? 'Photo'
                                : '${_metric(entry!.weightKg, decimals: 1)} kg',
                            style:
                                _progressText(size: 9, weight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined,
                            color: _progressMuted, size: 28),
                        const SizedBox(height: 7),
                        Text('No photo yet',
                            style:
                                _progressText(size: 10, color: _progressMuted)),
                      ],
                    ),
                  ),
          ),
        ],
      );
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({
    required this.index,
    required this.month,
    required this.entry,
    required this.onTap,
  });

  final int index;
  final DateTime month;
  final ProgressEntry? entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        key: ValueKey('progress-month-${progressMonthKey(month)}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 74,
          decoration: BoxDecoration(
            color: _progressSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _progressBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 66,
                height: 74,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: Color(0xFF111111),
                  borderRadius:
                      BorderRadius.horizontal(left: Radius.circular(16)),
                ),
                child: entry?.photoUrl.isNotEmpty == true
                    ? CachedNetworkImage(
                        imageUrl: entry!.photoUrl,
                        fit: BoxFit.cover,
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              color: _progressMuted, size: 18),
                          SizedBox(height: 4),
                          Text('Add photo',
                              style: TextStyle(
                                  color: _progressMuted,
                                  fontFamily: 'Poppins',
                                  fontSize: 8)),
                        ],
                      ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Month ${index + 1}',
                        style:
                            _progressText(size: 12, weight: FontWeight.w700)),
                    Text(DateFormat('MMM yyyy').format(month),
                        style: _progressText(size: 9, color: _progressMuted)),
                    if (entry?.note.trim().isNotEmpty == true)
                      Text(entry!.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _progressText(size: 8, color: _progressMuted)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 13),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      entry?.weightKg == null
                          ? '—'
                          : '${_metric(entry!.weightKg, decimals: 1)} kg',
                      style: _progressText(size: 12, weight: FontWeight.w700),
                    ),
                    Text(
                      entry?.bodyFatPercentage == null
                          ? 'Tap to edit'
                          : '${_metric(entry!.bodyFatPercentage, decimals: 1)}% bf',
                      style: _progressText(
                          size: 9,
                          color: entry?.bodyFatPercentage == null
                              ? _progressMuted
                              : _progressGreen,
                          weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _OverviewEditor extends StatefulWidget {
  const _OverviewEditor({required this.current});
  final ProgressOverview current;

  @override
  State<_OverviewEditor> createState() => _OverviewEditorState();
}

class _OverviewEditorState extends State<_OverviewEditor> {
  late final TextEditingController _weight;
  late final TextEditingController _bodyFat;
  late final TextEditingController _workouts;
  late final TextEditingController _session;
  late final TextEditingController _workoutPlan;
  late final TextEditingController _mealPlan;
  late final TextEditingController _suggestion;
  late String _level;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    _weight = TextEditingController(
        text: current.weightKg <= 0 ? '' : current.weightKg.toStringAsFixed(0));
    _bodyFat = TextEditingController(
        text: current.bodyFatPercentage <= 0
            ? ''
            : current.bodyFatPercentage.toStringAsFixed(1));
    _workouts = TextEditingController(text: current.workoutsPerWeek);
    _session = TextEditingController(text: current.sessionLength);
    _workoutPlan = TextEditingController(text: current.workoutPlan);
    _mealPlan = TextEditingController(text: current.mealPlan);
    _suggestion = TextEditingController(text: current.trainerSuggestion);
    final number = _levelNumber(current.workoutLevel);
    _level = const ['Beginner', 'Intermediate', 'Advanced'][number - 1];
  }

  @override
  void dispose() {
    _weight.dispose();
    _bodyFat.dispose();
    _workouts.dispose();
    _session.dispose();
    _workoutPlan.dispose();
    _mealPlan.dispose();
    _suggestion.dispose();
    super.dispose();
  }

  void _save() {
    final weight = double.tryParse(_weight.text.trim());
    final bodyFat = double.tryParse(_bodyFat.text.trim());
    if (weight == null || weight < 20 || weight > 500) {
      _message('Enter a weight between 20 and 500 kg.');
      return;
    }
    if (bodyFat == null || bodyFat < 1 || bodyFat > 75) {
      _message('Enter body fat between 1 and 75%.');
      return;
    }
    Navigator.pop(
      context,
      ProgressOverview(
        weightKg: weight,
        bodyFatPercentage: bodyFat,
        workoutsPerWeek: _workouts.text.trim(),
        sessionLength: _session.text.trim(),
        workoutLevel: _level,
        workoutPlan: _workoutPlan.text.trim(),
        mealPlan: _mealPlan.text.trim(),
        trainerSuggestion: _suggestion.text.trim(),
      ),
    );
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) => _EditorShell(
        title: 'Edit progress',
        action: TextButton(
          key: const ValueKey('progress-save-overview'),
          onPressed: _save,
          child: Text('Save',
              style: _progressText(
                  color: _progressGreen, weight: FontWeight.w700)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _EditorField(
                    controller: _weight,
                    label: 'Weight (kg)',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _EditorField(
                    controller: _bodyFat,
                    label: 'Body fat (%)',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(
                  child: _EditorField(
                    controller: _workouts,
                    label: 'Workouts / week',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _EditorField(
                    controller: _session,
                    label: 'Session length',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            DropdownButtonFormField<String>(
              value: _level,
              dropdownColor: _progressSurface,
              style: _progressText(size: 12),
              decoration: _editorDecoration('Workout level'),
              items: const ['Beginner', 'Intermediate', 'Advanced']
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _level = value ?? _level),
            ),
            const SizedBox(height: 11),
            _EditorField(
              controller: _workoutPlan,
              label: 'Workout plan',
              minLines: 2,
              maxLines: 5,
            ),
            const SizedBox(height: 11),
            _EditorField(
              controller: _mealPlan,
              label: 'Meal plan',
              minLines: 2,
              maxLines: 5,
            ),
            const SizedBox(height: 11),
            _EditorField(
              controller: _suggestion,
              label: 'Trainer suggestion',
              minLines: 3,
              maxLines: 6,
            ),
          ],
        ),
      );
}

class _EntryDraft {
  const _EntryDraft({
    this.file,
    this.removePhoto = false,
    this.weightKg,
    this.bodyFatPercentage,
    this.note = '',
    this.delete = false,
  });

  final SelectedFile? file;
  final bool removePhoto;
  final double? weightKg;
  final double? bodyFatPercentage;
  final String note;
  final bool delete;
}

class _EntryEditor extends StatefulWidget {
  const _EntryEditor({required this.entry, required this.canDelete});
  final ProgressEntry entry;
  final bool canDelete;

  @override
  State<_EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends State<_EntryEditor> {
  late final TextEditingController _weight;
  late final TextEditingController _bodyFat;
  late final TextEditingController _note;
  SelectedFile? _file;
  bool _removePhoto = false;

  @override
  void initState() {
    super.initState();
    _weight = TextEditingController(
        text: widget.entry.weightKg?.toStringAsFixed(1) ?? '');
    _bodyFat = TextEditingController(
        text: widget.entry.bodyFatPercentage?.toStringAsFixed(1) ?? '');
    _note = TextEditingController(text: widget.entry.note);
  }

  @override
  void dispose() {
    _weight.dispose();
    _bodyFat.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final selection = await selectMedia(
      storageFolderPath: 'progress/${progressMonthKey(widget.entry.month)}',
      mediaSource: MediaSource.photoGallery,
      imageQuality: 88,
    );
    if (selection == null || selection.isEmpty || !mounted) return;
    setState(() {
      _file = selection.first;
      _removePhoto = false;
    });
  }

  void _save() {
    final weight = _weight.text.trim().isEmpty
        ? null
        : double.tryParse(_weight.text.trim());
    final bodyFat = _bodyFat.text.trim().isEmpty
        ? null
        : double.tryParse(_bodyFat.text.trim());
    if (weight != null && (weight < 20 || weight > 500)) {
      _message('Weight must be between 20 and 500 kg.');
      return;
    }
    if (bodyFat != null && (bodyFat < 1 || bodyFat > 75)) {
      _message('Body fat must be between 1 and 75%.');
      return;
    }
    Navigator.pop(
      context,
      _EntryDraft(
        file: _file,
        removePhoto: _removePhoto,
        weightKg: weight,
        bodyFatPercentage: bodyFat,
        note: _note.text.trim(),
      ),
    );
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  ImageProvider<Object>? get _preview {
    if (_file != null) return MemoryImage(Uint8List.fromList(_file!.bytes));
    if (!_removePhoto && widget.entry.photoUrl.isNotEmpty) {
      return CachedNetworkImageProvider(widget.entry.photoUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => _EditorShell(
        title: DateFormat('MMMM yyyy').format(widget.entry.month),
        action: TextButton(
          key: const ValueKey('progress-save-month'),
          onPressed: _save,
          child: Text('Save',
              style: _progressText(
                  color: _progressGreen, weight: FontWeight.w700)),
        ),
        child: Column(
          children: [
            InkWell(
              key: const ValueKey('progress-pick-photo'),
              onTap: _pickPhoto,
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _progressBorder),
                  image: _preview == null
                      ? null
                      : DecorationImage(image: _preview!, fit: BoxFit.cover),
                ),
                child: _preview == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined,
                              color: _progressGreen, size: 29),
                          const SizedBox(height: 8),
                          Text('Upload progress photo',
                              style: _progressText(
                                  size: 12, weight: FontWeight.w700)),
                        ],
                      )
                    : const Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: CircleAvatar(
                            backgroundColor: Colors.black87,
                            child: Icon(Icons.edit_outlined,
                                color: _progressGreen, size: 18),
                          ),
                        ),
                      ),
              ),
            ),
            if (_preview != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _file = null;
                    _removePhoto = true;
                  }),
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFFF7272), size: 18),
                  label: Text('Remove photo',
                      style: _progressText(
                          size: 10, color: const Color(0xFFFF7272))),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _EditorField(
                    controller: _weight,
                    label: 'Weight (kg)',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _EditorField(
                    controller: _bodyFat,
                    label: 'Body fat (%)',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            _EditorField(
              controller: _note,
              label: 'Monthly note',
              minLines: 2,
              maxLines: 4,
            ),
            if (widget.canDelete) ...[
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(
                    context,
                    const _EntryDraft(delete: true),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF7272),
                    side: const BorderSide(color: Color(0xFF633232)),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete this month'),
                ),
              ),
            ],
          ],
        ),
      );
}

class _EditorShell extends StatelessWidget {
  const _EditorShell({
    required this.title,
    required this.action,
    required this.child,
  });

  final String title;
  final Widget action;
  final Widget child;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        initialChildSize: .88,
        minChildSize: .55,
        maxChildSize: .96,
        builder: (context, controller) => Container(
          decoration: const BoxDecoration(
            color: _progressSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            border: Border(top: BorderSide(color: _progressBorder)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A4A4A),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: _progressText(
                                size: 17, weight: FontWeight.w700)),
                      ),
                      action,
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(18, 5, 18,
                        20 + MediaQuery.viewInsetsOf(context).bottom),
                    children: [child],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _EditorField extends StatelessWidget {
  const _EditorField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: keyboardType,
        minLines: minLines,
        maxLines: maxLines,
        cursorColor: _progressGreen,
        style: _progressText(size: 12),
        decoration: _editorDecoration(label),
      );
}

InputDecoration _editorDecoration(String label) => InputDecoration(
      labelText: label,
      labelStyle: _progressText(size: 11, color: _progressMuted),
      filled: true,
      fillColor: const Color(0xFF111111),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _progressBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _progressGreen),
      ),
    );

class _ProgressError extends StatelessWidget {
  const _ProgressError({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, color: _progressGreen),
          label: Text('Could not load progress. Try again.',
              style: _progressText(color: _progressMuted)),
        ),
      );
}
