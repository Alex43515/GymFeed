import 'package:flutter/material.dart';

import '/backend/supabase/repositories/training_plan_repository.dart';
import '/workout/routines/workout_routine_flow.dart';
import '/workout/routines/workout_routine_models.dart';

import 'training_plan_models.dart';
import 'training_plan_ui.dart';

/// Creates or edits a plan: details, then a list of 1-31 days where each day is
/// a workout (built with the regular routine builder) or a rest day.
/// Pops `true` after the draft is saved.
class TrainingPlanBuilderWidget extends StatefulWidget {
  const TrainingPlanBuilderWidget({super.key, this.plan, this.repository});

  final TrainingPlan? plan;
  final TrainingPlanRepository? repository;

  @override
  State<TrainingPlanBuilderWidget> createState() =>
      _TrainingPlanBuilderWidgetState();
}

class _TrainingPlanBuilderWidgetState extends State<TrainingPlanBuilderWidget> {
  late final TrainingPlanRepository _repository =
      widget.repository ?? TrainingPlanRepository();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late String _goal;
  late String _level;
  late String _equipment;
  late List<TrainingPlanDay> _days;
  bool _saving = false;

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
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

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
    if (day != null && mounted) setState(() => _days.add(day));
  }

  void _addRest() {
    if (_days.length >= trainingPlanMaxDays) return;
    setState(() => _days.add(TrainingPlanDay(day: _days.length + 1, isRest: true)));
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
    if (_title.text.trim().length < 3) return 'Give your plan a name (3+ characters).';
    if (_days.isEmpty) return 'Add at least one day.';
    if (_days.every((day) => day.isRest)) return 'Add at least one workout day.';
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    final problem = _validate();
    if (problem != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem)));
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
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not save the plan. Please try again.')));
    }
  }

  Widget _picker(String label, Map<String, String> options, String value,
      ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: planText(size: 12, color: planMuted, weight: FontWeight.w600)),
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

  Widget _dayCard(int index) {
    final day = _days[index];
    return Container(
      key: ValueKey('builder-day-${day.day}'),
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: planCard,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: planBorder),
      ),
      child: ListTile(
        onTap: day.isRest ? null : () => _editDay(index),
        leading: Text('Day ${day.day}',
            style: planText(
                size: 11,
                color: day.isRest ? planMuted : planGreen,
                weight: FontWeight.w700)),
        title: Text(day.displayTitle,
            style: planText(
                size: 14,
                color: day.isRest ? planMuted : Colors.white,
                weight: FontWeight.w600)),
        subtitle: day.isRest
            ? null
            : Text('${day.exercises.length} exercises · tap to edit',
                style: planText(size: 10, color: planMuted)),
        trailing: IconButton(
          key: ValueKey('remove-plan-day-${day.day}'),
          tooltip: 'Remove day',
          onPressed: () => _removeDay(index),
          icon: const Icon(Icons.delete_outline_rounded, color: planMuted, size: 19),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final full = _days.length >= trainingPlanMaxDays;
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
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save',
                      style: planText(
                          size: 13, color: planGreen, weight: FontWeight.w700)),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    TextField(
                      key: const ValueKey('plan-title'),
                      controller: _title,
                      maxLength: 80,
                      textCapitalization: TextCapitalization.sentences,
                      style: planText(size: 16, weight: FontWeight.w600),
                      decoration: planInput('Plan name, e.g. 4-Week Glute Builder')
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
                    _picker('Level', trainingPlanLevels, _level, (v) => _level = v),
                    _picker('Equipment', trainingPlanEquipment, _equipment,
                        (v) => _equipment = v),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Days',
                              style: planText(
                                  size: 14, weight: FontWeight.w700)),
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
                    const SizedBox(height: 6),
                    if (_days.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
