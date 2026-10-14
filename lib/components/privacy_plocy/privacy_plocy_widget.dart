import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'privacy_plocy_model.dart';
export 'privacy_plocy_model.dart';

class PrivacyPlocyWidget extends StatefulWidget {
  const PrivacyPlocyWidget({super.key});

  @override
  State<PrivacyPlocyWidget> createState() => _PrivacyPlocyWidgetState();
}

class _PrivacyPlocyWidgetState extends State<PrivacyPlocyWidget> {
  late PrivacyPlocyModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PrivacyPlocyModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(10.0, 10.0, 10.0, 10.0),
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.9,
        height: MediaQuery.sizeOf(context).height * 0.9,
        decoration: BoxDecoration(
          color: Color(0xFF0A0A0A),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 0.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        context.safePop();
                      },
                      child: Icon(
                        Icons.horizontal_rule,
                        color: FlutterFlowTheme.of(context).tertiary,
                        size: 40.0,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Connected health\n\nIf you connect Apple Health or Android Health Connect, GymFeed reads steps, active calories and heart rate to show your daily activity. Access is optional and read-only. Readings stay on this phone unless you separately enable AI sharing in Connected health. With that explicit consent, today’s summary and measurement times are sent securely through GymFeed’s Supabase service to OpenAI or Google Gemini when you ask AI Coach a question. Provider retention policies apply. The raw summary is not stored in a GymFeed health database. Private questions, answers and plans may contain these numbers and are saved in Coach history or plans; health-assisted turns are excluded from rolling AI memory. Turning sharing off stops future sharing but does not delete existing history or plans. Health data is not sold, used for advertising or shared on your public profile. Only connection and AI-sharing preferences are saved locally. Disconnect turns both off; system permissions can be revoked in your health app.',
                      style: FlutterFlowTheme.of(context).bodyMedium,
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(10.0, 10.0, 10.0, 10.0),
                    child: Text(
                      FFLocalizations.of(context)
                          .getText(
                            'dev5w4fg' /* GymFeed Privacy Policy

Introd... */
                            ,
                          )
                          .replaceAll(
                            'aleksandar.zivkovc@gmail.com',
                            'official@gymfeed.io',
                          ),
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Poppins',
                            fontSize: 15.0,
                            letterSpacing: 0.0,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
