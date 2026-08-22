import 'package:flutter/material.dart';

/// Non-web placeholder. Callers only construct this widget when `kIsWeb`.
class WebHlsVideoPlayer extends StatelessWidget {
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
  Widget build(BuildContext context) => const ColoredBox(color: Colors.black);
}
