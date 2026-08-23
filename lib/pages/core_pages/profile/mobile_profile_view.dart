import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/backend/supabase/repositories/profile_repository.dart';
import '/backend/supabase/repositories/training_repository.dart';
import '/components/nav_bar/nav_bar_widget.dart';
import '/components/post_type_badge/post_type_badge.dart';
import '/components/profile_story_avatar/profile_story_avatar_widget.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/ai_workout/coach_events/event_details_sheet.dart';

class MobileProfileView extends StatefulWidget {
  const MobileProfileView({
    super.key,
    required this.profile,
    required this.isSelf,
    this.initialTab = 0,
    this.followerCount,
    this.followingCount,
    this.isFollowing = false,
    this.followBusy = false,
    this.onFollow,
    this.onMessage,
    this.onEdit,
    this.onShare,
    this.onMore,
    this.onBack,
  });

  final UsersRecord profile;
  final bool isSelf;
  final int initialTab;
  final int? followerCount;
  final int? followingCount;
  final bool isFollowing;
  final bool followBusy;
  final VoidCallback? onFollow;
  final VoidCallback? onMessage;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onMore;
  final VoidCallback? onBack;

  @override
  State<MobileProfileView> createState() => _MobileProfileViewState();
}

class _MobileProfileViewState extends State<MobileProfileView> {
  static const _green = Color(0xFF0EEA78);
  late int _tab;
  late Stream<List<PostsRecord>> _posts;
  late Stream<List<PostsRecord>> _tagged;
  late Stream<List<UserTrainingsRecord>> _trainings;
  Future<ProfileSocialState>? _social;

