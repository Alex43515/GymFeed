import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/backend/supabase/repositories/post_repository.dart';
import '/custom_code/widgets/feed_video_player.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/flutter_flow_util.dart';

class EditPostWidget extends StatefulWidget {
  const EditPostWidget({super.key, this.post});

  final PostsRecord? post;

  static const String routeName = 'EditPost';
  static const String routePath = 'editPost';

  @override
  State<EditPostWidget> createState() => _EditPostWidgetState();
}

class _EditPostWidgetState extends State<EditPostWidget> {
  static const _green = Color(0xFF0EEA78);
  static const _surface = Color(0xFF151515);
  static const _border = Color(0xFF2A2A2A);

  late final TextEditingController _caption;
  late final TextEditingController _location;
  late final TextEditingController _foodTitle;
  late final TextEditingController _foodDescription;
  late final TextEditingController _recipe;
  late final TextEditingController _nutritionFacts;
  late final TextEditingController _cookingTime;
  late final TextEditingController _mealType;
  late final TextEditingController _calories;
  late final TextEditingController _protein;
  late final TextEditingController _fats;
  late final TextEditingController _carbs;
  bool _saving = false;

  PostsRecord? get _post => widget.post;
  bool get _isFood => _post?.foodPost ?? false;

  @override
  void initState() {
    super.initState();
    final post = _post;
    _caption = TextEditingController(text: post?.postCaption ?? '');
    _location = TextEditingController(text: post?.location ?? '');
    _foodTitle = TextEditingController(text: post?.postTitleFood ?? '');
    _foodDescription =
        TextEditingController(text: post?.postDescriptionFood ?? '');
    _recipe = TextEditingController(text: post?.recepie ?? '');
    _nutritionFacts = TextEditingController(text: post?.nutritionFacts ?? '');
    _cookingTime = TextEditingController(text: post?.cookingTime ?? '');
    _mealType = TextEditingController(text: post?.mealType ?? '');
    _calories = TextEditingController(
      text: post != null && post.hasCalories() ? '${post.calories}' : '',
    );
    _protein = TextEditingController(
      text: post != null && post.hasProtein() ? '${post.protein}' : '',
    );
    _fats = TextEditingController(text: post?.fats ?? '');
    _carbs = TextEditingController(text: post?.carbs ?? '');
  }

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _caption,
      _location,
      _foodTitle,
      _foodDescription,
      _recipe,
      _nutritionFacts,
      _cookingTime,
      _mealType,
      _calories,
      _protein,
      _fats,
      _carbs,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  int _number(TextEditingController controller) =>
      int.tryParse(controller.text.trim()) ?? 0;

  Future<void> _save() async {
    final post = _post;
    if (_saving || post == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    try {
      await PostRepository().updatePost(
        post.reference.id,
        caption: _caption.text.trim(),
        location: _location.text.trim(),
        foodTitle: _isFood ? _foodTitle.text.trim() : null,
        foodDescription: _isFood ? _foodDescription.text.trim() : null,
        recipe: _isFood ? _recipe.text.trim() : null,
        nutritionFacts: _isFood ? _nutritionFacts.text.trim() : null,
        cookingTime: _isFood ? _cookingTime.text.trim() : null,
        mealType: _isFood ? _mealType.text.trim() : null,
        calories: _isFood ? _number(_calories) : null,
        protein: _isFood ? _number(_protein) : null,
        fats: _isFood ? _fats.text.trim() : null,
        carbs: _isFood ? _carbs.text.trim() : null,
      );
      if (mounted) context.pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save this post. Try again.')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    if (post == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('Post not found', style: TextStyle(color: Colors.white)),
        ),
      );
    }
    final rawPhoto =
        post.postPhoto.isNotEmpty ? post.postPhoto : post.postPhotoFood;
    final rawVideo =
        post.postVideo.isNotEmpty ? post.postVideo : post.postVideoFood;
    final photo = functions.bunnyCDNImagePath(rawPhoto);
    final video = functions.bunnyCDNVideoPath(rawVideo);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 88,
        leading: TextButton(
          onPressed: _saving ? null : () => context.pop(false),
          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        title: Text(
          _isFood ? 'Edit food post' : 'Edit post',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            key: const Key('save-post-edit'),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _green,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: _green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
          children: [
            _mediaPreview(photo: photo, video: video, post: post),
            const SizedBox(height: 18),
            _field('Caption', _caption, maxLines: 4),
            _field('Location', _location, icon: Icons.location_on_outlined),
            if (_isFood) ...[
              const Padding(
                padding: EdgeInsets.only(top: 10, bottom: 14),
                child: Row(
                  children: [
                    Icon(Icons.restaurant_rounded, color: _green),
                    SizedBox(width: 9),
                    Text(
                      'Meal details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _field('Meal name', _foodTitle),
              _field('Description', _foodDescription, maxLines: 3),
              _field('Recipe and preparation', _recipe, maxLines: 7),
              _field('Nutrition facts', _nutritionFacts, maxLines: 4),
              Row(
                children: [
                  Expanded(child: _field('Meal type', _mealType)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('Cooking time', _cookingTime)),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      'Calories',
                      _calories,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      'Protein (g)',
                      _protein,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _field('Fat', _fats)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('Carbs', _carbs)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _mediaPreview({
    required String photo,
    required String video,
    required PostsRecord post,
  }) {
    return AspectRatio(
      aspectRatio: 1.25,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ColoredBox(
          color: _surface,
          child: video.isNotEmpty
              ? FeedVideoPlayer(
                  videoUrl: video,
                  thumbnailUrl: post.videoThumbnail.isNotEmpty
                      ? functions.bunnyCDNImagePath(post.videoThumbnail)
                      : (photo.isEmpty ? null : photo),
                  borderRadius: 20,
                )
              : photo.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: photo,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const ColoredBox(color: _surface),
                      errorWidget: (_, __, ___) => const _MissingMediaPreview(),
                    )
                  : const _MissingMediaPreview(),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextField(
        key: Key('edit-${label.toLowerCase().replaceAll(' ', '-')}'),
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        cursorColor: _green,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF9A9A9A)),
          prefixIcon: icon == null ? null : Icon(icon, color: _green),
          filled: true,
          fillColor: _surface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: _green),
          ),
        ),
      ),
    );
  }
}

class _MissingMediaPreview extends StatelessWidget {
  const _MissingMediaPreview();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: Color(0xFF777777),
              size: 38,
            ),
            SizedBox(height: 8),
            Text(
              'Media unavailable',
              style: TextStyle(color: Color(0xFF999999)),
            ),
          ],
        ),
      );
}
