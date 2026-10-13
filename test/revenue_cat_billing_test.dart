import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthClientOptions;
import 'package:gym_feed/flutter_flow/revenue_cat_util.dart' as billing;
import 'package:gym_feed/ai_workout/premium/ai_usage_gate.dart';
import 'package:gym_feed/backend/supabase/supabase.dart';

const entitlement = 'premium_features';
const channel = MethodChannel('purchases_flutter');

Map<String, dynamic> customer({
  String uid = 'buyer',
  bool active = false,
  bool hasEntitlement = true,
  bool willRenew = true,
  DateTime? purchase,
  DateTime? expires,
  bool billingIssue = false,
}) {
  final bought = (purchase ?? DateTime.now()).toUtc().toIso8601String();
  final expiry = expires?.toUtc().toIso8601String();
  final item = <String, dynamic>{
    'identifier': entitlement,
    'isActive': active,
    'willRenew': willRenew,
    'latestPurchaseDate': bought,
    'originalPurchaseDate': bought,
    'productIdentifier': 'premium_2999_1m',
    'isSandbox': true,
    'expirationDate': expiry,
    'billingIssueDetectedAt': billingIssue ? bought : null,
  };
  return {
    'entitlements': {
      'all': hasEntitlement ? {entitlement: item} : {},
      'active': active && hasEntitlement ? {entitlement: item} : {},
    },
    'allPurchaseDates': {'premium_2999_1m': bought},
    'activeSubscriptions': active ? ['premium_2999_1m'] : [],
    'allPurchasedProductIdentifiers': ['premium_2999_1m'],
    'nonSubscriptionTransactions': [],
    'firstSeen': bought,
    'originalAppUserId': uid,
    'allExpirationDates': {'premium_2999_1m': expiry},
    'requestDate': DateTime.now().toUtc().toIso8601String(),
  };
}

