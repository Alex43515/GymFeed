import 'package:flutter/material.dart';

enum CoachSection { coach, train, events }

class CoachSectionSwitcher extends StatelessWidget {
  const CoachSectionSwitcher({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CoachSection selected;
  final ValueChanged<CoachSection> onSelected;

  @override
  Widget build(BuildContext context) {
    const labels = {
      CoachSection.coach: 'Coach',
      CoachSection.train: 'Train',
      CoachSection.events: 'Events',
    };

    return Semantics(
      label: 'Coach section',
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF282828)),
        ),
        child: Row(
          children: CoachSection.values.map((section) {
            final isSelected = section == selected;
            return Expanded(
              child: Semantics(
                selected: isSelected,
                button: true,
                child: InkWell(
                  key: ValueKey('coach-section-${section.name}'),
                  onTap: isSelected ? null : () => onSelected(section),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1FE276)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      labels[section]!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        height: 1,
                        fontWeight: FontWeight.w600,
                      ).copyWith(
                        color: isSelected
                            ? const Color(0xFF080808)
                            : const Color(0xFF8D8D8D),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
