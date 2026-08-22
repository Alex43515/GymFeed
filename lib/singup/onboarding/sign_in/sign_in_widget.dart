import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'sign_in_model.dart';
export 'sign_in_model.dart';

class SignInWidget extends StatefulWidget {
  const SignInWidget({super.key});

  static String routeName = 'SignIn';
  static String routePath = 'signIn';

  @override
  State<SignInWidget> createState() => _SignInWidgetState();
}

class _SignInWidgetState extends State<SignInWidget> {
  late SignInModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SignInModel());

    _model.emailAddressTextController ??= TextEditingController();
    _model.emailAddressFocusNode ??= FocusNode();

    _model.passwordTextController ??= TextEditingController();
    _model.passwordFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  // Clears the error styling as soon as the user starts correcting their input.
  void _clearError() {
    if (_model.loginError) {
      safeSetState(() => _model.loginError = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final bool hasError = _model.loginError;

    // Dark, borderless, rounded field matching the mockup.
    InputDecoration fieldDecoration(String hint, {Widget? suffixIcon}) {
      final border = OutlineInputBorder(
        borderSide: BorderSide(color: theme.secondary, width: 1.0),
        borderRadius: BorderRadius.circular(16.0),
      );
      final errorLine = OutlineInputBorder(
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
          fontWeight: FontWeight.normal,
        ),
        enabledBorder: hasError ? errorLine : border,
        focusedBorder: hasError ? errorLine : border,
        errorBorder: errorLine,
        focusedErrorBorder: errorLine,
        filled: true,
        fillColor: theme.secondary,
        contentPadding:
            const EdgeInsetsDirectional.fromSTEB(22.0, 20.0, 16.0, 20.0),
        suffixIcon: suffixIcon,
      );
    }

    final fieldTextStyle = theme.bodyMedium.override(
      fontFamily: 'Poppins',
      color: hasError ? theme.error : theme.tertiary,
      fontSize: 15.0,
      letterSpacing: 0.0,
      fontWeight: FontWeight.normal,
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
              // ── Top bar: back (left) + close (right) ───────────────────────
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
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8.0),
                      Text(
                        'Welcome back',
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
                        'Log In with your details to continue',
                        style: theme.bodyMedium.override(
                          fontFamily: 'Poppins',
                          color: theme.secondaryText,
                          fontSize: 15.0,
                          letterSpacing: 0.0,
                        ),
                      ),
                      // Error line (states 04 / 05).
                      if (hasError)
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              0.0, 10.0, 0.0, 0.0),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  color: theme.error, size: 18.0),
                              const SizedBox(width: 6.0),
                              Text(
                                'Wrong credentials! Please try again.',
                                style: theme.bodyMedium.override(
                                  fontFamily: 'Poppins',
                                  color: theme.error,
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 26.0),
                      Form(
                        key: _model.formKey,
                        autovalidateMode: AutovalidateMode.disabled,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _model.emailAddressTextController,
                              focusNode: _model.emailAddressFocusNode,
                              onChanged: (_) => _clearError(),
                              autofocus: false,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                              obscureText: false,
                              decoration: fieldDecoration('Email'),
                              style: fieldTextStyle,
                              keyboardType: TextInputType.emailAddress,
                              cursorColor: theme.primary,
                              validator: _model
                                  .emailAddressTextControllerValidator
                                  .asValidator(context),
                            ),
                            const SizedBox(height: 14.0),
                            TextFormField(
                              controller: _model.passwordTextController,
                              focusNode: _model.passwordFocusNode,
                              onChanged: (_) => _clearError(),
                              autofocus: false,
                              autofillHints: const [AutofillHints.password],
                              textInputAction: TextInputAction.done,
                              obscureText: !_model.passwordVisibility,
                              decoration: fieldDecoration(
                                'Password',
                                suffixIcon: InkWell(
                                  onTap: () => safeSetState(() =>
                                      _model.passwordVisibility =
                                          !_model.passwordVisibility),
                                  focusNode: FocusNode(skipTraversal: true),
                                  child: Icon(
                                    _model.passwordVisibility
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: hasError
                                        ? theme.error
                                        : theme.secondaryText,
                                    size: 20.0,
                                  ),
                                ),
                              ),
                              style: fieldTextStyle,
                              cursorColor: theme.primary,
                              validator: _model.passwordTextControllerValidator
                                  .asValidator(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14.0),
                      // Remember (left) + Forgot your password? (right)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () => safeSetState(() =>
                                _model.rememberValue = !_model.rememberValue),
                            child: Row(
                              children: [
                                Icon(
                                  _model.rememberValue
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: _model.rememberValue
                                      ? theme.secondary
                                      : theme.secondaryText,
                                  size: 20.0,
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  'Remember',
                                  style: theme.bodyMedium.override(
                                    fontFamily: 'Poppins',
                                    color: theme.secondaryText,
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () => context
                                .pushNamed(ForgotPasswordWidget.routeName),
                            child: Text(
                              'Forgot your password?',
                              style: theme.bodyMedium.override(
                                fontFamily: 'Poppins',
                                color: theme.secondary,
                                fontSize: 14.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60.0),
                      // Log in button — green normally, grey in the error state.
                      FFButtonWidget(
                        onPressed: () async {
                          if (_model.formKey.currentState == null ||
                              !_model.formKey.currentState!.validate()) {
                            return;
                          }
                          GoRouter.of(context).prepareAuthEvent();

                          final user = await authManager.signInWithEmail(
                            context,
                            _model.emailAddressTextController.text,
                            _model.passwordTextController.text,
                          );
                          if (user == null) {
                            if (authManager.lastFailure ==
                                SupabaseAuthFailureKind.emailNotConfirmed) {
                              if (!context.mounted) return;
                              context
                                  .goNamed(EmailVerificationWidget.routeName);
                              return;
                            }
                            safeSetState(() => _model.loginError = true);
                            return;
                          }

                          if (!context.mounted) return;
                          context.goAfterAuth(FeedWidget.routeName);
                        },
                        text: 'Log in',
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
                            color: Colors.transparent,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(28.0),
                        ),
                      ),
                      const SizedBox(height: 22.0),
                      // Social sign-in divider
                      Row(
                        children: [
                          Expanded(
                            child: Container(height: 1.0, color: theme.accent4),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Or continue with',
                              style: theme.bodySmall.override(
                                fontFamily: 'Poppins',
                                color: theme.secondaryText,
                                fontSize: 13.0,
                                letterSpacing: 0.0,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(height: 1.0, color: theme.accent4),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _socialButton(
                            icon: FontAwesomeIcons.google,
                            onTap: () => authManager.signInWithGoogle(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),
                    ],
                  ),
                ),
              ),
              // ── Footer pinned at the bottom ───────────────────────────────
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(24.0, 8.0, 24.0, 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
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
                      onTap: () => context.pushNamed(SignUpWidget.routeName),
                      child: Text(
                        'Sign up',
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
        decoration: BoxDecoration(
          color: theme.secondary,
          shape: BoxShape.circle,
        ),
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
