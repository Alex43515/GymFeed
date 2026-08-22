import 'dart:math' as math;

import 'package:flutter/material.dart';

import '/backend/supabase/repositories/meal_repository.dart';
import '/backend/supabase/repositories/starter_plan_repository.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'planned_meal_detail_widget.dart';

const _diaryBg = Color(0xFF090909);
const _diarySurface = Color(0xFF151515);
const _diaryBorder = Color(0xFF292929);
const _diaryMuted = Color(0xFF8A8A8A);
const _diaryGreen = Color(0xFF1FE276);
const _proteinColor = Color(0xFF2BE782);
const _carbColor = Color(0xFF4B9DFF);
const _fatColor = Color(0xFFFFBE4D);

TextStyle _diaryText({
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

class NutritionDiaryWidget extends StatefulWidget {
  const NutritionDiaryWidget({
    super.key,
    this.initialDate,
    this.dayLoader,
    this.goalSaver,
    this.mealDeleter,
    this.plannedMealLogger,
    this.scannerOpener,
  });

  static String routeName = 'nutritionDiary';
  static String routePath = 'nutritionDiary';

  final DateTime? initialDate;
  final Future<NutritionDay> Function(DateTime date)? dayLoader;
  final Future<void> Function(NutritionGoals goals)? goalSaver;
  final Future<void> Function(String mealId)? mealDeleter;
  final Future<void> Function(StarterPlannedMeal meal, DateTime date)?
      plannedMealLogger;
  final Future<void> Function(BuildContext context, DateTime date)?
      scannerOpener;

  @override
  State<NutritionDiaryWidget> createState() => _NutritionDiaryWidgetState();
}

class _NutritionDiaryWidgetState extends State<NutritionDiaryWidget> {
  final _repository = MealRepository();
  late DateTime _selectedDate;
  NutritionDay? _day;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final date = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(date.year, date.month, date.day);
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final day =
          await (widget.dayLoader ?? _repository.loadDay)(_selectedDate);
      if (!mounted) return;
      setState(() {
        _day = day;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Your nutrition diary could not be loaded.';
      });
    }
  }

  Future<void> _moveDate(int days) async {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: days)));
    await _load();
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
            primary: _diaryGreen,
            onPrimary: Colors.black,
            surface: _diarySurface,
            onSurface: Colors.white,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: _diarySurface),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
    await _load();
  }

  Future<void> _openScanner() async {
    if (widget.scannerOpener != null) {
      await widget.scannerOpener!(context, _selectedDate);
    } else {
      await context.pushNamed(
        'coachFoodScanner',
        queryParameters: {
          'logDate': serializeParam(
            DateFormat('yyyy-MM-dd').format(_selectedDate),
            ParamType.String,
          ),
        }.withoutNulls,
      );
    }
    await _load();
  }

  Future<void> _editGoals() async {
    final current = _day?.goals ?? const NutritionGoals();
    final calories = TextEditingController(text: '${current.calories}');
    final protein = TextEditingController(text: '${current.proteinG}');
    final carbs = TextEditingController(text: '${current.carbsG}');
    final fat = TextEditingController(text: '${current.fatG}');
    final updated = await showModalBottomSheet<NutritionGoals>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: _GoalSheet(
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
        ),
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      calories.dispose();
      protein.dispose();
      carbs.dispose();
      fat.dispose();
    });
    if (updated == null) return;
    try {
      await (widget.goalSaver ?? _repository.saveGoals)(updated);
      if (!mounted) return;
      setState(() {
        final existing = _day;
        if (existing != null) {
          _day = NutritionDay(
            meals: existing.meals,
            goals: updated,
            plannedMeals: existing.plannedMeals,
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily nutrition goal updated.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update your daily goal.')),
      );
    }
  }

  Future<void> _deleteMeal(MealScan meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _diarySurface,
        title: Text('Remove meal?',
            style: _diaryText(size: 18, weight: FontWeight.w700)),
        content: Text(
          '${meal.foodName} will be removed from this day.',
          style: _diaryText(color: _diaryMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child:
                const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await (widget.mealDeleter ?? _repository.delete)(meal.id);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove this meal.')),
      );
    }
  }

  Future<void> _logPlannedMeal(StarterPlannedMeal meal) async {
    final existing = _day?.meals.any(
          (logged) => logged.starterPlanMealId == meal.id,
        ) ??
        false;
    if (existing) return;
    try {
      if (widget.plannedMealLogger != null) {
        await widget.plannedMealLogger!(meal, _selectedDate);
      } else {
        await _repository.logPlannedMeal(meal, _selectedDate);
      }
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${meal.name} added to today\'s totals.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not log this planned meal.')),
      );
    }
  }

  Future<void> _openPlannedMeal(StarterPlannedMeal meal) async {
    final logged = _day?.meals.any(
          (entry) => entry.starterPlanMealId == meal.id,
        ) ??
        false;
    final shouldLog = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PlannedMealDetailWidget(
          meal: meal,
          planDate: _selectedDate,
          logged: logged,
        ),
      ),
    );
    if (shouldLog == true && !logged) {
      await _logPlannedMeal(meal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: media.textScaler.clamp(maxScaleFactor: 1.25),
      ),
      child: Scaffold(
        backgroundColor: _diaryBg,
        body: SafeArea(
          child: Column(
            children: [
              _DiaryHeader(onBack: () => context.safePop()),
              _DateSelector(
                date: _selectedDate,
                onPrevious: () => _moveDate(-1),
                onNext: () => _moveDate(1),
                onPick: _pickDate,
              ),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading && _day == null) {
      return const Center(
        child: CircularProgressIndicator(color: _diaryGreen),
      );
    }
    if (_error != null && _day == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, color: _diaryMuted, size: 42),
              const SizedBox(height: 14),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: _diaryText(color: _diaryMuted)),
              const SizedBox(height: 14),
              TextButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    final day = _day ??
        const NutritionDay(meals: <MealScan>[], goals: NutritionGoals());
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    return RefreshIndicator(
      color: _diaryGreen,
      backgroundColor: _diarySurface,
      onRefresh: _load,
      child: ListView(
        key: const ValueKey('nutrition-diary-list'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _CalorieCard(day: day, onEdit: _editGoals),
          const SizedBox(height: 14),
          _MacroCard(day: day),
          const SizedBox(height: 20),
          if (day.plannedMeals.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    isToday
                        ? "Today's meal plan"
                        : '${DateFormat('EEEE').format(_selectedDate)} meal plan',
                    style: _diaryText(size: 16, weight: FontWeight.w700),
                  ),
                ),
                Text('AI plan',
                    style: _diaryText(
                        size: 10, color: _diaryGreen, weight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            for (final planned in day.plannedMeals) ...[
              _PlannedMealCard(
                meal: planned,
                logged: day.meals
                    .any((meal) => meal.starterPlanMealId == planned.id),
                onOpen: () => _openPlannedMeal(planned),
                onLog: () => _logPlannedMeal(planned),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 10),
          ],
          Text(
              isToday
                  ? "Today's meals"
                  : '${DateFormat('EEEE').format(_selectedDate)} meals',
              style: _diaryText(size: 16, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (day.meals.isEmpty) _EmptyMeals(onScan: _openScanner),
          for (final meal in day.meals) ...[
            _MealCard(meal: meal, onDelete: () => _deleteMeal(meal)),
            const SizedBox(height: 10),
          ],
          if (day.meals.isNotEmpty) _ScanMealButton(onPressed: _openScanner),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _DiaryHeader extends StatelessWidget {
  const _DiaryHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 58,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                key: const ValueKey('nutrition-diary-back'),
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 21),
              ),
            ),
            Text('Nutrition diary',
                style: _diaryText(size: 17, weight: FontWeight.w700)),
          ],
        ),
      );
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.date,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Row(
          children: [
            IconButton(
              key: const ValueKey('nutrition-previous-day'),
              tooltip: 'Previous day',
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded, color: _diaryMuted),
            ),
            Expanded(
              child: TextButton.icon(
                key: const ValueKey('nutrition-pick-date'),
                onPressed: onPick,
                icon: const Icon(Icons.calendar_today_rounded,
                    color: _diaryGreen, size: 15),
                label: Text(
                  DateFormat('EEEE, MMMM d').format(date),
                  overflow: TextOverflow.ellipsis,
                  style: _diaryText(size: 12, color: _diaryMuted),
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('nutrition-next-day'),
              tooltip: 'Next day',
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded, color: _diaryMuted),
            ),
          ],
        ),
      );
}

class _CalorieCard extends StatelessWidget {
  const _CalorieCard({required this.day, required this.onEdit});

  final NutritionDay day;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final eaten = day.calories.round();
    final remaining = day.goals.calories - eaten;
    final progress = day.goals.calories <= 0 ? 0.0 : eaten / day.goals.calories;
    return InkWell(
      key: const ValueKey('edit-nutrition-goals'),
      onTap: onEdit,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _diarySurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _diaryBorder),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(
                painter: _CalorieRingPainter(progress),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$eaten',
                          style: _diaryText(
                              size: 22, weight: FontWeight.w700, height: 1)),
                      Text('kcal',
                          style: _diaryText(size: 9, color: _diaryMuted)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Daily goal',
                            style: _diaryText(size: 12, color: _diaryMuted)),
                      ),
                      const Icon(Icons.edit_outlined,
                          color: _diaryMuted, size: 17),
                    ],
                  ),
                  Text('${day.goals.calories}',
                      style: _diaryText(size: 24, weight: FontWeight.w700)),
                  Text(
                    remaining >= 0
                        ? '$remaining kcal left'
                        : '${remaining.abs()} kcal over',
                    style: _diaryText(
                      size: 11,
                      color: remaining >= 0 ? _diaryGreen : Colors.redAccent,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text('Tap to edit goal',
                      style: _diaryText(size: 9, color: _diaryMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalorieRingPainter extends CustomPainter {
  const _CalorieRingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - 12) / 2;
    final background = Paint()
      ..color = const Color(0xFF202020)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    final foreground = Paint()
      ..color = _diaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, background);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant _CalorieRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({required this.day});

  final NutritionDay day;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: _diarySurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _diaryBorder),
        ),
        child: Column(
          children: [
            _MacroProgress(
              label: 'Protein',
              current: day.proteinG,
              goal: day.goals.proteinG,
              color: _proteinColor,
            ),
            const SizedBox(height: 12),
            _MacroProgress(
              label: 'Carbs',
              current: day.carbsG,
              goal: day.goals.carbsG,
              color: _carbColor,
            ),
            const SizedBox(height: 12),
            _MacroProgress(
              label: 'Fat',
              current: day.fatG,
              goal: day.goals.fatG,
              color: _fatColor,
            ),
          ],
        ),
      );
}

