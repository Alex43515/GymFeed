import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '/backend/supabase/database/profile.dart';
import '/backend/supabase/repositories/profile_repository.dart';
import '/backend/supabase/repositories/story_repository.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/upload_progress_screen.dart';
import '/flutter_flow/upload_data.dart';
import '/flutter_flow/uploaded_file.dart';

class StoryUploadWidget extends StatefulWidget {
  const StoryUploadWidget({
    super.key,
    this.repository,
    this.onCreated,
  });

  final StoryDataSource? repository;
  final FutureOr<void> Function(StoryItem story)? onCreated;

  @override
  State<StoryUploadWidget> createState() => _StoryUploadWidgetState();
}

class _StoryUploadWidgetState extends State<StoryUploadWidget> {
  static const _green = Color(0xFF13E879);
  bool _working = false;
  late Future<StoryGroup?> _recent;
  late Future<Profile?> _profile;

  StoryDataSource get _repository => widget.repository ?? StoryRepository();

  @override
  void initState() {
    super.initState();
    final uid = _repository.currentUserId;
    _recent = uid == null
        ? Future.value(null)
        : _repository.loadForUser(uid).catchError((_) => null);
    _profile = widget.repository == null
        ? ProfileRepository().getMyProfile().catchError((_) => null)
        : Future.value(null);
  }

  Future<void> _chooseSource({required bool camera}) async {
    if (_working) return;
    final video = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF171717),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF2C2C2C)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF505050),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_outlined, color: _green),
                title: const Text(
                  'Photo',
                  style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                ),
                onTap: () => Navigator.pop(sheetContext, false),
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined, color: _green),
                title: const Text(
                  'Video',
                  style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                ),
                onTap: () => Navigator.pop(sheetContext, true),
              ),
            ],
          ),
        ),
      ),
    );
    if (video == null || !mounted) return;
    await _pickAndUpload(video: video, camera: camera);
  }

  Future<void> _pickAndUpload({
    required bool video,
    required bool camera,
  }) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final selection = await selectMedia(
        storageFolderPath: 'stories',
        mediaSource: camera
            ? MediaSource.camera
            : video
                ? MediaSource.videoGallery
                : MediaSource.photoGallery,
        isVideo: video,
        imageQuality: video ? null : 88,
      );
      if (selection == null || selection.isEmpty) return;
      final selected = selection.first;
      StoryItem story;

      if (video) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compressing story video…'),
            duration: Duration(minutes: 2),
          ),
        );
        final localPath = selected.filePath;
        final compressed = kIsWeb
            ? FFUploadedFile(
                name: selected.storagePath.split('/').last,
                bytes: selected.bytes,
              )
            : await actions.compressVideo(localPath ?? '');
        if (compressed?.bytes == null || compressed!.bytes!.isEmpty) {
          throw StateError('The story video could not be compressed.');
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        final upload = await showUploadProgress(
          context,
          videoBytes: compressed.bytes!,
          videoTitle: 'GymFeed story',
          videoFileName: compressed.name ?? 'gymfeed-story.mp4',
        );
        final videoUrl = upload?.videoPlaylistUrl;
        if (videoUrl == null || videoUrl.isEmpty) {
          throw StateError('The story video could not be uploaded.');
        }
        story = await _repository.create(
          videoAssetId: upload?.videoAssetId,
          videoUrl: videoUrl,
        );
      } else {
        final upload = await showUploadProgress(
          context,
          imageBytes: selected.bytes,
          imageFileName: selected.storagePath.split('/').last,
        );
        final photoUrl = upload?.imageUrl;
        if (photoUrl == null || photoUrl.isEmpty) {
          throw StateError('The story photo could not be uploaded.');
        }
        story = await _repository.create(photoUrl: photoUrl);
      }

      await widget.onCreated?.call(story);
      if (mounted) Navigator.of(context).pop(story);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Story was not posted: $error')),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _reuseRecent(StoryItem item) async {
    if (_working || !item.hasMedia) return;
    setState(() => _working = true);
    try {
      final story = await _repository.create(
        photoUrl: item.isPhoto ? item.photoUrl : null,
        videoUrl: item.isVideo ? item.videoUrl : null,
      );
      await widget.onCreated?.call(story);
      if (mounted) Navigator.pop(context, story);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Story was not posted: $error')),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF4B4B4B),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                FutureBuilder<Profile?>(
                  future: _profile,
                  builder: (context, snapshot) {
                    final profile = snapshot.data;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _green,
                          ),
                          child: CircleAvatar(
                            backgroundColor: const Color(0xFF0D6E40),
                            backgroundImage:
                                profile?.photoUrl.isNotEmpty == true
                                    ? NetworkImage(profile!.photoUrl)
                                    : null,
                            child: profile?.photoUrl.isNotEmpty == true
                                ? null
                                : const Icon(Icons.person_rounded,
                                    color: Colors.white),
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -1,
                          child: Container(
                            width: 21,
                            height: 21,
                            decoration: BoxDecoration(
                              color: _green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF141414),
                                width: 2,
                              ),
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.black, size: 15),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add to your gym day',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Disappears after 24 hours',
                        style: TextStyle(
                          color: Color(0xFF92979E),
                          fontFamily: 'Poppins',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _working ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: KeyedSubtree(
                    key: const ValueKey('story-camera-photo'),
                    child: KeyedSubtree(
                      key: const ValueKey('story-camera-video'),
                      child: _StorySourceButton(
                        icon: Icons.photo_camera_outlined,
                        label: 'Camera',
                        description: 'Capture now',
                        enabled: !_working,
                        onTap: () => _chooseSource(camera: true),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: KeyedSubtree(
                    key: const ValueKey('story-gallery-photo'),
                    child: KeyedSubtree(
                      key: const ValueKey('story-gallery-video'),
                      child: _StorySourceButton(
                        icon: Icons.photo_library_outlined,
                        label: 'Gallery',
                        description: 'Choose media',
                        enabled: !_working,
                        onTap: () => _chooseSource(camera: false),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'Recent',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<StoryGroup?>(
              future: _recent,
              builder: (context, snapshot) {
                final recent = (snapshot.data?.stories ?? const <StoryItem>[])
                    .reversed
                    .take(4)
                    .toList();
                if (recent.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101010),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFF282828)),
                    ),
                    child: const Text(
                      'Your recent gym-day media will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF777C82),
                        fontFamily: 'Poppins',
                        fontSize: 11,
                      ),
                    ),
                  );
                }
                return SizedBox(
                  height: 82,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recent.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 9),
                    itemBuilder: (context, index) {
                      final item = recent[index];
                      return _RecentStoryTile(
                        item: item,
                        enabled: !_working,
                        onTap: () => _reuseRecent(item),
                      );
                    },
                  ),
                );
              },
            ),
            if (_working) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(
                minHeight: 3,
                color: _green,
                backgroundColor: Color(0xFF252525),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StorySourceButton extends StatelessWidget {
  const _StorySourceButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 124,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2A2A2A)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0C3A24),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: _StoryUploadWidgetState._green),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF83888E),
                    fontFamily: 'Poppins',
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _RecentStoryTile extends StatelessWidget {
  const _RecentStoryTile({
    required this.item,
    required this.enabled,
    required this.onTap,
  });

  final StoryItem item;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(13),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Container(
            width: 82,
            height: 82,
            color: const Color(0xFF102A1E),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.isPhoto)
                  Image.network(
                    item.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                if (item.isVideo)
                  const Center(
                    child: Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 30),
                  ),
                if (item.isVideo)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xB8000000),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.videocam_rounded,
                          color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}
