import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../supabase/supabase.dart';

const _pendingAttributionKey = 'gymfeed_pending_marketing_attribution';

/// Saves the first GymFeed marketing touch until the visitor authenticates.
Future<void> captureMarketingAttribution(Uri uri) async {
  final contentKey = uri.queryParameters['utm_content']?.trim();
  if (contentKey == null || contentKey.length < 4) return;

  final preferences = await SharedPreferences.getInstance();
  if (preferences.containsKey(_pendingAttributionKey)) return;

  await preferences.setString(
    _pendingAttributionKey,
    jsonEncode({
      'attribution_key': contentKey,
      'source': uri.queryParameters['utm_source'],
      'medium': uri.queryParameters['utm_medium'],
      'campaign': uri.queryParameters['utm_campaign'],
      'captured_at': DateTime.now().toUtc().toIso8601String(),
    }),
  );
}

/// Claims a pending touch server-side. Supabase validates the content key and
/// always preserves the user's first successfully claimed attribution.
Future<void> claimPendingMarketingAttribution() async {
  if (supabase.auth.currentUser == null) return;
  final preferences = await SharedPreferences.getInstance();
  final encoded = preferences.getString(_pendingAttributionKey);
  if (encoded == null) return;

  try {
    final attribution = jsonDecode(encoded) as Map<String, dynamic>;
    await supabase.rpc('claim_marketing_attribution', params: {
      'p_attribution_key': attribution['attribution_key'],
      'p_source': attribution['source'],
      'p_medium': attribution['medium'],
      'p_campaign': attribution['campaign'],
      'p_session_id': null,
      'p_properties': {
        'captured_at': attribution['captured_at'],
        'client': kIsWeb ? 'web' : defaultTargetPlatform.name,
      },
    });
    await preferences.remove(_pendingAttributionKey);
  } catch (error) {
    // Keep the pending touch so a transient network/auth error can retry on
    // the next authenticated app start.
    debugPrint('Marketing attribution claim failed: $error');
  }
}
