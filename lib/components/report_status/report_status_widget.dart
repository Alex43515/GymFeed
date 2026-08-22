import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/backend/supabase/repositories/content_safety_repository.dart';
import '/components/content_safety/report_content_sheet.dart';

class ReportStatusWidget extends StatelessWidget {
  const ReportStatusWidget({
    super.key,
    this.userRecod,
    required this.postReference,
  });

  final UsersRecord? userRecod;
  final DocumentReference? postReference;

  @override
  Widget build(BuildContext context) {
    final reference = postReference;
    if (reference == null) return const SizedBox.shrink();
    return FutureBuilder<PostsRecord>(
      future: PostsRecord.getDocumentOnce(reference),
      builder: (context, postSnapshot) {
        if (!postSnapshot.hasData) return const _ReportLoading();
        final post = postSnapshot.data!;
        final authorRef = post.postUser;
        if (authorRef == null) return const SizedBox.shrink();
        if (userRecod != null) return _sheet(post, userRecod!);
        return FutureBuilder<UsersRecord>(
          future: UsersRecord.getDocumentOnce(authorRef),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return const _ReportLoading();
            return _sheet(post, userSnapshot.data!);
          },
        );
      },
    );
  }

  Widget _sheet(PostsRecord post, UsersRecord author) => ReportContentSheet(
        contentId: post.reference.id,
        authorId: post.postUser?.id ?? author.reference.id,
        authorUsername: author.username,
        imageUrl: post.postPhoto.isNotEmpty
            ? post.postPhoto
            : (post.postPhotoFood.isNotEmpty
                ? post.postPhotoFood
                : post.videoThumbnail),
        contentType: post.foodPost
            ? ReportedContentType.foodPost
            : ReportedContentType.post,
      );
}

class _ReportLoading extends StatelessWidget {
  const _ReportLoading();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 260,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF16E57A)),
        ),
      );
}
