import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/backend/supabase/repositories/content_safety_repository.dart';
import '/components/content_safety/report_content_sheet.dart';

class ReportStatusReelWidget extends StatelessWidget {
  const ReportStatusReelWidget({
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
    return FutureBuilder<UserTrainingsRecord>(
      future: UserTrainingsRecord.getDocumentOnce(reference),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 260,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF16E57A)),
            ),
          );
        }
        final training = snapshot.data!;
        final authorId =
            training.userTraining?.id ?? userRecod?.reference.id ?? '';
        return ReportContentSheet(
          contentId: training.reference.id,
          authorId: authorId,
          authorUsername: userRecod?.username ?? '',
          contentType: ReportedContentType.workout,
        );
      },
    );
  }
}
