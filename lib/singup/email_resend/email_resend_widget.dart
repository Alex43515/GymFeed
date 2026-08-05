import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'email_resend_model.dart';
export 'email_resend_model.dart';

class EmailResendWidget extends StatefulWidget {
  const EmailResendWidget({super.key});

  @override
  State<EmailResendWidget> createState() => _EmailResendWidgetState();
}

class _EmailResendWidgetState extends State<EmailResendWidget> {
  late EmailResendModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EmailResendModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).tertiary,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(16.0, 24.0, 16.0, 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () async {
                    Navigator.pop(context);
                  },
                  child: Icon(
                    Icons.close,
                    color: FlutterFlowTheme.of(context).error,
                    size: 15.0,
                  ),
                ),
              ],
            ),
            Text(
              FFLocalizations.of(context).getText(
                'up0qun3t' /* Email Verification */,
              ),
              style: FlutterFlowTheme.of(context).titleLarge.override(
                    fontFamily: 'Poppins',
                    color: Color(0xFF0FF76D),
                    fontSize: functions
                        .resizeFontBasedOnScreenSize(
                            MediaQuery.sizeOf(context).width, 22)
                        .toDouble(),
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
              child: Text(
                FFLocalizations.of(context).getText(
                  '0o7gjxcj' /* An email has been sent to your... */,
                ),
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Poppins',
                      color: FlutterFlowTheme.of(context).secondaryText,
                      fontSize: functions
                          .resizeFontBasedOnScreenSize(
                              MediaQuery.sizeOf(context).width, 13)
                          .toDouble(),
                      letterSpacing: 0.0,
                    ),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
              child: FFButtonWidget(
                onPressed: () async {
                  await authManager.sendEmailVerification();
                },
                text: FFLocalizations.of(context).getText(
                  '0yuctbwh' /* Resend Verification Email */,
                ),
                options: FFButtonOptions(
                  width: 200.0,
                  height: 40.0,
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                  iconPadding:
                      EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                  color: Color(0xFF0FF76D),
                  textStyle: FlutterFlowTheme.of(context).labelLarge.override(
                        fontFamily: 'Poppins',
                        fontSize: functions
                            .resizeFontBasedOnScreenSize(
                                MediaQuery.sizeOf(context).width, 14)
                            .toDouble(),
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w500,
                      ),
                  elevation: 0.0,
                ),
              ),
            ),
          ].divide(SizedBox(height: 20.0)),
        ),
      ),
    );
  }
}
