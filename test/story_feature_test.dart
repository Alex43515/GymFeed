import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_feed/backend/supabase/repositories/story_repository.dart';
import 'package:gym_feed/components/story_tray/story_tray_widget.dart';
import 'package:gym_feed/components/profile_story_avatar/profile_story_avatar_widget.dart';
import 'package:gym_feed/pages/core_pages/story/story_widget.dart';
import 'package:gym_feed/pages/core_pages/story_upload/story_upload_widget.dart';

void main() {
  test('story rows group by author with own first and unseen before seen', () {
    final now = DateTime.utc(2026, 8, 11, 12);
    final groups = groupStoryRows(
      currentUserId: 'me',
      seenStoryIds: {'seen-story'},
      playbackByAsset: const {'asset-video': 'https://cdn/video.m3u8'},
      profileRows: const [
        {
          'id': 'me',
          'username': 'alex',
          'display_name': 'Alex',
          'photo_url': 'me.jpg',
        },
        {
          'id': 'seen-user',
          'username': 'seen',
          'display_name': '',
          'photo_url': '',
        },
        {
          'id': 'new-user',
          'username': 'new',
          'display_name': '',
          'photo_url': '',
        },
      ],
      storyRows: [
        _storyRow('seen-story', 'seen-user', now,
            photoUrl: 'https://cdn/seen.jpg'),
        _storyRow('new-2', 'new-user', now.add(const Duration(minutes: 2)),
            videoAssetId: 'asset-video'),
        _storyRow('mine', 'me', now.add(const Duration(minutes: 3)),
            photoUrl: 'https://cdn/mine.jpg'),
        _storyRow('new-1', 'new-user', now.add(const Duration(minutes: 1)),
            photoUrl: 'https://cdn/new.jpg'),
      ],
    );

    expect(groups.map((group) => group.author.id),
        ['me', 'new-user', 'seen-user']);
    expect(groups[1].stories.map((story) => story.id), ['new-1', 'new-2']);
    expect(groups[1].stories.last.videoUrl, 'https://cdn/video.m3u8');
    expect(groups[1].hasUnseen, isTrue);
    expect(groups[2].allSeen, isTrue);
  });

  testWidgets('story tray presents own add action and following groups',
      (tester) async {
    final source = _FakeStorySource(groups: _groups());
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: StoryTrayWidget(repository: source)),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('my-story')), findsOneWidget);
    expect(find.byKey(const ValueKey('add-story')), findsOneWidget);
    expect(find.byKey(const ValueKey('story-group-coach')), findsOneWidget);
    expect(find.text('Your story'), findsOneWidget);
    expect(find.text('coach'), findsOneWidget);
  });

  testWidgets('viewer records receipts and advances through a story group',
      (tester) async {
    final source = _FakeStorySource(groups: _groups(), currentUser: 'viewer');
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: StoryWidget(
        groups: [source.groups.last],
        repository: source,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 150));

    expect(source.recorded, ['coach-1']);
    expect(find.text('coach'), findsOneWidget);

    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    await tester.tapAt(Offset(size.width * .8, size.height * .5));
    await tester.pump(const Duration(milliseconds: 150));
    expect(source.recorded, ['coach-1', 'coach-2']);
  });

  testWidgets('story composer exposes photo and video camera/gallery choices',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: StoryUploadWidget(repository: _FakeStorySource(groups: const [])),
      ),
    ));

    expect(find.byKey(const ValueKey('story-gallery-photo')), findsOneWidget);
    expect(find.byKey(const ValueKey('story-camera-photo')), findsOneWidget);
    expect(find.byKey(const ValueKey('story-gallery-video')), findsOneWidget);
    expect(find.byKey(const ValueKey('story-camera-video')), findsOneWidget);
  });

  testWidgets('profile story avatar opens the complete active group',
      (tester) async {
    final source = _FakeStorySource(groups: _groups(), currentUser: 'viewer');
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: ProfileStoryAvatarWidget(
          userId: 'coach',
          photoUrl: '',
          isCurrentUser: false,
          repository: source,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(source.loadedUsers, contains('coach'));

    final avatar = tester.widget<GestureDetector>(
      find.byKey(const ValueKey('profile-story-coach')),
    );
    avatar.onTap!.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(StoryWidget), findsOneWidget);
    expect(find.text('coach'), findsOneWidget);
    expect(source.recorded, ['coach-1']);
  });

  testWidgets('owner can delete a story without leaving a stale item',
      (tester) async {
    final source = _FakeStorySource(groups: _groups(), currentUser: 'coach');
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: StoryWidget(groups: [source.groups.last], repository: source),
    ));
    await tester.pump(const Duration(milliseconds: 150));

    await tester.tap(find.byKey(const ValueKey('delete-story')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pump(const Duration(milliseconds: 150));

    expect(source.deleted, ['coach-1']);
  });
}

