import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'all_done2_model.dart';
export 'all_done2_model.dart';

class AllDone2Widget extends StatefulWidget {
  const AllDone2Widget({super.key});

  static String routeName = 'allDone2';
  static String routePath = 'allDone2';

  @override
  State<AllDone2Widget> createState() => _AllDone2WidgetState();
}

class _AllDone2WidgetState extends State<AllDone2Widget>
    with TickerProviderStateMixin {
  late AllDone2Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AllDone2Model());

    _model.textController ??= TextEditingController(
        text: valueOrDefault<String>(
      functions.generateChatGPT(
          FFAppState().age2!.secondsSinceEpoch,
          FFAppState().height,
          FFAppState().weight,
          valueOrDefault(currentUserDocument?.workouts, ''),
          FFAppState().snacks,
          false,
          FFAppState().goals,
          FFAppState().age2!,
          FFAppState().meals,
          FFAppState().workouts,
          valueOrDefault(currentUserDocument?.workoutLenght, ''),
          FFAppState().workoutPeriod,
          FFAppState().workoutLevel,
          FFAppState().gender2,
          FFAppState().workoutWhere,
          FFAppState().foodAlergies),
      '1',
    ));
    _model.textFieldFocusNode ??= FocusNode();

    animationsMap.addAll({
      'imageOnActionTriggerAnimation': AnimationInfo(
        trigger: AnimationTrigger.onActionTrigger,
        applyInitialState: true,
        effectsBuilder: () => [
          TintEffect(
            curve: Curves.easeInOut,
            delay: 1080.0.ms,
            duration: 1580.0.ms,
            color: FlutterFlowTheme.of(context).primary,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
    });
    setupAnimations(
      animationsMap.values.where((anim) =>
          anim.trigger == AnimationTrigger.onActionTrigger ||
          !anim.applyInitialState),
      this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primary,
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primary,
                ),
                child: Align(
                  alignment: AlignmentDirectional(0.0, -1.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 50.0, 0.0, 0.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: MediaQuery.sizeOf(context).width * 1.0,
                                  decoration: BoxDecoration(),
                                  child: RichText(
                                    textScaler:
                                        MediaQuery.of(context).textScaler,
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: FFLocalizations.of(context)
                                              .getText(
                                            '7ccvamuc' /* Congratulations! */,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'Poppins',
                                                color: Color(0xFF0A0A0A),
                                                fontSize: 30.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        TextSpan(
                                          text: FFLocalizations.of(context)
                                              .getText(
                                            'spdgonnh' /* 
You may proceed with the app,... */
                                            ,
                                          ),
                                          style: TextStyle(
                                            color: Color(0xFF0A0A0A),
                                            fontSize: 15.0,
                                          ),
                                        )
                                      ],
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Poppins',
                                            fontSize: functions
                                                .resizeFontBasedOnScreenSize(
                                                    MediaQuery.sizeOf(context)
                                                        .width,
                                                    13)
                                                .toDouble(),
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            Opacity(
                              opacity: 0.0,
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 80.0, 0.0, 0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 1.0,
                                      height: 1.0,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            8.0, 0.0, 8.0, 0.0),
                                        child: AuthUserStreamWidget(
                                          builder: (context) => TextFormField(
                                            controller: _model.textController,
                                            focusNode:
                                                _model.textFieldFocusNode,
                                            autofocus: false,
                                            obscureText: false,
                                            decoration: InputDecoration(
                                              labelText:
                                                  FFLocalizations.of(context)
                                                      .getText(
                                                'rik83e12' /* Label here... */,
                                              ),
                                              labelStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .override(
                                                        fontFamily: 'Poppins',
                                                        letterSpacing: 0.0,
                                                      ),
                                              hintStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .override(
                                                        fontFamily: 'Poppins',
                                                        letterSpacing: 0.0,
                                                      ),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .alternate,
                                                  width: 2.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primary,
                                                  width: 2.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              errorBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error,
                                                  width: 2.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              focusedErrorBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error,
                                                  width: 2.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  letterSpacing: 0.0,
                                                ),
                                            validator: _model
                                                .textControllerValidator
                                                .asValidator(context),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 50.0, 0.0, 0.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.asset(
                                      'assets/images/Asset_3.png',
                                      width: 300.0,
                                      height: 200.0,
                                      fit: BoxFit.contain,
                                    ),
                                  ).animateOnActionTrigger(
                                    animationsMap[
                                        'imageOnActionTriggerAnimation']!,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 50.0),
                        child: StreamBuilder<List<AdministrativeRecord>>(
                          stream: queryAdministrativeRecord(
                            singleRecord: true,
                          ),
                          builder: (context, snapshot) {
                            // Customize what your widget looks like when it's loading.
                            if (!snapshot.hasData) {
                              return Center(
                                child: SizedBox(
                                  width: 12.0,
                                  height: 12.0,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            }
                            List<AdministrativeRecord>
                                columnAdministrativeRecordList = snapshot.data!;
                            // Return an empty Container when the item does not exist.
                            if (snapshot.data!.isEmpty) {
                              return Container();
                            }
                            final columnAdministrativeRecord =
                                columnAdministrativeRecordList.isNotEmpty
                                    ? columnAdministrativeRecordList.first
                                    : null;

                            return Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Align(
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 0.0, 0.0, 16.0),
                                        child: FFButtonWidget(
                                          onPressed: () async {
                                            GoRouter.of(context)
                                                .prepareAuthEvent();
                                            if (FFAppState().signupPassword !=
                                                FFAppState().signupPassword) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Passwords don\'t match!',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }

                                            final user = await authManager
                                                .createAccountWithEmail(
                                              context,
                                              FFAppState().signupEmail,
                                              FFAppState().signupPassword,
                                            );
                                            if (user == null) {
                                              return;
                                            }

                                            await UsersRecord.collection
                                                .doc(user.uid)
                                                .update({
                                              ...createUsersRecordData(
                                                enableEmail: false,
                                                displayName:
                                                    FFAppState().signupName,
                                                email: FFAppState().signupEmail,
                                                bio: FFAppState().bio,
                                                createdTime:
                                                    getCurrentTimestamp,
                                                username:
                                                    FFAppState().signupUsername,
                                                website: '',
                                                workoutLevel:
                                                    FFAppState().workoutLevel,
                                                days: FFAppState().days,
                                                snacks: FFAppState().snacks,
                                                goals: FFAppState().goals,
                                                workouts: FFAppState().workouts,
                                                age2: FFAppState().age2,
                                                height: FFAppState().height,
                                                weight: FFAppState().weight,
                                                meals: FFAppState().meals,
                                                workoutLenght:
                                                    FFAppState().workoutLenght,
                                                workoutPeriod:
                                                    FFAppState().workoutPeriod,
                                                photoUrl:
                                                    FFAppState().profileImage,
                                                gender2: FFAppState().gender2,
                                              ),
                                              ...mapToFirestore(
                                                {
                                                  'following':
                                                      FFAppState().emptyList,
                                                },
                                              ),
                                            });

                                            await authManager
                                                .sendEmailVerification();

                                            await columnAdministrativeRecord!
                                                .reference
                                                .update({
                                              ...mapToFirestore(
                                                {
                                                  'usernames':
                                                      FieldValue.arrayUnion([
                                                    FFAppState().signupUsername
                                                  ]),
                                                },
                                              ),
                                            });

                                            await FollowersRecord.createDoc(
                                                    currentUserReference!)
                                                .set({
                                              ...mapToFirestore(
                                                {
                                                  'userRefs':
                                                      FFAppState().emptyList,
                                                },
                                              ),
                                            });

                                            await BookmarksRecord.createDoc(
                                                    currentUserReference!)
                                                .set(
                                                    createBookmarksRecordData());
                                            _model.openaiRes =
                                                await OpenAIAPIGPTResponseGroup
                                                    .createChatCompletionCopyCall
                                                    .call(
                                              query: _model.textController.text,
                                            );

                                            if ((_model.openaiRes?.succeeded ??
                                                true)) {
                                              await currentUserReference!
                                                  .update(createUsersRecordData(
                                                gptprompt: OpenAIAPIGPTResponseGroup
                                                    .createChatCompletionCopyCall
                                                    .resText(
                                                  (_model.openaiRes?.jsonBody ??
                                                      ''),
                                                ),
                                              ));

                                              context.pushNamedAuth(
                                                  EmailVerificationWidget
                                                      .routeName,
                                                  context.mounted);
                                            }

                                            safeSetState(() {});
                                          },
                                          text: FFLocalizations.of(context)
                                              .getText(
                                            'eiqzoe24' /* Continue */,
                                          ),
                                          options: FFButtonOptions(
                                            width: MediaQuery.sizeOf(context)
                                                    .width *
                                                0.9,
                                            height: 55.0,
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 0.0, 0.0, 0.0),
                                            iconPadding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 0.0, 0.0, 0.0),
                                            color: Color(0xFF0A0A0A),
                                            textStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .override(
                                                      fontFamily: 'Poppins',
                                                      color: Colors.white,
                                                      fontSize: functions
                                                          .resizeFontBasedOnScreenSize(
                                                              MediaQuery.sizeOf(
                                                                      context)
                                                                  .width,
                                                              20)
                                                          .toDouble(),
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.w300,
                                                    ),
                                            elevation: 3.0,
                                            borderSide: BorderSide(
                                              color: Colors.transparent,
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(20.0),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
