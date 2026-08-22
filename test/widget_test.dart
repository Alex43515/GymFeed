// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

import 'package:gym_feed/ai_workout/coach_home/coach_home_widget.dart';
import 'package:gym_feed/ai_workout/coach_tools/coach_tools_widget.dart';
import 'package:gym_feed/components/home_post_engagement/home_post_engagement_widget.dart';
import 'package:gym_feed/components/nav_bar/nav_bar_widget.dart';
import 'package:gym_feed/custom_code/widgets/gym_feed_video_controls.dart';
import 'package:gym_feed/backend/supabase/repositories/body_scan_repository.dart';
import 'package:gym_feed/flutter_flow/custom_icons.dart';

void main() {
  testWidgets('bottom navigation fits a narrow screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
          ),
          child: child!,
        ),
        home: const Scaffold(
          bottomNavigationBar: NavBarWidget(selectPageIndex: 3),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Coach hub matches the mobile layout without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
          ),
          child: child!,
        ),
        home: CoachHomeWidget(
          statsLoader: () async => const CoachStats(
            mealsScanned: 18,
            machinesLearned: 7,
            bodyScans: 2,
          ),
          entitlementLoader: () async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AI Coach'), findsOneWidget);
    expect(find.text('Coach'), findsWidgets);
    expect(find.text('Train'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Your body, decoded.'), findsOneWidget);
    expect(find.text('Scan food'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Body scan'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Body scan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI Coach tool pages fit the phone design without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final pages = <(Widget, String)>[
      (const CoachFoodScannerWidget(), 'Point at your plate'),
      (const CoachEquipmentScannerWidget(), 'Frame the whole machine'),
      (const CoachTrainerWidget(), 'Ask your coach…'),
      (const CoachBodyScanWidget(), 'Stand 2m back'),
    ];

    for (final page in pages) {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
            ),
            child: child!,
          ),
          home: page.$1,
        ),
      );
      await tester.pump();
      expect(find.textContaining(page.$2), findsWidgets);
      if (page.$1 is CoachFoodScannerWidget) {
        expect(
            find.byKey(const ValueKey('open-nutrition-diary')), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Body scan analysis loader matches the staged design',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
          home: CoachBodyScanWidget(showAnalyzingForTesting: true)),
    );
    await tester.pump();

    expect(find.text('Analyzing your scan'), findsOneWidget);
    expect(find.text('Detecting body landmarks'), findsOneWidget);
    expect(find.text('Estimating composition'), findsOneWidget);
    expect(find.text('Measuring muscle balance'), findsOneWidget);
    expect(find.text('Generating coach insights'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Body scan scored report scrolls without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const profile = BodyScanProfileData(
      age: 30,
      heightCm: 180,
      weightKg: 80,
      gender: 'Male',
      workoutsPerWeek: '4 workouts',
    );
    final report = BodyScanRepository.withPreviousScan(
      BodyScanRepository.normalize('''
        {"person_visible":true,"body_fat_percent":18.4,
        "muscle_mass_kg":38.2,"body_water_percent":61,
        "essential_fat_percent":4,"beneficial_fat_percent":11.4,
        "unbeneficial_fat_percent":3,"confidence":0.86,
        "chest":"Strong","chest_score":86,"arms":"Good","arms_score":74,
        "core":"Good","core_score":68,"legs":"Needs work","legs_score":42,
        "visceral_fat_level":6,"visceral_fat_assessment":"Healthy estimate",
        "posture_assessment":"Neutral alignment",
        "symmetry_assessment":"Minor difference",
        "recommendation":"Add a second lower-body day."}
      ''', profile),
      const {'fitness_score': 78, 'body_fat': 19.6},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CoachBodyScanWidget(initialResultForTesting: report),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('FITNESS SCORE'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Composition analysis'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Composition analysis'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Detailed metrics'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Detailed metrics'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ask the trainer'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ask the trainer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home post like and comment controls update their counts',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var serverLikes = 4;
    var serverComments = 2;
    bool? requestedLikeState;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: HomePostEngagementWidget(
            data: const HomePostEngagementData(
              postId: 'post-1',
              likeCount: 4,
              commentCount: 2,
              likedByCurrentUser: false,
            ),
            toggleLike: (postId, shouldLike) async {
              expect(postId, 'post-1');
              requestedLikeState = shouldLike;
              serverLikes += shouldLike ? 1 : -1;
            },
            openComments: () async => serverComments += 1,
            loadCounts: (_) async => (
              likes: serverLikes,
              comments: serverComments,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('4'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.byIcon(FFIcons.kmuscles), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-like-post-1')));
    await tester.pumpAndSettle();
    expect(requestedLikeState, isTrue);
    expect(find.text('5'), findsOneWidget);
    expect(find.byIcon(FFIcons.k02012), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-comment-post-1')));
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('video controls center play and support stop mute and seeking',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final value = ValueNotifier(
      const VideoPlayerValue(
        duration: Duration(seconds: 100),
        position: Duration(seconds: 25),
        size: Size(1920, 1080),
        isInitialized: true,
      ),
    );
    addTearDown(value.dispose);
    var playTaps = 0;
    var stopTaps = 0;
    var muteTaps = 0;
    Duration? seekTarget;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SizedBox.expand(
            child: GymFeedVideoControls(
              valueListenable: value,
              onPlayPause: () => playTaps += 1,
              onStop: () => stopTaps += 1,
              onToggleMute: () => muteTaps += 1,
              onSeek: (target) => seekTarget = target,
              controlKeyPrefix: 'test-video',
            ),
          ),
        ),
      ),
    );

    final playFinder = find.byKey(const Key('test-video-play-pause'));
    final controlsFinder = find.byType(GymFeedVideoControls);
    final playCenter = tester.getCenter(playFinder);
    final controlsCenter = tester.getCenter(controlsFinder);
    expect((playCenter.dx - controlsCenter.dx).abs(), lessThan(0.5));
    expect((playCenter.dy - controlsCenter.dy).abs(), lessThan(0.5));

    await tester.tap(playFinder);
    await tester.tap(find.byKey(const Key('test-video-stop')));
    await tester.tap(find.byKey(const Key('test-video-mute')));
    expect(playTaps, 1);
    expect(stopTaps, 1);
    expect(muteTaps, 1);

    final progressFinder = find.byKey(const Key('test-video-progress'));
    final progressRect = tester.getRect(progressFinder);
    await tester.tapAt(
      Offset(progressRect.left + (progressRect.width * 0.75),
          progressRect.center.dy),
    );
    await tester.pump();
    expect(seekTarget, isNotNull);
    expect(seekTarget!.inSeconds, inInclusiveRange(70, 80));
    expect(tester.takeException(), isNull);
  });
}
