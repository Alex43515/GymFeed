import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HealthAvailability { available, installRequired, unsupported }

enum HealthConnectionState { disconnected, ready, permissionRequired, error }

class DailyHealthSummary {
  const DailyHealthSummary({
    required this.date,
    required this.syncedAt,
    this.steps,
    this.activeCalories,
    this.heartRate,
    this.heartRateAt,
    this.sources = const [],
    this.unavailableMetrics = const [],
  });
  final DateTime date;
  final DateTime syncedAt;
  final int? steps;
  final double? activeCalories;
  final double? heartRate;
  final DateTime? heartRateAt;
  final List<String> sources;
  final List<String> unavailableMetrics;
  bool get hasData =>
      steps != null || activeCalories != null || heartRate != null;
}

abstract class ConnectedHealthGateway {
  String get providerName;
  bool get isIOS;
  Future<HealthAvailability> availability();
  Future<bool> requestReadAccess();
  Future<DailyHealthSummary> readDay(DateTime date, DateTime now);
  Future<void> install();
  Future<bool> openSettings();
}

/// Only the user's opt-in is persisted. Health samples never enter preferences,
/// Firestore, Supabase, logs, analytics, AI prompts or public profile records.
class ConnectedHealthController extends ChangeNotifier {
  ConnectedHealthController({
    required this.gateway,
    required this.userId,
    required this.preferences,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now {
    selectedDate = day(this.clock());
  }
  final ConnectedHealthGateway gateway;
  final String userId;
  final SharedPreferences preferences;
  final DateTime Function() clock;
  late DateTime selectedDate;
  HealthAvailability available = HealthAvailability.unsupported;
  HealthConnectionState state = HealthConnectionState.disconnected;
  DailyHealthSummary? summary;
  bool busy = false;
  bool initialized = false;
  String? message;
  bool _disposed = false;
  int _generation = 0;
  String get _key => 'connected_health_opt_in_v1_$userId';
  bool get optedIn => userId.isNotEmpty && preferences.getBool(_key) == true;
  static DateTime day(DateTime date) =>
      DateTime(date.year, date.month, date.day);
  static DateTime nextDay(DateTime date) =>
      DateTime(date.year, date.month, date.day + 1);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    if (busy || initialized) return;
    await _run(() async {
      available = await gateway.availability();
      initialized = true;
      if (optedIn && available == HealthAvailability.available) await _read();
    });
  }

  Future<void> connect() async {
    if (busy || userId.isEmpty) return;
    await _run(() async {
      available = await gateway.availability();
      if (available != HealthAvailability.available) return;
      final granted = await gateway.requestReadAccess();
      if (!granted) {
        state = HealthConnectionState.permissionRequired;
        message =
            'Access was not enabled. You can try again or manage permissions in ${gateway.providerName}.';
        return;
      }
      await preferences.setBool(_key, true);
      await _read();
    });
  }

  Future<void> refresh() async {
    if (busy) return;
    await _run(() async {
      available = await gateway.availability();
      if (optedIn && available == HealthAvailability.available)
        await _read();
      else {
        summary = null;
        state = HealthConnectionState.disconnected;
      }
    });
  }

  Future<void> selectDate(DateTime date) async {
    if (busy) return;
    final today = day(clock());
    final chosen = day(date);
    if (chosen.isAfter(today) ||
        chosen.isBefore(DateTime(today.year, today.month, today.day - 6)))
      return;
    selectedDate = chosen;
    summary = null;
    _notify();
    await refresh();
  }

  Future<void> _read() async {
    final generation = _generation;
    summary = null;
    final result = await gateway
        .readDay(selectedDate, clock())
        .timeout(const Duration(seconds: 25));
    if (_disposed || generation != _generation) return;
    summary = result;
    state = result.unavailableMetrics.length == 3 && !gateway.isIOS
        ? HealthConnectionState.permissionRequired
        : HealthConnectionState.ready;
    if (result.unavailableMetrics.isNotEmpty) {
      message =
          'Some data is unavailable. Check permissions and that your watch app has synced to ${gateway.providerName}.';
    }
  }

  Future<void> _run(Future<void> Function() task) async {
    final generation = ++_generation;
    busy = true;
    message = null;
    _notify();
    try {
      await task();
    } catch (_) {
      if (generation == _generation && !_disposed) {
        summary = null;
        state = HealthConnectionState.error;
        message =
            'Could not sync health data. Unlock your phone, check access and try again.';
      }
    } finally {
      if (generation == _generation && !_disposed) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> disconnect() async {
    // UI disables this while a native request is pending.
    if (busy) return;
    await preferences.remove(_key);
    summary = null;
    state = HealthConnectionState.disconnected;
    message =
        'Sync stopped. To revoke system access too, use ${gateway.providerName} permissions.';
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    summary = null;
    super.dispose();
  }
}
