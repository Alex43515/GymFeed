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
                    padding:
                        EdgeInsetsDirectional.fromSTEB(10.0, 10.0, 10.0, 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GymFeed Privacy Policy',
                          style: FlutterFlowTheme.of(context).titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Read how GymFeed handles your information, connected '
                          'health data, data retention, and account deletion.',
                          style: FlutterFlowTheme.of(context).bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => launchURL('https://gymfeed.io/privacy/'),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Read Privacy Policy'),
                        ),
                        TextButton.icon(
                          onPressed: () => launchURL(
                            'mailto:official@gymfeed.io?subject=GymFeed%20account%20deletion%20request',
                          ),
                          icon: const Icon(Icons.mail_outline),
                          label: const Text('Request data deletion'),
                        ),
                      ],
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
