import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_feed/backend/supabase/repositories/training_plan_repository.dart';
import 'package:gym_feed/workout/plans/training_plan_builder_widget.dart';
import 'package:gym_feed/workout/plans/training_plan_detail_widget.dart';
import 'package:gym_feed/workout/plans/training_plan_models.dart';
import 'package:gym_feed/workout/plans/training_plan_schedule.dart';
import 'package:gym_feed/workout/plans/training_plan_service.dart';
import 'package:gym_feed/workout/routines/workout_routine_flow.dart';
import 'package:gym_feed/workout/routines/workout_routine_models.dart';
import 'package:gym_feed/workout/routines/workout_routine_store.dart';

const squat = RoutineExercise(name: 'Squat', setCount: 3, defaultReps: 8);
const bench = RoutineExercise(name: 'Bench Press', setCount: 3, defaultReps: 10);

PlanExerciseVideo video(String name, {String status = 'ready'}) =>
    PlanExerciseVideo(
      exerciseName: name,
      assetId: 'asset-$name',
      playbackUrl: 'https://cdn.test/$name/playlist.m3u8',
      thumbnailUrl: 'https://cdn.test/$name/thumbnail.jpg',
      status: status,
    );

TrainingPlan plan({
  String status = 'draft',
  String sellerId = 'seller',
  Map<String, PlanExerciseVideo> videos = const {},
  String coverImageUrl = '',
  PlanExerciseVideo? introVideo,
  bool isFeatured = false,
  double? ratingAvg,
  int ratingCount = 0,
}) =>
    TrainingPlan(
      id: 'p1',
      sellerId: sellerId,
      title: 'Strength Base',
      dayCount: 3,
      status: status,
      days: const [
        TrainingPlanDay(day: 1, title: 'Lower', exercises: [squat, bench]),
        TrainingPlanDay(day: 2, isRest: true),
        TrainingPlanDay(day: 3, title: 'Lower again', exercises: [squat]),
      ],
      videos: videos,
      coverImageUrl: coverImageUrl,
      introVideo: introVideo,
      isFeatured: isFeatured,
      ratingAvg: ratingAvg,
      ratingCount: ratingCount,
    );

TrainingPlan complete({String status = 'draft', String sellerId = 'seller'}) =>
    plan(
      status: status,
      sellerId: sellerId,
      coverImageUrl: 'https://cdn.test/cover.jpg',
      introVideo: video('Intro'),
      videos: {'squat': video('Squat'), 'bench press': video('Bench Press')},
    );

class FakeRepository extends TrainingPlanRepository {
  FakeRepository({this.plan, this.admin = false});

  TrainingPlan? plan;
  final bool admin;
  final reviews = <String>[];
  final submitted = <String>[];
  final featuredCalls = <bool>[];
  final rated = <String>[];
  List<PlanExerciseVideo>? savedVideos;
  String? savedCover;
  String? savedIntro;
  List<TrainingPlanRating> ratingList = const [];

  @override
  Future<void> setFeatured(String planId, bool featured) async =>
      featuredCalls.add(featured);

  @override
  Future<List<TrainingPlanRating>> ratings(String planId, {int limit = 30}) async =>
      ratingList;

  @override
  Future<void> rate(String planId, {required int rating, String comment = ''}) async =>
      rated.add('$rating:$comment');

  @override
  Future<TrainingPlan?> get(String planId) async => plan;

  @override
  Future<bool> isAdmin() async => admin;

  @override
  Future<String> review(String planId,
      {required bool approve, String note = ''}) async {
    reviews.add('${approve ? 'approve' : 'reject'}:$note');
    return approve ? 'published' : 'rejected';
  }

  @override
  Future<String> submit(String planId) async {
    submitted.add(planId);
    return 'in_review';
  }

  @override
  Future<String> saveDraft({
    String? planId,
    required String title,
    required String description,
    required String goal,
    required String level,
    required String equipment,
    required List<TrainingPlanDay> days,
    Iterable<PlanExerciseVideo> videos = const [],
    String coverImageUrl = '',
    String? introVideoAssetId,
  }) async {
    savedVideos = videos.toList();
    savedCover = coverImageUrl;
    savedIntro = introVideoAssetId;
    return planId ?? 'new';
  }

