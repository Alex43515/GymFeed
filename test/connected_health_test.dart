import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_feed/health/connected_health_controller.dart';
import 'package:gym_feed/health/connected_health_widget.dart';

final now = DateTime(2026, 10, 13, 12, 30);

class FakeHealth extends ConnectedHealthGateway {
  HealthAvailability status = HealthAvailability.available;
  bool granted = true;
  bool ios = false;
  bool fail = false;
  int requests = 0;
  int reads = 0;
  Completer<DailyHealthSummary>? pending;
  DailyHealthSummary data = DailyHealthSummary(
      date: now,
      syncedAt: now,
      steps: 6250,
      activeCalories: 320.6,
      heartRate: 75,
      heartRateAt: now);
  @override
  String get providerName => ios ? 'Apple Health' : 'Health Connect';
  @override
  bool get isIOS => ios;
  @override
  Future<HealthAvailability> availability() async => status;
  @override
  Future<bool> requestReadAccess() async {
    requests++;
    return granted;
  }

  @override
  Future<DailyHealthSummary> readDay(DateTime date, DateTime now) async {
    reads++;
    if (fail) throw StateError('native failure');
    if (pending != null) return await pending!.future;
    return data;
  }

  @override
  Future<void> install() async {}
  @override
  Future<bool> openSettings() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late FakeHealth gateway;
  late ConnectedHealthController controller;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    gateway = FakeHealth();
    controller = ConnectedHealthController(
        gateway: gateway,
        userId: 'user-a',
        preferences: prefs,
        clock: () => now);
  });
  tearDown(() => controller.dispose());

  test('opening never prompts or reads without consent', () async {
    await controller.initialize();
    expect(gateway.requests, 0);
    expect(gateway.reads, 0);
    expect(controller.state, HealthConnectionState.disconnected);
    await controller.refresh();
    expect(gateway.reads, 0);
  });
  test('denial does not persist consent or read health records', () async {
    gateway.granted = false;
    await controller.initialize();
    await controller.connect();
    expect(controller.state, HealthConnectionState.permissionRequired);
    expect(controller.optedIn, false);
    expect(gateway.reads, 0);
  });
  test('consent stores only a user-scoped boolean, not health data', () async {
    await controller.connect();
    expect(controller.summary!.steps, 6250);
    expect(prefs.getKeys(), {'connected_health_opt_in_v1_user-a'});
    expect(prefs.getBool('connected_health_opt_in_v1_user-a'), true);
    final other = ConnectedHealthController(
        gateway: gateway,
        userId: 'user-b',
        preferences: prefs,
        clock: () => now);
    await other.initialize();
    expect(other.optedIn, false);
    expect(other.summary, null);
    expect(gateway.reads, 1);
    other.dispose();
  });
  test('reopening refreshes without a second permission prompt', () async {
    await controller.connect();
    final reopened = ConnectedHealthController(
        gateway: gateway,
        userId: 'user-a',
        preferences: prefs,
        clock: () => now);
    await reopened.initialize();
    expect(gateway.requests, 1);
    expect(gateway.reads, 2);
    reopened.dispose();
  });
  test('partial access still displays available metrics', () async {
    gateway.data = DailyHealthSummary(
        date: now,
        syncedAt: now,
        steps: 1100,
        unavailableMetrics: ['Heart rate']);
    await controller.connect();
    expect(controller.state, HealthConnectionState.ready);
    expect(controller.summary!.steps, 1100);
    expect(controller.summary!.heartRate, null);
    expect(controller.message, contains('Some data'));
  });
  test('Android revoked access requests reconnection and clears stale values',
      () async {
    await controller.connect();
    gateway.data = DailyHealthSummary(
        date: now,
        syncedAt: now,
        unavailableMetrics: ['Steps', 'Active calories', 'Heart rate']);
    await controller.refresh();
    expect(controller.state, HealthConnectionState.permissionRequired);
    expect(controller.summary!.hasData, false);
  });
  test('iOS empty readings are never claimed as read permission denial',
      () async {
    gateway.ios = true;
    gateway.data = DailyHealthSummary(date: now, syncedAt: now);
    await controller.connect();
    expect(controller.state, HealthConnectionState.ready);
    expect(controller.summary!.hasData, false);
  });
  test('unavailable provider cannot request or read health data', () async {
    gateway.status = HealthAvailability.installRequired;
    await controller.initialize();
    await controller.connect();
    expect(gateway.requests, 0);
    expect(gateway.reads, 0);
  });
  test('failed read clears data and can be retried', () async {
    await controller.connect();
    gateway.fail = true;
    await controller.refresh();
    expect(controller.summary, null);
    expect(controller.busy, false);
    expect(controller.state, HealthConnectionState.error);
    gateway.fail = false;
    await controller.refresh();
    expect(controller.state, HealthConnectionState.ready);
  });
  test('disconnect stops future reads and clears consent and summary',
      () async {
    await controller.connect();
    await controller.disconnect();
    await controller.refresh();
    expect(gateway.reads, 1);
    expect(controller.summary, null);
    expect(controller.optedIn, false);
    expect(prefs.getKeys(), isEmpty);
  });
  test('parallel refreshes cannot start duplicate reads', () async {
    await controller.connect();
    gateway.pending = Completer();
    final refresh = controller.refresh();
    await Future<void>.delayed(Duration.zero);
    await controller.refresh();
    expect(gateway.reads, 2);
    gateway.pending!.complete(gateway.data);
    await refresh;
  });
  test('only seven local calendar days are selectable', () async {
    await controller.connect();
    await controller.selectDate(DateTime(2026, 10, 12));
    expect(controller.selectedDate, DateTime(2026, 10, 12));
    await controller.selectDate(DateTime(2026, 10, 14));
    await controller.selectDate(DateTime(2026, 10, 6));
    expect(controller.selectedDate, DateTime(2026, 10, 12));
    expect(ConnectedHealthController.nextDay(DateTime(2026, 10, 31)),
        DateTime(2026, 11, 1));
  });
  testWidgets('phone UI connects, shows metrics and disconnects',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: ConnectedHealthWidget(userId: 'user-a', controller: controller)));
    await tester.pumpAndSettle();
    expect(find.text('Connect Health Connect'), findsOneWidget);
    await tester.tap(find.text('Connect Health Connect'));
    await tester.pumpAndSettle();
    expect(find.text('6,250'), findsOneWidget);
    expect(find.text('321'), findsOneWidget);
    expect(find.text('75'), findsOneWidget);
    expect(find.textContaining('not live'), findsOneWidget);
    for (var i = 0;
        i < 8 &&
            find.text('Disconnect health').hitTestable().evaluate().isEmpty;
        i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Disconnect health'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();
    expect(controller.optedIn, false);
    expect(tester.takeException(), null);
  });
  testWidgets('empty iOS data explains missing readings, not fake zeroes',
      (tester) async {
    gateway.ios = true;
    gateway.data = DailyHealthSummary(date: now, syncedAt: now);
    await controller.connect();
    await tester.pumpWidget(MaterialApp(
        home: ConnectedHealthWidget(userId: 'user-a', controller: controller)));
    await tester.pumpAndSettle();
    expect(find.text('—'), findsNWidgets(3));
    expect(find.textContaining('Access requested'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(tester.takeException(), null);
  });
  testWidgets('unsupported web/desktop provides guidance without connecting',
      (tester) async {
    gateway.status = HealthAvailability.unsupported;
    await tester.pumpWidget(MaterialApp(
        home: ConnectedHealthWidget(userId: 'user-a', controller: controller)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Android 9 or newer'), findsOneWidget);
    expect(find.text('Connect Health Connect'), findsNothing);
    expect(gateway.requests, 0);
  });
}