  String get _userId {
    final uid = widget.profile.uid.trim();
    return uid.isEmpty ? widget.profile.reference.id : uid;
  }

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab.clamp(0, 2);
    _bindData();
  }

  @override
  void didUpdateWidget(covariant MobileProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.reference.id != widget.profile.reference.id) {
      _bindData();
    }
  }

  void _bindData() {
    _posts = queryPostsByUserStream(_userId);
    _tagged = queryTaggedPostsByUserStream(_userId);
    _trainings = queryTrainingsByUserStream(_userId);
    if (widget.followerCount == null || widget.followingCount == null) {
      _social = ProfileRepository().socialState(_userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Stack(
        children: [
          CustomScrollView(
            key: PageStorageKey<String>('profile-$_userId-$_tab'),
            slivers: [
              SliverToBoxAdapter(child: _header()),
              SliverToBoxAdapter(child: _tabs()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                sliver: SliverToBoxAdapter(child: _content()),
              ),
            ],
          ),
          if (widget.isSelf)
            const Align(
              alignment: Alignment.bottomCenter,
              child: NavBarWidget(
                selectPageIndex: 5,
                hidden: false,
                overlay: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _header() {
    return FutureBuilder<ProfileSocialState>(
      future: _social,
      builder: (context, snapshot) {
        final followers =
            widget.followerCount ?? snapshot.data?.followerCount ?? 0;
        final following =
            widget.followingCount ?? snapshot.data?.followingCount ?? 0;
        return Container(
          padding: EdgeInsets.fromLTRB(
              18, MediaQuery.paddingOf(context).top + 10, 18, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  if (!widget.isSelf)
                    IconButton(
                      key: const Key('profile-back'),
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      '@${widget.profile.username}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    key: const Key('profile-more'),
                    onPressed: widget.onMore,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.more_horiz_rounded),
                  ),
                ],
              ),
              ProfileStoryAvatarWidget(
                userId: _userId,
                photoUrl: widget.profile.photoUrl,
                isCurrentUser: widget.isSelf,
              ),
              const SizedBox(height: 8),
              if (widget.profile.displayName.isNotEmpty)
                Text(widget.profile.displayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
              if (widget.profile.bio.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(widget.profile.bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF333333))),
              ],
              if (widget.profile.website.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(widget.profile.website,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFF176D43), fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 16),
              Row(
                children: widget.isSelf
                    ? [
                        _headerButton('Edit profile', widget.onEdit,
                            background: Colors.black, foreground: Colors.white),
                        const SizedBox(width: 10),
                        _headerButton('Share profile', widget.onShare,
                            background: const Color(0xFFAAB5BF),
                            foreground: Colors.white),
                      ]
                    : [
                        _headerButton(
                            widget.isFollowing ? 'Following' : 'Follow',
                            widget.followBusy ? null : widget.onFollow,
                            background: widget.isFollowing
                                ? const Color(0xFF202020)
                                : Colors.black,
                            foreground: Colors.white),
                        const SizedBox(width: 10),
                        _headerButton('Message', widget.onMessage,
                            background: _green, foreground: Colors.black),
                      ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _stat('Level', '★'),
                  _divider(),
                  _stat('Followers', '$followers'),
                  _divider(),
                  _stat('Following', '$following'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _headerButton(String label, VoidCallback? onPressed,
      {required Color background, required Color foreground}) {
    return Expanded(
      child: SizedBox(
        height: 48,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            disabledBackgroundColor: background.withValues(alpha: .6),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: label == 'Level' ? _green : Colors.black,
                    fontSize: label == 'Level' ? 28 : 20,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(color: Colors.black, fontSize: 13)),
          ],
        ),
      );

  Widget _divider() => Container(width: 1.5, height: 43, color: Colors.black);

  Widget _tabs() {
    const labels = ['Posts', 'Tagged', 'Workout'];
    return Row(
      children: List.generate(labels.length, (index) {
        final selected = _tab == index;
        return Expanded(
          child: InkWell(
            key: Key('profile-tab-$index'),
            onTap: () => setState(() => _tab = index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 17),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: selected ? _green : Colors.transparent, width: 3),
                ),
              ),
              child: Text(labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF777777),
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        );
      }),
    );
  }

  Widget _content() {
    if (_tab == 2) return _workoutList();
    return _postGrid(_tab == 0 ? _posts : _tagged);
  }

  Widget _postGrid(Stream<List<PostsRecord>> stream) {
    return StreamBuilder<List<PostsRecord>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(color: _green)));
        }
        final posts = snapshot.data!;
        if (posts.isEmpty) return _empty('No posts yet');
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: .82,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) => _postTile(posts[index]),
        );
      },
    );
  }

  Widget _postTile(PostsRecord post) {
    final rawPhoto =
        post.postPhoto.isNotEmpty ? post.postPhoto : post.postPhotoFood;
    final rawVideo =
        post.postVideo.isNotEmpty ? post.postVideo : post.postVideoFood;
    final thumb = post.videoThumbnail.isNotEmpty
        ? functions.bunnyCDNImagePath(post.videoThumbnail)
        : functions.bunnyCDNImagePath(rawPhoto);
    return InkWell(
      onTap: () => context.pushNamed(
        PostDetailsWidget.routeName,
        queryParameters: {
          'post': serializeParam(post.reference, ParamType.DocumentReference),
        }.withoutNulls,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumb.isNotEmpty)
              CachedNetworkImage(
                imageUrl: thumb,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const ColoredBox(
                  color: Color(0xFF171717),
                  child: Icon(Icons.image_not_supported_outlined,
                      color: Color(0xFF666666)),
                ),
              )
            else
              const ColoredBox(color: Color(0xFF171717)),
            if (rawVideo.isNotEmpty)
              const Positioned(
                  top: 7,
                  left: 7,
                  child: Icon(Icons.play_circle_fill_rounded,
                      color: Colors.white, size: 23)),
            if (post.foodPost)
              const Positioned(
                  top: 6, right: 6, child: FoodPostBadge(size: 26)),
          ],
        ),
      ),
    );
  }

  Widget _workoutList() {
    return StreamBuilder<List<UserTrainingsRecord>>(
      stream: _trainings,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(color: _green)));
        }
        final trainings = snapshot.data!;
        if (trainings.isEmpty) return _empty('No workouts yet');
        return Column(
          children: [
            for (final training in trainings) _workoutCard(training),
          ],
        );
      },
    );
  }

  Widget _workoutCard(UserTrainingsRecord training) {
    final cover = functions.bunnyCDNImagePath(training.trainingBackgroundImage);
    return InkWell(
      key: Key('profile-workout-${training.reference.id}'),
      onTap: () async {
        final value = await TrainingRepository().get(training.reference.id);
        if (value != null && mounted) {
          await showGymFeedEventDetails(context, value);
        }
      },
      child: Container(
        height: 154,
        margin: const EdgeInsets.only(bottom: 13),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF2B2B2B)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cover.isNotEmpty)
              CachedNetworkImage(imageUrl: cover, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x22000000), Color(0xEF080808)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xD9173A25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          training.trainingCategory.isEmpty
                              ? 'Workout'
                              : training.trainingCategory,
                          style: const TextStyle(
                              color: _green,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded,
                          color: Colors.white),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    training.trainingTitle.isEmpty
                        ? 'Workout'
                        : training.trainingTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 13,
                    children: [
                      _meta(
                          Icons.calendar_today_rounded, training.trainingDate),
                      _meta(
                          Icons.schedule_rounded,
                          training.duration > 0
                              ? '${training.duration} min'
                              : training.trainingTime),
                      _meta(Icons.fitness_center_rounded,
                          training.difficultyLevel),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFAAAAAA), size: 14),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12)),
      ],
    );
  }

  Widget _empty(String label) => Container(
        height: 190,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF252525)),
        ),
        child: Text(label,
            style: const TextStyle(color: Color(0xFF888888), fontSize: 15)),
      );
}
