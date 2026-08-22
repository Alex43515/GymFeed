import 'dart:async';

import 'package:app_links/app_links.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import '../marketing/marketing_attribution.dart';
import 'package:flutter/material.dart';

const _kGymFeedWebOrigin = 'https://gymfeed.io';

Future<String> generateCurrentPageLink(
  BuildContext context, {
  String? title,
  String? description,
  String? imageUrl,
  bool isShortLink = true,
  bool forceRedirect = false,
}) async {
  final location = GoRouterState.of(context).uri;
  return Uri.parse(_kGymFeedWebOrigin).resolveUri(location).toString();
}

class DynamicLinksHandler extends StatefulWidget {
  const DynamicLinksHandler({
    Key? key,
    required this.router,
    required this.child,
  }) : super(key: key);

  final GoRouter router;
  final Widget child;

  @override
  _DynamicLinksHandlerState createState() => _DynamicLinksHandlerState();
}

class _DynamicLinksHandlerState extends State<DynamicLinksHandler> {
  StreamSubscription<Uri>? appLinkSubscription;
  final AppLinks _appLinks = AppLinks();
  String? _initialAppLink;

  void _handleAppLink(Uri uri) {
    unawaited(captureMarketingAttribution(uri));
    final location = appLocationFromIncomingLink(uri);
    if (location.isNotEmpty && widget.router.getCurrentLocation() != location) {
      widget.router.push(location);
    }
  }

  Future<void> handleAppLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _initialAppLink = initial.toString();
        _handleAppLink(initial);
      }
    } catch (error) {
      debugPrint('Initial app link handling failed: $error');
    }
    appLinkSubscription ??= _appLinks.uriLinkStream.listen(
      (uri) {
        // Some platforms replay getInitialLink() as the first stream event.
        if (_initialAppLink == uri.toString()) {
          _initialAppLink = null;
          return;
        }
        _handleAppLink(uri);
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('App link handling failed: $error');
      },
    );
  }

  @override
  void initState() {
    super.initState();
    if (!isWeb) {
      unawaited(handleAppLinks());
    }
  }

  @override
  void dispose() {
    appLinkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

String appLocationFromIncomingLink(Uri uri) {
  if (uri.scheme == 'com.flutterflow.gymfeedofficial') {
    // Prefer a path-style custom URI (`scheme:/postDetails`). Also accept the
    // older host-style form (`scheme://postDetails`) for links already shared.
    var path = uri.path.isNotEmpty
        ? uri.path
        : uri.host.isNotEmpty
            ? '/${uri.host}'
            : '/';
    path = switch (path.toLowerCase()) {
      '/postdetails' => '/postDetails',
      '/authcallback' => '/authCallback',
      '/emailverification' => '/emailVerification',
      '/changepassword' => '/changePassword',
      _ => path,
    };
    return Uri(path: path, queryParameters: uri.queryParameters).toString();
  }

  final isGymFeedWebLink = (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.toLowerCase() == 'gymfeed.io';
  if (isGymFeedWebLink && uri.pathSegments.length == 2) {
    final section = uri.pathSegments.first.toLowerCase();
    final postId = uri.pathSegments.last.trim();
    if (section == 'post' && postId.isNotEmpty) {
      return Uri(
        path: '/postDetails',
        queryParameters: {'post': postId},
      ).toString();
    }
  }

  final path = uri.path.isEmpty ? '/' : uri.path;
  return uri.queryParameters.isEmpty
      ? path
      : Uri(path: path, queryParameters: uri.queryParameters).toString();
}