  @override
  Future<void> enroll({
    required TrainingPlan plan,
    required DateTime startDate,
    required PlanScheduleMode mode,
    Set<int> weekdays = const {},
  }) async {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  void tallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('model', () {
    test('one video per exercise name, shared across days and case-insensitive', () {
      final p = plan(videos: {'squat': video('Squat')});

      expect(p.exerciseNames, ['Squat', 'Bench Press']);
      expect(p.videoFor(' SQUAT ')?.assetId, 'asset-Squat');
      expect(p.exercisesMissingVideo, ['Bench Press']);
      expect(p.coverUrl, 'https://cdn.test/Squat/thumbnail.jpg');
    });

    test('failed uploads still count as missing', () {
      final p = plan(videos: {
        'squat': video('Squat'),
        'bench press': video('Bench Press', status: 'failed'),
      });

      expect(p.exercisesMissingVideo, ['Bench Press']);
    });

    test('videos parse from the Supabase embed', () {
      final parsed = TrainingPlan.fromRow({
        'id': 'p1',
        'seller_id': 's',
        'title': 'Plan',
        'videos': [
          {
            'exercise_name': 'Squat',
            'video_asset_id': 'a1',
            'asset': {'playback_url': 'https://cdn/x.m3u8', 'thumbnail_url': 'https://cdn/x.jpg', 'status': 'processing'},
          },
        ],
      });

      final squatVideo = parsed.videoFor('squat')!;
      expect(squatVideo.assetId, 'a1');
      expect(squatVideo.status, 'processing');
      expect(squatVideo.isPlayable, isTrue);
      expect(squatVideo.toRpcJson(), {'exercise_name': 'Squat', 'video_asset_id': 'a1'});
    });
  });

  group('workout videos on device', () {
    test('adding a plan makes its videos available to the workout screen', () async {
      final p = plan(status: 'published', videos: {'squat': video('Squat')});
      await TrainingPlanService(repository: FakeRepository())
          .addToTrain(plan: p, startDate: DateTime(2030, 1, 1));

      expect(await WorkoutRoutineStore.exerciseVideoUrl('plan-p1-v1-d1', 'squat'),
          'https://cdn.test/Squat/playlist.m3u8');
      expect(await WorkoutRoutineStore.exerciseVideoUrl('plan-p1-v1-d1', 'Bench Press'), isNull);
      expect(await WorkoutRoutineStore.exerciseVideoUrl('default-leg-day', 'Squat'), isNull);

      await WorkoutRoutineStore.removePlan('plan-p1');
      expect(await WorkoutRoutineStore.exerciseVideoUrl('plan-p1-v1-d1', 'Squat'), isNull);
    });

    testWidgets('active workout shows How to for plan exercises with a video', (tester) async {
      tallPhone(tester);
      final p = plan(status: 'published', videos: {'squat': video('Squat')});
      final import = buildTrainingPlanImport(plan: p, start: DateTime(2030, 1, 1));
      await WorkoutRoutineStore.importPlan(
        planKey: import.planKey,
        syncKey: import.syncKey,
        routines: import.routines,
        schedule: import.schedule,
        videos: import.videos,
      );

      await tester.pumpWidget(MaterialApp(
          home: ActiveWorkoutWidget(routine: import.routines.first)));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('exercise-video-Squat')), findsOneWidget);
      expect(find.byKey(const ValueKey('exercise-video-Bench Press')), findsNothing);
    });
  });

  group('builder', () {
    testWidgets('each exercise gets its video inside the day editor; cover and intro are saved',
        (tester) async {
      tallPhone(tester);
      tester.view.physicalSize = const Size(430, 2400);
      final repository = FakeRepository();
      final uploads = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: TrainingPlanBuilderWidget(
          plan: plan(),
          repository: repository,
          videoUploader: (_, name) async {
            uploads.add(name);
            return video(name, status: 'processing');
          },
          imageUploader: (_) async => 'https://cdn.test/new-cover.jpg',
        ),
      ));
      await tester.pumpAndSettle();

      // The plan's day cards only list exercises; there is no upload there.
      expect(find.byKey(const ValueKey('plan-exercise-row-d1-Squat')), findsOneWidget);
      expect(find.byKey(const ValueKey('plan-exercise-row-d3-Squat')), findsOneWidget);
      expect(find.byKey(const ValueKey('upload-exercise-video-Squat')), findsNothing);
      expect(find.text('Videos 0/2'), findsOneWidget);

      // Open day 1: every exercise has its own video row.
      await tester.tap(find.byKey(const ValueKey('edit-plan-day-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('exercise-video-footer-Squat')), findsOneWidget);
      expect(find.byKey(const ValueKey('exercise-video-footer-Bench Press')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('upload-exercise-video-Squat')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('upload-exercise-video-Bench Press')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Video added · processing'), findsNWidgets(2));
      expect(find.textContaining('used on day 1, 3'), findsOneWidget,
          reason: 'Squat on day 1 and 3 shares one video');

      await tester.tap(find.byKey(const ValueKey('save-routine')));
      await tester.pumpAndSettle();

      expect(find.text('Videos 2/2'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('upload-plan-intro')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('plan-cover')));
      await tester.pumpAndSettle();

      expect(uploads, ['Squat', 'Bench Press', 'Intro']);
      expect(find.text('Required'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('save-training-plan')));
      await tester.pumpAndSettle();
      expect(repository.savedVideos!.map((v) => v.assetId),
          ['asset-Squat', 'asset-Bench Press']);
      expect(repository.savedCover, 'https://cdn.test/new-cover.jpg');
      expect(repository.savedIntro, 'asset-Intro');
    });
  });

  group('plan page', () {
    test('submit problems list cover, intro and missing videos', () {
      expect(plan(videos: {'squat': video('Squat')}).submitProblems,
          ['a cover image', 'an intro video', 'a video for Bench Press']);
      expect(complete().submitProblems, isEmpty);
    });

    testWidgets('owner cannot submit while something is missing', (tester) async {
      tallPhone(tester);
      final repository = FakeRepository(plan: plan(videos: {'squat': video('Squat')}));

      await tester.pumpWidget(MaterialApp(
        home: TrainingPlanDetailWidget(
          introPlayerBuilder: (url) => Text('intro:$url'),
          planId: 'p1',
          currentUserId: 'seller',
          service: TrainingPlanService(repository: repository),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('owner-missing-videos')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('submit-plan')));
      await tester.pumpAndSettle();
      expect(repository.submitted, isEmpty);
      expect(find.textContaining('Still needed: a cover image'), findsWidgets);
    });

    testWidgets('admins approve or send back plans waiting for review', (tester) async {
      tallPhone(tester);
      final repository = FakeRepository(
        admin: true,
        plan: complete(status: 'in_review'),
      );

      await tester.pumpWidget(MaterialApp(
        home: TrainingPlanDetailWidget(
          introPlayerBuilder: (url) => Text('intro:$url'),
          planId: 'p1',
          currentUserId: 'admin',
          service: TrainingPlanService(repository: repository),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('admin-review-card')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('review-request-changes')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('review-note')), 'Film the squat from the side');
      await tester.tap(find.byKey(const ValueKey('send-review-note')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('review-approve')));
      await tester.pumpAndSettle();

      expect(repository.reviews, ['reject:Film the squat from the side', 'approve:']);
    });

    testWidgets('followers rate a plan; ratings show on the page', (tester) async {
      tallPhone(tester);
      tester.view.physicalSize = const Size(430, 2400);
      final p = complete(status: 'published');
      await WorkoutRoutineStore.importPlan(
          planKey: 'plan-p1', syncKey: 'k', routines: const [], schedule: const {});
      final repository = FakeRepository(
        plan: TrainingPlan(
          id: p.id, sellerId: p.sellerId, title: p.title, dayCount: p.dayCount,
          status: 'published', days: p.days, videos: p.videos,
          coverImageUrl: p.coverImageUrl, introVideo: p.introVideo,
          ratingAvg: 4.5, ratingCount: 2,
        ),
      )..ratingList = const [
          TrainingPlanRating(userId: 'x', rating: 5, comment: 'Loved the squat cues', authorName: 'Mia'),
        ];

      await tester.pumpWidget(MaterialApp(
        home: TrainingPlanDetailWidget(
          introPlayerBuilder: (url) => Text('intro:$url'),
          planId: 'p1',
          currentUserId: 'follower',
          service: TrainingPlanService(repository: repository),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('4.5 · 2 ratings'), findsOneWidget);
      expect(find.text('Loved the squat cues'), findsOneWidget);
      expect(find.text('intro:https://cdn.test/Intro/playlist.m3u8'), findsOneWidget,
          reason: 'the intro plays on the plan page right away');
      expect(find.byKey(const ValueKey('plan-creator')), findsOneWidget);
      expect(find.text('Plan days · tap an exercise to watch how'), findsOneWidget,
          reason: 'followers can watch exercise videos');
      expect(find.byKey(const ValueKey('share-plan')), findsOneWidget);
      expect(find.byKey(const ValueKey('report-plan')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('rate-plan')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('rate-star-4')));
      await tester.enterText(find.byKey(const ValueKey('rate-comment')), 'Solid plan');
      await tester.tap(find.byKey(const ValueKey('save-rating')));
      await tester.pumpAndSettle();

      expect(repository.rated, ['4:Solid plan']);
      // Let the dialog's delayed controller disposal run.
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('a plan without an intro shows its cover at the top', (tester) async {
      tallPhone(tester);
      final repository = FakeRepository(
          plan: plan(status: 'published', coverImageUrl: 'https://cdn.test/cover.jpg'));

      await tester.pumpWidget(MaterialApp(
        home: TrainingPlanDetailWidget(
          introPlayerBuilder: (url) => Text('intro:$url'),
          planId: 'p1',
          currentUserId: 'someone',
          service: TrainingPlanService(repository: repository),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('plan-cover-image')), findsOneWidget);
      expect(find.byKey(const ValueKey('plan-intro-video')), findsNothing);
    });

    testWidgets('admins feature published plans', (tester) async {
      tallPhone(tester);
      final repository = FakeRepository(admin: true, plan: complete(status: 'published'));

      await tester.pumpWidget(MaterialApp(
        home: TrainingPlanDetailWidget(
          introPlayerBuilder: (url) => Text('intro:$url'),
          planId: 'p1',
          currentUserId: 'admin',
          service: TrainingPlanService(repository: repository),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('toggle-featured')));
      await tester.pumpAndSettle();
      expect(repository.featuredCalls, [true]);
    });

    testWidgets('regular users see no admin controls', (tester) async {
      tallPhone(tester);
      final repository = FakeRepository(plan: complete(status: 'published'));

      await tester.pumpWidget(MaterialApp(
        home: TrainingPlanDetailWidget(
          introPlayerBuilder: (url) => Text('intro:$url'),
          planId: 'p1',
          currentUserId: 'someone',
          service: TrainingPlanService(repository: repository),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('admin-review-card')), findsNothing);
      expect(find.byKey(const ValueKey('toggle-featured')), findsNothing);
      expect(find.byKey(const ValueKey('rate-plan')), findsNothing,
          reason: 'only people who follow the plan can rate it');
      expect(find.byKey(const ValueKey('plan-intro-video')), findsOneWidget,
          reason: 'the intro video sits where the cover would be');
      expect(find.byKey(const ValueKey('plan-cover-image')), findsNothing);
      expect(find.byKey(const ValueKey('plan-creator')), findsOneWidget);
      expect(find.text('intro:https://cdn.test/Intro/playlist.m3u8'), findsOneWidget);
      expect(
          find.text('Plan days · exercise videos unlock when you add the plan to your Train'),
          findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('plan-day-1')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.play_circle_fill_rounded), findsNothing,
          reason: 'exercise names only until the plan is added');
      expect(find.byKey(const ValueKey('add-plan-to-train')), findsOneWidget);
    });
  });
}
