import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '/backend/backend.dart' show StoriesRecord;
import '/backend/supabase/repositories/story_repository.dart';
import '/custom_code/widgets/media_request_headers.dart';

class StoryWidget extends StatefulWidget {
  const StoryWidget({
    super.key,
    this.story,
    this.groups,
    this.initialGroupIndex = 0,
    this.repository,
    this.onChanged,
  });

  /// Compatibility input for older generated callers. The modern tray passes
  /// [groups], which enables sequential playback across every active Story.
  final StoriesRecord? story;
  final List<StoryGroup>? groups;
  final int initialGroupIndex;
  final StoryDataSource? repository;
  final FutureOr<void> Function()? onChanged;

  @override
  State<StoryWidget> createState() => _StoryWidgetState();
}

class _StoryWidgetState extends State<StoryWidget> with WidgetsBindingObserver {
  static const _photoDuration = Duration(seconds: 5);

  late List<StoryGroup> _groups;
  late int _groupIndex;
  int _storyIndex = 0;
  StoryDataSource get _repository => widget.repository ?? StoryRepository();

  VideoPlayerController? _video;
  Timer? _ticker;
  Duration _photoElapsed = Duration.zero;
  double _progress = 0;
  bool _paused = false;
  bool _muted = false;
  bool _loading = true;
  bool _failed = false;
  bool _advancing = false;
  int _viewerCount = 0;

