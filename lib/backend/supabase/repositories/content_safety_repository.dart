import 'dart:convert';

import 'package:http/http.dart' as http;

import '/backend/supabase/supabase.dart';

enum ReportedContentType { post, foodPost, workout, account }

extension ReportedContentTypeValue on ReportedContentType {
  String get databaseValue => switch (this) {
        ReportedContentType.post => 'post',
        ReportedContentType.foodPost => 'food_post',
        ReportedContentType.workout => 'workout',
        ReportedContentType.account => 'account',
      };

  String get label => switch (this) {
        ReportedContentType.foodPost => 'food post',
        ReportedContentType.workout => 'workout',
        ReportedContentType.account => 'account',
        ReportedContentType.post => 'post',
      };
}

class ContentReportResult {
  const ContentReportResult({
    required this.reportId,
    required this.moderationEmailQueued,
  });

  final String reportId;
  final bool moderationEmailQueued;
}

/// Writes abuse reports to Supabase and asks the GymFeed website mail relay to
/// notify moderation. The database write is authoritative; email failure never
/// loses the report and is visible to the confirmation UI.
class ContentSafetyRepository {
  SupabaseClient get _db => supabase;

  Future<ContentReportResult> submitReport({
    required String contentId,
    required String reportedUserId,
    required ReportedContentType contentType,
    required String reason,
    String details = '',
    String imageUrl = '',
  }) async {
    final session = _db.auth.currentSession;
    final reporterId = session?.user.id;
    if (session == null || reporterId == null) {
      throw StateError('Sign in before submitting a report.');
    }
    if (contentId.trim().isEmpty || reportedUserId.trim().isEmpty) {
      throw ArgumentError('The reported content is unavailable.');
    }
    if (reportedUserId == reporterId) {
      throw ArgumentError('You cannot report your own content.');
    }

    Map<String, dynamic> row;
    try {
      row = await _db
          .from('reports')
          .insert({
            'reporter_id': reporterId,
            'reported_user_id': reportedUserId,
            'post_ref': contentId,
            'post_image': imageUrl,
            'content_type': contentType.databaseValue,
            'reason': reason,
            'details': details,
            'metadata': {
              'app': 'gymfeed',
              'source': 'content_report_sheet',
            },
          })
          .select('id')
          .single();
    } catch (_) {
      // Keeps reporting operational while migration 0027 is being rolled out.
      row = await _db
          .from('reports')
          .insert({
            'reporter_id': reporterId,
            'post_ref': contentId,
            'post_image': imageUrl,
            'details': '$reason${details.trim().isEmpty ? '' : ': $details'}',
          })
          .select('id')
          .single();
    }

    final reportId = row['id'].toString();
    final emailQueued = await _notifyModeration(
      accessToken: session.accessToken,
      reportId: reportId,
      contentId: contentId,
      reportedUserId: reportedUserId,
      contentType: contentType.databaseValue,
      reason: reason,
      details: details,
      imageUrl: imageUrl,
    );
    if (emailQueued) {
      try {
        await _db.rpc(
          'mark_report_notified',
          params: {'p_report_id': reportId},
        );
      } catch (_) {
        // The report itself is already safely stored. Older schemas do not yet
        // have notified_at and should not turn that into a failed submission.
      }
    }
    return ContentReportResult(
      reportId: reportId,
      moderationEmailQueued: emailQueued,
    );
  }

  Future<bool> _notifyModeration({
    required String accessToken,
    required String reportId,
    required String contentId,
    required String reportedUserId,
    required String contentType,
    required String reason,
    required String details,
    required String imageUrl,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('https://gymfeed.io/report-mail.php'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'report_id': reportId,
              'content_id': contentId,
              'reported_user_id': reportedUserId,
              'content_type': contentType,
              'reason': reason,
              'details': details,
              'image_url': imageUrl,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