Map<String, dynamic> monthlyOfferings(String product) {
  final package = {
    'identifier': r'$rc_monthly',
    'packageType': 'MONTHLY',
    'product': {
      'identifier': product,
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
    'current': offering
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> info;
  late List<MethodCall> calls;
  Future<Object?> Function(MethodCall)? override;
  var sequence = 0;

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    info = customer();
    calls = [];
    override = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (override != null) return override!(call);
      switch (call.method) {
        case 'getCustomerInfo':
        case 'restorePurchases':
        case 'logOut':
          return info;
        case 'logIn':
          return {'customerInfo': info, 'created': false};
        case 'getOfferings':
          return monthlyOfferings(defaultTargetPlatform == TargetPlatform.iOS
              ? 'premium_2999_1m'
              : 'subscription_1_month:subscription-1month');
        case 'isAnonymous':
          return false;
        case 'purchasePackage':
          return {
            'customerInfo': info,
            'transaction': {
              'productIdentifier': 'premium_2999_1m',
              'purchaseDate': DateTime.now().toUtc().toIso8601String(),
            },
          };
        default:
          return null;
      }
    });
    await billing.login('buyer-${++sequence}');
    await billing.loadOfferings();
    calls.clear();
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('cached active premium refreshes and loses access after expiry',
      () async {
    billing.customerInfo = CustomerInfo.fromJson(customer(
      active: true,
      expires: DateTime.now().subtract(const Duration(seconds: 1)),
    ));
    info = customer(active: false);
    expect(await billing.isEntitled(entitlement), false);
    expect(calls.map((c) => c.method),
        ['invalidateCustomerInfoCache', 'getCustomerInfo']);
    expect(billing.activeEntitlementIds, isEmpty);
  });

  test('every access asks SDK for updated entitlements', () async {
    info = customer(active: true);
    expect(await billing.isEntitled(entitlement), true);
    info = customer(active: false);
    expect(await billing.isEntitled(entitlement), false);
    expect(calls.where((c) => c.method == 'getCustomerInfo'), hasLength(2));
  });

  test('AI premium gate does not bypass SDK with cached active access',
      () async {
    final client = SupabaseClient(
        'https://billing-test.invalid', 'public-test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    addTearDown(client.dispose);
    await client.auth.recoverSession(jsonEncode({
      'access_token': 'local-fixture-only',
      'token_type': 'bearer',
      'user': {'id': 'gate-buyer'},
    }));
    await billing.login('gate-buyer');
    billing.customerInfo = CustomerInfo.fromJson(customer(active: true));
    info = customer(active: false);
    calls.clear();
    expect(await AiUsageGate(client: client).isPremium(), false);
    expect(calls.map((c) => c.method), ['getCustomerInfo']);
  });

  for (final dates in [
    [DateTime.utc(2027, 2, 1), DateTime.utc(2027, 3, 1), 28],
    [DateTime.utc(2028, 2, 1), DateTime.utc(2028, 3, 1), 29],
    [DateTime.utc(2027, 4, 1), DateTime.utc(2027, 5, 1), 30],
    [DateTime.utc(2027, 1, 1), DateTime.utc(2027, 2, 1), 31],
  ]) {
    test('honors store calendar period of ${dates[2]} days', () async {
      final start = dates[0] as DateTime;
      final end = dates[1] as DateTime;
      expect(end.difference(start).inDays, dates[2]);
      info = customer(active: true, purchase: start, expires: end);
      expect(await billing.isEntitled(entitlement), true);
      expect(
          billing.customerInfo!.entitlements.all[entitlement]!.expirationDate,
          end.toIso8601String());
    });
  }

  test('cancellation preserves the remaining paid period', () async {
    info = customer(
        active: true,
        willRenew: false,
        expires: DateTime.now().add(const Duration(days: 4)));
    expect(await billing.isEntitled(entitlement), true);
  });

  test('renewal replaces expired cached receipt with new entitlement',
      () async {
    billing.customerInfo = CustomerInfo.fromJson(customer(
        active: true,
        expires: DateTime.now().subtract(const Duration(minutes: 1))));
    info = customer(
        active: true, expires: DateTime.now().add(const Duration(days: 31)));
    expect(await billing.isEntitled(entitlement), true);
    expect(billing.customerInfo!.entitlements.all[entitlement]!.expirationDate,
        info['allExpirationDates']['premium_2999_1m']);
  });

  test('RevenueCat grace period stays active past paid expiry', () async {
    info = customer(
        active: true,
        billingIssue: true,
        expires: DateTime.now().subtract(const Duration(hours: 1)));
    billing.customerInfo = CustomerInfo.fromJson(info);
    expect(await billing.isEntitled(entitlement), true);
    expect(calls.first.method, 'invalidateCustomerInfoCache');
  });

  test('refund or revoked entitlement removes premium', () async {
    billing.customerInfo = CustomerInfo.fromJson(customer(active: true));
    info = customer(active: false);
    expect(await billing.isEntitled(entitlement), false);
  });

  test('failed refresh does not approve access from cached premium', () async {
    billing.customerInfo = CustomerInfo.fromJson(customer(active: true));
    override = (call) async => throw PlatformException(code: '10');
    expect(await billing.isEntitled(entitlement), isNull);
  });

  test('ending a billing grace period revokes access', () async {
    billing.customerInfo = CustomerInfo.fromJson(customer(
        active: true,
        billingIssue: true,
        expires: DateTime.now().subtract(const Duration(days: 4))));
    info = customer(active: false, billingIssue: true);
    expect(await billing.isEntitled(entitlement), false);
  });

  test('logging out clears premium and logs the native account out', () async {
    billing.customerInfo = CustomerInfo.fromJson(customer(active: true));
    expect(await billing.login(null), true);
    expect(calls.map((c) => c.method), ['isAnonymous', 'logOut']);
    expect(billing.activeEntitlementIds, isEmpty);
  });

  test('rapid account switches are serialized and keep final identity',
      () async {
    final firstReply = Completer<Object?>();
    override = (call) async {
      if (call.arguments['appUserID'] == 'first-switch')
        return firstReply.future;
      return {'customerInfo': customer(uid: 'second-switch'), 'created': false};
    };
    final first = billing.login('first-switch');
    final second = billing.login('second-switch');
    await Future<void>.delayed(Duration.zero);
    expect(calls.where((c) => c.method == 'logIn'), hasLength(1));
    firstReply
        .complete({'customerInfo': customer(active: true), 'created': false});
    expect(await first, false);
    expect(await second, true);
    expect(billing.customerInfo!.originalAppUserId, 'second-switch');
    expect(billing.activeEntitlementIds, isEmpty);
  });

  test('paid transaction requires the expected premium entitlement', () async {
    info = customer(active: true, hasEntitlement: false);
    expect(
        await billing.purchasePackageWithOutcome(r'$rc_monthly',
            requiredEntitlementId: entitlement),
        billing.PurchaseOutcome.missingEntitlement);
    expect(billing.activeEntitlementIds, isEmpty);
  });

  test('successful purchase activates premium', () async {
    info = customer(active: true);
    expect(
        await billing.purchasePackageWithOutcome(r'$rc_monthly',
            requiredEntitlementId: entitlement),
        billing.PurchaseOutcome.active);
    expect(billing.activeEntitlementIds, contains(entitlement));
  });

  for (final error in [
    PurchasesErrorCode.purchaseCancelledError,
    PurchasesErrorCode.paymentPendingError,
    PurchasesErrorCode.networkError,
  ]) {
    test('handles native ${error.name} without granting premium', () async {
      override =
          (call) async => throw PlatformException(code: '${error.index}');
      expect(
          await billing.purchasePackageWithOutcome(r'$rc_monthly',
              requiredEntitlementId: entitlement),
          error == PurchasesErrorCode.purchaseCancelledError
              ? billing.PurchaseOutcome.cancelled
              : error == PurchasesErrorCode.paymentPendingError
                  ? billing.PurchaseOutcome.pending
                  : billing.PurchaseOutcome.failed);
      expect(billing.activeEntitlementIds, isEmpty);
    });
  }

  test('restore distinguishes active subscription from expired purchase',
      () async {
    info = customer(active: true);
    expect(await billing.restorePurchases(), true);
    expect(billing.activeEntitlementIds, contains(entitlement));
    info = customer(active: false);
    expect(await billing.restorePurchases(), true);
    expect(billing.activeEntitlementIds, isEmpty);
  });

  test('failed account switch clears previous user premium', () async {
    billing.customerInfo = CustomerInfo.fromJson(customer(active: true));
    override = (call) async => throw PlatformException(code: '10');
    expect(await billing.login('other-user'), false);
    expect(billing.customerInfo, isNull);
    expect(billing.activeEntitlementIds, isEmpty);
    expect(await billing.isEntitled(entitlement), isNull);
  });

  test('delayed old account refresh cannot overwrite a new account', () async {
    final delayed = Completer<Object?>();
    override = (call) async {
      if (call.method == 'getCustomerInfo') return delayed.future;
      if (call.method == 'logIn')
        return {'customerInfo': customer(), 'created': false};
      return null;
    };
    final refresh = billing.isEntitled(entitlement);
    await Future<void>.delayed(Duration.zero);
    expect(await billing.login('new-user'), true);
    delayed.complete(customer(active: true, uid: 'previous-user'));
    expect(await refresh, false);
    expect(billing.activeEntitlementIds, isEmpty);
  });

  test('concurrent binding of the same account shares a successful login',
      () async {
    final delayed = Completer<Object?>();
    override = (call) async => delayed.future;
    final first = billing.login('shared-buyer');
    final second = billing.login('shared-buyer');
    await Future<void>.delayed(Duration.zero);
    delayed
        .complete({'customerInfo': customer(active: true), 'created': false});
    expect(await first, true);
    expect(await second, true);
    expect(calls.where((c) => c.method == 'logIn'), hasLength(1));
  });

  test('simultaneous subscribe calls launch only one checkout', () async {
    final delayed = Completer<Object?>();
    override = (call) async => delayed.future;
    final first = billing.purchasePackageWithOutcome(r'$rc_monthly');
    expect(await billing.purchasePackageWithOutcome(r'$rc_monthly'),
        billing.PurchaseOutcome.failed);
    delayed.complete({
      'customerInfo': customer(active: true),
      'transaction': {
        'productIdentifier': 'premium_2999_1m',
        'purchaseDate': '2026-10-13T00:00:00Z',
      }
    });
    expect(await first, billing.PurchaseOutcome.active);
    expect(calls.where((c) => c.method == 'purchasePackage'), hasLength(1));
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    test('configures ${platform.name} public SDK key and monthly product',
        () async {
      debugDefaultTargetPlatformOverride = platform;
      await billing.initialize('ios-public-key', 'android-public-key');
      final configure = calls.firstWhere((c) => c.method == 'setupPurchases');
      expect(
          configure.arguments['apiKey'],
          platform == TargetPlatform.iOS
              ? 'ios-public-key'
              : 'android-public-key');
      expect(
          billing.offerings!.current!.monthly!.storeProduct.subscriptionPeriod,
          'P1M');
      expect(
          billing.offerings!.current!.monthly!.storeProduct.identifier,
          platform == TargetPlatform.iOS
              ? 'premium_2999_1m'
              : 'subscription_1_month:subscription-1month');
    });
  }
}
