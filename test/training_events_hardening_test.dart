import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_feed/ai_workout/coach_events/coach_events_widget.dart';
import 'package:gym_feed/backend/supabase/repositories/training_repository.dart';
import 'package:gym_feed/ai_workout/coach_events/event_details_sheet.dart';
import 'package:gym_feed/custom_code/widgets/feed_video_player.dart';

Widget _app(Widget child) => MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: child,
    );

void main() {
  group('workout and event hardening', () {
    testWidgets('event cover and video occupy separate sections',
        (tester) async {
      final event = Training({
        'id': 'separate-media',
        'title': 'Workout at the park',
        'description': 'Join us for a workout.',
        'background_image': 'https://example.com/cover.jpg',
        'legacy_video_url': 'https://example.com/video.mp4',
        'video_thumbnail': 'https://example.com/video-poster.jpg',
      });
      await tester.pumpWidget(_app(Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showGymFeedEventDetails(context, event),
            child: const Text('Open event'),
          ),
        ),
      )));
      await tester.tap(find.text('Open event'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final cover = find.byKey(const Key('event-cover-image'));
      expect(cover, findsOneWidget);
      final coverTop = tester.getTopLeft(cover).dy;
      final video = find.byKey(const Key('event-video-separate-media'));
      await tester.scrollUntilVisible(video, 250,
          scrollable: find.byType(Scrollable).last);
      final player = tester.widget<FeedVideoPlayer>(video);
      expect(player.thumbnailUrl, 'https://example.com/video-poster.jpg');
      expect(find.text('Event video'), findsOneWidget);
      expect(coverTop, lessThan(tester.getTopLeft(video).dy));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    test('training maps the persisted event/media fields', () {
      final startsAt = DateTime.utc(2026, 8, 24, 7);
      final training = Training({
        'id': 'cardio-1',
        'category': 'Cardio',
        'difficulty_level': 'Intermediate',
        'duration': 45,
        'starts_at': startsAt.toIso8601String(),
        'background_image': 'https://gymfeed.io/cover.jpg',
        'legacy_video_url': 'https://gymfeed.io/workout.m3u8',
      });

      expect(training.category, 'Cardio');
      expect(training.difficultyLevel, 'Intermediate');
      expect(training.duration, 45);
      expect(training.startsAt, startsAt);
      expect(training.coverUrl, 'https://gymfeed.io/cover.jpg');
      expect(training.videoUrl, 'https://gymfeed.io/workout.m3u8');
    });

    testWidgets('event categories use the saved category and cards open',
        (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final events = [
        Training({
          'id': 'cardio-1',
          'title': 'Park run',
          'description': '5k together',
          'category': 'Cardio',
          'difficulty_level': 'Beginner',
          'duration': 30,
          'training_date_raw': 'Aug 24, 2026',
          'training_time_raw': '7:00 AM',
          'joined_by_me': true,
          'author': {'username': 'alex'},
        }),
        Training({
          'id': 'strength-1',
          'title': 'Heavy day',
          'category': 'Strength',
        }),
      ];
      await tester.pumpWidget(_app(CoachEventsWidget(
        trainingsLoader: () async => events,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('event-filter-Cardio')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('event-card-cardio-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('event-card-strength-1')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('event-card-cardio-1')));
      await tester.pumpAndSettle();
      expect(find.text('Park run'), findsWidgets);
      expect(find.text('Leave event'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('upcoming events are shown soonest first', (tester) async {
      tester.view.physicalSize = const Size(900, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = DateTime.now().toUtc();
      Training event(String id, [DateTime? startsAt]) => Training({
            'id': id,
            'title': id,
            if (startsAt != null) 'starts_at': startsAt.toIso8601String(),
          });

      await tester.pumpWidget(_app(CoachEventsWidget(
        trainingsLoader: () async => [
          event('unknown'),
          event('later', now.add(const Duration(days: 7))),
          event('past', now.subtract(const Duration(days: 1))),
          event('soon', now.add(const Duration(hours: 1))),
        ],
      )));
      await tester.pumpAndSettle();

      final soon = find.byKey(const ValueKey('upcoming-event-soon'));
      final later = find.byKey(const ValueKey('upcoming-event-later'));
      expect(tester.getTopLeft(soon).dx, lessThan(tester.getTopLeft(later).dx));
      expect(find.byKey(const ValueKey('upcoming-event-past')), findsNothing);
      expect(
          find.byKey(const ValueKey('upcoming-event-unknown')), findsNothing);
      final firstCard = find.byKey(const ValueKey('event-card-soon'));
      final secondCard = find.byKey(const ValueKey('event-card-later'));
      expect(tester.getTopLeft(firstCard).dy,
          lessThanOrEqualTo(tester.getTopLeft(secondCard).dy));
    });

    test('block, creation, and FitClips no longer use legacy paths', () {
      final blocked =
          File('lib/components/blocked/blocked_widget.dart').readAsStringSync();
      final creator = File(
        'lib/workout/schedule_training/schedule_training_widget.dart',
      ).readAsStringSync();
      final clips = File(
        'lib/workout/video_reels/video_reels_widget.dart',
      ).readAsStringSync();

      expect(blocked, contains('ProfileRepository().block(targetId)'));
      expect(blocked, isNot(contains("'user_blocked'")));
      expect(creator, contains('showWorkoutLocationPicker(context)'));
      expect(creator, contains('CoachEventsWidget.routeName'));
      expect(creator, isNot(contains('JoinTrainingWidget.routeName')));
      expect(creator, contains('startsAt: startsAt'));
      expect(clips, contains('TrainingRepository'));
      expect(clips, contains('videoFeed(limit: 60)'));
      expect(clips, isNot(contains('PostsRecord')));
      expect(clips, isNot(contains('reels_page')));
    });

    test('all event entry points use the complete shared details surface', () {
      final events = File(
        'lib/ai_workout/coach_events/coach_events_widget.dart',
      ).readAsStringSync();
      final train = File(
        'lib/workout/training_home/training_home_widget.dart',
      ).readAsStringSync();
      final details = File(
        'lib/ai_workout/coach_events/event_details_sheet.dart',
      ).readAsStringSync();

      expect(events, contains('showGymFeedEventDetails'));
      expect(train, contains('showGymFeedEventDetails'));
      expect(details, contains('event-participants-section'));
      expect(details, contains('Created by'));
      expect(details, contains('event-google-maps-link'));
      expect(details, contains('TrainingRepository().participants'));
    });

    test('Explore has one mixed content tab with food badges', () {
      final explore = File(
        'lib/pages/core_pages/explore_page/explore_page_widget.dart',
      ).readAsStringSync();

      expect(explore, contains('FoodPostBadge'));
      expect(explore, contains("Tab(text: 'Explore')"));
      expect(explore, contains("Tab(text: 'People')"));
      expect(explore, isNot(contains("Tab(text: 'Meals')")));
    });
  });
}
