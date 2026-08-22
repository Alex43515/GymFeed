import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/signup_ui.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'work_out_level_model.dart';
export 'work_out_level_model.dart';

class WorkOutLevelWidget extends StatefulWidget {
  const WorkOutLevelWidget({super.key});

  static String routeName = 'WorkOutLevel';
  static String routePath = 'workOutLevel';

  @override
  State<WorkOutLevelWidget> createState() => _WorkOutLevelWidgetState();
}

class _WorkOutLevelWidgetState extends State<WorkOutLevelWidget> {
  late WorkOutLevelModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WorkOutLevelModel());

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
    final options = ['Beginner', 'Intermediate', 'Advanced', 'Professional'];

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
                'What is Your\nworkout level?',
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
              ...options.map((o) => signupOptionTile(
                    context: context,
                    label: o,
                    selected: _model.selected == o,
                    onTap: () => safeSetState(() => _model.selected = o),
                  )),
              const Spacer(),
              signupPageDots(context: context, active: 5),
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
                          'Please select your workout level.',
                          style: TextStyle(color: theme.secondary),
                        ),
                        backgroundColor: theme.primary,
                        duration: const Duration(milliseconds: 3000),
                      ),
                    );
                    return;
                  }
                  FFAppState().workoutLevel = _model.selected;
                  FFAppState().update(() {});
                  context.pushNamed(FiveQuestionsWidget.routeName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
