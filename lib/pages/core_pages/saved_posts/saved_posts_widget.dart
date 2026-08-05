import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_video_player.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'saved_posts_model.dart';
export 'saved_posts_model.dart';

class SavedPostsWidget extends StatefulWidget {
  const SavedPostsWidget({super.key});

  static String routeName = 'savedPosts';
  static String routePath = 'savedPosts';

  @override
  State<SavedPostsWidget> createState() => _SavedPostsWidgetState();
}

class _SavedPostsWidgetState extends State<SavedPostsWidget>
    with TickerProviderStateMixin {
  late SavedPostsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SavedPostsModel());

    _model.tabBarController = TabController(
      vsync: this,
      length: 3,
      initialIndex: 0,
    )..addListener(() => safeSetState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UsersRecord>(
      stream: UsersRecord.getDocument(currentUserReference!),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: SizedBox(
                width: 12.0,
                height: 12.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              ),
            ),
          );
        }

        final savedPostsUsersRecord = snapshot.data!;

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
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 15.0, 0.0, 0.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 20.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                20.0, 0.0, 0.0, 0.0),
                            child: InkWell(
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
                          ),
                          Align(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Text(
                              FFLocalizations.of(context).getText(
                                'hd9u39c1' /* Saved */,
                              ),
                              textAlign: TextAlign.center,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Poppins',
                                    fontSize: functions
                                        .resizeFontBasedOnScreenSize(
                                            MediaQuery.sizeOf(context).width,
                                            20)
                                        .toDouble(),
                                    letterSpacing: 0.0,
                                  ),
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
                                  .titleMedium
                                  .override(
                                    fontFamily: 'Poppins',
                                    fontSize: functions
                                        .resizeFontBasedOnScreenSize(
                                            MediaQuery.sizeOf(context).width,
                                            15)
                                        .toDouble(),
                                    letterSpacing: 0.0,
                                  ),
                              unselectedLabelStyle: TextStyle(),
                              indicatorColor: Color(0xFF8EFF76),
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  30.0, 0.0, 30.0, 0.0),
                              tabs: [
                                Tab(
                                  text: FFLocalizations.of(context).getText(
                                    'au4a6oys' /* Post items */,
                                  ),
                                ),
                                Tab(
                                  text: FFLocalizations.of(context).getText(
                                    'ggwbxgih' /* FitClips */,
                                  ),
                                ),
                                Tab(
                                  text: FFLocalizations.of(context).getText(
                                    'lxkt5yes' /* Food Posts */,
                                  ),
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
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      10.0, 10.0, 10.0, 0.0),
                                  child: StreamBuilder<List<BookmarksRecord>>(
                                    stream: queryBookmarksRecord(
                                      parent: currentUserReference,
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
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      List<BookmarksRecord>
                                          bookmarkedPhotosBookmarksRecordList =
                                          snapshot.data!;
                                      // Return an empty Container when the item does not exist.
                                      if (snapshot.data!.isEmpty) {
                                        return Container();
                                      }
                                      final bookmarkedPhotosBookmarksRecord =
                                          bookmarkedPhotosBookmarksRecordList
                                                  .isNotEmpty
                                              ? bookmarkedPhotosBookmarksRecordList
                                                  .first
                                              : null;

                                      return Builder(
                                        builder: (context) {
                                          final bookmarkedposts =
                                              bookmarkedPhotosBookmarksRecord
                                                      ?.postRefs
                                                      .toList() ??
                                                  [];

                                          return GridView.builder(
                                            padding: EdgeInsets.zero,
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 3,
                                              crossAxisSpacing: 1.0,
                                              mainAxisSpacing: 1.0,
                                              childAspectRatio: 1.0,
                                            ),
                                            primary: false,
                                            shrinkWrap: true,
                                            scrollDirection: Axis.vertical,
                                            itemCount: bookmarkedposts.length,
                                            itemBuilder: (context,
                                                bookmarkedpostsIndex) {
                                              final bookmarkedpostsItem =
                                                  bookmarkedposts[
                                                      bookmarkedpostsIndex];
                                              return Visibility(
                                                visible:
                                                    true /* Warning: Trying to access variable not yet defined. */,
                                                child:
                                                    StreamBuilder<PostsRecord>(
                                                  stream:
                                                      PostsRecord.getDocument(
                                                          bookmarkedpostsItem),
                                                  builder: (context, snapshot) {
                                                    // Customize what your widget looks like when it's loading.
                                                    if (!snapshot.hasData) {
                                                      return Center(
                                                        child: SizedBox(
                                                          width: 12.0,
                                                          height: 12.0,
                                                          child:
                                                              CircularProgressIndicator(
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                    Color>(
                                                              Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }

                                                    final columnPostsRecord =
                                                        snapshot.data!;

                                                    return Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        if ((columnPostsRecord
                                                                        .postPhoto !=
                                                                    '') ||
                                                            (columnPostsRecord
                                                                        .postVideo !=
                                                                    ''))
                                                          Expanded(
                                                            child: Container(
                                                              width: double
                                                                  .infinity,
                                                              height: double
                                                                  .infinity,
                                                              child: Stack(
                                                                children: [
                                                                  if (columnPostsRecord
                                                                              .postPhoto !=
                                                                          '')
                                                                    StreamBuilder<
                                                                        PostsRecord>(
                                                                      stream: PostsRecord
                                                                          .getDocument(
                                                                              bookmarkedpostsItem),
                                                                      builder:
                                                                          (context,
                                                                              snapshot) {
                                                                        // Customize what your widget looks like when it's loading.
                                                                        if (!snapshot
                                                                            .hasData) {
                                                                          return Center(
                                                                            child:
                                                                                SizedBox(
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

                                                                        final photoPostsRecord =
                                                                            snapshot.data!;

                                                                        return InkWell(
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
                                                                            context.pushNamed(
                                                                              PostDetailsWidget.routeName,
                                                                              queryParameters: {
                                                                                'post': serializeParam(
                                                                                  bookmarkedpostsItem,
                                                                                  ParamType.DocumentReference,
                                                                                ),
                                                                              }.withoutNulls,
                                                                            );
                                                                          },
                                                                          child:
                                                                              Image.network(
                                                                            functions.bunnyCDNImagePath(photoPostsRecord.postPhoto),
                                                                            width:
                                                                                100.0,
                                                                            height:
                                                                                100.0,
                                                                            fit:
                                                                                BoxFit.cover,
                                                                          ),
                                                                        );
                                                                      },
                                                                    ),
                                                                  if (columnPostsRecord
                                                                              .postVideo !=
                                                                          '')
                                                                    StreamBuilder<
                                                                        PostsRecord>(
                                                                      stream: PostsRecord
                                                                          .getDocument(
                                                                              bookmarkedpostsItem),
                                                                      builder:
                                                                          (context,
                                                                              snapshot) {
                                                                        // Customize what your widget looks like when it's loading.
                                                                        if (!snapshot
                                                                            .hasData) {
                                                                          return Center(
                                                                            child:
                                                                                SizedBox(
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

                                                                        final videoPlayerPostsRecord =
                                                                            snapshot.data!;

                                                                        return InkWell(
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
                                                                            context.pushNamed(
                                                                              PostDetailsWidget.routeName,
                                                                              queryParameters: {
                                                                                'post': serializeParam(
                                                                                  bookmarkedpostsItem,
                                                                                  ParamType.DocumentReference,
                                                                                ),
                                                                              }.withoutNulls,
                                                                            );
                                                                          },
                                                                          child:
                                                                              FlutterFlowVideoPlayer(
                                                                            path:
                                                                                functions.bunnyCDNVideoPath(videoPlayerPostsRecord.postVideo),
                                                                            videoType:
                                                                                VideoType.network,
                                                                            width:
                                                                                100.0,
                                                                            height:
                                                                                100.0,
                                                                            autoPlay:
                                                                                false,
                                                                            looping:
                                                                                true,
                                                                            showControls:
                                                                                false,
                                                                            allowFullScreen:
                                                                                true,
                                                                            allowPlaybackSpeedMenu:
                                                                                false,
                                                                          ),
                                                                        );
                                                                      },
                                                                    ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 10.0, 0.0, 0.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Expanded(
                                        child: Builder(
                                          builder: (context) {
                                            final savedreels =
                                                savedPostsUsersRecord.reelsSaved
                                                    .toList();

                                            return GridView.builder(
                                              padding: EdgeInsets.zero,
                                              gridDelegate:
                                                  SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 3,
                                                crossAxisSpacing: 5.0,
                                                mainAxisSpacing: 5.0,
                                                childAspectRatio: 1.0,
                                              ),
                                              scrollDirection: Axis.vertical,
                                              itemCount: savedreels.length,
                                              itemBuilder:
                                                  (context, savedreelsIndex) {
                                                final savedreelsItem =
                                                    savedreels[savedreelsIndex];
                                                return StreamBuilder<
                                                    UserTrainingsRecord>(
                                                  stream: UserTrainingsRecord
                                                      .getDocument(
                                                          savedreelsItem),
                                                  builder: (context, snapshot) {
                                                    // Customize what your widget looks like when it's loading.
                                                    if (!snapshot.hasData) {
                                                      return Center(
                                                        child: SizedBox(
                                                          width: 12.0,
                                                          height: 12.0,
                                                          child:
                                                              CircularProgressIndicator(
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                    Color>(
                                                              Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }

                                                    final containerUserTrainingsRecord =
                                                        snapshot.data!;

                                                    return InkWell(
                                                      splashColor:
                                                          Colors.transparent,
                                                      focusColor:
                                                          Colors.transparent,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      onTap: () async {
                                                        context.pushNamed(
                                                          TrainingpostDetailsWidget
                                                              .routeName,
                                                          queryParameters: {
                                                            'userRecord':
                                                                serializeParam(
                                                              savedPostsUsersRecord,
                                                              ParamType
                                                                  .Document,
                                                            ),
                                                            'trainingReference':
                                                                serializeParam(
                                                              containerUserTrainingsRecord
                                                                  .reference,
                                                              ParamType
                                                                  .DocumentReference,
                                                            ),
                                                          }.withoutNulls,
                                                          extra: <String,
                                                              dynamic>{
                                                            'userRecord':
                                                                savedPostsUsersRecord,
                                                          },
                                                        );
                                                      },
                                                      child: Container(
                                                        width:
                                                            MediaQuery.sizeOf(
                                                                        context)
                                                                    .width *
                                                                0.96,
                                                        height:
                                                            MediaQuery.sizeOf(
                                                                        context)
                                                                    .height *
                                                                1.0,
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Color(0xFF111111),
                                                        ),
                                                        child:
                                                            FlutterFlowVideoPlayer(
                                                          path: functions
                                                              .bunnyCDNVideoPath(
                                                                  containerUserTrainingsRecord
                                                                      .trainingVideo),
                                                          videoType:
                                                              VideoType.network,
                                                          width: 80.0,
                                                          height: 80.0,
                                                          autoPlay: false,
                                                          looping: false,
                                                          showControls: false,
                                                          allowFullScreen:
                                                              false,
                                                          allowPlaybackSpeedMenu:
                                                              false,
                                                          lazyLoad: false,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 10.0, 0.0, 0.0),
                                  child: StreamBuilder<List<BookmarksRecord>>(
                                    stream: queryBookmarksRecord(
                                      parent: currentUserReference,
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
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      List<BookmarksRecord>
                                          gridViewBookmarksRecordList =
                                          snapshot.data!;
                                      // Return an empty Container when the item does not exist.
                                      if (snapshot.data!.isEmpty) {
                                        return Container();
                                      }
                                      final gridViewBookmarksRecord =
                                          gridViewBookmarksRecordList.isNotEmpty
                                              ? gridViewBookmarksRecordList
                                                  .first
                                              : null;

                                      return Builder(
                                        builder: (context) {
                                          final savedposts =
                                              gridViewBookmarksRecord
                                                      ?.foodPostRef
                                                      .toList() ??
                                                  [];

                                          return GridView.builder(
                                            padding: EdgeInsets.zero,
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 3,
                                              crossAxisSpacing: 10.0,
                                              mainAxisSpacing: 10.0,
                                              childAspectRatio: 1.0,
                                            ),
                                            scrollDirection: Axis.vertical,
                                            itemCount: savedposts.length,
                                            itemBuilder:
                                                (context, savedpostsIndex) {
                                              final savedpostsItem =
                                                  savedposts[savedpostsIndex];
                                              return StreamBuilder<PostsRecord>(
                                                stream: PostsRecord.getDocument(
                                                    savedpostsItem),
                                                builder: (context, snapshot) {
                                                  // Customize what your widget looks like when it's loading.
                                                  if (!snapshot.hasData) {
                                                    return Center(
                                                      child: SizedBox(
                                                        width: 12.0,
                                                        height: 12.0,
                                                        child:
                                                            CircularProgressIndicator(
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                  Color>(
                                                            Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }

                                                  final containerPostsRecord =
                                                      snapshot.data!;

                                                  return Container(
                                                    width: 100.0,
                                                    height: 100.0,
                                                    decoration: BoxDecoration(
                                                      color: FlutterFlowTheme
                                                              .of(context)
                                                          .secondaryBackground,
                                                    ),
                                                    child: Visibility(
                                                      visible: (containerPostsRecord
                                                                      .postPhoto !=
                                                                  '') ||
                                                          (containerPostsRecord
                                                                      .postVideo !=
                                                                  ''),
                                                      child: Stack(
                                                        children: [
                                                          if (containerPostsRecord
                                                                      .postPhoto !=
                                                                  '')
                                                            InkWell(
                                                              splashColor: Colors
                                                                  .transparent,
                                                              focusColor: Colors
                                                                  .transparent,
                                                              hoverColor: Colors
                                                                  .transparent,
                                                              highlightColor:
                                                                  Colors
                                                                      .transparent,
                                                              onTap: () async {
                                                                context
                                                                    .pushNamed(
                                                                  PostDetailsWidget
                                                                      .routeName,
                                                                  queryParameters:
                                                                      {
                                                                    'post':
                                                                        serializeParam(
                                                                      savedpostsItem,
                                                                      ParamType
                                                                          .DocumentReference,
                                                                    ),
                                                                  }.withoutNulls,
                                                                );
                                                              },
                                                              child: ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8.0),
                                                                child: Image
                                                                    .network(
                                                                  functions.bunnyCDNImagePath(
                                                                      containerPostsRecord
                                                                          .postPhoto),
                                                                  width: 300.0,
                                                                  height: 200.0,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                ),
                                                              ),
                                                            ),
                                                          if (containerPostsRecord
                                                                      .postVideo !=
                                                                  '')
                                                            InkWell(
                                                              splashColor: Colors
                                                                  .transparent,
                                                              focusColor: Colors
                                                                  .transparent,
                                                              hoverColor: Colors
                                                                  .transparent,
                                                              highlightColor:
                                                                  Colors
                                                                      .transparent,
                                                              onTap: () async {
                                                                context
                                                                    .pushNamed(
                                                                  PostDetailsWidget
                                                                      .routeName,
                                                                  queryParameters:
                                                                      {
                                                                    'post':
                                                                        serializeParam(
                                                                      savedpostsItem,
                                                                      ParamType
                                                                          .DocumentReference,
                                                                    ),
                                                                  }.withoutNulls,
                                                                );
                                                              },
                                                              child:
                                                                  FlutterFlowVideoPlayer(
                                                                path: functions
                                                                    .bunnyCDNVideoPath(
                                                                        containerPostsRecord
                                                                            .postVideo),
                                                                videoType:
                                                                    VideoType
                                                                        .network,
                                                                width: 300.0,
                                                                height: 200.0,
                                                                autoPlay: false,
                                                                looping: true,
                                                                showControls:
                                                                    true,
                                                                allowFullScreen:
                                                                    true,
                                                                allowPlaybackSpeedMenu:
                                                                    false,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
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
            ),
          ),
        );
      },
    );
  }
}
