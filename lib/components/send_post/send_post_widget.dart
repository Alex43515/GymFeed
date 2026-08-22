import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '/backend/backend.dart';
import '/backend/share_links.dart';
import '/backend/supabase/database/profile.dart';
import '/backend/supabase/repositories/chat_repository.dart';
import '/backend/supabase/repositories/profile_repository.dart';
import '/backend/supabase/repositories/story_repository.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// The shared post/workout picker used by Home, Food posts and Reels.
///
/// A workout can be supplied as its serialisable routine map. Existing call
/// sites that share a post continue to use [post]/[post2].
class SendPostWidget extends StatefulWidget {
  const SendPostWidget({
    super.key,
    this.post,
    this.comment,
    this.post2,
    this.workout,
  });

  final DocumentReference? post;
  final DocumentReference? comment;
  final PostsRecord? post2;
  final Map<String, dynamic>? workout;

  @override
  State<SendPostWidget> createState() => _SendPostWidgetState();
}

class _SendPostWidgetState extends State<SendPostWidget> {
  static const _green = Color(0xFF14E77C);
  static const _surface = Color(0xFF141414);
  static const _field = Color(0xFF1A1A1A);
  static const _border = Color(0xFF303030);
  static const _muted = Color(0xFF92979E);

  final _profiles = ProfileRepository();
  final _chats = ChatRepository();
  final _stories = StoryRepository();
  final _search = TextEditingController();
  final _selected = <String>{};
  final _knownProfiles = <String, Profile>{};
  late Future<List<Profile>> _people;
  Timer? _debounce;
  bool _sending = false;
  bool _sharingStory = false;

  bool get _isWorkout => widget.workout != null;
  String get _postId => widget.post?.id ?? widget.post2?.reference.id ?? '';
  String get _title {
    if (_isWorkout) {
      return (widget.workout?['name'] ?? widget.workout?['title'] ?? 'Workout')
          .toString();
    }
    final post = widget.post2;
    if (post == null)
      return widget.comment != null ? 'Comment' : 'GymFeed post';
    final value = post.foodPost ? post.postTitleFood : post.postCaption;
    return value.trim().isEmpty
        ? post.foodPost
            ? 'Food post'
            : 'GymFeed post'
        : value.trim();
  }

  String get _subtitle {
    if (_isWorkout) {
      final raw = widget.workout?['exercises'];
      final count = raw is List ? raw.length : null;
      return count == null ? 'Workout' : 'Workout · $count exercises';
    }
    final post = widget.post2;
    if (post == null) return 'GymFeed';
    final hasVideo = post.postVideo.isNotEmpty || post.postVideoFood.isNotEmpty;
    return '${post.foodPost ? 'Food post' : 'Post'} · ${hasVideo ? 'video' : 'photo'}';
  }

  String get _thumbnail {
    final post = widget.post2;
    if (post == null) return '';
    return [
      post.videoThumbnail,
      post.postPhoto,
      post.postPhotoFood,
    ].firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');
  }

  String get _photoUrl {
    final post = widget.post2;
    if (post == null) return '';
    return post.postPhoto.isNotEmpty ? post.postPhoto : post.postPhotoFood;
  }

  String get _videoUrl {
    final post = widget.post2;
    if (post == null) return '';
    return post.postVideo.isNotEmpty ? post.postVideo : post.postVideoFood;
  }

  String get _shareLink {
    if (_postId.isNotEmpty) return gymFeedPostShareUrl(_postId);
    return 'GymFeed';
  }

