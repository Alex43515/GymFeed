import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String source(String path) => File(path).readAsStringSync();

  test('tagging is searchable, multi-select, and Supabase-user based', () {
    final picker = source(
        'lib/pages/posts/select_tagged_users/select_tagged_users_widget.dart');
    final summary = source('lib/pages/posts/tag_users/tag_users_widget.dart');
    final repository =
        source('lib/backend/supabase/repositories/post_repository.dart');

    expect(picker, contains('queryUsersRecordOnce(limit: 500)'));
    expect(picker, contains("Key('tag-user-\${user.uid}')"));
    expect(picker, contains('state.addToTaggedUsers(user.reference)'));
    expect(picker, isNot(contains('EasyDebounce')));
    expect(summary, contains("Key('add-tagged-people')"));
    expect(repository, contains("from('post_tags')"));
  });

  test('food details use one scroll surface and preserve video aspect', () {
    final details =
        source('lib/pages/posts/post_details/food_post_details_view.dart');
    final player = source('lib/custom_code/widgets/feed_video_player.dart');

    expect(details, contains('fit: BoxFit.contain'));
    expect(details, contains("key: const Key('food-details-tabs')"));
    expect(details, isNot(contains('TabBarView(')));
    expect(details, isNot(contains('height: 430')));
    expect(player, contains('final BoxFit fit;'));
  });

  test('home activities open events and their shared details sheet', () {
    final feed = source('lib/pages/core_pages/feed/feed_widget.dart');

    expect(feed, contains('joinedByCurrentUser(limit: 100)'));
    expect(feed, contains('CoachEventsWidget.routeName'));
    expect(feed, contains('showGymFeedEventDetails('));
    expect(feed, isNot(contains('_myTrainingsStream')));
  });

  test('mobile profiles have one primary scroll and redesigned workouts', () {
    final profile =
        source('lib/pages/core_pages/profile/mobile_profile_view.dart');

    expect('CustomScrollView('.allMatches(profile), hasLength(1));
    expect(profile, contains('NeverScrollableScrollPhysics'));
    expect(
        profile, contains("Key('profile-workout-\${training.reference.id}')"));
    expect(profile, contains('showGymFeedEventDetails(context, value)'));
    expect(profile, contains('FoodPostBadge(size: 26)'));
  });
}
