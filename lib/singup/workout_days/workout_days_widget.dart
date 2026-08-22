import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/signup_ui.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'workout_days_model.dart';
export 'workout_days_model.dart';

class WorkoutDaysWidget extends StatefulWidget {
  const WorkoutDaysWidget({super.key});

  static String routeName = 'workoutDays';
  static String routePath = 'workoutDays';

  @override
  State<WorkoutDaysWidget> createState() => _WorkoutDaysWidgetState();
}

class _WorkoutDaysWidgetState extends State<WorkoutDaysWidget> {
  late WorkoutDaysModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WorkoutDaysModel());

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
    final options = ['1', '2-3', '3-4', '5+'];

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
                'Number of\nworkouts per week?',
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
              signupPageDots(context: context, active: 3, count: 6),
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
                          'Please choose how many workouts you do per week.',
                          style: TextStyle(color: theme.secondary),
                        ),
                        backgroundColor: theme.primary,
                        duration: const Duration(milliseconds: 3000),
                      ),
                    );
                    return;
                  }
                  FFAppState().workouts = _model.selected;
                  FFAppState().update(() {});
                  context.pushNamed(WorkoutWhenWidget.routeName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
