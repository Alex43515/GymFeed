import 'package:flutter/material.dart';

import '/backend/supabase/repositories/profile_repository.dart';
import '/backend/supabase/repositories/training_repository.dart';
import '/components/nav_bar/nav_bar_widget.dart';
import '/components/send_post/send_post_widget.dart';
import '/custom_code/widgets/feed_video_player.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import 'video_reels_model.dart';
export 'video_reels_model.dart';

/// Workout-only vertical video feed. Generic and food posts stay on Home.
class VideoReelsWidget extends StatefulWidget {
  const VideoReelsWidget({super.key, this.initialStoryIndex});

  final int? initialStoryIndex;
  static String routeName = 'videoReels';
  static String routePath = 'videoReels';

  @override
  State<VideoReelsWidget> createState() => _VideoReelsWidgetState();
}

class _VideoReelsWidgetState extends State<VideoReelsWidget> {
  late VideoReelsModel _model;
  final _pageController = PageController();
  final _repository = TrainingRepository();
  final _liked = <String, bool>{};
  final _likeCounts = <String, int>{};
  late Future<List<Training>> _future;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VideoReelsModel());
    _future = _repository.videoFeed(limit: 60);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _future = _repository.videoFeed(limit: 60));
    await _future;
  }

  Future<void> _toggleLike(Training training) async {
    final before = _liked[training.id] ?? training.likedByMe;
    final count = _likeCounts[training.id] ?? training.likeCount;
    setState(() {
      _liked[training.id] = !before;
      _likeCounts[training.id] = (count + (before ? -1 : 1)).clamp(0, 1 << 30);
    });
    try {
      if (before) {
        await _repository.unlike(training.id);
      } else {
        await _repository.like(training.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _liked[training.id] = before;
        _likeCounts[training.id] = count;
      });
    }
  }

  void _share(Training training) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SendPostWidget(
        workout: {
          'id': training.id,
          'title': training.title,
          'description': training.description ?? '',
          'category': training.category,
          'video_url': training.videoUrl,
          'cover_url': training.coverUrl,
        },
      ),
    );
  }

  void _options(Training training) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: Color(0xFF151515),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF555555),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.white),
              title: const Text('Report',
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Reported. Thanks for letting us know.')));
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.block_rounded, color: Color(0xFFFF6464)),
              title: const Text('Block account',
                  style: TextStyle(
                      color: Color(0xFFFF6464),
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(sheetContext);
                try {
                  await ProfileRepository().block(training.userId);
                  if (mounted) await _refresh();
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Could not block this account.')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _compact(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: const NavBarWidget(selectPageIndex: 4),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<Training>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1FE276)),
              );
            }
            if (snapshot.hasError) {
              return _empty(
                icon: Icons.wifi_off_rounded,
                title: 'FitClips could not load',
                message: 'Check your connection and tap to try again.',
              );
            }
            final clips = snapshot.data ?? const <Training>[];
            if (clips.isEmpty) {
              return _empty(
                icon: Icons.video_library_outlined,
                title: 'No workout clips yet',
                message:
                    'Workout videos appear here after a training is scheduled.',
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              color: const Color(0xFF1FE276),
              child: PageView.builder(
                key: const ValueKey('fitclips-workout-video-feed'),
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: clips.length,
                itemBuilder: (_, index) => _clipPage(clips[index]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _empty({
    required IconData icon,
    required String title,
    required String message,
  }) =>
      InkWell(
        onTap: _refresh,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: const Color(0xFF1FE276), size: 52),
                const SizedBox(height: 16),
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontSize: 19,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 7),
                Text(message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFF929292),
                        fontFamily: 'Poppins',
                        fontSize: 13)),
              ],
            ),
          ),
        ),
      );

  Widget _clipPage(Training training) {
    final videoUrl = functions.bunnyCDNVideoPath(training.videoUrl.trim());
    final coverUrl = training.coverUrl.trim();
    final liked = _liked[training.id] ?? training.likedByMe;
    final count = _likeCounts[training.id] ?? training.likeCount;
    return Stack(
      fit: StackFit.expand,
      children: [
        FeedVideoPlayer(
          key: ValueKey('fitclip-video-${training.id}'),
          videoUrl: videoUrl,
          thumbnailUrl: coverUrl.isEmpty ? null : coverUrl,
          borderRadius: 0,
        ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000)],
              ),
            ),
          ),
        ),
        Positioned(
          left: 18,
          right: 16,
          top: 8,
          child: Row(
            children: [
              const Text('FitClips',
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(color: Colors.black, blurRadius: 5)])),
              const Spacer(),
              IconButton(
                key: ValueKey('fitclip-options-${training.id}'),
                onPressed: () => _options(training),
                icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
        Positioned(
          left: 18,
          right: 82,
          bottom: 70,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF153925),
                    backgroundImage: training.authorPhotoUrl.isEmpty
                        ? null
                        : NetworkImage(training.authorPhotoUrl),
                    child: training.authorPhotoUrl.isEmpty
                        ? const Icon(Icons.person_rounded,
                            color: Colors.white, size: 21)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '@${training.authorUsername.isEmpty ? 'gymfeed' : training.authorUsername}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 5)
                          ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(training.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: Colors.black, blurRadius: 5)])),
              if (training.description?.trim().isNotEmpty == true)
                Text(training.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFFD4D4D4),
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        shadows: [Shadow(color: Colors.black, blurRadius: 5)])),
            ],
          ),
        ),
        Positioned(
          right: 12,
          bottom: 72,
          child: Column(
            children: [
              _action(
                key: ValueKey('fitclip-like-${training.id}'),
                icon: liked ? Icons.favorite : Icons.favorite_border,
                color:
                    liked ? FlutterFlowTheme.of(context).error : Colors.white,
                label: _compact(count),
                onTap: () => _toggleLike(training),
              ),
              const SizedBox(height: 18),
              _action(
                key: ValueKey('fitclip-share-${training.id}'),
                icon: Icons.send_outlined,
                color: Colors.white,
                label: 'Share',
                onTap: () => _share(training),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _action({
    required Key key,
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) =>
      InkResponse(
        key: key,
        onTap: onTap,
        radius: 28,
        child: SizedBox(
          width: 58,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: color,
                  size: 32,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 5)]),
              const SizedBox(height: 3),
              Text(label,
                  maxLines: 1,
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: Colors.black, blurRadius: 5)])),
            ],
          ),
        ),
      );
}
