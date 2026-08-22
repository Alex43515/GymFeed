import 'package:flutter_test/flutter_test.dart';

import 'package:gym_feed/backend/firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:gym_feed/backend/share_links.dart';

void main() {
  const postId = '11111111-2222-4333-8444-555555555555';

  test('external post share uses the verified GymFeed website', () {
    final uri = Uri.parse(gymFeedPostShareUrl(postId));

    expect(uri.scheme, 'https');
    expect(uri.host, 'gymfeed.io');
    expect(uri.path, '/post/$postId');
    expect(gymFeedPostShareText(postId: postId, title: 'Push day'),
        contains(uri.toString()));
  });

  test('post app link resolves to the exact PostDetails route', () {
    final appUri = Uri.parse(gymFeedPostDeepLink(postId));
    expect(appLocationFromIncomingLink(appUri), '/postDetails?post=$postId');
  });

  test('host-style legacy custom links also resolve correctly', () {
    final uri =
        Uri.parse('com.flutterflow.gymfeedofficial://postDetails?post=$postId');
    expect(appLocationFromIncomingLink(uri), '/postDetails?post=$postId');
  });

  test('verified website post links resolve to the exact PostDetails route',
      () {
    final uri = Uri.parse('https://gymfeed.io/post/$postId');
    expect(appLocationFromIncomingLink(uri), '/postDetails?post=$postId');
  });

  test('unrelated website paths stay as website paths', () {
    final uri = Uri.parse('https://gymfeed.io/privacy/');
    expect(appLocationFromIncomingLink(uri), '/privacy/');
  });
}
