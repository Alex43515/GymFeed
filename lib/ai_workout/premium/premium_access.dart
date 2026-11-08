import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '/backend/supabase/supabase.dart';
import '/flutter_flow/revenue_cat_util.dart' as revenue_cat;

/// RevenueCat entitlement that a paid GymFeed Pro subscription unlocks.
const String premiumEntitlementId = 'premium_features';

/// Explicit internal QA accounts that need uninterrupted access while testing
/// the premium Coach tools. Keep this list UID-only so another account cannot
/// gain access by changing a profile email or username.
const Set<String> premiumTesterUserIds = <String>{
  'a9fd1bc3-61a8-43a0-b96e-b6e7f0c6d060', // test@test.com
};

bool hasPremiumTesterOverride(String? userId) =>
    userId != null && premiumTesterUserIds.contains(userId);

/// Premium state for the signed-in user.
///
/// A user is premium when they pay through RevenueCat ([paid]) or still have
/// free Premium days left ([freeDaysActive]). Free days come from the server
/// (`get_premium_status`): 7 for Founding Members, 3 after the first 1,000,
/// plus 7 for each invited friend (up to [invitesMax]).
@immutable
class PremiumStatus {
  const PremiumStatus({
    required this.paid,
    this.secondsLeft = 0,
    this.fetchedAt,
    this.trialDays = 0,
    this.invitesUsed = 0,
    this.invitesMax = 4,
    this.referralBonusDays = 7,
    this.invitedBy,
    this.canRedeemInvite = false,
    this.aiUsesToday = 0,
    this.aiDailyLimit = 40,
    this.serverKnown = false,
  });

  /// Only the paid state is known, for example when the server is unreachable.
  const PremiumStatus.paidOnly(bool paid) : this(paid: paid);

  factory PremiumStatus.fromServer(
    Map<String, dynamic> json, {
    required bool paid,
    DateTime? now,
  }) {
    int asInt(Object? value, int fallback) =>
        value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
    final invitedBy = json['invited_by']?.toString().trim();
    return PremiumStatus(
      paid: paid,
      secondsLeft: math.max(0, asInt(json['seconds_left'], 0)),
      fetchedAt: now ?? DateTime.now(),
      trialDays: asInt(json['trial_days'], 0),
      invitesUsed: asInt(json['invites_used'], 0),
      invitesMax: asInt(json['invites_max'], 4),
      referralBonusDays: asInt(json['referral_bonus_days'], 7),
      invitedBy: invitedBy == null || invitedBy.isEmpty ? null : invitedBy,
      canRedeemInvite: json['can_redeem_invite'] == true,
      aiUsesToday: asInt(json['ai_uses_today'], 0),
      aiDailyLimit: asInt(json['ai_daily_limit'], 40),
      serverKnown: true,
    );
  }

  final bool paid;

  /// Free Premium seconds left when [fetchedAt] was recorded. Counting from
  /// the server's figure keeps a wrong device clock from changing the result.
  final int secondsLeft;
  final DateTime? fetchedAt;
  final int trialDays;
  final int invitesUsed;
  final int invitesMax;
  final int referralBonusDays;
  final String? invitedBy;
  final bool canRedeemInvite;
  final int aiUsesToday;
  final int aiDailyLimit;

  /// False when the free-days part could not be loaded.
  final bool serverKnown;

  int secondsLeftAt(DateTime now) {
    if (fetchedAt == null) return secondsLeft;
    final elapsed = now.difference(fetchedAt!).inSeconds;
    return math.max(0, secondsLeft - math.max(0, elapsed));
  }

  bool get freeDaysActive => secondsLeftAt(DateTime.now()) > 0;

  bool get isPremium => paid || freeDaysActive;

  /// Whole days left, rounded up: 6 days and 1 hour shows as 7.
  int get daysLeft => (secondsLeftAt(DateTime.now()) / 86400).ceil();

  int get invitesLeft => math.max(0, invitesMax - invitesUsed);

  bool get canInvite => invitesLeft > 0;

  /// The free days were used up and there is no paid plan.
  bool get freeDaysEnded => serverKnown && !paid && !freeDaysActive;
}

/// Result codes from `redeem_invite`.
enum InviteRedeemCode {
  ok,
  empty,
  notFound,
  self,
  alreadyRedeemed,
  tooLate,
  inviterLimit,
  failed,
}

@immutable
class InviteRedeemResult {
  const InviteRedeemResult(this.code, {this.inviter, this.bonusDays = 7});

  factory InviteRedeemResult.fromServer(Map<String, dynamic> json) {
    final code = switch (json['code']?.toString()) {
      'ok' => InviteRedeemCode.ok,
      'empty' => InviteRedeemCode.empty,
      'not_found' => InviteRedeemCode.notFound,
      'self' => InviteRedeemCode.self,
      'already_redeemed' => InviteRedeemCode.alreadyRedeemed,
      'too_late' => InviteRedeemCode.tooLate,
      'inviter_limit' => InviteRedeemCode.inviterLimit,
      _ => InviteRedeemCode.failed,
    };
    final bonus = json['bonus_days'];
    return InviteRedeemResult(
      code,
      inviter: json['inviter']?.toString(),
      bonusDays: bonus is num ? bonus.toInt() : 7,
    );
  }

