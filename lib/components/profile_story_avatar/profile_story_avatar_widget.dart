import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/backend/supabase/repositories/story_repository.dart';
import '/backend/supabase/supabase.dart';
import '/pages/core_pages/story/story_widget.dart';
import '/pages/core_pages/story_upload/story_upload_widget.dart';

/// The single Story entry point used by both profile screens.
///
/// It deliberately uses the same repository as the Home tray so a Story has
/// one source of truth for its 24-hour lifetime, view receipt and media URL.
class ProfileStoryAvatarWidget extends StatefulWidget {
  const ProfileStoryAvatarWidget({
    super.key,
    required this.userId,
    required this.photoUrl,
    required this.isCurrentUser,
    this.size = 100,
    this.onNoStoryTap,
    this.liveUpdates = true,
    this.repository,
  });

  final String userId;
  final String photoUrl;
  final bool isCurrentUser;
  final double size;
  final VoidCallback? onNoStoryTap;
  final bool liveUpdates;
  final StoryDataSource? repository;

  @override
  State<ProfileStoryAvatarWidget> createState() =>
      _ProfileStoryAvatarWidgetState();
}

class _ProfileStoryAvatarWidgetState extends State<ProfileStoryAvatarWidget> {
  StoryDataSource get _repository => widget.repository ?? StoryRepository();

  StoryGroup? _group;
  RealtimeChannel? _channel;
  Timer? _reloadDebounce;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant ProfileStoryAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _load();
    }
  }

  void _subscribe() {
    if (widget.repository != null || !widget.liveUpdates) return;
    _channel = supabase
        .channel('profile-story-${widget.userId}-${identityHashCode(this)}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'stories',
          callback: (change) {
            final row = change.newRecord.isNotEmpty
                ? change.newRecord
                : change.oldRecord;
            if ((row['user_id'] ?? '').toString() == widget.userId) {
              _scheduleLoad();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'story_views',
          callback: (_) => _scheduleLoad(),
        )
        .subscribe();
  }

  void _scheduleLoad() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 250), _load);
  }

  Future<void> _load() async {
    if (widget.userId.isEmpty) return;
    try {
      final group = await _repository.loadForUser(widget.userId);
      if (mounted) setState(() => _group = group);
    } catch (_) {
      // A profile remains usable if Stories are temporarily unavailable.
    }
  }

  Future<void> _openStory() async {
    var group = _group;
    if (group == null && widget.userId.isNotEmpty) {
      try {
        group = await _repository.loadForUser(widget.userId);
        if (mounted) setState(() => _group = group);
      } catch (_) {}
    }
    if (!mounted) return;
    if (group == null) {
      if (widget.isCurrentUser) {
        await _openUpload();
      } else {
        widget.onNoStoryTap?.call();
      }
      return;
    }
    final activeGroup = group;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => StoryWidget(
          groups: [activeGroup],
          repository: widget.repository,
          onChanged: _load,
        ),
      ),
    );
    await _load();
  }

  Future<void> _openUpload() async {
    if (!widget.isCurrentUser) return;
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

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    final channel = _channel;
    if (channel != null) unawaited(supabase.removeChannel(channel));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;
    final hasStory = group != null;
    final unseen = group?.hasUnseen == true;
    final imageUrl = group?.author.photoUrl.isNotEmpty == true
        ? group!.author.photoUrl
        : widget.photoUrl;
    final ringPadding = (widget.size * .03).clamp(1.5, 3.0);
    final ringWidth = (widget.size * .03).clamp(1.5, 3.0);
    final addSize = (widget.size * .31).clamp(22.0, 31.0);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              key: ValueKey('profile-story-${widget.userId}'),
              onTap: _openStory,
              child: Container(
                width: widget.size,
                height: widget.size,
                padding: EdgeInsets.all(ringPadding),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasStory && unseen
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF13E879), Color(0xFF009B52)],
                        )
                      : null,
                  border: hasStory && !unseen
                      ? Border.all(
                          color: const Color(0xFF555555), width: ringWidth)
                      : !hasStory
                          ? Border.all(
                              color: const Color(0xFF13E879), width: ringWidth)
                          : null,
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFF173425),
                    backgroundImage:
                        imageUrl.isEmpty ? null : NetworkImage(imageUrl),
                    child: imageUrl.isEmpty
                        ? Icon(
                            Icons.person_rounded,
                            color: const Color(0xFF13E879),
                            size: widget.size * .42,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
          if (widget.isCurrentUser)
            GestureDetector(
              key: const ValueKey('profile-add-story'),
              onTap: _openUpload,
              child: Container(
                width: addSize,
                height: addSize,
                decoration: BoxDecoration(
                  color: const Color(0xFF13E879),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.black,
                  size: addSize * .62,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
