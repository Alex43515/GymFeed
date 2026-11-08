import '/components/eula/eula_widget.dart';
import '/components/privacy_plocy/privacy_plocy_widget.dart';
import '/custom_code/widgets/create_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/revenue_cat_util.dart' as revenue_cat;
import '/backend/supabase/supabase.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'payment_model.dart';
export 'payment_model.dart';

class PaymentWidget extends StatefulWidget {
  const PaymentWidget({super.key, this.initialPremium = false});

  final bool initialPremium;

  @override
  State<PaymentWidget> createState() => _PaymentWidgetState();
}

class _PaymentWidgetState extends State<PaymentWidget> {
  late PaymentModel _model;

  static const _surface = Color(0xFF151515);

  // 0 = Free, 1 = Premium. Matches the two tabs in the paywall design.
  int _tab = 0;
  bool _billingBusy = false;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PaymentModel());
    _tab = widget.initialPremium ? 1 : 0;

    if (revenue_cat.offerings == null) {
      revenue_cat.loadOfferings().then((_) {
        if (mounted) safeSetState(() {});
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  // ── Building blocks ────────────────────────────────────────────────────────
  Widget _tabButton(String label, int index) {
    final theme = FlutterFlowTheme.of(context);
    final active = _tab == index;
    return Expanded(
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
        onTap: () => safeSetState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? theme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            label,
            style: theme.bodyMedium.override(
              fontFamily: 'Poppins',
              color: active ? Colors.black : kCreateHint,
              fontSize: 15.0,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _priceCard({required bool isFree, required String premiumPrice}) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(
          color: isFree ? const Color(0x33FFFFFF) : theme.primary,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            isFree ? 'Free plan' : 'Premium plan',
            style: theme.bodyMedium.override(
              fontFamily: 'Poppins',
              color: isFree ? kCreateHint : theme.primary,
              fontSize: 14.0,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            isFree
                ? 'Free'
                : premiumPrice.isEmpty
                    ? 'Monthly'
                    : premiumPrice,
            style: theme.headlineMedium.override(
              fontFamily: 'Poppins',
              color: theme.tertiary,
              fontSize: 38.0,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            isFree ? 'No subscription needed' : 'Per month',
            style: theme.bodyMedium.override(
              fontFamily: 'Poppins',
              color: kCreateHint,
              fontSize: 13.0,
              letterSpacing: 0.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _feature(IconData icon, String title, String detail) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        children: [
          Container(
            width: 42.0,
            height: 42.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF103820),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(icon, color: theme.primary, size: 21.0),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.bodyMedium.override(
                    fontFamily: 'Poppins',
                    color: theme.tertiary,
                    fontSize: 15.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1.0),
                Text(
                  detail,
                  style: theme.bodyMedium.override(
                    fontFamily: 'Poppins',
                    color: kCreateHint,
                    fontSize: 13.0,
                    letterSpacing: 0.0,
                    lineHeight: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _note(IconData icon, String text) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.primary, size: 18.0),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              text,
              style: theme.bodyMedium.override(
                fontFamily: 'Poppins',
                color: theme.tertiary,
                fontSize: 13.0,
                letterSpacing: 0.0,
                lineHeight: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _termsLine() {
    final theme = FlutterFlowTheme.of(context);
    Future<void> _sheet(Widget child) => showModalBottomSheet(
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          enableDrag: false,
          context: context,
          builder: (context) => Padding(
            padding: MediaQuery.viewInsetsOf(context),
            child: child,
          ),
        ).then((value) => safeSetState(() {}));
    return RichText(
      textScaler: MediaQuery.of(context).textScaler,
      textAlign: TextAlign.center,
      text: TextSpan(
        style: theme.bodyMedium.override(
          fontFamily: 'Poppins',
          color: kCreateHint,
          fontSize: 12.0,
          letterSpacing: 0.0,
        ),
        children: [
          const TextSpan(text: 'By continuing you agree to our '),
          TextSpan(
            text: 'Terms of Use (EULA)',
            style:
                TextStyle(color: theme.tertiary, fontWeight: FontWeight.w600),
            mouseCursor: SystemMouseCursors.click,
            recognizer: TapGestureRecognizer()
              ..onTap = () async => _sheet(EulaWidget()),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style:
                TextStyle(color: theme.tertiary, fontWeight: FontWeight.w600),
            mouseCursor: SystemMouseCursors.click,
            recognizer: TapGestureRecognizer()
              ..onTap = () async => _sheet(PrivacyPlocyWidget()),
          ),
        ],
      ),
    );
  }

  Future<void> _subscribe() async {
    if (_billingBusy) return;
    if (kIsWeb) {
      await launchURL(
        'https://play.google.com/store/apps/details?id=com.flutterflow.gymfeedofficial',
      );
      return;
    }
    _billingBusy = true;
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null || !await revenue_cat.login(uid)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please sign in and try again.'),
          ));
        }
        return;
      }
      var monthly = revenue_cat.offerings?.current?.monthly;
      if (monthly == null) {
        await revenue_cat.loadOfferings();
        monthly = revenue_cat.offerings?.current?.monthly;
      }
      if (monthly == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The monthly plan is unavailable.')),
        );
        return;
      }
      final outcome = await revenue_cat.purchasePackageWithOutcome(
        monthly.identifier,
        requiredEntitlementId: 'premium_features',
      );
      if (!mounted) return;
      if (outcome == revenue_cat.PurchaseOutcome.active) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GymFeed Pro is now active.')),
        );
        context.safePop();
      } else if (outcome != revenue_cat.PurchaseOutcome.cancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              switch (outcome) {
                revenue_cat.PurchaseOutcome.pending =>
                  'Your purchase is pending approval. Premium will activate after approval.',
                revenue_cat.PurchaseOutcome.missingEntitlement =>
                  'Premium access could not be verified. Try Restore or contact support.',
                _ => 'Purchase could not be completed. Please try again.',
              },
              style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
            ),
            duration: const Duration(milliseconds: 4000),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
      safeSetState(() {});
    } finally {
      _billingBusy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isFree = _tab == 0;
    final premiumPrice =
        revenue_cat.offerings?.current?.monthly?.storeProduct.priceString ?? '';

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFF0A0A0A)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20.0, 12.0, 20.0, 12.0),
          child: Column(
            children: [
              // Header: close + restore
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async => context.safePop(),
                    child: Icon(Icons.close_rounded,
                        color: theme.tertiary, size: 24.0),
                  ),
                  InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      if (kIsWeb) {
                        await launchURL(
                          'https://play.google.com/store/apps/details?id=com.flutterflow.gymfeedofficial',
                        );
                        return;
                      }
                      if (_billingBusy) return;
                      _billingBusy = true;
                      var restored = false;
                      try {
                        final uid = supabase.auth.currentUser?.id;
                        if (uid != null && await revenue_cat.login(uid)) {
                          restored = await revenue_cat.restorePurchases();
                        }
                      } finally {
                        _billingBusy = false;
                      }
                      final premiumActive = restored &&
                          revenue_cat.activeEntitlementIds
                              .contains('premium_features');
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            premiumActive
                                ? 'GymFeed Pro restored.'
                                : restored
                                    ? 'No active GymFeed Pro purchase was found.'
                                    : 'Purchases could not be restored. Try again.',
                            style: TextStyle(color: theme.secondary),
                          ),
                          duration: const Duration(milliseconds: 4000),
                          backgroundColor:
                              premiumActive ? theme.primary : theme.error,
                        ),
                      );
                      safeSetState(() {});
                    },
                    child: Text(
                      'Restore',
                      style: theme.bodyMedium.override(
                        fontFamily: 'Poppins',
                        color: kCreateHint,
                        letterSpacing: 0.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              // Tabs
              Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Row(
                  children: [_tabButton('Free', 0), _tabButton('Premium', 1)],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20.0),
                      Text(
                        isFree
                            ? 'Train and share for free'
                            : 'Your AI coach for training and food',
                        textAlign: TextAlign.center,
                        style: theme.headlineMedium.override(
                          fontFamily: 'Poppins',
                          color: theme.tertiary,
                          fontSize: 25.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w700,
                          lineHeight: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        isFree
                            ? 'Track your workouts and stay connected with your gym community.'
                            : 'Scan meals and gym machines, and get coaching that fits your day.',
                        textAlign: TextAlign.center,
                        style: theme.bodyMedium.override(
                          fontFamily: 'Poppins',
                          color: kCreateHint,
                          fontSize: 14.0,
                          letterSpacing: 0.0,
                          lineHeight: 1.35,
                        ),
                      ),
                      const SizedBox(height: 18.0),
                      _priceCard(isFree: isFree, premiumPrice: premiumPrice),
                      const SizedBox(height: 20.0),
                      // What each plan really includes. The 40 matches the
                      // daily limit in the claim_ai_use server function.
                      if (isFree) ...[
                        _feature(
                          Icons.dynamic_feed_rounded,
                          'Feed and community',
                          'Post your progress, follow friends and join events',
                        ),
                        _feature(
                          Icons.playlist_add_check_rounded,
                          'Workout tracking',
                          'Log your sets and build your routines',
                        ),
                        _feature(
                          Icons.menu_book_rounded,
                          'Training plans',
                          'Follow ready-made plans from the community',
                        ),
                        _note(
                          Icons.card_giftcard_rounded,
                          'New members get free Premium days. Invite a friend and you both get 7 more days, up to 4 friends.',
                        ),
                      ] else ...[
                        _feature(
                          Icons.restaurant_rounded,
                          'Food scanner',
                          'Calories and macros from a photo',
                        ),
                        _feature(
                          Icons.fitness_center_rounded,
                          'Equipment scanner',
                          'Identify a machine and see how to use it',
                        ),
                        _feature(
                          Icons.auto_awesome_rounded,
                          'AI Trainer',
                          'Chat about training and nutrition, and get workout and meal plans',
                        ),
                        _note(
                          Icons.info_outline_rounded,
                          'Includes up to 40 scans and AI Trainer messages a day.',
                        ),
                      ],
                      const SizedBox(height: 12.0),
                    ],
                  ),
                ),
              ),
              // Bottom CTA + terms
              Text(
                isFree
                    ? 'Upgrade anytime'
                    : 'Auto-renews monthly. Cancel anytime.',
                textAlign: TextAlign.center,
                style: theme.bodySmall.override(
                  fontFamily: 'Poppins',
                  color: kCreateHint,
                  fontSize: 12.0,
                  letterSpacing: 0.0,
                ),
              ),
              const SizedBox(height: 12.0),
              createPrimaryButton(
                context,
                label: isFree ? 'Try Premium' : 'Subscribe',
                onTap: () async {
                  if (isFree) {
                    safeSetState(() => _tab = 1);
                  } else {
                    await _subscribe();
                  }
                },
              ),
              const SizedBox(height: 12.0),
              _termsLine(),
            ],
          ),
        ),
      ),
    );
  }
}
