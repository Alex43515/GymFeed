import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_video_player.dart';

/// Plays an exercise explanation video (from a training plan) in a sheet,
/// with sound and controls, looping so the movement can be watched again.
Future<void> showExerciseVideo(
  BuildContext context, {
  required String exerciseName,
  required String videoUrl,
  String? subtitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0B0B0B),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetContext) {
      final height = MediaQuery.of(sheetContext).size.height;
      return SafeArea(
        child: SizedBox(
          height: height * 0.86,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(exerciseName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          if (subtitle != null && subtitle.isNotEmpty)
                            Text(subtitle,
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: Color(0xFF8B8B8B))),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close video',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: FlutterFlowVideoPlayer(
                          key: ValueKey(videoUrl),
                          path: videoUrl,
                          aspectRatio: 9 / 16,
                          autoPlay: true,
                          looping: true,
                          showControls: true,
                          allowFullScreen: true,
                          allowPlaybackSpeedMenu: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Small "How to" button shown next to an exercise that has a video.
class ExerciseVideoButton extends StatelessWidget {
  const ExerciseVideoButton({
    super.key,
    required this.onPressed,
    this.label = 'How to',
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.play_circle_fill_rounded,
          color: Color(0xFF1FE276), size: 17),
      label: Text(label,
          style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1FE276))),
    );
  }
}
