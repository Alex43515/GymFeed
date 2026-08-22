import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/supabase/repositories/post_repository.dart';
import '/components/send_post/send_post_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/posts/comments/comments_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef ToggleHomePostLike = Future<void> Function(
  String postId,
  bool shouldLike,
);

typedef LoadHomePostCounts = Future<({int likes, int comments})?> Function(
  String postId,
);

class HomePostEngagementData {
  const HomePostEngagementData({
    required this.postId,
    required this.likeCount,
    required this.commentCount,
    required this.likedByCurrentUser,
    this.allowLikes = true,
    this.allowComments = true,
    this.sourcePost,
  });

  factory HomePostEngagementData.fromPost(PostsRecord post) =>
      HomePostEngagementData(
        postId: post.reference.id,
        likeCount: post.likes.length,
        commentCount: post.foodPost ? post.numCommentsFood : post.numComments,
        likedByCurrentUser: post.likes.contains(currentUserReference),
        allowLikes: !post.hasAllowLikes() || post.allowLikes,
        allowComments: !post.hasAllowComments() || post.allowComments,
        sourcePost: post,
      );

  final String postId;
  final int likeCount;
  final int commentCount;
  final bool likedByCurrentUser;
  final bool allowLikes;
  final bool allowComments;
  final PostsRecord? sourcePost;
}

/// The compact interaction row shown directly below every post on Home.
///
/// It owns an optimistic copy of the engagement state so a tap is reflected in
/// the same frame. Supabase remains authoritative and is used to reconcile the
/// counters after a successful write or after returning from Comments.
class HomePostEngagementWidget extends StatefulWidget {
  const HomePostEngagementWidget({
    super.key,
    required this.data,
    this.toggleLike,
    this.loadCounts,
    this.openComments,
  });

  final HomePostEngagementData data;

  /// Test seams; production callers leave these null to use PostRepository and
  /// the app router.
  final ToggleHomePostLike? toggleLike;
  final LoadHomePostCounts? loadCounts;
  final Future<void> Function()? openComments;

  @override
  State<HomePostEngagementWidget> createState() =>
      _HomePostEngagementWidgetState();
}

class _HomePostEngagementWidgetState extends State<HomePostEngagementWidget> {
  late bool _liked;
  late int _likeCount;
  late int _commentCount;
  bool _savingLike = false;

  String get _postId => widget.data.postId;
  bool get _allowLikes => widget.data.allowLikes;
  bool get _allowComments => widget.data.allowComments;

  @override
  void initState() {
    super.initState();
    _readInitialState();
  }

