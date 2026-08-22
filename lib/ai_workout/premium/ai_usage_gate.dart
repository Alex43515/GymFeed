import 'package:flutter/material.dart';

import '/ai_workout/payment/payment_widget.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/revenue_cat_util.dart' as revenue_cat;

const int freeAiUseLimit = 3;
const String premiumEntitlementId = 'premium_features';

/// Explicit internal QA accounts that need uninterrupted access while testing
/// the premium Coach tools. Keep this list UID-only so another account cannot
/// gain access by changing a profile email or username.
const Set<String> premiumTesterUserIds = <String>{
  'a9fd1bc3-61a8-43a0-b96e-b6e7f0c6d060', // test@test.com
};

bool hasPremiumTesterOverride(String? userId) =>
    userId != null && premiumTesterUserIds.contains(userId);

class AiUsageStatus {
  const AiUsageStatus({required this.isPremium, required this.used});

  final bool isPremium;
  final int used;

  int get remaining => isPremium
      ? freeAiUseLimit
      : (freeAiUseLimit - used).clamp(0, freeAiUseLimit);
  bool get exhausted => !isPremium && remaining == 0;
}

enum AiUseResult { premium, free, exhausted, unavailable }

class AiUseDecision {
  const AiUseDecision(this.result, {this.remaining = 0});

  final AiUseResult result;
  final int remaining;

  bool get allowed =>
      result == AiUseResult.premium || result == AiUseResult.free;
  bool get consumedFreeUse => result == AiUseResult.free;
}

class AiUsageGate {
  SupabaseClient get _db => supabase;
  String? get _uid => _db.auth.currentUser?.id;

  Future<bool> isPremium() async {
    if (hasPremiumTesterOverride(_uid)) return true;
    if (revenue_cat.activeEntitlementIds.contains(premiumEntitlementId)) {
      return true;
    }
    return await revenue_cat.isEntitled(premiumEntitlementId) ?? false;
  }

  Future<AiUsageStatus> loadStatus() async {
    final premium = await isPremium();
    if (premium) return const AiUsageStatus(isPremium: true, used: 0);
    final uid = _uid;
    if (uid == null) return const AiUsageStatus(isPremium: false, used: 0);
    final row = await _db
        .from('profile_private')
        .select('button_click')
        .eq('id', uid)
        .maybeSingle();
    return AiUsageStatus(
      isPremium: false,
      used: ((row?['button_click'] as num?)?.toInt() ?? 0).clamp(0, 1 << 30),
    );
  }

  /// Atomically claims one shared free use with a compare-and-swap update.
  /// Food scans, equipment scans, and trainer messages all call this method.
  Future<AiUseDecision> claimUse() async {
    if (await isPremium()) {
      return const AiUseDecision(AiUseResult.premium,
          remaining: freeAiUseLimit);
    }
    final uid = _uid;
    if (uid == null) return const AiUseDecision(AiUseResult.unavailable);

    try {
      for (var attempt = 0; attempt < 4; attempt++) {
        final row = await _db
            .from('profile_private')
            .select('button_click')
            .eq('id', uid)
            .maybeSingle();
        if (row == null) return const AiUseDecision(AiUseResult.unavailable);
        final used = (row['button_click'] as num?)?.toInt() ?? 0;
        if (used >= freeAiUseLimit) {
          return const AiUseDecision(AiUseResult.exhausted);
        }
        final updated = await _db
            .from('profile_private')
            .update({'button_click': used + 1})
            .eq('id', uid)
            .eq('button_click', used)
            .select('button_click');
        if ((updated as List).isNotEmpty) {
          return AiUseDecision(
            AiUseResult.free,
            remaining: (freeAiUseLimit - used - 1).clamp(0, freeAiUseLimit),
          );
        }
      }
    } catch (_) {
      return const AiUseDecision(AiUseResult.unavailable);
    }
    return const AiUseDecision(AiUseResult.unavailable);
  }

  /// A network/AI failure does not cost the user one of their trial uses.
  Future<void> refundUse() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      for (var attempt = 0; attempt < 4; attempt++) {
        final row = await _db
            .from('profile_private')
            .select('button_click')
            .eq('id', uid)
            .maybeSingle();
        final used = (row?['button_click'] as num?)?.toInt() ?? 0;
        if (used <= 0) return;
        final updated = await _db
            .from('profile_private')
            .update({'button_click': used - 1})
            .eq('id', uid)
            .eq('button_click', used)
            .select('button_click');
        if ((updated as List).isNotEmpty) return;
      }
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
    const SnackBar(
      content: Text('Could not verify your free uses. Please try again.'),
    ),
  );
  return false;
}
