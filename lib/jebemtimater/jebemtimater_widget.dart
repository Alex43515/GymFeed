import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/gemini/gemini.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'jebemtimater_model.dart';
export 'jebemtimater_model.dart';

class JebemtimaterWidget extends StatefulWidget {
  const JebemtimaterWidget({super.key});

  static String routeName = 'jebemtimater';
  static String routePath = 'jebemtimater';

  @override
  State<JebemtimaterWidget> createState() => _JebemtimaterWidgetState();
}

class _JebemtimaterWidgetState extends State<JebemtimaterWidget> {
  late JebemtimaterModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => JebemtimaterModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          title: InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () async {
              context.pushNamed(FeedWidget.routeName);
            },
            child: Text(
              FFLocalizations.of(context).getText(
                'kg2je3uz' /* Page Title */,
              ),
              style: FlutterFlowTheme.of(context).headlineMedium.override(
                    fontFamily: 'Poppins',
                    color: Colors.black,
                    fontSize: 22.0,
                    letterSpacing: 0.0,
                  ),
            ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  valueOrDefault<String>(
                    _model.geminiOutput2,
                    '0',
                  ),
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Poppins',
                        letterSpacing: 0.0,
                      ),
                ),
                FFButtonWidget(
                  onPressed: () async {
                    await geminiGenerateText(
                      context,
                      '\"Please provide a comprehensive fitness and nutrition plan in the exact format below. Ensure the following: The entire response must be formatted as a single line string with no line breaks or new rows. Separate sections using periods or semicolons for clarity. Include valid YouTube links for every exercise—no placeholders or invalid links. Links must be clickable and directly related to the exercises suggested. The meal plan should include a variety of dishes for each meal, with approximate calories and a brief explanation of how to prepare them.  Format: Calories Burn: [Explain how many calories the user should aim to burn daily and how to achieve this goal; specify how many calories will be burned based on the workout plan below.] Calories Intake: [Recommend daily caloric intake for the user’s goal and provide a brief rationale.] Meal Plan (3-Month Sample – Include Approx. Calories per Meal): Week 1-4 (Breakfast, Lunch, Dinner): [Provide a variety of dishes for each meal with approximate calories and preparation instructions.] Week 5-8 (Breakfast, Lunch, Dinner): [Provide a variety of dishes for each meal with approximate calories and preparation instructions.] Week 9-12 (Breakfast, Lunch, Dinner): [Provide a variety of dishes for each meal with approximate calories and preparation instructions.] Workout Plan (3-Month Sample): Month 1: [Provide a weekly structure for Month 1; for each day (Monday to Sunday), include detailed exercises, how many calories will be burned, and valid YouTube links for each exercise.] Month 2: [Adjust or progress from Month 1; for each day (Monday to Sunday), include detailed exercises, how many calories will be burned, and valid YouTube links for each exercise.] Month 3: [Further adjustments or progressions; for each day (Monday to Sunday), include detailed exercises, how many calories will be burned, and valid YouTube links for each exercise.] Pro Tips: [Add any additional advice: hydration, sleep, stress management, supplements, etc.] Motivational Quotes: [List at least three short motivational quotes.] and put the word END after the last quote.   Additional Requirements: All sections and their contents must be concatenated into a single line string with clear delimiters (periods or semicolons). Valid YouTube links are mandatory for exercises. Ensure concise but complete information for meal preparation and calorie burning strategies.\"User Info: Image URL:  , Age:${currentUserDocument?.age2?.toString()} , Height: ${valueOrDefault(currentUserDocument?.height, 0).toString()} ,weight: ${valueOrDefault(currentUserDocument?.weight, 0).toString()} ,goal: ${valueOrDefault(currentUserDocument?.goals, '')} ,level of phisical readiness: ${valueOrDefault(currentUserDocument?.workoutLevel, '')} ,Gender: ${valueOrDefault<bool>(currentUserDocument?.gender, false).toString()}Estimate the following nutritional values based on the user\'s information and meal plan, give me just a single number dont give me a range from to: Answer only in this manner with your best guess, don\'t answer anything else, just give me a structured answer like this: Total Calories Intake: , Proteins Per Day: , Fats Per Day: , Carbs Per Day: .At the end of Motivational quotes put the word END',
                    ).then((generatedText) {
                      safeSetState(() => _model.geminiOutput2 = generatedText);
                    });

                    await currentUserReference!.update(createUsersRecordData(
                      geminiParse2: _model.geminiOutput2,
                    ));
                    _model.caloriesBurn = await actions.caloriesBurn(
                      valueOrDefault(currentUserDocument?.geminiParse2, ''),
                    );
                    _model.caloriesIntake = await actions.caloriesIntake(
                      valueOrDefault(currentUserDocument?.geminiParse2, ''),
                    );
                    _model.workoutPlan = await actions.workoutPlan(
                      valueOrDefault(currentUserDocument?.geminiParse2, ''),
                    );
                    _model.carbsPerDay = await actions.carbsPerDay(
                      valueOrDefault(currentUserDocument?.geminiParse2, ''),
                    );
                    _model.proteinPerDay = await actions.proteinsPerDay(
                      valueOrDefault(currentUserDocument?.geminiParse2, ''),
                    );
                    _model.fatsPerDay = await actions.fatsPerDay(
                      valueOrDefault(currentUserDocument?.geminiParse2, ''),
                    );
                    _model.caloricIntakePerDay =
                        await actions.caloriesIntakeNumber(
                      valueOrDefault(currentUserDocument?.geminiParse2, ''),
                    );
                    _model.proTips = await actions.proTips(
                      valueOrDefault(currentUserDocument?.geminiParse2, ''),
                    );
                    _model.quotes = await actions.quotes(
                      valueOrDefault(currentUserDocument?.geminiParse2, ''),
                    );

                    await currentUserReference!.update(createUsersRecordData(
                      caloriesBurn: _model.caloriesBurn,
                      caloriesIntake: _model.caloriesIntake,
                      workoutPlan: _model.workoutPlan,
                      caloricIntakePerDay: _model.caloricIntakePerDay,
                      fatsPerDay: _model.fatsPerDay,
                      proteinPerDay: _model.proteinPerDay,
                      carbsPerDay: _model.carbsPerDay,
                      proTips: _model.proTips,
                      quotes: _model.quotes,
                    ));

                    safeSetState(() {});
                  },
                  text: FFLocalizations.of(context).getText(
                    'ixguanaz' /* Button */,
                  ),
                  options: FFButtonOptions(
                    height: 40.0,
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                    iconPadding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                    color: FlutterFlowTheme.of(context).primary,
                    textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          letterSpacing: 0.0,
                        ),
                    elevation: 0.0,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                AuthUserStreamWidget(
                  builder: (context) => Text(
                    valueOrDefault(currentUserDocument?.workoutPlan, ''),
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Poppins',
                          letterSpacing: 0.0,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
