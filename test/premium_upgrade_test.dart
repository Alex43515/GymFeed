import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_feed/ai_workout/payment/payment_widget.dart';
import 'package:gym_feed/ai_workout/premium/ai_usage_gate.dart';

const _channel = MethodChannel('purchases_flutter');

Map<String, dynamic> _offerings() {
  final package = {
    'identifier': r'$rc_monthly',
    'packageType': 'MONTHLY',
    'product': {
      'identifier': 'subscription_1_month:subscription-1month',
      'description': 'One calendar month',
      'title': 'GymFeed Pro',
      'price': 29.99,
      'priceString': r'$29.99',
      'currencyCode': 'USD',
      'subscriptionPeriod': 'P1M',
    },
    'presentedOfferingContext': {'offeringIdentifier': 'subscription'},
  };
  final offering = {
    'identifier': 'subscription',
    'serverDescription': 'Premium features',
    'metadata': <String, dynamic>{},
    'availablePackages': [package],
    'monthly': package,
  };
  return {
    'all': {'subscription': offering},
    'current': offering,
  };
}

void main() {
  late Future<Object?> Function() getOfferings;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      if (call.method == 'getOfferings') return getOfferings();
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  Future<void> tapUpgrade(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => openPremiumUpgrade(context),
            child: const Text('Upgrade'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Upgrade'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('Upgrade opens the paywall while the store is still answering',
      (tester) async {
    final store = Completer<Object?>();
    getOfferings = () => store.future;

    await tapUpgrade(tester);
    expect(find.byType(PaymentWidget), findsOneWidget);
    expect(find.text('Premium plan'), findsOneWidget);

    store.complete(_offerings());
    await tester.pump();
    await tester.pump();
    expect(find.text(r'$29.99'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Upgrade opens the paywall when the store returns an error',
      (tester) async {
    getOfferings = () => throw PlatformException(code: '10', message: 'network');

    await tapUpgrade(tester);
    expect(find.byType(PaymentWidget), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Upgrade opens the paywall when the store answer is unreadable',
      (tester) async {
    getOfferings = () async => <String, dynamic>{'current': 'not an offering'};

    await tapUpgrade(tester);
    expect(find.byType(PaymentWidget), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
