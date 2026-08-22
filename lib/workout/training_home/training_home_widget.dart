import 'dart:async';

import '/ai_workout/coach_home/coach_section_switcher.dart';
import '/ai_workout/starter_plan/starter_plan_service.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/supabase/repositories/training_repository.dart';
import '/components/nav_bar/nav_bar_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/workout/routines/workout_routine_flow.dart';
import '/workout/routines/workout_routine_models.dart';
import '/workout/routines/workout_routine_store.dart';
import 'package:flutter/material.dart';
import 'training_home_model.dart';
export 'training_home_model.dart';

class TrainingHomeWidget extends StatefulWidget {
  const TrainingHomeWidget({super.key, this.trainingsLoader});

  final Future<List<Training>> Function()? trainingsLoader;

  static String routeName = 'trainingHome';
  static String routePath = 'trainingHome';

  static Future<List<Training>>? _cachedTrainings;
  static String? _cachedUserId;

  static Future<void> warmUp() async {
    try {
      await Future.wait<dynamic>([
        _loadTrainings(),
        WorkoutRoutineStore.loadRoutines(),
        WorkoutRoutineStore.loadHistory(),
        WorkoutRoutineStore.loadSchedule(),
      ]);
    } catch (_) {
      // Startup remains usable when a remote feed is temporarily unavailable.
    }
  }

  static Future<List<Training>> _loadTrainings({bool refresh = false}) {
    final userId = currentUserUid;
    if (refresh || _cachedTrainings == null || _cachedUserId != userId) {
      _cachedUserId = userId;
      _cachedTrainings = TrainingRepository().feed(limit: 30);
    }
    return _cachedTrainings!;
  }

  @override
  State<TrainingHomeWidget> createState() => _TrainingHomeWidgetState();
}

class _TrainingHomeWidgetState extends State<TrainingHomeWidget> {
  late TrainingHomeModel _model;
  late Future<List<Training>> _trainingsFuture;
  late Future<List<WorkoutRoutine>> _routinesFuture;
  late Future<List<WorkoutHistoryItem>> _historyFuture;
  late Future<Map<String, List<String>>> _scheduleFuture;

  late DateTime _selectedDate;
  late DateTime _visibleWeekStart;

  int _tab = 0;

  static const _bg = Color(0xFF0B0B0B);
  static const _card = Color(0xFF141414);
  static const _border = Color(0xFF282828);
  static const _muted = Color(0xFF8B8B8B);
  static const _green = Color(0xFF1FE276);
  static const _flame = Color(0xFFFF8A3D);

