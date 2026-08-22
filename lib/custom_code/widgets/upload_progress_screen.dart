// Custom upload progress screen.
//
// A reusable, theme-aware full-screen overlay that drives a media upload and
// shows live progress. Handles both images (Supabase Storage) and videos
// (Bunny Stream TUS, with real byte progress + a short "processing" wait).
//
// Usage from any widget/action:
//
//   // photo
//   final res = await showUploadProgress(context, imageBytes: bytes,
//       imageFileName: file.name);
//   if (res?.imageUrl != null) { /* use res!.imageUrl */ }
//
//   // video (pass the compressed video bytes)
//   final res = await showUploadProgress(context, videoBytes: bytes,
//       videoTitle: 'My reel');
//   if (res?.videoPlaylistUrl != null) { /* store the HLS url / assetId */ }

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/backend/firebase_storage/storage.dart';
import '/backend/supabase/repositories/media_repository.dart';
import '/custom_code/actions/upload_video_to_bunny.dart';

/// Outcome of an upload. On success either [imageUrl] (photo) or the video
/// fields are set; [error] is set on failure.
class UploadResult {
  const UploadResult({
    this.imageUrl,
    this.videoAssetId,
    this.videoPlaylistUrl,
    this.videoThumbnailUrl,
    this.error,
  });

  final String? imageUrl;
  final String? videoAssetId;
  final String? videoPlaylistUrl;
  final String? videoThumbnailUrl;
  final String? error;

  bool get success =>
      error == null && (imageUrl != null || videoAssetId != null);
}

/// Shows a full-screen upload-progress overlay and completes with the result
/// once the upload finishes (or `null` if the user closes a failed upload).
///
/// Provide EITHER [imageBytes] (a photo) OR [videoBytes] (a compressed video).
Future<UploadResult?> showUploadProgress(
  BuildContext context, {
  Uint8List? imageBytes,
  String imageFileName = 'photo.jpg',
  Uint8List? videoBytes,
  String videoTitle = 'GymFeed video',
  String videoFileName = 'gymfeed-video.mp4',
}) {
  assert(
    imageBytes != null || videoBytes != null,
    'showUploadProgress needs either imageBytes or videoBytes.',
  );
  return showGeneralDialog<UploadResult>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Uploading',
    barrierColor: Colors.black.withOpacity(0.82),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => UploadProgressScreen(
      imageBytes: imageBytes,
      imageFileName: imageFileName,
      videoBytes: videoBytes,
      videoTitle: videoTitle,
      videoFileName: videoFileName,
    ),
    transitionBuilder: (_, anim, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: child,
    ),
  );
}

enum _Phase { uploading, processing, done, failed }

class UploadProgressScreen extends StatefulWidget {
  const UploadProgressScreen({
    super.key,
    this.imageBytes,
    this.imageFileName = 'photo.jpg',
    this.videoBytes,
    this.videoTitle = 'GymFeed video',
    this.videoFileName = 'gymfeed-video.mp4',
  });

  final Uint8List? imageBytes;
  final String imageFileName;
  final Uint8List? videoBytes;
  final String videoTitle;
  final String videoFileName;

  bool get isVideo => videoBytes != null;

  @override
  State<UploadProgressScreen> createState() => _UploadProgressScreenState();
}

