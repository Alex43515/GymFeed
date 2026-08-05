import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'assistant_g_p_t_pro_model.dart';
export 'assistant_g_p_t_pro_model.dart';

class AssistantGPTProWidget extends StatefulWidget {
  const AssistantGPTProWidget({super.key});

  static String routeName = 'assistantGPTPro';
  static String routePath = 'assistantGPTPro';

  @override
  State<AssistantGPTProWidget> createState() => _AssistantGPTProWidgetState();
}

class _AssistantGPTProWidgetState extends State<AssistantGPTProWidget>
    with TickerProviderStateMixin {
  late AssistantGPTProModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AssistantGPTProModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.apiThreadsResult = await OpenAIAPIAssistantGroup.threadsCall.call(
        token: FFAppState().apiKey,
      );

      if ((_model.apiThreadsResult?.succeeded ?? true)) {
        _model.threadId = OpenAIAPIAssistantGroup.threadsCall.threadId(
          (_model.apiThreadsResult?.jsonBody ?? ''),
        )!;
        safeSetState(() {});
      }
    });

    _model.questionTestFieldTextController ??= TextEditingController();
    _model.questionTestFieldFocusNode ??= FocusNode();

    _model.alwayspopulatedTextController ??= TextEditingController(
        text:
            'And this is my name always address me by my name,${currentUserDisplayName}.Context infomration about the user that you need to take into account before answering any question he posted related to fitness and meal prepartion.You are a highly renowned health and nutrition expert at FitnessGPT. Take the following information about me into account when answering me back. I am${currentUserDocument?.age2?.toString()}years old. ${valueOrDefault<bool>(currentUserDocument?.gender, false).toString()}, height in cm${valueOrDefault(currentUserDocument?.height, 0).toString()}, weight in kg${valueOrDefault(currentUserDocument?.weight, 0).toString()}My primary fitness and health goals are${valueOrDefault(currentUserDocument?.goals, '')}. I can commit to working out ${valueOrDefault(currentUserDocument?.workouts, '')}per week at this specific time slot${valueOrDefault(currentUserDocument?.workoutPeriod, '')}, and at this lenght ${valueOrDefault(currentUserDocument?.workoutLenght, '')}I want to have ${valueOrDefault(currentUserDocument?.meals, '')}per day. And this is my workout level or condition level ${valueOrDefault(currentUserDocument?.workoutLevel, '')}. And this is the premade personal plan based on the following information.${valueOrDefault(currentUserDocument?.gptprompt, '')}. And this is the personal plan created for me based on my information. ${valueOrDefault(currentUserDocument?.gptprompt, '')}. Take this all into account before answering to my question.');
    _model.alwayspopulatedFocusNode ??= FocusNode();

    animationsMap.addAll({
      'containerOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'containerOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
    });

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
        backgroundColor: FlutterFlowTheme.of(context).secondary,
        body: SafeArea(
          top: true,
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 10.0),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFF0A0A0A),
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: Image.asset(
                    'assets/images/blur_bg@1x.png',
                  ).image,
                ),
              ),
              child: Align(
                alignment: AlignmentDirectional(0.0, 0.0),
                child: Container(
                  width: MediaQuery.sizeOf(context).width * 1.0,
                  height: double.infinity,
                  constraints: BoxConstraints(
                    maxWidth: 770.0,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFF0A0A0A),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 50.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional(0.0, -1.0),
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 12.0, 0.0, 0.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  if (responsiveVisibility(
                                    context: context,
                                    phone: false,
                                    tablet: false,
                                  ))
                                    Container(
                                      width: 100.0,
                                      height: 24.0,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF0A0A0A),
                                      ),
                                    ),
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        24.0, 0.0, 24.0, 12.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Align(
                                          alignment:
                                              AlignmentDirectional(0.0, -1.0),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(0.0),
                                            child: Image.asset(
                                              'assets/images/09.png',
                                              width: 40.0,
                                              height: 40.0,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                'kt5f8d8o' /* Your own personal 24/7 AI
Nutr... */
                                                ,
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .headlineMedium
                                                      .override(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 15.0,
                                                        letterSpacing: 0.0,
                                                      ),
                                            ),
                                            Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                '96d5wm3p' /* Here to help and answer all yo... */,
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Poppins',
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondaryText,
                                                        fontSize: 10.0,
                                                        letterSpacing: 0.0,
                                                      ),
                                            ),
                                          ].divide(SizedBox(height: 4.0)),
                                        ),
                                        InkWell(
                                          splashColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () async {
                                            context.safePop();
                                          },
                                          child: Icon(
                                            Icons.close,
                                            color: FlutterFlowTheme.of(context)
                                                .error,
                                            size: 20.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 12.0, 0.0, 0.0),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 5.0,
                                            sigmaY: 4.0,
                                          ),
                                          child: Container(
                                            width: MediaQuery.sizeOf(context)
                                                    .width *
                                                0.95,
                                            decoration: BoxDecoration(
                                              color: Color(0xFF0A0A0A),
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                              border: Border.all(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondary,
                                                width: 1.0,
                                              ),
                                            ),
                                            child: SingleChildScrollView(
                                              controller:
                                                  _model.scollingChatColumn,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Align(
                                                    alignment:
                                                        AlignmentDirectional(
                                                            0.0, -1.0),
                                                    child: Builder(
                                                      builder: (context) {
                                                        final chat = _model
                                                            .chatHostpry
                                                            .toList();

                                                        return ListView
                                                            .separated(
                                                          padding: EdgeInsets
                                                              .fromLTRB(
                                                            0,
                                                            16.0,
                                                            0,
                                                            16.0,
                                                          ),
                                                          primary: false,
                                                          shrinkWrap: true,
                                                          scrollDirection:
                                                              Axis.vertical,
                                                          itemCount:
                                                              chat.length,
                                                          separatorBuilder: (_,
                                                                  __) =>
                                                              SizedBox(
                                                                  height: 16.0),
                                                          itemBuilder: (context,
                                                              chatIndex) {
                                                            final chatItem =
                                                                chat[chatIndex];
                                                            return Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                if ((int
                                                                    index) {
                                                                  return index %
                                                                          2 !=
                                                                      0;
                                                                }(chatIndex))
                                                                  Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    children: [
                                                                      Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            5.0,
                                                                            0.0),
                                                                        child:
                                                                            Container(
                                                                          width:
                                                                              30.0,
                                                                          height:
                                                                              30.0,
                                                                          clipBehavior:
                                                                              Clip.antiAlias,
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            shape:
                                                                                BoxShape.circle,
                                                                          ),
                                                                          child:
                                                                              Image.asset(
                                                                            'assets/images/011.png',
                                                                            fit:
                                                                                BoxFit.contain,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Container(
                                                                            width:
                                                                                MediaQuery.sizeOf(context).width * 0.8,
                                                                            constraints:
                                                                                BoxConstraints(
                                                                              maxWidth: () {
                                                                                if (MediaQuery.sizeOf(context).width >= 1170.0) {
                                                                                  return 700.0;
                                                                                } else if (MediaQuery.sizeOf(context).width <= 470.0) {
                                                                                  return 330.0;
                                                                                } else {
                                                                                  return 530.0;
                                                                                }
                                                                              }(),
                                                                            ),
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: FlutterFlowTheme.of(context).primary,
                                                                              boxShadow: [
                                                                                BoxShadow(
                                                                                  blurRadius: 3.0,
                                                                                  color: Color(0x33000000),
                                                                                  offset: Offset(
                                                                                    0.0,
                                                                                    1.0,
                                                                                  ),
                                                                                )
                                                                              ],
                                                                              borderRadius: BorderRadius.circular(12.0),
                                                                              border: Border.all(
                                                                                color: FlutterFlowTheme.of(context).primary,
                                                                                width: 1.0,
                                                                              ),
                                                                            ),
                                                                            child:
                                                                                Padding(
                                                                              padding: EdgeInsets.all(12.0),
                                                                              child: Column(
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  SelectionArea(
                                                                                      child: AutoSizeText(
                                                                                    chatItem.text.value,
                                                                                    style: FlutterFlowTheme.of(context).titleMedium.override(
                                                                                          fontFamily: 'Poppins',
                                                                                          color: Color(0xFF0A0A0A),
                                                                                          fontSize: 14.0,
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FontWeight.normal,
                                                                                          lineHeight: 1.5,
                                                                                        ),
                                                                                  )),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ).animateOnPageLoad(
                                                                              animationsMap['containerOnPageLoadAnimation1']!),
                                                                          Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                0.0,
                                                                                6.0,
                                                                                0.0,
                                                                                0.0),
                                                                            child:
                                                                                InkWell(
                                                                              splashColor: Colors.transparent,
                                                                              focusColor: Colors.transparent,
                                                                              hoverColor: Colors.transparent,
                                                                              highlightColor: Colors.transparent,
                                                                              onTap: () async {
                                                                                await Clipboard.setData(ClipboardData(text: chatItem.text.value));
                                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                                  SnackBar(
                                                                                    content: Text(
                                                                                      'Response copied to clipboard.',
                                                                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                            fontFamily: 'Poppins',
                                                                                            color: Color(0x00000000),
                                                                                            fontSize: 12.0,
                                                                                            letterSpacing: 0.0,
                                                                                          ),
                                                                                    ),
                                                                                    duration: Duration(milliseconds: 2000),
                                                                                    backgroundColor: FlutterFlowTheme.of(context).primary,
                                                                                  ),
                                                                                );
                                                                              },
                                                                              child: Row(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                children: [
                                                                                  Padding(
                                                                                    padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 4.0, 0.0),
                                                                                    child: Icon(
                                                                                      Icons.content_copy,
                                                                                      color: FlutterFlowTheme.of(context).tertiary,
                                                                                      size: 10.0,
                                                                                    ),
                                                                                  ),
                                                                                  Text(
                                                                                    FFLocalizations.of(context).getText(
                                                                                      'heqv2phh' /* Copy response */,
                                                                                    ),
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          fontFamily: 'Poppins',
                                                                                          color: FlutterFlowTheme.of(context).tertiary,
                                                                                          fontSize: 10.0,
                                                                                          letterSpacing: 0.0,
                                                                                        ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                0.0,
                                                                                6.0,
                                                                                0.0,
                                                                                0.0),
                                                                            child:
                                                                                InkWell(
                                                                              splashColor: Colors.transparent,
                                                                              focusColor: Colors.transparent,
                                                                              hoverColor: Colors.transparent,
                                                                              highlightColor: Colors.transparent,
                                                                              onTap: () async {
                                                                                await currentUserReference!.update(createUsersRecordData(
                                                                                  personalTrainerSuggestions: chatItem.text.value,
                                                                                ));
                                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                                  SnackBar(
                                                                                    content: Text(
                                                                                      'Message has been stored on My Info page',
                                                                                      style: TextStyle(
                                                                                        color: FlutterFlowTheme.of(context).tertiary,
                                                                                      ),
                                                                                    ),
                                                                                    duration: Duration(milliseconds: 4000),
                                                                                    backgroundColor: FlutterFlowTheme.of(context).primary,
                                                                                  ),
                                                                                );
                                                                              },
                                                                              child: Row(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                children: [
                                                                                  Padding(
                                                                                    padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 4.0, 0.0),
                                                                                    child: Icon(
                                                                                      Icons.content_copy,
                                                                                      color: FlutterFlowTheme.of(context).tertiary,
                                                                                      size: 10.0,
                                                                                    ),
                                                                                  ),
                                                                                  Text(
                                                                                    FFLocalizations.of(context).getText(
                                                                                      'kag14b1p' /* Copy response to my Progress p... */,
                                                                                    ),
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          fontFamily: 'Poppins',
                                                                                          color: FlutterFlowTheme.of(context).tertiary,
                                                                                          fontSize: 10.0,
                                                                                          letterSpacing: 0.0,
                                                                                        ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                if (chatIndex %
                                                                        2 ==
                                                                    0)
                                                                  Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            5.0,
                                                                            0.0,
                                                                            0.0),
                                                                    child: Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .end,
                                                                      children: [
                                                                        Container(
                                                                          width:
                                                                              MediaQuery.sizeOf(context).width * 0.8,
                                                                          constraints:
                                                                              BoxConstraints(
                                                                            maxWidth:
                                                                                () {
                                                                              if (MediaQuery.sizeOf(context).width >= 1170.0) {
                                                                                return 700.0;
                                                                              } else if (MediaQuery.sizeOf(context).width <= 470.0) {
                                                                                return 330.0;
                                                                              } else {
                                                                                return 530.0;
                                                                              }
                                                                            }(),
                                                                          ),
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                Color(0xFFADABAB),
                                                                            borderRadius:
                                                                                BorderRadius.circular(12.0),
                                                                            border:
                                                                                Border.all(
                                                                              color: FlutterFlowTheme.of(context).primaryBackground,
                                                                            ),
                                                                          ),
                                                                          child:
                                                                              Padding(
                                                                            padding:
                                                                                EdgeInsets.all(12.0),
                                                                            child:
                                                                                Column(
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              crossAxisAlignment: CrossAxisAlignment.end,
                                                                              children: [
                                                                                Text(
                                                                                  chatItem.text.value,
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        fontFamily: 'Poppins',
                                                                                        color: Color(0xFF0A0A0A),
                                                                                        letterSpacing: 0.0,
                                                                                      ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ).animateOnPageLoad(
                                                                            animationsMap['containerOnPageLoadAnimation2']!),
                                                                        Padding(
                                                                          padding: EdgeInsetsDirectional.fromSTEB(
                                                                              5.0,
                                                                              0.0,
                                                                              0.0,
                                                                              0.0),
                                                                          child:
                                                                              AuthUserStreamWidget(
                                                                            builder: (context) =>
                                                                                Container(
                                                                              width: 40.0,
                                                                              height: 40.0,
                                                                              clipBehavior: Clip.antiAlias,
                                                                              decoration: BoxDecoration(
                                                                                shape: BoxShape.circle,
                                                                              ),
                                                                              child: Image.network(
                                                                                valueOrDefault<String>(
                                                                                  currentUserPhoto,
                                                                                  'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                                ),
                                                                                fit: BoxFit.cover,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                              ],
                                                            );
                                                          },
                                                          controller: _model
                                                              .chatListView,
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 0.9,
                              decoration: BoxDecoration(
                                color: Color(0xFF0A0A0A),
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(
                                  color: FlutterFlowTheme.of(context).accent1,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16.0, 4.0, 16.0, 4.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width:
                                            MediaQuery.sizeOf(context).width *
                                                1.0,
                                        child: TextFormField(
                                          controller: _model
                                              .questionTestFieldTextController,
                                          focusNode:
                                              _model.questionTestFieldFocusNode,
                                          autofocus: false,
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                          obscureText: false,
                                          decoration: InputDecoration(
                                            hintText:
                                                FFLocalizations.of(context)
                                                    .getText(
                                              'suxm1ws5' /* How can I help you today ... */,
                                            ),
                                            hintStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .override(
                                                      fontFamily: 'Poppins',
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .accent1,
                                                      letterSpacing: 0.0,
                                                    ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(4.0),
                                                topRight: Radius.circular(4.0),
                                              ),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(4.0),
                                                topRight: Radius.circular(4.0),
                                              ),
                                            ),
                                            errorBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(4.0),
                                                topRight: Radius.circular(4.0),
                                              ),
                                            ),
                                            focusedErrorBorder:
                                                UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(4.0),
                                                topRight: Radius.circular(4.0),
                                              ),
                                            ),
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'Poppins',
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .tertiary,
                                                letterSpacing: 0.0,
                                              ),
                                          maxLines: 20,
                                          minLines: 1,
                                          keyboardType: TextInputType.multiline,
                                          validator: _model
                                              .questionTestFieldTextControllerValidator
                                              .asValidator(context),
                                        ),
                                      ),
                                    ),
                                    if (valueOrDefault(
                                            currentUserDocument?.gptButton,
                                            0) <=
                                        1000)
                                      AuthUserStreamWidget(
                                        builder: (context) =>
                                            FlutterFlowIconButton(
                                          borderColor: Colors.transparent,
                                          borderRadius: 20.0,
                                          borderWidth: 2.0,
                                          buttonSize: 30.0,
                                          icon: Icon(
                                            Icons.send_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            size: 20.0,
                                          ),
                                          showLoadingIndicator: true,
                                          onPressed: () async {
                                            await currentUserReference!.update({
                                              ...mapToFirestore(
                                                {
                                                  'gptButton':
                                                      FieldValue.increment(1),
                                                },
                                              ),
                                            });
                                            // Create a message
                                            _model.apiMessageCreateResult =
                                                await OpenAIAPIAssistantGroup
                                                    .messageCall
                                                    .call(
                                              threadId: _model.threadId,
                                              token: FFAppState().apiKey,
                                              content: _model
                                                  .questionTestFieldTextController
                                                  .text,
                                            );

                                            if ((_model.apiMessageCreateResult
                                                    ?.succeeded ??
                                                true)) {
                                              // Add Message to Chat History
                                              _model.addToChatHostpry(
                                                  ContentStruct.maybeFromMap(
                                                      getJsonField(
                                                (_model.apiMessageCreateResult
                                                        ?.jsonBody ??
                                                    ''),
                                                r'''$.content[0]''',
                                              ))!);
                                              safeSetState(() {});
                                              // Clear TextField
                                              safeSetState(() {
                                                _model
                                                    .questionTestFieldTextController
                                                    ?.clear();
                                              });
                                              // Wait for UI to catchup
                                              await Future.delayed(
                                                  const Duration(
                                                      milliseconds: 500));
                                              // Scroll to bottom
                                              await _model.scollingChatColumn
                                                  ?.animateTo(
                                                _model.scollingChatColumn!
                                                    .position.maxScrollExtent,
                                                duration:
                                                    Duration(milliseconds: 100),
                                                curve: Curves.ease,
                                              );
                                              // Run the assistant
                                              _model.apiAssistantRunResult =
                                                  await OpenAIAPIAssistantGroup
                                                      .runCall
                                                      .call(
                                                threadId: _model.threadId,
                                                assistantId:
                                                    FFAppState().assistantId,
                                                token: FFAppState().apiKey,
                                              );

                                              if ((_model.apiAssistantRunResult
                                                      ?.succeeded ??
                                                  true)) {
                                                // Store the runid
                                                _model.runId =
                                                    OpenAIAPIAssistantGroup
                                                        .runCall
                                                        .runId(
                                                  (_model.apiAssistantRunResult
                                                          ?.jsonBody ??
                                                      ''),
                                                )!;
                                                safeSetState(() {});
                                                while (_model.status !=
                                                    'completed') {
                                                  _model.apiRetrieveRunResult =
                                                      await OpenAIAPIAssistantGroup
                                                          .retrieverunCall
                                                          .call(
                                                    threadId: _model.threadId,
                                                    runId: _model.runId,
                                                    token: FFAppState().apiKey,
                                                  );

                                                  if ((_model
                                                          .apiRetrieveRunResult
                                                          ?.succeeded ??
                                                      true)) {
                                                    _model.status =
                                                        OpenAIAPIAssistantGroup
                                                            .retrieverunCall
                                                            .status(
                                                              (_model.apiRetrieveRunResult
                                                                      ?.jsonBody ??
                                                                  ''),
                                                            )
                                                            .toString();
                                                    safeSetState(() {});
                                                    if (_model.status !=
                                                        'completed') {
                                                      // Delay 3 seconds before next check
                                                      await Future.delayed(
                                                          const Duration(
                                                              milliseconds:
                                                                  3000));
                                                    }
                                                  }
                                                }
                                                // Get latest message
                                                _model.apiGetMessagesResult =
                                                    await OpenAIAPIAssistantGroup
                                                        .messagesCall
                                                        .call(
                                                  threadId: _model.threadId,
                                                  token: FFAppState().apiKey,
                                                );

                                                if ((_model.apiGetMessagesResult
                                                        ?.succeeded ??
                                                    true)) {
                                                  // Add message to chat history
                                                  _model.addToChatHostpry(
                                                      ContentStruct.maybeFromMap(
                                                          OpenAIAPIAssistantGroup
                                                              .messagesCall
                                                              .data(
                                                    (_model.apiGetMessagesResult
                                                            ?.jsonBody ??
                                                        ''),
                                                  ))!);
                                                  safeSetState(() {});
                                                  // Wait for UI to catchup
                                                  await Future.delayed(
                                                      const Duration(
                                                          milliseconds: 500));
                                                  // Scroll to bottom
                                                  await _model
                                                      .scollingChatColumn
                                                      ?.animateTo(
                                                    _model
                                                        .scollingChatColumn!
                                                        .position
                                                        .maxScrollExtent,
                                                    duration: Duration(
                                                        milliseconds: 100),
                                                    curve: Curves.ease,
                                                  );
                                                  // Reset completed status
                                                  _model.status = 'pusiga';
                                                  safeSetState(() {});
                                                }
                                              }
                                            }

                                            safeSetState(() {});
                                          },
                                        ),
                                      ),
                                    Container(
                                      width: 0.0,
                                      height: 0.0,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                      ),
                                      child: AuthUserStreamWidget(
                                        builder: (context) => Container(
                                          width:
                                              MediaQuery.sizeOf(context).width *
                                                  1.0,
                                          child: TextFormField(
                                            controller: _model
                                                .alwayspopulatedTextController,
                                            focusNode:
                                                _model.alwayspopulatedFocusNode,
                                            autofocus: false,
                                            textCapitalization:
                                                TextCapitalization.sentences,
                                            obscureText: false,
                                            decoration: InputDecoration(
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Color(0x00000000),
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  topLeft: Radius.circular(4.0),
                                                  topRight:
                                                      Radius.circular(4.0),
                                                ),
                                              ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Color(0x00000000),
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  topLeft: Radius.circular(4.0),
                                                  topRight:
                                                      Radius.circular(4.0),
                                                ),
                                              ),
                                              errorBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Color(0x00000000),
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  topLeft: Radius.circular(4.0),
                                                  topRight:
                                                      Radius.circular(4.0),
                                                ),
                                              ),
                                              focusedErrorBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Color(0x00000000),
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  topLeft: Radius.circular(4.0),
                                                  topRight:
                                                      Radius.circular(4.0),
                                                ),
                                              ),
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .tertiary,
                                                  letterSpacing: 0.0,
                                                ),
                                            maxLines: 20,
                                            minLines: 1,
                                            keyboardType:
                                                TextInputType.multiline,
                                            validator: _model
                                                .alwayspopulatedTextControllerValidator
                                                .asValidator(context),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