  final InviteRedeemCode code;
  final String? inviter;
  final int bonusDays;

  bool get ok => code == InviteRedeemCode.ok;

  String get message => switch (code) {
        InviteRedeemCode.ok =>
          'You and @${inviter ?? 'your friend'} both got $bonusDays more days of Premium.',
        InviteRedeemCode.empty => 'Enter the username of the friend who invited you.',
        InviteRedeemCode.notFound => 'We could not find that username.',
        InviteRedeemCode.self => 'You cannot invite yourself.',
        InviteRedeemCode.alreadyRedeemed => 'You already used an invite.',
        InviteRedeemCode.tooLate =>
          'Invites can be added only in the first 3 days after signing up.',
        InviteRedeemCode.inviterLimit =>
          '@${inviter ?? 'This user'} already invited 4 friends.',
        InviteRedeemCode.failed => 'Could not add the invite. Please try again.',
      };
}

/// The one place the app asks "is this user premium?".
///
/// Every premium screen goes through here, so paid subscriptions and free
/// Premium days unlock exactly the same features.
class PremiumAccess {
  PremiumAccess({
    Future<bool> Function()? paidLoader,
    Future<Map<String, dynamic>> Function()? statusLoader,
    Future<Map<String, dynamic>> Function(String username)? inviteRedeemer,
    String? Function()? userId,
  })  : _paidLoaderOverride = paidLoader,
        _statusLoader = statusLoader ?? _loadStatusFromServer,
        _inviteRedeemer = inviteRedeemer ?? _redeemOnServer,
        _userId = userId ?? (() => supabase.auth.currentUser?.id);

  static PremiumAccess instance = PremiumAccess();

  @visibleForTesting
  static void overrideForTesting(PremiumAccess access) => instance = access;

  final Future<bool> Function()? _paidLoaderOverride;
  final Future<Map<String, dynamic>> Function() _statusLoader;
  final Future<Map<String, dynamic>> Function(String username) _inviteRedeemer;
  final String? Function() _userId;

  static const _maxAge = Duration(minutes: 1);

  PremiumStatus? _cached;
  String? _cachedUserId;
  DateTime? _cachedAt;
  Future<PremiumStatus>? _loading;

  /// Binds RevenueCat to this account before asking, and always asks the SDK
  /// rather than trusting cached entitlements, so a previous account's
  /// subscription can never unlock this one (premium billing audit, 3.0.6).
  static Future<bool> _loadPaidFromRevenueCat(String? userId) async {
    if (userId == null || !await revenue_cat.login(userId)) return false;
    return await revenue_cat.isEntitled(premiumEntitlementId) ?? false;
  }

  static Future<Map<String, dynamic>> _loadStatusFromServer() async {
    final result = await supabase.rpc('get_premium_status');
    return Map<String, dynamic>.from(result as Map);
  }

  static Future<Map<String, dynamic>> _redeemOnServer(String username) async {
    final result =
        await supabase.rpc('redeem_invite', params: {'p_username': username});
    return Map<String, dynamic>.from(result as Map);
  }

  /// Paid GymFeed Pro only (RevenueCat), without free days.
  Future<bool> hasPaidSubscription() async {
    if (hasPremiumTesterOverride(_userId())) return true;
    try {
      return await (_paidLoaderOverride?.call() ??
          _loadPaidFromRevenueCat(_userId()));
    } catch (_) {
      return false;
    }
  }

  /// Full premium state. Cached for a minute; pass [refresh] after a purchase,
  /// an invite or anything else that changes it.
  Future<PremiumStatus> status({bool refresh = false}) {
    final userId = _userId();
    if (userId == null) return Future.value(const PremiumStatus(paid: false));
    final fresh = _cached != null &&
        _cachedUserId == userId &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _maxAge;
    if (!refresh && fresh) return Future.value(_cached!);
    return _loading ??= _load(userId).whenComplete(() => _loading = null);
  }

  Future<PremiumStatus> _load(String userId) async {
    final paid = await hasPaidSubscription();
    PremiumStatus result;
    try {
      result = PremiumStatus.fromServer(await _statusLoader(), paid: paid);
    } catch (_) {
      // Without the server only a paid plan can be confirmed. Do not cache
      // this, so the next call retries the free-days lookup.
      return PremiumStatus.paidOnly(paid);
    }
    _cached = result;
    _cachedUserId = userId;
    _cachedAt = DateTime.now();
    return result;
  }

  /// True for paid subscribers and for users with free Premium days left.
  Future<bool> isPremium({bool refresh = false}) async =>
      (await status(refresh: refresh)).isPremium;

  void invalidate() {
    _cached = null;
    _cachedAt = null;
  }

  /// Credits the friend who invited this user: +7 days for both.
  Future<InviteRedeemResult> redeemInvite(String username) async {
    final cleaned = username.trim().replaceFirst(RegExp(r'^@+'), '');
    if (cleaned.isEmpty) return const InviteRedeemResult(InviteRedeemCode.empty);
    try {
      final result =
          InviteRedeemResult.fromServer(await _inviteRedeemer(cleaned));
      if (result.ok) invalidate();
      return result;
    } catch (_) {
      return const InviteRedeemResult(InviteRedeemCode.failed);
    }
  }
}
