import 'package:flutter/material.dart';

import '/auth/supabase_auth/password_recovery_service.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/singup/onboarding/sign_in/sign_in_widget.dart';
import 'change_password_model.dart';

export 'change_password_model.dart';

typedef PasswordUpdateAction = Future<void> Function(String password);

class ChangePasswordWidget extends StatefulWidget {
  const ChangePasswordWidget({
    super.key,
    this.updateAction,
    this.completionOpener,
    this.sessionChecker,
  });

  static String routeName = 'changePassword';
  static String routePath = 'changePassword';

  final PasswordUpdateAction? updateAction;
  final VoidCallback? completionOpener;
  final bool Function()? sessionChecker;

  @override
  State<ChangePasswordWidget> createState() => _ChangePasswordWidgetState();
}

class _ChangePasswordWidgetState extends State<ChangePasswordWidget> {
  late ChangePasswordModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hidePassword = true;
  bool _hideConfirmation = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ChangePasswordModel());
    _model.passwordTextController ??= TextEditingController();
    _model.passwordFocusNode ??= FocusNode();
    _model.confirmationTextController ??= TextEditingController();
    _model.confirmationFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _message(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: error ? const Color(0xFF8E2635) : null,
      ));
  }

  Future<void> _save() async {
    if (_saving) return;
    final password = _model.passwordTextController!.text;
    final confirmation = _model.confirmationTextController!.text;
    final validation = passwordValidationError(password, confirmation);
    if (validation != null) {
      _message(validation, error: true);
      return;
    }

    final hasSession =
        widget.sessionChecker?.call() ?? supabase.auth.currentSession != null;
    if (!hasSession) {
      _message(
        'This recovery link is invalid or expired. Request a new link and try again.',
        error: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final action = widget.updateAction;
      if (action != null) {
        await action(password);
      } else {
        await supabase.auth.updateUser(UserAttributes(password: password));
      }
      if (!mounted) return;
      _message('Password updated. Sign in with your new password.');
      if (widget.completionOpener != null) {
        widget.completionOpener!();
      } else {
        await supabase.auth.signOut();
        if (mounted) context.goNamed(SignInWidget.routeName);
      }
    } on AuthException catch (error) {
      _message(error.message, error: true);
    } catch (error) {
      _message('Password could not be updated. Please try again.', error: true);
      debugPrint('Password update failed: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => context.safePop(),
          icon: Icon(Icons.chevron_left, color: theme.secondaryText, size: 30),
        ),
        title: Text(
          'Create new password',
          style: theme.headlineSmall.override(
            fontFamily: 'Poppins',
            color: theme.secondaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          children: [
            Text(
              'Choose a secure password for your GymFeed account.',
              textAlign: TextAlign.center,
              style: theme.bodyMedium.override(
                fontFamily: 'Poppins',
                color: theme.secondaryText,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 28),
            _PasswordField(
              key: const ValueKey('new-password'),
              controller: _model.passwordTextController!,
              focusNode: _model.passwordFocusNode!,
              label: 'New password',
              hidden: _hidePassword,
              onToggle: () => setState(() => _hidePassword = !_hidePassword),
              onSubmitted: (_) => _model.confirmationFocusNode!.requestFocus(),
            ),
            const SizedBox(height: 14),
            _PasswordField(
              key: const ValueKey('confirm-password'),
              controller: _model.confirmationTextController!,
              focusNode: _model.confirmationFocusNode!,
              label: 'Confirm new password',
              hidden: _hideConfirmation,
              onToggle: () =>
                  setState(() => _hideConfirmation = !_hideConfirmation),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            Text(
              'Use at least 8 characters with a letter and a number.',
              style: theme.bodySmall.override(
                fontFamily: 'Poppins',
                color: theme.secondaryText.withValues(alpha: .65),
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 28),
            FFButtonWidget(
              key: const ValueKey('save-new-password'),
              onPressed: _saving ? null : _save,
              text: _saving ? 'Updating…' : 'Update password',
              options: FFButtonOptions(
                width: double.infinity,
                height: 54,
                color: theme.primary,
                disabledColor: theme.primary.withValues(alpha: .4),
                textStyle: theme.titleSmall.override(
                  fontFamily: 'Poppins',
                  color: const Color(0xFF06120B),
                  fontWeight: FontWeight.w700,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hidden,
    required this.onToggle,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final bool hidden;
  final VoidCallback onToggle;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: hidden,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: label.startsWith('Confirm')
          ? TextInputAction.done
          : TextInputAction.next,
      onFieldSubmitted: onSubmitted,
      style: theme.bodyMedium.override(
        fontFamily: 'Poppins',
        color: theme.secondaryText,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.bodySmall.override(
          fontFamily: 'Poppins',
          color: theme.secondaryText.withValues(alpha: .65),
        ),
        filled: true,
        fillColor: const Color(0xFF141414),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: theme.secondaryText.withValues(alpha: .65),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF303030)),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.primary, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFFF4B63)),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFFF4B63), width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
