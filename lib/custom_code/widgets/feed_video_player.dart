import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'gym_feed_video_controls.dart';
import 'media_request_headers.dart';
import 'web_hls_video_player.dart';

/// Instagram-style feed video.
///
/// * Autoplays (muted) once the tile is >60% on-screen, pauses when it leaves.
/// * The player is created lazily on first visibility and disposed with the
///   widget, so a long feed only ever holds a handful of controllers.
/// * A tap toggles nothing destructive — it calls [onTap] to open the post.
/// * A small speaker button mutes/unmutes without leaving the feed.
/// * Fills whatever box the parent gives it (wrap it in a sized container),
///   with the frame cover-fitted inside — like IG — so the list height is
///   stable and there are no scroll jumps as videos initialize.
class FeedVideoPlayer extends StatefulWidget {
  const FeedVideoPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.onTap,
    this.borderRadius = 16.0,
  });

  final String videoUrl;
  final String? thumbnailUrl;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  static const _initializeTimeout = Duration(seconds: 10);
  static const _maximumRetries = 20;

  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _muted = true;
  bool _visible = false;
  bool _disposed = false;
  Timer? _retryTimer;
  int _retryCount = 0;

  bool get _useWebHls =>
      kIsWeb &&
      (Uri.tryParse(widget.videoUrl)?.path.toLowerCase().endsWith('.m3u8') ??
          false);

  @override
  void initState() {
    super.initState();
    // New uploads are Bunny HLS streams and take slightly longer to prepare
    // than the seeded MP4 files. Start initialization as soon as the lazy feed
    // tile is built instead of leaving the poster dependent on a later
    // VisibilityDetector callback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) _ensureController();
    });
  }

  Future<void> _ensureController() async {
    if (_useWebHls || _controller != null || widget.videoUrl.isEmpty) return;
    final c = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
      httpHeaders: gymFeedMediaHeaders(widget.videoUrl),
    );
    _controller = c;
    try {
      // ExoPlayer can leave an HLS initialization Future pending when the
      // Bunny manifest is requested during the final moments of transcoding.
      // A detail page works in that situation because it creates a fresh
      // controller, while the feed used to keep the original pending one
      // forever. Bound every attempt so the feed can recreate the data source.
      await c.initialize().timeout(_initializeTimeout);
      if (_disposed) {
        c.dispose();
        return;
      }
      await c.setLooping(true);
      await c.setVolume(_muted ? 0.0 : 1.0);
      _retryCount = 0;
      if (mounted) setState(() => _initialized = true);
      if (_visible) c.play();
    } catch (_) {
      if (_controller == c) _controller = null;
      await c.dispose();
      if (!_disposed && _retryCount < _maximumRetries) {
        _retryCount++;
        _retryTimer?.cancel();
        _retryTimer = Timer(
          Duration(seconds: _retryCount < 4 ? 2 : 5),
          _ensureController,
        );
      }
    }
  }

  void _onVisibility(VisibilityInfo info) {
    final visible = info.visibleFraction > 0.6;
    if (visible == _visible) return;
    _visible = visible;
    if (_useWebHls) {
      if (mounted) setState(() {});
      return;
    }
    if (visible) {
      // Cancel a delayed retry and try immediately when the tile becomes
      // visible. The per-attempt timeout above will replace a stalled source.
      _retryTimer?.cancel();
      _ensureController().then((_) {
        if (!_disposed && _visible) _controller?.play();
      });
    } else {
      _controller?.pause();
    }
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _controller?.setVolume(_muted ? 0.0 : 1.0);
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isCompleted) controller.seekTo(Duration.zero);
    controller.value.isPlaying ? controller.pause() : controller.play();
  }

  void _stop() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    controller.pause();
    controller.seekTo(Duration.zero);
  }

  @override
  void didUpdateWidget(covariant FeedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _retryTimer?.cancel();
      _retryCount = 0;
      _initialized = false;
      final old = _controller;
      _controller = null;
      old?.dispose();
      if (_visible) _ensureController();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('feedvid-${widget.videoUrl}'),
      onVisibilityChanged: _onVisibility,
      child: _useWebHls
          ? ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: WebHlsVideoPlayer(
                videoUrl: widget.videoUrl,
                thumbnailUrl: widget.thumbnailUrl,
                autoPlay: _visible,
                looping: true,
                muted: _muted,
                showControls: true,
                fit: BoxFit.cover,
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: GestureDetector(
                onDoubleTap: widget.onTap,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Poster/thumbnail — shown until the first frame is ready.
                    if ((widget.thumbnailUrl ?? '').isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: widget.thumbnailUrl!,
                        httpHeaders: gymFeedMediaHeaders(widget.thumbnailUrl!),
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: Colors.black12),
                        errorWidget: (_, __, ___) =>
                            Container(color: Colors.black),
                      )
                    else
                      Container(color: Colors.black),
                    if (!_initialized)
                      const IgnorePointer(
                        child: Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0x99000000),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: SizedBox(
                                key: Key('feed-video-loading'),
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_initialized && _controller != null)
                      FittedBox(
                        fit: BoxFit.cover,
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: _controller!.value.size.width,
                          height: _controller!.value.size.height,
                          child: VideoPlayer(_controller!),
                        ),
                      ),
                    if (_initialized && _controller != null)
                      GymFeedVideoControls(
                        valueListenable: _controller!,
                        onPlayPause: _togglePlay,
                        onStop: _stop,
                        onToggleMute: _toggleMute,
                        onSeek: _controller!.seekTo,
                        controlKeyPrefix: 'feed-video',
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