class _MacroProgress extends StatelessWidget {
  const _MacroProgress({
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
  });

  final String label;
  final double current;
  final int goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = goal <= 0 ? 0.0 : current / goal;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: _diaryText(size: 12, weight: FontWeight.w600)),
            ),
            Text('${current.round()} / ${goal}g',
                style: _diaryText(size: 11, color: _diaryMuted)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progress.clamp(0, 1),
            backgroundColor: const Color(0xFF222222),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal, required this.onDelete});

  final MealScan meal;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
        key: ValueKey('nutrition-meal-${meal.id}'),
        decoration: BoxDecoration(
          color: _diarySurface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: _diaryBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 76,
              child: meal.photoUrl == null
                  ? const ColoredBox(
                      color: Color(0xFF101C15),
                      child: Icon(Icons.restaurant_rounded,
                          color: _diaryGreen, size: 24),
                    )
                  : Image.network(
                      meal.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFF101C15),
                        child: Icon(Icons.restaurant_rounded,
                            color: _diaryGreen, size: 24),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.foodName.isEmpty ? 'Scanned meal' : meal.foodName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _diaryText(size: 13, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    '${meal.mealType} · ${DateFormat('HH:mm').format(meal.scannedAt ?? DateTime.now())}',
                    style: _diaryText(size: 10, color: _diaryMuted),
                  ),
                  Text(
                    'P ${meal.proteinG.round()} · C ${meal.carbsG.round()} · F ${meal.fatG.round()}',
                    style: _diaryText(size: 9, color: _diaryMuted),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${meal.calories.round()}',
                    style: _diaryText(
                        size: 17, color: _diaryGreen, weight: FontWeight.w700)),
                Text('kcal', style: _diaryText(size: 9, color: _diaryMuted)),
              ],
            ),
            PopupMenuButton<String>(
              key: ValueKey('nutrition-meal-menu-${meal.id}'),
              icon: const Icon(Icons.more_vert_rounded,
                  color: _diaryMuted, size: 20),
              color: _diarySurface,
              onSelected: (value) {
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Remove meal',
                      style: _diaryText(color: Colors.redAccent)),
                ),
              ],
            ),
          ],
        ),
      );
}

