import 'package:flutter/material.dart';

/// Compact, shared marker used anywhere a food post appears in GymFeed.
/// Keeping this in one widget prevents the Home and profile grids from
/// drifting into different visual meanings for the same post type.
class FoodPostBadge extends StatelessWidget {
  const FoodPostBadge({
    super.key,
    this.size = 30,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Food post',
      child: Container(
        key: const Key('food-post-badge'),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF0EEA78),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 8),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.restaurant_rounded,
          color: const Color(0xFF07150D),
          size: size * .55,
        ),
      ),
    );
  }
}
