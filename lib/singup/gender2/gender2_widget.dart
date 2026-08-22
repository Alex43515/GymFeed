import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/signup_ui.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'gender2_model.dart';
export 'gender2_model.dart';

class Gender2Widget extends StatefulWidget {
  const Gender2Widget({super.key});

  static String routeName = 'Gender2';
  static String routePath = 'gender2';

  @override
  State<Gender2Widget> createState() => _Gender2WidgetState();
}

class _Gender2WidgetState extends State<Gender2Widget> {
  late Gender2Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Gender2Model());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final options = ['Male', 'Female', 'Other'];

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.secondary,
      body: SafeArea(
        top: true,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(28.0, 24.0, 28.0, 28.0),
          child: Column(
            children: [
              const SizedBox(height: 40.0),
              Text(
                'Tell us more\nAbout Yourself',
                textAlign: TextAlign.center,
                style: theme.displaySmall.override(
                  fontFamily: 'Poppins',
                  color: theme.tertiary,
                  fontSize: 30.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w700,
                  lineHeight: 1.15,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Complete your details to proceed',
                textAlign: TextAlign.center,
                style: theme.bodyMedium.override(
                  fontFamily: 'Poppins',
                  color: theme.secondaryText,
                  fontSize: 16.0,
                  letterSpacing: 0.0,
                ),
              ),
              const SizedBox(height: 32.0),
              ...options.map((o) => signupOptionTile(
                    context: context,
                    label: o,
                    selected: _model.selected == o,
                    onTap: () => safeSetState(() => _model.selected = o),
                  )),
              const Spacer(),
              signupPageDots(context: context, active: 1),
              const SizedBox(height: 24.0),
              signupPrimaryButton(
                context: context,
                text: 'Next',
                enabled: _model.selected.isNotEmpty,
                onPressed: () async {
                  if (_model.selected.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please select a gender so we can build your custom plan.',
                          style: TextStyle(color: theme.secondary),
                        ),
                        backgroundColor: theme.primary,
                        duration: const Duration(milliseconds: 3000),
                      ),
                    );
                    return;
                  }
                  FFAppState().gender2 = _model.selected;
                  FFAppState().update(() {});
                  context.pushNamed(HowOldAreYouWidget.routeName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
