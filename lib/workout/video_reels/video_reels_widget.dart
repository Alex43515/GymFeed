import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/mark_reel/mark_reel_widget.dart';
import '/flutter_flow/flutter_flow_media_display.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_toggle_icon.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_video_player.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/workout/reels_description/reels_description_widget.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'
    as smooth_page_indicator;
import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:flutter/material.dart';
import 'video_reels_model.dart';
export 'video_reels_model.dart';

class VideoReelsWidget extends StatefulWidget {
  const VideoReelsWidget({
    super.key,
    this.initialStoryIndex,
  });

  final int? initialStoryIndex;

  @override
  State<VideoReelsWidget> createState() => _VideoReelsWidgetState();
}

class _VideoReelsWidgetState extends State<VideoReelsWidget> {
  late VideoReelsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VideoReelsModel());

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
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width * 1.0,
            height: MediaQuery.sizeOf(context).height * 1.0,
            child: Stack(
              alignment: const AlignmentDirectional(0.0, 1.0),
              children: [
                Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: StreamBuilder<List<UserTrainingsRecord>>(
                        stream: queryUserTrainingsRecord(
                          queryBuilder: (userTrainingsRecord) =>
                              userTrainingsRecord
                                  .where(
                                    'TrainingVideo',
                                    isNotEqualTo: '',
                                  )
                                  .orderBy('TrainingVideo', descending: true),
                        ),
                        builder: (context, snapshot) {
                          // Customize what your widget looks like when it's loading.
                          if (!snapshot.hasData) {
                            return const Center(
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
                          List<UserTrainingsRecord>
                              pageViewUserTrainingsRecordList = snapshot.data!;

                          return SizedBox(
                            width: MediaQuery.sizeOf(context).width * 1.0,
                            height: double.infinity,
                            child: Stack(
                              children: [
                                PageView.builder(
                                  controller: _model.pageViewController ??=
                                      PageController(
                                          initialPage: max(
                                              0,
                                              min(
                                                  valueOrDefault<int>(
                                                    widget.initialStoryIndex,
                                                    0,
                                                  ),
                                                  pageViewUserTrainingsRecordList
                                                          .length -
                                                      1))),
                                  scrollDirection: Axis.vertical,
                                  itemCount:
                                      pageViewUserTrainingsRecordList.length,
                                  itemBuilder: (context, pageViewIndex) {
                                    final pageViewUserTrainingsRecord =
                                        pageViewUserTrainingsRecordList[
                                            pageViewIndex];
                                    return Column(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Container(
                                          width:
                                              MediaQuery.sizeOf(context).width *
                                                  1.0,
                                          height: MediaQuery.sizeOf(context)
                                                  .height *
                                              1.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .secondary,
                                          ),
                                          child: SizedBox(
                                            width: MediaQuery.sizeOf(context)
                                                    .width *
                                                1.0,
                                            height: MediaQuery.sizeOf(context)
                                                    .height *
                                                1.0,
                                            child: Stack(
                                              children: [
                                                FlutterFlowMediaDisplay(
                                                  path:
                                                      pageViewUserTrainingsRecord
                                                          .trainingVideo,
                                                  imageBuilder: (path) =>
                                                      ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                    child: Image.network(
                                                      path,
                                                      width: MediaQuery.sizeOf(
                                                                  context)
                                                              .width *
                                                          1.0,
                                                      height: MediaQuery.sizeOf(
                                                                  context)
                                                              .height *
                                                          1.0,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  videoPlayerBuilder: (path) =>
                                                      FlutterFlowVideoPlayer(
                                                    path: path,
                                                    width: MediaQuery.sizeOf(
                                                                context)
                                                            .width *
                                                        1.0,
                                                    height: MediaQuery.sizeOf(
                                                                context)
                                                            .height *
                                                        0.9,
                                                    autoPlay: true,
                                                    looping: true,
                                                    showControls: true,
                                                    allowFullScreen: true,
                                                    allowPlaybackSpeedMenu:
                                                        false,
                                                  ),
                                                ),
                                                Align(
                                                  alignment:
                                                      const AlignmentDirectional(
                                                          0.0, 0.0),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 0.0,
                                                                0.0, 30.0),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Align(
                                                          alignment:
                                                              const AlignmentDirectional(
                                                                  0.0, 0.0),
                                                          child: Container(
                                                            width:
                                                                double.infinity,
                                                            height: 200.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              gradient:
                                                                  LinearGradient(
                                                                colors: [
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondary,
                                                                  const Color(
                                                                      0x001A1F24)
                                                                ],
                                                                stops: const [
                                                                  0.0,
                                                                  1.0
                                                                ],
                                                                begin:
                                                                    const AlignmentDirectional(
                                                                        0.0,
                                                                        -1.0),
                                                                end:
                                                                    const AlignmentDirectional(
                                                                        0, 1.0),
                                                              ),
                                                            ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceAround,
                                                                  children: [
                                                                    Opacity(
                                                                      opacity:
                                                                          0.0,
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .arrow_back,
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryText,
                                                                        size:
                                                                            24.0,
                                                                      ),
                                                                    ),
                                                                    Opacity(
                                                                      opacity:
                                                                          0.0,
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .arrow_back,
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryText,
                                                                        size:
                                                                            24.0,
                                                                      ),
                                                                    ),
                                                                    Padding(
                                                                      padding: const EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          15.0,
                                                                          0.0),
                                                                      child:
                                                                          InkWell(
                                                                        splashColor:
                                                                            Colors.transparent,
                                                                        focusColor:
                                                                            Colors.transparent,
                                                                        hoverColor:
                                                                            Colors.transparent,
                                                                        highlightColor:
                                                                            Colors.transparent,
                                                                        onTap:
                                                                            () async {
                                                                          context
                                                                              .safePop();
                                                                        },
                                                                        child:
                                                                            Icon(
                                                                          Icons
                                                                              .close,
                                                                          color:
                                                                              FlutterFlowTheme.of(context).tertiary,
                                                                          size:
                                                                              20.0,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                Padding(
                                                                  padding: const EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          16.0,
                                                                          12.0,
                                                                          16.0,
                                                                          36.0),
                                                                  child: StreamBuilder<
                                                                      UsersRecord>(
                                                                    stream: UsersRecord.getDocument(
                                                                        pageViewUserTrainingsRecord
                                                                            .userTraining!),
                                                                    builder:
                                                                        (context,
                                                                            snapshot) {
                                                                      // Customize what your widget looks like when it's loading.
                                                                      if (!snapshot
                                                                          .hasData) {
                                                                        return const Center(
                                                                          child:
                                                                              SizedBox(
                                                                            width:
                                                                                12.0,
                                                                            height:
                                                                                12.0,
                                                                            child:
                                                                                CircularProgressIndicator(
                                                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                                                Colors.white,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        );
                                                                      }

                                                                      final userInfoUsersRecord =
                                                                          snapshot
                                                                              .data!;

                                                                      return Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          InkWell(
                                                                            splashColor:
                                                                                Colors.transparent,
                                                                            focusColor:
                                                                                Colors.transparent,
                                                                            hoverColor:
                                                                                Colors.transparent,
                                                                            highlightColor:
                                                                                Colors.transparent,
                                                                            onTap:
                                                                                () async {
                                                                              if (userInfoUsersRecord.reference == currentUserReference) {
                                                                                context.pushNamed('Profile');
                                                                              } else {
                                                                                context.pushNamed(
                                                                                  'ProfileOther',
                                                                                  queryParameters: {
                                                                                    'username': serializeParam(
                                                                                      userInfoUsersRecord.username,
                                                                                      ParamType.String,
                                                                                    ),
                                                                                  }.withoutNulls,
                                                                                );
                                                                              }
                                                                            },
                                                                            child:
                                                                                Container(
                                                                              width: 40.0,
                                                                              height: 40.0,
                                                                              clipBehavior: Clip.antiAlias,
                                                                              decoration: const BoxDecoration(
                                                                                shape: BoxShape.circle,
                                                                              ),
                                                                              child: Image.network(
                                                                                userInfoUsersRecord.photoUrl,
                                                                                fit: BoxFit.fitHeight,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Expanded(
                                                                            child:
                                                                                InkWell(
                                                                              splashColor: Colors.transparent,
                                                                              focusColor: Colors.transparent,
                                                                              hoverColor: Colors.transparent,
                                                                              highlightColor: Colors.transparent,
                                                                              onTap: () async {
                                                                                if (userInfoUsersRecord.reference == currentUserReference) {
                                                                                  context.pushNamed('Profile');
                                                                                } else {
                                                                                  context.pushNamed(
                                                                                    'ProfileOther',
                                                                                    queryParameters: {
                                                                                      'username': serializeParam(
                                                                                        userInfoUsersRecord.username,
                                                                                        ParamType.String,
                                                                                      ),
                                                                                    }.withoutNulls,
                                                                                  );
                                                                                }
                                                                              },
                                                                              child: Column(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  Padding(
                                                                                    padding: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 0.0, 0.0),
                                                                                    child: Text(
                                                                                      userInfoUsersRecord.username,
                                                                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                            fontFamily: 'Poppins',
                                                                                            color: FlutterFlowTheme.of(context).tertiary,
                                                                                            fontSize: MediaQuery.sizeOf(context).width < 768.0 ? 14.0 : 24.0,
                                                                                            letterSpacing: 0.0,
                                                                                          ),
                                                                                    ),
                                                                                  ),
                                                                                  Padding(
                                                                                    padding: const EdgeInsetsDirectional.fromSTEB(12.0, 4.0, 0.0, 0.0),
                                                                                    child: Text(
                                                                                      pageViewUserTrainingsRecord.trainingTitle,
                                                                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                            fontFamily: 'Poppins',
                                                                                            color: FlutterFlowTheme.of(context).tertiary,
                                                                                            fontSize: MediaQuery.sizeOf(context).width < 768.0 ? 12.0 : 22.0,
                                                                                            letterSpacing: 0.0,
                                                                                          ),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Padding(
                                                                            padding: const EdgeInsetsDirectional.fromSTEB(
                                                                                0.0,
                                                                                0.0,
                                                                                20.0,
                                                                                0.0),
                                                                            child:
                                                                                FFButtonWidget(
                                                                              onPressed: () async {
                                                                                context.pushNamed(
                                                                                  'trainingpostDetails',
                                                                                  queryParameters: {
                                                                                    'userRecord': serializeParam(
                                                                                      userInfoUsersRecord,
                                                                                      ParamType.Document,
                                                                                    ),
                                                                                    'trainingReference': serializeParam(
                                                                                      pageViewUserTrainingsRecord.reference,
                                                                                      ParamType.DocumentReference,
                                                                                    ),
                                                                                  }.withoutNulls,
                                                                                  extra: <String, dynamic>{
                                                                                    'userRecord': userInfoUsersRecord,
                                                                                  },
                                                                                );
                                                                              },
                                                                              text: FFLocalizations.of(context).getText(
                                                                                '7y0kypyo' /* Training */,
                                                                              ),
                                                                              options: FFButtonOptions(
                                                                                height: 25.0,
                                                                                padding: const EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                                                                                iconPadding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                                                                                color: FlutterFlowTheme.of(context).secondary,
                                                                                textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                                                                      fontFamily: 'Poppins',
                                                                                      color: FlutterFlowTheme.of(context).primary,
                                                                                      fontSize: 12.0,
                                                                                      letterSpacing: 0.0,
                                                                                    ),
                                                                                elevation: 3.0,
                                                                                borderSide: const BorderSide(
                                                                                  color: Color(0xFF0FF76D),
                                                                                  width: 2.0,
                                                                                ),
                                                                                borderRadius: BorderRadius.circular(20.0),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Column(
                                                                            mainAxisSize:
                                                                                MainAxisSize.max,
                                                                            children: [
                                                                              Builder(
                                                                                builder: (context) => InkWell(
                                                                                  splashColor: Colors.transparent,
                                                                                  focusColor: Colors.transparent,
                                                                                  hoverColor: Colors.transparent,
                                                                                  highlightColor: Colors.transparent,
                                                                                  onTap: () async {
                                                                                    await showAlignedDialog(
                                                                                      context: context,
                                                                                      isGlobal: false,
                                                                                      avoidOverflow: true,
                                                                                      targetAnchor: const AlignmentDirectional(-1.0, 1.0).resolve(Directionality.of(context)),
                                                                                      followerAnchor: const AlignmentDirectional(-1.0, 1.0).resolve(Directionality.of(context)),
                                                                                      builder: (dialogContext) {
                                                                                        return Material(
                                                                                          color: Colors.transparent,
                                                                                          child: GestureDetector(
                                                                                            onTap: () => FocusScope.of(dialogContext).unfocus(),
                                                                                            child: MarkReelWidget(
                                                                                              userDetails: userInfoUsersRecord,
                                                                                              postReference: pageViewUserTrainingsRecord.reference,
                                                                                            ),
                                                                                          ),
                                                                                        );
                                                                                      },
                                                                                    );
                                                                                  },
                                                                                  child: Icon(
                                                                                    Icons.keyboard_control_sharp,
                                                                                    color: FlutterFlowTheme.of(context).secondaryText,
                                                                                    size: 24.0,
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
                                                        Container(
                                                          width:
                                                              double.infinity,
                                                          height: 50.0,
                                                          decoration:
                                                              BoxDecoration(
                                                            gradient:
                                                                LinearGradient(
                                                              colors: [
                                                                const Color(
                                                                    0x001A1F24),
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondary
                                                              ],
                                                              stops: const [0.0, 1.0],
                                                              begin:
                                                                  const AlignmentDirectional(
                                                                      0.0,
                                                                      -1.0),
                                                              end:
                                                                  const AlignmentDirectional(
                                                                      0, 1.0),
                                                            ),
                                                          ),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .end,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              StreamBuilder<
                                                                  UsersRecord>(
                                                                stream: UsersRecord
                                                                    .getDocument(
                                                                        pageViewUserTrainingsRecord
                                                                            .userTraining!),
                                                                builder: (context,
                                                                    snapshot) {
                                                                  // Customize what your widget looks like when it's loading.
                                                                  if (!snapshot
                                                                      .hasData) {
                                                                    return const Center(
                                                                      child:
                                                                          SizedBox(
                                                                        width:
                                                                            12.0,
                                                                        height:
                                                                            12.0,
                                                                        child:
                                                                            CircularProgressIndicator(
                                                                          valueColor:
                                                                              AlwaysStoppedAnimation<Color>(
                                                                            Colors.white,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }

                                                                  final rowUsersRecord =
                                                                      snapshot
                                                                          .data!;

                                                                  return Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceAround,
                                                                    children: [
                                                                      Padding(
                                                                        padding:
                                                                            const EdgeInsets.all(16.0),
                                                                        child:
                                                                            InkWell(
                                                                          splashColor:
                                                                              Colors.transparent,
                                                                          focusColor:
                                                                              Colors.transparent,
                                                                          hoverColor:
                                                                              Colors.transparent,
                                                                          highlightColor:
                                                                              Colors.transparent,
                                                                          onTap:
                                                                              () async {
                                                                            await showModalBottomSheet(
                                                                              isScrollControlled: true,
                                                                              backgroundColor: Colors.transparent,
                                                                              enableDrag: false,
                                                                              context: context,
                                                                              builder: (context) {
                                                                                return GestureDetector(
                                                                                  onTap: () => FocusScope.of(context).unfocus(),
                                                                                  child: Padding(
                                                                                    padding: MediaQuery.viewInsetsOf(context),
                                                                                    child: SizedBox(
                                                                                      height: MediaQuery.sizeOf(context).height * 0.8,
                                                                                      child: ReelsDescriptionWidget(
                                                                                        userDetails: pageViewUserTrainingsRecord.reference,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                              },
                                                                            ).then((value) =>
                                                                                safeSetState(() {}));
                                                                          },
                                                                          child:
                                                                              Text(
                                                                            pageViewUserTrainingsRecord.trainingDescription.maybeHandleOverflow(
                                                                              maxChars: 30,
                                                                              replacement: '…',
                                                                            ),
                                                                            textAlign:
                                                                                TextAlign.start,
                                                                            maxLines:
                                                                                1,
                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                  fontFamily: 'Poppins',
                                                                                  color: FlutterFlowTheme.of(context).tertiary,
                                                                                  fontSize: MediaQuery.sizeOf(context).width < 768.0 ? 14.0 : 24.0,
                                                                                  letterSpacing: 0.0,
                                                                                ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      ToggleIcon(
                                                                        onPressed:
                                                                            () async {
                                                                          final reelsSavedElement =
                                                                              pageViewUserTrainingsRecord.reference;
                                                                          final reelsSavedUpdate = rowUsersRecord.reelsSaved.contains(reelsSavedElement)
                                                                              ? FieldValue.arrayRemove([
                                                                                  reelsSavedElement
                                                                                ])
                                                                              : FieldValue.arrayUnion([
                                                                                  reelsSavedElement
                                                                                ]);
                                                                          await rowUsersRecord
                                                                              .reference
                                                                              .update({
                                                                            ...mapToFirestore(
                                                                              {
                                                                                'reelsSaved': reelsSavedUpdate,
                                                                              },
                                                                            ),
                                                                          });
                                                                        },
                                                                        value: rowUsersRecord
                                                                            .reelsSaved
                                                                            .contains(pageViewUserTrainingsRecord.reference),
                                                                        onIcon:
                                                                            Icon(
                                                                          Icons
                                                                              .bookmark,
                                                                          color:
                                                                              const Color(0xFF8EFF76),
                                                                          size: MediaQuery.sizeOf(context).width < 768.0
                                                                              ? 20.0
                                                                              : 30.0,
                                                                        ),
                                                                        offIcon:
                                                                            Icon(
                                                                          Icons
                                                                              .bookmark_border,
                                                                          color:
                                                                              FlutterFlowTheme.of(context).secondaryText,
                                                                          size: MediaQuery.sizeOf(context).width < 768.0
                                                                              ? 20.0
                                                                              : 30.0,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  );
                                                                },
                                                              ),
                                                            ],
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
                                      ],
                                    );
                                  },
                                ),
                                Align(
                                  alignment: const AlignmentDirectional(0.95, 0.7),
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 10.0),
                                    child: smooth_page_indicator
                                        .SmoothPageIndicator(
                                      controller: _model.pageViewController ??=
                                          PageController(
                                              initialPage: max(
                                                  0,
                                                  min(
                                                      valueOrDefault<int>(
                                                        widget
                                                            .initialStoryIndex,
                                                        0,
                                                      ),
                                                      pageViewUserTrainingsRecordList
                                                              .length -
                                                          1))),
                                      count: pageViewUserTrainingsRecordList
                                          .length,
                                      axisDirection: Axis.vertical,
                                      onDotClicked: (i) async {
                                        await _model.pageViewController!
                                            .animateToPage(
                                          i,
                                          duration: const Duration(milliseconds: 500),
                                          curve: Curves.ease,
                                        );
                                        safeSetState(() {});
                                      },
                                      effect: smooth_page_indicator
                                          .ExpandingDotsEffect(
                                        expansionFactor: 2.0,
                                        spacing: 8.0,
                                        radius: 16.0,
                                        dotWidth: 8.0,
                                        dotHeight: 4.0,
                                        dotColor: const Color(0x65DBE2E7),
                                        activeDotColor:
                                            FlutterFlowTheme.of(context)
                                                .primary,
                                        paintStyle: PaintingStyle.fill,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
