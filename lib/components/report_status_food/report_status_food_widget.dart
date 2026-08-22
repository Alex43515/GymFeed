import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/components/report_status/report_status_widget.dart';

/// Food posts use the same report sheet as normal posts. The post row supplies
/// the food-post discriminator so moderation receives the correct content type.
class ReportStatusFoodWidget extends StatelessWidget {
  const ReportStatusFoodWidget({
    super.key,
    this.userRecod,
    required this.postReference,
  });

  final UsersRecord? userRecod;
  final DocumentReference? postReference;

  @override
  Widget build(BuildContext context) => ReportStatusWidget(
        userRecod: userRecod,
        postReference: postReference,
      );
}
