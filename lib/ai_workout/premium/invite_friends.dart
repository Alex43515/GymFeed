import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/ai_workout/premium/premium_access.dart';
import '/backend/share_links.dart' show gymFeedInviteText;

/// Username typed into "Who invited you?" during signup. It is kept until the
/// verified profile exists and the invite has been redeemed.
class PendingInvite {
  PendingInvite._();

  static const _key = 'ff_pendingInviteUsername';
  static String _value = '';

  static String get value => _value;

  static String normalize(String raw) =>
      raw.trim().replaceFirst(RegExp(r'^@+'), '');

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _value = prefs.getString(_key) ?? '';
    } catch (_) {}
  }

  static Future<void> save(String raw) async {
    _value = normalize(raw);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_value.isEmpty) {
        await prefs.remove(_key);
      } else {
        await prefs.setString(_key, _value);
      }
    } catch (_) {}
  }

  static Future<void> clear() => save('');
}

/// Share text for the referral program. It tells the friend exactly what to
/// type, because the bonus only arrives when they enter the username.
String referralInviteText({required String username, int bonusDays = 7}) =>
    gymFeedInviteText(
      username: PendingInvite.normalize(username),
      bonusDays: bonusDays,
    );

Future<void> shareReferralInvite(
  BuildContext context, {
  required String username,
  int bonusDays = 7,
}) async {
  final text = referralInviteText(username: username, bonusDays: bonusDays);
  final box = context.findRenderObject() as RenderBox?;
  try {
    await Share.share(
      text,
      subject: 'Join me on GymFeed',
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite copied. Paste it to a friend.')),
    );
  }
}

/// Bottom sheet where a new user enters the friend who invited them.
/// Returns the result, or null when the sheet was dismissed.
Future<InviteRedeemResult?> showRedeemInviteSheet(
  BuildContext context, {
  Future<InviteRedeemResult> Function(String username)? redeemer,
}) {
  return showModalBottomSheet<InviteRedeemResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF141414),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _RedeemInviteSheet(
      redeemer: redeemer ?? PremiumAccess.instance.redeemInvite,
    ),
  );
}

class _RedeemInviteSheet extends StatefulWidget {
  const _RedeemInviteSheet({required this.redeemer});

  final Future<InviteRedeemResult> Function(String username) redeemer;

  @override
  State<_RedeemInviteSheet> createState() => _RedeemInviteSheetState();
}

class _RedeemInviteSheetState extends State<_RedeemInviteSheet> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.redeemer(_controller.text);
    if (!mounted) return;
    if (result.ok) {
      Navigator.of(context).pop(result);
      return;
    }
    setState(() {
      _busy = false;
      _error = result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 18, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Who invited you?',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your friend\'s username. You both get 7 more days of Premium.',
            style: TextStyle(color: Color(0xFF9A9A9A), fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('redeem-invite-input'),
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixText: '@',
              prefixStyle: const TextStyle(color: Color(0xFF9A9A9A)),
              hintText: 'username',
              hintStyle: const TextStyle(color: Color(0xFF6A6A6A)),
              errorText: _error,
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('redeem-invite-submit'),
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1FE276),
                foregroundColor: const Color(0xFF062313),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(_busy ? 'Adding…' : 'Add invite',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Coach page block: free Premium days left, invites used and the invite
/// button. Paid subscribers see the regular "Pro active" card.
class PremiumDaysCard extends StatelessWidget {
  const PremiumDaysCard({
    super.key,
    required this.status,
    required this.onUpgrade,
    required this.onInvite,
    required this.onRedeemInvite,
  });

  final PremiumStatus status;
  final VoidCallback onUpgrade;
  final VoidCallback onInvite;
  final VoidCallback onRedeemInvite;

  static const _green = Color(0xFF1FE276);
  static const _muted = Color(0xFF9A9A9A);

  TextStyle _text(double size,
          {Color color = Colors.white,
          FontWeight weight = FontWeight.w400}) =>
      TextStyle(
          fontFamily: 'Poppins',
          fontSize: size,
          color: color,
          fontWeight: weight,
          height: 1.3);

  @override
  Widget build(BuildContext context) {
    if (status.paid) return _paidCard();
    final active = status.freeDaysActive;
    final days = status.daysLeft;
    final title = active
        ? 'Premium · $days ${days == 1 ? 'day' : 'days'} left'
        : status.serverKnown
            ? 'Your free Premium has ended'
            : 'Unlock GymFeed Pro';
    final invites =
        'Invite friends: +${status.referralBonusDays} days each · ${status.invitesUsed} of ${status.invitesMax} used';

    return Container(
      key: const ValueKey('coach-premium-banner'),
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF103820),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF176137)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: _green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    key: const ValueKey('coach-premium-days'),
                    style: _text(15, weight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            active
                ? invites
                : status.serverKnown
                    ? 'Invite a friend for ${status.referralBonusDays} more days, or upgrade for unlimited AI tools.'
                    : 'Unlimited AI scans and coaching.',
            style: _text(12, color: const Color(0xFFB9E8CB)),
          ),
          if (!active && status.serverKnown) ...[
            const SizedBox(height: 2),
            Text(invites, style: _text(12, color: const Color(0xFFB9E8CB))),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (status.serverKnown && status.canInvite)
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('coach-invite-friend'),
                    onPressed: onInvite,
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
                    label: Text('Invite a friend',
                        style: _text(13,
                            color: const Color(0xFF062313),
                            weight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: const Color(0xFF062313),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              if (status.serverKnown && status.canInvite)
                const SizedBox(width: 8),
              TextButton(
                key: const ValueKey('coach-upgrade'),
                onPressed: onUpgrade,
                style: TextButton.styleFrom(
                  foregroundColor: _green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFF2B7A4B)),
                  ),
                ),
                child: Text('Upgrade',
                    style: _text(13, color: _green, weight: FontWeight.w700)),
              ),
            ],
          ),
          if (status.canRedeemInvite) ...[
            const SizedBox(height: 6),
            TextButton(
              key: const ValueKey('coach-redeem-invite'),
              onPressed: onRedeemInvite,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                foregroundColor: _muted,
              ),
              child: Text('Invited by a friend? Enter their username',
                  style: _text(12,
                      color: const Color(0xFFB9E8CB),
                      weight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _paidCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF103820),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF176137)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded, color: _green),
          const SizedBox(width: 11),
          Expanded(
            child: Text('GymFeed Pro active · Unlimited AI tools',
                style: _text(13, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