  StoryGroup get _group => _groups[_groupIndex];
  StoryItem get _story => _group.stories[_storyIndex];
  bool get _isOwner => _group.author.id == _repository.currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _groups =
        widget.groups?.where((group) => group.stories.isNotEmpty).toList() ??
            _compatibilityGroups();
    _groupIndex = _groups.isEmpty
        ? 0
        : widget.initialGroupIndex.clamp(0, _groups.length - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_groups.isEmpty) {
        Navigator.maybePop(context);
      } else {
        _bootstrap();
      }
    });
  }

  Future<void> _bootstrap() async {
    final legacy = widget.story;
    if (widget.groups == null && legacy != null) {
      final userId = legacy.user?.id ?? '';
      try {
        final group = await _repository.loadForUser(userId);
        if (group != null && mounted) {
          _groups = [group];
          _groupIndex = 0;
          final selected = group.stories
              .indexWhere((story) => story.id == legacy.reference.id);
          _storyIndex = selected < 0 ? 0 : selected;
        }
      } catch (_) {}
    }
    await _loadCurrent();
  }

  List<StoryGroup> _compatibilityGroups() {
    final legacy = widget.story;
    if (legacy == null) return const [];
    final userId = legacy.user?.id ?? '';
    return [
      StoryGroup(
        author: StoryAuthor(
          id: userId,
          username: 'Story',
          displayName: '',
          photoUrl: '',
        ),
        stories: [
          StoryItem(
            id: legacy.reference.id,
            userId: userId,
            photoUrl: legacy.storyPhoto,
            videoUrl: legacy.storyVideo,
            createdAt: legacy.timeCreated ?? DateTime.now(),
            expiresAt: legacy.expireTime ??
                DateTime.now().add(const Duration(hours: 24)),
          ),
        ],
      ),
    ];
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resume();
    } else {
      _pause();
    }
  }

  Future<void> _loadCurrent() async {
    _ticker?.cancel();
    _ticker = null;
    await _video?.dispose();
    _video = null;
    _photoElapsed = Duration.zero;
    if (!mounted) return;
    setState(() {
      _progress = 0;
      _paused = false;
      _loading = true;
      _failed = false;
      _viewerCount = 0;
    });

    await _markViewed();
    if (!mounted) return;
    if (_isOwner) unawaited(_refreshViewerCount());
    if (_story.isVideo) {
      try {
        final controller = VideoPlayerController.networkUrl(
          Uri.parse(_story.videoUrl),
          httpHeaders: gymFeedMediaHeaders(_story.videoUrl),
        );
        _video = controller;
        await controller.initialize();
        await controller.setLooping(false);
        await controller.setVolume(_muted ? 0 : 1);
        await controller.play();
      } catch (_) {
        _failed = true;
      }
    } else if (_story.isPhoto) {
      unawaited(precacheImage(
        NetworkImage(_story.photoUrl),
        context,
        onError: (_, __) {},
      ));
    } else {
      _failed = true;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
  }

  Future<void> _markViewed() async {
    if (_isOwner || _story.seenByMe) return;
    try {
      await _repository.recordView(_story.id);
    } catch (_) {
      // Playback must remain available when a receipt cannot be recorded.
    }
    final stories = [..._group.stories];
    stories[_storyIndex] = stories[_storyIndex].copyWith(seenByMe: true);
    _groups[_groupIndex] = _group.copyWith(stories: stories);
    await widget.onChanged?.call();
  }

  Future<void> _refreshViewerCount() async {
    try {
      final viewers = await _repository.viewerProfiles(_story.id);
      if (mounted) setState(() => _viewerCount = viewers.length);
    } catch (_) {
      if (mounted) setState(() => _viewerCount = 0);
    }
  }

  void _tick() {
    if (!mounted || _paused || _advancing) return;
    if (_failed) {
      _photoElapsed += const Duration(milliseconds: 50);
      if (_photoElapsed >= const Duration(seconds: 2)) _next();
      return;
    }
    if (_story.isVideo) {
      final controller = _video;
      if (controller == null || !controller.value.isInitialized) return;
      final duration = controller.value.duration;
      final position = controller.value.position;
      final nextProgress = duration.inMilliseconds <= 0
          ? 0.0
          : position.inMilliseconds / duration.inMilliseconds;
      if (nextProgress >= .998 || controller.value.isCompleted) {
        _next();
      } else if ((nextProgress - _progress).abs() > .005) {
        setState(() => _progress = nextProgress.clamp(0, 1));
      }
    } else {
      _photoElapsed += const Duration(milliseconds: 50);
      final nextProgress =
          _photoElapsed.inMilliseconds / _photoDuration.inMilliseconds;
      if (nextProgress >= 1) {
        _next();
      } else {
        setState(() => _progress = nextProgress.clamp(0, 1));
      }
    }
  }

  Future<void> _next() async {
    if (_advancing || !mounted) return;
    _advancing = true;
    if (_storyIndex + 1 < _group.stories.length) {
      _storyIndex++;
    } else if (_groupIndex + 1 < _groups.length) {
      _groupIndex++;
      _storyIndex = 0;
    } else {
      Navigator.of(context).pop();
      _advancing = false;
      return;
    }
    await _loadCurrent();
    _advancing = false;
  }

  Future<void> _previous() async {
    if (_advancing || !mounted) return;
    _advancing = true;
    if (_progress > .12) {
      await _loadCurrent();
      _advancing = false;
      return;
    }
    if (_storyIndex > 0) {
      _storyIndex--;
    } else if (_groupIndex > 0) {
      _groupIndex--;
      _storyIndex = _group.stories.length - 1;
    } else {
      await _loadCurrent();
      _advancing = false;
      return;
    }
    await _loadCurrent();
    _advancing = false;
  }

  void _pause() {
    if (_paused) return;
    _paused = true;
    _video?.pause();
    if (mounted) setState(() {});
  }

  void _resume() {
    if (!_paused) return;
    _paused = false;
    if (_story.isVideo) _video?.play();
    if (mounted) setState(() {});
  }

  void _togglePause() => _paused ? _resume() : _pause();

  Future<void> _toggleMute() async {
    _muted = !_muted;
    await _video?.setVolume(_muted ? 0 : 1);
    if (mounted) setState(() {});
  }

  Future<void> _seek(double value) async {
    final controller = _video;
    if (controller == null || !controller.value.isInitialized) return;
    final duration = controller.value.duration;
    await controller.seekTo(Duration(
      milliseconds: (duration.inMilliseconds * value).round(),
    ));
    setState(() => _progress = value);
  }

  Future<void> _showViewers() async {
    _pause();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      showDragHandle: true,
      builder: (_) => _StoryViewersSheet(
        future: _repository.viewerProfiles(_story.id),
      ),
    );
    if (mounted) _resume();
  }

  Future<void> _deleteCurrent() async {
    _pause();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title:
            const Text('Delete story?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This story will be removed immediately.',
          style: TextStyle(color: Color(0xFFAAAAAA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      _resume();
      return;
    }
    try {
      await _repository.delete(_story.id);
      final stories = [..._group.stories]..removeAt(_storyIndex);
      if (stories.isEmpty) {
        _groups.removeAt(_groupIndex);
        if (_groups.isEmpty) {
          await widget.onChanged?.call();
          if (mounted) Navigator.pop(context);
          return;
        }
        if (_groupIndex >= _groups.length) _groupIndex = _groups.length - 1;
        _storyIndex = 0;
      } else {
        _groups[_groupIndex] = _group.copyWith(stories: stories);
        if (_storyIndex >= stories.length) _storyIndex = stories.length - 1;
      }
      await widget.onChanged?.call();
      await _loadCurrent();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Story could not be deleted: $error')),
      );
      _resume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_groups.isEmpty) return const SizedBox.shrink();
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 550) Navigator.pop(context);
        },
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _media(),
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _previous,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _next,
                    ),
                  ),
                ],
              ),
            ),
            _topOverlay(),
            if (_story.isVideo && !_loading) _videoControls(),
            if (_isOwner) _ownerActions(),
            if (_paused)
              Center(
                child: GestureDetector(
                  onTap: _togglePause,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0x99000000),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 38),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _media() {
    if (_failed) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.white54, size: 44),
            SizedBox(height: 10),
            Text('Story unavailable', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }
    if (_story.isVideo) {
      final controller = _video;
      if (controller == null || !controller.value.isInitialized) {
        return const Center(
            child: CircularProgressIndicator(color: Colors.white));
      }
      final size = controller.value.size;
      return ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: VideoPlayer(controller),
          ),
        ),
      );
    }
    return Image.network(
      _story.photoUrl,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
      errorBuilder: (_, __, ___) => const Center(
        child:
            Icon(Icons.broken_image_outlined, color: Colors.white54, size: 44),
      ),
    );
  }

  Widget _topOverlay() => Positioned(
        left: 0,
        right: 0,
        top: 0,
        child: SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xB8000000), Colors.transparent],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: List.generate(_group.stories.length, (index) {
                    final value = index < _storyIndex
                        ? 1.0
                        : index == _storyIndex
                            ? _progress
                            : 0.0;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: index == _group.stories.length - 1 ? 0 : 4),
                        child: LinearProgressIndicator(
                          minHeight: 2.5,
                          value: value,
                          color: Colors.white,
                          backgroundColor: Colors.white30,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF222222),
                      backgroundImage: _group.author.photoUrl.isEmpty
                          ? null
                          : NetworkImage(_group.author.photoUrl),
                      child: _group.author.photoUrl.isEmpty
                          ? Text(
                              _group.author.label.characters.first
                                  .toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              _group.author.label,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _relativeTime(_story.createdAt),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isOwner)
                      IconButton(
                        key: const ValueKey('delete-story'),
                        onPressed: _deleteCurrent,
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: Colors.white,
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _videoControls() => Positioned(
        left: 12,
        right: 12,
        bottom: _isOwner ? 68 : 22,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: const Color(0xA6000000),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('story-play-pause'),
                onPressed: _togglePause,
                icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                color: Colors.white,
                iconSize: 20,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: const Color(0xFF13E879),
                    inactiveTrackColor: Colors.white30,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    key: const ValueKey('story-video-progress'),
                    value: _progress.clamp(0, 1),
                    onChangeStart: (_) => _pause(),
                    onChanged: _seek,
                    onChangeEnd: (_) => _resume(),
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('story-mute'),
                onPressed: _toggleMute,
                icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
                color: Colors.white,
                iconSize: 20,
              ),
            ],
          ),
        ),
      );

  Widget _ownerActions() => Positioned(
        left: 0,
        right: 0,
        bottom: 12,
        child: SafeArea(
          top: false,
          child: Center(
            child: TextButton.icon(
              key: const ValueKey('story-viewers'),
              onPressed: _showViewers,
              icon: const Icon(Icons.visibility_outlined,
                  color: Colors.white, size: 18),
              label: Text(
                '$_viewerCount ${_viewerCount == 1 ? 'viewer' : 'viewers'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ),
      );
}

class _StoryViewersSheet extends StatelessWidget {
  const _StoryViewersSheet({required this.future});

  final Future<List<StoryViewerProfile>> future;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .5,
          child: FutureBuilder<List<StoryViewerProfile>>(
            future: future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF13E879)),
                );
              }
              final viewers = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Text(
                      '${viewers.length} ${viewers.length == 1 ? 'viewer' : 'viewers'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (viewers.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text('No views yet',
                            style: TextStyle(color: Colors.white54)),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: viewers.length,
                        itemBuilder: (_, index) {
                          final viewer = viewers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF24352D),
                              backgroundImage: viewer.photoUrl.isEmpty
                                  ? null
                                  : NetworkImage(viewer.photoUrl),
                              child: viewer.photoUrl.isEmpty
                                  ? Text(viewer.label.characters.first
                                      .toUpperCase())
                                  : null,
                            ),
                            title: Text(viewer.label,
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                              _relativeTime(viewer.viewedAt),
                              style: const TextStyle(color: Colors.white38),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      );
}

String _relativeTime(DateTime date) {
  final difference = DateTime.now().difference(date.toLocal());
  if (difference.inMinutes < 1) return 'now';
  if (difference.inHours < 1) return '${difference.inMinutes}m';
  if (difference.inHours < 24) return '${difference.inHours}h';
  return '${difference.inDays}d';
}
