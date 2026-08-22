import 'package:flutter/material.dart';

import '/backend/supabase/repositories/notification_repository.dart';
import '/backend/supabase/repositories/profile_repository.dart';
import '/backend/supabase/supabase_records.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/core_pages/profile_other/profile_other_widget.dart';
import '/pages/posts/post_details/post_details_widget.dart';

enum _NotificationFilter { all, follows, likes }

class NotificationsWidget extends StatefulWidget {
  const NotificationsWidget({super.key});

  static String routeName = 'Notifications';
  static String routePath = 'notifications';

  @override
  State<NotificationsWidget> createState() => _NotificationsWidgetState();
}

class _NotificationsWidgetState extends State<NotificationsWidget> {
  static const _green = Color(0xFF16E77D);
  static const _bg = Color(0xFF090909);
  static const _surface = Color(0xFF151515);
  static const _border = Color(0xFF292929);
  static const _muted = Color(0xFF8C9299);

  final _notifications = NotificationRepository();
  final _profiles = ProfileRepository();
  final _followState = <String, bool>{};
  final _followBusy = <String>{};
  var _filter = _NotificationFilter.all;

  bool _isFollow(AppNotification item) =>
      item.type.toLowerCase().contains('follow');

  bool _isLike(AppNotification item) {
    final type = item.type.toLowerCase();
    return type.contains('like') || type.contains('comment');
  }

