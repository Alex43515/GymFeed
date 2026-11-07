import 'package:flutter/material.dart';

import '/backend/schema/posts_record.dart';

/// What to show above a feed item, Instagram style.
enum FeedSectionHeader {
  none,

  /// First suggested post right after your followed posts.
  caughtUpThenSuggested,

  /// The feed starts with suggested posts (you follow nobody with posts yet).
  suggestedOnly,
}

/// Decides the header above `items[index]`. Pure, so it is easy to test.
FeedSectionHeader feedSectionHeaderFor(List<PostsRecord> items, int index) {
  if (index < 0 || index >= items.length) return FeedSectionHeader.none;
  if (!items[index].isSuggestedInFeed) return FeedSectionHeader.none;
  if (index == 0) return FeedSectionHeader.suggestedOnly;
  return items[index - 1].isSuggestedInFeed
      ? FeedSectionHeader.none
      : FeedSectionHeader.caughtUpThenSuggested;
}

class FeedSectionDivider extends StatelessWidget {
  const FeedSectionDivider({super.key, required this.header});

  final FeedSectionHeader header;

  static const _green = Color(0xFF16E77D);
  static const _muted = Color(0xFF8C9299);

  @override
  Widget build(BuildContext context) {
    if (header == FeedSectionHeader.none) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
      child: Column(
        children: [
          if (header == FeedSectionHeader.caughtUpThenSuggested) ...[
            Container(
              key: const Key('feed-caught-up'),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _green, width: 2),
              ),
              child: const Icon(Icons.check_rounded, color: _green, size: 30),
            ),
            const SizedBox(height: 12),
            const Text(
              "You're all caught up",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "You've seen all new posts from people you follow.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 12, color: _muted),
            ),
            const SizedBox(height: 22),
            const Divider(height: 1, color: Color(0x33FFFFFF)),
            const SizedBox(height: 18),
          ],
          const Align(
            key: Key('feed-suggested-for-you'),
            alignment: Alignment.centerLeft,
            child: Text(
              'Suggested for you',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
