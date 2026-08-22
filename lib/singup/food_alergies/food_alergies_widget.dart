import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/signup_ui.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'food_alergies_model.dart';
export 'food_alergies_model.dart';

class FoodAlergiesWidget extends StatefulWidget {
  const FoodAlergiesWidget({super.key});

  static String routeName = 'foodAlergies';
  static String routePath = 'foodAlergies';

  @override
  State<FoodAlergiesWidget> createState() => _FoodAlergiesWidgetState();
}

class _FoodAlergiesWidgetState extends State<FoodAlergiesWidget> {
  late FoodAlergiesModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FoodAlergiesModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

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

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.secondary,
        body: SafeArea(
          top: true,
          child: Padding(
            padding:
                const EdgeInsetsDirectional.fromSTEB(28.0, 24.0, 28.0, 28.0),
            child: Column(
              children: [
                const SizedBox(height: 40.0),
                Text(
                  'Any Food\nAllergies?',
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
                signupTextField(
                  context: context,
                  controller: _model.textController!,
                  focusNode: _model.textFieldFocusNode,
                  hint: 'Food allergies (or type "none")',
                  keyboardType: TextInputType.text,
                  onChanged: (_) => safeSetState(() {}),
                ),
                const Spacer(),
                signupPageDots(context: context, active: 2, count: 6),
                const SizedBox(height: 24.0),
                // Allergies are optional — the user can proceed either way.
                signupPrimaryButton(
                  context: context,
                  text: 'Next',
                  onPressed: () async {
                    FFAppState().foodAlergies =
                        _model.textController.text.trim();
                    FFAppState().update(() {});
                    context.pushNamed(WorkoutDaysWidget.routeName);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
