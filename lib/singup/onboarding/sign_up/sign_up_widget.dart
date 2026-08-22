import 'dart:async';

import '/backend/supabase/repositories/profile_repository.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/auth/supabase_auth/social_auth_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'sign_up_model.dart';
export 'sign_up_model.dart';

class SignUpWidget extends StatefulWidget {
  const SignUpWidget({
    super.key,
    this.usernameAvailabilityChecker,
  });

  static String routeName = 'SignUp';
  static String routePath = 'signUp';

  /// Test seam; production uses the server-authoritative Supabase RPC.
  final Future<bool> Function(String username)? usernameAvailabilityChecker;

  @override
  State<SignUpWidget> createState() => _SignUpWidgetState();
}

class _SignUpWidgetState extends State<SignUpWidget> {
  late SignUpModel _model;
  Timer? _usernameDebounce;
  int _usernameRequest = 0;
  _UsernameAvailability _usernameAvailability = _UsernameAvailability.idle;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SignUpModel());

    _model.fullNameTextController ??= TextEditingController();
    _model.fullNameFocusNode ??= FocusNode();

    _model.usernameTextController ??= TextEditingController();
    _model.usernameFocusNode ??= FocusNode();

    _model.emailAddressTextController ??= TextEditingController();
    _model.emailAddressFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _model.dispose();

    super.dispose();
  }

  void _clearError() {
    if (_model.errorField.isNotEmpty) {
      safeSetState(() {
        _model.errorField = '';
        _model.errorMessage = '';
      });
    }
  }

  Future<bool> _lookupUsername(String username) =>
      widget.usernameAvailabilityChecker?.call(username) ??
      ProfileRepository().isUsernameAvailable(username);

  void _onUsernameChanged(String value) {
    _clearError();
    _usernameDebounce?.cancel();
    final request = ++_usernameRequest;
    final username = value.trim();
    if (!RegExp(r'^[A-Za-z0-9_]{3,30}$').hasMatch(username)) {
      safeSetState(() => _usernameAvailability = _UsernameAvailability.idle);
      return;
    }
    safeSetState(() => _usernameAvailability = _UsernameAvailability.checking);
    _usernameDebounce = Timer(const Duration(milliseconds: 450), () async {
      try {
        final available = await _lookupUsername(username);
        if (!mounted || request != _usernameRequest) return;
        safeSetState(() => _usernameAvailability = available
            ? _UsernameAvailability.available
            : _UsernameAvailability.taken);
      } catch (_) {
        if (!mounted || request != _usernameRequest) return;
        safeSetState(() => _usernameAvailability = _UsernameAvailability.error);
      }
    });
  }

  Widget? _usernameSuffix(Color green, Color red, Color muted) {
    switch (_usernameAvailability) {
      case _UsernameAvailability.idle:
        return null;
      case _UsernameAvailability.checking:
        return const Padding(
          key: ValueKey('username-checking'),
          padding: EdgeInsets.all(15),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case _UsernameAvailability.available:
        return Icon(Icons.check_circle_rounded,
            key: const ValueKey('username-available'), color: green);
      case _UsernameAvailability.taken:
        return Icon(Icons.cancel_rounded,
            key: const ValueKey('username-taken'), color: red);
      case _UsernameAvailability.error:
        return Icon(Icons.error_outline_rounded,
            key: const ValueKey('username-check-error'), color: muted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final bool hasError = _model.errorField.isNotEmpty;

    InputDecoration fieldDecoration(String hint,
        {required bool fieldError, Widget? suffixIcon}) {
      final normal = OutlineInputBorder(
        borderSide: BorderSide(color: theme.secondary, width: 1.0),
        borderRadius: BorderRadius.circular(16.0),
      );
      final errored = OutlineInputBorder(
        borderSide: BorderSide(color: theme.error, width: 1.0),
        borderRadius: BorderRadius.circular(16.0),
      );
      return InputDecoration(
        hintText: hint,
        hintStyle: theme.bodyMedium.override(
          fontFamily: 'Poppins',
          color: theme.secondaryText,
          fontSize: 15.0,
          letterSpacing: 0.0,
        ),
        enabledBorder: fieldError ? errored : normal,
        focusedBorder: fieldError ? errored : normal,
        errorBorder: errored,
        focusedErrorBorder: errored,
        filled: true,
        fillColor: theme.secondary,
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsetsDirectional.fromSTEB(22.0, 20.0, 16.0, 20.0),
      );
    }

    TextStyle fieldTextStyle(bool fieldError) => theme.bodyMedium.override(
          fontFamily: 'Poppins',
          color: fieldError ? theme.error : theme.tertiary,
          fontSize: 15.0,
          letterSpacing: 0.0,
        );

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.tertiary,
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(24.0, 12.0, 24.0, 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => context.safePop(),
                    ),
                    _circleIconButton(
                      icon: Icons.close_rounded,
                      onTap: () => context.safePop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Form(
                    key: _model.formKey,
                    autovalidateMode: AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8.0),
                        Text(
                          'Register Account',
                          style: theme.displaySmall.override(
                            fontFamily: 'Poppins',
                            color: theme.secondary,
                            fontSize: 34.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          'Complete your details or sync with socials',
                          style: theme.bodyMedium.override(
                            fontFamily: 'Poppins',
                            color: theme.secondaryText,
                            fontSize: 15.0,
                            letterSpacing: 0.0,
                          ),
                        ),
                        if (hasError)
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0.0, 10.0, 0.0, 0.0),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline_rounded,
                                    color: theme.error, size: 18.0),
                                const SizedBox(width: 6.0),
                                Flexible(
                                  child: Text(
                                    _model.errorMessage,
                                    style: theme.bodyMedium.override(
                                      fontFamily: 'Poppins',
                                      color: theme.error,
                                      fontSize: 14.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 26.0),
                        TextFormField(
                          controller: _model.fullNameTextController,
                          focusNode: _model.fullNameFocusNode,
                          onChanged: (_) => _clearError(),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: fieldDecoration('Full name',
                              fieldError: _model.errorField == 'name'),
                          style: fieldTextStyle(false),
                          cursorColor: theme.primary,
                          validator: _model.fullNameTextControllerValidator
                              .asValidator(context),
                        ),
                        const SizedBox(height: 14.0),
                        TextFormField(
                          controller: _model.usernameTextController,
                          focusNode: _model.usernameFocusNode,
                          onChanged: _onUsernameChanged,
                          textInputAction: TextInputAction.next,
                          decoration: fieldDecoration(
                            'Username',
                            fieldError: _model.errorField == 'username' ||
                                _usernameAvailability ==
                                    _UsernameAvailability.taken,
                            suffixIcon: _usernameSuffix(theme.primary,
                                theme.error, theme.secondaryText),
                          ),
                          style:
                              fieldTextStyle(_model.errorField == 'username'),
                          cursorColor: theme.primary,
                          validator: _model.usernameTextControllerValidator
                              .asValidator(context),
                        ),
                        if (_usernameAvailability ==
                                _UsernameAvailability.available ||
                            _usernameAvailability ==
                                _UsernameAvailability.taken ||
                            _usernameAvailability ==
                                _UsernameAvailability.error)
                          Padding(
                            padding: const EdgeInsets.only(top: 7, left: 4),
                            child: Text(
                              _usernameAvailability ==
                                      _UsernameAvailability.available
                                  ? 'Username is available'
                                  : _usernameAvailability ==
                                          _UsernameAvailability.taken
                                      ? 'Username is already taken'
                                      : 'Could not check right now. We’ll check again when you continue.',
                              key: const ValueKey('username-status-text'),
                              style: theme.bodySmall.override(
                                fontFamily: 'Poppins',
                                color: _usernameAvailability ==
                                        _UsernameAvailability.available
                                    ? theme.primary
                                    : _usernameAvailability ==
                                            _UsernameAvailability.taken
                                        ? theme.error
                                        : theme.secondaryText,
                                fontSize: 12,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        const SizedBox(height: 14.0),
                        TextFormField(
                          controller: _model.emailAddressTextController,
                          focusNode: _model.emailAddressFocusNode,
                          onChanged: (_) => _clearError(),
                          autofillHints: const [AutofillHints.email],
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          decoration: fieldDecoration('Email',
                              fieldError: _model.errorField == 'email'),
                          style: fieldTextStyle(_model.errorField == 'email'),
                          cursorColor: theme.primary,
                          validator: _model.emailAddressTextControllerValidator
                              .asValidator(context),
                        ),
                        const SizedBox(height: 40.0),
                        FFButtonWidget(
                          onPressed: () async {
                            _clearError();
                            if (_model.formKey.currentState == null ||
                                !_model.formKey.currentState!.validate()) {
                              return;
                            }
                            final username =
                                _model.usernameTextController.text.trim();
                            safeSetState(() => _usernameAvailability =
                                _UsernameAvailability.checking);
                            bool available;
                            try {
                              available = await _lookupUsername(username);
                            } catch (_) {
                              if (!mounted) return;
                              safeSetState(() {
                                _usernameAvailability =
                                    _UsernameAvailability.error;
                                _model.errorField = 'username';
                                _model.errorMessage =
                                    'We could not check that username. Check your connection and try again.';
                              });
                              return;
                            }
                            if (!mounted) return;
                            if (!available) {
                              safeSetState(() {
                                _usernameAvailability =
                                    _UsernameAvailability.taken;
                                _model.errorField = 'username';
                                _model.errorMessage =
                                    'Username taken! Please try again.';
                              });
                              return;
                            }
                            safeSetState(() => _usernameAvailability =
                                _UsernameAvailability.available);

                            FFAppState().signupName =
                                _model.fullNameTextController.text.trim();
                            FFAppState().signupUsername = username;
                            FFAppState().signupEmail =
                                _model.emailAddressTextController.text.trim();
                            FFAppState().update(() {});

                            context.goNamed(SignUpPasswordWidget.routeName);
                          },
                          text: 'Sign up',
                          options: FFButtonOptions(
                            width: double.infinity,
                            height: 56.0,
                            padding: EdgeInsets.zero,
                            iconPadding: EdgeInsets.zero,
                            color: hasError ? theme.accent3 : theme.primary,
                            textStyle: theme.titleSmall.override(
                              fontFamily: 'Poppins',
                              color: theme.secondary,
                              fontSize: 17.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                            ),
                            elevation: 0.0,
                            borderSide: const BorderSide(
                                color: Colors.transparent, width: 1.0),
                            borderRadius: BorderRadius.circular(28.0),
                          ),
                        ),
                        const SizedBox(height: 22.0),
                        Row(
                          children: [
                            Expanded(
                                child: Container(
                                    height: 1.0, color: theme.accent4)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'Or sign up with',
                                style: theme.bodySmall.override(
                                  fontFamily: 'Poppins',
                                  color: theme.secondaryText,
                                  fontSize: 13.0,
                                  letterSpacing: 0.0,
                                ),
                              ),
                            ),
                            Expanded(
                                child: Container(
                                    height: 1.0, color: theme.accent4)),
                          ],
                        ),
                        const SizedBox(height: 22.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _socialButton(
                                icon: FontAwesomeIcons.google,
                                onTap: () => _startSocialSignup(
                                    () => authManager.signInWithGoogle(
                                          context,
                                          nextPath: socialAuthSignupDestination,
                                        ))),
                          ],
                        ),
                        const SizedBox(height: 24.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Footer — fixed from the mockup's copy-paste: a sign-up screen
              // sends existing users to sign-in, not "Sign up" again.
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(24.0, 8.0, 24.0, 12.0),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.bodyMedium.override(
                        fontFamily: 'Poppins',
                        color: theme.secondaryText,
                        fontSize: 14.0,
                        letterSpacing: 0.0,
                      ),
                    ),
                    InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () => context.pushNamed(SignInWidget.routeName),
                      child: Text(
                        'Sign in',
                        style: theme.bodyMedium.override(
                          fontFamily: 'Poppins',
                          color: theme.secondary,
                          fontSize: 14.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startSocialSignup(
    Future<Object?> Function() launch,
  ) async {
    _clearError();
    final name = _model.fullNameTextController.text.trim();
    final username = _model.usernameTextController.text.trim();
    // Social providers supply the verified name and email. A username is
    // generated on the callback when the user leaves it blank, so tapping the
    // Google button on an empty form must still launch OAuth.
    final usernameError = username.isEmpty
        ? null
        : _model.usernameTextControllerValidator?.call(context, username);
    if (usernameError != null) {
      safeSetState(() {
        _model.errorField = 'username';
        _model.errorMessage = usernameError;
      });
      return;
    }

    final available = username.isEmpty
        ? true
        : await ProfileRepository().isUsernameAvailable(username);
    if (!available) {
      safeSetState(() {
        _model.errorField = 'username';
        _model.errorMessage = 'Username taken! Please try again.';
      });
      return;
    }

    FFAppState().signupName = name;
    FFAppState().signupUsername = username;
    // The verified provider email replaces this value on the callback page.
    FFAppState().signupEmail = '';
    FFAppState().update(() {});
    await launch();
  }

  Widget _circleIconButton(
      {required IconData icon, required VoidCallback onTap}) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onTap,
      child: Container(
        width: 40.0,
        height: 40.0,
        decoration:
            BoxDecoration(color: theme.secondary, shape: BoxShape.circle),
        child: Icon(icon, color: theme.tertiary, size: 18.0),
      ),
    );
  }

  Widget _socialButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 24.0,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onTap,
      child: FaIcon(icon, color: theme.secondary, size: size),
    );
  }
}

enum _UsernameAvailability { idle, checking, available, taken, error }
