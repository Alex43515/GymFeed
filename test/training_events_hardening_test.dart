import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_feed/ai_workout/coach_events/coach_events_widget.dart';
import 'package:gym_feed/backend/supabase/repositories/training_repository.dart';

Widget _app(Widget child) => MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: child,
    );

void main() {
  group('workout and event hardening', () {
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
