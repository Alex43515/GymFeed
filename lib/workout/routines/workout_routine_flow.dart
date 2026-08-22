import 'dart:async';

import 'package:flutter/material.dart';

import '/components/send_post/send_post_widget.dart';

import 'workout_routine_models.dart';
import 'workout_routine_store.dart';

const _routineBg = Color(0xFF090909);
const _routineSurface = Color(0xFF151515);
const _routineBorder = Color(0xFF292929);
const _routineMuted = Color(0xFF8B8B8B);
const _routineGreen = Color(0xFF1FE276);

const workoutExerciseLibrary = [
  'Bench Press',
  'Squat',
  'Deadlift',
  'Overhead Press',
  'Pull Up',
  'Barbell Row',
  'Incline DB Press',
  'Lat Pulldown',
  'Leg Press',
  'Bicep Curl',
  'Triceps Pushdown',
  'Lateral Raise',
];

TextStyle _routineText({
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

String workoutDurationLabel(int seconds) {
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  return '$minutes:${remaining.toString().padLeft(2, '0')}';
}

Future<String?> showWorkoutExerciseLibrary(
  BuildContext context, {
  Iterable<String> excluded = const [],
}) async {
  final excludedSet = excluded.toSet();
  final customController = TextEditingController();
  try {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        void submitCustomExercise() {
          final name = customController.text.trim();
          if (name.isEmpty) return;
          if (excludedSet.any(
              (exercise) => exercise.toLowerCase() == name.toLowerCase())) {
            ScaffoldMessenger.of(sheetContext).showSnackBar(
              const SnackBar(content: Text('That exercise is already added.')),
            );
            return;
          }
          Navigator.pop(sheetContext, name);
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.5,
          maxChildSize: 0.94,
          builder: (context, controller) => Container(
            decoration: const BoxDecoration(
              color: _routineSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: _routineBorder)),
            ),
            child: Column(
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
                        child: Text('Add exercise',
                            style: _routineText(
                                size: 20, weight: FontWeight.w700)),
                      ),
                      IconButton(
                        tooltip: 'Close exercise library',
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    key: const ValueKey('custom-exercise-name'),
                    controller: customController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => submitCustomExercise(),
                    style: _routineText(size: 14, weight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Enter a custom exercise',
                      hintStyle: _routineText(size: 13, color: _routineMuted),
                      filled: true,
                      fillColor: const Color(0xFF101010),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: _routineBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: _routineGreen),
                      ),
                      suffixIcon: IconButton(
                        key: const ValueKey('add-custom-exercise'),
                        tooltip: 'Add custom exercise',
                        onPressed: submitCustomExercise,
                        icon: const Icon(Icons.add_circle_rounded,
                            color: _routineGreen),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    itemCount: workoutExerciseLibrary.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final name = workoutExerciseLibrary[index];
                      final selected = excludedSet.contains(name);
                      return Material(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          key: ValueKey('exercise-library-$name'),
                          onTap: selected
                              ? null
                              : () => Navigator.pop(sheetContext, name),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _routineBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF123821),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                      Icons.fitness_center_rounded,
                                      color: _routineGreen,
                                      size: 18),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Text(name,
                                      style: _routineText(
                                          size: 14,
                                          color: selected
                                              ? _routineMuted
                                              : Colors.white,
                                          weight: FontWeight.w600)),
                                ),
                                Text(selected ? 'Added' : '+',
                                    style: _routineText(
                                        size: selected ? 11 : 24,
                                        color: selected
                                            ? _routineMuted
                                            : _routineGreen,
                                        weight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  } finally {
    // A modal route completes its future before the closing animation has
    // stopped building. Dispose after that transition releases the field.
    unawaited(Future<void>.delayed(
      const Duration(milliseconds: 500),
      customController.dispose,
    ));
  }
}

class _RoutineSetDraft {
  _RoutineSetDraft(RoutineSetTarget target)
      : weightController = TextEditingController(
            text: target.weightKg == 0
                ? '0'
                : target.weightKg
                    .toStringAsFixed(target.weightKg % 1 == 0 ? 0 : 1)),
        repsController = TextEditingController(text: '${target.reps}');

  final TextEditingController weightController;
  final TextEditingController repsController;

  RoutineSetTarget? toTarget() {
    final weight = double.tryParse(weightController.text.trim());
    final reps = int.tryParse(repsController.text.trim());
    if (weight == null || weight < 0 || reps == null || reps <= 0) return null;
    return RoutineSetTarget(weightKg: weight, reps: reps);
  }

  void dispose() {
    weightController.dispose();
    repsController.dispose();
  }
}

class RoutineSetEditorWidget extends StatefulWidget {
  const RoutineSetEditorWidget({
    super.key,
    required this.exerciseName,
    required this.initialSets,
  });

  final String exerciseName;
  final List<RoutineSetTarget> initialSets;

  @override
  State<RoutineSetEditorWidget> createState() => _RoutineSetEditorWidgetState();
}

class _RoutineSetEditorWidgetState extends State<RoutineSetEditorWidget> {
  late final List<_RoutineSetDraft> _sets;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSets.isEmpty
        ? const [RoutineSetTarget(weightKg: 0, reps: 10)]
        : widget.initialSets;
    _sets = initial.map(_RoutineSetDraft.new).toList();
  }

  @override
  void dispose() {
    for (final set in _sets) {
      set.dispose();
    }
    super.dispose();
  }

  void _addSet() {
    if (_sets.length >= 10) return;
    final previous =
        _sets.last.toTarget() ?? const RoutineSetTarget(weightKg: 0, reps: 10);
    setState(() => _sets.add(_RoutineSetDraft(previous)));
  }

  void _removeSet(int index) {
    if (_sets.length <= 1) return;
    final removed = _sets.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  void _save() {
    final targets = _sets.map((set) => set.toTarget()).toList();
    if (targets.any((target) => target == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a valid weight and at least 1 rep for every set.'),
      ));
      return;
    }
    Navigator.pop(
      context,
      targets.cast<RoutineSetTarget>(),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required Key fieldKey,
    bool decimal = false,
  }) {
    return TextField(
      key: fieldKey,
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      textAlign: TextAlign.center,
      style: _routineText(size: 15, weight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: _routineText(size: 11, color: _routineMuted),
        suffixText: suffix,
        suffixStyle: _routineText(size: 11, color: _routineMuted),
        filled: true,
        fillColor: const Color(0xFF101010),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _routineBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _routineGreen),
        ),
      ),
    );
  }

  Widget _setCard(int index) {
    final set = _sets[index];
    return Container(
      key: ValueKey('routine-set-${index + 1}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
      decoration: BoxDecoration(
        color: _routineSurface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _routineBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Set ${index + 1}',
                    style: _routineText(size: 14, weight: FontWeight.w700)),
              ),
              IconButton(
                key: ValueKey('remove-routine-set-${index + 1}'),
                tooltip: 'Remove set',
                onPressed: _sets.length <= 1 ? null : () => _removeSet(index),
                icon: const Icon(Icons.delete_outline_rounded, size: 19),
                color: _routineMuted,
                disabledColor: const Color(0xFF424242),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _field(
                  fieldKey: ValueKey('routine-set-weight-${index + 1}'),
                  controller: set.weightController,
                  label: 'Weight',
                  suffix: 'kg',
                  decimal: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  fieldKey: ValueKey('routine-set-reps-${index + 1}'),
                  controller: set.repsController,
                  label: 'Reps',
                  suffix: 'reps',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
          textScaler: media.textScaler.clamp(maxScaleFactor: 1.3)),
      child: Scaffold(
        backgroundColor: _routineBg,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 62,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(widget.exerciseName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _routineText(
                                  size: 16, weight: FontWeight.w700)),
                          Text('Set targets',
                              style:
                                  _routineText(size: 10, color: _routineMuted)),
                        ],
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('save-routine-sets'),
                      onPressed: _save,
                      child: Text('Done',
                          style: _routineText(
                              size: 13,
                              color: _routineGreen,
                              weight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    Text(
                      'Set the target weight and repetitions. These values will be ready when you start the workout.',
                      style: _routineText(size: 12, color: _routineMuted),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_sets.length, _setCard),
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      key: const ValueKey('add-routine-set'),
                      onPressed: _sets.length >= 10 ? null : _addSet,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: _routineBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.add_rounded,
                          color: _routineGreen, size: 20),
                      label: Text('Add set',
                          style: _routineText(
                              size: 13,
                              color: _routineGreen,
                              weight: FontWeight.w700)),
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

class RoutineBuilderWidget extends StatefulWidget {
  const RoutineBuilderWidget({
    super.key,
    this.routine,
    this.initialExerciseName,
  });

  final WorkoutRoutine? routine;
  final String? initialExerciseName;

  @override
  State<RoutineBuilderWidget> createState() => _RoutineBuilderWidgetState();
}

class _RoutineBuilderWidgetState extends State<RoutineBuilderWidget> {
  late final TextEditingController _nameController;
  late final List<RoutineExercise> _exercises;
  bool _saving = false;

  bool get _editing => widget.routine != null;

  @override
  void initState() {
    super.initState();
    final initialExercise = widget.initialExerciseName?.trim() ?? '';
    _nameController = TextEditingController(
      text: widget.routine?.name ??
          (initialExercise.isEmpty ? '' : '$initialExercise routine'),
    );
    _exercises = List<RoutineExercise>.from(
        widget.routine?.exercises ?? const <RoutineExercise>[]);
    if (widget.routine == null && initialExercise.isNotEmpty) {
      _exercises.add(RoutineExercise(name: initialExercise));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addExercise() async {
    final selected = await showWorkoutExerciseLibrary(
      context,
      excluded: _exercises.map((item) => item.name),
    );
    if (selected == null || !mounted) return;
    setState(() => _exercises.add(RoutineExercise(name: selected)));
  }

  Future<void> _editExerciseSets(int index) async {
    final exercise = _exercises[index];
    final targets = await Navigator.of(context)
        .push<List<RoutineSetTarget>>(MaterialPageRoute(
      settings: const RouteSettings(name: 'routine-set-editor'),
      builder: (_) => RoutineSetEditorWidget(
        exerciseName: exercise.name,
        initialSets: exercise.plannedSets,
      ),
    ));
    if (targets == null || targets.isEmpty || !mounted) return;
    final first = targets.first;
    setState(() => _exercises[index] = exercise.copyWith(
          setCount: targets.length,
          defaultWeightKg: first.weightKg,
          defaultReps: first.reps,
          setTargets: List<RoutineSetTarget>.unmodifiable(targets),
        ));
  }

  void _changeSetCount(int index, int change) {
    final exercise = _exercises[index];
    final targets = List<RoutineSetTarget>.from(exercise.plannedSets);
    if (change < 0 && targets.length > 1) {
      targets.removeLast();
    } else if (change > 0 && targets.length < 10) {
      targets.add(targets.last);
    } else {
      return;
    }
    final first = targets.first;
    setState(() => _exercises[index] = exercise.copyWith(
          setCount: targets.length,
          defaultWeightKg: first.weightKg,
          defaultReps: first.reps,
          setTargets: List<RoutineSetTarget>.unmodifiable(targets),
        ));
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty || _exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(name.isEmpty
            ? 'Give your routine a name.'
            : 'Add at least one exercise.'),
      ));
      return;
    }
    setState(() => _saving = true);
    final existing = widget.routine;
    final routine = WorkoutRoutine(
      id: existing?.id ??
          'routine-${DateTime.now().microsecondsSinceEpoch.toString()}',
      name: name,
      category: existing?.category ?? 'Custom',
      exercises: List.unmodifiable(_exercises),
      createdAt: existing?.createdAt ?? DateTime.now(),
      lastPerformedAt: existing?.lastPerformedAt,
    );
    await WorkoutRoutineStore.saveRoutine(routine);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Widget _exerciseCard(int index) {
    final exercise = _exercises[index];
    return Padding(
      key: ValueKey('routine-exercise-${exercise.name}'),
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _routineSurface,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          key: ValueKey('edit-routine-sets-${exercise.name}'),
          onTap: () => _editExerciseSets(index),
          borderRadius: BorderRadius.circular(17),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: _routineBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF121B15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _routineBorder),
                  ),
                  child: const Icon(Icons.fitness_center_rounded,
                      color: _routineGreen, size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.name,
                          style:
                              _routineText(size: 14, weight: FontWeight.w700)),
                      Text('${exercise.setCount} sets · Tap to edit kg & reps',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _routineText(size: 10, color: _routineMuted)),
                    ],
                  ),
                ),
                IconButton(
                  key: ValueKey('decrease-sets-${exercise.name}'),
                  tooltip: 'Decrease sets',
                  constraints:
                      const BoxConstraints.tightFor(width: 32, height: 32),
                  padding: EdgeInsets.zero,
                  onPressed: exercise.setCount <= 1
                      ? null
                      : () => _changeSetCount(index, -1),
                  icon: const Icon(Icons.remove_rounded, size: 18),
                  color: Colors.white,
                  disabledColor: const Color(0xFF4A4A4A),
                ),
                Container(
                  width: 30,
                  alignment: Alignment.center,
                  child: Text('${exercise.setCount}',
                      style: _routineText(size: 13, weight: FontWeight.w700)),
                ),
                IconButton(
                  key: ValueKey('increase-sets-${exercise.name}'),
                  tooltip: 'Increase sets',
                  constraints:
                      const BoxConstraints.tightFor(width: 32, height: 32),
                  padding: EdgeInsets.zero,
                  onPressed: exercise.setCount >= 10
                      ? null
                      : () => _changeSetCount(index, 1),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  color: _routineGreen,
                ),
                IconButton(
                  key: ValueKey('remove-exercise-${exercise.name}'),
                  tooltip: 'Remove exercise',
                  constraints:
                      const BoxConstraints.tightFor(width: 32, height: 32),
                  padding: EdgeInsets.zero,
                  onPressed: () => setState(() => _exercises.removeAt(index)),
                  icon: const Icon(Icons.delete_outline_rounded, size: 19),
                  color: _routineMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
          textScaler: media.textScaler.clamp(maxScaleFactor: 1.3)),
      child: Scaffold(
        backgroundColor: _routineBg,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 62,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Close',
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 25),
                    ),
                    Expanded(
                      child: Text(_editing ? 'Edit routine' : 'New routine',
                          textAlign: TextAlign.center,
                          style:
                              _routineText(size: 17, weight: FontWeight.w700)),
                    ),
                    TextButton(
                      key: const ValueKey('save-routine'),
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving…' : 'Save',
                          style: _routineText(
                              size: 13,
                              color: _routineGreen,
                              weight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                  children: [
                    TextField(
                      key: const ValueKey('routine-name'),
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: _routineText(size: 16, weight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Routine name',
                        hintStyle: _routineText(size: 15, color: _routineMuted),
                        filled: true,
                        fillColor: _routineSurface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _routineBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _routineBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _routineGreen),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text('Exercises',
                        style: _routineText(
                            size: 14,
                            color: _routineMuted,
                            weight: FontWeight.w600)),
                    const SizedBox(height: 11),
                    if (_exercises.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25, vertical: 35),
                        decoration: BoxDecoration(
                          color: _routineSurface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _routineBorder),
                        ),
                        child: Text(
                          'No exercises yet. Add them from the library to build your routine.',
                          textAlign: TextAlign.center,
                          style: _routineText(size: 12, color: _routineMuted),
                        ),
                      )
                    else
                      ...List.generate(
                          _exercises.length, (index) => _exerciseCard(index)),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const ValueKey('add-routine-exercise'),
                      onPressed: _addExercise,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        side: const BorderSide(color: _routineBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17)),
                      ),
                      icon: const Icon(Icons.add_rounded,
                          color: _routineGreen, size: 20),
                      label: Text('Add exercise',
                          style: _routineText(
                              size: 13,
                              color: _routineGreen,
                              weight: FontWeight.w700)),
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

class RoutineDetailWidget extends StatefulWidget {
  const RoutineDetailWidget({super.key, required this.routine});

  final WorkoutRoutine routine;

  @override
  State<RoutineDetailWidget> createState() => _RoutineDetailWidgetState();
}

class _RoutineDetailWidgetState extends State<RoutineDetailWidget> {
  late WorkoutRoutine _routine;
  bool _routineChanged = false;

  @override
  void initState() {
    super.initState();
    _routine = widget.routine;
  }

  Future<void> _editExerciseSets(int index) async {
    final exercise = _routine.exercises[index];
    final targets = await Navigator.of(context)
        .push<List<RoutineSetTarget>>(MaterialPageRoute(
      settings: const RouteSettings(name: 'routine-detail-set-editor'),
      builder: (_) => RoutineSetEditorWidget(
        exerciseName: exercise.name,
        initialSets: exercise.plannedSets,
      ),
    ));
    if (targets == null || targets.isEmpty || !mounted) return;

    final exercises = List<RoutineExercise>.from(_routine.exercises);
    final first = targets.first;
    exercises[index] = exercise.copyWith(
      setCount: targets.length,
      defaultWeightKg: first.weightKg,
      defaultReps: first.reps,
      setTargets: List<RoutineSetTarget>.unmodifiable(targets),
    );
    final updated = _routine.copyWith(
        exercises: List<RoutineExercise>.unmodifiable(exercises));
    await WorkoutRoutineStore.saveRoutine(updated);
    if (!mounted) return;
    setState(() {
      _routine = updated;
      _routineChanged = true;
    });
  }

  Future<void> _startWorkout(BuildContext context) async {
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'active-workout'),
        builder: (_) => ActiveWorkoutWidget(routine: _routine),
      ),
    );
    if (completed == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _shareWorkout(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SendPostWidget(workout: _routine.toJson()),
      );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
          textScaler: media.textScaler.clamp(maxScaleFactor: 1.3)),
      child: Scaffold(
        backgroundColor: _routineBg,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 62,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Back',
                        onPressed: () =>
                            Navigator.pop(context, _routineChanged),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 21),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: 'Share workout',
                        onPressed: () => _shareWorkout(context),
                        icon: const Icon(Icons.ios_share_rounded,
                            color: Colors.white, size: 21),
                      ),
                    ),
                    Text('Routine',
                        style: _routineText(size: 16, weight: FontWeight.w700)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    Text(_routine.name,
                        style: _routineText(
                            size: 25, weight: FontWeight.w700, height: 1.15)),
                    const SizedBox(height: 4),
                    Text(_routine.category,
                        style: _routineText(
                            size: 12,
                            color: _routineGreen,
                            weight: FontWeight.w600)),
                    const SizedBox(height: 25),
                    Text('Exercises',
                        style: _routineText(
                            size: 13,
                            color: _routineMuted,
                            weight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    ...List.generate(_routine.exercises.length, (index) {
                      final exercise = _routine.exercises[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: _routineSurface,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            key: ValueKey('edit-detail-sets-${exercise.name}'),
                            onTap: () => _editExerciseSets(index),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: _routineBorder),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 43,
                                    height: 43,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF121B15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _routineBorder),
                                    ),
                                    child: const Icon(
                                        Icons.fitness_center_rounded,
                                        color: _routineGreen,
                                        size: 17),
                                  ),
                                  const SizedBox(width: 13),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(exercise.name,
                                            style: _routineText(
                                                size: 14,
                                                weight: FontWeight.w700)),
                                        Text(
                                            '${exercise.setCount} sets - Tap to edit kg & reps',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: _routineText(
                                                size: 10,
                                                color: _routineMuted)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right_rounded,
                                      color: _routineMuted, size: 21),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                decoration: const BoxDecoration(
                  color: _routineBg,
                  border: Border(top: BorderSide(color: _routineBorder)),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      key: const ValueKey('start-routine-workout'),
                      onPressed: () => _startWorkout(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: _routineGreen,
                        foregroundColor: _routineBg,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: Text('Start workout',
                          style: _routineText(
                              size: 14,
                              color: _routineBg,
                              weight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditableSet {
  _EditableSet({required double weight, required int reps})
      : weightController = TextEditingController(
            text: weight == 0
                ? '0'
                : weight.toStringAsFixed(weight % 1 == 0 ? 0 : 1)),
        repsController = TextEditingController(text: '$reps');

  final TextEditingController weightController;
  final TextEditingController repsController;
  bool completed = false;

  void dispose() {
    weightController.dispose();
    repsController.dispose();
  }
}

class _ActiveExercise {
  _ActiveExercise(this.exercise)
      : sets = exercise.plannedSets
            .map((target) =>
                _EditableSet(weight: target.weightKg, reps: target.reps))
            .toList();

  final RoutineExercise exercise;
  final List<_EditableSet> sets;

  void dispose() {
    for (final set in sets) {
      set.dispose();
    }
  }
}

class ActiveWorkoutWidget extends StatefulWidget {
  const ActiveWorkoutWidget({super.key, required this.routine});

  final WorkoutRoutine routine;

  @override
  State<ActiveWorkoutWidget> createState() => _ActiveWorkoutWidgetState();
}

class _ActiveWorkoutWidgetState extends State<ActiveWorkoutWidget> {
  late final DateTime _startedAt;
  late final List<_ActiveExercise> _exercises;
  Timer? _elapsedTimer;
  Timer? _restTimer;
  int _elapsedSeconds = 0;
  int _restSeconds = 0;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _exercises = widget.routine.exercises
        .map((exercise) => _ActiveExercise(exercise))
        .toList();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds += 1);
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    for (final exercise in _exercises) {
      exercise.dispose();
    }
    super.dispose();
  }

  void _startRest() {
    _restTimer?.cancel();
    setState(() => _restSeconds = 90);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_restSeconds <= 1) {
        timer.cancel();
        setState(() => _restSeconds = 0);
      } else {
        setState(() => _restSeconds -= 1);
      }
    });
  }

  void _toggleSet(_EditableSet set) {
    setState(() => set.completed = !set.completed);
    if (set.completed) _startRest();
  }

  void _removeSet(_ActiveExercise exercise, int index) {
    if (exercise.sets.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An exercise needs at least one set.')),
      );
      return;
    }
    final removed = exercise.sets.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _discard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _routineSurface,
        title: Text('Discard workout?',
            style: _routineText(size: 18, weight: FontWeight.w700)),
        content: Text('Your completed sets will not be saved.',
            style: _routineText(size: 13, color: _routineMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep training'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard',
                style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context, false);
  }

  Future<void> _addExercise() async {
    final selected = await showWorkoutExerciseLibrary(
      context,
      excluded: _exercises.map((item) => item.exercise.name),
    );
    if (selected == null || !mounted) return;
    setState(() => _exercises
        .add(_ActiveExercise(RoutineExercise(name: selected, setCount: 3))));
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    final completedExercises = _exercises
        .map((exercise) => CompletedExercise(
              name: exercise.exercise.name,
              sets: exercise.sets
                  .map((set) => CompletedSet(
                        weightKg:
                            double.tryParse(set.weightController.text) ?? 0,
                        reps: int.tryParse(set.repsController.text) ?? 0,
                        completed: set.completed,
                      ))
                  .toList(),
            ))
        .toList();
    final history = WorkoutHistoryItem(
      id: 'workout-${DateTime.now().microsecondsSinceEpoch}',
      routineId: widget.routine.id,
      name: widget.routine.name,
      startedAt: _startedAt,
      durationSeconds: _elapsedSeconds,
      exercises: completedExercises,
    );
    await WorkoutRoutineStore.saveHistory(history);
    if (!mounted) return;
    final done = await Navigator.of(context).push<bool>(MaterialPageRoute(
      settings: const RouteSettings(name: 'workout-summary'),
      builder: (_) => WorkoutSummaryWidget(history: history),
    ));
    if (done == true && mounted) Navigator.pop(context, true);
    if (mounted) setState(() => _finishing = false);
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    Key? fieldKey,
  }) {
    return SizedBox(
      width: 62,
      height: 40,
      child: TextField(
        key: fieldKey,
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: _routineText(size: 13, weight: FontWeight.w700),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          filled: true,
          fillColor: const Color(0xFF111111),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _routineBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _routineBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _routineGreen),
          ),
          semanticCounterText: label,
        ),
      ),
    );
  }

  Widget _exerciseCard(_ActiveExercise activeExercise) {
    final exercise = activeExercise.exercise;
    return Container(
      key: ValueKey('active-exercise-${exercise.name}'),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 9),
      decoration: BoxDecoration(
        color: _routineSurface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _routineBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(exercise.name,
                    style: _routineText(
                        size: 14,
                        color: _routineGreen,
                        weight: FontWeight.w700)),
              ),
              Text('${activeExercise.sets.length} sets',
                  style: _routineText(size: 10, color: _routineMuted)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                  width: 34,
                  child: Text('SET',
                      style: _routineText(size: 9, color: _routineMuted))),
              Expanded(
                child: Text('PREVIOUS',
                    style: _routineText(size: 9, color: _routineMuted)),
              ),
              SizedBox(
                width: 70,
                child: Text('KG',
                    textAlign: TextAlign.center,
                    style: _routineText(size: 9, color: _routineMuted)),
              ),
              SizedBox(
                width: 70,
                child: Text('REPS',
                    textAlign: TextAlign.center,
                    style: _routineText(size: 9, color: _routineMuted)),
              ),
              const SizedBox(width: 32),
              const SizedBox(width: 38),
            ],
          ),
          const SizedBox(height: 3),
          ...activeExercise.sets.asMap().entries.map((entry) {
            final set = entry.value;
            final plannedSets = exercise.plannedSets;
            final target = entry.key < plannedSets.length
                ? plannedSets[entry.key]
                : plannedSets.last;
            final previous = target.weightKg == 0
                ? '—'
                : '${target.weightKg.toStringAsFixed(target.weightKg % 1 == 0 ? 0 : 1)}×${target.reps}';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: Text('${entry.key + 1}',
                        textAlign: TextAlign.center,
                        style: _routineText(size: 12, weight: FontWeight.w700)),
                  ),
                  Expanded(
                    child: Text(previous,
                        style: _routineText(size: 11, color: _routineMuted)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _numberField(
                      set.weightController,
                      'Weight',
                      fieldKey: ValueKey(
                          'active-set-weight-${exercise.name}-${entry.key + 1}'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _numberField(
                      set.repsController,
                      'Repetitions',
                      fieldKey: ValueKey(
                          'active-set-reps-${exercise.name}-${entry.key + 1}'),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: IconButton(
                      key: ValueKey(
                          'delete-set-${exercise.name}-${entry.key + 1}'),
                      tooltip: 'Delete set',
                      constraints:
                          const BoxConstraints.tightFor(width: 30, height: 30),
                      padding: EdgeInsets.zero,
                      onPressed: activeExercise.sets.length <= 1
                          ? null
                          : () => _removeSet(activeExercise, entry.key),
                      icon: const Icon(Icons.delete_outline_rounded, size: 17),
                      color: const Color(0xFFFF6B6B),
                      disabledColor: const Color(0xFF424242),
                    ),
                  ),
                  SizedBox(
                    width: 38,
                    child: IconButton(
                      key: ValueKey(
                          'complete-${exercise.name}-${entry.key + 1}'),
                      tooltip: set.completed ? 'Set complete' : 'Complete set',
                      padding: EdgeInsets.zero,
                      onPressed: () => _toggleSet(set),
                      icon: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: set.completed
                              ? _routineGreen
                              : const Color(0xFF171717),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                              color: set.completed
                                  ? _routineGreen
                                  : const Color(0xFF353535)),
                        ),
                        child: Icon(Icons.check_rounded,
                            size: 17,
                            color: set.completed
                                ? _routineBg
                                : const Color(0xFF4D4D4D)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 5),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: TextButton(
              key: ValueKey('add-set-${exercise.name}'),
              onPressed: () {
                final lastTarget = exercise.plannedSets.last;
                setState(() => activeExercise.sets.add(_EditableSet(
                    weight: lastTarget.weightKg, reps: lastTarget.reps)));
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF191919),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('+ Add set',
                  style: _routineText(
                      size: 11, color: Colors.white, weight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _restBar() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 12,
      child: Container(
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _routineBorder),
          boxShadow: const [
            BoxShadow(color: Color(0x99000000), blurRadius: 18)
          ],
        ),
        child: Row(
          children: [
            TextButton(
              key: const ValueKey('rest-minus-15'),
              onPressed: () => setState(() =>
                  _restSeconds = (_restSeconds - 15).clamp(0, 600).toInt()),
              child: Text('−15',
                  style: _routineText(size: 13, weight: FontWeight.w700)),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('REST',
                      style: _routineText(size: 9, color: _routineMuted)),
                  Text(workoutDurationLabel(_restSeconds),
                      style: _routineText(
                          size: 22,
                          color: _routineGreen,
                          weight: FontWeight.w700,
                          height: 1.05)),
                ],
              ),
            ),
            TextButton(
              key: const ValueKey('rest-plus-15'),
              onPressed: () => setState(() =>
                  _restSeconds = (_restSeconds + 15).clamp(0, 600).toInt()),
              child: Text('+15',
                  style: _routineText(size: 13, weight: FontWeight.w700)),
            ),
            FilledButton(
              key: const ValueKey('skip-rest'),
              onPressed: () {
                _restTimer?.cancel();
                setState(() => _restSeconds = 0);
              },
              style: FilledButton.styleFrom(
                backgroundColor: _routineGreen,
                foregroundColor: _routineBg,
                padding: const EdgeInsets.symmetric(horizontal: 17),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
              ),
              child: Text('Skip',
                  style: _routineText(
                      size: 11, color: _routineBg, weight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
          textScaler: media.textScaler.clamp(maxScaleFactor: 1.25)),
      child: Scaffold(
        backgroundColor: _routineBg,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 68,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: _routineBorder)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Discard',
                      onPressed: _discard,
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 25),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(workoutDurationLabel(_elapsedSeconds),
                              style: _routineText(
                                  size: 18,
                                  color: _routineGreen,
                                  weight: FontWeight.w700,
                                  height: 1.05)),
                          Text(widget.routine.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  _routineText(size: 10, color: _routineMuted)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 9),
                      child: FilledButton(
                        key: const ValueKey('finish-workout'),
                        onPressed: _finishing ? null : _finish,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4A30),
                          disabledBackgroundColor: const Color(0xFF1A2F22),
                          foregroundColor: _routineGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 17),
                        ),
                        child: Text(_finishing ? 'Saving…' : 'Finish',
                            style: _routineText(
                                size: 11,
                                color: _routineGreen,
                                weight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 105),
                      children: [
                        ..._exercises.map(_exerciseCard),
                        OutlinedButton.icon(
                          key: const ValueKey('active-add-exercise'),
                          onPressed: _addExercise,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: const BorderSide(color: _routineBorder),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                          ),
                          icon: const Icon(Icons.add_rounded,
                              color: _routineGreen, size: 18),
                          label: Text('Add exercise',
                              style: _routineText(
                                  size: 12,
                                  color: _routineGreen,
                                  weight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    if (_restSeconds > 0) _restBar(),
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

class WorkoutSummaryWidget extends StatelessWidget {
  const WorkoutSummaryWidget({super.key, required this.history});

  final WorkoutHistoryItem history;

  Future<void> _share(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SendPostWidget(workout: history.toJson()),
      );

  Widget _summaryMetric(String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: _routineSurface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _routineBorder),
          ),
          child: Column(
            children: [
              Text(label, style: _routineText(size: 10, color: _routineMuted)),
              const SizedBox(height: 5),
              Text(value,
                  textAlign: TextAlign.center,
                  style: _routineText(size: 19, weight: FontWeight.w700)),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
          textScaler: media.textScaler.clamp(maxScaleFactor: 1.3)),
      child: Scaffold(
        backgroundColor: _routineBg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 78,
                  height: 78,
                  decoration: const BoxDecoration(
                      color: _routineGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded,
                      color: _routineBg, size: 42),
                ),
                const SizedBox(height: 22),
                Text('Workout complete',
                    textAlign: TextAlign.center,
                    style: _routineText(size: 25, weight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text(history.name,
                    textAlign: TextAlign.center,
                    style: _routineText(size: 13, color: _routineMuted)),
                const SizedBox(height: 28),
                Row(
                  children: [
                    _summaryMetric('Duration',
                        workoutDurationLabel(history.durationSeconds)),
                    const SizedBox(width: 9),
                    _summaryMetric(
                        'Total volume', '${history.totalVolume.round()} kg'),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    _summaryMetric('Sets done', '${history.setsDone}'),
                    const SizedBox(width: 9),
                    _summaryMetric('Exercises', '${history.exercises.length}'),
                  ],
                ),
                const Spacer(flex: 2),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    key: const ValueKey('workout-summary-done'),
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: _routineGreen,
                      foregroundColor: _routineBg,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27)),
                    ),
                    child: Text('Done',
                        style: _routineText(
                            size: 14,
                            color: _routineBg,
                            weight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    key: const ValueKey('share-workout'),
                    onPressed: () => _share(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _routineBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                    ),
                    icon: const Icon(Icons.ios_share_rounded,
                        color: Colors.white, size: 18),
                    label: Text('Share workout',
                        style: _routineText(size: 13, weight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
