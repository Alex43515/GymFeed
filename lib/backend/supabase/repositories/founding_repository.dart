import 'package:flutter/foundation.dart';

import '/backend/supabase/supabase.dart';

/// Founding numbers (#0001–#1000) for the first 1,000 GymFeed profiles.
///
/// The whole `founding_members` table is at most 1,000 small rows, so the app
/// loads it once and keeps it in memory. Every badge in the feed then reads
/// from the same map instead of issuing one query per post.
class FoundingRegistry {
  FoundingRegistry._({Future<Map<String, int>> Function()? loader})
      : _loader = loader ?? _loadFromSupabase;

  static FoundingRegistry instance = FoundingRegistry._();

  /// Replaces the shared registry, for tests.
  @visibleForTesting
  static void overrideForTesting(Map<String, int> numbers) {
    instance = FoundingRegistry._(loader: () async => numbers);
  }

  final Future<Map<String, int>> Function() _loader;
  final ValueNotifier<Map<String, int>> numbers =
      ValueNotifier<Map<String, int>>(const {});

  Future<void>? _loading;
  DateTime? _loadedAt;

  static const _maxAge = Duration(minutes: 10);

  static Future<Map<String, int>> _loadFromSupabase() async {
    final rows = await supabase
        .from('founding_members')
        .select('user_id, founding_number')
        .limit(2000);
    final result = <String, int>{};
    for (final row in rows as List) {
      final map = row as Map<String, dynamic>;
      final id = map['user_id']?.toString() ?? '';
      final number = (map['founding_number'] as num?)?.toInt();
      if (id.isNotEmpty && number != null) result[id] = number;
    }
    return result;
  }

  /// Loads the table if it has not been loaded recently. Safe to call from
  /// every badge; concurrent calls share one request.
  Future<void> ensureLoaded({bool force = false}) {
    final fresh = _loadedAt != null &&
        DateTime.now().difference(_loadedAt!) < _maxAge;
    if (!force && fresh) return Future.value();
    return _loading ??= _loader().then((value) {
      numbers.value = Map.unmodifiable(value);
      _loadedAt = DateTime.now();
    }).catchError((Object _) {
      // A missing badge is better than a broken screen. Retry on next call.
    }).whenComplete(() => _loading = null);
  }

  int? numberFor(String userId) => numbers.value[userId];
}

/// "#0142" style label.
String formatFoundingNumber(int number) =>
    '#${number.toString().padLeft(4, '0')}';
