import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/repositories/story_repository.dart';
import '/backend/supabase/supabase.dart';
import '/pages/core_pages/story/story_widget.dart';
import '/pages/core_pages/story_upload/story_upload_widget.dart';

class StoryTrayWidget extends StatefulWidget {
  const StoryTrayWidget({super.key, this.repository});

  final StoryDataSource? repository;

  @override
  State<StoryTrayWidget> createState() => _StoryTrayWidgetState();
}

class _StoryTrayWidgetState extends State<StoryTrayWidget> {
  StoryDataSource get _repository => widget.repository ?? StoryRepository();

  List<StoryGroup> _groups = const [];
  bool _loading = true;
  Object? _error;
  RealtimeChannel? _channel;
  Timer? _reloadDebounce;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribe();
  }

  void _subscribe() {
    if (widget.repository != null) return;
    final channel = supabase
        .channel('story-tray-${_repository.currentUserId ?? 'guest'}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'stories',
          callback: (_) => _scheduleReload(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'story_views',
          callback: (_) => _scheduleReload(),
        )
        .subscribe();
    _channel = channel;
  }

  void _scheduleReload() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 250), _load);
  }

  Future<void> _load() async {
    try {
      final groups = await _repository.loadTray();
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  Future<void> _openUpload() async {
    await showModalBottomSheet<StoryItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: MediaQuery.viewInsetsOf(context),
        child: StoryUploadWidget(repository: widget.repository),
      ),
    );
    await _load();
  }

  Future<void> _openViewer(int groupIndex) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => StoryWidget(
          groups: _groups,
          initialGroupIndex: groupIndex,
          repository: widget.repository,
          onChanged: _load,
        ),
      ),
    );
    await _load();
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    final channel = _channel;
    if (channel != null) unawaited(supabase.removeChannel(channel));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 98,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF13E879),
          ),
        ),
      );
    }
    final uid = _repository.currentUserId ?? currentUserUid;
    final ownIndex = _groups.indexWhere((group) => group.author.id == uid);
    final own = ownIndex == -1 ? null : _groups[ownIndex];
    final following = <MapEntry<int, StoryGroup>>[
      for (var index = 0; index < _groups.length; index++)
        if (index != ownIndex) MapEntry(index, _groups[index]),
    ];

    return SizedBox(
      height: 104,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
        children: [
          _OwnStoryTile(
            group: own,
            fallbackPhotoUrl: currentUserPhoto,
            onOpen: own == null ? _openUpload : () => _openViewer(ownIndex),
            onAdd: _openUpload,
          ),
          for (final entry in following) ...[
            const SizedBox(width: 12),
            _StoryTile(
              key: ValueKey('story-group-${entry.value.author.id}'),
              group: entry.value,
              onTap: () => _openViewer(entry.key),
            ),
          ],
          if (following.isEmpty && _error != null) ...[
            const SizedBox(width: 18),
            Center(
              child: TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry stories'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OwnStoryTile extends StatelessWidget {
  const _OwnStoryTile({
    required this.group,
    required this.fallbackPhotoUrl,
    required this.onOpen,
    required this.onAdd,
  });

  final StoryGroup? group;
  final String fallbackPhotoUrl;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final photo = group?.author.photoUrl.isNotEmpty == true
        ? group!.author.photoUrl
        : fallbackPhotoUrl;
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                key: const ValueKey('my-story'),
                onTap: onOpen,
                child: _StoryRing(
                  photoUrl: photo,
                  active: group?.hasUnseen == true,
                  hasStory: group != null,
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: GestureDetector(
                  key: const ValueKey('add-story'),
                  onTap: onAdd,
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: const Color(0xFF13E879),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2.5),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.black, size: 17),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'Your story',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white70,
              fontFamily: 'Poppins',
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryTile extends StatelessWidget {
  const _StoryTile({super.key, required this.group, required this.onTap});

  final StoryGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 68,
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            children: [
              _StoryRing(
                photoUrl: group.author.photoUrl,
                active: group.hasUnseen,
                hasStory: true,
              ),
              const SizedBox(height: 7),
              Text(
                group.author.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: group.hasUnseen ? Colors.white : Colors.white54,
                  fontFamily: 'Poppins',
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      );
}

class _StoryRing extends StatelessWidget {
  const _StoryRing({
    required this.photoUrl,
    required this.active,
    required this.hasStory,
  });

  final String photoUrl;
  final bool active;
  final bool hasStory;

  @override
  Widget build(BuildContext context) => Container(
        width: 64,
        height: 64,
        padding: EdgeInsets.all(hasStory ? 2.5 : 1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasStory && active
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF13E879), Color(0xFF00A95A)],
                )
              : null,
          border: !active
              ? Border.all(
                  color: hasStory
                      ? const Color(0xFF555555)
                      : const Color(0xFF2B2B2B),
                  width: hasStory ? 2 : 1,
                )
              : null,
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          child: CircleAvatar(
            backgroundColor: const Color(0xFF1D3026),
            backgroundImage: photoUrl.isEmpty ? null : NetworkImage(photoUrl),
            child: photoUrl.isEmpty
                ? const Icon(Icons.person_rounded,
                    color: Color(0xFF13E879), size: 25)
                : null,
          ),
        ),
      );
}
