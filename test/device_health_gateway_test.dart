import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:gym_feed/health/connected_health_controller.dart';
import 'package:gym_feed/health/device_health_gateway.dart';

class FakePlugin extends Health {
  int configurations = 0;
  int rawReads = 0;
  int totals = 0;
  bool? hasAccess = true;
  HealthConnectSdkStatus sdk = HealthConnectSdkStatus.sdkAvailable;
  List<HealthDataAccess>? requested;
  DateTime? queriedStart;
  DateTime? queriedEnd;
  List<HealthDataPoint> points = [];
  List<HealthDataPoint> statistics = [];
  int? steps = 5432;
  final denied = <HealthDataType>{};
  @override
  Future<void> configure() async {
    configurations++;
  }

  @override
  Future<HealthConnectSdkStatus?> getHealthConnectSdkStatus() async => sdk;
  @override
  Future<bool?> hasPermissions(List<HealthDataType> types,
          {List<HealthDataAccess>? permissions}) async =>
      denied.contains(types.single) ? false : hasAccess;
  @override
  Future<bool> requestAuthorization(List<HealthDataType> types,
      {List<HealthDataAccess>? permissions}) async {
    requested = permissions;
    return true;
  }

  @override
  Future<int?> getTotalStepsInInterval(DateTime startTime, DateTime endTime,
      {bool includeManualEntry = true}) async {
    totals++;
    queriedStart = startTime;
    queriedEnd = endTime;
    return steps;
  }

  @override
  Future<List<HealthDataPoint>> getHealthDataFromTypes(
      {required List<HealthDataType> types,
      required DateTime startTime,
      required DateTime endTime,
      List<RecordingMethod> recordingMethodsToFilter = const []}) async {
    expect(types, [HealthDataType.HEART_RATE]);
    rawReads++;
    return points;
  }

  @override
  Future<List<HealthDataPoint>> getHealthIntervalDataFromTypes(
      {required DateTime startDate,
      required DateTime endDate,
      required List<HealthDataType> types,
      required int interval,
      List<RecordingMethod> recordingMethodsToFilter = const []}) async {
    expect(types, [HealthDataType.ACTIVE_ENERGY_BURNED]);
    expect(interval, greaterThan(0));
    return statistics;
  }
}

HealthDataPoint sample(
        String id, double value, HealthDataType type, DateTime time) =>
    HealthDataPoint(
        uuid: id,
        value: NumericHealthValue(numericValue: value),
        type: type,
        unit: type == HealthDataType.HEART_RATE
            ? HealthDataUnit.BEATS_PER_MINUTE
            : HealthDataUnit.KILOCALORIE,
        dateFrom: time,
        dateTo: time,
        sourcePlatform: HealthPlatformType.appleHealth,
        sourceDeviceId: 'test',
        sourceId: 'watch',
        sourceName: 'Test watch');

void main() {
  late FakePlugin plugin;
  late DeviceHealthGateway gateway;
  final now = DateTime(2026, 10, 13, 12);
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    plugin = FakePlugin();
    gateway = DeviceHealthGateway(health: plugin);
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  test('requests only read permissions for the three displayed metrics',
      () async {
    await gateway.availability();
    await gateway.requestReadAccess();
    expect(plugin.requested, List.filled(3, HealthDataAccess.READ));
    await gateway.availability();
    expect(plugin.configurations, 1);
  });
  test(
      'uses system step totals and calorie statistics, deduplicates latest pulse',
      () async {
    plugin.points = [
      sample('earlier', 90, HealthDataType.HEART_RATE,
          now.subtract(const Duration(hours: 1))),
      sample('latest', 70, HealthDataType.HEART_RATE, now),
      sample('latest', 70, HealthDataType.HEART_RATE, now)
    ];
    plugin.statistics = [
      sample('calories', 350, HealthDataType.ACTIVE_ENERGY_BURNED, now),
      sample('calories', 350, HealthDataType.ACTIVE_ENERGY_BURNED, now)
    ];
    final result = await gateway.readDay(now, now);
    expect(result.steps, 5432);
    expect(result.activeCalories, 350);
    expect(result.heartRate, 70);
    expect(result.sources, ['Test watch']);
    expect(plugin.totals, 1);
    expect(plugin.rawReads, 1);
    expect(plugin.queriedStart, DateTime(2026, 10, 13));
    expect(plugin.queriedEnd, now);
  });
  test('Android skips denied types and reads permitted data', () async {
    plugin.denied.addAll(
        [HealthDataType.HEART_RATE, HealthDataType.ACTIVE_ENERGY_BURNED]);
    final result = await gateway.readDay(now, now);
    expect(result.steps, 5432);
    expect(result.unavailableMetrics, ['Active calories', 'Heart rate']);
    expect(plugin.rawReads, 0);
  });
  test('iOS reads despite indeterminate read permission status', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    plugin.hasAccess = null;
    final result = await gateway.readDay(now, now);
    expect(result.steps, 5432);
    expect(result.unavailableMetrics, isEmpty);
  });
  test(
      'zero or empty records remain missing; invalid numeric samples are ignored',
      () async {
    plugin.steps = 0;
    plugin.points = [
      sample('invalid', double.nan, HealthDataType.HEART_RATE, now)
    ];
    final result = await gateway.readDay(now, now);
    expect(result.hasData, false);
  });
  test('past-day reads stop at local calendar midnight, not current time',
      () async {
    await gateway.readDay(DateTime(2026, 10, 12), now);
    expect(plugin.queriedEnd, DateTime(2026, 10, 13));
  });
  test('desktop availability never calls the native plugin', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(await gateway.availability(), HealthAvailability.unsupported);
    expect(plugin.configurations, 0);
  });
}
