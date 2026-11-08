import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

const gymFeedAppScheme = 'com.flutterflow.gymfeedofficial';
const gymFeedWebOrigin = 'https://gymfeed.io';

/// Where the share sheet is anchored. iPads and iPhones on iOS 26 refuse to
/// open it without a non-empty rectangle inside the screen, and throw instead.
Rect shareSheetOrigin([BuildContext? context]) {
  final box = context?.findRenderObject();
  if (box is RenderBox && box.hasSize && !box.size.isEmpty) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final size = view.physicalSize / view.devicePixelRatio;
  return Rect.fromCenter(center: size.center(Offset.zero), width: 2, height: 2);
}

/// Opens the profile in the app (App Links and Universal Links), or a landing
/// page with the store buttons when GymFeed is not installed.
String gymFeedProfileShareUrl(String username) {
  final handle = username.trim().replaceFirst(RegExp(r'^@+'), '');
  if (handle.isEmpty) throw ArgumentError.value(username, 'username');
  return '$gymFeedWebOrigin/u/${Uri.encodeComponent(handle)}';
}

Future<void> shareGymFeedProfile({
  required String username,
  String displayName = '',
  Rect? sharePositionOrigin,
}) {
  final handle = username.trim().replaceFirst(RegExp(r'^@+'), '');
  final name = displayName.trim().isEmpty ? '@$handle' : displayName.trim();
  return Share.share(
    'View @$handle on GymFeed\n${gymFeedProfileShareUrl(handle)}',
    subject: '$name on GymFeed',
    sharePositionOrigin: sharePositionOrigin ?? shareSheetOrigin(),
  );
}

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

/// Opens the plan in the app (Android App Links) or the GymFeed web app.
String gymFeedTrainingPlanShareUrl(String planId) {
  final id = planId.trim();
  if (id.isEmpty) throw ArgumentError.value(planId, 'planId');
  return Uri.parse('$gymFeedWebOrigin/trainingPlan')
      .replace(queryParameters: {'id': id}).toString();
}

Future<void> shareGymFeedTrainingPlan({
  required String planId,
  required String title,
  Rect? sharePositionOrigin,
}) {
  final cleanTitle = title.trim().isEmpty ? 'Training plan' : title.trim();
  return Share.share(
    'Check out this training plan on GymFeed: $cleanTitle\n'
    '${gymFeedTrainingPlanShareUrl(planId)}',
    subject: cleanTitle,
    sharePositionOrigin: sharePositionOrigin,
  );
}

const gymFeedDownloadUrl = '$gymFeedWebOrigin/download';

/// Text a user sends to bring a friend (gym partner) to GymFeed.
///
/// With the sender's username it tells the friend to enter it under
/// "Who invited you?" at sign-up, which is what gives both of them the
/// referral bonus (server function redeem_invite: +7 days each, up to 4
/// friends). Every invite button uses this text.
String gymFeedInviteText({String username = '', int bonusDays = 7}) {
  final handle = username.trim().replaceFirst(RegExp(r'^@+'), '');
  final enter = handle.isEmpty
      ? ''
      : ' When you sign up, enter @$handle under "Who invited you?" and we '
          'both get $bonusDays extra days of Premium.';
  return 'Join me on GymFeed, the app that keeps me on track at the gym. '
      'The first 1,000 members get Founding perks.$enter\n'
      '$gymFeedDownloadUrl';
}

Future<void> shareGymFeedInvite({
  String username = '',
  Rect? sharePositionOrigin,
}) {
  return Share.share(
    gymFeedInviteText(username: username),
    subject: 'Join me on GymFeed',
    sharePositionOrigin: sharePositionOrigin ?? shareSheetOrigin(),
  );
}
