// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// HTML5/Hls.js playback for Flutter Web.
///
/// Chrome/Edge/Firefox do not natively decode Bunny's `.m3u8` manifests.
/// `video_player_web` consequently leaves the poster visible. This platform
/// view uses native HLS on Safari and Hls.js everywhere else.
class WebHlsVideoPlayer extends StatefulWidget {
  const WebHlsVideoPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.autoPlay = false,
    this.looping = false,
    this.muted = false,
    this.showControls = true,
    this.fit = BoxFit.cover,
  });

  final String videoUrl;
  final String? thumbnailUrl;
  final bool autoPlay;
  final bool looping;
  final bool muted;
  final bool showControls;
  final BoxFit fit;

  @override
  State<WebHlsVideoPlayer> createState() => _WebHlsVideoPlayerState();
}

class _WebHlsVideoPlayerState extends State<WebHlsVideoPlayer> {
  late final String _viewType;
  late final html.VideoElement _video;
  dynamic _hls;
  StreamSubscription<html.Event>? _errorSub;
  Timer? _retryTimer;
  int _retryCount = 0;

  bool get _isHls =>
      Uri.tryParse(widget.videoUrl)?.path.toLowerCase().endsWith('.m3u8') ??
      false;

  @override
  void initState() {
    super.initState();
    _viewType = 'gymfeed-hls-${identityHashCode(this)}';
    _video = html.VideoElement()
      ..setAttribute('playsinline', 'true')
      ..setAttribute('webkit-playsinline', 'true');
    _applyPresentation();
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (_) => _video,
    );
    _errorSub = _video.onError.listen((_) => _scheduleRetry());
    _loadSource();
  }

  @override
  void didUpdateWidget(covariant WebHlsVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applyPresentation();
    if (oldWidget.videoUrl != widget.videoUrl) {
      _retryCount = 0;
      _loadSource();
    } else if (widget.autoPlay && !oldWidget.autoPlay) {
      _playSafely();
    } else if (!widget.autoPlay && oldWidget.autoPlay) {
      _video.pause();
    }
  }

  void _applyPresentation() {
    _video
      ..controls = widget.showControls
      ..autoplay = widget.autoPlay
      ..loop = widget.looping
      ..muted = widget.muted
      ..poster = widget.thumbnailUrl ?? '';
    _video.style
      ..width = '100%'
      ..height = '100%'
      ..display = 'block'
      ..backgroundColor = '#000'
      ..objectFit = widget.fit == BoxFit.contain ? 'contain' : 'cover';
  }

  void _destroyHls() {
    final hls = _hls;
    _hls = null;
    if (hls != null) {
      try {
        js_util.callMethod<void>(hls, 'destroy', const []);
      } catch (_) {}
    }
  }

  void _loadSource() {
    _retryTimer?.cancel();
    _destroyHls();
    _video
      ..pause()
      ..removeAttribute('src')
      ..load();

    if (_isHls && _video.canPlayType('application/vnd.apple.mpegurl').isEmpty) {
      try {
        final hlsConstructor = js_util.getProperty<dynamic>(html.window, 'Hls');
        final supported = hlsConstructor != null &&
            js_util.callMethod<bool>(hlsConstructor, 'isSupported', const []);
        if (supported) {
          final hls =
              js_util.callConstructor<dynamic>(hlsConstructor, const []);
          _hls = hls;
          js_util.callMethod<void>(hls, 'loadSource', [widget.videoUrl]);
          js_util.callMethod<void>(hls, 'attachMedia', [_video]);
          if (widget.autoPlay) _playSafely();
          return;
        }
      } catch (_) {
        // Fall through to the browser source assignment. Safari supports HLS
        // natively; a retry also covers a late-loading Hls.js script.
      }
    }

    _video.src = widget.videoUrl;
    _video.load();
    if (widget.autoPlay) _playSafely();
  }

  void _playSafely() {
    _video.play().catchError((_) {});
  }

  void _scheduleRetry() {
    if (_retryCount >= 8 || _retryTimer?.isActive == true) return;
    _retryCount++;
    final seconds = _retryCount < 4 ? 3 : 7;
    _retryTimer = Timer(Duration(seconds: seconds), _loadSource);
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _errorSub?.cancel();
    _destroyHls();
    _video
      ..pause()
      ..removeAttribute('src')
      ..load();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
