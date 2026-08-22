import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/editsettings/editsettings_widget.dart';
import '/components/qr/qr_widget.dart';
import '/components/post_type_badge/post_type_badge.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'profile_model.dart';

enum _DesktopProfileTab { posts, tagged, workouts }

class DesktopProfileView extends StatefulWidget {
  const DesktopProfileView({super.key});

  @override
  State<DesktopProfileView> createState() => _DesktopProfileViewState();
}

class _DesktopProfileViewState extends State<DesktopProfileView> {
  static const _background = Color(0xFF090909);
  static const _surface = Color(0xFF121212);
  static const _surfaceRaised = Color(0xFF181818);
  static const _border = Color(0xFF2A2A2A);
  static const _green = Color(0xFF16E77D);
  static const _muted = Color(0xFF8F9499);

  _DesktopProfileTab _tab = _DesktopProfileTab.posts;
  late final Stream<List<PostsRecord>> _postsStream;
  late final Stream<List<UserTrainingsRecord>> _trainingsStream;
  late final Stream<List<FollowersRecord>> _followersStream;

  @override
  void initState() {
    super.initState();
    _postsStream = queryPostsByUserStream(currentUserUid);
    _trainingsStream = queryTrainingsByUserStream(currentUserUid);
    _followersStream = queryFollowersRecord(
      parent: currentUserReference,
      singleRecord: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userReference = currentUserReference;
    if (userReference == null) {
      return const Scaffold(
        backgroundColor: _background,
        body: Center(
          child: CircularProgressIndicator(color: _green),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: StreamBuilder<UsersRecord>(
          stream: UsersRecord.getDocument(userReference),
          builder: (context, userSnapshot) {
            final user = userSnapshot.data;
            if (user == null) {
              return const Center(
                child: CircularProgressIndicator(color: _green),
              );
            }

            return StreamBuilder<List<PostsRecord>>(
              stream: _postsStream,
              initialData: ProfileModel.cachedMyPosts,
              builder: (context, postsSnapshot) {
                final posts = postsSnapshot.data ?? const <PostsRecord>[];
                if (postsSnapshot.hasData) ProfileModel.cachedMyPosts = posts;

                return StreamBuilder<List<FollowersRecord>>(
                  stream: _followersStream,
                  builder: (context, followersSnapshot) {
                    final followerRows =
                        followersSnapshot.data ?? const <FollowersRecord>[];
                    final followerCount = followerRows.isEmpty
                        ? 0
                        : followerRows.first.userRefs.length;

                    return CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(34, 28, 34, 0),
                          sliver: SliverToBoxAdapter(
                            child: _profileHeader(
                              context,
                              user,
                              posts.length,
                              followerCount,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(34, 22, 34, 0),
                          sliver: SliverToBoxAdapter(child: _tabs()),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(34, 22, 34, 60),
                          sliver: _tabContent(context, user, posts),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _profileHeader(
    BuildContext context,
    UsersRecord user,
    int postCount,
    int followerCount,
  ) {
    final displayName = user.displayName.trim().isNotEmpty
        ? user.displayName.trim()
        : 'GymFeed athlete';
    final username = user.username.trim().isNotEmpty
        ? '@${user.username.trim()}'
        : '@gymfeed';

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatar(user),
              const SizedBox(width: 24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          color: _green,
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.7,
                        ),
                      ),
                      if (user.bio.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Text(
                            user.bio.trim(),
                            style: const TextStyle(
                              color: Color(0xFFC4C8CB),
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                      if (user.website.trim().isNotEmpty) ...[
                        const SizedBox(height: 7),
                        InkWell(
                          onTap: () => launchURL(user.website.trim()),
                          child: Text(
                            user.website.trim(),
                            style: const TextStyle(
                              color: _green,
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              _headerActions(context, user),
            ],
          ),
          const SizedBox(height: 28),
          const Divider(color: _border, height: 1),
          const SizedBox(height: 22),
          Row(
            children: [
              _stat(
                value: formatNumber(postCount, formatType: FormatType.compact),
                label: 'Posts',
              ),
              _statDivider(),
              _stat(
                value:
                    formatNumber(followerCount, formatType: FormatType.compact),
                label: 'Followers',
                onTap: () => _openConnections(context, 0),
              ),
              _statDivider(),
              _stat(
                value: formatNumber(
                  user.following.length,
                  formatType: FormatType.compact,
                ),
                label: 'Following',
                onTap: () => _openConnections(context, 1),
              ),
              _statDivider(),
              _stat(
                value: user.workoutLevel.trim().isEmpty
                    ? 'Starter'
                    : user.workoutLevel.trim(),
                label: 'Training level',
                onTap: () => context.pushNamed(ProgressDetailsWidget.routeName),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar(UsersRecord user) {
    final url = functions.bunnyCDNImagePath(user.photoUrl);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 116,
          height: 116,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _green, width: 2),
            color: const Color(0xFF0B2518),
          ),
          child: ClipOval(
            child: url.isEmpty
                ? const Icon(Icons.person_rounded, color: _green, size: 54)
                : CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const ColoredBox(color: Color(0xFF0B2518)),
                    errorWidget: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        color: _green,
                        size: 54),
                  ),
          ),
        ),
        Positioned(
          right: 1,
          bottom: 3,
          child: Container(
            width: 31,
            height: 31,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _green,
              shape: BoxShape.circle,
              border: Border.all(color: _surface, width: 3),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.black, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _headerActions(BuildContext context, UsersRecord user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                await context.pushNamed(EditProfileWidget.routeName);
                await refreshCurrentUserProfile();
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.edit_rounded, size: 17),
              label: const Text('Edit profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: _border),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                textStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: () => _shareProfile(context, user),
              icon: const Icon(Icons.ios_share_rounded, size: 17),
              label: const Text('Share'),
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: const Color(0xFF06150C),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                textStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'Settings',
              onPressed: () => _openSettings(context),
              style: IconButton.styleFrom(
                backgroundColor: _surfaceRaised,
                foregroundColor: Colors.white,
                side: const BorderSide(color: _border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: const Icon(Icons.more_horiz_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Your public GymFeed profile',
          style: TextStyle(
            color: _muted,
            fontFamily: 'Poppins',
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _stat({
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: _muted,
                  fontFamily: 'Poppins',
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statDivider() => const SizedBox(
        height: 38,
        child: VerticalDivider(color: _border, width: 1),
      );

  Widget _tabs() {
    return Container(
      height: 58,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          _tabButton(
              _DesktopProfileTab.posts, Icons.grid_view_rounded, 'Posts'),
          _tabButton(
            _DesktopProfileTab.tagged,
            Icons.person_pin_outlined,
            'Tagged',
          ),
          _tabButton(
            _DesktopProfileTab.workouts,
            Icons.fitness_center_rounded,
            'Workouts',
          ),
        ],
      ),
    );
  }

  Widget _tabButton(_DesktopProfileTab value, IconData icon, String label) {
    final active = _tab == value;
    return Expanded(
      child: Material(
        color: active ? _green : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => setState(() => _tab = value),
          hoverColor: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? const Color(0xFF07160E) : _muted,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: active ? const Color(0xFF07160E) : _muted,
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabContent(
    BuildContext context,
    UsersRecord user,
    List<PostsRecord> posts,
  ) {
    switch (_tab) {
      case _DesktopProfileTab.posts:
        return _postGrid(context, posts);
      case _DesktopProfileTab.tagged:
        return _emptySliver(
          icon: Icons.person_pin_outlined,
          title: 'No tagged posts yet',
          message: 'Posts you are tagged in will appear here.',
        );
      case _DesktopProfileTab.workouts:
        return _trainingGrid(context, user);
    }
  }

  Widget _postGrid(BuildContext context, List<PostsRecord> posts) {
    if (posts.isEmpty) {
      return _emptySliver(
        icon: Icons.photo_library_outlined,
        title: 'Your grid is ready',
        message: 'Share your first workout or progress update.',
        actionLabel: 'Create a post',
        onAction: () => context.pushNamed(NewPostWidget.routeName),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1000 ? 4 : 3;
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _postTile(context, posts[index]),
        childCount: posts.length,
      ),
    );
  }

  Widget _postTile(BuildContext context, PostsRecord post) {
    final source = post.postVideo.isNotEmpty
        ? (post.videoThumbnail.isNotEmpty
            ? post.videoThumbnail
            : post.postPhoto)
        : post.postPhoto;
    final imageUrl = functions.bunnyCDNImagePath(source);

    return Material(
      color: _surfaceRaised,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          PostDetailsWidget.routeName,
          queryParameters: {
            'post': serializeParam(post.reference, ParamType.DocumentReference),
          }.withoutNulls,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const ColoredBox(color: _surfaceRaised),
                errorWidget: (_, __, ___) => _mediaFallback(post.postCaption),
              )
            else
              _mediaFallback(post.postCaption),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x99000000)],
                  stops: [0.58, 1],
                ),
              ),
            ),
            if (post.postVideo.isNotEmpty)
              Positioned(
                left: post.foodPost ? 12 : null,
                right: post.foodPost ? null : 12,
                top: 12,
                child: const Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            if (post.foodPost)
              const Positioned(
                right: 12,
                top: 12,
                child: FoodPostBadge(size: 28),
              ),
            Positioned(
              left: 13,
              right: 13,
              bottom: 11,
              child: Row(
                children: [
                  const Icon(Icons.fitness_center_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    '${post.likes.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Icon(Icons.chat_bubble_outline_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    '${post.numComments}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mediaFallback(String caption) {
    return Container(
      color: _surfaceRaised,
      padding: const EdgeInsets.all(22),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, color: _muted, size: 34),
          if (caption.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              caption.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFB8BCBF),
                fontFamily: 'Poppins',
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _trainingGrid(BuildContext context, UsersRecord user) {
    return StreamBuilder<List<UserTrainingsRecord>>(
      stream: _trainingsStream,
      builder: (context, snapshot) {
        final trainings = snapshot.data ?? const <UserTrainingsRecord>[];
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(50),
              child: Center(
                child: CircularProgressIndicator(color: _green),
              ),
            ),
          );
        }
        if (trainings.isEmpty) {
          return _emptySliver(
            icon: Icons.fitness_center_rounded,
            title: 'No public workouts yet',
            message: 'Create or schedule a training session in Train.',
            actionLabel: 'Open Train',
            onAction: () => context.goNamed(TrainingHomeWidget.routeName),
          );
        }

        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 2.05,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _trainingTile(context, user, trainings[index]),
            childCount: trainings.length,
          ),
        );
      },
    );
  }

  Widget _trainingTile(
    BuildContext context,
    UsersRecord user,
    UserTrainingsRecord training,
  ) {
    final image = functions.bunnyCDNImagePath(training.trainingBackgroundImage);
    return Material(
      color: _surfaceRaised,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          TrainingpostDetailsWidget.routeName,
          queryParameters: {
            'userRecord': serializeParam(user, ParamType.Document),
            'trainingReference': serializeParam(
              training.reference,
              ParamType.DocumentReference,
            ),
          }.withoutNulls,
          extra: <String, dynamic>{'userRecord': user},
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image.isNotEmpty)
              CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    const ColoredBox(color: _surfaceRaised),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x22000000), Color(0xEE000000)],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    training.trainingTitle.trim().isEmpty
                        ? 'Training session'
                        : training.trainingTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    [
                      training.trainingCategory,
                      training.trainingDate,
                      if (training.duration > 0) '${training.duration} min',
                    ].where((value) => value.trim().isNotEmpty).join('  /  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFBAC0BD),
                      fontFamily: 'Poppins',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptySliver({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return SliverToBoxAdapter(
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF0B301E),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _green, size: 27),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              style: const TextStyle(
                color: _muted,
                fontFamily: 'Poppins',
                fontSize: 12,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: const Color(0xFF06150C),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openConnections(BuildContext context, int tab) {
    context.pushNamed(
      FollowersFollowingWidget.routeName,
      queryParameters: {
        'followersTabIndex': serializeParam(tab, ParamType.int),
      }.withoutNulls,
    );
  }

  Future<void> _shareProfile(BuildContext context, UsersRecord user) async {
    final link = await generateCurrentPageLink(
      context,
      title: user.displayName,
      imageUrl: user.photoUrl,
      description: user.bio,
      isShortLink: false,
    );
    await user.reference.update(createUsersRecordData(customLink: link));
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: QrWidget(userDetails: user.reference),
          ),
        ),
      ),
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: const EditsettingsWidget(),
          ),
        ),
      ),
    );
  }
}
