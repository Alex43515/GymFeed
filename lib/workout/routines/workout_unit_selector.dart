import 'package:flutter/material.dart';
import 'workout_routine_store.dart';
import 'workout_units.dart';

/// Keeps canonical kilograms when an unchanged displayed number is saved or
/// converted repeatedly, instead of accumulating display-rounding error.
class WorkoutWeightController extends TextEditingController {
  WorkoutWeightController(double kilograms, this.unit)
      : _kilograms = kilograms,
        _rendered = unit.format(kilograms),
        super(text: unit.format(kilograms));

  WorkoutWeightUnit unit;
  double _kilograms;
  String? _rendered;

  double? get kilograms {
    if (text == _rendered) return _kilograms;
    final number = double.tryParse(text.trim());
    return number != null && number.isFinite && number >= 0
        ? unit.toKg(number)
        : null;
  }

  void changeUnit(WorkoutWeightUnit next) {
    if (unit == next) return;
    final current = kilograms;
    unit = next;
    if (current == null) {
      _rendered = null;
      return;
    }
    _kilograms = current;
    final rendered = next.format(current);
    _rendered = rendered;
    text = rendered;
  }
}

class WorkoutUnitSelector extends StatefulWidget {
  const WorkoutUnitSelector({super.key, this.onChanged});
  final ValueChanged<WorkoutWeightUnit>? onChanged;

  @override
  State<WorkoutUnitSelector> createState() => _WorkoutUnitSelectorState();
}

class _WorkoutUnitSelectorState extends State<WorkoutUnitSelector> {
  WorkoutWeightUnit _unit = WorkoutWeightUnit.lb;
  bool _ready = false;
  int _loadEpoch = 0;

  @override
  void initState() {
    super.initState();
    WorkoutRoutineStore.weightUnitChanges.addListener(_load);
    _load();
  }

  Future<void> _load() async {
    final epoch = ++_loadEpoch;
    final unit = await WorkoutRoutineStore.loadWeightUnit();
    if (!mounted || epoch != _loadEpoch) return;
    setState(() {
      _unit = unit;
      _ready = true;
    });
    widget.onChanged?.call(unit);
  }

  Future<void> _select(Set<WorkoutWeightUnit> values) async {
    final next = values.single;
    if (next == _unit) return;
    await WorkoutRoutineStore.saveWeightUnit(next);
  }

  @override
  void dispose() {
    WorkoutRoutineStore.weightUnitChanges.removeListener(_load);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'Weight unit',
        child: SegmentedButton<WorkoutWeightUnit>(
          key: const ValueKey('workout-weight-unit'),
          segments: const [
            ButtonSegment(value: WorkoutWeightUnit.kg, label: Text('kg')),
            ButtonSegment(value: WorkoutWeightUnit.lb, label: Text('lb')),
          ],
          selected: {_unit},
          showSelectedIcon: false,
          onSelectionChanged: _ready ? _select : null,
          style: SegmentedButton.styleFrom(
            foregroundColor: const Color(0xFFAAAAAA),
            selectedForegroundColor: const Color(0xFF090909),
            selectedBackgroundColor: const Color(0xFF1FE276),
            textStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600),
            padding: const EdgeInsets.symmetric(horizontal: 9),
            minimumSize: const Size(36, 32),
            visualDensity: VisualDensity.compact,
          ),
        ),
      );
}
