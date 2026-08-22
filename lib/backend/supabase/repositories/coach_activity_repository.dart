import 'dart:convert';

import '/backend/supabase/supabase.dart';

double _coachNumber(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

/// Persists the useful output of Coach scans instead of treating the result
/// screen as disposable UI state.
class CoachActivityRepository {
  SupabaseClient get _db => supabase;
  String? get _uid => _db.auth.currentUser?.id;

  Future<Map<String, dynamic>?> latestBodyScan() async {
    final uid = _requireUid();
    final row = await _db
        .from('coach_activity_log')
        .select('result')
        .eq('user_id', uid)
        .eq('tool', 'body_scan')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    final result = row?['result'];
    if (result is Map<String, dynamic>) return result;
    if (result is Map) {
      return result.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  Future<void> recordEquipmentScan({
    required String photoUrl,
    required Map<String, dynamic> result,
  }) async {
    final uid = _requireUid();
    // The dated, user-owned row is the source of truth for scan history and
    // Coach hub statistics. If it fails, the scanner treats the operation as
    // failed and refunds the trial use.
    await _recordActivity(
      uid: uid,
      tool: 'equipment_scan',
      photoUrl: photoUrl,
      result: result,
    );

    // Keep the original profile summary fields in sync for legacy screens.
    // They are compatibility data rather than the source of truth.
    try {
      final row = await _db
          .from('profile_private')
          .select('vision_button')
          .eq('id', uid)
          .maybeSingle();
      final current = (row?['vision_button'] as num?)?.toInt() ?? 0;
      await _db.from('profile_private').update({
        'vision_button': current + 1,
        'vision_url': photoUrl,
        'gemini_parse3': jsonEncode(result),
        'description_scanner': (result['name'] ?? '').toString(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', uid);
    } catch (_) {
      // The normalized scan remains safely stored in coach_activity_log.
    }
  }

  Future<void> recordBodyScan(
    Map<String, dynamic> result, {
    String photoUrl = '',
  }) async {
    final uid = _requireUid();
    final bodyFat = _coachNumber(result['body_fat']);
    final leanMass = _coachNumber(result['lean_mass_kg']);
    final leanMassPercent = _coachNumber(result['lean_mass_percent']);
    final essentialFat = _coachNumber(result['essential_fat_percent']);
    final unbeneficialFat = _coachNumber(result['unbeneficial_fat_percent']);
    final leanMassIndex = _coachNumber(result['lean_mass_index']);
    final fatMassIndex = _coachNumber(result['fat_mass_index']);
    final restingCalories = _coachNumber(result['resting_metabolic_rate_kcal']);
    await _db.from('profile_private').update({
      if (bodyFat > 0) 'bfat2': bodyFat,
      if (bodyFat > 0) 'bfat': bodyFat.toStringAsFixed(1),
      if (leanMass > 0) 'lean_mass2': leanMass,
      if (leanMassPercent > 0) 'leanmass': leanMassPercent.toStringAsFixed(1),
      if (essentialFat > 0) 'efat2': essentialFat,
      if (essentialFat > 0) 'efat': essentialFat.toStringAsFixed(1),
      if (unbeneficialFat > 0) 'ufat2': unbeneficialFat,
      if (unbeneficialFat > 0) 'ufat': unbeneficialFat.toStringAsFixed(1),
      if (leanMassIndex > 0) 'lean_mass_index': leanMassIndex.round(),
      if (fatMassIndex > 0) 'fat_mass_index': fatMassIndex.round(),
      if (restingCalories > 0)
        'calories_burnt': restingCalories.round().toString(),
      'gemini_parse': jsonEncode(result),
      'personal_trainer_suggestions':
          (result['recommendation'] ?? '').toString(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', uid);

    // Added by migration 0014. The profile summary and dated activity entry
    // are both kept so the Coach hub can show lifetime and weekly progress.
    try {
      final row = await _db
          .from('profile_private')
          .select('body_scan_count')
          .eq('id', uid)
          .maybeSingle();
      final current = (row?['body_scan_count'] as num?)?.toInt() ?? 0;
      await _db
          .from('profile_private')
          .update({'body_scan_count': current + 1}).eq('id', uid);
    } catch (_) {}
    await _recordActivity(
      uid: uid,
      tool: 'body_scan',
      photoUrl: photoUrl,
      result: result,
    );
  }

  Future<void> _recordActivity({
    required String uid,
    required String tool,
    String photoUrl = '',
    required Map<String, dynamic> result,
  }) async {
    await _db.from('coach_activity_log').insert({
      'user_id': uid,
      'tool': tool,
      'photo_url': photoUrl,
      'result': result,
    });
  }

  String _requireUid() {
    final uid = _uid;
    if (uid == null) throw StateError('Sign in to save Coach activity.');
    return uid;
  }
}
