import 'package:flutter/material.dart';

import '/backend/supabase/repositories/starter_plan_repository.dart';
import '/flutter_flow/flutter_flow_util.dart';

const _detailBg = Color(0xFF090909);
const _detailSurface = Color(0xFF151515);
const _detailBorder = Color(0xFF292929);
const _detailMuted = Color(0xFF8A8A8A);
const _detailGreen = Color(0xFF1FE276);
const _detailProtein = Color(0xFF2BE782);
const _detailCarbs = Color(0xFF4B9DFF);
const _detailFat = Color(0xFFFFBE4D);

TextStyle _detailText({
  double size = 14,
  Color color = Colors.white,
  FontWeight weight = FontWeight.w400,
  double height = 1.35,
}) =>
    TextStyle(
      fontFamily: 'Poppins',
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
    );

class PlannedMealDetailWidget extends StatelessWidget {
  const PlannedMealDetailWidget({
    super.key,
    required this.meal,
    required this.planDate,
    required this.logged,
  });

  final StarterPlannedMeal meal;
  final DateTime planDate;
  final bool logged;

  @override
  Widget build(BuildContext context) {
    final preparation = meal.description.trim().isEmpty
        ? 'Use the ingredients and portions from your personalized meal plan. '
            'Prepare them using your preferred safe cooking method.'
        : meal.description.trim();
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: media.textScaler.clamp(maxScaleFactor: 1.25),
      ),
      child: Scaffold(
        backgroundColor: _detailBg,
        body: SafeArea(
          child: Column(
            children: [
              _Header(onBack: () => Navigator.of(context).pop(false)),
              Expanded(
                child: SingleChildScrollView(
                  key: const ValueKey('planned-meal-detail-scroll'),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF101C15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF155B34)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF123821),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.restaurant_menu_rounded,
                                color: _detailGreen,
                                size: 25,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              meal.name,
                              key: const ValueKey('planned-meal-detail-name'),
                              style: _detailText(
                                size: 23,
                                weight: FontWeight.w700,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              '${meal.mealType} · ${DateFormat('EEEE, MMMM d').format(planDate)}',
                              style: _detailText(size: 11, color: _detailMuted),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Personalized AI meal plan',
                              style: _detailText(
                                size: 10,
                                color: _detailGreen,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Nutrition',
                          style:
                              _detailText(size: 17, weight: FontWeight.w700)),
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          Expanded(
                            child: _NutritionTile(
                              label: 'Calories',
                              value: '${meal.calories}',
                              unit: 'kcal',
                              color: _detailGreen,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: _NutritionTile(
                              label: 'Protein',
                              value: '${meal.proteinG}',
                              unit: 'g',
                              color: _detailProtein,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Expanded(
                            child: _NutritionTile(
                              label: 'Carbs',
                              value: '${meal.carbsG}',
                              unit: 'g',
                              color: _detailCarbs,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: _NutritionTile(
                              label: 'Fat',
                              value: '${meal.fatG}',
                              unit: 'g',
                              color: _detailFat,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _InformationCard(
                        icon: Icons.menu_book_rounded,
                        title: 'How to prepare',
                        child: Text(
                          preparation,
                          key: const ValueKey('planned-meal-preparation'),
                          style: _detailText(
                            size: 13,
                            color: const Color(0xFFD8D8D8),
                            height: 1.55,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InformationCard(
                        icon: Icons.info_outline_rounded,
                        title: 'Plan information',
                        child: Column(
                          children: [
                            _InfoRow(label: 'Meal', value: meal.mealType),
                            const SizedBox(height: 9),
                            _InfoRow(
                              label: 'Plan day',
                              value: '${meal.dayIndex + 1} of 28',
                            ),
                            const SizedBox(height: 9),
                            _InfoRow(
                              label: 'Date',
                              value: DateFormat('MMM d, yyyy').format(planDate),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                decoration: const BoxDecoration(
                  color: _detailBg,
                  border: Border(top: BorderSide(color: _detailBorder)),
                ),
                child: SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('log-planned-meal-from-detail'),
                    onPressed:
                        logged ? null : () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: _detailGreen,
                      disabledBackgroundColor: const Color(0xFF242424),
                      foregroundColor: _detailBg,
                      disabledForegroundColor: _detailMuted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: Icon(
                      logged
                          ? Icons.check_circle_rounded
                          : Icons.add_circle_outline_rounded,
                      size: 19,
                    ),
                    label: Text(
                      logged ? 'Already logged' : 'Log this meal',
                      style: _detailText(
                        size: 14,
                        color: logged ? _detailMuted : _detailBg,
                        weight: FontWeight.w700,
                      ),
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

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

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
                key: const ValueKey('planned-meal-detail-back'),
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
            ),
            Text('Meal details',
                style: _detailText(size: 17, weight: FontWeight.w700)),
          ],
        ),
      );
}

class _NutritionTile extends StatelessWidget {
  const _NutritionTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _detailSurface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: _detailBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: _detailText(size: 10, color: _detailMuted)),
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value,
                    style: _detailText(
                        size: 22, color: color, weight: FontWeight.w700)),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(unit,
                      style: _detailText(size: 9, color: _detailMuted)),
                ),
              ],
            ),
          ],
        ),
      );
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: _detailSurface,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: _detailBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _detailGreen, size: 19),
                const SizedBox(width: 9),
                Text(title,
                    style: _detailText(size: 14, weight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 13),
            child,
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
              child: Text(label,
                  style: _detailText(size: 11, color: _detailMuted))),
          Text(value,
              textAlign: TextAlign.right,
              style: _detailText(size: 11, weight: FontWeight.w600)),
        ],
      );
}
