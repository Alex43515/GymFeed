import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart';

export 'package:purchases_flutter/purchases_flutter.dart'
    show Package, Offering;

Offerings? _offerings;
CustomerInfo? _customerInfo;
String? _loggedInUid;
bool _identityBound = false;
int _identityVersion = 0;
int _pendingIdentityChanges = 0;
Future<void> _loginQueue = Future<void>.value();
String? _pendingLoginUid;
Future<bool>? _pendingLoginResult;
bool _purchaseInProgress = false;

enum PurchaseOutcome { active, cancelled, pending, missingEntitlement, failed }

Offerings? get offerings => _offerings;
CustomerInfo? get customerInfo => _customerInfo;

set customerInfo(CustomerInfo? customerInfo) => _customerInfo = customerInfo;

Future initialize(
  String appStoreKey,
  String playStoreKey, {
  bool debugLogEnabled = false,
  bool loadDataAfterLaunch = false,
}) async {
  if (kIsWeb) {
    print('RevenueCat is not supported on web.');
    return;
  }
  try {
    await Purchases.setLogLevel(
      debugLogEnabled ? LogLevel.debug : LogLevel.info,
    );
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await Purchases.configure(PurchasesConfiguration(appStoreKey));
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      await Purchases.configure(PurchasesConfiguration(playStoreKey));
    } else {
      print("RevenueCat is not supported on this platform.");
      return;
    }

    if (loadDataAfterLaunch) {
      loadCustomerInfo();
      loadOfferings();
    } else {
      await loadCustomerInfo();
      await loadOfferings();
    }

    Purchases.addCustomerInfoUpdateListener((info) {
      if (_identityBound && _pendingIdentityChanges == 0) customerInfo = info;
    });
  } on Exception catch (e) {
    // This should happen only in the web run mode.
    print("RevenueCat initialization failed: $e");
  }
}

// Purchase a package.
Future<bool> purchasePackage(String package) async =>
    await purchasePackageWithOutcome(package) == PurchaseOutcome.active;

Future<PurchaseOutcome> purchasePackageWithOutcome(
  String package, {
  String? requiredEntitlementId,
}) async {
  if (kIsWeb ||
      !_identityBound ||
      _purchaseInProgress ||
      _pendingIdentityChanges > 0) {
    return PurchaseOutcome.failed;
  }
  _purchaseInProgress = true;
  final identityVersion = _identityVersion;
  try {
    final revenueCatPackage = offerings?.current?.getPackage(package);
    if (revenueCatPackage == null) {
      return PurchaseOutcome.failed;
    }
    final purchaseResult = await Purchases.purchase(
      PurchaseParams.package(revenueCatPackage),
    );
    if (identityVersion != _identityVersion) return PurchaseOutcome.failed;
    customerInfo = purchaseResult.customerInfo;
    if (requiredEntitlementId != null &&
        !(customerInfo!.entitlements.all[requiredEntitlementId]?.isActive ??
            false)) {
      return PurchaseOutcome.missingEntitlement;
    }
    return PurchaseOutcome.active;
  } on PlatformException catch (e) {
    // Native cancellation and pending approval are not successful purchases.
    final code = int.tryParse(e.code);
    if (code == PurchasesErrorCode.purchaseCancelledError.index) {
      return PurchaseOutcome.cancelled;
    }
    if (code == PurchasesErrorCode.paymentPendingError.index) {
      return PurchaseOutcome.pending;
    }
    return PurchaseOutcome.failed;
  } catch (_) {
    return PurchaseOutcome.failed;
  } finally {
    _purchaseInProgress = false;
  }
}

List<String> get activeEntitlementIds => _identityBound && _customerInfo != null
    ? _customerInfo!.entitlements.active.values
        .map((e) => e.identifier)
        .toList()
    : [];

Future loadOfferings() async {
  if (kIsWeb) {
    return;
  }
  try {
    _offerings = await Purchases.getOfferings();
  } on PlatformException catch (e) {
    print("Error loading offerings info: $e");
  }
}

Future loadCustomerInfo() async {
  if (kIsWeb || !_identityBound || _pendingIdentityChanges > 0) {
    return;
  }
  final identityVersion = _identityVersion;
  try {
    final info = await Purchases.getCustomerInfo();
    if (identityVersion == _identityVersion) _customerInfo = info;
  } on PlatformException catch (e) {
    print("Error loading purchaser info: $e");
  }
}

// Return if the user has the entitlement.
// Return null on errors.
Future<bool?> isEntitled(String entitlementId) async {
  if (kIsWeb || !_identityBound || _pendingIdentityChanges > 0) {
    return null;
  }
  final identityVersion = _identityVersion;
  try {
    final expiration = DateTime.tryParse(
        _customerInfo?.entitlements.all[entitlementId]?.expirationDate ?? '');
    if (expiration != null && !DateTime.now().isBefore(expiration)) {
      // Recheck the store entitlement at its actual expiry. RevenueCat remains
      // authoritative for renewals and billing grace periods; never add 30 days.
      await Purchases.invalidateCustomerInfoCache();
    }
    final info = await Purchases.getCustomerInfo();
    if (identityVersion != _identityVersion) return false;
    customerInfo = info;
    return info.entitlements.all[entitlementId]?.isActive ?? false;
  } on Exception catch (e) {
    print("Unable to check RevenueCat entitlements: $e");
    return null;
  }
}

// https://docs.revenuecat.com/docs/user-ids
Future<bool> login(String? uid) async {
  if (kIsWeb) return false;
  if (_pendingIdentityChanges > 0 &&
      uid == _pendingLoginUid &&
      _pendingLoginResult != null) {
    return _pendingLoginResult!;
  }
  if (_identityBound && uid == _loggedInUid && _pendingIdentityChanges == 0) {
    return true;
  }
  final identityVersion = ++_identityVersion;
  ++_pendingIdentityChanges;
  _customerInfo = null;
  _identityBound = false;
  // Clear before the native request: a failed login must not retain another
  // account's premium. Serialize SDK mutations so the final identity is correct.
  final previous = _loginQueue;
  var succeeded = false;
  final operation = () async {
    await previous;
    try {
      final info = uid != null
          ? (await Purchases.logIn(uid)).customerInfo
          : await Purchases.isAnonymous
              ? await Purchases.getCustomerInfo()
              : await Purchases.logOut();
      if (identityVersion == _identityVersion) {
        _customerInfo = info;
        _loggedInUid = uid;
        _identityBound = true;
        succeeded = true;
      }
    } on Exception catch (e) {
      if (identityVersion == _identityVersion) _loggedInUid = null;
      print("Unable to logIn or logOut user in RevenueCat: $e");
    } finally {
      --_pendingIdentityChanges;
    }
  }();
  _loginQueue = operation;
  _pendingLoginUid = uid;
  final result = operation.then((_) => succeeded);
  _pendingLoginResult = result;
  return result;
}

// https://docs.revenuecat.com/docs/restoring-purchases
Future<bool> restorePurchases() async {
  if (kIsWeb || !_identityBound || _pendingIdentityChanges > 0) {
    return false;
  }
  final identityVersion = _identityVersion;
  try {
    final info = await Purchases.restorePurchases();
    if (identityVersion != _identityVersion) return false;
    customerInfo = info;
    return true;
  } on PlatformException catch (e) {
    print("Unable to restore purchases in RevenueCat: $e");
    return false;
  }
}
