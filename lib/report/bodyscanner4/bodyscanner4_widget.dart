import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/gemini/gemini.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'bodyscanner4_model.dart';
export 'bodyscanner4_model.dart';

class Bodyscanner4Widget extends StatefulWidget {
  const Bodyscanner4Widget({super.key});

  static String routeName = 'bodyscanner4';
  static String routePath = 'bodyscanner4';

  @override
  State<Bodyscanner4Widget> createState() => _Bodyscanner4WidgetState();
}

class _Bodyscanner4WidgetState extends State<Bodyscanner4Widget> {
  late Bodyscanner4Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Bodyscanner4Model());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.check = false;
      _model.waitCheck = false;
      _model.waitCheck2 = false;
      safeSetState(() {});
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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).tertiary,
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Stack(
                children: [
                  if ((_model.waitCheck == true) && (_model.waitCheck2 == true))
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 25.0, 20.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  FlutterFlowIconButton(
                                    borderRadius: 8.0,
                                    buttonSize: 30.0,
                                    fillColor:
                                        FlutterFlowTheme.of(context).secondary,
                                    icon: Icon(
                                      Icons.close,
                                      color:
                                          FlutterFlowTheme.of(context).tertiary,
                                      size: 15.0,
                                    ),
                                    onPressed: () async {
                                      context.safePop();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Opacity(
                              opacity: 0.0,
                              child: Text(
                                FFLocalizations.of(context).getText(
                                  'aesjm0v7' /* Generating Your Personalized R... */,
                                ),
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Poppins',
                                      color: FlutterFlowTheme.of(context)
                                          .secondary,
                                      fontSize: 20.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  25.0, 20.0, 25.0, 0.0),
                              child: Text(
                                FFLocalizations.of(context).getText(
                                  'kc0c95x1' /* 🔄 Please wait while we analyz... */,
                                ),
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Poppins',
                                      color: FlutterFlowTheme.of(context)
                                          .secondary,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.normal,
                                    ),
                              ),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.asset(
                                'assets/images/60s_Planks-original.webp',
                                width: 200.0,
                                height: 200.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  if ((_model.waitCheck == false) &&
                      (_model.waitCheck2 == false))
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 25.0, 20.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FlutterFlowIconButton(
                                borderRadius: 8.0,
                                buttonSize: 30.0,
                                fillColor:
                                    FlutterFlowTheme.of(context).secondary,
                                icon: Icon(
                                  Icons.close,
                                  color: FlutterFlowTheme.of(context).tertiary,
                                  size: 15.0,
                                ),
                                onPressed: () async {
                                  context.safePop();
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              25.0, 0.0, 25.0, 0.0),
                          child: Text(
                            FFLocalizations.of(context).getText(
                              '6t4iiibm' /* Before we begin you need to fo... */,
                            ),
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Poppins',
                                  color: FlutterFlowTheme.of(context).secondary,
                                  fontSize: 20.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              25.0, 20.0, 25.0, 0.0),
                          child: Text(
                            FFLocalizations.of(context).getText(
                              '2sxydfp3' /* To generate your personalized ... */,
                            ),
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Poppins',
                                  color: FlutterFlowTheme.of(context).secondary,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.normal,
                                ),
                          ),
                        ),
                      ],
                    ),
                  if ((_model.waitCheck2 == true) &&
                      (_model.waitCheck == false))
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 25.0, 20.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  FlutterFlowIconButton(
                                    borderRadius: 8.0,
                                    buttonSize: 30.0,
                                    fillColor:
                                        FlutterFlowTheme.of(context).secondary,
                                    icon: Icon(
                                      Icons.close,
                                      color:
                                          FlutterFlowTheme.of(context).tertiary,
                                      size: 15.0,
                                    ),
                                    onPressed: () async {
                                      context.safePop();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  25.0, 0.0, 25.0, 0.0),
                              child: Text(
                                FFLocalizations.of(context).getText(
                                  'hn4q3w1e' /* Upload photos */,
                                ),
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Poppins',
                                      color: FlutterFlowTheme.of(context)
                                          .secondary,
                                      fontSize: 25.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  25.0, 20.0, 25.0, 0.0),
                              child: Text(
                                FFLocalizations.of(context).getText(
                                  'r1v2ncxn' /* Once you've taken the photos, ... */,
                                ),
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Poppins',
                                      color: FlutterFlowTheme.of(context)
                                          .secondary,
                                      fontSize: 15.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 100.0, 0.0, 0.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(
                                    width: 150.0,
                                    height: 150.0,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.memory(
                                        _model.uploadedLocalFile1.bytes ??
                                            Uint8List.fromList([]),
                                        width: 200.0,
                                        height: 200.0,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 150.0,
                                    height: 150.0,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.memory(
                                        _model.uploadedLocalFile2.bytes ??
                                            Uint8List.fromList([]),
                                        width: 200.0,
                                        height: 200.0,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Stack(
                                children: [
                                  if (((_model.uploadedLocalFile1.bytes
                                                  ?.isNotEmpty ??
                                              false)) &&
                                      ((_model.uploadedLocalFile2.bytes
                                                  ?.isNotEmpty ??
                                              false)))
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 20.0, 0.0, 0.0),
                                      child: Stack(
                                        children: [
                                          FFButtonWidget(
                                            onPressed: () async {
                                              safeSetState(() {
                                                _model.isDataUploading1 = false;
                                                _model.uploadedLocalFile1 =
                                                    FFUploadedFile(
                                                        bytes:
                                                            Uint8List.fromList(
                                                                []));
                                              });

                                              safeSetState(() {
                                                _model.isDataUploading2 = false;
                                                _model.uploadedLocalFile2 =
                                                    FFUploadedFile(
                                                        bytes:
                                                            Uint8List.fromList(
                                                                []));
                                              });
                                            },
                                            text: FFLocalizations.of(context)
                                                .getText(
                                              'sr3tmdr6' /* Delete  photos */,
                                            ),
                                            options: FFButtonOptions(
                                              height: 40.0,
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      16.0, 0.0, 16.0, 0.0),
                                              iconPadding: EdgeInsetsDirectional
                                                  .fromSTEB(0.0, 0.0, 0.0, 0.0),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .error,
                                              textStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .override(
                                                        fontFamily: 'Poppins',
                                                        color: Colors.white,
                                                        letterSpacing: 0.0,
                                                      ),
                                              elevation: 0.0,
                                              borderRadius:
                                                  BorderRadius.circular(20.0),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if ((_model.uploadedLocalFile2.bytes
                                              ?.isEmpty ??
                                          true))
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 20.0, 0.0, 0.0),
                                      child: Stack(
                                        children: [
                                          FFButtonWidget(
                                            onPressed: () async {
                                              final selectedMedia =
                                                  await selectMediaWithSourceBottomSheet(
                                                context: context,
                                                maxWidth: 300.00,
                                                maxHeight: 300.00,
                                                allowPhoto: true,
                                                pickerFontFamily: 'Poppins',
                                              );
                                              if (selectedMedia != null &&
                                                  selectedMedia.every((m) =>
                                                      validateFileFormat(
                                                          m.storagePath,
                                                          context))) {
                                                safeSetState(() => _model
                                                    .isDataUploading1 = true);
                                                var selectedUploadedFiles =
                                                    <FFUploadedFile>[];

                                                try {
                                                  showUploadMessage(
                                                    context,
                                                    'Uploading file...',
                                                    showLoading: true,
                                                  );
                                                  selectedUploadedFiles =
                                                      selectedMedia
                                                          .map((m) =>
                                                              FFUploadedFile(
                                                                name: m
                                                                    .storagePath
                                                                    .split('/')
                                                                    .last,
                                                                bytes: m.bytes,
                                                                height: m
                                                                    .dimensions
                                                                    ?.height,
                                                                width: m
                                                                    .dimensions
                                                                    ?.width,
                                                                blurHash:
                                                                    m.blurHash,
                                                              ))
                                                          .toList();
                                                } finally {
                                                  ScaffoldMessenger.of(context)
                                                      .hideCurrentSnackBar();
                                                  _model.isDataUploading1 =
                                                      false;
                                                }
                                                if (selectedUploadedFiles
                                                        .length ==
                                                    selectedMedia.length) {
                                                  safeSetState(() {
                                                    _model.uploadedLocalFile1 =
                                                        selectedUploadedFiles
                                                            .first;
                                                  });
                                                  showUploadMessage(
                                                      context, 'Success!');
                                                } else {
                                                  safeSetState(() {});
                                                  showUploadMessage(context,
                                                      'Failed to upload data');
                                                  return;
                                                }
                                              }
                                            },
                                            text: FFLocalizations.of(context)
                                                .getText(
                                              'zj8plo7u' /* Upload first photo */,
                                            ),
                                            options: FFButtonOptions(
                                              height: 40.0,
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      16.0, 0.0, 16.0, 0.0),
                                              iconPadding: EdgeInsetsDirectional
                                                  .fromSTEB(0.0, 0.0, 0.0, 0.0),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondary,
                                              textStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .override(
                                                        fontFamily: 'Poppins',
                                                        color: Colors.white,
                                                        letterSpacing: 0.0,
                                                      ),
                                              elevation: 0.0,
                                              borderRadius:
                                                  BorderRadius.circular(20.0),
                                            ),
                                          ),
                                          if ((_model.uploadedLocalFile1.bytes
                                                      ?.isNotEmpty ??
                                                  false))
                                            FFButtonWidget(
                                              onPressed: () async {
                                                final selectedMedia =
                                                    await selectMediaWithSourceBottomSheet(
                                                  context: context,
                                                  allowPhoto: true,
                                                );
                                                if (selectedMedia != null &&
                                                    selectedMedia.every((m) =>
                                                        validateFileFormat(
                                                            m.storagePath,
                                                            context))) {
                                                  safeSetState(() => _model
                                                      .isDataUploading2 = true);
                                                  var selectedUploadedFiles =
                                                      <FFUploadedFile>[];

                                                  try {
                                                    selectedUploadedFiles =
                                                        selectedMedia
                                                            .map((m) =>
                                                                FFUploadedFile(
                                                                  name: m
                                                                      .storagePath
                                                                      .split(
                                                                          '/')
                                                                      .last,
                                                                  bytes:
                                                                      m.bytes,
                                                                  height: m
                                                                      .dimensions
                                                                      ?.height,
                                                                  width: m
                                                                      .dimensions
                                                                      ?.width,
                                                                  blurHash: m
                                                                      .blurHash,
                                                                ))
                                                            .toList();
                                                  } finally {
                                                    _model.isDataUploading2 =
                                                        false;
                                                  }
                                                  if (selectedUploadedFiles
                                                          .length ==
                                                      selectedMedia.length) {
                                                    safeSetState(() {
                                                      _model.uploadedLocalFile2 =
                                                          selectedUploadedFiles
                                                              .first;
                                                    });
                                                  } else {
                                                    safeSetState(() {});
                                                    return;
                                                  }
                                                }
                                              },
                                              text: FFLocalizations.of(context)
                                                  .getText(
                                                'ihrcccd7' /* Upload second photo */,
                                              ),
                                              options: FFButtonOptions(
                                                height: 40.0,
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        16.0, 0.0, 16.0, 0.0),
                                                iconPadding:
                                                    EdgeInsetsDirectional
                                                        .fromSTEB(
                                                            0.0, 0.0, 0.0, 0.0),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondary,
                                                textStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .override(
                                                          fontFamily: 'Poppins',
                                                          color: Colors.white,
                                                          letterSpacing: 0.0,
                                                        ),
                                                elevation: 0.0,
                                                borderRadius:
                                                    BorderRadius.circular(20.0),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              Stack(
                children: [
                  if ((_model.waitCheck == false) &&
                      (_model.waitCheck2 == false))
                    FFButtonWidget(
                      onPressed: () async {
                        _model.waitCheck2 = true;
                        safeSetState(() {});
                      },
                      text: FFLocalizations.of(context).getText(
                        'cjdaniel' /* Next */,
                      ),
                      options: FFButtonOptions(
                        width: MediaQuery.sizeOf(context).width * 0.8,
                        height: 50.0,
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 0.0),
                        iconPadding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: FlutterFlowTheme.of(context).secondary,
                        textStyle:
                            FlutterFlowTheme.of(context).titleSmall.override(
                                  fontFamily: 'Poppins',
                                  color: FlutterFlowTheme.of(context).tertiary,
                                  letterSpacing: 0.0,
                                ),
                        elevation: 0.0,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  if ((_model.waitCheck2 == true) || (_model.waitCheck == true))
                    FFButtonWidget(
                      onPressed: () async {
                        if (((_model.uploadedLocalFile1.bytes?.isNotEmpty ??
                                    false)) &&
                            ((_model.uploadedLocalFile2.bytes?.isNotEmpty ??
                                    false))) {
                          _model.waitCheck = true;
                          safeSetState(() {});
                          await geminiTextFromImage(
                            context,
                            '***Important: TOTAL SUM OF ALL NUMBERS MUST BE 100, IT CANNOT BE UNDER OR OVER 100 ALWAYS FOLLOW THIS RULE, Essential Fat (E.fat), Basal Metabolic Fat (B.fat), Upper Body Fat (U.fat), and Lean Mass (Leanmass)*** ***Important: Fat Mass Index cannot be calculated over 15, adhere to this rule always.*** Estimate the following body composition values based on the users information and attached images:  Answer only in this manner with your best guess dont answer anything else just give me structured answer like this: Essential Fat (E.fat), Basal Metabolic Fat (B.fat), Upper Body Fat (U.fat), and Lean Mass (Leanmass). Provide only the numerical values in the following format:  E.fat: B.fat: U.fat: Leanmass: Lean Mass Index: Fat Mass Index: Calories burned at rest:  . Age:${currentUserDocument?.age2?.toString()} , Height: ${valueOrDefault(currentUserDocument?.height, 0).toString()} ,weight: ${valueOrDefault(currentUserDocument?.weight, 0).toString()} ,goal: ${valueOrDefault(currentUserDocument?.goals, '')} ,level of phisical readiness: ${valueOrDefault(currentUserDocument?.workoutLevel, '')} ,Gender: ${valueOrDefault<bool>(currentUserDocument?.gender, false).toString()}Take into account all of the information provided about the person and answer based on the data you have.',
                            uploadImageBytes: _model.uploadedLocalFile1,
                          ).then((generatedText) {
                            safeSetState(
                                () => _model.geminiOutput = generatedText);
                          });

                          await currentUserReference!
                              .update(createUsersRecordData(
                            geminiParse: _model.geminiOutput,
                          ));
                          _model.bfat2 = await actions.bFat(
                            valueOrDefault(
                                currentUserDocument?.geminiParse, ''),
                          );
                          _model.ufat2 = await actions.uFat(
                            valueOrDefault(
                                currentUserDocument?.geminiParse, ''),
                          );
                          _model.efat2 = await actions.eFat(
                            valueOrDefault(
                                currentUserDocument?.geminiParse, ''),
                          );
                          _model.leanmass2 = await actions.leanMass(
                            valueOrDefault(
                                currentUserDocument?.geminiParse, ''),
                          );
                          _model.bFat = await actions.bFat2(
                            valueOrDefault(
                                currentUserDocument?.geminiParse, ''),
                          );
                          _model.efat = await actions.eFat2(
                            valueOrDefault(
                                currentUserDocument?.geminiParse, ''),
                          );
                          _model.leanmass = await actions.leanMass2(
                            valueOrDefault(
                                currentUserDocument?.geminiParse, ''),
                          );
                          _model.ufat = await actions.uFat2(
                            valueOrDefault(
                                currentUserDocument?.geminiParse, ''),
                          );
                          _model.leanMassIndex = await actions.leanMassIndex(
                            valueOrDefault(
                                currentUserDocument?.geminiParse, ''),
                          );
                          _model.fatMassIndex = await actions.fatMassIndex(
                            valueOrDefault(
                                currentUserDocument?.geminiParse, ''),
                          );
                          _model.caloriesBurnt = await actions.caloriesBurnt(
                            valueOrDefault(
                                currentUserDocument?.geminiParse, ''),
                          );

                          await currentUserReference!
                              .update(createUsersRecordData(
                            fatMassIndex: _model.fatMassIndex,
                            leanMassIndex: _model.leanMassIndex,
                            caloriesBurnt: _model.caloriesBurnt,
                            ufat2: _model.ufat,
                            bfat2: _model.bFat,
                            efat2: _model.efat,
                            leanMass2: _model.leanmass,
                            efat: _model.efat2,
                            ufat: _model.ufat2,
                            bfat: _model.bfat2,
                            leanmass: _model.leanmass2,
                          ));
                          await geminiTextFromImage(
                            context,
                            '\"Please provide a comprehensive fitness and nutrition plan in the exact format below. The response should be well-structured with line breaks, bolded headers, subheadings, and emojis to enhance readability. Include valid YouTube links for every exercise—no placeholders, expired, or invalid links. If no valid link is available for a given exercise, simply omit the link. The meal plan must feature approximate calories and brief preparation instructions for each dish. The workout plan must specify daily exercises, approximate calories burned, and clickable Search-query style YouTube link if desired (e.g., [https://www.youtube.com/results?search_query=push+ups+exercise](...))..  Important: For Month 2 and Month 3 in the workout plan, do not simply say “increase weight or reps.” Each day must have specific exercises, approximate calories burned, instructions (sets, reps, recommended weight increases or variations), and valid YouTube links—just like Month 1, but with clearly shown progressions (e.g., heavier weights, additional sets, more advanced exercises).   Daily Exercises & YouTube Search Links For each day (e.g., Monday), provide: A list of exercises or workout routines Approx. calories burned (if applicable) Concise instructions (sets, reps, form tips) Search-query style YouTube link if desired (e.g., [https://www.youtube.com/results?search_query=push+ups+exercise](...)). No placeholders like “Link goes here.” Valid Search-Query Links For each exercise, add a link like: [https://www.youtube.com/results?search_query=push+ups+exercise](https://www.youtube.com/results?search_query=push+ups+exercise) If you can’t find a sensible query, skip the link. No placeholder text or “YouTube search” references.  Format (maintain the exact headers and subheaders verbatim): Calories Burn:[Provide only a single integer for the daily calorie burn target (e.g., 2500). No extra text or range—just the number.]Calories Intake:[Provide only a single integer for the daily calorie intake (e.g., 2000). No extra text—just the number.] Workout Plan (3-Month Sample):  Month 1: [Provide a weekly structure (Monday to Sunday). For each day, list the exercises (with emojis, e.g., 🏋️, 🏃, 🤸), approximate calories burned, concise instructions or sets/reps, and valid YouTube links—no placeholders or invalid links. If no valid link is found, skip the link.]  Month 2: [Give a similar day-by-day breakdown (Monday to Sunday) as Month 1 with explicit progressions—heavier weights, more sets/reps, or new exercises. Include approximate calories burned, emojis, concise instructions, and valid YouTube links if available. Do not just say “increase weight;” show how much or how to do it.]  Month 3: [Again, provide day-by-day details (Monday to Sunday), further progressions (heavier weights, more advanced variations, additional sets/reps), approximate calories burned, emojis, concise instructions, and valid YouTube links where possible. It must be fully detailed, not just “increase.”]  Pro Tips: [Add any additional advice on hydration, sleep, stress management, supplements, etc.]  Motivational Quotes: [List at least three short motivational quotes, and put the word END after the last quote.]  Example of the Workout Plan Section Below is an illustrative snippet (just an example). Your final output should be more detailed and cover all days for each month with progressive changes:**Workout Plan (3-Month Sample):**  **Workout Plan (3-Month Sample)**  **Month 1** **Monday** 🏋️ - *Push-Ups* (Approx. 100 Calories)   - Perform 3 sets of 12 reps; keep your core tight.   - [https://www.youtube.com/results?search_query=push+ups+exercise](https://www.youtube.com/results?search_query=push+ups+exercise) - *Squats* (Approx. 120 Calories)   - Perform 3 sets of 10 reps; knees tracking over toes.   - [https://www.youtube.com/results?search_query=squats+exercise](https://www.youtube.com/results?search_query=squats+exercise)  **Tuesday** 🏃 - *20-Minute Jog* (Approx. 180 Calories)   - Warm up 5 minutes; jog at moderate pace; cool down 5 minutes.   - [https://www.youtube.com/results?search_query=jogging+tips](https://www.youtube.com/results?search_query=jogging+tips)  Continue this style for all days in Month 1, then Month 2 with specific increases (e.g., heavier dumbbells, 2–3 extra reps, new advanced movements), then Month 3 with further progressions.  Styling & Additional Requirements Use bold text for headers (e.g., Month 1, Monday). Include emojis for workouts (e.g., 🏋️, 🏃, 🤸). Provide approximate calories for each exercise or daily session. Include concise but complete instructions (e.g., sets, reps, recommended weight changes, form tips). All YouTube links must be valid and relevant—no placeholders, no “search here” text, no expired links. If no valid link is found, omit the link entirely. After listing the plan, provide Pro Tips and at least three Motivational Quotes, ending the last quote with END.\" . Age:${currentUserDocument?.age2?.toString()} , Height: ${valueOrDefault(currentUserDocument?.height, 0).toString()} ,weight: ${valueOrDefault(currentUserDocument?.weight, 0).toString()} ,goal: ${valueOrDefault(currentUserDocument?.goals, '')} ,level of phisical readiness: ${valueOrDefault(currentUserDocument?.workoutLevel, '')} ,Gender: ${valueOrDefault<bool>(currentUserDocument?.gender, false).toString()}Take into account all of the information provided about the person and answer based on the data you have.',
                            uploadImageBytes: _model.uploadedLocalFile2,
                          ).then((generatedText) {
                            safeSetState(
                                () => _model.geminiOutput2 = generatedText);
                          });

                          await currentUserReference!
                              .update(createUsersRecordData(
                            geminiParse2: _model.geminiOutput2,
                          ));
                          _model.caloriesBurn = await actions.caloriesBurn(
                            valueOrDefault(
                                currentUserDocument?.geminiParse2, ''),
                          );
                          _model.caloriesIntake = await actions.caloriesIntake(
                            valueOrDefault(
                                currentUserDocument?.geminiParse2, ''),
                          );
                          _model.workoutPlan = await actions.workoutPlan(
                            valueOrDefault(
                                currentUserDocument?.geminiParse2, ''),
                          );
                          _model.caloricIntakePerDay =
                              await actions.caloriesIntakeNumber(
                            _model.geminiOutput2,
                          );

                          await currentUserReference!
                              .update(createUsersRecordData(
                            caloriesBurn: _model.caloriesBurn,
                            caloriesIntake: _model.caloriesIntake,
                            workoutPlan: _model.workoutPlan,
                            caloricIntakePerDay: _model.caloricIntakePerDay,
                          ));
                          await geminiTextFromImage(
                            context,
                            '\"Take into account the information provided in the description bellow and craft the meal plan based on the users specific information. Please provide a detailed Meal Plan for Weeks 1-4, Weeks 5-8, and Weeks 9-12. The plan must follow all of these requirements: Headers & Subheaders   Bold and label each phase as Week 1-4, Week 5-8, and Week 9-12. Under each week range, include subheaders for Breakfast, Lunch, and Dinner. Use relevant emojis for each meal (e.g., 🍳 for breakfast, 🥪 for lunch, 🍝 for dinner) to add clarity and style. Meal Options & YouTube Search Links For each meal (Breakfast, Lunch, Dinner), provide 3 meal options, each with: A meal name Approximate calorie count A short preparation description A YouTube search query link relevant to that meal (e.g., [https://www.youtube.com/results?search_query=shrimp+scampi+zoodles](...)). No placeholders like “Link goes here” or “Lorem ipsum.” If you cannot confirm a reasonable search query for the dish, just provide the meal but no link. Approximate Calorie Counts   Approximate the calorie count for each meal option. Layout & Styling   Use line breaks to separate the meal phases (Week 1-4, 5-8, 9-12) and meal types (Breakfast, Lunch, Dinner). Bold the text for each header and subheader (e.g., Week 1-4, Breakfast 🍳). Include emojis that fit naturally with each meal. Variations & Consistency   Provide meal variations for Week 1-4, Week 5-8, and Week 9-12. If a meal repeats in later weeks, re-list it with the same format (3 options, approximate calories, instructions, and a valid YouTube link if available). Do not just say “Same as Week 1-4” for Weeks 5-8 or 9-12. If you reuse a dish, fully re-list it so the instructions are clear. No Placeholder Text   Ensure the response does not contain any placeholder text like “Link goes here,” “YouTube search,” or “Lorem ipsum.” Provide actual dish names, approximate calorie counts, and valid YouTube links if available. Otherwise, skip the link entirely. Exact Format Sample  (adapt the sample as needed, but keep a similar style):   markdown CopyEdit **Meal Plan (3-Month Sample – Include Approx. Calories per Meal):**  **Week 1-4** **Dinner** 🍝 - *Option 1:* Shrimp Scampi with Zucchini Noodles (Approx. 450 Calories)   - Sauté shrimp with zucchini noodles in garlic, lemon juice, and white wine.   - [https://www.youtube.com/results?search_query=shrimp+scampi+zoodles](https://www.youtube.com/results?search_query=shrimp+scampi+zoodles) - *Option 2:* Chicken and Vegetable Skewers with Quinoa (Approx. 400 Calories)   - Prepare skewers with chicken breast and vegetables; grill or bake, serve with quinoa.   - [https://www.youtube.com/results?search_query=chicken+vegetable+skewers](https://www.youtube.com/results?search_query=chicken+vegetable+skewers) - *Option 3:* Black Bean Burgers on Whole Wheat Buns (Approx. 500 Calories)   - Prepare black bean patties, pan-fry or bake; serve with favorite toppings.   - [https://www.youtube.com/results?search_query=black+bean+burger+recipe](https://www.youtube.com/results?search_query=black+bean+burger+recipe)    Important: Make sure the entire response is visually clear, includes bolded headers, emojis, concise preparation instructions, and approximate calories for each meal. If a valid YouTube link exists for the dish, include it; if not, skip the link. No placeholders or partial references to searching are allowed. After finishing the meal plan put the word END. . Age:${currentUserDocument?.age2?.toString()} , Height: ${valueOrDefault(currentUserDocument?.height, 0).toString()} ,weight: ${valueOrDefault(currentUserDocument?.weight, 0).toString()} ,goal: ${valueOrDefault(currentUserDocument?.goals, '')} ,level of phisical readiness: ${valueOrDefault(currentUserDocument?.workoutLevel, '')} ,Gender: ${valueOrDefault<bool>(currentUserDocument?.gender, false).toString()}. Alergies: ${valueOrDefault(currentUserDocument?.foodAlergies, '')}. Caloric target: ${valueOrDefault(currentUserDocument?.caloriesIntake, '')}Additional estimate the following nutritional values based on the user\'s information and meal plan, give me just a single number dont give me a range from to: Answer only in this manner with your best guess, don\'t answer anything else, just give me a structured answer like this: Total Calories Intake: , Proteins Per Day: , Fats Per Day: , Carbs Per Day: .',
                            uploadImageBytes: _model.uploadedLocalFile1,
                          ).then((generatedText) {
                            safeSetState(
                                () => _model.cusotmMealPlan = generatedText);
                          });

                          await currentUserReference!
                              .update(createUsersRecordData(
                            geminiParse3: _model.cusotmMealPlan,
                          ));
                          _model.carbsPerDay = await actions.carbsPerDay(
                            valueOrDefault(
                                currentUserDocument?.geminiParse3, ''),
                          );
                          _model.fatsPerDay = await actions.fatsPerDay(
                            valueOrDefault(
                                currentUserDocument?.geminiParse3, ''),
                          );
                          _model.proteinPerDay = await actions.proteinsPerDay(
                            valueOrDefault(
                                currentUserDocument?.geminiParse3, ''),
                          );
                          _model.customMealPlanOutput = await actions.mealPlan(
                            valueOrDefault(
                                currentUserDocument?.geminiParse3, ''),
                          );

                          await currentUserReference!
                              .update(createUsersRecordData(
                            mealPlan: _model.customMealPlanOutput,
                            carbsPerDay: _model.carbsPerDay,
                            fatsPerDay: _model.fatsPerDay,
                            proteinPerDay: _model.proteinPerDay,
                          ));

                          context.pushNamed(ReportWidget.routeName);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Upload images in order to proceed',
                                style: TextStyle(
                                  color: FlutterFlowTheme.of(context).tertiary,
                                ),
                              ),
                              duration: Duration(milliseconds: 4000),
                              backgroundColor:
                                  FlutterFlowTheme.of(context).secondary,
                            ),
                          );
                        }

                        safeSetState(() {});
                      },
                      text: FFLocalizations.of(context).getText(
                        'tasoiv8x' /* Generate report */,
                      ),
                      options: FFButtonOptions(
                        width: MediaQuery.sizeOf(context).width * 0.8,
                        height: 50.0,
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 0.0),
                        iconPadding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: FlutterFlowTheme.of(context).secondary,
                        textStyle:
                            FlutterFlowTheme.of(context).titleSmall.override(
                                  fontFamily: 'Poppins',
                                  color: FlutterFlowTheme.of(context).tertiary,
                                  letterSpacing: 0.0,
                                ),
                        elevation: 0.0,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
