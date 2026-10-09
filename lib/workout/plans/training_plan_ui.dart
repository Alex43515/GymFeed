import 'package:flutter/material.dart';

import 'training_plan_models.dart';

// Same palette as the Train and routine screens.
const planBg = Color(0xFF0B0B0B);
const planCard = Color(0xFF141414);
const planBorder = Color(0xFF282828);
const planMuted = Color(0xFF8B8B8B);
const planGreen = Color(0xFF1FE276);
const planAmber = Color(0xFFFFB547);

TextStyle planText({
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

const planMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const planWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String planDateLabel(DateTime date) =>
    '${planWeekdays[date.weekday - 1]}, ${planMonths[date.month - 1]} ${date.day}';

/// Caps text scaling like the other Train screens so layouts stay intact.
Widget planScaled(BuildContext context, Widget child) {
  final media = MediaQuery.of(context);
  return MediaQuery(
    data: media.copyWith(textScaler: media.textScaler.clamp(maxScaleFactor: 1.3)),
    child: child,
  );
}

Widget planTopBar(
  BuildContext context, {
  required String title,
  String? subtitle,
  Widget? action,
  IconData icon = Icons.arrow_back_ios_new_rounded,
}) =>
    SizedBox(
      height: 62,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.maybePop(context),
            icon: Icon(icon, color: Colors.white, size: 20),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: planText(size: 16, weight: FontWeight.w700)),
                if (subtitle != null)
                  Text(subtitle, style: planText(size: 10, color: planMuted)),
              ],
            ),
          ),
          SizedBox(width: 72, child: action),
        ],
      ),
    );

Widget planChip(String label, {Color color = planMuted, Color? background}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: planBorder),
      ),
      child: Text(label,
          style: planText(size: 10, color: color, weight: FontWeight.w600)),
    );

Color planStatusColor(String status) => switch (status) {
      'published' => planGreen,
      'in_review' => planAmber,
      'rejected' => const Color(0xFFFF6B6B),
      _ => planMuted,
    };

InputDecoration planInput(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: planText(size: 13, color: planMuted),
      filled: true,
      fillColor: planCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: planBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: planBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: planGreen),
      ),
    );

class TrainingPlanCard extends StatelessWidget {
  const TrainingPlanCard({
    super.key,
    required this.plan,
    required this.onTap,
    this.showStatus = false,
  });

  final TrainingPlan plan;
  final VoidCallback onTap;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: planCard,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: ValueKey('training-plan-card-${plan.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: planBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF123821),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text('${plan.dayCount}\nDAYS',
                      textAlign: TextAlign.center,
                      style: planText(
                          size: 11,
                          color: planGreen,
                          weight: FontWeight.w800,
                          height: 1.1)),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: planText(size: 14, weight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                          showStatus
                              ? '${plan.goalLabel} · ${plan.levelLabel}'
                              : 'by ${plan.seller?.label ?? 'GymFeed athlete'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: planText(size: 11, color: planMuted)),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (showStatus)
                            planChip(plan.statusLabel,
                                color: planStatusColor(plan.status))
                          else
                            planChip(plan.goalLabel),
                          planChip(plan.priceLabel, color: planGreen),
                          if (plan.enrollmentCount > 0)
                            planChip('${plan.enrollmentCount} following'),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: planMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
