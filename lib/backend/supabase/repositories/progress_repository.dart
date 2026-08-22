import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '/backend/supabase/database/profile.dart';
import '/backend/supabase/repositories/profile_repository.dart';
import '/backend/supabase/supabase.dart';

double? _number(dynamic value) {
  if (value is num) return value.toDouble();
  final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(value?.toString() ?? '');
  return double.tryParse(match?.group(0) ?? '');
}

DateTime _month(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  return DateTime(parsed.year, parsed.month);
}

String progressMonthKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}';

class ProgressEntry {
  const ProgressEntry({
    required this.id,
    required this.month,
    this.photoUrl = '',
    this.weightKg,
    this.bodyFatPercentage,
    this.note = '',
    this.legacySlot,
  });

  final String id;
  final DateTime month;
  final String photoUrl;
  final double? weightKg;
  final double? bodyFatPercentage;
  final String note;
  final int? legacySlot;

  String get monthKey => progressMonthKey(month);

  ProgressEntry copyWith({
    String? id,
    DateTime? month,
    String? photoUrl,
    double? weightKg,
    bool clearWeight = false,
    double? bodyFatPercentage,
    bool clearBodyFat = false,
    String? note,
    int? legacySlot,
    bool clearLegacySlot = false,
  }) =>
      ProgressEntry(
        id: id ?? this.id,
        month: month ?? this.month,
        photoUrl: photoUrl ?? this.photoUrl,
        weightKg: clearWeight ? null : weightKg ?? this.weightKg,
        bodyFatPercentage:
            clearBodyFat ? null : bodyFatPercentage ?? this.bodyFatPercentage,
        note: note ?? this.note,
        legacySlot: clearLegacySlot ? null : legacySlot ?? this.legacySlot,
      );

  factory ProgressEntry.fromRow(Map<String, dynamic> row) => ProgressEntry(
        id: (row['id'] ?? '').toString(),
        month: _month(row['month_start']),
        photoUrl: (row['photo_url'] ?? '').toString(),
        weightKg: _number(row['weight_kg']),
        bodyFatPercentage: _number(row['body_fat_percentage']),
        note: (row['note'] ?? '').toString(),
        legacySlot: (row['legacy_slot'] as num?)?.toInt(),
      );

  Map<String, dynamic> toLocalJson() => {
        'id': id,
        'month_start': '${monthKey}-01',
        'photo_url': photoUrl,
        'weight_kg': weightKg,
        'body_fat_percentage': bodyFatPercentage,
        'note': note,
        'legacy_slot': legacySlot,
      };
}

class ProgressOverview {
  const ProgressOverview({
    this.weightKg = 0,
    this.bodyFatPercentage = 0,
    this.workoutsPerWeek = '',
    this.sessionLength = '',
    this.workoutLevel = '',
    this.workoutPlan = '',
    this.mealPlan = '',
    this.trainerSuggestion = '',
  });

  final double weightKg;
  final double bodyFatPercentage;
  final String workoutsPerWeek;
  final String sessionLength;
  final String workoutLevel;
  final String workoutPlan;
  final String mealPlan;
  final String trainerSuggestion;

  factory ProgressOverview.fromProfile(Profile? profile) {
    if (profile == null) return const ProgressOverview();
    return ProgressOverview(
      weightKg: profile.weight.toDouble(),
      bodyFatPercentage:
          profile.bfat2 > 0 ? profile.bfat2 : (_number(profile.bfat) ?? 0),
      workoutsPerWeek: profile.workouts,
      sessionLength: profile.workoutLenght,
      workoutLevel: profile.workoutLevel,
      workoutPlan: profile.workoutPlan.isNotEmpty
          ? profile.workoutPlan
          : profile.gptprompt,
      mealPlan: profile.mealPlan,
      trainerSuggestion: profile.personalTrainerSuggestions,
    );
  }
}

class ProgressData {
  const ProgressData({required this.overview, required this.entries});

  final ProgressOverview overview;
  final List<ProgressEntry> entries;
}

/// Owner-only progress persistence.
///
/// New installations use `progress_entries`. Until migration 0013 is deployed,
/// the repository preserves the legacy Supabase photo columns and stores the
/// per-month numeric metadata locally, so existing users can use the redesigned
/// page immediately without losing their seven historical photos.
class ProgressRepository {
  SupabaseClient get _db => supabase;
  String? get _uid => _db.auth.currentUser?.id;

  String _localKey(String uid) => 'gymfeed_progress_entries_v1_$uid';

  Future<ProgressData> load() async {
    final uid = _uid;
    final profile = await ProfileRepository().getMyProfile();
    if (uid == null) {
      return ProgressData(
        overview: ProgressOverview.fromProfile(profile),
        entries: const [],
      );
    }

    final merged = <String, ProgressEntry>{};
    for (final entry in await _loadLocal(uid)) {
      merged[entry.monthKey] = entry;
    }
    try {
      final rows = await _db
          .from('progress_entries')
          .select()
          .eq('user_id', uid)
          .order('month_start', ascending: true);
      for (final raw in (rows as List)) {
        final entry = ProgressEntry.fromRow(raw as Map<String, dynamic>);
        merged[entry.monthKey] = entry;
      }
    } catch (_) {
      // Migration 0013 may not yet be deployed; legacy data is merged below.
    }

    if (profile != null) {
      final photos = <String>[
        profile.progressImage,
        profile.progressImage2,
        profile.progressImage3,
        profile.progressImage4,
        profile.progressImage5,
        profile.progressImage6,
        profile.progressImage12,
      ];
      final usedSlots = <int>[
        for (var index = 0; index < photos.length; index++)
          if (photos[index].trim().isNotEmpty) index,
      ];
      if (usedSlots.isNotEmpty) {
        final lastSlot = usedSlots.last;
        final now = DateTime.now();
        for (final slot in usedSlots) {
          final month = DateTime(now.year, now.month - (lastSlot - slot));
          final key = progressMonthKey(month);
          final existing = merged[key];
          merged[key] = ProgressEntry(
            id: existing?.id ?? 'legacy-$slot',
            month: month,
            photoUrl: existing?.photoUrl.isNotEmpty == true
                ? existing!.photoUrl
                : photos[slot],
            weightKg: existing?.weightKg ??
                (slot == lastSlot && profile.weight > 0
                    ? profile.weight.toDouble()
                    : null),
            bodyFatPercentage: existing?.bodyFatPercentage ??
                (slot == lastSlot && profile.bfat2 > 0 ? profile.bfat2 : null),
            note: existing?.note ?? '',
            legacySlot: existing?.legacySlot ?? slot,
          );
        }
      }
    }

    final entries = merged.values.toList()
      ..sort((a, b) => a.month.compareTo(b.month));
    return ProgressData(
      overview: ProgressOverview.fromProfile(profile),
      entries: entries,
    );
  }