  @override
  void initState() {
    super.initState();
    _people = _profiles.suggested();
    _search.addListener(_scheduleSearch);
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      final query = _search.text.trim();
      setState(() {
        _people =
            query.isEmpty ? _profiles.suggested() : _profiles.search(query);
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search
      ..removeListener(_scheduleSearch)
      ..dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_selected.isEmpty || _sending) return;
    setState(() => _sending = true);
    var sent = 0;
    try {
      for (final id in _selected) {
        final chatId = await _chats.getOrCreateDirectChat(id);
        if (_isWorkout) {
          await _chats.shareWorkout(chatId, widget.workout!);
        } else {
          await _chats.sendMessage(
            chatId,
            widget.comment != null ? 'Shared a comment.' : 'Shared a post.',
            postId: _postId.isEmpty ? null : _postId,
          );
        }
        sent++;
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sent to $sent ${sent == 1 ? 'person' : 'people'}'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not finish sharing: $error')),
      );
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _shareLink));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied')),
    );
  }

  Future<void> _externalShare() async {
    if (!_isWorkout && _postId.isNotEmpty) {
      await shareGymFeedPost(
        postId: _postId,
        title: _title,
        sharePositionOrigin: getWidgetBoundingBox(context),
      );
      return;
    }
    await Share.share('Try this GymFeed workout: $_title',
        subject: _title, sharePositionOrigin: getWidgetBoundingBox(context));
  }

  Future<void> _shareToStory() async {
    if (_isWorkout || _sharingStory) return;
    if (_photoUrl.isEmpty && _videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This post has no media to add.')),
      );
      return;
    }
    setState(() => _sharingStory = true);
    try {
      await _stories.create(
        photoUrl: _photoUrl.isEmpty ? null : _photoUrl,
        videoUrl: _videoUrl.isEmpty ? null : _videoUrl,
      );
      if (!mounted) return;
      setState(() => _sharingStory = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to your gym day for 24 hours')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _sharingStory = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add to Story: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .82,
        ),
        padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottom),
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: _border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF525252),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Share',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
            _PreviewChip(
              title: _title,
              subtitle: _subtitle,
              thumbnail: _thumbnail,
              isWorkout: _isWorkout,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              cursorColor: _green,
              style:
                  const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
              decoration: InputDecoration(
                hintText: 'Search people',
                hintStyle:
                    const TextStyle(color: _muted, fontFamily: 'Poppins'),
                prefixIcon: const Icon(Icons.search_rounded, color: _muted),
                filled: true,
                fillColor: _field,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _green),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: FutureBuilder<List<Profile>>(
                future: _people,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: _green),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: TextButton.icon(
                        onPressed: () => setState(() {
                          _people = _search.text.trim().isEmpty
                              ? _profiles.suggested()
                              : _profiles.search(_search.text.trim());
                        }),
                        icon: const Icon(Icons.refresh, color: _green),
                        label: const Text('Try again',
                            style: TextStyle(color: _muted)),
                      ),
                    );
                  }
                  final values = snapshot.data ?? const <Profile>[];
                  for (final value in values) {
                    _knownProfiles[value.id] = value;
                  }
                  if (values.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No people found',
                            style: TextStyle(color: _muted)),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: values.length,
                    itemBuilder: (context, index) {
                      final person = values[index];
                      final selected = _selected.contains(person.id);
                      return InkWell(
                        onTap: _sending
                            ? null
                            : () => setState(() {
                                  selected
                                      ? _selected.remove(person.id)
                                      : _selected.add(person.id);
                                }),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                          child: Row(
                            children: [
                              _Avatar(profile: person),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      person.displayName.trim().isNotEmpty
                                          ? person.displayName
                                          : person.username,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      person.username.isEmpty
                                          ? 'GymFeed member'
                                          : '@${person.username}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _muted,
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                width: 25,
                                height: 25,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selected ? _green : Colors.transparent,
                                  border: Border.all(
                                    color: selected ? _green : _muted,
                                  ),
                                ),
                                child: selected
                                    ? const Icon(Icons.check_rounded,
                                        size: 17, color: Colors.black)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(color: _border, height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ShareAction(
                  icon: _sharingStory
                      ? Icons.hourglass_top_rounded
                      : Icons.add_circle_outline_rounded,
                  label: 'Story',
                  enabled: !_isWorkout && !_sharingStory,
                  onTap: _shareToStory,
                ),
                _ShareAction(
                  icon: Icons.link_rounded,
                  label: 'Copy link',
                  enabled: !_isWorkout && _shareLink.isNotEmpty,
                  onTap: _copyLink,
                ),
                _ShareAction(
                  icon: Icons.more_horiz_rounded,
                  label: 'More',
                  enabled: true,
                  onTap: _externalShare,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _selected.isEmpty || _sending ? null : _send,
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  disabledBackgroundColor: const Color(0xFF262626),
                  foregroundColor: Colors.black,
                  disabledForegroundColor: const Color(0xFF717171),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        _selected.isEmpty
                            ? 'Select people to send'
                            : 'Send to ${_selected.length} ${_selected.length == 1 ? 'person' : 'people'}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({
    required this.title,
    required this.subtitle,
    required this.thumbnail,
    required this.isWorkout,
  });

  final String title;
  final String subtitle;
  final String thumbnail;
  final bool isWorkout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: _SendPostWidgetState._field,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _SendPostWidgetState._border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Container(
              width: 48,
              height: 48,
              color: const Color(0xFF103B26),
              child: thumbnail.isNotEmpty
                  ? Image.network(
                      thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_outlined,
                        color: _SendPostWidgetState._green,
                      ),
                    )
                  : Icon(
                      isWorkout
                          ? Icons.fitness_center_rounded
                          : Icons.image_outlined,
                      color: _SendPostWidgetState._green,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _SendPostWidgetState._muted,
                    fontFamily: 'Poppins',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final label = profile.displayName.isNotEmpty
        ? profile.displayName
        : profile.username.isNotEmpty
            ? profile.username
            : '?';
    return CircleAvatar(
      radius: 23,
      backgroundColor: const Color(0xFF0C6B3D),
      backgroundImage:
          profile.photoUrl.isEmpty ? null : NetworkImage(profile.photoUrl),
      child: profile.photoUrl.isEmpty
          ? Text(
              label.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}

class _ShareAction extends StatelessWidget {
  const _ShareAction({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Colors.white : const Color(0xFF555555);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _SendPostWidgetState._field,
                shape: BoxShape.circle,
                border: Border.all(color: _SendPostWidgetState._border),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontFamily: 'Poppins',
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
