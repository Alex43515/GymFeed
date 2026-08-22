import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:gym_feed/custom_code/widgets/feed_video_player.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the newest uploaded feed HLS video initializes on Android',
      (tester) async {
    const videoUrl =
        'https://vz-55fc89c2-aab.b-cdn.net/e3f4685e-b619-413e-a0fb-31c4818f3e57/playlist.m3u8';
    const thumbnailUrl =
        'https://vz-55fc89c2-aab.b-cdn.net/e3f4685e-b619-413e-a0fb-31c4818f3e57/thumbnail.jpg';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
              SliverToBoxAdapter(
                child: SizedBox(
                  width: 360,
                  height: 520,
                  child: FeedVideoPlayer(
                    videoUrl: videoUrl,
                    thumbnailUrl: thumbnailUrl,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('feed-video-loading')), findsOneWidget);

    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find
          .byKey(const Key('feed-video-play-pause'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(find.byKey(const Key('feed-video-play-pause')), findsOneWidget);
    expect(find.byKey(const Key('feed-video-progress')), findsOneWidget);
    expect(find.byKey(const Key('feed-video-loading')), findsNothing);
  });
}
