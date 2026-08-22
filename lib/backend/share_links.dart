import 'dart:ui' show Rect;

import 'package:share_plus/share_plus.dart';

const gymFeedAppScheme = 'com.flutterflow.gymfeedofficial';
const gymFeedWebOrigin = 'https://gymfeed.io';

String gymFeedPostShareUrl(String postId) {
  final id = postId.trim();
  if (id.isEmpty) throw ArgumentError.value(postId, 'postId');
  return '$gymFeedWebOrigin/post/${Uri.encodeComponent(id)}';
}

String gymFeedPostDeepLink(String postId) {
  final id = postId.trim();
  if (id.isEmpty) throw ArgumentError.value(postId, 'postId');
  return Uri(
    scheme: gymFeedAppScheme,
    path: '/postDetails',
    queryParameters: {'post': id},
  ).toString();
}

String gymFeedPostShareText({
  required String postId,
  String title = 'GymFeed post',
}) {
  final cleanTitle = title.trim().isEmpty ? 'GymFeed post' : title.trim();
  return 'Check out this GymFeed post: $cleanTitle\n'
      '${gymFeedPostShareUrl(postId)}';
}

Future<void> shareGymFeedPost({
  required String postId,
  String title = 'GymFeed post',
  Rect? sharePositionOrigin,
}) {
  return Share.share(
    gymFeedPostShareText(postId: postId, title: title),
    subject: title.trim().isEmpty ? 'GymFeed post' : title.trim(),
    sharePositionOrigin: sharePositionOrigin,
  );
}
