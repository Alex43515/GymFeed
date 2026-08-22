import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/supabase_auth/email_verification_service.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'email_verification_model.dart';

export 'email_verification_model.dart';

const _background = Color(0xFF090909);
const _surface = Color(0xFF151515);
const _border = Color(0xFF2A2A2A);
const _green = Color(0xFF1FE276);
const _muted = Color(0xFF929292);

class EmailVerificationWidget extends StatefulWidget {
  const EmailVerificationWidget({
    super.key,
    this.verificationChecker,
    this.resendAction,
    this.onboardingCompleter,
    this.verifiedOpener,
    this.verificationEvents,
    this.email,
    this.resendCooldown = const Duration(seconds: 60),
  });

  static String routeName = 'EmailVerification';
  static String routePath = 'emailVerification';

  /// Test seams also keep the UI independent from a particular auth SDK.
  final Future<bool> Function()? verificationChecker;
  final Future<void> Function()? resendAction;
  final Future<void> Function()? onboardingCompleter;
  final VoidCallback? verifiedOpener;
  final Stream<bool>? verificationEvents;
  final String? email;
  final Duration resendCooldown;

  @override
  State<EmailVerificationWidget> createState() =>
      _EmailVerificationWidgetState();
}

class _EmailVerificationWidgetState extends State<EmailVerificationWidget> {
  late EmailVerificationModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<bool>? _verificationSubscription;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  bool _checking = false;
  bool _resending = false;
  bool _completing = false;
  bool _readRouteError = false;
  String? _message;
  bool _messageIsError = false;

