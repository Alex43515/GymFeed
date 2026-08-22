import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Shared, centered controls for every GymFeed video surface.
class GymFeedVideoControls extends StatelessWidget {
  const GymFeedVideoControls({
    super.key,
    required this.valueListenable,
    required this.onPlayPause,
    required this.onStop,
    required this.onToggleMute,
    required this.onSeek,
    this.onFullScreen,
    this.bottomInset = 0,
    this.controlKeyPrefix = 'video',
  });

  final ValueListenable<VideoPlayerValue> valueListenable;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final VoidCallback onToggleMute;
  final ValueChanged<Duration> onSeek;
  final VoidCallback? onFullScreen;
  final double bottomInset;
  final String controlKeyPrefix;

  String _time(Duration value) {
    final totalSeconds = value.inSeconds.clamp(0, 359999);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.3),
      ),
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: valueListenable,
        builder: (context, value, _) {
          final durationMs = value.duration.inMilliseconds;
          final positionMs = value.position.inMilliseconds.clamp(
            0,
            durationMs > 0 ? durationMs : 0,
          );
          final progress = durationMs <= 0 ? 0.0 : positionMs / durationMs;
          final muted = value.volume <= 0.01;
          final replay = value.isCompleted ||
              (durationMs > 0 && positionMs >= durationMs && !value.isPlaying);

          return Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Semantics(
                  button: true,
                  label: replay
                      ? 'Replay video'
                      : value.isPlaying
                          ? 'Pause video'
                          : 'Play video',
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.52),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: Key('$controlKeyPrefix-play-pause'),
                      onTap: onPlayPause,
                      child: SizedBox(
                        width: 58,
                        height: 58,
                        child: Icon(
                          replay
                              ? Icons.replay_rounded
                              : value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomInset,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 18, 8, 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              key: Key('$controlKeyPrefix-mute'),
                              onPressed: onToggleMute,
                              tooltip: muted ? 'Unmute' : 'Mute',
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                muted
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            IconButton(
                              key: Key('$controlKeyPrefix-stop'),
                              onPressed: onStop,
                              tooltip: 'Stop',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.stop_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            Text(
                              '${_time(value.position)} / ${_time(value.duration)}',
                              key: Key('$controlKeyPrefix-time'),
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 3),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (value.isBuffering)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            if (onFullScreen != null)
                              IconButton(
                                key: Key('$controlKeyPrefix-full-screen'),
                                onPressed: onFullScreen,
                                tooltip: 'Full screen',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.fullscreen_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            activeTrackColor: const Color(0xFF14E86D),
                            inactiveTrackColor: Colors.white38,
                            thumbColor: Colors.white,
                            overlayColor:
                                const Color(0xFF14E86D).withValues(alpha: 0.20),
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                          ),
                          child: Slider(
                            key: Key('$controlKeyPrefix-progress'),
                            value: progress.clamp(0, 1),
                            onChanged: durationMs <= 0
                                ? null
                                : (next) => onSeek(
                                      Duration(
                                        milliseconds:
                                            (durationMs * next).round(),
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