class _UploadProgressScreenState extends State<UploadProgressScreen> {
  _Phase _phase = _Phase.uploading;
  double _progress = 0.0;
  String? _error;
  Timer? _imageTicker;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _imageTicker?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _phase = _Phase.uploading;
      _progress = 0.0;
      _error = null;
    });
    try {
      if (widget.isVideo) {
        await _uploadVideo();
      } else {
        await _uploadImage();
      }
    } catch (e) {
      _fail(e.toString());
    }
  }

  Future<void> _uploadVideo() async {
    final ticket = await uploadVideoToBunny(
      widget.videoBytes!,
      widget.videoTitle,
      fileName: widget.videoFileName,
      onProgress: (p) async {
        if (mounted) setState(() => _progress = p.clamp(0.0, 1.0));
      },
    );

    // Bytes are with Bunny; give encoding a short window to finish so the HLS
    // URL is playable the moment the post is created. We don't wait forever —
    // if the webhook is slow, we proceed (the URL becomes valid shortly after).
    if (mounted) {
      setState(() {
        _phase = _Phase.processing;
        _progress = 1.0;
      });
    }
    await _awaitReady(ticket.assetId);

    _succeed(UploadResult(
      videoAssetId: ticket.assetId,
      videoPlaylistUrl: ticket.playlistUrl,
      videoThumbnailUrl: ticket.thumbnailUrl,
    ));
  }

  /// Waits (bounded) for the media asset to reach `ready`/`failed` via Realtime.
  Future<void> _awaitReady(String assetId) async {
    final completer = Completer<void>();
    StreamSubscription<dynamic>? sub;
    Timer? timeout;

    void finish() {
      if (!completer.isCompleted) completer.complete();
    }

    timeout = Timer(const Duration(seconds: 25), finish);
    sub = MediaRepository().watchAsset(assetId).listen(
      (row) {
        final status = row?['status'];
        if (status == 'ready' || status == 'failed') finish();
      },
      onError: (_) => finish(),
    );

    await completer.future;
    timeout.cancel();
    await sub.cancel();
  }

  Future<void> _uploadImage() async {
    // Supabase's uploadBinary doesn't surface byte progress, so ease a smooth
    // bar toward ~92% while the request is in flight, then snap to 100%.
    _imageTicker = Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (!mounted) return;
      setState(() {
        _progress += (0.92 - _progress) * 0.08 + 0.004;
        if (_progress > 0.92) _progress = 0.92;
      });
    });

    final url = await uploadData(widget.imageFileName, widget.imageBytes!);

    _imageTicker?.cancel();
    if (url == null) {
      _fail('The photo could not be uploaded. Please try again.');
      return;
    }
    if (mounted) setState(() => _progress = 1.0);
    _succeed(UploadResult(imageUrl: url));
  }

  void _succeed(UploadResult result) {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.done;
      _progress = 1.0;
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  void _fail(String message) {
    if (!mounted) return;
    _imageTicker?.cancel();
    setState(() {
      _phase = _Phase.failed;
      _error = message;
    });
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  static const _green = Color(0xFF39D98A);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.28),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _preview(theme),
                  const SizedBox(height: 20),
                  _title(theme),
                  const SizedBox(height: 6),
                  _subtitle(theme),
                  const SizedBox(height: 20),
                  if (_phase == _Phase.failed)
                    _failureActions(theme)
                  else
                    _progressBar(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _preview(FlutterFlowTheme theme) {
    Widget inner;
    if (!widget.isVideo && widget.imageBytes != null) {
      inner = Image.memory(widget.imageBytes!, fit: BoxFit.cover);
    } else {
      inner = Container(
        color: theme.primary.withOpacity(0.12),
        child: Icon(Icons.videocam_rounded, color: theme.primary, size: 34),
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(width: 84, height: 84, child: inner),
        ),
        if (_phase == _Phase.done)
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.check_rounded, color: _green, size: 40),
          ),
        if (_phase == _Phase.failed)
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                Icon(Icons.error_outline_rounded, color: theme.error, size: 38),
          ),
      ],
    );
  }

  Widget _title(FlutterFlowTheme theme) {
    final label = switch (_phase) {
      _Phase.done => widget.isVideo ? 'Video uploaded' : 'Photo uploaded',
      _Phase.failed => 'Upload failed',
      _Phase.processing => 'Processing video',
      _ => widget.isVideo ? 'Uploading video' : 'Uploading photo',
    };
    return Text(
      label,
      textAlign: TextAlign.center,
      style: theme.titleMedium.override(
        fontFamily: theme.titleMediumFamily,
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _subtitle(FlutterFlowTheme theme) {
    final text = switch (_phase) {
      _Phase.done => widget.isVideo ? 'Ready to post.' : 'All done!',
      _Phase.failed => _error ?? 'Something went wrong.',
      _Phase.processing => 'Optimising your video for playback…',
      _ => widget.isVideo
          ? 'Keep the app open while we upload.'
          : 'Just a moment…',
    };
    return Text(
      text,
      textAlign: TextAlign.center,
      style: theme.bodySmall.override(
        fontFamily: theme.bodySmallFamily,
        color: theme.secondaryText,
      ),
    );
  }

  Widget _progressBar(FlutterFlowTheme theme) {
    final indeterminate = _phase == _Phase.processing;
    final pct = (_progress * 100).round();
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: indeterminate
                ? null
                : (_phase == _Phase.done ? 1.0 : _progress),
            minHeight: 8,
            backgroundColor: theme.primaryText.withOpacity(0.10),
            valueColor: AlwaysStoppedAnimation<Color>(
              _phase == _Phase.done ? _green : theme.primary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          indeterminate
              ? 'Almost there…'
              : (_phase == _Phase.done ? '100%' : '$pct%'),
          style: theme.bodySmall.override(
            fontFamily: theme.bodySmallFamily,
            color: theme.secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _failureActions(FlutterFlowTheme theme) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(
              UploadResult(error: _error ?? 'cancelled'),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.primaryText.withOpacity(0.18)),
              ),
            ),
            child: Text(
              'Close',
              style: theme.bodyMedium.override(
                fontFamily: theme.bodyMediumFamily,
                color: theme.secondaryText,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextButton(
            onPressed: _start,
            style: TextButton.styleFrom(
              backgroundColor: theme.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Retry',
              style: theme.bodyMedium.override(
                fontFamily: theme.bodyMediumFamily,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
