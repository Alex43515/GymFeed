import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';

/// Shared building blocks for the "Create" flows (Create post / Create workout /
/// Create food post) so they match the GymFeed Create Flows prototype: dark
/// near-black page, filled `#1C1C1C` cards & fields, green accent (theme.primary),
/// muted `#8A8A8A` labels, chips for taxonomy, and a green pill primary button.

// ── Design tokens ────────────────────────────────────────────────────────────
const Color kCreateSurface = Color(0xFF1C1C1C); // filled field / grouped card
const Color kCreateSurfaceAlt = Color(0xFF242424); // secondary / inactive track
const Color kCreateHint = Color(0xFF8A8A8A); // muted labels & placeholders
const Color kCreateStroke = Color(0xFF2A2A2A); // hairline separators / borders
const Color kCreateOnAccent = Color(0xFF0A0A0A); // text/icon on the green accent
const double kCreateRadius = 16.0; // grouped card radius
const double kCreateFieldRadius = 14.0; // input field radius

/// Small muted label that sits above a group of controls.
Widget createSectionLabel(BuildContext context, String text) => Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4.0, 0.0, 0.0, 10.0),
      child: Text(
        text,
        style: FlutterFlowTheme.of(context).labelMedium.override(
              fontFamily: 'Poppins',
              color: kCreateHint,
              fontSize: 13.0,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w500,
            ),
      ),
    );

/// Rounded dark card that groups related rows.
Widget createCard(BuildContext context, {required Widget child}) => Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kCreateSurface,
        borderRadius: BorderRadius.circular(kCreateRadius),
        border: Border.all(color: kCreateStroke, width: 1.0),
      ),
      child: child,
    );

/// Hairline separator between rows inside a [createCard].
Widget createInnerDivider() => Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
      child: Container(height: 1.0, color: kCreateStroke),
    );

/// Filled dark input decoration. Apply to existing `TextFormField`s by swapping
/// their `decoration:` — controllers/validators stay untouched.
InputDecoration createInputDecoration(
  BuildContext context, {
  String? hintText,
  String? labelText,
  String? suffixText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  int contentVPad = 14,
}) {
  final theme = FlutterFlowTheme.of(context);
  final hintStyle = theme.bodyMedium.override(
    fontFamily: 'Poppins',
    color: kCreateHint,
    fontSize: 14.0,
    letterSpacing: 0.0,
    fontWeight: FontWeight.normal,
  );
  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(kCreateFieldRadius),
        borderSide: BorderSide(color: c, width: 1.0),
      );
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: kCreateSurface,
    hintText: hintText,
    hintStyle: hintStyle,
    labelText: labelText,
    labelStyle: hintStyle,
    floatingLabelStyle: theme.bodyMedium.override(
      fontFamily: 'Poppins',
      color: theme.primary,
      fontSize: 13.0,
      letterSpacing: 0.0,
    ),
    suffixText: suffixText,
    suffixStyle: hintStyle,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    contentPadding: EdgeInsetsDirectional.fromSTEB(
        16.0, contentVPad.toDouble(), 16.0, contentVPad.toDouble()),
    enabledBorder: border(Colors.transparent),
    focusedBorder: border(theme.primary),
    errorBorder: border(theme.error),
    focusedErrorBorder: border(theme.error),
  );
}

/// Selectable pill chip (category / level / meal type). Green when selected.
Widget createChip(
  BuildContext context, {
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  final theme = FlutterFlowTheme.of(context);
  return InkWell(
    borderRadius: BorderRadius.circular(24.0),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 9.0, 16.0, 9.0),
      decoration: BoxDecoration(
        color: selected ? theme.primary : kCreateSurface,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: selected ? theme.primary : kCreateStroke,
          width: 1.0,
        ),
      ),
      child: Text(
        label,
        style: theme.bodyMedium.override(
          fontFamily: 'Poppins',
          color: selected ? kCreateOnAccent : theme.tertiary,
          fontSize: 13.5,
          letterSpacing: 0.0,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    ),
  );
}