  @override
  void didUpdateWidget(covariant HomePostEngagementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.postId != _postId) {
      _readInitialState();
      return;
    }
    if (!_savingLike) {
      _liked = widget.data.likedByCurrentUser;
      _likeCount = widget.data.likeCount;
    }
    _commentCount = widget.data.commentCount;
  }

  void _readInitialState() {
    _liked = widget.data.likedByCurrentUser;
    _likeCount = widget.data.likeCount;
    _commentCount = widget.data.commentCount;
  }

  Future<void> _toggleLike() async {
    if (!_allowLikes || _savingLike) return;

    final previousLiked = _liked;
    final previousCount = _likeCount;
    final shouldLike = !_liked;
    setState(() {
      _savingLike = true;
      _liked = shouldLike;
      _likeCount = (_likeCount + (shouldLike ? 1 : -1)).clamp(0, 1 << 31);
    });

    try {
      if (widget.toggleLike != null) {
        await widget.toggleLike!(_postId, shouldLike);
      } else if (shouldLike) {
        await PostRepository().likePost(_postId);
      } else {
        await PostRepository().unlikePost(_postId);
      }
      await HapticFeedback.selectionClick();
      await _refreshCounts(useDefaultLoader: widget.toggleLike == null);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _liked = previousLiked;
        _likeCount = previousCount;
      });
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Could not update this like. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _savingLike = false);
    }
  }

  Future<void> _openComments() async {
    if (!_allowComments) return;
    if (widget.openComments != null) {
      await widget.openComments!();
    } else {
      final post = widget.data.sourcePost;
      if (post == null) return;
      await context.pushNamed(
        CommentsWidget.routeName,
        queryParameters: {
          'post': serializeParam(
            post.reference,
            ParamType.DocumentReference,
          ),
        }.withoutNulls,
      );
    }
    await _refreshCounts(useDefaultLoader: widget.openComments == null);
  }

  Future<void> _refreshCounts({required bool useDefaultLoader}) async {
    try {
      final counts = widget.loadCounts != null
          ? await widget.loadCounts!(_postId)
          : useDefaultLoader
              ? await _loadCounts(_postId)
              : null;
      if (!mounted || counts == null) return;
      setState(() {
        _likeCount = counts.likes;
        _commentCount = counts.comments;
      });
    } catch (_) {
      // The optimistic result remains useful; pull-to-refresh will reconcile it.
    }
  }

  Future<({int likes, int comments})?> _loadCounts(String postId) async {
    final row = await PostRepository().getById(postId);
    if (row == null) return null;
    return (
      likes: (row['like_count'] as num?)?.toInt() ?? _likeCount,
      comments: (row['comment_count'] as num?)?.toInt() ?? _commentCount,
    );
  }

  Future<void> _sharePost() async {
    final post = widget.data.sourcePost;
    if (post == null) return;
    await showModalBottomSheet<void>(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => Padding(
        padding: MediaQuery.viewInsetsOf(context),
        child: SendPostWidget(
          post: post.reference,
          post2: post,
        ),
      ),
    );
  }

  String _compactCount(int value) {
    if (value < 1000) return '$value';
    if (value < 1000000) {
      final amount = value / 1000;
      return '${amount >= 10 ? amount.toStringAsFixed(0) : amount.toStringAsFixed(1)}K';
    }
    final amount = value / 1000000;
    return '${amount >= 10 ? amount.toStringAsFixed(0) : amount.toStringAsFixed(1)}M';
  }

  Widget _action({
    required Key key,
    required IconData icon,
    required String label,
    required String semanticLabel,
    required VoidCallback? onTap,
    Color? color,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final actionColor = color ?? theme.tertiary;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: actionColor),
                const SizedBox(width: 7),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: Text(
                    label,
                    key: ValueKey(label),
                    maxLines: 1,
                    style: theme.bodyMedium.override(
                      fontFamily: 'Poppins',
                      color: actionColor,
                      fontSize: 13,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = FlutterFlowTheme.of(context);
    final muted = theme.secondaryText;

    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.4),
      ),
      child: Container(
        key: Key('home-engagement-$_postId'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          border: Border(
            top: BorderSide(color: theme.secondary.withValues(alpha: 0.55)),
          ),
        ),
        child: Row(
          children: [
            _action(
              key: Key('home-like-$_postId'),
              icon: _liked ? FFIcons.k02012 : FFIcons.kmuscles,
              label: _compactCount(_likeCount),
              semanticLabel:
                  '${_liked ? 'Unlike' : 'Like'} post, $_likeCount likes',
              onTap: _allowLikes && !_savingLike ? _toggleLike : null,
              color: _liked ? theme.primary : (_allowLikes ? null : muted),
            ),
            const SizedBox(width: 4),
            _action(
              key: Key('home-comment-$_postId'),
              icon: Icons.mode_comment_outlined,
              label: _compactCount(_commentCount),
              semanticLabel: 'Open comments, $_commentCount comments',
              onTap: _allowComments ? _openComments : null,
              color: _allowComments ? null : muted,
            ),
            const Spacer(),
            IconButton(
              key: Key('home-share-$_postId'),
              onPressed: widget.data.sourcePost == null ? null : _sharePost,
              tooltip: 'Share post',
              icon: Icon(Icons.send_outlined, color: theme.tertiary, size: 23),
            ),
          ],
        ),
      ),
    );
  }
}
