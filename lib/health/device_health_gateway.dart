import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:url_launcher/url_launcher.dart';
import 'connected_health_controller.dart';

class DeviceHealthGateway implements ConnectedHealthGateway {
  DeviceHealthGateway({Health? health}) : _health = health ?? Health();
  final Health _health;
  bool _configured = false;
  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.HEART_RATE
  ];
  static const _names = ['Steps', 'Active calories', 'Heart rate'];
  @override
  bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  @override
  String get providerName => isIOS ? 'Apple Health' : 'Health Connect';

  @override
  Future<HealthAvailability> availability() async {
    if (!isIOS && !_android) return HealthAvailability.unsupported;
    if (!_configured) {
      await _health.configure();
      _configured = true;
    }
    if (isIOS) {
      final supported = await const MethodChannel('gymfeed/health_settings')
          .invokeMethod<bool>('isAvailable');
      return supported == true
          ? HealthAvailability.available
          : HealthAvailability.unsupported;
    }
    return switch (await _health.getHealthConnectSdkStatus()) {
      HealthConnectSdkStatus.sdkAvailable => HealthAvailability.available,
      HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired =>
        HealthAvailability.installRequired,
      _ => HealthAvailability.unsupported,
    };
  }

  @override
  Future<bool> requestReadAccess() => _health.requestAuthorization(_types,
      permissions: List.filled(_types.length, HealthDataAccess.READ));

  @override
  Future<DailyHealthSummary> readDay(DateTime date, DateTime now) async {
    final start = ConnectedHealthController.day(date);
    final next = ConnectedHealthController.nextDay(start);
    final end = next.isAfter(now) ? now : next;
    if (!end.isAfter(start))
      return DailyHealthSummary(date: start, syncedAt: now);
    int? steps;
    double? calories;
    double? heart;
    DateTime? heartAt;
    final unavailable = <String>[];
    final sources = <String>{};
    for (var i = 0; i < _types.length; i++) {
      final type = _types[i];
      try {
        // iOS deliberately hides read-permission status. Never treat null as denial.
        if (_android &&
            await _health.hasPermissions([type],
                    permissions: [HealthDataAccess.READ]) !=
                true) {
          unavailable.add(_names[i]);
          continue;
        }
        if (type == HealthDataType.STEPS) {
          final total = await _health.getTotalStepsInInterval(start, end);
          steps = total != null && total > 0 ? total : null;
        } else {
          final points = type == HealthDataType.ACTIVE_ENERGY_BURNED
              // Platform statistics, rather than summing overlapping raw watch/phone samples.
              ? await _health.getHealthIntervalDataFromTypes(
                  startDate: start,
                  endDate: end,
                  types: [type],
                  interval: next.difference(start).inSeconds)
              : await _health.getHealthDataFromTypes(
                  startTime: start, endTime: end, types: [type]);
          final values = _health
              .removeDuplicates(points)
              .where((p) =>
                  p.value is NumericHealthValue &&
                  (p.value as NumericHealthValue).numericValue.isFinite &&
                  (p.value as NumericHealthValue).numericValue > 0)
              .toList();
          for (final p in values) {
            if (p.sourceName.isNotEmpty) sources.add(p.sourceName);
          }
          if (type == HealthDataType.ACTIVE_ENERGY_BURNED &&
              values.isNotEmpty) {
            calories = values.fold<double>(
                0,
                (sum, p) =>
                    sum +
                    (p.value as NumericHealthValue).numericValue.toDouble());
          } else if (type == HealthDataType.HEART_RATE && values.isNotEmpty) {
            values.sort((a, b) => b.dateTo.compareTo(a.dateTo));
            heart = (values.first.value as NumericHealthValue)
                .numericValue
                .toDouble();
            heartAt = values.first.dateTo;
          }
        }
      } catch (_) {
        unavailable.add(_names[i]);
      }
    }
    return DailyHealthSummary(
        date: start,
        syncedAt: now,
        steps: steps,
        activeCalories: calories,
        heartRate: heart,
        heartRateAt: heartAt,
        sources: sources.toList()..sort(),
        unavailableMetrics: unavailable);
  }

  @override
  Future<void> install() => _health.installHealthConnect();
  @override
  Future<bool> openSettings() async {
    if (isIOS)
      return launchUrl(Uri.parse('x-apple-health://'),
          mode: LaunchMode.externalApplication);
    if (_android)
      return await const MethodChannel('gymfeed/health_settings')
              .invokeMethod<bool>('openSettings') ??
          false;
    return false;
  }
}
