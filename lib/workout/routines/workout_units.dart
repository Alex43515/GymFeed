enum WorkoutWeightUnit {
  kg,
  lb;

  static const poundsPerKilogram = 2.2046226218487757;

  double fromKg(double kilograms) =>
      this == kg ? kilograms : kilograms * poundsPerKilogram;
  double toKg(double value) => this == kg ? value : value / poundsPerKilogram;

  String format(double kilograms) => formatWorkoutNumber(fromKg(kilograms));
}

String formatWorkoutNumber(double value) =>
    value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');

int? workoutDurationFromMinutes(String text) {
  final minutes = double.tryParse(text.trim());
  if (minutes == null || !minutes.isFinite || minutes <= 0 || minutes > 1440)
    return null;
  final seconds = (minutes * 60).round();
  return seconds > 0 ? seconds : null;
}

String workoutMinutesLabel(int seconds) =>
    '${formatWorkoutNumber(seconds / 60)} min';
