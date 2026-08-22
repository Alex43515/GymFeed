import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/signup_ui.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'goals_model.dart';
export 'goals_model.dart';

class GoalsWidget extends StatefulWidget {
  const GoalsWidget({super.key});

  static String routeName = 'Goals';
  static String routePath = 'goals';

  @override
  State<GoalsWidget> createState() => _GoalsWidgetState();
}

class _GoalsWidgetState extends State<GoalsWidget> {
  late GoalsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => GoalsModel());

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
    final options = [
      'Lose weight',
      'Gain Muscle',
      'Improved Strength',
      'Enhanced Cardiovascular Health',
    ];

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
                'Why did You\njoin GymFeed?',
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
                'Complete your details to proceed further',
                textAlign: TextAlign.center,
                style: theme.bodyMedium.override(
                  fontFamily: 'Poppins',
                  color: theme.secondaryText,
                  fontSize: 16.0,
                  letterSpacing: 0.0,
                ),
              ),
              const SizedBox(height: 32.0),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: options
                        .map((o) => signupOptionTile(
                              context: context,
                              label: o,
                              selected: _model.selected.contains(o),
                              onTap: () => safeSetState(() {
                                if (_model.selected.contains(o)) {
                                  _model.selected.remove(o);
                                } else {
                                  _model.selected.add(o);
                                }
                              }),
                            ))
                        .toList(),
                  ),
                ),
              ),
              signupPageDots(context: context, active: 0, count: 6),
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
                          'Pick at least one goal so we can tailor your plan.',
                          style: TextStyle(color: theme.secondary),
                        ),
                        backgroundColor: theme.primary,
                        duration: const Duration(milliseconds: 3000),
                      ),
                    );
                    return;
                  }
                  FFAppState().goals = _model.selected.join(', ');
                  FFAppState().update(() {});
                  context.pushNamed(MealsWidget.routeName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
