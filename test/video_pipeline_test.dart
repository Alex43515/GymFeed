import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_feed/custom_code/widgets/media_request_headers.dart';

void main() {
  group('real video upload pipeline', () {
    test('regular posts no longer generate or upload a GIF preview', () {
      final source = File('lib/pages/posts/new_post/new_post_widget.dart')
          .readAsStringSync();

      expect(source, contains('actions.pickAndPrepareVideo()'));
      expect(source, contains('videoAssetId: _videoAssetId'));
      expect(source, contains('uploadRes.videoThumbnailUrl'));
      expect(source, isNot(contains('generate2SecondVideoPreview(')));
      expect(source, isNot(contains('_model.previewVideo!.bytes!')));
    });

    test('food and workout videos use Bunny instead of the images bucket', () {
      final food = File(
        'lib/pages/posts/create_food_post/create_food_post_widget.dart',
      ).readAsStringSync();
      final training = File(
        'lib/workout/schedule_training/schedule_training_widget.dart',
      ).readAsStringSync();

      final foodVideoMethod = food.substring(
        food.indexOf('Future<void> _pickFoodVideo()'),
        food.indexOf('Future<void> _pickFoodPhoto()'),
      );
      final trainingVideoMethod = training.substring(
        training.indexOf('Future<void> _pickWorkoutVideo()'),
        training.indexOf('Future<void> _scheduleTraining()'),
      );

      for (final method in [foodVideoMethod, trainingVideoMethod]) {
        expect(method, contains('pickAndPrepareVideo'));
        expect(method, contains('showUploadProgress'));
        expect(method, contains('videoPlaylistUrl'));
        expect(method, isNot(contains('uploadData(')));
      }
      expect(food, contains('videoAssetId: _videoAssetId'));
      expect(training, contains('videoAssetId: _videoAssetId'));
    });

    test('home food posts use the retrying feed player with a thumbnail', () {
      final foodPost = File(
        'lib/pages/posts/post_food/post_food_widget.dart',
      ).readAsStringSync();

      expect(foodPost, contains('FeedVideoPlayer('));
      expect(foodPost, contains('videoThumbnail.isNotEmpty'));
      expect(foodPost, isNot(contains('FlutterFlowVideoPlayer(')));
      expect(foodPost, contains('FoodPostBadge'));
      expect(foodPost, contains('onTap: widget.isHomePage == true'));
      expect(foodPost, contains('PostDetailsWidget.routeName'));
    });

    test('website loads Hls.js and all shared players use the web HLS view',
        () {
      final html = File('web/index.html').readAsStringSync();
      final sharedPlayer = File(
        'lib/flutter_flow/flutter_flow_video_player.dart',
      ).readAsStringSync();
      final feedPlayer = File(
        'lib/custom_code/widgets/feed_video_player.dart',
      ).readAsStringSync();
      final reels = File(
        'lib/workout/video_reels/video_reels_widget.dart',
      ).readAsStringSync();

      expect(html, contains('hls.js@'));
      expect(sharedPlayer, contains('WebHlsVideoPlayer('));
      expect(feedPlayer, contains('WebHlsVideoPlayer('));
      expect(reels, contains('FeedVideoPlayer('));
      expect(reels, contains('videoFeed(limit: 60)'));
      expect(reels, isNot(contains("rpc('reels_page'")));
    });

    test('native Bunny playback carries the allowed GymFeed referrer', () {
      const bunnyUrl = 'https://vz-55fc89c2-aab.b-cdn.net/video/playlist.m3u8';

      expect(
        gymFeedMediaHeaders(bunnyUrl, isWebOverride: false),
        {'Referer': 'https://gymfeed.io/'},
      );
      expect(
        gymFeedMediaHeaders(bunnyUrl, isWebOverride: true),
        isEmpty,
      );
      expect(
        gymFeedMediaHeaders(
          'https://example.com/video.mp4',
          isWebOverride: false,
        ),
        isEmpty,
      );
    });

    test('feed playback replaces a stalled HLS initialization', () {
      final player = File(
        'lib/custom_code/widgets/feed_video_player.dart',
      ).readAsStringSync();

      expect(player, contains('c.initialize().timeout(_initializeTimeout)'));
      expect(player, contains('static const _maximumRetries = 20'));
      expect(player, contains("_retryCount < _maximumRetries"));
    });

    test('Home feed returns the video playback URL, never its thumbnail', () {
      final migration = File(
        'supabase/migrations/0024_feed_video_playback_url.sql',
      ).readAsStringSync();

      expect(
        migration,
        contains("coalesce(nullif(ma_video.playback_url, ''), "
            'p.legacy_video_url)'),
      );
      expect(
        migration,
        isNot(contains('coalesce(ma_video.thumbnail_url, '
            'p.legacy_video_url)')),
      );
    });

    test('post rows expose one share action, backed by the full share sheet',
        () {
      for (final path in [
        'lib/pages/posts/post/post_widget.dart',
        'lib/pages/posts/post_food/post_food_widget.dart',
      ]) {
        final source = File(path).readAsStringSync();
        expect(source, contains('SendPostWidget('));
        expect(source, isNot(contains('Icons.share')));
        expect(source, isNot(contains('shareGymFeedPost(')));
      }
    });

    test('legacy Bunny videos are reconciled to their media asset', () {
      final migration = File(
        'supabase/migrations/0020_video_asset_reconciliation.sql',
      ).readAsStringSync();

      expect(migration, contains('update public.posts'));
      expect(migration, contains('video_asset_id'));
      expect(migration, contains('bunny_video_guid'));
      expect(migration, contains('thumbnail_url'));
    });
  });
}
