import 'package:flutter/material.dart';

import '/backend/supabase/repositories/founding_repository.dart';

const _foundingGold = Color(0xFFE8B339);

/// Shows the Founding Member badge for [userId], or nothing if the user is
/// not one of the first 1,000.
///
/// [compact] is the small star used next to a name in the feed. The full
/// version ("Founding Member #0142") is used on profiles.
class FoundingBadge extends StatefulWidget {
  const FoundingBadge({
    super.key,
    required this.userId,
    this.compact = false,
    this.onDark = false,
    this.padding = EdgeInsets.zero,
  });

  final String userId;
  final bool compact;

  /// Light text for dark backgrounds (full badge only).
  final bool onDark;

  /// Space around the full badge, applied only when the badge is shown.
  final EdgeInsets padding;

  @override
  State<FoundingBadge> createState() => _FoundingBadgeState();
}

class _FoundingBadgeState extends State<FoundingBadge> {
  @override
  void initState() {
    super.initState();
    FoundingRegistry.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId.isEmpty) return const SizedBox.shrink();
    return ValueListenableBuilder<Map<String, int>>(
      valueListenable: FoundingRegistry.instance.numbers,
      builder: (context, numbers, _) {
        final number = numbers[widget.userId];
        if (number == null) return const SizedBox.shrink();
        final label = 'Founding Member ${formatFoundingNumber(number)}';
        if (widget.compact) {
          return Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Tooltip(
              message: label,
              child: Semantics(
                label: label,
                child: Container(
                  key: const Key('founding-badge-compact'),
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: _foundingGold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star_rounded,
                      size: 12, color: Colors.white),
                ),
              ),
            ),
          );
        }
        final badge = Container(
          key: const Key('founding-badge-full'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _foundingGold.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _foundingGold.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 14, color: _foundingGold),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: widget.onDark ? Colors.white : const Color(0xFF6B4E00),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
        return Padding(padding: widget.padding, child: badge);
      },
    );
  }
}
