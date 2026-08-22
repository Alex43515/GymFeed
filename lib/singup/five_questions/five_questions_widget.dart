import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/signup_ui.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'five_questions_model.dart';
export 'five_questions_model.dart';

class FiveQuestionsWidget extends StatefulWidget {
  const FiveQuestionsWidget({super.key});

  static String routeName = 'FiveQuestions';
  static String routePath = 'fiveQuestions';

  @override
  State<FiveQuestionsWidget> createState() => _FiveQuestionsWidgetState();
}

class _FiveQuestionsWidgetState extends State<FiveQuestionsWidget> {
  late FiveQuestionsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FiveQuestionsModel());

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

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.secondary,
      body: SafeArea(
        top: true,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(28.0, 40.0, 28.0, 28.0),
          child: Column(
            children: [
              const SizedBox(height: 40.0),
              Text(
                'Almost done!',
                textAlign: TextAlign.center,
                style: theme.displaySmall.override(
                  fontFamily: 'Poppins',
                  color: theme.tertiary,
                  fontSize: 32.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Last step!',
                textAlign: TextAlign.center,
                style: theme.displaySmall.override(
                  fontFamily: 'Poppins',
                  color: theme.tertiary,
                  fontSize: 32.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: 180.0,
                    height: 180.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.primary, width: 7.0),
                    ),
                    child: Icon(Icons.check_rounded,
                        color: theme.primary, size: 96.0),
                  ),
                ),
              ),
              signupPrimaryButton(
                context: context,
                text: 'Continue',
                onPressed: () async {
                  context.pushNamed(GoalsWidget.routeName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
