import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/reportdialog/reportdialog_widget.dart';
import '/flutter_flow/flutter_flow_radio_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'package:flutter/material.dart';
import 'report_status_food_model.dart';
export 'report_status_food_model.dart';

class ReportStatusFoodWidget extends StatefulWidget {
  const ReportStatusFoodWidget({
    super.key,
    required this.userRecod,
    required this.postReference,
  });

  final UsersRecord? userRecod;
  final DocumentReference? postReference;

  @override
  State<ReportStatusFoodWidget> createState() => _ReportStatusFoodWidgetState();
}

class _ReportStatusFoodWidgetState extends State<ReportStatusFoodWidget> {
  late ReportStatusFoodModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ReportStatusFoodModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width * 1.0,
      height: MediaQuery.sizeOf(context).height * 1.0,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0.0),
          bottomRight: Radius.circular(0.0),
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 0.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(10.0, 0.0, 0.0, 0.0),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        context.safePop();
                      },
                      child: Icon(
                        Icons.chevron_left,
                        color: FlutterFlowTheme.of(context).tertiary,
                        size: 25.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 0.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    width: MediaQuery.sizeOf(context).width * 0.9,
                    height: MediaQuery.sizeOf(context).height * 1.0,
                    decoration: BoxDecoration(),
                    child: FlutterFlowRadioButton(
                      options: [
                        FFLocalizations.of(context).getText(
                          'hrs0x28a' /* I just dont like it */,
                        ),
                        FFLocalizations.of(context).getText(
                          'b2xd59wf' /* This is spaming me */,
                        ),
                        FFLocalizations.of(context).getText(
                          'zeqebbvc' /* Nudity or sexual activity */,
                        ),
                        FFLocalizations.of(context).getText(
                          '2rochx8w' /* Hate speech or symbols */,
                        ),
                        FFLocalizations.of(context).getText(
                          's480w05z' /* Violence or dangerous organiza... */,
                        ),
                        FFLocalizations.of(context).getText(
                          'cyaqx1fk' /* False information */,
                        ),
                        FFLocalizations.of(context).getText(
                          'b31qm3mt' /* Bullying or harassment */,
                        ),
                        FFLocalizations.of(context).getText(
                          '4wj297ok' /* Scam or fraud */,
                        ),
                        FFLocalizations.of(context).getText(
                          '1nttwdgn' /* Suicide or self-injury */,
                        ),
                        FFLocalizations.of(context).getText(
                          '7na8wngz' /* Sale of illegal or regulated g... */,
                        ),
                        FFLocalizations.of(context).getText(
                          's1ftjzmm' /* Intellectual property violatio... */,
                        ),
                        FFLocalizations.of(context).getText(
                          '9gdch31p' /* Eating disorders */,
                        ),
                        FFLocalizations.of(context).getText(
                          'jsale30d' /* Drugs */,
                        ),
                        FFLocalizations.of(context).getText(
                          'jmjnm9sa' /* Something else */,
                        )
                      ].toList(),
                      onChanged: (val) => safeSetState(() {}),
                      controller: _model.radioButtonValueController ??=
                          FormFieldController<String>(null),
                      optionHeight: 32.0,
                      textStyle:
                          FlutterFlowTheme.of(context).labelMedium.override(
                                fontFamily: 'Poppins',
                                letterSpacing: 0.0,
                              ),
                      selectedTextStyle:
                          FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'Poppins',
                                letterSpacing: 0.0,
                              ),
                      buttonPosition: RadioButtonPosition.left,
                      direction: Axis.vertical,
                      radioButtonColor: FlutterFlowTheme.of(context).error,
                      inactiveRadioButtonColor:
                          FlutterFlowTheme.of(context).secondaryText,
                      toggleable: false,
                      horizontalAlignment: WrapAlignment.start,
                      verticalAlignment: WrapCrossAlignment.start,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 50.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FFButtonWidget(
                    onPressed: () async {
                      await ReportsRecord.collection
                          .doc()
                          .set(createReportsRecordData(
                            userID: currentUserReference?.id,
                            postRef: widget.postReference?.id,
                            timeOfReport: getCurrentTimestamp,
                            details: _model.radioButtonValue,
                          ));
                      await showModalBottomSheet(
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        enableDrag: false,
                        context: context,
                        builder: (context) {
                          return Padding(
                            padding: MediaQuery.viewInsetsOf(context),
                            child: Container(
                              height: MediaQuery.sizeOf(context).height * 0.5,
                              child: ReportdialogWidget(
                                userRef: widget.userRecod!,
                              ),
                            ),
                          );
                        },
                      ).then((value) => safeSetState(() {}));
                    },
                    text: FFLocalizations.of(context).getText(
                      'ubkp7pe3' /* Submit report */,
                    ),
                    options: FFButtonOptions(
                      width: 200.0,
                      height: 55.0,
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      iconPadding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      color: FlutterFlowTheme.of(context).error,
                      textStyle:
                          FlutterFlowTheme.of(context).bodySmall.override(
                                fontFamily: 'Lexend Deca',
                                color: FlutterFlowTheme.of(context).tertiary,
                                fontSize: 14.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.normal,
                              ),
                      elevation: 3.0,
                      borderSide: BorderSide(
                        color: Colors.transparent,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
