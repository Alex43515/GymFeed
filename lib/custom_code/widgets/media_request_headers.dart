import 'package:flutter/foundation.dart';

const String gymFeedMediaReferrer = 'https://gymfeed.io/';

/// Bunny's GymFeed pull zone uses hotlink protection. Browsers provide the
/// website referrer themselves, but native video/image clients do not, so
/// Android and iOS must attach the same allowed referrer explicitly.
Map<String, String> gymFeedMediaHeaders(
  String url, {
  bool? isWebOverride,
}) {
  final isWebClient = isWebOverride ?? kIsWeb;
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  final isBunnyMedia = host == 'b-cdn.net' || host.endsWith('.b-cdn.net');
  if (isWebClient || !isBunnyMedia) return const <String, String>{};
  return const <String, String>{'Referer': gymFeedMediaReferrer};
}