Map<String, dynamic> _storyRow(
  String id,
  String userId,
  DateTime createdAt, {
  String photoUrl = '',
  String videoUrl = '',
  String? videoAssetId,
}) =>
    {
      'id': id,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'expires_at': createdAt.add(const Duration(hours: 24)).toIso8601String(),
      'legacy_photo_url': photoUrl,
      'legacy_video_url': videoUrl,
      'video_asset_id': videoAssetId,
    };

List<StoryGroup> _groups() {
  final now = DateTime.now();
  return [
    StoryGroup(
      author: const StoryAuthor(
        id: 'me',
        username: 'alex',
        displayName: 'Alex',
        photoUrl: '',
      ),
      stories: [
        StoryItem(
          id: 'mine',
          userId: 'me',
          photoUrl: 'https://example.invalid/mine.jpg',
          createdAt: now,
          expiresAt: now.add(const Duration(hours: 24)),
        ),
      ],
    ),
    StoryGroup(
      author: const StoryAuthor(
        id: 'coach',
        username: 'coach',
        displayName: 'Coach',
        photoUrl: '',
      ),
      stories: [
        StoryItem(
          id: 'coach-1',
          userId: 'coach',
          photoUrl: 'https://example.invalid/one.jpg',
          createdAt: now,
          expiresAt: now.add(const Duration(hours: 24)),
        ),
        StoryItem(
          id: 'coach-2',
          userId: 'coach',
          photoUrl: 'https://example.invalid/two.jpg',
          createdAt: now.add(const Duration(minutes: 1)),
          expiresAt: now.add(const Duration(hours: 24)),
        ),
      ],
    ),
  ];
}

class _FakeStorySource implements StoryDataSource {
  _FakeStorySource({required this.groups, this.currentUser = 'me'});

  final List<StoryGroup> groups;
  final String currentUser;
  final List<String> recorded = [];
  final List<String> deleted = [];
  final List<String> loadedUsers = [];

  @override
  String get currentUserId => currentUser;

  @override
  Future<List<StoryGroup>> loadTray() async => groups;

  @override
  Future<StoryGroup?> loadForUser(String userId) async {
    loadedUsers.add(userId);
    for (final group in groups) {
      if (group.author.id == userId) return group;
    }
    return null;
  }

  @override
  Future<StoryItem> create({
    String? photoAssetId,
    String? videoAssetId,
    String? photoUrl,
    String? videoUrl,
    DateTime? expiresAt,
  }) async =>
      StoryItem(
        id: 'created',
        userId: currentUser,
        photoUrl: photoUrl ?? '',
        videoUrl: videoUrl ?? '',
        createdAt: DateTime.now(),
        expiresAt: expiresAt ?? DateTime.now().add(const Duration(hours: 24)),
      );

  @override
  Future<void> delete(String storyId) async => deleted.add(storyId);

  @override
  Future<void> recordView(String storyId) async => recorded.add(storyId);

  @override
  Future<List<StoryViewerProfile>> viewerProfiles(String storyId) async =>
      const [];
}
