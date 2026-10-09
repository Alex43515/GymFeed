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
    );

class FakeRepository extends TrainingPlanRepository {
  FakeRepository({this.plan, this.admin = false});

  TrainingPlan? plan;
  final bool admin;
  final reviews = <String>[];
  final submitted = <String>[];
  List<PlanExerciseVideo>? savedVideos;

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
  }) async {
    savedVideos = videos.toList();
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
    testWidgets('lists each exercise once and saves uploaded videos', (tester) async {
      tallPhone(tester);
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
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('plan-video-row-Squat')), findsOneWidget);
      expect(find.byKey(const ValueKey('plan-video-row-Bench Press')), findsOneWidget);
      expect(find.text('2 still needed'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('upload-plan-video-Squat')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('upload-plan-video-Bench Press')));
      await tester.pumpAndSettle();

      expect(uploads, ['Squat', 'Bench Press']);
      expect(find.text('All set'), findsOneWidget);
      expect(find.text('Video added · processing'), findsNWidgets(2));

      await tester.tap(find.byKey(const ValueKey('save-training-plan')));
      await tester.pumpAndSettle();
      expect(repository.savedVideos!.map((v) => v.assetId),
          ['asset-Squat', 'asset-Bench Press']);
    });
  });

  group('plan page', () {
    testWidgets('owner cannot submit while videos are missing', (tester) async {
      tallPhone(tester);
      final repository = FakeRepository(plan: plan(videos: {'squat': video('Squat')}));

      await tester.pumpWidget(MaterialApp(
        home: TrainingPlanDetailWidget(
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
      expect(find.textContaining('Bench Press still needs a video'), findsOneWidget);
    });

    testWidgets('admins approve or send back plans waiting for review', (tester) async {
      tallPhone(tester);
      final repository = FakeRepository(
        admin: true,
        plan: plan(status: 'in_review', videos: {
          'squat': video('Squat'),
          'bench press': video('Bench Press'),
        }),
      );

      await tester.pumpWidget(MaterialApp(
        home: TrainingPlanDetailWidget(
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

    testWidgets('regular users see no admin controls', (tester) async {
      tallPhone(tester);
      final repository = FakeRepository(
          plan: plan(status: 'published', videos: {'squat': video('Squat')}));

      await tester.pumpWidget(MaterialApp(
        home: TrainingPlanDetailWidget(
          planId: 'p1',
          currentUserId: 'someone',
          service: TrainingPlanService(repository: repository),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('admin-review-card')), findsNothing);
      expect(find.byKey(const ValueKey('add-plan-to-train')), findsOneWidget);
    });
  });
}