  Future<void> saveOverview(ProgressOverview overview) async {
    final uid = _requireUid();
    await _db.from('profile_private').update({
      'weight_kg': overview.weightKg.round(),
      'bfat2': overview.bodyFatPercentage,
      'workouts': overview.workoutsPerWeek,
      'workout_length': overview.sessionLength,
      'workout_level': overview.workoutLevel,
      'workout_plan': overview.workoutPlan,
      'meal_plan': overview.mealPlan,
      'personal_trainer_suggestions': overview.trainerSuggestion,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', uid);
  }

  Future<ProgressEntry> saveEntry(ProgressEntry input) async {
    final uid = _requireUid();
    var entry =
        input.copyWith(month: DateTime(input.month.year, input.month.month));
    if (entry.photoUrl.isNotEmpty && entry.legacySlot == null) {
      entry = entry.copyWith(legacySlot: await _firstAvailableLegacySlot());
    }

    try {
      final row = await _db
          .from('progress_entries')
          .upsert({
            'user_id': uid,
            'month_start': '${entry.monthKey}-01',
            'photo_url': entry.photoUrl,
            'weight_kg': entry.weightKg,
            'body_fat_percentage': entry.bodyFatPercentage,
            'note': entry.note,
            'legacy_slot': entry.legacySlot,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'user_id,month_start')
          .select()
          .single();
      entry = ProgressEntry.fromRow(row);
    } catch (_) {
      // Keep the full edit locally until migration 0013 becomes available.
    }

    final local = await _loadLocal(uid);
    local.removeWhere((item) => item.monthKey == entry.monthKey);
    local.add(entry);
    local.sort((a, b) => a.month.compareTo(b.month));
    await _writeLocal(uid, local);

    final patch = <String, dynamic>{};
    if (entry.legacySlot != null) {
      patch[_legacyColumn(entry.legacySlot!)] = entry.photoUrl;
      patch['progress_button_index'] = entry.legacySlot! + 1;
    }
    final now = DateTime.now();
    if (entry.month.year == now.year && entry.month.month == now.month) {
      if (entry.weightKg != null) patch['weight_kg'] = entry.weightKg!.round();
      if (entry.bodyFatPercentage != null) {
        patch['bfat2'] = entry.bodyFatPercentage;
      }
    }
    if (patch.isNotEmpty) {
      patch['updated_at'] = DateTime.now().toUtc().toIso8601String();
      await _db.from('profile_private').update(patch).eq('id', uid);
    }
    return entry;
  }

  Future<void> deleteEntry(ProgressEntry entry) async {
    final uid = _requireUid();
    try {
      await _db
          .from('progress_entries')
          .delete()
          .eq('user_id', uid)
          .eq('month_start', '${entry.monthKey}-01');
    } catch (_) {}
    final local = await _loadLocal(uid)
      ..removeWhere((item) => item.monthKey == entry.monthKey);
    await _writeLocal(uid, local);
    if (entry.legacySlot != null) {
      await _db.from('profile_private').update({
        _legacyColumn(entry.legacySlot!): '',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', uid);
    }
  }

  Future<int?> _firstAvailableLegacySlot() async {
    final profile = await ProfileRepository().getMyProfile();
    if (profile == null) return null;
    final photos = [
      profile.progressImage,
      profile.progressImage2,
      profile.progressImage3,
      profile.progressImage4,
      profile.progressImage5,
      profile.progressImage6,
      profile.progressImage12,
    ];
    final index = photos.indexWhere((value) => value.trim().isEmpty);
    return index == -1 ? null : index;
  }

  String _legacyColumn(int slot) => const [
        'progress_image',
        'progress_image2',
        'progress_image3',
        'progress_image4',
        'progress_image5',
        'progress_image6',
        'progress_image12',
      ][slot.clamp(0, 6)];

  Future<List<ProgressEntry>> _loadLocal(String uid) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_localKey(uid));
    if (encoded == null || encoded.isEmpty) return <ProgressEntry>[];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return <ProgressEntry>[];
      return decoded
          .whereType<Map>()
          .map((raw) => ProgressEntry.fromRow(
              raw.map((key, value) => MapEntry(key.toString(), value))))
          .toList();
    } catch (_) {
      return <ProgressEntry>[];
    }
  }

  Future<void> _writeLocal(String uid, List<ProgressEntry> entries) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _localKey(uid),
      jsonEncode(entries.map((entry) => entry.toLocalJson()).toList()),
    );
  }

  String _requireUid() {
    final uid = _uid;
    if (uid == null) throw StateError('Sign in to edit your progress.');
    return uid;
  }
}
