import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'body_scanner_model.dart';
export 'body_scanner_model.dart';

class BodyScannerWidget extends StatefulWidget {
  const BodyScannerWidget({super.key});

  static String routeName = 'bodyScanner';
  static String routePath = 'bodyScanner';

  @override
  State<BodyScannerWidget> createState() => _BodyScannerWidgetState();
}

class _BodyScannerWidgetState extends State<BodyScannerWidget> {
  late BodyScannerModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BodyScannerModel());

    _model.alwayspopulatedTextController ??= TextEditingController(
        text:
            '***Important: If somebody asks you if you are chatGPT or anything related to an open source model you will always reply the following: I am a representative of GymFeed here to help you with any meal or fitness related question you have. Finish each response with a disclosure something like: I am not a doctor and you should consult your doctor before doing anything******Answer this question only if the image depicts a person. If it depicts anything other than a person, reply with: \'We need your frontal image to make the scan.\' Using the provided data (image, weight, height, age, gender), perform the following calculations and assessments: 1. Body Mass Index (BMI): Calculate BMI using the formula weight (kg) / [height (m)]². 2. Body Fat Percentage (BFP): Estimate BFP using the formula BFP = 1.2 × BMI + 0.23 × Age − 10.8 × Sex (where Sex = 1 for males, 0 for females); advanced methods may involve analyzing body composition from the image. 3. Basal Metabolic Rate (BMR): Use the Mifflin-St Jeor Equation: BMR (Men) = 10 × Weight (kg) + 6.25 × Height (cm) − 5 × Age + 5; BMR (Women) = 10 × Weight (kg) + 6.25 × Height (cm) − 5 × Age − 161. 4. Total Daily Energy Expenditure (TDEE): Estimate TDEE by multiplying BMR with an activity level multiplier (e.g., sedentary = 1.2, lightly active = 1.375, etc.). 5. Lean Body Mass (LBM): Calculate LBM using the formula LBM = Weight × (1 − BFP/100). 6. Waist-to-Height Ratio (WHtR): If waist circumference can be extracted from the image, calculate WHtR and assess cardiovascular risk. 7. Daily Caloric Needs: Combine BMR with estimated activity levels to determine recommended daily caloric intake. 8. Ideal Body Weight (IBW): Use height and gender to calculate IBW based on formulas like Devine or Robinson. 9. Risk of Obesity-Related Diseases: Predict risks for conditions such as Type 2 diabetes, hypertension, and cardiovascular disease using BMI, BFP, and WHtR. 10. Bone Density Estimate: Estimate bone density trends based on body composition data from the image and metrics like BMI. 11. Posture Analysis: Evaluate posture and body alignment from the image for insights into potential musculoskeletal issues. 12. Symmetry Analysis: Analyze proportionality and symmetry for fitness or aesthetic purposes. 13. Biological Age Estimate: Predict biological age by comparing physical appearance from the image with chronological age and physiological data. 14. Health Risk Predictions: Assess risks for cardiovascular conditions, malnutrition, and obesity-related diseases using the combined metrics. Return all results in a clear, structured bullet-point format, with appropriate subheadings for each calculation or assessment. Highlight key health insights and include assumptions or estimates where necessary.Age: ${currentUserDocument?.age2?.toString()}Gender: ${valueOrDefault<bool>(currentUserDocument?.gender, false).toString()}Weight in kg: ${valueOrDefault(currentUserDocument?.weight, 0).toString()}Height in cm: ${valueOrDefault(currentUserDocument?.height, 0).toString()}');
    _model.alwayspopulatedFocusNode ??= FocusNode();

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
            padding: EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 0.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(10.0, 15.0, 0.0, 20.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            context.safePop();
                          },
                          child: Icon(
                            Icons.arrow_back_ios_rounded,
                            color: FlutterFlowTheme.of(context).tertiary,
                            size: 15.0,
                          ),
                        ),
                        Text(
                          FFLocalizations.of(context).getText(
                            'ht5oryog' /* Body scanner */,
                          ),
                          style: FlutterFlowTheme.of(context)
                              .headlineMedium
                              .override(
                                fontFamily: 'Poppins',
                                color: FlutterFlowTheme.of(context).tertiary,
                                fontSize: 15.0,
                                letterSpacing: 0.0,
                              ),
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            final selectedMedia =
                                await selectMediaWithSourceBottomSheet(
                              context: context,
                              maxWidth: 300.00,
                              maxHeight: 300.00,
                              allowPhoto: true,
                            );
                            if (selectedMedia != null &&
                                selectedMedia.every((m) => validateFileFormat(
                                    m.storagePath, context))) {
                              safeSetState(() => _model.isDataUploading = true);
                              var selectedUploadedFiles = <FFUploadedFile>[];

                              var downloadUrls = <String>[];
                              try {
                                showUploadMessage(
                                  context,
                                  'Uploading file...',
                                  showLoading: true,
                                );
                                selectedUploadedFiles = selectedMedia
                                    .map((m) => FFUploadedFile(
                                          name: m.storagePath.split('/').last,
                                          bytes: m.bytes,
                                          height: m.dimensions?.height,
                                          width: m.dimensions?.width,
                                          blurHash: m.blurHash,
                                        ))
                                    .toList();

                                downloadUrls = (await Future.wait(
                                  selectedMedia.map(
                                    (m) async => await uploadData(
                                        m.storagePath, m.bytes),
                                  ),
                                ))
                                    .where((u) => u != null)
                                    .map((u) => u!)
                                    .toList();
                              } finally {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                _model.isDataUploading = false;
                              }
                              if (selectedUploadedFiles.length ==
                                      selectedMedia.length &&
                                  downloadUrls.length == selectedMedia.length) {
                                safeSetState(() {
                                  _model.uploadedLocalFile =
                                      selectedUploadedFiles.first;
                                  _model.uploadedFileUrl = downloadUrls.first;
                                });
                                showUploadMessage(context, 'Success!');
                              } else {
                                safeSetState(() {});
                                showUploadMessage(
                                    context, 'Failed to upload data');
                                return;
                              }
                            }

                            await currentUserReference!
                                .update(createUsersRecordData(
                              visionURL: _model.uploadedFileUrl,
                            ));
                          },
                          child: Icon(
                            Icons.add,
                            color: FlutterFlowTheme.of(context).tertiary,
                            size: 15.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AuthUserStreamWidget(
                    builder: (context) => Container(
                      width: MediaQuery.sizeOf(context).width * 0.96,
                      height: 300.0,
                      decoration: BoxDecoration(
                        color: Color(0xFF111111),
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: Image.network(
                            valueOrDefault(currentUserDocument?.visionURL, ''),
                          ).image,
                        ),
                        borderRadius: BorderRadius.circular(20.0),
                        shape: BoxShape.rectangle,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.0),
                          child: Image.network(
                            valueOrDefault(currentUserDocument?.visionURL, ''),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 0.0),
                    child: SingleChildScrollView(
                      primary: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: MediaQuery.sizeOf(context).width * 0.96,
                            decoration: BoxDecoration(
                              color: Color(0xFF0A0A0A),
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).accent1,
                                width: 1.0,
                              ),
                            ),
                            child: Align(
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    20.0, 50.0, 20.0, 50.0),
                                child: SelectionArea(
                                    child: Text(
                                  valueOrDefault<String>(
                                    OpenAIAPIGroup.createChatCompletionCall
                                        .resText(
                                      (_model.openaiRes?.jsonBody ?? ''),
                                    ),
                                    'The result will be shown here',
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Poppins',
                                        color: FlutterFlowTheme.of(context)
                                            .tertiary,
                                        letterSpacing: 0.0,
                                      ),
                                )),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 0.0,
                    height: 0.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                    ),
                    child: Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(8.0, 50.0, 8.0, 0.0),
                      child: AuthUserStreamWidget(
                        builder: (context) => Container(
                          width: MediaQuery.sizeOf(context).width * 0.96,
                          child: TextFormField(
                            controller: _model.alwayspopulatedTextController,
                            focusNode: _model.alwayspopulatedFocusNode,
                            autofocus: false,
                            obscureText: false,
                            decoration: InputDecoration(
                              labelStyle: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .override(
                                    fontFamily: 'Poppins',
                                    color: FlutterFlowTheme.of(context).accent1,
                                    letterSpacing: 0.0,
                                  ),
                              hintStyle: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .override(
                                    fontFamily: 'Poppins',
                                    letterSpacing: 0.0,
                                  ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).accent1,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).error,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).error,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Poppins',
                                  color: FlutterFlowTheme.of(context).tertiary,
                                  letterSpacing: 0.0,
                                ),
                            keyboardType: TextInputType.multiline,
                            validator: _model
                                .alwayspopulatedTextControllerValidator
                                .asValidator(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Stack(
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            0.0, 40.0, 0.0, 70.0),
                        child: FFButtonWidget(
                          onPressed: () async {
                            await currentUserReference!.update({
                              ...mapToFirestore(
                                {
                                  'visionButton': FieldValue.increment(1),
                                },
                              ),
                            });
                            _model.openaiRes = await OpenAIAPIGroup
                                .createChatCompletionCall
                                .call(
                              query:
                                  '${_model.alwayspopulatedTextController.text}',
                              imagePath: valueOrDefault(
                                  currentUserDocument?.visionURL, ''),
                              assistantId: FFAppState().assistantId,
                            );

                            if ((_model.openaiRes?.succeeded ?? true)) {
                              FFAppState().query =
                                  _model.alwayspopulatedTextController.text;
                              FFAppState().imageURL = _model.uploadedFileUrl;
                              FFAppState().chatHistoryAPP = OpenAIAPIGroup
                                  .createChatCompletionCall
                                  .resText(
                                (_model.openaiRes?.jsonBody ?? ''),
                              )!;
                              FFAppState().assistantVisionID =
                                  FFAppState().assistantId;
                              safeSetState(() {});
                            }

                            safeSetState(() {});
                          },
                          text: FFLocalizations.of(context).getText(
                            'ge87albk' /* Scan */,
                          ),
                          options: FFButtonOptions(
                            width: MediaQuery.sizeOf(context).width * 0.8,
                            height: 50.0,
                            padding: EdgeInsetsDirectional.fromSTEB(
                                24.0, 0.0, 24.0, 0.0),
                            iconPadding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 0.0),
                            color: FlutterFlowTheme.of(context).tertiary,
                            textStyle: FlutterFlowTheme.of(context)
                                .titleSmall
                                .override(
                                  fontFamily: 'Poppins',
                                  color: Color(0xFF0A0A0A),
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                ),
                            elevation: 3.0,
                            borderSide: BorderSide(
                              color: Colors.transparent,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