  List<AppNotification> _filtered(List<AppNotification> values) {
    return switch (_filter) {
      _NotificationFilter.all => values,
      _NotificationFilter.follows => values.where(_isFollow).toList(),
      _NotificationFilter.likes => values.where(_isLike).toList(),
    };
  }

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final local = date.toLocal();
    return now.year == local.year &&
        now.month == local.month &&
        now.day == local.day;
  }

  Future<void> _markAll() async {
    try {
      await _notifications.markAllRead();
      if (!mounted) return;
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not mark notifications read: $error')),
      );
    }
  }

  Future<void> _toggleFollow(AppNotification item) async {
    final actorId = item.actorId;
    if (actorId == null || actorId.isEmpty || _followBusy.contains(actorId)) {
      return;
    }
    final wasFollowing = _followState[actorId] ??
        await _profiles.isFollowing(actorId).catchError((_) => false);
    setState(() {
      _followBusy.add(actorId);
      _followState[actorId] = !wasFollowing;
    });
    try {
      if (wasFollowing) {
        await _profiles.unfollow(actorId);
      } else {
        await _profiles.follow(actorId);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _followState[actorId] = wasFollowing);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update follow: $error')),
      );
    } finally {
      if (mounted) setState(() => _followBusy.remove(actorId));
    }
  }

  Future<void> _open(AppNotification item) async {
    if (!item.isRead) {
      await _notifications.markRead(item.id).catchError((_) {});
    }
    if (!mounted) return;
    if (item.postId?.isNotEmpty == true) {
      context.pushNamed(
        PostDetailsWidget.routeName,
        queryParameters: {
          'post': serializeParam(
            supaRef('posts', item.postId!),
            ParamType.DocumentReference,
          ),
        }.withoutNulls,
      );
      return;
    }
    if (item.actorUsername.isNotEmpty) {
      context.pushNamed(
        ProfileOtherWidget.routeName,
        queryParameters: {
          'username': serializeParam(
            item.actorUsername,
            ParamType.String,
          ),
        }.withoutNulls,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: media.textScaler.clamp(maxScaleFactor: 1.25),
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              _header(),
              _filters(),
              Expanded(
                child: StreamBuilder<List<AppNotification>>(
                  stream: _notifications.watch(limit: 80),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData &&
                        snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: _green),
                      );
                    }
                    if (snapshot.hasError) {
                      return _ErrorState(
                        message: 'Notifications could not be loaded',
                        onRetry: () => setState(() {}),
                      );
                    }
                    final values = _filtered(snapshot.data ?? const []);
                    if (values.isEmpty) {
                      return _emptyState();
                    }
                    final today = values
                        .where((item) => _isToday(item.createdAt))
                        .toList();
                    final thisWeek = values
                        .where((item) => !_isToday(item.createdAt))
                        .toList();
                    return RefreshIndicator(
                      color: _green,
                      backgroundColor: _surface,
                      onRefresh: () async => setState(() {}),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                        children: [
                          if (today.isNotEmpty) ...[
                            _sectionTitle('Today'),
                            ...today.map(_notificationRow),
                          ],
                          if (thisWeek.isNotEmpty) ...[
                            const SizedBox(height: 15),
                            _sectionTitle('This Week'),
                            ...thisWeek.map(_notificationRow),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => SizedBox(
        height: 68,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: () => context.safePop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 21),
            ),
            const Expanded(
              child: Text(
                'Notifications',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: _markAll,
              child: const Text(
                'Mark read',
                style: TextStyle(
                  color: _green,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
      );

  Widget _filters() => Container(
        padding: const EdgeInsets.fromLTRB(16, 3, 16, 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _border)),
        ),
        child: Row(
          children: [
            _filterPill(_NotificationFilter.all, 'All'),
            const SizedBox(width: 8),
            _filterPill(_NotificationFilter.follows, 'Follows'),
            const SizedBox(width: 8),
            _filterPill(_NotificationFilter.likes, 'Likes'),
          ],
        ),
      );

  Widget _filterPill(_NotificationFilter value, String label) {
    final selected = value == _filter;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _green : _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? _green : _border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : _muted,
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(3, 6, 3, 9),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _notificationRow(AppNotification item) {
    final follow = _isFollow(item);
    final accent = follow ? const Color(0xFF3E9BFF) : const Color(0xFFFF4F8B);
    final actor = item.actorDisplayName.trim().isNotEmpty
        ? item.actorDisplayName.trim()
        : item.actorUsername.trim().isNotEmpty
            ? item.actorUsername.trim()
            : 'GymFeed member';
    final action = follow
        ? 'started following you'
        : item.type.toLowerCase().contains('comment')
            ? 'commented on your post'
            : 'liked your post';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(item),
        borderRadius: BorderRadius.circular(17),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: item.isRead ? Colors.transparent : const Color(0x1716E77D),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: item.isRead ? Colors.transparent : const Color(0x4316E77D),
            ),
          ),
          child: Row(
            children: [
              _notificationAvatar(item, accent, follow),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      height: 1.35,
                    ),
                    children: [
                      TextSpan(
                        text: '$actor ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: action),
                      TextSpan(
                        text: '  ${_relativeTime(item.createdAt)}',
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (follow)
                _followButton(item)
              else if (item.postThumbnail.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.network(
                    item.postThumbnail,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notificationAvatar(AppNotification item, Color accent, bool follow) {
    final label = item.actorUsername.isNotEmpty ? item.actorUsername : '?';
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF0D6E3F),
            backgroundImage: item.actorPhotoUrl.isEmpty
                ? null
                : NetworkImage(item.actorPhotoUrl),
            child: item.actorPhotoUrl.isEmpty
                ? Text(
                    label.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
                border: Border.all(color: _bg, width: 2),
              ),
              child: Icon(
                follow
                    ? Icons.person_add_alt_1_rounded
                    : Icons.favorite_rounded,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _followButton(AppNotification item) {
    final id = item.actorId ?? '';
    final known = _followState[id];
    return FutureBuilder<bool>(
      future: known == null ? _profiles.isFollowing(id) : Future.value(known),
      builder: (context, snapshot) {
        final following = _followState[id] ?? snapshot.data ?? false;
        _followState.putIfAbsent(id, () => following);
        final busy = _followBusy.contains(id);
        return SizedBox(
          height: 35,
          child: FilledButton(
            onPressed: busy ? null : () => _toggleFollow(item),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              backgroundColor: following ? _surface : _green,
              disabledBackgroundColor: following ? _surface : _green,
              foregroundColor: following ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: following ? _border : _green),
              ),
            ),
            child: busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    following ? 'Following' : 'Follow',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  color: Color(0xFF102D20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_none_rounded,
                    color: _green, size: 30),
              ),
              const SizedBox(height: 15),
              const Text(
                'You are all caught up',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'New follows and post activity will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );

  String _relativeTime(DateTime? value) {
    if (value == null) return '';
    final difference = DateTime.now().difference(value.toLocal());
    if (difference.inMinutes < 1) return 'now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${(difference.inDays / 7).floor()}w';
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded,
              color: _NotificationsWidgetState._green),
          label: Text(
            message,
            style: const TextStyle(color: _NotificationsWidgetState._muted),
          ),
        ),
      );
}
