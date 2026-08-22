import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/flutter_flow/flutter_flow_media_display.dart';
import '/flutter_flow/flutter_flow_place_picker.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_video_player.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import '/custom_code/widgets/create_ui.dart';
import '/custom_code/widgets/upload_progress_screen.dart';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'schedule_training_model.dart';
import 'workout_location_picker.dart';
export 'schedule_training_model.dart';

class ScheduleTrainingWidget extends StatefulWidget {
  const ScheduleTrainingWidget({super.key});

  static String routeName = 'ScheduleTraining';
  static String routePath = 'scheduleTraining';

  @override
  State<ScheduleTrainingWidget> createState() => _ScheduleTrainingWidgetState();
}

class _ScheduleTrainingWidgetState extends State<ScheduleTrainingWidget>
    with TickerProviderStateMixin {
  late ScheduleTrainingModel _model;
  double? _coverProgress;
  double? _videoProgress;
  bool _scheduling = false;
  bool _showLegacyWorkoutMedia = false;
  String? _videoAssetId;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ScheduleTrainingModel());

    _model.tabBarController = TabController(
      vsync: this,
      length: 3,
      initialIndex: 0,
    )..addListener(() => safeSetState(() {}));
    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();

    _model.textController3 ??= TextEditingController();
    _model.textFieldFocusNode3 ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _pickCover() async {
    if (_coverProgress != null) return;
    setState(() => _coverProgress = .08);
    try {
      final path = await actions.pickImage();
      if (path == null || path.isEmpty) return;
      _model.pickImage = path;
      if (mounted) setState(() => _coverProgress = .25);
      final compressed = await actions.compressImage(path);
      if (compressed?.bytes == null || compressed!.bytes!.isEmpty) {
        throw StateError('The cover could not be compressed.');
      }
      if (compressed.bytes!.length > 10 * 1024 * 1024) {
        throw StateError('The cover must be 10 MB or smaller.');
      }
      _model.compressImage = compressed;
      if (mounted) setState(() => _coverProgress = .62);
      final selected = selectedFilesFromUploadedFiles([compressed]).first;
      final url = await uploadData(selected.storagePath, selected.bytes);
      if (url == null || url.isEmpty) {
        throw StateError('The cover could not be uploaded.');
      }
      if (!mounted) return;
      setState(() {
        _model.uploadedLocalFile1 = compressed;
        _model.uploadedFileUrl1 = url;
        _coverProgress = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _coverProgress = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cover was not added: $error')),
      );
    } finally {
      if (mounted && _coverProgress != null) {
        setState(() => _coverProgress = null);
      }
    }
  }

  Future<void> _pickWorkoutVideo() async {
    if (_videoProgress != null) return;
    setState(() => _videoProgress = .08);
    try {
      final compressed = await actions.pickAndPrepareVideo();
      if (compressed?.bytes == null || compressed!.bytes!.isEmpty) {
        return;
      }
      _model.compressVideo = compressed;
      if (mounted) setState(() => _videoProgress = .35);
      final upload = await showUploadProgress(
        context,
        videoBytes: compressed.bytes!,
        videoTitle: _model.textController1.text.trim().isEmpty
            ? 'GymFeed workout video'
            : _model.textController1.text.trim(),
        videoFileName: compressed.name ?? 'gymfeed-workout-video.mp4',
      );
      final url = upload?.videoPlaylistUrl;
      if (url == null || url.isEmpty || upload?.videoAssetId == null) {
        throw StateError('The video could not be uploaded.');
      }
      if (!mounted) return;
      setState(() {
        _model.uploadedLocalFile2 = compressed;
        _model.uploadedFileUrl2 = url;
        _videoAssetId = upload!.videoAssetId;
        _videoProgress = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _videoProgress = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video was not added: $error')),
      );
    } finally {
      if (mounted && _videoProgress != null) {
        setState(() => _videoProgress = null);
      }
    }
  }

  Future<void> _scheduleTraining() async {
    if (_scheduling) return;
    final title = _model.textController1.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give this workout a name.')),
      );
      _model.tabBarController?.animateTo(0);
      return;
    }
    if (_model.dropDownValue == null || _model.dropDownValue!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a workout category.')),
      );
      _model.tabBarController?.animateTo(0);
      return;
    }
    if (_model.datePicked2 == null || _model.datePicked1 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a date and start time.')),
      );
      _model.tabBarController?.animateTo(0);
      return;
    }
    if (_model.uploadedFileUrl1.isEmpty && _model.uploadedFileUrl2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a cover or workout video first.')),
      );
      return;
    }
    final selectedDate = _model.datePicked2!;
    final selectedTime = _model.datePicked1!;
    final startsAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    final pickedLocation = _model.placePickerValue;
    final hasLocation = pickedLocation.address.trim().isNotEmpty &&
        !(pickedLocation.latLng.latitude == 0 &&
            pickedLocation.latLng.longitude == 0);
    setState(() => _scheduling = true);
    try {
      await createTrainingSupabase(
        trainingDateRaw: dateTimeFormat(
          'yMMMd',
          _model.datePicked2,
          locale: FFLocalizations.of(context).languageCode,
        ),
        trainingTimeRaw: dateTimeFormat(
          'jm',
          _model.datePicked1,
          locale: FFLocalizations.of(context).languageCode,
        ),
        title: title,
        category: _model.dropDownValue,
        videoUrl: _model.uploadedFileUrl2,
        videoAssetId: _videoAssetId,
        description: _model.textController2.text,
        duration: int.tryParse(_model.textController3.text),
        location: hasLocation ? pickedLocation.latLng : null,
        backgroundImage: _model.uploadedFileUrl1,
        difficultyLevel: _model.dificultLevelValue,
        startsAt: startsAt,
      );
      if (!mounted) return;
      context.goNamed(CoachEventsWidget.routeName);
    } catch (error) {
      if (!mounted) return;
      setState(() => _scheduling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Training was not scheduled: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showLegacyWorkoutMedia) {
      return _buildModernWorkoutCreator(context);
    }
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 0.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(10.0, 15.0, 0.0, 0.0),
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
                        'Create workout',
                        style: FlutterFlowTheme.of(context)
                            .headlineMedium
                            .override(
                              fontFamily: 'Poppins',
                              fontSize: 15.0,
                              letterSpacing: 0.0,
                            ),
                      ),
                      Opacity(
                        opacity: 0.0,
                        child: Icon(
                          Icons.settings_outlined,
                          color: FlutterFlowTheme.of(context).secondaryText,
                          size: 24.0,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment(0.0, 0),
                        child: TabBar(
                          labelColor: FlutterFlowTheme.of(context).tertiary,
                          unselectedLabelColor:
                              FlutterFlowTheme.of(context).secondaryText,
                          labelStyle: FlutterFlowTheme.of(context)
                              .headlineMedium
                              .override(
                                fontFamily: 'Outfit',
                                fontSize: 14.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.normal,
                              ),
                          unselectedLabelStyle: TextStyle(),
                          indicatorColor: FlutterFlowTheme.of(context).primary,
                          padding: EdgeInsetsDirectional.fromSTEB(
                              30.0, 0.0, 30.0, 0.0),
                          tabs: [
                            Tab(
                              text: 'Training info',
                            ),
                            Tab(
                              text: 'Cover image',
                            ),
                            Tab(
                              text: 'Video',
                            ),
                          ],
                          controller: _model.tabBarController,
                          onTap: (i) async {
                            [() async {}, () async {}, () async {}][i]();
                          },
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _model.tabBarController,
                          children: [
                            SingleChildScrollView(
                              primary: false,
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        10.0, 10.0, 10.0, 10.0),
                                    child: Container(
                                      width: MediaQuery.sizeOf(context).width *
                                          1.0,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF0A0A0A),
                                        border: Border.all(
                                          color: Color(0xFF0A0A0A),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            10.0, 10.0, 10.0, 10.0),
                                        child: Form(
                                          key: _model.formKey,
                                          autovalidateMode:
                                              AutovalidateMode.disabled,
                                          child: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 0.0, 0.0, 10.0),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: [
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          Text(
                                                            FFLocalizations.of(
                                                                    context)
                                                                .getText(
                                                              'uan6ha7i' /* Trainer Name */,
                                                            ),
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'Poppins',
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .accent1,
                                                                  letterSpacing:
                                                                      0.0,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          AuthUserStreamWidget(
                                                            builder:
                                                                (context) =>
                                                                    Text(
                                                              currentUserDisplayName,
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'Poppins',
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .tertiary,
                                                                    letterSpacing:
                                                                        0.0,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 0.0, 0.0, 10.0),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: [
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          Expanded(
                                                            child:
                                                                TextFormField(
                                                              controller: _model
                                                                  .textController1,
                                                              focusNode: _model
                                                                  .textFieldFocusNode1,
                                                              autofocus: false,
                                                              obscureText:
                                                                  false,
                                                              decoration:
                                                                  createInputDecoration(
                                                                context,
                                                                hintText:
                                                                    FFLocalizations.of(
                                                                            context)
                                                                        .getText(
                                                                  'r1wlj3eb' /* Training Title */,
                                                                ),
                                                              ),
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'Poppins',
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .tertiary,
                                                                    fontSize:
                                                                        12.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                  ),
                                                              maxLines: 2,
                                                              minLines: 1,
                                                              validator: _model
                                                                  .textController1Validator
                                                                  .asValidator(
                                                                      context),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsetsDirectional
                                                          .fromSTEB(
                                                          0.0, 0.0, 0.0, 4.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      createSectionLabel(
                                                          context, 'Location'),
                                                      FlutterFlowPlacePicker(
                                                        iOSGoogleMapsApiKey:
                                                            'AIzaSyAhiNjvBpWvH1VVuoRGU5J3WnjVPFIzkE4',
                                                        androidGoogleMapsApiKey:
                                                            'AIzaSyD60h9pruOAaVuyPzjCD5Cg3fxemawEUpg',
                                                        webGoogleMapsApiKey:
                                                            'AIzaSyBaAKbRwjQpBxUxfa46HZYGwxPTwpXqy4g',
                                                        onSelect:
                                                            (place) async {
                                                          safeSetState(() =>
                                                              _model.placePickerValue =
                                                                  place);
                                                        },
                                                        defaultText: _model
                                                                .placePickerValue
                                                                .address
                                                                .isNotEmpty
                                                            ? _model
                                                                .placePickerValue
                                                                .address
                                                            : 'Select location',
                                                        icon: Icon(
                                                          Icons.place,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primary,
                                                          size: 18.0,
                                                        ),
                                                        buttonOptions:
                                                            FFButtonOptions(
                                                          width:
                                                              double.infinity,
                                                          height: 52.0,
                                                          color: kCreateSurface,
                                                          textStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'Poppins',
                                                                    color: _model
                                                                            .placePickerValue
                                                                            .address
                                                                            .isNotEmpty
                                                                        ? FlutterFlowTheme.of(context)
                                                                            .tertiary
                                                                        : kCreateHint,
                                                                    fontSize:
                                                                        14.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal,
                                                                  ),
                                                          elevation: 0.0,
                                                          borderSide:
                                                              const BorderSide(
                                                                  color:
                                                                      kCreateStroke,
                                                                  width: 1.0),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  kCreateFieldRadius),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsetsDirectional
                                                          .fromSTEB(
                                                          0.0, 0.0, 0.0, 4.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      createSectionLabel(
                                                          context, 'Time'),
                                                      createTapField(
                                                        context,
                                                        text:
                                                            _model.datePicked1 ==
                                                                    null
                                                                ? 'Select time'
                                                                : dateTimeFormat(
                                                                    "jm",
                                                                    _model
                                                                        .datePicked1,
                                                                    locale: FFLocalizations.of(
                                                                            context)
                                                                        .languageCode,
                                                                  ),
                                                        filled: _model
                                                                .datePicked1 !=
                                                            null,
                                                        icon: Icons
                                                            .access_time_rounded,
                                                        onTap: () async {
                                                          final _datePicked1Time =
                                                              await showTimePicker(
                                                            context: context,
                                                            initialTime: TimeOfDay
                                                                .fromDateTime(
                                                                    getCurrentTimestamp),
                                                          );
                                                          if (_datePicked1Time !=
                                                              null) {
                                                            safeSetState(() {
                                                              _model.datePicked1 =
                                                                  DateTime(
                                                                getCurrentTimestamp
                                                                    .year,
                                                                getCurrentTimestamp
                                                                    .month,
                                                                getCurrentTimestamp
                                                                    .day,
                                                                _datePicked1Time
                                                                    .hour,
                                                                _datePicked1Time
                                                                    .minute,
                                                              );
                                                            });
                                                          } else if (_model
                                                                  .datePicked1 !=
                                                              null) {
                                                            safeSetState(() {
                                                              _model.datePicked1 =
                                                                  getCurrentTimestamp;
                                                            });
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsetsDirectional
                                                          .fromSTEB(
                                                          0.0, 0.0, 0.0, 4.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      createSectionLabel(
                                                          context, 'Date'),
                                                      createTapField(
                                                        context,
                                                        text:
                                                            _model.datePicked2 ==
                                                                    null
                                                                ? 'Select date'
                                                                : dateTimeFormat(
                                                                    "yMd",
                                                                    _model
                                                                        .datePicked2,
                                                                    locale: FFLocalizations.of(
                                                                            context)
                                                                        .languageCode,
                                                                  ),
                                                        filled: _model
                                                                .datePicked2 !=
                                                            null,
                                                        icon: Icons
                                                            .calendar_today_rounded,
                                                        onTap: () async {
                                                          final _datePicked2Date =
                                                              await showDatePicker(
                                                            context: context,
                                                            initialDate:
                                                                getCurrentTimestamp,
                                                            firstDate:
                                                                getCurrentTimestamp,
                                                            lastDate:
                                                                DateTime(2050),
                                                          );
                                                          if (_datePicked2Date !=
                                                              null) {
                                                            safeSetState(() {
                                                              _model.datePicked2 =
                                                                  DateTime(
                                                                _datePicked2Date
                                                                    .year,
                                                                _datePicked2Date
                                                                    .month,
                                                                _datePicked2Date
                                                                    .day,
                                                              );
                                                            });
                                                          } else if (_model
                                                                  .datePicked2 !=
                                                              null) {
                                                            safeSetState(() {
                                                              _model.datePicked2 =
                                                                  getCurrentTimestamp;
                                                            });
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 0.0, 0.0, 10.0),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: [
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          Expanded(
                                                            child: Container(
                                                              width: MediaQuery
                                                                          .sizeOf(
                                                                              context)
                                                                      .width *
                                                                  0.8,
                                                              child:
                                                                  TextFormField(
                                                                controller: _model
                                                                    .textController2,
                                                                focusNode: _model
                                                                    .textFieldFocusNode2,
                                                                onChanged: (_) =>
                                                                    EasyDebounce
                                                                        .debounce(
                                                                  '_model.textController2',
                                                                  Duration(
                                                                      milliseconds:
                                                                          2000),
                                                                  () =>
                                                                      safeSetState(
                                                                          () {}),
                                                                ),
                                                                autofocus:
                                                                    false,
                                                                obscureText:
                                                                    false,
                                                                decoration:
                                                                    createInputDecoration(
                                                                  context,
                                                                  hintText: FFLocalizations.of(
                                                                          context)
                                                                      .getText(
                                                                    '6no3imck' /*       Describe your training */,
                                                                  ),
                                                                ),
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .tertiary,
                                                                      letterSpacing:
                                                                          0.0,
                                                                    ),
                                                                maxLines: 10,
                                                                minLines: 1,
                                                                validator: _model
                                                                    .textController2Validator
                                                                    .asValidator(
                                                                        context),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 0.0, 0.0, 10.0),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: [
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                createSectionLabel(
                                                                    context,
                                                                    'Category'),
                                                                Wrap(
                                                                  spacing: 8.0,
                                                                  runSpacing:
                                                                      8.0,
                                                                  children: const [
                                                                    'Cardio',
                                                                    'Muscle Mass',
                                                                    'Calisthenics',
                                                                    'CrossFit',
                                                                    'Zumba',
                                                                    'Yoga',
                                                                  ]
                                                                      .map((c) => createChip(
                                                                            context,
                                                                            label:
                                                                                c,
                                                                            selected:
                                                                                _model.dropDownValue == c,
                                                                            onTap: () =>
                                                                                safeSetState(() => _model.dropDownValue = c),
                                                                          ))
                                                                      .toList(),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              createSectionLabel(
                                                                  context,
                                                                  'Level'),
                                                              Wrap(
                                                                spacing: 8.0,
                                                                runSpacing: 8.0,
                                                                children: const [
                                                                  'Beginner',
                                                                  'Intermediate',
                                                                  'Advanced',
                                                                ]
                                                                    .map((c) => createChip(
                                                                          context,
                                                                          label:
                                                                              c,
                                                                          selected:
                                                                              _model.dificultLevelValue == c,
                                                                          onTap: () =>
                                                                              safeSetState(() => _model.dificultLevelValue = c),
                                                                        ))
                                                                    .toList(),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 5.0, 0.0, 0.0),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: [
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          Expanded(
                                                            child: Container(
                                                              width: MediaQuery
                                                                          .sizeOf(
                                                                              context)
                                                                      .width *
                                                                  0.8,
                                                              child:
                                                                  TextFormField(
                                                                controller: _model
                                                                    .textController3,
                                                                focusNode: _model
                                                                    .textFieldFocusNode3,
                                                                onChanged: (_) =>
                                                                    EasyDebounce
                                                                        .debounce(
                                                                  '_model.textController3',
                                                                  Duration(
                                                                      milliseconds:
                                                                          2000),
                                                                  () =>
                                                                      safeSetState(
                                                                          () {}),
                                                                ),
                                                                autofocus:
                                                                    false,
                                                                obscureText:
                                                                    false,
                                                                decoration:
                                                                    createInputDecoration(
                                                                  context,
                                                                  hintText: FFLocalizations.of(
                                                                          context)
                                                                      .getText(
                                                                    'c66qd7yn' /*       Set duration in minutes */,
                                                                  ),
                                                                ),
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .tertiary,
                                                                      letterSpacing:
                                                                          0.0,
                                                                    ),
                                                                maxLines: 10,
                                                                minLines: 1,
                                                                validator: _model
                                                                    .textController3Validator
                                                                    .asValidator(
                                                                        context),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SingleChildScrollView(
                              primary: false,
                              child: !_showLegacyWorkoutMedia
                                  ? _WorkoutMediaPanel(
                                      video: false,
                                      mediaUrl: _model.uploadedFileUrl1,
                                      fileName:
                                          _model.uploadedLocalFile1.name ?? '',
                                      bytes: _model.uploadedLocalFile1.bytes
                                              ?.length ??
                                          0,
                                      progress: _coverProgress,
                                      onPick: _pickCover,
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Column(
                                                mainAxisSize: MainAxisSize.max,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Stack(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    0.0,
                                                                    20.0,
                                                                    0.0,
                                                                    12.0),
                                                        child: Container(
                                                          width:
                                                              MediaQuery.sizeOf(
                                                                          context)
                                                                      .width *
                                                                  0.96,
                                                          height: 300.0,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .tertiary,
                                                            image:
                                                                DecorationImage(
                                                              fit: BoxFit.fill,
                                                              image:
                                                                  Image.network(
                                                                _model
                                                                    .uploadedFileUrl1,
                                                              ).image,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20.0),
                                                            border: Border.all(
                                                              color: Color(
                                                                  0xFF0A0A0A),
                                                              width: 2.0,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Align(
                                                    alignment:
                                                        AlignmentDirectional(
                                                            0.0, 0.0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          FFLocalizations.of(
                                                                  context)
                                                              .getText(
                                                            '2enbpcg6' /* Upload cover image here */,
                                                          ),
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'Poppins',
                                                                letterSpacing:
                                                                    0.0,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 50.0,
                                                                0.0, 0.0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceAround,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Stack(
                                                          children: [
                                                            if (_model
                                                                    .uploadedFileUrl1 !=
                                                                '')
                                                              FFButtonWidget(
                                                                onPressed:
                                                                    () async {
                                                                  safeSetState(
                                                                      () {
                                                                    _model.isDataUploading1 =
                                                                        false;
                                                                    _model.uploadedLocalFile1 =
                                                                        FFUploadedFile(
                                                                            bytes:
                                                                                Uint8List.fromList([]));
                                                                    _model.uploadedFileUrl1 =
                                                                        '';
                                                                  });
                                                                },
                                                                text: FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  'o8iqzo0p' /* Delete photo */,
                                                                ),
                                                                options:
                                                                    FFButtonOptions(
                                                                  width: 150.0,
                                                                  height: 40.0,
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          24.0,
                                                                          0.0,
                                                                          24.0,
                                                                          0.0),
                                                                  iconPadding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          0.0),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .error,
                                                                  textStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmall
                                                                      .override(
                                                                        fontFamily:
                                                                            'Poppins',
                                                                        color: Color(
                                                                            0xFF0A0A0A),
                                                                        fontSize:
                                                                            15.0,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                  elevation:
                                                                      3.0,
                                                                  borderSide:
                                                                      BorderSide(
                                                                    color: Colors
                                                                        .transparent,
                                                                    width: 1.0,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              40.0),
                                                                ),
                                                              ),
                                                            if (_model
                                                                    .uploadedFileUrl1 ==
                                                                '')
                                                              FFButtonWidget(
                                                                onPressed:
                                                                    () async {
                                                                  _model.pickImage =
                                                                      await actions
                                                                          .pickImage();
                                                                  _model.compressImage =
                                                                      await actions
                                                                          .compressImage(
                                                                    _model
                                                                        .pickImage!,
                                                                  );
                                                                  {
                                                                    safeSetState(() =>
                                                                        _model.isDataUploading1 =
                                                                            true);
                                                                    var selectedUploadedFiles =
                                                                        <FFUploadedFile>[];
                                                                    var selectedMedia =
                                                                        <SelectedFile>[];
                                                                    var downloadUrls =
                                                                        <String>[];
                                                                    try {
                                                                      selectedUploadedFiles = _model
                                                                              .compressImage!
                                                                              .bytes!
                                                                              .isNotEmpty
                                                                          ? [
                                                                              _model.compressImage!
                                                                            ]
                                                                          : <FFUploadedFile>[];
                                                                      selectedMedia =
                                                                          selectedFilesFromUploadedFiles(
                                                                        selectedUploadedFiles,
                                                                      );
                                                                      downloadUrls = (await Future
                                                                              .wait(
                                                                        selectedMedia
                                                                            .map(
                                                                          (m) async => await uploadData(
                                                                              m.storagePath,
                                                                              m.bytes),
                                                                        ),
                                                                      ))
                                                                          .where((u) =>
                                                                              u !=
                                                                              null)
                                                                          .map((u) =>
                                                                              u!)
                                                                          .toList();
                                                                    } finally {
                                                                      _model.isDataUploading1 =
                                                                          false;
                                                                    }
                                                                    if (selectedUploadedFiles.length ==
                                                                            selectedMedia
                                                                                .length &&
                                                                        downloadUrls.length ==
                                                                            selectedMedia.length) {
                                                                      safeSetState(
                                                                          () {
                                                                        _model.uploadedLocalFile1 =
                                                                            selectedUploadedFiles.first;
                                                                        _model.uploadedFileUrl1 =
                                                                            downloadUrls.first;
                                                                      });
                                                                    } else {
                                                                      safeSetState(
                                                                          () {});
                                                                      return;
                                                                    }
                                                                  }

                                                                  safeSetState(
                                                                      () {});
                                                                },
                                                                text: FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  '0q31cy2t' /* Add a photo */,
                                                                ),
                                                                options:
                                                                    FFButtonOptions(
                                                                  width: 150.0,
                                                                  height: 40.0,
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          24.0,
                                                                          0.0,
                                                                          24.0,
                                                                          0.0),
                                                                  iconPadding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          0.0),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .tertiary,
                                                                  textStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmall
                                                                      .override(
                                                                        fontFamily:
                                                                            'Poppins',
                                                                        color: Color(
                                                                            0xFF0A0A0A),
                                                                        fontSize:
                                                                            15.0,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                  elevation:
                                                                      3.0,
                                                                  borderSide:
                                                                      BorderSide(
                                                                    color: Colors
                                                                        .transparent,
                                                                    width: 1.0,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              40.0),
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
                                        ),
                                      ],
                                    ),
                            ),
                            SingleChildScrollView(
                              child: !_showLegacyWorkoutMedia
                                  ? _WorkoutMediaPanel(
                                      video: true,
                                      mediaUrl: _model.uploadedFileUrl2,
                                      fileName:
                                          _model.uploadedLocalFile2.name ?? '',
                                      bytes: _model.uploadedLocalFile2.bytes
                                              ?.length ??
                                          0,
                                      progress: _videoProgress,
                                      onPick: _pickWorkoutVideo,
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Column(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 20.0, 0.0, 12.0),
                                              child: Container(
                                                width:
                                                    MediaQuery.sizeOf(context)
                                                            .width *
                                                        0.96,
                                                height: 300.0,
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .tertiary,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20.0),
                                                  border: Border.all(
                                                    color: Color(0xFF0A0A0A),
                                                    width: 2.0,
                                                  ),
                                                ),
                                                child: Stack(
                                                  children: [
                                                    if (_model
                                                            .uploadedFileUrl2 !=
                                                        '')
                                                      FlutterFlowMediaDisplay(
                                                        path: _model
                                                            .uploadedFileUrl2,
                                                        imageBuilder: (path) =>
                                                            ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                          child: Image.network(
                                                            path,
                                                            width: MediaQuery
                                                                        .sizeOf(
                                                                            context)
                                                                    .width *
                                                                1.0,
                                                            height: 300.0,
                                                            fit: BoxFit.fill,
                                                          ),
                                                        ),
                                                        videoPlayerBuilder:
                                                            (path) =>
                                                                FlutterFlowVideoPlayer(
                                                          path: path,
                                                          width:
                                                              MediaQuery.sizeOf(
                                                                          context)
                                                                      .width *
                                                                  0.96,
                                                          height: 300.0,
                                                          autoPlay: false,
                                                          looping: true,
                                                          showControls: true,
                                                          allowFullScreen: true,
                                                          allowPlaybackSpeedMenu:
                                                              false,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Align(
                                          alignment:
                                              AlignmentDirectional(0.0, 0.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'jyj1whij' /* Upload workout video here */,
                                                ),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Poppins',
                                                          letterSpacing: 0.0,
                                                        ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Align(
                                          alignment:
                                              AlignmentDirectional(0.0, 0.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'pzac4zbm' /* All videos over 60 seconds
wil... */
                                                  ,
                                                ),
                                                textAlign: TextAlign.center,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Poppins',
                                                          letterSpacing: 0.0,
                                                        ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 50.0, 0.0, 0.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Stack(
                                                    children: [
                                                      if (_model
                                                              .uploadedFileUrl2 !=
                                                          '')
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      0.0,
                                                                      0.0,
                                                                      0.0,
                                                                      20.0),
                                                          child: FFButtonWidget(
                                                            onPressed:
                                                                () async {
                                                              await FirebaseStorage
                                                                  .instance
                                                                  .refFromURL(_model
                                                                      .uploadedFileUrl2)
                                                                  .delete();
                                                            },
                                                            text: FFLocalizations
                                                                    .of(context)
                                                                .getText(
                                                              'n94ldcnq' /* Delete Video */,
                                                            ),
                                                            options:
                                                                FFButtonOptions(
                                                              width: 150.0,
                                                              height: 40.0,
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          24.0,
                                                                          0.0,
                                                                          24.0,
                                                                          0.0),
                                                              iconPadding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          0.0),
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .error,
                                                              textStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmall
                                                                      .override(
                                                                        fontFamily:
                                                                            'Poppins',
                                                                        color: Color(
                                                                            0xFF0A0A0A),
                                                                        fontSize:
                                                                            15.0,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                              elevation: 3.0,
                                                              borderSide:
                                                                  BorderSide(
                                                                color: Colors
                                                                    .transparent,
                                                                width: 1.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          40.0),
                                                            ),
                                                          ),
                                                        ),
                                                      if (_model
                                                              .uploadedFileUrl2 ==
                                                          '')
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      0.0,
                                                                      0.0,
                                                                      0.0,
                                                                      20.0),
                                                          child: FFButtonWidget(
                                                            onPressed:
                                                                () async {
                                                              _model.pickVideo =
                                                                  await actions
                                                                      .pickVideo();
                                                              _model.compressVideo =
                                                                  await actions
                                                                      .compressVideo(
                                                                _model
                                                                    .pickVideo!,
                                                              );
                                                              {
                                                                safeSetState(() =>
                                                                    _model.isDataUploading2 =
                                                                        true);
                                                                var selectedUploadedFiles =
                                                                    <FFUploadedFile>[];
                                                                var selectedMedia =
                                                                    <SelectedFile>[];
                                                                var downloadUrls =
                                                                    <String>[];
                                                                try {
                                                                  showUploadMessage(
                                                                    context,
                                                                    'Uploading file...',
                                                                    showLoading:
                                                                        true,
                                                                  );
                                                                  selectedUploadedFiles = _model
                                                                          .compressVideo!
                                                                          .bytes!
                                                                          .isNotEmpty
                                                                      ? [
                                                                          _model
                                                                              .compressVideo!
                                                                        ]
                                                                      : <FFUploadedFile>[];
                                                                  selectedMedia =
                                                                      selectedFilesFromUploadedFiles(
                                                                    selectedUploadedFiles,
                                                                  );
                                                                  downloadUrls = (await Future
                                                                          .wait(
                                                                    selectedMedia
                                                                        .map(
                                                                      (m) async => await uploadData(
                                                                          m.storagePath,
                                                                          m.bytes),
                                                                    ),
                                                                  ))
                                                                      .where((u) =>
                                                                          u !=
                                                                          null)
                                                                      .map((u) =>
                                                                          u!)
                                                                      .toList();
                                                                } finally {
                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .hideCurrentSnackBar();
                                                                  _model.isDataUploading2 =
                                                                      false;
                                                                }
                                                                if (selectedUploadedFiles
                                                                            .length ==
                                                                        selectedMedia
                                                                            .length &&
                                                                    downloadUrls
                                                                            .length ==
                                                                        selectedMedia
                                                                            .length) {
                                                                  safeSetState(
                                                                      () {
                                                                    _model.uploadedLocalFile2 =
                                                                        selectedUploadedFiles
                                                                            .first;
                                                                    _model.uploadedFileUrl2 =
                                                                        downloadUrls
                                                                            .first;
                                                                  });
                                                                  showUploadMessage(
                                                                      context,
                                                                      'Success!');
                                                                } else {
                                                                  safeSetState(
                                                                      () {});
                                                                  showUploadMessage(
                                                                      context,
                                                                      'Failed to upload data');
                                                                  return;
                                                                }
                                                              }

                                                              safeSetState(
                                                                  () {});
                                                            },
                                                            text: FFLocalizations
                                                                    .of(context)
                                                                .getText(
                                                              'vu82jjkv' /* Add a Video */,
                                                            ),
                                                            options:
                                                                FFButtonOptions(
                                                              width: 150.0,
                                                              height: 40.0,
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          24.0,
                                                                          0.0,
                                                                          24.0,
                                                                          0.0),
                                                              iconPadding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          0.0),
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .tertiary,
                                                              textStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmall
                                                                      .override(
                                                                        fontFamily:
                                                                            'Poppins',
                                                                        color: Color(
                                                                            0xFF0A0A0A),
                                                                        fontSize:
                                                                            15.0,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                              elevation: 3.0,
                                                              borderSide:
                                                                  BorderSide(
                                                                color: Colors
                                                                    .transparent,
                                                                width: 1.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          40.0),
                                                            ),
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
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_model.datePicked1 ==
                    dateTimeFromSecondsSinceEpoch(valueOrDefault<int>(
                      _model.datePicked1?.secondsSinceEpoch,
                      1,
                    )))
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 20.0, 16.0, 0.0),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      height: 150.0,
                      constraints: BoxConstraints(
                        minHeight: 130.0,
                        maxHeight: 800.0,
                      ),
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondary,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).accent1,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 12.0, 0.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_rounded,
                                    color: FlutterFlowTheme.of(context).accent1,
                                    size: 24.0,
                                  ),
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        12.0, 0.0, 0.0, 0.0),
                                    child: Text(
                                      _model.textController1.text,
                                      textAlign: TextAlign.start,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Poppins',
                                            color: FlutterFlowTheme.of(context)
                                                .accent1,
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 12.0, 0.0),
                              child: Text(
                                dateTimeFormat(
                                  "yMd",
                                  _model.datePicked2,
                                  locale:
                                      FFLocalizations.of(context).languageCode,
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Poppins',
                                      color:
                                          FlutterFlowTheme.of(context).accent1,
                                      letterSpacing: 0.0,
                                    ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 12.0, 0.0),
                              child: Text(
                                dateTimeFormat(
                                  "jm",
                                  _model.datePicked1,
                                  locale:
                                      FFLocalizations.of(context).languageCode,
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Poppins',
                                      color:
                                          FlutterFlowTheme.of(context).accent1,
                                      letterSpacing: 0.0,
                                    ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 5.0, 0.0, 0.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  RichText(
                                    textScaler:
                                        MediaQuery.of(context).textScaler,
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: valueOrDefault<String>(
                                            _model.placePickerValue.name,
                                            '0',
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'Poppins',
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        TextSpan(
                                          text: FFLocalizations.of(context)
                                              .getText(
                                            'ak6fn8qq' /* ,  */,
                                          ),
                                          style: TextStyle(),
                                        ),
                                        TextSpan(
                                          text: valueOrDefault<String>(
                                            _model.placePickerValue.address,
                                            '0',
                                          ),
                                          style: TextStyle(),
                                        ),
                                        TextSpan(
                                          text: FFLocalizations.of(context)
                                              .getText(
                                            'cmyx6313' /* ,  */,
                                          ),
                                          style: TextStyle(),
                                        ),
                                        TextSpan(
                                          text: valueOrDefault<String>(
                                            _model.placePickerValue.city,
                                            '0',
                                          ),
                                          style: TextStyle(),
                                        ),
                                        TextSpan(
                                          text: FFLocalizations.of(context)
                                              .getText(
                                            'n726c48w' /* ,  */,
                                          ),
                                          style: TextStyle(),
                                        ),
                                        TextSpan(
                                          text: valueOrDefault<String>(
                                            _model.placePickerValue.country,
                                            '0',
                                          ),
                                          style: TextStyle(),
                                        )
                                      ],
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Poppins',
                                            color: FlutterFlowTheme.of(context)
                                                .accent1,
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                    maxLines: 1,
                                  ),
                                ],
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
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 24.0, 16.0, 50.0),
                    child: FFButtonWidget(
                      onPressed: _scheduling ? null : _scheduleTraining,
                      text: FFLocalizations.of(context).getText(
                        'e32mtyu6' /* Schedule a Training */,
                      ),
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 54.0,
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        iconPadding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle:
                            FlutterFlowTheme.of(context).titleSmall.override(
                                  fontFamily: 'Poppins',
                                  color: FlutterFlowTheme.of(context).secondary,
                                  fontSize: 16.0,
                                  letterSpacing: 0.2,
                                  fontWeight: FontWeight.w600,
                                ),
                        borderSide: BorderSide(
                          color: Colors.transparent,
                        ),
                        borderRadius: BorderRadius.circular(28.0),
                      ),
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

  static const _modernGreen = Color(0xFF1FE276);
  static const _modernSurface = Color(0xFF151515);
  static const _modernBorder = Color(0xFF2A2A2A);

  TextStyle _modernText(
    double size, {
    Color color = Colors.white,
    FontWeight weight = FontWeight.w500,
  }) =>
      TextStyle(
        fontFamily: 'Poppins',
        fontSize: size,
        color: color,
        fontWeight: weight,
      );

  InputDecoration _modernDecoration(String hint,
          {IconData? icon, String? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: _modernText(13, color: const Color(0xFF737373)),
        prefixIcon: icon == null
            ? null
            : Icon(icon, color: const Color(0xFF777777), size: 20),
        suffixText: suffix,
        suffixStyle: _modernText(12, color: const Color(0xFF8A8A8A)),
        filled: true,
        fillColor: _modernSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _modernBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _modernBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _modernGreen),
        ),
      );

  Widget _modernLabel(String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(value,
            style: _modernText(12,
                color: const Color(0xFFB7B7B7), weight: FontWeight.w600)),
      );

  Future<void> _pickModernLocation() async {
    final place = await showWorkoutLocationPicker(context);
    if (place == null || !mounted) return;
    setState(() => _model.placePickerValue = place);
  }

  Future<void> _pickModernDate() async {
    final now = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: _model.datePicked2 ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _modernGreen,
            surface: _modernSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (value != null && mounted) setState(() => _model.datePicked2 = value);
  }

  Future<void> _pickModernTime() async {
    final now = TimeOfDay.now();
    final initial = _model.datePicked1 == null
        ? now
        : TimeOfDay.fromDateTime(_model.datePicked1!);
    final value = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _modernGreen,
            surface: _modernSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (value != null && mounted) {
      final current = _model.datePicked1 ?? DateTime.now();
      setState(() => _model.datePicked1 = DateTime(
            current.year,
            current.month,
            current.day,
            value.hour,
            value.minute,
          ));
    }
  }

  Widget _choiceGroup({
    required String label,
    required List<String> values,
    required String? selected,
    required ValueChanged<String> onSelected,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _modernLabel(label),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((value) {
              final active = selected == value;
              return ChoiceChip(
                key: ValueKey('workout-${label.toLowerCase()}-$value'),
                label: Text(value),
                selected: active,
                showCheckmark: false,
                onSelected: (_) => onSelected(value),
                selectedColor: _modernGreen,
                backgroundColor: _modernSurface,
                side: BorderSide(color: active ? _modernGreen : _modernBorder),
                labelStyle: _modernText(12,
                    color: active ? const Color(0xFF07130B) : Colors.white,
                    weight: FontWeight.w600),
              );
            }).toList(growable: false),
          ),
        ],
      );

  Widget _trainingInfoTab() {
    final place = _model.placePickerValue;
    final hasPlace = place.address.trim().isNotEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
      children: [
        _modernLabel('Workout name'),
        TextField(
          key: const ValueKey('workout-title'),
          controller: _model.textController1,
          focusNode: _model.textFieldFocusNode1,
          style: _modernText(14),
          decoration: _modernDecoration('e.g. Morning cardio'),
        ),
        const SizedBox(height: 18),
        _modernLabel('Location'),
        InkWell(
          key: const ValueKey('workout-location-picker'),
          onTap: _pickModernLocation,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            decoration: BoxDecoration(
              color: _modernSurface,
              border: Border.all(color: _modernBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF103620),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: _modernGreen, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hasPlace ? place.name : 'Choose a location',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _modernText(13,
                              weight: FontWeight.w600,
                              color: hasPlace
                                  ? Colors.white
                                  : const Color(0xFF8B8B8B))),
                      if (hasPlace)
                        Text(place.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _modernText(10,
                                color: const Color(0xFF858585))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF777777)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _modernLabel('Date'),
                  OutlinedButton.icon(
                    key: const ValueKey('workout-date-picker'),
                    onPressed: _pickModernDate,
                    icon: const Icon(Icons.calendar_month_rounded,
                        color: _modernGreen, size: 18),
                    label: Text(
                      _model.datePicked2 == null
                          ? 'Select date'
                          : dateTimeFormat('MMM d, y', _model.datePicked2),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: _modernBorder),
                      backgroundColor: _modernSurface,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      textStyle: _modernText(12, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _modernLabel('Start time'),
                  OutlinedButton.icon(
                    key: const ValueKey('workout-time-picker'),
                    onPressed: _pickModernTime,
                    icon: const Icon(Icons.schedule_rounded,
                        color: _modernGreen, size: 18),
                    label: Text(
                      _model.datePicked1 == null
                          ? 'Select time'
                          : dateTimeFormat('jm', _model.datePicked1),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: _modernBorder),
                      backgroundColor: _modernSurface,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      textStyle: _modernText(12, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _modernLabel('Description'),
        TextField(
          key: const ValueKey('workout-description'),
          controller: _model.textController2,
          focusNode: _model.textFieldFocusNode2,
          minLines: 3,
          maxLines: 5,
          style: _modernText(13),
          decoration: _modernDecoration(
              'What will you train? Add anything participants should know.'),
        ),
        const SizedBox(height: 18),
        _choiceGroup(
          label: 'Category',
          values: const [
            'Full body',
            'Cardio',
            'Strength',
            'Cross-Fit',
            'Legs',
            'Yoga',
          ],
          selected: _model.dropDownValue,
          onSelected: (value) => setState(() => _model.dropDownValue = value),
        ),
        const SizedBox(height: 18),
        _choiceGroup(
          label: 'Level',
          values: const ['Beginner', 'Intermediate', 'Advanced'],
          selected: _model.dificultLevelValue,
          onSelected: (value) =>
              setState(() => _model.dificultLevelValue = value),
        ),
        const SizedBox(height: 18),
        _modernLabel('Duration'),
        TextField(
          key: const ValueKey('workout-duration'),
          controller: _model.textController3,
          focusNode: _model.textFieldFocusNode3,
          keyboardType: TextInputType.number,
          style: _modernText(14),
          decoration: _modernDecoration('45',
              icon: Icons.timer_outlined, suffix: 'minutes'),
        ),
      ],
    );
  }

  Widget _mediaTab(bool video) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
        children: [
          _WorkoutMediaPanel(
            video: video,
            mediaUrl: video ? _model.uploadedFileUrl2 : _model.uploadedFileUrl1,
            fileName: video
                ? (_model.uploadedLocalFile2.name ?? '')
                : (_model.uploadedLocalFile1.name ?? ''),
            bytes: video
                ? (_model.uploadedLocalFile2.bytes?.length ?? 0)
                : (_model.uploadedLocalFile1.bytes?.length ?? 0),
            progress: video ? _videoProgress : _coverProgress,
            onPick: video ? _pickWorkoutVideo : _pickCover,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF10251A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF195B36)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: _modernGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    video
                        ? 'This workout video will appear in FitClips after the training is scheduled.'
                        : 'This cover appears on your event card and workout details.',
                    style: _modernText(11, color: const Color(0xFFB2C5B8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildModernWorkoutCreator(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFF090909),
        appBar: AppBar(
          backgroundColor: const Color(0xFF090909),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => context.safePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          title: Text('Create workout',
              style: _modernText(19, weight: FontWeight.w700)),
          bottom: TabBar(
            controller: _model.tabBarController,
            indicatorColor: _modernGreen,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF777777),
            labelStyle: _modernText(13, weight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Training info'),
              Tab(text: 'Cover image'),
              Tab(text: 'Video'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _model.tabBarController,
          children: [
            _trainingInfoTab(),
            _mediaTab(false),
            _mediaTab(true),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          child: SizedBox(
            height: 56,
            child: FilledButton(
              key: const ValueKey('schedule-workout-button'),
              onPressed: _scheduling ? null : _scheduleTraining,
              style: FilledButton.styleFrom(
                backgroundColor: _modernGreen,
                disabledBackgroundColor: const Color(0xFF225C3B),
                foregroundColor: const Color(0xFF07130B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
              ),
              child: _scheduling
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF07130B),
                      ),
                    )
                  : Text('Schedule a Training',
                      style: _modernText(15,
                          color: const Color(0xFF07130B),
                          weight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkoutMediaPanel extends StatelessWidget {
  const _WorkoutMediaPanel({
    required this.video,
    required this.mediaUrl,
    required this.fileName,
    required this.bytes,
    required this.progress,
    required this.onPick,
  });

  static const _green = Color(0xFF15E77D);
  final bool video;
  final String mediaUrl;
  final String fileName;
  final int bytes;
  final double? progress;
  final VoidCallback onPick;

  String get _title => video ? 'Add a workout video' : 'Add a workout cover';
  String get _description => video
      ? 'MP4 or MOV · 60 seconds max'
      : 'JPG or PNG · 4:5 recommended · up to 10 MB';
  String get _constraint => video
      ? 'Clips over 60 seconds are rejected on upload.'
      : 'This cover appears on Explore and training event cards.';

  String _sizeLabel() {
    if (bytes <= 0) return 'Uploaded';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomPaint(
              painter: mediaUrl.isEmpty
                  ? _WorkoutDashedBorderPainter(
                      color:
                          progress == null ? const Color(0xFF444444) : _green,
                      radius: 22,
                    )
                  : null,
              child: Container(
                width: double.infinity,
                height: 330,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFF101010),
                  borderRadius: BorderRadius.circular(22),
                  border: mediaUrl.isNotEmpty
                      ? Border.all(color: const Color(0xFF303030))
                      : null,
                ),
                child: progress != null
                    ? _uploading()
                    : mediaUrl.isNotEmpty
                        ? _preview()
                        : _empty(),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: progress == null ? onPick : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  disabledForegroundColor: const Color(0xFF555555),
                  side: const BorderSide(color: Color(0xFF323232)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                icon: Icon(
                  video ? Icons.videocam_outlined : Icons.photo_outlined,
                  color: progress == null ? _green : null,
                ),
                label: Text(
                  mediaUrl.isEmpty
                      ? (video ? 'Add video' : 'Add cover')
                      : 'Choose another',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 13),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFF858A90), size: 16),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _constraint,
                    style: const TextStyle(
                      color: Color(0xFF858A90),
                      fontFamily: 'Poppins',
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _empty() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFF0E3422),
              shape: BoxShape.circle,
            ),
            child: Icon(
              video ? Icons.play_arrow_rounded : Icons.image_outlined,
              color: _green,
              size: 29,
            ),
          ),
          const SizedBox(height: 17),
          Text(
            _title,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF878C92),
              fontFamily: 'Poppins',
              fontSize: 12,
            ),
          ),
        ],
      );

  Widget _uploading() {
    final percent = ((progress ?? 0) * 100).clamp(1, 99).round();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: _green,
              backgroundColor: Color(0xFF282828),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Uploading… $percent%',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            color: _green,
            backgroundColor: const Color(0xFF282828),
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _preview() => Stack(
        fit: StackFit.expand,
        children: [
          if (!video)
            Image.network(
              mediaUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFF151515),
                child:
                    Icon(Icons.broken_image_outlined, color: Color(0xFF777777)),
              ),
            )
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF202020), Color(0xFF0A0A0A)],
                ),
              ),
              child: Center(
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Color(0xCC000000),
                  child: Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 38),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: const Color(0xDC101010),
              padding: const EdgeInsets.fromLTRB(14, 11, 9, 11),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName.isEmpty
                              ? (video
                                  ? 'workout-video.mp4'
                                  : 'workout-cover.jpg')
                              : fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          video
                              ? '${_sizeLabel()} · within 60 seconds'
                              : 'Uploaded · ${_sizeLabel()}',
                          style: const TextStyle(
                            color: Color(0xFF8B9096),
                            fontFamily: 'Poppins',
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onPick,
                    child: const Text(
                      'Replace',
                      style: TextStyle(
                        color: _green,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

class _WorkoutDashedBorderPainter extends CustomPainter {
  const _WorkoutDashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(radius),
      ));
    final metric = path.computeMetrics().first;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const dash = 7.0;
    const gap = 5.0;
    for (double distance = 0;
        distance < metric.length;
        distance += dash + gap) {
      canvas.drawPath(
        metric.extractPath(distance, (distance + dash).clamp(0, metric.length)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WorkoutDashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
