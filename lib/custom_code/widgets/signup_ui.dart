import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';

/// Shared building blocks for the black "profile creation" sign-up screens
/// (gender, goals, workout preferences, …) so they stay pixel-consistent.

/// A full-width selectable pill: white when unselected, green when selected.
Widget signupOptionTile({
  required BuildContext context,
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  final theme = FlutterFlowTheme.of(context);
  return Padding(
    padding: const EdgeInsets.only(bottom: 14.0),
    child: InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(16.0),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 62.0,
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsetsDirectional.only(start: 22.0, end: 16.0),
        decoration: BoxDecoration(
          color: selected ? theme.primary : Colors.white,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Text(
          label,
          style: theme.bodyMedium.override(
            fontFamily: 'Poppins',
            color: selected ? theme.secondary : theme.secondaryText,
            fontSize: 16.0,
            letterSpacing: 0.0,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    ),
  );
}

/// A white, rounded, borderless input field used on the weight/height steps.
Widget signupTextField({
  required BuildContext context,
  required TextEditingController controller,
  FocusNode? focusNode,
  required String hint,
  TextInputType keyboardType = TextInputType.text,
  ValueChanged<String>? onChanged,
}) {
  final theme = FlutterFlowTheme.of(context);
  final border = OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.white, width: 1.0),
    borderRadius: BorderRadius.circular(16.0),
  );
  return TextFormField(
    controller: controller,
    focusNode: focusNode,
    keyboardType: keyboardType,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: theme.bodyMedium.override(
        fontFamily: 'Poppins',
        color: theme.secondaryText,
        fontSize: 16.0,
        letterSpacing: 0.0,
      ),
      enabledBorder: border,
      focusedBorder: border,
      errorBorder: border,
      focusedErrorBorder: border,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsetsDirectional.fromSTEB(22.0, 20.0, 16.0, 20.0),
    ),
    style: theme.bodyMedium.override(
      fontFamily: 'Poppins',
      color: theme.secondary,
      fontSize: 16.0,
      letterSpacing: 0.0,
    ),
    cursorColor: theme.primary,
  );
}

/// The 6-step progress dots at the bottom of the profile-creation flow.
Widget signupPageDots({
  required BuildContext context,
  required int active,
  int count = 6,
}) {
  final theme = FlutterFlowTheme.of(context);
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(count, (i) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 3.0),
        width: 7.0,
        height: 7.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: i == active ? theme.primary : theme.accent1,
        ),
      );
    }),
  );
}

/// The green (or greyed, when [enabled] is false) full-width primary button
/// used at the bottom of every profile-creation step.
Widget signupPrimaryButton({
  required BuildContext context,
  required String text,
  required VoidCallback onPressed,
  bool enabled = true,
}) {
  final theme = FlutterFlowTheme.of(context);
  return SizedBox(
    width: double.infinity,
    height: 56.0,
    child: Material(
      color: enabled ? theme.primary : theme.accent3,
      borderRadius: BorderRadius.circular(28.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(28.0),
        onTap: onPressed,
        child: Center(
          child: Text(
            text,
            style: theme.titleSmall.override(
              fontFamily: 'Poppins',
              color: theme.secondary,
              fontSize: 17.0,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );
}