class _PlannedMealCard extends StatelessWidget {
  const _PlannedMealCard({
    required this.meal,
    required this.logged,
    required this.onOpen,
    required this.onLog,
  });

  final StarterPlannedMeal meal;
  final bool logged;
  final VoidCallback onOpen;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) => Material(
        key: ValueKey('planned-meal-${meal.id}'),
        color: const Color(0xFF101C15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: const BorderSide(color: Color(0xFF155B34)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('open-planned-meal-${meal.id}'),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF123821),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.restaurant_menu_rounded,
                      color: _diaryGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _diaryText(size: 13, weight: FontWeight.w700)),
                      Text(
                        '${meal.mealType} · ${meal.calories} kcal',
                        style: _diaryText(size: 10, color: _diaryMuted),
                      ),
                      Text(
                        'P ${meal.proteinG} · C ${meal.carbsG} · F ${meal.fatG}',
                        style: _diaryText(size: 9, color: _diaryMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  key: ValueKey('log-planned-meal-${meal.id}'),
                  onPressed: logged ? null : onLog,
                  style: TextButton.styleFrom(
                    backgroundColor:
                        logged ? const Color(0xFF242424) : _diaryGreen,
                    foregroundColor: logged ? _diaryMuted : Colors.black,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                  ),
                  child: Text(logged ? 'Logged' : 'Log',
                      style: _diaryText(
                          size: 10,
                          color: logged ? _diaryMuted : Colors.black,
                          weight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      );
}

class _EmptyMeals extends StatelessWidget {
  const _EmptyMeals({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
        decoration: BoxDecoration(
          color: _diarySurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _diaryBorder),
        ),
        child: Column(
          children: [
            const Icon(Icons.restaurant_menu_rounded,
                color: _diaryMuted, size: 34),
            const SizedBox(height: 10),
            Text('No meals logged',
                style: _diaryText(size: 15, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Scan your first meal to start today’s progress.',
                textAlign: TextAlign.center,
                style: _diaryText(size: 11, color: _diaryMuted)),
            const SizedBox(height: 16),
            _ScanMealButton(onPressed: onScan),
          ],
        ),
      );
}

class _ScanMealButton extends StatelessWidget {
  const _ScanMealButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        key: const ValueKey('nutrition-scan-meal'),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: _diaryBorder),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.photo_camera_outlined,
            color: _diaryGreen, size: 18),
        label: Text('Scan a meal',
            style: _diaryText(color: _diaryGreen, weight: FontWeight.w700)),
      );
}

class _GoalSheet extends StatelessWidget {
  const _GoalSheet({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final TextEditingController calories;
  final TextEditingController protein;
  final TextEditingController carbs;
  final TextEditingController fat;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        decoration: const BoxDecoration(
          color: _diarySurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A5A5A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Daily nutrition goal',
                    style: _diaryText(size: 20, weight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text('Set the targets used by your daily progress bars.',
                    style: _diaryText(size: 11, color: _diaryMuted)),
                const SizedBox(height: 18),
                _GoalField(
                  key: const ValueKey('nutrition-goal-calories'),
                  controller: calories,
                  label: 'Calories',
                  suffix: 'kcal',
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: _GoalField(
                        controller: protein,
                        label: 'Protein',
                        suffix: 'g',
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _GoalField(
                        controller: carbs,
                        label: 'Carbs',
                        suffix: 'g',
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _GoalField(
                        controller: fat,
                        label: 'Fat',
                        suffix: 'g',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const ValueKey('save-nutrition-goals'),
                  onPressed: () {
                    final result = NutritionGoals(
                      calories: (int.tryParse(calories.text) ?? 2200)
                          .clamp(800, 10000),
                      proteinG:
                          (int.tryParse(protein.text) ?? 165).clamp(1, 1000),
                      carbsG: (int.tryParse(carbs.text) ?? 250).clamp(1, 1500),
                      fatG: (int.tryParse(fat.text) ?? 70).clamp(1, 500),
                    );
                    Navigator.pop(context, result);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: _diaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Save goals',
                      style: _diaryText(
                          color: Colors.black, weight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      );
}

class _GoalField extends StatelessWidget {
  const _GoalField({
    super.key,
    required this.controller,
    required this.label,
    required this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: _diaryText(weight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: _diaryText(size: 11, color: _diaryMuted),
          suffixText: suffix,
          suffixStyle: _diaryText(size: 10, color: _diaryMuted),
          filled: true,
          fillColor: const Color(0xFF111111),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _diaryBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _diaryGreen),
          ),
        ),
      );
}
