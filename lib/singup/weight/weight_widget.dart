import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/signup_ui.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'weight_model.dart';
export 'weight_model.dart';

class WeightWidget extends StatefulWidget {
  const WeightWidget({super.key});

  static String routeName = 'Weight';
  static String routePath = 'weight';

  @override
  State<WeightWidget> createState() => _WeightWidgetState();
}

class _WeightWidgetState extends State<WeightWidget> {
  late WeightModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WeightModel());

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
    final filled = _model.textController.text.trim().isNotEmpty;

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
                  'What is\nYour Weight?',
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
                  hint: 'Weight (kg)',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => safeSetState(() {}),
                ),
                const Spacer(),
                signupPageDots(context: context, active: 3),
                const SizedBox(height: 24.0),
                signupPrimaryButton(
                  context: context,
                  text: 'Next',
                  enabled: filled,
                  onPressed: () async {
                    final value =
                        int.tryParse(_model.textController.text.trim());
                    if (value == null || value <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please enter a valid weight in kg.',
                            style: TextStyle(color: theme.secondary),
                          ),
                          backgroundColor: theme.primary,
                          duration: const Duration(milliseconds: 3000),
                        ),
                      );
                      return;
                    }
                    FFAppState().weight = value;
                    FFAppState().update(() {});
                    context.pushNamed(HeightWidget.routeName);
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