  String get _email {
    final suppliedEmail = widget.email?.trim() ?? '';
    if (suppliedEmail.isNotEmpty) return suppliedEmail;
    final liveEmail = supabase.auth.currentUser?.email?.trim() ?? '';
    if (liveEmail.isNotEmpty) return liveEmail;
    final pending = FFAppState().pendingVerificationEmail.trim();
    if (pending.isNotEmpty) return pending;
    return FFAppState().signupEmail.trim();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EmailVerificationModel());
    final events = widget.verificationEvents ??
        supabase.auth.onAuthStateChange.map(
          (event) => event.session?.user.emailConfirmedAt != null,
        );
    _verificationSubscription = events.distinct().listen(
      (verified) {
        if (verified) unawaited(_finishVerification());
      },
      onError: (Object error, StackTrace stack) {
        if (!mounted) return;
        setState(() {
          _message = isEmailConfirmationError(error)
              ? 'Verify your email before continuing.'
              : 'The verification link could not be completed. Request a new email.';
          _messageIsError = true;
        });
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkVerification(showWaitingMessage: false));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_readRouteError) return;
    _readRouteError = true;
    String? error;
    try {
      error = verificationLinkError(GoRouterState.of(context).uri);
    } catch (_) {
      // Widget tests and embedded previews may not have a GoRouter ancestor.
    }
    if (error != null) {
      _message = error;
      _messageIsError = true;
    }
  }

  @override
  void dispose() {
    _verificationSubscription?.cancel();
    _cooldownTimer?.cancel();
    _model.dispose();
    super.dispose();
  }

  Future<bool> _defaultVerificationCheck() async {
    if (supabase.auth.currentSession == null) return false;
    await authManager.refreshUser();
    return supabase.auth.currentUser?.emailConfirmedAt != null;
  }

  Future<void> _checkVerification({bool showWaitingMessage = true}) async {
    if (_checking || _completing) return;
    setState(() {
      _checking = true;
      if (showWaitingMessage) _message = null;
    });
    try {
      final verified = await (widget.verificationChecker?.call() ??
          _defaultVerificationCheck());
      if (!mounted) return;
      if (verified) {
        await _finishVerification();
      } else if (showWaitingMessage) {
        setState(() {
          _message =
              'Not verified yet. Open the newest GymFeed email and tap Verify email.';
          _messageIsError = false;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = 'We could not check verification. Check your connection.';
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _finishVerification() async {
    if (_completing) return;
    setState(() {
      _completing = true;
      _message = 'Email verified. Finishing your GymFeed setup…';
      _messageIsError = false;
    });
    try {
      await (widget.onboardingCompleter?.call() ??
          completeVerifiedOnboarding());
      if (!mounted) return;
      setState(() => _completing = false);
      final opener = widget.verifiedOpener;
      if (opener != null) {
        opener();
      } else {
        context.goNamed(AllMostDoneWidget.routeName);
      }
    } catch (error) {
      debugPrint('Verified onboarding completion failed: $error');
      if (!mounted) return;
      setState(() {
        _completing = false;
        _message =
            'Your email is verified, but setup could not finish. Tap Continue to retry.';
        _messageIsError = true;
      });
    }
  }

  Future<void> _resend() async {
    if (_resending || _cooldownSeconds > 0) return;
    setState(() {
      _resending = true;
      _message = null;
    });
    try {
      await (widget.resendAction?.call() ??
          authManager.sendEmailVerification());
      if (!mounted) return;
      setState(() {
        _message = 'A new verification email was sent to $_email.';
        _messageIsError = false;
        _cooldownSeconds = widget.resendCooldown.inSeconds;
      });
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return timer.cancel();
        setState(() {
          _cooldownSeconds -= 1;
          if (_cooldownSeconds <= 0) timer.cancel();
        });
      });
    } catch (error) {
      if (!mounted) return;
      final rateLimited = error.toString().toLowerCase().contains('rate');
      setState(() {
        _message = rateLimited
            ? 'Please wait a minute before requesting another email.'
            : 'We could not resend the email. Check the address and try again.';
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _changeEmail() async {
    await authManager.signOut();
    FFAppState().pendingVerificationEmail = '';
    if (!mounted) return;
    context.goNamed(WelcomePageWidget.routeName);
  }

  TextStyle _text({
    double size = 14,
    Color color = Colors.white,
    FontWeight weight = FontWeight.w400,
    double height = 1.35,
  }) =>
      TextStyle(
        fontFamily: 'Poppins',
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
      );

  @override
  Widget build(BuildContext context) {
    final busy = _checking || _completing;
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _green,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(Icons.mark_email_read_rounded,
                              color: _background, size: 22),
                        ),
                        const SizedBox(width: 11),
                        Text('GymFeed',
                            style: _text(size: 22, weight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 54),
                    Text('Verify your email',
                        style: _text(size: 30, weight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Text(
                      'We sent a secure verification link to',
                      style: _text(size: 13, color: _muted),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _email.isEmpty ? 'your email address' : _email,
                      key: const ValueKey('verification-email'),
                      style: _text(
                          size: 15, color: _green, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              color: const Color(0xFF103523),
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: busy
                                ? const Padding(
                                    padding: EdgeInsets.all(28),
                                    child: CircularProgressIndicator(
                                        color: _green, strokeWidth: 3),
                                  )
                                : const Icon(Icons.alternate_email_rounded,
                                    color: _green, size: 40),
                          ),
                          const SizedBox(height: 18),
                          Text('Check your inbox',
                              style: _text(size: 18, weight: FontWeight.w700)),
                          const SizedBox(height: 7),
                          Text(
                            'Tap Verify email in the newest message. The link opens GymFeed, then you can answer the questions for your personalized meal and training plans.',
                            textAlign: TextAlign.center,
                            style: _text(size: 12, color: _muted, height: 1.55),
                          ),
                          const SizedBox(height: 18),
                          OutlinedButton.icon(
                            key: const ValueKey('open-email-app'),
                            onPressed: () => launchUrl(Uri(scheme: 'mailto')),
                            icon:
                                const Icon(Icons.open_in_new_rounded, size: 17),
                            label: const Text('Open email app'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: _border),
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        key: const ValueKey('verification-message'),
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: (_messageIsError
                                  ? const Color(0xFFFF6262)
                                  : _green)
                              .withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: (_messageIsError
                                    ? const Color(0xFFFF6262)
                                    : _green)
                                .withValues(alpha: .45),
                          ),
                        ),
                        child: Text(
                          _message!,
                          style: _text(
                            size: 11,
                            color: _messageIsError
                                ? const Color(0xFFFF8A8A)
                                : _green,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Didn't get it? ",
                            style: _text(size: 12, color: _muted)),
                        TextButton(
                          key: const ValueKey('resend-verification'),
                          onPressed: _resending || _cooldownSeconds > 0
                              ? null
                              : _resend,
                          child: Text(
                            _resending
                                ? 'Sending…'
                                : _cooldownSeconds > 0
                                    ? 'Resend in ${_cooldownSeconds}s'
                                    : 'Resend email',
                            style: _text(
                              size: 12,
                              color: _cooldownSeconds > 0 ? _muted : _green,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      key: const ValueKey('change-verification-email'),
                      onPressed: _changeEmail,
                      child: Text('Use a different email',
                          style: _text(size: 11, color: _muted)),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: const BoxDecoration(
                color: _background,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  key: const ValueKey('check-verification'),
                  onPressed: busy ? null : _checkVerification,
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    disabledBackgroundColor: const Color(0xFF215F3B),
                    foregroundColor: _background,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text(
                    _completing
                        ? 'Finishing setup…'
                        : _checking
                            ? 'Checking…'
                            : 'I verified my email — continue',
                    style: _text(
                        size: 14, color: _background, weight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