  static const _weekdayShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];
  static const _weekdayLong = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TrainingHomeModel());
    _trainingsFuture =
        widget.trainingsLoader?.call() ?? TrainingHomeWidget._loadTrainings();
    _routinesFuture = WorkoutRoutineStore.loadRoutines();
    _historyFuture = WorkoutRoutineStore.loadHistory();
    _scheduleFuture = WorkoutRoutineStore.loadSchedule();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _visibleWeekStart =
        _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    unawaited(_ensureStarterPlan());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  TextStyle _text({
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

  Future<void> _refresh() async {
    try {
      await StarterPlanService().ensureRequestedPlan();
    } catch (_) {
      // Pull-to-refresh still refreshes local workouts while AI is unavailable.
    }
    _trainingsFuture = widget.trainingsLoader?.call() ??
        TrainingHomeWidget._loadTrainings(refresh: true);
    _routinesFuture = WorkoutRoutineStore.loadRoutines();
    _historyFuture = WorkoutRoutineStore.loadHistory();
    _scheduleFuture = WorkoutRoutineStore.loadSchedule();
    setState(() {});
    await Future.wait<dynamic>([
      _trainingsFuture.catchError((_) => <Training>[]),
      _routinesFuture,
      _historyFuture,
      _scheduleFuture,
    ]);
  }

  Future<void> _ensureStarterPlan() async {
    try {
      final plan = await StarterPlanService().ensureRequestedPlan();
      if (plan?.status == 'ready' && mounted) await _refreshLocal();
    } catch (_) {
      // Signup is never blocked by a temporary AI or network outage. A later
      // visit/pull-to-refresh retries the already-requested plan.
    }
  }

  void _selectCoachSection(CoachSection section) {
    switch (section) {
      case CoachSection.coach:
        context.goNamed(CoachHomeWidget.routeName);
        return;
      case CoachSection.train:
        return;
      case CoachSection.events:
        context.goNamed(CoachEventsWidget.routeName);
        return;
    }
  }

  Future<void> _newRoutine() async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
      settings: const RouteSettings(name: 'new-routine'),
      builder: (_) => const RoutineBuilderWidget(),
    ));
    if (saved == true && mounted) await _refreshLocal();
  }

  Future<void> _editRoutine(WorkoutRoutine routine) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
      settings: const RouteSettings(name: 'edit-routine'),
      builder: (_) => RoutineBuilderWidget(routine: routine),
    ));
    if (saved == true && mounted) await _refreshLocal();
  }

  Future<void> _openRoutine(WorkoutRoutine routine,
      {bool startImmediately = false}) async {
    final completed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      settings: RouteSettings(
          name: startImmediately ? 'active-workout' : 'routine-detail'),
      builder: (_) => startImmediately
          ? ActiveWorkoutWidget(routine: routine)
          : RoutineDetailWidget(routine: routine),
    ));
    if (completed == true && mounted) await _refreshLocal();
  }

  Future<void> _refreshLocal() async {
    _routinesFuture = WorkoutRoutineStore.loadRoutines();
    _historyFuture = WorkoutRoutineStore.loadHistory();
    _scheduleFuture = WorkoutRoutineStore.loadSchedule();
    setState(() {});
    await Future.wait<dynamic>(
        [_routinesFuture, _historyFuture, _scheduleFuture]);
  }

  String _lastPerformedLabel(WorkoutRoutine routine) {
    final date = routine.lastPerformedAt;
    if (date == null) return 'New';
    final now = DateTime.now();
    final difference = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    if (difference <= 0) return 'today';
    if (difference == 1) return 'yesterday';
    return '$difference days ago';
  }

  String _historyDate(DateTime date) {
    final now = DateTime.now();
    final difference = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return '${_weekdayShort[date.weekday - 1]}, ${_months[date.month - 1]} ${date.day}';
  }

  Widget _header(int streak) {
    final display = currentUserDisplayName.trim();
    final name = display.isEmpty ? 'athlete' : display.split(' ').first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 17, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_weekdayLong[_selectedDate.weekday - 1]}, '
                  '${_months[_selectedDate.month - 1]} ${_selectedDate.day}',
                  style: _text(size: 12, color: _muted),
                ),
                const SizedBox(height: 2),
                Text("Let's train, $name",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        _text(size: 25, weight: FontWeight.w700, height: 1.12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: _flame, size: 19),
                const SizedBox(width: 6),
                Text('$streak',
                    style: _text(size: 14, weight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  void _selectDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    setState(() {
      _selectedDate = normalized;
      _visibleWeekStart =
          normalized.subtract(Duration(days: normalized.weekday - 1));
    });
  }

  void _moveWeek(int weeks) {
    setState(() {
      _visibleWeekStart = _visibleWeekStart.add(Duration(days: weeks * 7));
      _selectedDate = _visibleWeekStart;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _green,
            onPrimary: _bg,
            surface: _card,
            onSurface: Colors.white,
          ),
          datePickerTheme: const DatePickerThemeData(
            backgroundColor: _card,
            dividerColor: _border,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) _selectDate(picked);
  }

  Widget _weekStrip() {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 13, 4, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                key: const ValueKey('calendar-previous-week'),
                tooltip: 'Previous week',
                onPressed: () => _moveWeek(-1),
                icon:
                    const Icon(Icons.chevron_left_rounded, color: Colors.white),
              ),
              Expanded(
                child: TextButton.icon(
                  key: const ValueKey('calendar-date-picker'),
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month_rounded,
                      color: _green, size: 18),
                  label: Text(
                    '${_months[_selectedDate.month - 1]} ${_selectedDate.year}',
                    style: _text(size: 13, weight: FontWeight.w700),
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('calendar-next-week'),
                tooltip: 'Next week',
                onPressed: () => _moveWeek(1),
                icon: const Icon(Icons.chevron_right_rounded,
                    color: Colors.white),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final date = _visibleWeekStart.add(Duration(days: index));
              final today = _sameDate(date, now);
              final selected = _sameDate(date, _selectedDate);
              return Expanded(
                child: InkWell(
                  key: ValueKey(
                      'calendar-date-${WorkoutRoutineStore.dateKey(date)}'),
                  onTap: () => _selectDate(date),
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(_weekdayShort[index],
                            style: _text(
                                size: 10,
                                color: selected ? Colors.white : _muted,
                                weight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 35,
                        height: 35,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? _green : Colors.transparent,
                          shape: BoxShape.circle,
                          border: !selected && today
                              ? Border.all(color: _green)
                              : null,
                        ),
                        child: Text('${date.day}',
                            style: _text(
                                size: 13,
                                color: selected ? _bg : Colors.white,
                                weight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: today ? _green : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _todayCard(WorkoutRoutine routine, {VoidCallback? onRemove}) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(routine.name,
                        style: _text(size: 19, weight: FontWeight.w700)),
                    Text(
                        '${routine.exercises.length} exercises · ~${routine.estimatedMinutes} min',
                        style: _text(size: 11, color: _muted)),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 47,
                    height: 47,
                    decoration: BoxDecoration(
                      color: _green,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.fitness_center_rounded,
                        color: _bg, size: 21),
                  ),
                  if (onRemove != null)
                    IconButton(
                      key: ValueKey('remove-scheduled-${routine.id}'),
                      tooltip: 'Remove from this date',
                      visualDensity: VisualDensity.compact,
                      onPressed: onRemove,
                      icon: const Icon(Icons.close_rounded,
                          color: _muted, size: 18),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const ValueKey('preview-today-routine'),
                  onPressed: () => _openRoutine(routine),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: _border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text('Preview',
                      style: _text(size: 12, weight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  key: const ValueKey('start-today-workout'),
                  onPressed: () =>
                      _openRoutine(routine, startImmediately: true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: _green,
                    foregroundColor: _bg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text('Start workout',
                      style:
                          _text(size: 12, color: _bg, weight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _selectedDateLabel {
    final now = DateTime.now();
    if (_sameDate(_selectedDate, now)) return "Today's plan";
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (_sameDate(_selectedDate, tomorrow)) return "Tomorrow's plan";
    if (_sameDate(_selectedDate, yesterday)) return "Yesterday's plan";
    return '${_weekdayLong[_selectedDate.weekday - 1]}, '
        '${_months[_selectedDate.month - 1]} ${_selectedDate.day}';
  }

  Future<void> _addScheduledWorkout(
    List<WorkoutRoutine> routines,
    List<String> scheduledIds,
  ) async {
    final selectedId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.76),
          decoration: const BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
            border: Border(top: BorderSide(color: _border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 11),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A4A4A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Add workout',
                          style: _text(size: 20, weight: FontWeight.w700)),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon:
                          const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  itemCount: routines.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final routine = routines[index];
                    final added = scheduledIds.contains(routine.id);
                    return ListTile(
                      key: ValueKey('schedule-routine-${routine.id}'),
                      enabled: !added,
                      onTap: added
                          ? null
                          : () => Navigator.pop(sheetContext, routine.id),
                      tileColor: const Color(0xFF111111),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: _border),
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF123821),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.fitness_center_rounded,
                            color: _green, size: 18),
                      ),
                      title: Text(routine.name,
                          style: _text(size: 14, weight: FontWeight.w700)),
                      subtitle: Text('${routine.exercises.length} exercises',
                          style: _text(size: 10, color: _muted)),
                      trailing: Text(added ? 'Added' : 'Add',
                          style: _text(
                              size: 11,
                              color: added ? _muted : _green,
                              weight: FontWeight.w700)),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
                child: OutlinedButton.icon(
                  key: const ValueKey('schedule-create-routine'),
                  onPressed: () => Navigator.pop(sheetContext, '__create__'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: _border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.add_rounded, color: _green, size: 18),
                  label: Text('Create custom routine',
                      style: _text(
                          size: 12, color: _green, weight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || selectedId == null) return;
    if (selectedId == '__create__') {
      final existingIds = routines.map((routine) => routine.id).toSet();
      await _newRoutine();
      final updatedRoutines = await WorkoutRoutineStore.loadRoutines();
      WorkoutRoutine? created;
      for (final routine in updatedRoutines) {
        if (!existingIds.contains(routine.id)) {
          created = routine;
          break;
        }
      }
      if (created != null) {
        await WorkoutRoutineStore.scheduleRoutine(_selectedDate, created.id);
        if (mounted) await _refreshLocal();
      }
      return;
    }
    await WorkoutRoutineStore.scheduleRoutine(_selectedDate, selectedId);
    if (mounted) await _refreshLocal();
  }

  Future<void> _removeScheduledWorkout(String routineId) async {
    await WorkoutRoutineStore.unscheduleRoutine(_selectedDate, routineId);
    if (mounted) await _refreshLocal();
  }

  Widget _emptySchedule(List<WorkoutRoutine> routines) => Container(
        padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            const Icon(Icons.event_available_rounded, color: _muted, size: 36),
            const SizedBox(height: 10),
            Text('No workout scheduled',
                style: _text(size: 14, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Add any routine to this date.',
                style: _text(size: 11, color: _muted)),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('add-scheduled-workout-empty'),
              onPressed: () => _addScheduledWorkout(routines, const []),
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: _bg,
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('Add workout',
                  style: _text(size: 12, color: _bg, weight: FontWeight.w700)),
            ),
          ],
        ),
      );

  Widget _aiCoachCard() {
    return InkWell(
      onTap: () => context.goNamed(CoachHomeWidget.routeName),
      borderRadius: BorderRadius.circular(19),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF062814),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: const Color(0xFF0C9A4D)),
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration:
                  const BoxDecoration(color: _green, shape: BoxShape.circle),
              child:
                  const Icon(Icons.auto_awesome_rounded, color: _bg, size: 20),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Coach',
                      style: _text(size: 15, weight: FontWeight.w700)),
                  Text('Ask the expert or scan a machine',
                      style: _text(size: 11, color: _muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _green, size: 27),
          ],
        ),
      ),
    );
  }

  Widget _tabs() {
    const labels = ['Plans', 'Joined', 'History'];
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = index == _tab;
          return Expanded(
            child: InkWell(
              key: ValueKey('training-tab-${labels[index].toLowerCase()}'),
              onTap: selected ? null : () => setState(() => _tab = index),
              borderRadius: BorderRadius.circular(22),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 170),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? _green : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(labels[index],
                    style: _text(
                        size: 12,
                        color: selected ? _bg : _muted,
                        weight: FontWeight.w600)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _routineCard(WorkoutRoutine routine) {
    return InkWell(
      key: ValueKey('routine-card-${routine.id}'),
      onTap: () => _openRoutine(routine),
      onLongPress: () => _editRoutine(routine),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF111814),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.fitness_center_rounded,
                  color: _green, size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(routine.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _text(size: 14, weight: FontWeight.w700)),
                  Text(routine.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _text(
                          size: 10, color: _green, weight: FontWeight.w600)),
                  Text(
                      '${routine.exercises.length} exercises · Last: ${_lastPerformedLabel(routine)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _text(size: 10, color: _muted)),
                ],
              ),
            ),
            IconButton.filled(
              key: ValueKey('play-routine-${routine.id}'),
              tooltip: 'Start ${routine.name}',
              onPressed: () => _openRoutine(routine, startImmediately: true),
              style: IconButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: _bg,
                fixedSize: const Size(42, 42),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 21),
            ),
            PopupMenuButton<String>(
              tooltip: 'Routine options',
              color: const Color(0xFF202020),
              icon:
                  const Icon(Icons.more_vert_rounded, color: _muted, size: 20),
              onSelected: (value) async {
                if (value == 'edit') {
                  await _editRoutine(routine);
                } else if (value == 'delete') {
                  await WorkoutRoutineStore.deleteRoutine(routine.id);
                  if (mounted) await _refreshLocal();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit', style: _text(size: 12)),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete',
                      style: _text(size: 12, color: const Color(0xFFFF7272))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _newRoutineButton() {
    return OutlinedButton.icon(
      key: const ValueKey('new-routine'),
      onPressed: _newRoutine,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(55),
        side: const BorderSide(color: _border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      icon: const Icon(Icons.add_rounded, color: _green, size: 19),
      label: Text('New routine',
          style: _text(size: 13, color: _green, weight: FontWeight.w700)),
    );
  }

  Widget _joinedCard(Training training) {
    final author = training.authorUsername.isNotEmpty
        ? '@${training.authorUsername}'
        : training.authorDisplayName;
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFF173A25),
            backgroundImage: training.authorPhotoUrl.isEmpty
                ? null
                : NetworkImage(training.authorPhotoUrl),
            child: training.authorPhotoUrl.isEmpty
                ? const Icon(Icons.groups_rounded, color: _green)
                : null,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(training.title.isEmpty ? 'Training event' : training.title,
                    style: _text(size: 14, weight: FontWeight.w700)),
                Text(author.isEmpty ? 'GymFeed coach' : author,
                    style: _text(size: 11, color: _green)),
                Text('${training.participantCount} joined',
                    style: _text(size: 10, color: _muted)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => context.pushNamed(JoinTrainingWidget.routeName),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('Details',
                style: _text(size: 11, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(WorkoutHistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.name,
                    style: _text(size: 15, weight: FontWeight.w700)),
              ),
              Text(_historyDate(item.startedAt),
                  style: _text(size: 10, color: _muted)),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              _historyMetric(
                  'Duration', workoutDurationLabel(item.durationSeconds)),
              _historyMetric('Volume', '${item.totalVolume.round()} kg'),
              _historyMetric('Sets', '${item.setsDone}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _historyMetric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _text(size: 9, color: _muted)),
          const SizedBox(height: 2),
          Text(value, style: _text(size: 12, weight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _empty(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 55),
      child: Column(
        children: [
          const Icon(Icons.fitness_center_rounded, color: _muted, size: 42),
          const SizedBox(height: 13),
          Text(message,
              textAlign: TextAlign.center,
              style: _text(size: 13, color: _muted)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final horizontal =
        media.size.width > 640 ? (media.size.width - 600) / 2 : 20.0;
    return MediaQuery(
      data: media.copyWith(
          textScaler: media.textScaler.clamp(maxScaleFactor: 1.35)),
      child: Scaffold(
        backgroundColor: _bg,
        bottomNavigationBar: wrapWithModel(
          model: _model.navBarModel,
          updateCallback: () => safeSetState(() {}),
          child: const NavBarWidget(selectPageIndex: 3),
        ),
        body: SafeArea(
          child: FutureBuilder<List<WorkoutRoutine>>(
            future: _routinesFuture,
            builder: (context, routineSnapshot) {
              final routines = routineSnapshot.data ?? const <WorkoutRoutine>[];
              return FutureBuilder<List<Training>>(
                future: _trainingsFuture,
                builder: (context, trainingSnapshot) {
                  final trainings = trainingSnapshot.data ?? const <Training>[];
                  final joined = trainings
                      .where((training) => training.joinedByMe)
                      .toList();
                  return FutureBuilder<List<WorkoutHistoryItem>>(
                    future: _historyFuture,
                    builder: (context, historySnapshot) {
                      final history =
                          historySnapshot.data ?? const <WorkoutHistoryItem>[];
                      return FutureBuilder<Map<String, List<String>>>(
                        future: _scheduleFuture,
                        builder: (context, scheduleSnapshot) {
                          final schedule = scheduleSnapshot.data ??
                              const <String, List<String>>{};
                          final scheduledIds = schedule[
                                  WorkoutRoutineStore.dateKey(_selectedDate)] ??
                              const <String>[];
                          final scheduledRoutines = routines
                              .where((routine) =>
                                  scheduledIds.contains(routine.id))
                              .toList();
                          return RefreshIndicator(
                            onRefresh: _refresh,
                            color: _green,
                            backgroundColor: _card,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                  horizontal, 16, horizontal, 28),
                              children: [
                                CoachSectionSwitcher(
                                  selected: CoachSection.train,
                                  onSelected: _selectCoachSection,
                                ),
                                _header(history.length),
                                _weekStrip(),
                                const SizedBox(height: 21),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(_selectedDateLabel,
                                          style: _text(
                                              size: 15,
                                              weight: FontWeight.w700)),
                                    ),
                                    if (scheduledRoutines.isNotEmpty)
                                      TextButton.icon(
                                        key: const ValueKey(
                                            'add-scheduled-workout'),
                                        onPressed: () => _addScheduledWorkout(
                                            routines, scheduledIds),
                                        icon: const Icon(Icons.add_rounded,
                                            color: _green, size: 17),
                                        label: Text('Add',
                                            style: _text(
                                                size: 11,
                                                color: _green,
                                                weight: FontWeight.w700)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (scheduledRoutines.isEmpty)
                                  _emptySchedule(routines)
                                else ...[
                                  ...scheduledRoutines.map((routine) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: _todayCard(
                                          routine,
                                          onRemove: () =>
                                              _removeScheduledWorkout(
                                                  routine.id),
                                        ),
                                      )),
                                ],
                                const SizedBox(height: 18),
                                _aiCoachCard(),
                                const SizedBox(height: 20),
                                _tabs(),
                                const SizedBox(height: 16),
                                if (_tab == 0) ...[
                                  if (routineSnapshot.connectionState ==
                                      ConnectionState.waiting)
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 45),
                                      child: Center(
                                          child: CircularProgressIndicator(
                                              color: _green, strokeWidth: 2.4)),
                                    )
                                  else if (routines.isEmpty)
                                    _empty(
                                        'No plans yet — create your first routine.'),
                                  ...routines.map(_routineCard),
                                  _newRoutineButton(),
                                ] else if (_tab == 1) ...[
                                  if (trainingSnapshot.connectionState ==
                                      ConnectionState.waiting)
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 45),
                                      child: Center(
                                          child: CircularProgressIndicator(
                                              color: _green, strokeWidth: 2.4)),
                                    )
                                  else if (joined.isEmpty)
                                    _empty('Events you join will appear here.')
                                  else
                                    ...joined.map(_joinedCard),
                                ] else ...[
                                  if (historySnapshot.connectionState ==
                                      ConnectionState.waiting)
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 45),
                                      child: Center(
                                          child: CircularProgressIndicator(
                                              color: _green, strokeWidth: 2.4)),
                                    )
                                  else if (history.isEmpty)
                                    _empty(
                                        'Completed workouts will appear here.')
                                  else
                                    ...history.map(_historyCard),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
