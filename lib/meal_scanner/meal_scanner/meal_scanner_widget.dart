import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/gemini/gemini.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'meal_scanner_model.dart';
export 'meal_scanner_model.dart';

class MealScannerWidget extends StatefulWidget {
  const MealScannerWidget({
    super.key,
    this.mealRef,
  });

  final DocumentReference? mealRef;

  static String routeName = 'mealScanner';
  static String routePath = 'mealScanner';

  @override
  State<MealScannerWidget> createState() => _MealScannerWidgetState();
}

class _MealScannerWidgetState extends State<MealScannerWidget> {
  late MealScannerModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MealScannerModel());

    _model.foodItemsTextController ??= TextEditingController();
    _model.foodItemsFocusNode ??= FocusNode();

    _model.portionSizesTextController ??= TextEditingController();
    _model.portionSizesFocusNode ??= FocusNode();

    _model.cookingMethodsTextController ??= TextEditingController();
    _model.cookingMethodsFocusNode ??= FocusNode();

    _model.ingredientDetailsTextController ??= TextEditingController();
    _model.ingredientDetailsFocusNode ??= FocusNode();

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
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            final _datePickedDate = await showDatePicker(
                              context: context,
                              initialDate: getCurrentTimestamp,
                              firstDate: getCurrentTimestamp,
                              lastDate: DateTime(2050),
                              builder: (context, child) {
                                return wrapInMaterialDatePickerTheme(
                                  context,
                                  child!,
                                  headerBackgroundColor:
                                      FlutterFlowTheme.of(context).secondary,
                                  headerForegroundColor:
                                      FlutterFlowTheme.of(context).tertiary,
                                  headerTextStyle: FlutterFlowTheme.of(context)
                                      .headlineLarge
                                      .override(
                                        fontFamily: 'Poppins',
                                        fontSize: 32.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                  pickerBackgroundColor:
                                      FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                  pickerForegroundColor:
                                      FlutterFlowTheme.of(context).tertiary,
                                  selectedDateTimeBackgroundColor:
                                      FlutterFlowTheme.of(context).tertiary,
                                  selectedDateTimeForegroundColor:
                                      FlutterFlowTheme.of(context).secondary,
                                  actionButtonForegroundColor:
                                      FlutterFlowTheme.of(context).secondary,
                                  iconSize: 24.0,
                                );
                              },
                            );

                            if (_datePickedDate != null) {
                              safeSetState(() {
                                _model.datePicked = DateTime(
                                  _datePickedDate.year,
                                  _datePickedDate.month,
                                  _datePickedDate.day,
                                );
                              });
                            } else if (_model.datePicked != null) {
                              safeSetState(() {
                                _model.datePicked = getCurrentTimestamp;
                              });
                            }
                          },
                          child: Text(
                            FFLocalizations.of(context).getText(
                              'cr1u611p' /* Meal scanner */,
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
                        ),
                        Stack(
                          children: [
                            if ((_model.uploadedLocalFile.bytes?.isEmpty ??
                                    true))
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
                                      selectedMedia.every((m) =>
                                          validateFileFormat(
                                              m.storagePath, context))) {
                                    safeSetState(
                                        () => _model.isDataUploading = true);
                                    var selectedUploadedFiles =
                                        <FFUploadedFile>[];

                                    try {
                                      showUploadMessage(
                                        context,
                                        'Uploading file...',
                                        showLoading: true,
                                      );
                                      selectedUploadedFiles = selectedMedia
                                          .map((m) => FFUploadedFile(
                                                name: m.storagePath
                                                    .split('/')
                                                    .last,
                                                bytes: m.bytes,
                                                height: m.dimensions?.height,
                                                width: m.dimensions?.width,
                                                blurHash: m.blurHash,
                                              ))
                                          .toList();
                                    } finally {
                                      ScaffoldMessenger.of(context)
                                          .hideCurrentSnackBar();
                                      _model.isDataUploading = false;
                                    }
                                    if (selectedUploadedFiles.length ==
                                        selectedMedia.length) {
                                      safeSetState(() {
                                        _model.uploadedLocalFile =
                                            selectedUploadedFiles.first;
                                      });
                                      showUploadMessage(context, 'Success!');
                                    } else {
                                      safeSetState(() {});
                                      showUploadMessage(
                                          context, 'Failed to upload data');
                                      return;
                                    }
                                  }
                                },
                                child: Icon(
                                  Icons.add,
                                  color: FlutterFlowTheme.of(context).tertiary,
                                  size: 15.0,
                                ),
                              ),
                            if ((_model.uploadedLocalFile.bytes?.isNotEmpty ??
                                    false))
                              InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  safeSetState(() {
                                    _model.isDataUploading = false;
                                    _model.uploadedLocalFile = FFUploadedFile(
                                        bytes: Uint8List.fromList([]));
                                  });
                                },
                                child: Icon(
                                  Icons.close,
                                  color: FlutterFlowTheme.of(context).tertiary,
                                  size: 15.0,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: MediaQuery.sizeOf(context).width * 0.96,
                    height: 300.0,
                    decoration: BoxDecoration(
                      color: Color(0xFF111111),
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: Image.network(
                          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHNlYXJjaHwzfHxmb29kfGVufDB8fHx8MTc0MDEzNjg3MXww&ixlib=rb-4.0.3&q=80&w=1080',
                        ).image,
                      ),
                      borderRadius: BorderRadius.circular(20.0),
                      shape: BoxShape.rectangle,
                    ),
                    child: Visibility(
                      visible: (_model.uploadedLocalFile.bytes?.isNotEmpty ?? false),
                      child: Align(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.0),
                          child: Image.memory(
                            _model.uploadedLocalFile.bytes ??
                                Uint8List.fromList([]),
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
                        EdgeInsetsDirectional.fromSTEB(8.0, 50.0, 8.0, 0.0),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 0.96,
                      child: TextFormField(
                        controller: _model.foodItemsTextController,
                        focusNode: _model.foodItemsFocusNode,
                        autofocus: false,
                        obscureText: false,
                        decoration: InputDecoration(
                          labelText: FFLocalizations.of(context).getText(
                            '2mq61r5h' /*  Food Items, list all of the f... */,
                          ),
                          labelStyle:
                              FlutterFlowTheme.of(context).labelMedium.override(
                                    fontFamily: 'Poppins',
                                    color: FlutterFlowTheme.of(context).accent1,
                                    letterSpacing: 0.0,
                                  ),
                          hintStyle:
                              FlutterFlowTheme.of(context).labelMedium.override(
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
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Poppins',
                              color: FlutterFlowTheme.of(context).tertiary,
                              letterSpacing: 0.0,
                            ),
                        keyboardType: TextInputType.multiline,
                        validator: _model.foodItemsTextControllerValidator
                            .asValidator(context),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(8.0, 50.0, 8.0, 0.0),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 0.96,
                      child: TextFormField(
                        controller: _model.portionSizesTextController,
                        focusNode: _model.portionSizesFocusNode,
                        autofocus: false,
                        obscureText: false,
                        decoration: InputDecoration(
                          labelText: FFLocalizations.of(context).getText(
                            '139rnpy6' /* Portion Sizes */,
                          ),
                          labelStyle:
                              FlutterFlowTheme.of(context).labelMedium.override(
                                    fontFamily: 'Poppins',
                                    color: FlutterFlowTheme.of(context).accent1,
                                    letterSpacing: 0.0,
                                  ),
                          hintStyle:
                              FlutterFlowTheme.of(context).labelMedium.override(
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
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Poppins',
                              color: FlutterFlowTheme.of(context).tertiary,
                              letterSpacing: 0.0,
                            ),
                        keyboardType: TextInputType.multiline,
                        validator: _model.portionSizesTextControllerValidator
                            .asValidator(context),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(8.0, 50.0, 8.0, 0.0),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 0.96,
                      child: TextFormField(
                        controller: _model.cookingMethodsTextController,
                        focusNode: _model.cookingMethodsFocusNode,
                        autofocus: false,
                        obscureText: false,
                        decoration: InputDecoration(
                          labelText: FFLocalizations.of(context).getText(
                            'pvpkpamp' /* Cooking Methods */,
                          ),
                          labelStyle:
                              FlutterFlowTheme.of(context).labelMedium.override(
                                    fontFamily: 'Poppins',
                                    color: FlutterFlowTheme.of(context).accent1,
                                    letterSpacing: 0.0,
                                  ),
                          hintStyle:
                              FlutterFlowTheme.of(context).labelMedium.override(
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
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Poppins',
                              color: FlutterFlowTheme.of(context).tertiary,
                              letterSpacing: 0.0,
                            ),
                        keyboardType: TextInputType.multiline,
                        validator: _model.cookingMethodsTextControllerValidator
                            .asValidator(context),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(8.0, 50.0, 8.0, 0.0),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 0.96,
                      child: TextFormField(
                        controller: _model.ingredientDetailsTextController,
                        focusNode: _model.ingredientDetailsFocusNode,
                        autofocus: false,
                        obscureText: false,
                        decoration: InputDecoration(
                          labelText: FFLocalizations.of(context).getText(
                            'l7oe8vo9' /* Ingredient Details */,
                          ),
                          labelStyle:
                              FlutterFlowTheme.of(context).labelMedium.override(
                                    fontFamily: 'Poppins',
                                    color: FlutterFlowTheme.of(context).accent1,
                                    letterSpacing: 0.0,
                                  ),
                          hintStyle:
                              FlutterFlowTheme.of(context).labelMedium.override(
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
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Poppins',
                              color: FlutterFlowTheme.of(context).tertiary,
                              letterSpacing: 0.0,
                            ),
                        keyboardType: TextInputType.multiline,
                        validator: _model
                            .ingredientDetailsTextControllerValidator
                            .asValidator(context),
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
                            await geminiTextFromImage(
                              context,
                              'Important Instructions: Always return the following structured response for every food or drink image: Name of the dish: (If you do not know the name of the dish just guess dont make it too long) Carbs: (Only a whole number, e.g., 45. Do not include text, ranges, or units.) Fats: (Only a whole number, e.g., 12. Do not include text, ranges, or units.) Kcal: (Only a whole number, e.g., 350. Do not include text, ranges, or units.) Protein: (Only a whole number, e.g., 25. Do not include text, ranges, or units.) Description: (Detailed breakdown of the food or drink, including preparation method, ingredients, portion size, and notable nutritional factors.) Strictly prohibit any text, ranges (e.g., \"500-700\"), or descriptors (e.g., \"High,\" \"Moderate,\" \"Approximately\"). Only return whole numbers. If someone asks if you are Gemini or related to an open-source model, always respond with: \"I am a representative of GymFeed here to help you with any meal or fitness-related question you have.\" Answer the question only if the image contains food or drinks. If the image contains anything else, respond with: \"We cannot scan this image as it does not contain food or drinks.\"  Take into account the information about the food or drink listed bellow:Food Items:${_model.foodItemsTextController.text} Portion size: ${_model.portionSizesTextController.text} Cooking Methods: ${_model.cookingMethodsTextController.text} Ingredient Details: ${_model.ingredientDetailsTextController.text}',
                              uploadImageBytes: _model.uploadedLocalFile,
                            ).then((generatedText) {
                              safeSetState(
                                  () => _model.geminiOutput = generatedText);
                            });

                            var mealScannerRecordReference =
                                MealScannerRecord.collection.doc();
                            await mealScannerRecordReference
                                .set(createMealScannerRecordData(
                              mealScannerUser: currentUserReference,
                              geminiParse: _model.geminiOutput,
                            ));
                            _model.mealdocument =
                                MealScannerRecord.getDocumentFromData(
                                    createMealScannerRecordData(
                                      mealScannerUser: currentUserReference,
                                      geminiParse: _model.geminiOutput,
                                    ),
                                    mealScannerRecordReference);
                            _model.fatsScanner = await actions.fatsScanner2(
                              _model.mealdocument?.geminiParse,
                            );
                            _model.dishName = await actions.dishNameScanner(
                              _model.mealdocument?.geminiParse,
                            );
                            _model.carbsScanner = await actions.carbsScanner(
                              _model.geminiOutput,
                            );
                            _model.proteinScanner =
                                await actions.proteinScanner(
                              _model.mealdocument?.geminiParse,
                            );
                            _model.caloriesScanner =
                                await actions.caloriesScanner(
                              _model.mealdocument?.geminiParse,
                            );
                            _model.descriptionScanner =
                                await actions.descriptionScanner(
                              _model.mealdocument?.geminiParse,
                            );

                            await currentUserReference!
                                .update(createUsersRecordData(
                              carbsScanner: _model.carbsScanner,
                              fatsScanner: _model.fatsScanner,
                              caloriesScanner: _model.caloriesScanner,
                              proteinScanner: _model.proteinScanner,
                              descriptionScanner: _model.descriptionScanner,
                            ));

                            await _model.mealdocument!.reference
                                .update(createMealScannerRecordData(
                              protein: _model.proteinScanner,
                              carbs: _model.carbsScanner,
                              fats: _model.fatsScanner,
                              calories: _model.caloriesScanner,
                              description: _model.descriptionScanner,
                              dishName: _model.dishName,
                            ));

                            context.pushNamed(
                              AddingMealsWidget.routeName,
                              queryParameters: {
                                'mealRef': serializeParam(
                                  _model.mealdocument,
                                  ParamType.Document,
                                ),
                              }.withoutNulls,
                              extra: <String, dynamic>{
                                'mealRef': _model.mealdocument,
                              },
                            );

                            safeSetState(() {});
                          },
                          text: FFLocalizations.of(context).getText(
                            'batt9it6' /* Scan */,
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
