import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_feed/backend/profile_post_scope.dart';

void main() {
  group('profile post ownership guard', () {
    test('keeps only posts owned by the selected profile', () {
      final rows = <Map<String, dynamic>>[
        {'id': 'a-post-1', 'user_id': 'user-a'},
        {'id': 'b-post-1', 'user_id': 'user-b'},
        {'id': 'a-post-2', 'user_id': 'user-a'},
      ];

      final result = retainProfilePostRows(rows, 'user-a');

      expect(result.map((row) => row['id']), ['a-post-1', 'a-post-2']);
      expect(result.every((row) => row['user_id'] == 'user-a'), isTrue);
    });

    test('the same exact-owner guard protects profile workouts', () {
      final rows = <Map<String, dynamic>>[
        {'id': 'training-a', 'user_id': 'user-a'},
        {'id': 'training-b', 'user_id': 'user-b'},
      ];

      final result = retainRowsOwnedBy(rows, 'user-b');

      expect(result.map((row) => row['id']), ['training-b']);
    });

    test('rejects missing, null, and similar-looking owners', () {
      final rows = <Map<String, dynamic>>[
        {'id': 'missing-owner'},
        {'id': 'null-owner', 'user_id': null},
        {'id': 'prefix-owner', 'user_id': 'user-a-extra'},
      ];

      expect(retainProfilePostRows(rows, 'user-a'), isEmpty);
    });

    test('an empty profile id can never expose posts', () {
      final rows = <Map<String, dynamic>>[
        {'id': 'a-post-1', 'user_id': 'user-a'},
      ];

      expect(retainProfilePostRows(rows, ''), isEmpty);
      expect(retainProfilePostRows(rows, '   '), isEmpty);
    });

    test('other-user profile is wired only to scoped post queries', () {
      final shell = File(
        'lib/pages/core_pages/profile_other/profile_other_widget.dart',
      ).readAsStringSync();
      final source = File(
        'lib/pages/core_pages/profile/mobile_profile_view.dart',
      ).readAsStringSync();

      expect(shell, contains('MobileProfileView('));
      expect(source, contains('queryPostsByUserStream('));
      expect(source, contains('queryTaggedPostsByUserStream('));
      expect(source, isNot(contains('queryPostsRecord(')));
      expect(source, contains('queryTrainingsByUserStream('));
      expect(source, isNot(contains('queryChatsRecord(')));
      expect(source, isNot(contains('queryStoriesRecord(')));
    });

    test('profile Posts tabs include both regular and food posts', () {
      for (final path in [
        'lib/pages/core_pages/profile/mobile_profile_view.dart',
        'lib/pages/core_pages/profile/desktop_profile_view.dart',
      ]) {
        final source = File(path).readAsStringSync();
        expect(source, contains('queryPostsByUserStream('));
        expect(source, isNot(contains('foodPost: false')));
        expect(source, contains('FoodPostBadge'));
      }
    });

    test('joined and owned training tabs do not use the global query', () {
      final source = File(
        'lib/workout/join_training/join_training_widget.dart',
      ).readAsStringSync();

      expect(source, contains('queryJoinedTrainingsStream('));
      expect(source, contains('queryTrainingsByUserStream('));
      expect(source, isNot(contains('queryUserTrainingsRecord(')));
      expect(source, contains('queryWorkoutsByDateStream('));
      expect(source, isNot(contains('queryWorkoutRecord(')));
    });

    test('report dialogs load the selected item instead of a global first row',
        () {
      final foodSource = File('lib/components/mark_food/mark_food_widget.dart')
          .readAsStringSync();
      final reelSource = File('lib/components/mark_reel/mark_reel_widget.dart')
          .readAsStringSync();
      final reelsFeedSource = File(
        'lib/workout/video_reels_copy/video_reels_copy_widget.dart',
      ).readAsStringSync();

      expect(foodSource, contains('PostsRecord.getDocument(postReference)'));
      expect(foodSource, isNot(contains('queryPostsRecord(')));
      expect(
        reelSource,
        contains('UserTrainingsRecord.getDocument(trainingReference)'),
      );
      expect(reelSource, isNot(contains('queryUserTrainingsRecord(')));
      expect(reelsFeedSource, contains('queryTrainingsFeedStream()'));
      expect(reelsFeedSource, isNot(contains('queryUserTrainingsRecord(')));
    });
  });
}
