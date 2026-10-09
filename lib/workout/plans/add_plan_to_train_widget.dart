import 'package:flutter/material.dart';

import '/workout/routines/workout_routine_store.dart';

import 'training_plan_models.dart';
import 'training_plan_schedule.dart';
import 'training_plan_service.dart';
import 'training_plan_ui.dart';

typedef AddPlanCallback = Future<void> Function(
    DateTime start, PlanScheduleMode mode, Set<int> weekdays);

/// Lets the user pick a start date and schedule style, previews the calendar,
/// then schedules the plan. Pops `true` once the plan is in the Train calendar.
class AddPlanToTrainWidget extends StatefulWidget {
  const AddPlanToTrainWidget({
    super.key,
    required this.plan,
    this.initialStart,
    this.onConfirm,
  });

  final TrainingPlan plan;
  final DateTime? initialStart;

  /// Overrides the default save (local calendar + server enrollment) in tests.
  final AddPlanCallback? onConfirm;

  @override
  State<AddPlanToTrainWidget> createState() => _AddPlanToTrainWidgetState();
}

class _AddPlanToTrainWidgetState extends State<AddPlanToTrainWidget> {
  late DateTime _start;
  PlanScheduleMode _mode = PlanScheduleMode.consecutive;
  final Set<int> _weekdays = {1, 3, 5};
  Map<String, List<String>> _existing = const {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = widget.initialStart ?? DateTime.now();
    _start = DateTime(now.year, now.month, now.day);
    WorkoutRoutineStore.loadSchedule().then((schedule) {
      if (mounted) setState(() => _existing = schedule);
    });
  }

  Map<int, DateTime> get _dates => planWorkoutDates(
        days: widget.plan.days,
        start: _start,
        mode: _mode,
        weekdays: _weekdays,
      );

  int _conflicts(Map<int, DateTime> dates) {
    final ownKey = '${trainingPlanKey(widget.plan.id)}-';
    return dates.values.where((date) {
      final ids = _existing[WorkoutRoutineStore.dateKey(date)] ?? const [];
      return ids.any((id) => !id.startsWith(ownKey));
    }).length;
  }

  Future<void> _pickStart() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 2, 12, 31),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: planGreen, onPrimary: planBg, surface: planCard),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _confirm() async {
    if (_saving) return;
    if (_mode == PlanScheduleMode.weekdays && _weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pick at least one training day.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final onConfirm = widget.onConfirm ??
          (start, mode, weekdays) => TrainingPlanService()
              .addToTrain(
                  plan: widget.plan,
                  startDate: start,
                  mode: mode,
                  weekdays: weekdays)
              .then((_) {});
      await onConfirm(_start, _mode, Set.of(_weekdays));
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Could not add the plan. Check your connection and try again.')));
    }
  }

  Widget _modeOption(PlanScheduleMode mode, String title, String subtitle) {
    final selected = _mode == mode;
    return Expanded(
      child: InkWell(
        key: ValueKey('plan-mode-${mode.name}'),
        onTap: () => setState(() => _mode = mode),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0E2A19) : planCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? planGreen : planBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: planText(size: 13, weight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(subtitle, style: planText(size: 10, color: planMuted)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dates = _dates;
    final conflicts = _conflicts(dates);
    final workouts = dates.length;
    return planScaled(
      context,
      Scaffold(
        backgroundColor: planBg,
        body: SafeArea(
          child: Column(
            children: [
              planTopBar(context,
                  title: 'Add to my Train', subtitle: widget.plan.title),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    Text('Start date',
                        style: planText(
                            size: 13, color: planMuted, weight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Material(
                      color: planCard,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        key: const ValueKey('plan-start-date'),
                        onTap: _pickStart,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: planBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded,
                                  color: planGreen, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(planDateLabel(_start),
                                    style: planText(
                                        size: 14, weight: FontWeight.w700)),
                              ),
                              Text('Change',
                                  style: planText(size: 12, color: planGreen)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('How should it fit your week?',
                        style: planText(
                            size: 13, color: planMuted, weight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _modeOption(PlanScheduleMode.consecutive, 'Day by day',
                            'Day 1 on the start date, day 2 the next day'),
                        const SizedBox(width: 10),
                        _modeOption(PlanScheduleMode.weekdays,
                            'My training days', 'Workouts only on days you pick'),
                      ],
                    ),
                    if (_mode == PlanScheduleMode.weekdays) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: List.generate(7, (index) {
                          final weekday = index + 1;
                          final selected = _weekdays.contains(weekday);
                          return FilterChip(
                            key: ValueKey('plan-weekday-$weekday'),
                            label: Text(planWeekdays[index]),
                            selected: selected,
                            showCheckmark: false,
                            onSelected: (value) => setState(() => value
                                ? _weekdays.add(weekday)
                                : _weekdays.remove(weekday)),
                            labelStyle: planText(
                                size: 12,
                                color: selected ? planBg : Colors.white,
                                weight: FontWeight.w600),
                            backgroundColor: planCard,
                            selectedColor: planGreen,
                            side: BorderSide(
                                color: selected ? planGreen : planBorder),
                          );
                        }),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Text('Your calendar',
                        style: planText(
                            size: 13, color: planMuted, weight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...widget.plan.days.map((day) {
                      final date = dates[day.day];
                      if (day.isRest && _mode == PlanScheduleMode.weekdays) {
                        return const SizedBox.shrink();
                      }
                      final restDate = day.isRest
                          ? DateTime(_start.year, _start.month,
                              _start.day + day.day - 1)
                          : null;
                      return Container(
                        key: ValueKey('plan-preview-day-${day.day}'),
                        margin: const EdgeInsets.only(bottom: 7),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 11),
                        decoration: BoxDecoration(
                          color: planCard,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: planBorder),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 52,
                              child: Text('Day ${day.day}',
                                  style: planText(
                                      size: 11,
                                      color: day.isRest ? planMuted : planGreen,
                                      weight: FontWeight.w700)),
                            ),
                            Expanded(
                              child: Text(day.displayTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: planText(
                                      size: 13,
                                      color: day.isRest
                                          ? planMuted
                                          : Colors.white)),
                            ),
                            Text(
                                planDateLabel(date ?? restDate ?? _start),
                                style: planText(size: 11, color: planMuted)),
                          ],
                        ),
                      );
                    }),
                    if (conflicts > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        conflicts == 1
                            ? '1 of these days already has a workout. Both will show in your calendar.'
                            : '$conflicts of these days already have a workout. Both will show in your calendar.',
                        key: const ValueKey('plan-conflict-warning'),
                        style: planText(size: 11, color: planAmber),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: ElevatedButton(
                  key: const ValueKey('confirm-add-plan'),
                  onPressed: _saving || workouts == 0 ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: planGreen,
                    foregroundColor: planBg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17)),
                  ),
                  child: Text(
                      _saving
                          ? 'Adding…'
                          : workouts == 1
                              ? 'Add 1 workout to my Train'
                              : 'Add $workouts workouts to my Train',
                      style: planText(
                          size: 14, color: planBg, weight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