/// Tappable row inside a card: title (+ optional subtitle) → value + chevron.
/// Pass [onClear] to swap the chevron for a red clear (×) affordance.
Widget createChoiceRow(
  BuildContext context, {
  required String label,
  String? value,
  String? subtitle,
  IconData trailingIcon = Icons.arrow_forward_ios_rounded,
  VoidCallback? onTap,
  VoidCallback? onClear,
}) {
  final theme = FlutterFlowTheme.of(context);
  return InkWell(
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 15.0, 16.0, 15.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.bodyMedium.override(
                    fontFamily: 'Poppins',
                    fontSize: 14.5,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(0.0, 3.0, 0.0, 0.0),
                    child: Text(
                      subtitle,
                      style: theme.bodySmall.override(
                        fontFamily: 'Poppins',
                        color: kCreateHint,
                        fontSize: 12.5,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (value != null && value.isNotEmpty)
            Flexible(
              child: Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 0.0),
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall.override(
                    fontFamily: 'Poppins',
                    color: kCreateHint,
                    fontSize: 13.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          if (onClear != null)
            InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: onClear,
              child: Icon(Icons.close_rounded, color: theme.error, size: 18.0),
            )
          else
            Icon(trailingIcon, color: kCreateHint, size: 16.0),
        ],
      ),
    ),
  );
}

/// Row inside a card: title (+ subtitle) → switch.
Widget createToggleRow(
  BuildContext context, {
  required String label,
  String? subtitle,
  required bool value,
  required ValueChanged<bool> onChanged,
}) {
  final theme = FlutterFlowTheme.of(context);
  return Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 8.0, 8.0),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.bodyMedium.override(
                  fontFamily: 'Poppins',
                  fontSize: 14.5,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsetsDirectional.fromSTEB(0.0, 3.0, 0.0, 0.0),
                  child: Text(
                    subtitle,
                    style: theme.bodySmall.override(
                      fontFamily: 'Poppins',
                      color: kCreateHint,
                      fontSize: 12.5,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: theme.primary,
          inactiveTrackColor: kCreateSurfaceAlt,
          inactiveThumbColor: kCreateHint,
        ),
      ],
    ),
  );
}

/// Filled, tappable pseudo-field for pickers (time / date / location). Shows a
/// leading icon, a value (white) or placeholder ([filled] == false → muted), and
/// a trailing chevron.
Widget createTapField(
  BuildContext context, {
  required String text,
  required bool filled,
  IconData? icon,
  IconData trailingIcon = Icons.chevron_right_rounded,
  required VoidCallback onTap,
}) {
  final theme = FlutterFlowTheme.of(context);
  return InkWell(
    borderRadius: BorderRadius.circular(kCreateFieldRadius),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 14.0, 12.0, 14.0),
      decoration: BoxDecoration(
        color: kCreateSurface,
        borderRadius: BorderRadius.circular(kCreateFieldRadius),
        border: Border.all(color: kCreateStroke, width: 1.0),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: theme.primary, size: 18.0),
            const SizedBox(width: 10.0),
          ],
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.bodyMedium.override(
                fontFamily: 'Poppins',
                color: filled ? theme.tertiary : kCreateHint,
                fontSize: 14.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          Icon(trailingIcon, color: kCreateHint, size: 20.0),
        ],
      ),
    ),
  );
}

/// Full-width green pill button — the primary submit action on each create flow.
Widget createPrimaryButton(
  BuildContext context, {
  required String label,
  required VoidCallback? onTap,
  bool loading = false,
}) {
  final theme = FlutterFlowTheme.of(context);
  return InkWell(
    borderRadius: BorderRadius.circular(28.0),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    onTap: loading ? null : onTap,
    child: Container(
      width: double.infinity,
      height: 54.0,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.primary,
        borderRadius: BorderRadius.circular(28.0),
      ),
      child: loading
          ? const SizedBox(
              width: 22.0,
              height: 22.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(kCreateOnAccent),
              ),
            )
          : Text(
              label,
              style: theme.titleSmall.override(
                fontFamily: 'Poppins',
                color: kCreateOnAccent,
                fontSize: 16.0,
                letterSpacing: 0.2,
                fontWeight: FontWeight.w600,
              ),
            ),
    ),
  );
}
