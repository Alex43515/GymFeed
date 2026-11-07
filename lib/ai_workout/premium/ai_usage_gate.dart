import 'package:flutter/material.dart';

import '/ai_workout/payment/payment_widget.dart';
import '/ai_workout/premium/premium_access.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/revenue_cat_util.dart' as revenue_cat;

export '/ai_workout/premium/premium_access.dart'
    show
        PremiumAccess,
        PremiumStatus,
        premiumEntitlementId,
        premiumTesterUserIds,
        hasPremiumTesterOverride;

enum AiUseResult { premium, exhausted, dailyLimit, unavailable }

class AiUseDecision {
  const AiUseDecision(this.result, {this.counted = false});

  final AiUseResult result;

  /// True when the server counted this action toward today's limit, so a
  /// failed AI call should give it back with [AiUsageGate.refundUse].
  final bool counted;

  bool get allowed => result == AiUseResult.premium;
}

/// Gate in front of every AI action (food scan, equipment scan, trainer
/// message, body scan).
///
/// Premium users, paid or on free Premium days, may use AI tools up to the
/// server's daily fair-use limit. Everyone else sees the upgrade screen.
class AiUsageGate {
  AiUsageGate({
    PremiumAccess? access,
    Future<Map<String, dynamic>> Function(bool clientPaid)? claimer,
    Future<void> Function()? refunder,
  })  : _access = access ?? PremiumAccess.instance,
        _claimer = claimer ?? _claimOnServer,
        _refunder = refunder ?? _refundOnServer;

  final PremiumAccess _access;
  final Future<Map<String, dynamic>> Function(bool clientPaid) _claimer;
  final Future<void> Function() _refunder;

  static Future<Map<String, dynamic>> _claimOnServer(bool clientPaid) async {
    final result = await supabase
        .rpc('claim_ai_use', params: {'p_client_paid': clientPaid});
    return Map<String, dynamic>.from(result as Map);
  }

  static Future<void> _refundOnServer() async {
    await supabase.rpc('refund_ai_use');
  }

  Future<bool> isPremium() => _access.isPremium();

  Future<PremiumStatus> loadStatus({bool refresh = false}) =>
      _access.status(refresh: refresh);

  /// Asks the server to count one AI action.
  Future<AiUseDecision> claimUse() async {
    final status = await _access.status();
    try {
      final result = await _claimer(status.paid);
      if (result['allowed'] == true) {
        return const AiUseDecision(AiUseResult.premium, counted: true);
      }
      return switch (result['reason']?.toString()) {
        'daily_limit' => const AiUseDecision(AiUseResult.dailyLimit),
        _ => const AiUseDecision(AiUseResult.exhausted),
      };
    } catch (_) {
      // A paying user is never blocked by a counting hiccup.
      if (status.paid) return const AiUseDecision(AiUseResult.premium);
      return const AiUseDecision(AiUseResult.unavailable);
    }
  }

  /// A network/AI failure does not count against today's limit.
  Future<void> refundUse() async {
    try {
      await _refunder();
    } catch (_) {}
  }
}

Future<void> openPremiumUpgrade(BuildContext context) async {
  await revenue_cat.loadOfferings();
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const Scaffold(body: PaymentWidget(initialPremium: true)),
    ),
  );
  PremiumAccess.instance.invalidate();
}

Future<bool> handleDeniedAiUse(
  BuildContext context,
  AiUseDecision decision, {
  Future<void> Function()? upgradeOpener,
}) async {
  if (decision.allowed) return true;
  if (decision.result == AiUseResult.exhausted) {
    if (upgradeOpener != null) {
      await upgradeOpener();
    } else {
      await openPremiumUpgrade(context);
    }
    return false;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        decision.result == AiUseResult.dailyLimit
            ? "You've reached today's AI limit. It resets tomorrow."
            : 'Could not verify your Premium access. Please try again.',
      ),
    ),
  );
  return false;
}
