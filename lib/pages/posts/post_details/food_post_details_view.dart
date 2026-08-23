import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '/backend/backend.dart';
import '/backend/supabase/repositories/post_repository.dart';
import '/components/post_type_badge/post_type_badge.dart';
import '/components/send_post/send_post_widget.dart';
import '/custom_code/widgets/feed_video_player.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/posts/comments/comments_widget.dart';

class FoodPostDetailsView extends StatefulWidget {
  const FoodPostDetailsView({super.key, required this.post});
  final PostsRecord post;

  @override
  State<FoodPostDetailsView> createState() => _FoodPostDetailsViewState();
}

class _FoodPostDetailsViewState extends State<FoodPostDetailsView> {
  static const _green = Color(0xFF0EEA78);
  int _selectedTab = 0;
  bool _liked = false;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    PostRepository().isLiked(widget.post.reference.id).then((value) {
      if (mounted) setState(() => _liked = value);
    });
  }

  Future<void> _toggleLike() async {
    if (_working || !widget.post.allowLikes) return;
    setState(() {
      _working = true;
      _liked = !_liked;
    });
    try {
      if (_liked) {
        await PostRepository().likePost(widget.post.reference.id);
      } else {
        await PostRepository().unlikePost(widget.post.reference.id);
      }
    } catch (_) {
      if (mounted) setState(() => _liked = !_liked);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _openMap() async {
    final value = widget.post.location.trim();
    if (value.isEmpty) return;
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': value,
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final rawPhoto =
        post.postPhoto.isNotEmpty ? post.postPhoto : post.postPhotoFood;
    final rawVideo =
        post.postVideo.isNotEmpty ? post.postVideo : post.postVideoFood;
    final photo = functions.bunnyCDNImagePath(rawPhoto);
    final video = functions.bunnyCDNVideoPath(rawVideo);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 4 / 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: video.isNotEmpty
                    ? FeedVideoPlayer(
                        videoUrl: video,
                        thumbnailUrl: post.videoThumbnail.isEmpty
                            ? null
                            : functions.bunnyCDNImagePath(post.videoThumbnail),
                        borderRadius: 18,
                        fit: BoxFit.contain,
                      )
                    : CachedNetworkImage(
                        imageUrl: photo,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const ColoredBox(
                          color: Color(0xFF151515),
                          child: Icon(Icons.image_not_supported_outlined,
                              color: Color(0xFF777777)),
                        ),
                      ),
              ),
            ),
            const Positioned(
                top: 12, right: 12, child: FoodPostBadge(size: 32)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              key: const Key('food-details-like'),
              onPressed: _toggleLike,
              icon: Icon(_liked ? Icons.favorite : Icons.favorite_border,
                  color: _liked ? _green : Colors.white, size: 28),
            ),
            if (post.allowComments)
              IconButton(
                onPressed: () => context.pushNamed(
                  CommentsWidget.routeName,
                  queryParameters: {
                    'post': serializeParam(
                        post.reference, ParamType.DocumentReference),
                  }.withoutNulls,
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded,
                    color: Colors.white, size: 27),
              ),
            IconButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) =>
                    SendPostWidget(post: post.reference, post2: post),
              ),
              icon: const Icon(Icons.send_outlined,
                  color: Colors.white, size: 27),
            ),
            const Spacer(),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(post.postCaption,
              style: const TextStyle(color: Colors.white, fontSize: 15)),
        ),
        if (post.callToActionEnabled && post.callToActionLink.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 0),
            child: FilledButton.icon(
              onPressed: () => launchUrl(Uri.parse(post.callToActionLink),
                  mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(post.callToActionText.isEmpty
                  ? 'Learn more'
                  : post.callToActionText),
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: const Color(0xFF07150D),
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        const SizedBox(height: 18),
        Row(
          key: const Key('food-details-tabs'),
          children: [
            _tabButton('Comments', 0),
            _tabButton('Info', 1),
          ],
        ),
        ColoredBox(
          color: const Color(0xFF080808),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: KeyedSubtree(
              key: ValueKey(_selectedTab),
              child: _selectedTab == 0 ? _comments(post) : _info(post),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: 2.5,
                color: selected ? _green : const Color(0xFF202020),
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF888888),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _comments(PostsRecord post) {
    return StreamBuilder<List<CommentsRecord>>(
      stream: queryCommentsRecord(parent: post.reference, limit: 20),
      builder: (context, snapshot) {
        final comments = snapshot.data ?? const <CommentsRecord>[];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _green));
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 30),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (comments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 50),
                child: Text('No comments yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF888888))),
              ),
            for (final comment in comments)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF173A25),
                  child: Icon(Icons.person_rounded, color: _green),
                ),
                title: Text(comment.comment,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              ),
            FilledButton(
              onPressed: () => context.pushNamed(
                CommentsWidget.routeName,
                queryParameters: {
                  'post': serializeParam(
                      post.reference, ParamType.DocumentReference),
                }.withoutNulls,
              ),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF191919),
                  foregroundColor: _green),
              child: const Text('Add a comment'),
            ),
          ]),
        );
      },
    );
  }

  Widget _info(PostsRecord post) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Meal', post.postTitleFood),
      MapEntry('Description', post.postDescriptionFood),
      MapEntry('Meal type', post.mealType),
      MapEntry('Preparation time', post.cookingTime),
      MapEntry('Calories', post.hasCalories() ? '${post.calories} kcal' : ''),
      MapEntry('Protein', post.hasProtein() ? '${post.protein} g' : ''),
      MapEntry('Carbs', post.carbs),
      MapEntry('Fat', post.fats),
      MapEntry('Nutrition facts', post.nutritionFacts),
      MapEntry('Recipe & preparation', post.recepie),
    ].where((entry) => entry.value.trim().isNotEmpty).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 30),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final entry in rows)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF292929)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key,
                    style: const TextStyle(
                        color: _green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 5),
                Text(entry.value,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        if (post.location.isNotEmpty)
          ListTile(
            key: const Key('food-post-location-link'),
            onTap: _openMap,
            tileColor: const Color(0xFF151515),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            leading: const Icon(Icons.location_on_rounded, color: _green),
            title: Text(post.location,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
            trailing: const Icon(Icons.open_in_new_rounded, color: _green),
          ),
      ]),
    );
  }
}
