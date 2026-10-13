import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_feed/health/connected_health_controller.dart';
import 'package:gym_feed/health/connected_health_widget.dart';
import 'package:gym_feed/health/device_health_gateway.dart';

/// Native plugin smoke test. Run on Android 14+ or an iPhone Simulator/device.
/// It does not log in, create backend records or prompt for health access.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native health availability and optional connection UI',
      (tester) async {
    final gateway = DeviceHealthGateway();
    final availability = await gateway.availability();
    expect(
        availability,
        gateway.isIOS
            ? anyOf(
                HealthAvailability.available, HealthAvailability.unsupported)
            : HealthAvailability.available);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('connected_health_opt_in_v1_native-smoke-test');
    final controller = ConnectedHealthController(
        gateway: gateway, userId: 'native-smoke-test', preferences: prefs);
    await tester.pumpWidget(MaterialApp(
        home: ConnectedHealthWidget(
            userId: 'native-smoke-test', controller: controller)));
    await tester.pumpAndSettle();
    if (availability == HealthAvailability.available) {
      expect(find.text('Connect ${gateway.providerName}'), findsOneWidget);
    } else {
      expect(find.textContaining('Available in the GymFeed'), findsOneWidget);
    }
    expect(controller.summary, null);
    expect(controller.optedIn, false);
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
