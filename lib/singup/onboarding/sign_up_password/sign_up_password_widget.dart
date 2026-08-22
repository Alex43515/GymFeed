import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/auth/supabase_auth/email_verification_service.dart';
import '/auth/supabase_auth/social_auth_service.dart';
import '/backend/supabase/repositories/profile_repository.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'sign_up_password_model.dart';
export 'sign_up_password_model.dart';

class SignUpPasswordWidget extends StatefulWidget {
  const SignUpPasswordWidget({super.key});

  static String routeName = 'SignUp_Password';
  static String routePath = 'signUpPassword';

  @override
  State<SignUpPasswordWidget> createState() => _SignUpPasswordWidgetState();
}

class _SignUpPasswordWidgetState extends State<SignUpPasswordWidget> {
  late SignUpPasswordModel _model;
  bool _creatingAccount = false;
  String? _signupError;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SignUpPasswordModel());

    _model.passwordTextController ??= TextEditingController();
    _model.passwordFocusNode ??= FocusNode();

    _model.confirmPasswordTextController ??= TextEditingController();
    _model.confirmPasswordFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  void _clearError() {
    if (_model.passwordError || _signupError != null) {
      safeSetState(() {
        _model.passwordError = false;
        _signupError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final bool hasError = _model.passwordError || _signupError != null;

    InputDecoration fieldDecoration(String hint, {required Widget suffixIcon}) {
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
        enabledBorder: hasError ? errored : normal,
        focusedBorder: hasError ? errored : normal,
        errorBorder: errored,
        focusedErrorBorder: errored,
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
    );

    Widget eye(bool visible, VoidCallback onTap) => InkWell(
          onTap: onTap,
          focusNode: FocusNode(skipTraversal: true),
          child: Icon(
            visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: hasError ? theme.error : theme.secondaryText,
            size: 20.0,
          ),
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
                          'Complete your details to continue',
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
                                    _signupError ??
                                        'Passwords do not match. Please try again.',
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
                          controller: _model.passwordTextController,
                          focusNode: _model.passwordFocusNode,
                          onChanged: (_) => _clearError(),
                          obscureText: !_model.passwordVisibility,
                          textInputAction: TextInputAction.next,
                          decoration: fieldDecoration(
                            'Password',
                            suffixIcon: eye(
                              _model.passwordVisibility,
                              () => safeSetState(() =>
                                  _model.passwordVisibility =
                                      !_model.passwordVisibility),
                            ),
                          ),
                          style: fieldTextStyle,
                          cursorColor: theme.primary,
                          validator: _model.passwordTextControllerValidator
                              .asValidator(context),
                        ),
                        const SizedBox(height: 14.0),
                        TextFormField(
                          controller: _model.confirmPasswordTextController,
                          focusNode: _model.confirmPasswordFocusNode,
                          onChanged: (_) => _clearError(),
                          obscureText: !_model.confirmPasswordVisibility,
                          textInputAction: TextInputAction.done,
                          decoration: fieldDecoration(
                            'Confirm password',
                            suffixIcon: eye(
                              _model.confirmPasswordVisibility,
                              () => safeSetState(() =>
                                  _model.confirmPasswordVisibility =
                                      !_model.confirmPasswordVisibility),
                            ),
                          ),
                          style: fieldTextStyle,
                          cursorColor: theme.primary,
                          validator: _model
                              .confirmPasswordTextControllerValidator
                              .asValidator(context),
                        ),
                        const SizedBox(height: 40.0),
                        FFButtonWidget(
                          onPressed: _creatingAccount
                              ? null
                              : () async {
                                  _clearError();
                                  if (_model.formKey.currentState == null ||
                                      !_model.formKey.currentState!
                                          .validate()) {
                                    return;
                                  }
                                  if (_model.passwordTextController.text !=
                                      _model
                                          .confirmPasswordTextController.text) {
                                    safeSetState(
                                        () => _model.passwordError = true);
                                    return;
                                  }

                                  safeSetState(() => _creatingAccount = true);
                                  try {
                                    final username =
                                        FFAppState().signupUsername;
                                    final available = await ProfileRepository()
                                        .isUsernameAvailable(username);
                                    if (!available) {
                                      if (!mounted) return;
                                      safeSetState(() {
                                        _signupError =
                                            'That username was just taken. Go back and choose another one.';
                                      });
                                      return;
                                    }

                                    GoRouter.of(context).prepareAuthEvent();
                                    final user = await authManager
                                        .createAccountWithEmail(
                                      context,
                                      FFAppState().signupEmail,
                                      _model.passwordTextController.text,
                                      data: signupIdentityMetadata(),
                                    );
                                    if (!mounted) return;
                                    if (user == null) {
                                      safeSetState(() {
                                        _signupError =
                                            'We could not create the pending account. Check the email and username, then try again.';
                                      });
                                      return;
                                    }

                                    // Supabase must keep a pending auth identity so it
                                    // can deliver the confirmation email. The database
                                    // does not expose a GymFeed profile until that
                                    // email is verified.
                                    FFAppState().signupPassword = '';
                                    context.goNamed(
                                        EmailVerificationWidget.routeName);
                                  } catch (_) {
                                    if (!mounted) return;
                                    safeSetState(() {
                                      _signupError =
                                          'Signup could not be started. Check your connection and try again.';
                                    });
                                  } finally {
                                    if (mounted) {
                                      safeSetState(
                                          () => _creatingAccount = false);
                                    }
                                  }
                                },
                          text: _creatingAccount
                              ? 'Creating account…'
                              : 'Sign up',
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
                                onTap: () => authManager.signInWithGoogle(
                                      context,
                                      nextPath: socialAuthSignupDestination,
                                    )),
                          ],
                        ),
                        const SizedBox(height: 24.0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(24.0, 8.0, 24.0, 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
