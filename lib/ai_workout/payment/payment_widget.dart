import '/components/eula/eula_widget.dart';
import '/components/privacy_plocy/privacy_plocy_widget.dart';
import '/custom_code/widgets/create_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/revenue_cat_util.dart' as revenue_cat;
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

  // 0 = Free, 1 = Premium. Matches the two tabs in the paywall design.
  int _tab = 0;

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
        onTap: () => safeSetState(() => _tab = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text(
                label,
                style: theme.bodyMedium.override(
                  fontFamily: 'Poppins',
                  color: active ? theme.tertiary : kCreateHint,
                  fontSize: 16.0,
                  letterSpacing: 0.0,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Container(
              height: 2.0,
              color: active ? theme.primary : const Color(0xFF2A2A2A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feature(String text) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, color: theme.primary, size: 22.0),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              text,
              style: theme.bodyMedium.override(
                fontFamily: 'Poppins',
                color: theme.tertiary,
                fontSize: 15.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.normal,
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
    if (kIsWeb) {
      await launchURL(
        'https://play.google.com/store/apps/details?id=com.flutterflow.gymfeedofficial',
      );
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
    final purchased = await revenue_cat.purchasePackage(monthly.identifier);
    if (purchased) {
      await revenue_cat.loadCustomerInfo();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GymFeed Pro is now active.')),
      );
      context.safePop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed Purchase',
            style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
          ),
          duration: const Duration(milliseconds: 4000),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    }
    safeSetState(() {});
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
                      final restored = await revenue_cat.restorePurchases();
                      final premiumActive = revenue_cat.activeEntitlementIds
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
              Row(children: [_tabButton('Free', 0), _tabButton('Premium', 1)]),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 22.0),
                      Text(
                        'Start Your Fitness Journey with GymFeed',
                        textAlign: TextAlign.center,
                        style: theme.headlineMedium.override(
                          fontFamily: 'Poppins',
                          color: theme.tertiary,
                          fontSize: 27.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w700,
                          lineHeight: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Text(
                        'Elevate your fitness and health experience with our premium AI features',
                        textAlign: TextAlign.center,
                        style: theme.bodyMedium.override(
                          fontFamily: 'Poppins',
                          color: kCreateHint,
                          fontSize: 14.0,
                          letterSpacing: 0.0,
                        ),
                      ),
                      const SizedBox(height: 22.0),
                      // Price
                      Center(
                        child: Text(
                          isFree
                              ? '0€'
                              : premiumPrice.isEmpty
                                  ? 'Monthly'
                                  : premiumPrice,
                          style: theme.headlineMedium.override(
                            fontFamily: 'Poppins',
                            color: theme.tertiary,
                            fontSize: 44.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Center(
                        child: Text(
                          'Per month',
                          style: theme.bodyMedium.override(
                            fontFamily: 'Poppins',
                            color: kCreateHint,
                            fontSize: 14.0,
                            letterSpacing: 0.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      // Plan chip (outlined)
                      Container(
                        width: double.infinity,
                        height: 54.0,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: isFree
                                ? const Color(0x33FFFFFF)
                                : theme.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          isFree ? 'Free plan' : 'Premium plan',
                          style: theme.bodyMedium.override(
                            fontFamily: 'Poppins',
                            color: theme.tertiary,
                            fontSize: 16.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22.0),
                      // Features
                      if (isFree) ...[
                        _feature('Customer Support'),
                        _feature('Unlimited numbers of creations'),
                        _feature(
                            '3 shared uses of Scan food, Scan equipment, and AI Trainer'),
                      ] else ...[
                        _feature('Customer Support'),
                        _feature('Unlimited numbers of creations'),
                        _feature('Unlimited food and equipment scans'),
                        _feature('Unlimited AI Trainer conversations'),
                        _feature('Detailed body composition reports'),
                        _feature('One month of GymFeed Pro access'),
                      ],
                      const SizedBox(height: 8.0),
                    ],
                  ),
                ),
              ),
              // Bottom CTA + terms
              Text(
                'Auto-renewable. Cancel anytime',
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
