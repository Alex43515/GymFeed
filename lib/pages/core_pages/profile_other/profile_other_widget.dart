import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/components/bio/bio_widget.dart';
import '/components/blocked/blocked_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_timer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_video_player.dart';
import '/pages/core_pages/story/story_widget.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'profile_other_model.dart';
export 'profile_other_model.dart';

class ProfileOtherWidget extends StatefulWidget {
  const ProfileOtherWidget({
    super.key,
    this.username,
  });

  final String? username;

  static String routeName = 'ProfileOther';
  static String routePath = 'profileOther';

  @override
  State<ProfileOtherWidget> createState() => _ProfileOtherWidgetState();
}

class _ProfileOtherWidgetState extends State<ProfileOtherWidget>
    with TickerProviderStateMixin {
  late ProfileOtherModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProfileOtherModel());

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
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(8.0),
          child: AppBar(
            backgroundColor: FlutterFlowTheme.of(context).tertiary,
            automaticallyImplyLeading: false,
            actions: [],
            centerTitle: false,
            elevation: 0.0,
          ),
        ),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).tertiary,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30.0),
                          bottomRight: Radius.circular(30.0),
                          topLeft: Radius.circular(0.0),
                          topRight: Radius.circular(0.0),
                        ),
                      ),
                      child: StreamBuilder<List<UsersRecord>>(
                        stream: queryUsersRecord(
                          queryBuilder: (usersRecord) => usersRecord.where(
                            'username',
                            isEqualTo: widget.username,
                          ),
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
                          List<UsersRecord> columnUsersRecordList =
                              snapshot.data!;
                          // Return an empty Container when the item does not exist.
                          if (snapshot.data!.isEmpty) {
                            return Container();
                          }
                          final columnUsersRecord =
                              columnUsersRecordList.isNotEmpty
                                  ? columnUsersRecordList.first
                                  : null;

                          return SingleChildScrollView(
                            primary: false,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      10.0, 10.0, 10.0, 5.0),
                                  child: StreamBuilder<List<UsersRecord>>(
                                    stream: queryUsersRecord(
                                      queryBuilder: (usersRecord) =>
                                          usersRecord.where(
                                        'username',
                                        isEqualTo: widget.username,
                                      ),
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
                                      List<UsersRecord> rowUsersRecordList =
                                          snapshot.data!;
                                      // Return an empty Container when the item does not exist.
                                      if (snapshot.data!.isEmpty) {
                                        return Container();
                                      }
                                      final rowUsersRecord =
                                          rowUsersRecordList.isNotEmpty
                                              ? rowUsersRecordList.first
                                              : null;

                                      return Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          FlutterFlowIconButton(
                                            borderColor: Color(0xFF0A0A0A),
                                            borderRadius: 10.0,
                                            borderWidth: 1.0,
                                            buttonSize: 30.0,
                                            fillColor: Color(0xFF0A0A0A),
                                            icon: Icon(
                                              Icons.arrow_back_ios_rounded,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .tertiary,
                                              size: 15.0,
                                            ),
                                            onPressed: () async {
                                              context.safePop();
                                            },
                                          ),
                                          Text(
                                            valueOrDefault<String>(
                                              rowUsersRecord?.username,
                                              '0',
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondary,
                                                  fontSize:
                                                      MediaQuery.sizeOf(context)
                                                                  .width <
                                                              768.0
                                                          ? 15.0
                                                          : 25.0,
                                                  letterSpacing: 0.0,
                                                ),
                                          ),
                                          FlutterFlowIconButton(
                                            borderColor: Color(0xFF0A0A0A),
                                            borderRadius: 10.0,
                                            borderWidth: 1.0,
                                            buttonSize: 30.0,
                                            fillColor: Color(0xFF0A0A0A),
                                            icon: Icon(
                                              Icons.keyboard_control,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .tertiary,
                                              size: 15.0,
                                            ),
                                            onPressed: () async {
                                              await showModalBottomSheet(
                                                isScrollControlled: true,
                                                backgroundColor:
                                                    Colors.transparent,
                                                enableDrag: false,
                                                context: context,
                                                builder: (context) {
                                                  return GestureDetector(
                                                    onTap: () {
                                                      FocusScope.of(context)
                                                          .unfocus();
                                                      FocusManager
                                                          .instance.primaryFocus
                                                          ?.unfocus();
                                                    },
                                                    child: Padding(
                                                      padding: MediaQuery
                                                          .viewInsetsOf(
                                                              context),
                                                      child: Container(
                                                        height:
                                                            MediaQuery.sizeOf(
                                                                        context)
                                                                    .height *
                                                                0.5,
                                                        child: BlockedWidget(
                                                          userDetails:
                                                              rowUsersRecord,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ).then((value) =>
                                                  safeSetState(() {}));
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Stack(
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      children: [
                                        StreamBuilder<List<StoriesRecord>>(
                                          stream: queryStoriesRecord(
                                            queryBuilder: (storiesRecord) =>
                                                storiesRecord
                                                    .where(
                                                      'user',
                                                      isEqualTo:
                                                          columnUsersRecord
                                                              ?.reference,
                                                    )
                                                    .where(
                                                      'expire_time',
                                                      isGreaterThan:
                                                          getCurrentTimestamp,
                                                    ),
                                            singleRecord: true,
                                          ),
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
                                            List<StoriesRecord>
                                                activeStoryIndicatorStoriesRecordList =
                                                snapshot.data!;
                                            // Return an empty Container when the item does not exist.
                                            if (snapshot.data!.isEmpty) {
                                              return Container();
                                            }
                                            final activeStoryIndicatorStoriesRecord =
                                                activeStoryIndicatorStoriesRecordList
                                                        .isNotEmpty
                                                    ? activeStoryIndicatorStoriesRecordList
                                                        .first
                                                    : null;

                                            return InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                await showModalBottomSheet(
                                                  isScrollControlled: true,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  barrierColor:
                                                      Color(0x00000000),
                                                  context: context,
                                                  builder: (context) {
                                                    return GestureDetector(
                                                      onTap: () {
                                                        FocusScope.of(context)
                                                            .unfocus();
                                                        FocusManager.instance
                                                            .primaryFocus
                                                            ?.unfocus();
                                                      },
                                                      child: Padding(
                                                        padding: MediaQuery
                                                            .viewInsetsOf(
                                                                context),
                                                        child: StoryWidget(
                                                          story:
                                                              activeStoryIndicatorStoriesRecord,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ).then((value) =>
                                                    safeSetState(() {}));
                                              },
                                              child: Container(
                                                width: 100.0,
                                                height: 100.0,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .primary,
                                                      Color(0xFF0D723A)
                                                    ],
                                                    stops: [0.0, 1.0],
                                                    begin: AlignmentDirectional(
                                                        1.0, -1.0),
                                                    end: AlignmentDirectional(
                                                        -1.0, 1.0),
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        Align(
                                          alignment:
                                              AlignmentDirectional(0.0, 0.0),
                                          child: Container(
                                            width: 93.0,
                                            height: 93.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              image: DecorationImage(
                                                fit: BoxFit.cover,
                                                image: Image.network(
                                                  functions.bunnyCDNImagePath(
                                                      valueOrDefault<String>(
                                                    columnUsersRecord?.photoUrl,
                                                    'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                  )),
                                                ).image,
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                width: 3.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    if (columnUsersRecord?.displayName !=
                                            null &&
                                        columnUsersRecord?.displayName != '')
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 6.0, 0.0, 0.0),
                                        child: Text(
                                          columnUsersRecord!.displayName,
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'Poppins',
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondary,
                                                fontSize:
                                                    MediaQuery.sizeOf(context)
                                                                .width <
                                                            768.0
                                                        ? 15.0
                                                        : 25.0,
                                                letterSpacing: 0.0,
                                              ),
                                        ),
                                      ),
                                    if (columnUsersRecord?.bio != null &&
                                        columnUsersRecord?.bio != '')
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 4.0, 0.0, 0.0),
                                        child: InkWell(
                                          splashColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () async {
                                            await showModalBottomSheet(
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              enableDrag: false,
                                              context: context,
                                              builder: (context) {
                                                return GestureDetector(
                                                  onTap: () {
                                                    FocusScope.of(context)
                                                        .unfocus();
                                                    FocusManager
                                                        .instance.primaryFocus
                                                        ?.unfocus();
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        MediaQuery.viewInsetsOf(
                                                            context),
                                                    child: Container(
                                                      height: MediaQuery.sizeOf(
                                                                  context)
                                                              .height *
                                                          0.9,
                                                      child: BioWidget(
                                                        userDetails:
                                                            columnUsersRecord
                                                                .reference,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ).then(
                                                (value) => safeSetState(() {}));
                                          },
                                          child: Text(
                                            columnUsersRecord!.bio
                                                .maybeHandleOverflow(
                                              maxChars: 30,
                                            ),
                                            maxLines: 1,
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondary,
                                                  fontSize: functions
                                                      .resizeFontBasedOnScreenSize(
                                                          MediaQuery.sizeOf(
                                                                  context)
                                                              .width,
                                                          13)
                                                      .toDouble(),
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                          ),
                                        ),
                                      ),
                                    if (columnUsersRecord?.website != null &&
                                        columnUsersRecord?.website != '')
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 4.0, 0.0, 0.0),
                                        child: InkWell(
                                          splashColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () async {
                                            await launchURL(
                                                columnUsersRecord.website);
                                          },
                                          child: Text(
                                            columnUsersRecord!.website,
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondary,
                                                  fontSize: functions
                                                      .resizeFontBasedOnScreenSize(
                                                          MediaQuery.sizeOf(
                                                                  context)
                                                              .width,
                                                          13)
                                                      .toDouble(),
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      15.0, 15.0, 15.0, 0.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 6.0, 0.0),
                                          child: AuthUserStreamWidget(
                                            builder: (context) => StreamBuilder<
                                                List<FollowersRecord>>(
                                              stream: queryFollowersRecord(
                                                parent: columnUsersRecord
                                                    ?.reference,
                                                singleRecord: true,
                                              ),
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
                                                List<FollowersRecord>
                                                    followUnfollowButtonFollowersRecordList =
                                                    snapshot.data!;
                                                final followUnfollowButtonFollowersRecord =
                                                    followUnfollowButtonFollowersRecordList
                                                            .isNotEmpty
                                                        ? followUnfollowButtonFollowersRecordList
                                                            .first
                                                        : null;

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
                                                    if ((currentUserDocument
                                                                ?.following
                                                                .toList() ??
                                                            [])
                                                        .contains(
                                                            columnUsersRecord
                                                                ?.reference)) {
                                                      await currentUserReference!
                                                          .update({
                                                        ...mapToFirestore(
                                                          {
                                                            'following':
                                                                FieldValue
                                                                    .arrayRemove([
                                                              columnUsersRecord
                                                                  ?.reference
                                                            ]),
                                                          },
                                                        ),
                                                      });

                                                      await followUnfollowButtonFollowersRecord!
                                                          .reference
                                                          .update({
                                                        ...mapToFirestore(
                                                          {
                                                            'userRefs': FieldValue
                                                                .arrayRemove([
                                                              currentUserReference
                                                            ]),
                                                          },
                                                        ),
                                                      });
                                                      _model
                                                          .timerFollowButtonActionsController
                                                          .onResetTimer();
                                                    } else {
                                                      await currentUserReference!
                                                          .update({
                                                        ...mapToFirestore(
                                                          {
                                                            'following':
                                                                FieldValue
                                                                    .arrayUnion([
                                                              columnUsersRecord
                                                                  ?.reference
                                                            ]),
                                                          },
                                                        ),
                                                      });

                                                      await followUnfollowButtonFollowersRecord!
                                                          .reference
                                                          .update({
                                                        ...mapToFirestore(
                                                          {
                                                            'userRefs':
                                                                FieldValue
                                                                    .arrayUnion([
                                                              currentUserReference
                                                            ]),
                                                          },
                                                        ),
                                                      });
                                                      _model
                                                          .timerFollowButtonActionsController
                                                          .onStartTimer();
                                                    }
                                                  },
                                                  child: Container(
                                                    width: MediaQuery.sizeOf(
                                                                context)
                                                            .width *
                                                        0.45,
                                                    height: 38.0,
                                                    decoration: BoxDecoration(
                                                      color: (currentUserDocument
                                                                      ?.following
                                                                      .toList() ??
                                                                  [])
                                                              .contains(
                                                                  columnUsersRecord
                                                                      ?.reference)
                                                          ? FlutterFlowTheme.of(
                                                                  context)
                                                              .secondary
                                                          : FlutterFlowTheme.of(
                                                                  context)
                                                              .secondary,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15.0),
                                                    ),
                                                    child: Align(
                                                      alignment:
                                                          AlignmentDirectional(
                                                              0.0, 0.0),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    8.0,
                                                                    6.0,
                                                                    8.0,
                                                                    6.0),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              () {
                                                                if (columnUsersRecord!
                                                                        .following
                                                                        .contains(
                                                                            currentUserReference) &&
                                                                    !(currentUserDocument?.following.toList() ??
                                                                            [])
                                                                        .contains(columnUsersRecord
                                                                            .reference)) {
                                                                  return 'Follow back';
                                                                } else if (!columnUsersRecord
                                                                        .following
                                                                        .contains(
                                                                            currentUserReference) &&
                                                                    !(currentUserDocument?.following.toList() ??
                                                                            [])
                                                                        .contains(
                                                                            columnUsersRecord.reference)) {
                                                                  return 'Follow';
                                                                } else {
                                                                  return 'Unfollow';
                                                                }
                                                              }(),
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'Poppins',
                                                                    color: (currentUserDocument?.following.toList() ??
                                                                                [])
                                                                            .contains(columnUsersRecord
                                                                                ?.reference)
                                                                        ? FlutterFlowTheme.of(context)
                                                                            .tertiary
                                                                        : Colors
                                                                            .white,
                                                                    fontSize: functions
                                                                        .resizeFontBasedOnScreenSize(
                                                                            MediaQuery.sizeOf(context).width,
                                                                            13)
                                                                        .toDouble(),
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  6.0, 0.0, 0.0, 0.0),
                                          child: Stack(
                                            children: [
                                              InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor:
                                                    Colors.transparent,
                                                onTap: () async {
                                                  FFAppState().tempUserList =
                                                      [];
                                                  FFAppState().addToTempUserList(
                                                      currentUserReference!);
                                                  FFAppState().update(() {});
                                                  FFAppState()
                                                      .addToTempUserList(
                                                          columnUsersRecord!
                                                              .reference);
                                                  FFAppState().update(() {});

                                                  var chatsRecordReference =
                                                      ChatsRecord.collection
                                                          .doc();
                                                  await chatsRecordReference
                                                      .set({
                                                    ...createChatsRecordData(
                                                      userA:
                                                          currentUserReference,
                                                      userB: columnUsersRecord
                                                          .reference,
                                                      lastMessage:
                                                          'Hey! Let\'s chat!',
                                                      lastMessageTime:
                                                          getCurrentTimestamp,
                                                      lastMessageSentBy:
                                                          currentUserReference,
                                                    ),
                                                    ...mapToFirestore(
                                                      {
                                                        'last_message_seen_by':
                                                            [
                                                          currentUserReference
                                                        ],
                                                        'users': FFAppState()
                                                            .tempUserList,
                                                      },
                                                    ),
                                                  });
                                                  _model.chat = ChatsRecord
                                                      .getDocumentFromData({
                                                    ...createChatsRecordData(
                                                      userA:
                                                          currentUserReference,
                                                      userB: columnUsersRecord
                                                          .reference,
                                                      lastMessage:
                                                          'Hey! Let\'s chat!',
                                                      lastMessageTime:
                                                          getCurrentTimestamp,
                                                      lastMessageSentBy:
                                                          currentUserReference,
                                                    ),
                                                    ...mapToFirestore(
                                                      {
                                                        'last_message_seen_by':
                                                            [
                                                          currentUserReference
                                                        ],
                                                        'users': FFAppState()
                                                            .tempUserList,
                                                      },
                                                    ),
                                                  }, chatsRecordReference);

                                                  context.pushNamed(
                                                    IndividualMessageWidget
                                                        .routeName,
                                                    queryParameters: {
                                                      'chat': serializeParam(
                                                        _model.chat?.reference,
                                                        ParamType
                                                            .DocumentReference,
                                                      ),
                                                    }.withoutNulls,
                                                  );

                                                  safeSetState(() {});
                                                },
                                                child: Container(
                                                  width:
                                                      MediaQuery.sizeOf(context)
                                                              .width *
                                                          0.45,
                                                  height: 38.0,
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15.0),
                                                  ),
                                                  child: Align(
                                                    alignment:
                                                        AlignmentDirectional(
                                                            0.0, 0.0),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  8.0,
                                                                  6.0,
                                                                  8.0,
                                                                  6.0),
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
                                                              'zm41tzrh' /* Message */,
                                                            ),
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'Poppins',
                                                                  fontSize:
                                                                      13.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              StreamBuilder<List<ChatsRecord>>(
                                                stream: queryChatsRecord(
                                                  queryBuilder: (chatsRecord) =>
                                                      chatsRecord
                                                          .where(
                                                            'user_a',
                                                            isEqualTo:
                                                                columnUsersRecord
                                                                    ?.reference,
                                                          )
                                                          .where(
                                                            'user_b',
                                                            isEqualTo:
                                                                currentUserReference,
                                                          ),
                                                  singleRecord: true,
                                                ),
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
                                                  List<ChatsRecord>
                                                      messageButton1ChatsRecordList =
                                                      snapshot.data!;
                                                  // Return an empty Container when the item does not exist.
                                                  if (snapshot.data!.isEmpty) {
                                                    return Container();
                                                  }
                                                  final messageButton1ChatsRecord =
                                                      messageButton1ChatsRecordList
                                                              .isNotEmpty
                                                          ? messageButton1ChatsRecordList
                                                              .first
                                                          : null;

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
                                                        IndividualMessageWidget
                                                            .routeName,
                                                        queryParameters: {
                                                          'chat':
                                                              serializeParam(
                                                            messageButton1ChatsRecord
                                                                ?.reference,
                                                            ParamType
                                                                .DocumentReference,
                                                          ),
                                                        }.withoutNulls,
                                                      );
                                                    },
                                                    child: Container(
                                                      width: MediaQuery.sizeOf(
                                                                  context)
                                                              .width *
                                                          0.45,
                                                      height: 38.0,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primary,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(15.0),
                                                      ),
                                                      child: Align(
                                                        alignment:
                                                            AlignmentDirectional(
                                                                0.0, 0.0),
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      8.0,
                                                                      6.0,
                                                                      8.0,
                                                                      6.0),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Text(
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  'l6zbnbid' /* Message */,
                                                                ),
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      fontSize:
                                                                          13.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              StreamBuilder<List<ChatsRecord>>(
                                                stream: queryChatsRecord(
                                                  queryBuilder: (chatsRecord) =>
                                                      chatsRecord
                                                          .where(
                                                            'user_a',
                                                            isEqualTo:
                                                                currentUserReference,
                                                          )
                                                          .where(
                                                            'user_b',
                                                            isEqualTo:
                                                                columnUsersRecord
                                                                    ?.reference,
                                                          ),
                                                  singleRecord: true,
                                                ),
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
                                                  List<ChatsRecord>
                                                      messageButton2ChatsRecordList =
                                                      snapshot.data!;
                                                  // Return an empty Container when the item does not exist.
                                                  if (snapshot.data!.isEmpty) {
                                                    return Container();
                                                  }
                                                  final messageButton2ChatsRecord =
                                                      messageButton2ChatsRecordList
                                                              .isNotEmpty
                                                          ? messageButton2ChatsRecordList
                                                              .first
                                                          : null;

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
                                                        IndividualMessageWidget
                                                            .routeName,
                                                        queryParameters: {
                                                          'chat':
                                                              serializeParam(
                                                            messageButton2ChatsRecord
                                                                ?.reference,
                                                            ParamType
                                                                .DocumentReference,
                                                          ),
                                                        }.withoutNulls,
                                                      );
                                                    },
                                                    child: Container(
                                                      width: MediaQuery.sizeOf(
                                                                  context)
                                                              .width *
                                                          0.45,
                                                      height: 38.0,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primary,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(15.0),
                                                      ),
                                                      child: Align(
                                                        alignment:
                                                            AlignmentDirectional(
                                                                0.0, 0.0),
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      8.0,
                                                                      6.0,
                                                                      8.0,
                                                                      6.0),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Text(
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  'rmn8ix5j' /* Message */,
                                                                ),
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      fontSize: functions
                                                                          .resizeFontBasedOnScreenSize(
                                                                              MediaQuery.sizeOf(context).width,
                                                                              13)
                                                                          .toDouble(),
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      FlutterFlowTimer(
                                        initialTime: _model
                                            .timerFollowButtonActionsInitialTimeMs,
                                        getDisplayTime: (value) =>
                                            StopWatchTimer.getDisplayTime(value,
                                                milliSecond: false),
                                        controller: _model
                                            .timerFollowButtonActionsController,
                                        onChanged:
                                            (value, displayTime, shouldUpdate) {
                                          _model.timerFollowButtonActionsMilliseconds =
                                              value;
                                          _model.timerFollowButtonActionsValue =
                                              displayTime;
                                          if (shouldUpdate) safeSetState(() {});
                                        },
                                        onEnded: () async {
                                          var notificationsRecordReference =
                                              NotificationsRecord.createDoc(
                                                  columnUsersRecord!.reference);
                                          await notificationsRecordReference
                                              .set(
                                                  createNotificationsRecordData(
                                            notificationType: 'Follow',
                                            userRef: currentUserReference,
                                            timeCreated: getCurrentTimestamp,
                                          ));
                                          _model.notification = NotificationsRecord
                                              .getDocumentFromData(
                                                  createNotificationsRecordData(
                                                    notificationType: 'Follow',
                                                    userRef:
                                                        currentUserReference,
                                                    timeCreated:
                                                        getCurrentTimestamp,
                                                  ),
                                                  notificationsRecordReference);

                                          await columnUsersRecord.reference
                                              .update({
                                            ...mapToFirestore(
                                              {
                                                'unreadNotifications':
                                                    FieldValue.arrayUnion([
                                                  _model.notification?.reference
                                                ]),
                                              },
                                            ),
                                          });
                                          triggerPushNotification(
                                            notificationTitle: 'GymFeed',
                                            notificationText:
                                                '${valueOrDefault(currentUserDocument?.username, '')} started following you.',
                                            notificationImageUrl:
                                                currentUserPhoto,
                                            notificationSound: 'default',
                                            userRefs: [
                                              columnUsersRecord.reference
                                            ],
                                            initialPageName: 'ProfileOther',
                                            parameterData: {
                                              'username': valueOrDefault(
                                                  currentUserDocument?.username,
                                                  ''),
                                            },
                                          );

                                          safeSetState(() {});
                                        },
                                        textAlign: TextAlign.start,
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'Poppins',
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              fontSize: 0.0,
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      15.0, 15.0, 15.0, 10.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        10.0, 0.0, 0.0, 0.0),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Stack(
                                                          children: [
                                                            if ((columnUsersRecord
                                                                        ?.workoutLevel ==
                                                                    'Intermediate') ||
                                                                (columnUsersRecord
                                                                        ?.workoutLevel ==
                                                                    'Srednji'))
                                                              Icon(
                                                                FFIcons.kx96B1,
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                                size: MediaQuery.sizeOf(context)
                                                                            .width <
                                                                        768.0
                                                                    ? 24.0
                                                                    : 34.0,
                                                              ),
                                                            if ((columnUsersRecord
                                                                        ?.workoutLevel ==
                                                                    'Advanced') ||
                                                                (columnUsersRecord
                                                                        ?.workoutLevel ==
                                                                    'Napredni'))
                                                              Icon(
                                                                FFIcons.kx96B11,
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                                size: MediaQuery.sizeOf(context)
                                                                            .width <
                                                                        768.0
                                                                    ? 24.0
                                                                    : 34.0,
                                                              ),
                                                            if ((columnUsersRecord
                                                                        ?.workoutLevel ==
                                                                    'Begginer') ||
                                                                (columnUsersRecord
                                                                        ?.workoutLevel ==
                                                                    'Početnik'))
                                                              Icon(
                                                                Icons
                                                                    .star_border,
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                                size: MediaQuery.sizeOf(context)
                                                                            .width <
                                                                        768.0
                                                                    ? 24.0
                                                                    : 34.0,
                                                              ),
                                                          ],
                                                        ),
                                                        Text(
                                                          FFLocalizations.of(
                                                                  context)
                                                              .getText(
                                                            '4fy6g1gm' /* Level */,
                                                          ),
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'Poppins',
                                                                color: Color(
                                                                    0xFF0A0A0A),
                                                                fontSize:
                                                                    MediaQuery.sizeOf(context).width <
                                                                            768.0
                                                                        ? 12.0
                                                                        : 22.0,
                                                                letterSpacing:
                                                                    0.0,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 2.0,
                                              height: 30.0,
                                              decoration: BoxDecoration(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondary,
                                              ),
                                            ),
                                            Expanded(
                                              child: InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor:
                                                    Colors.transparent,
                                                onTap: () async {
                                                  context.pushNamed(
                                                    FollowersFollowingOtherWidget
                                                        .routeName,
                                                    queryParameters: {
                                                      'userRef': serializeParam(
                                                        columnUsersRecord
                                                            ?.reference,
                                                        ParamType
                                                            .DocumentReference,
                                                      ),
                                                    }.withoutNulls,
                                                  );
                                                },
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    StreamBuilder<
                                                        List<FollowersRecord>>(
                                                      stream:
                                                          queryFollowersRecord(
                                                        parent:
                                                            columnUsersRecord
                                                                ?.reference,
                                                        singleRecord: true,
                                                      ),
                                                      builder:
                                                          (context, snapshot) {
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
                                                        List<FollowersRecord>
                                                            numberFollowersRecordList =
                                                            snapshot.data!;
                                                        final numberFollowersRecord =
                                                            numberFollowersRecordList
                                                                    .isNotEmpty
                                                                ? numberFollowersRecordList
                                                                    .first
                                                                : null;

                                                        return Text(
                                                          valueOrDefault<
                                                              String>(
                                                            formatNumber(
                                                              numberFollowersRecord
                                                                  ?.userRefs
                                                                  .length,
                                                              formatType:
                                                                  FormatType
                                                                      .compact,
                                                            ),
                                                            '0',
                                                          ),
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'Poppins',
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondary,
                                                                fontSize: functions
                                                                    .resizeFontBasedOnScreenSize(
                                                                        MediaQuery.sizeOf(context)
                                                                            .width,
                                                                        17)
                                                                    .toDouble(),
                                                                letterSpacing:
                                                                    0.0,
                                                              ),
                                                        );
                                                      },
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  2.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Text(
                                                        FFLocalizations.of(
                                                                context)
                                                            .getText(
                                                          'l4yq21yh' /* Followers */,
                                                        ),
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'Poppins',
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondary,
                                                                  fontSize: functions
                                                                      .resizeFontBasedOnScreenSize(
                                                                          MediaQuery.sizeOf(context)
                                                                              .width,
                                                                          12)
                                                                      .toDouble(),
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal,
                                                                ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 2.0,
                                              height: 30.0,
                                              decoration: BoxDecoration(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondary,
                                              ),
                                            ),
                                            Expanded(
                                              child: InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor:
                                                    Colors.transparent,
                                                onTap: () async {
                                                  context.pushNamed(
                                                    FollowersFollowingOtherWidget
                                                        .routeName,
                                                    queryParameters: {
                                                      'userRef': serializeParam(
                                                        columnUsersRecord
                                                            ?.reference,
                                                        ParamType
                                                            .DocumentReference,
                                                      ),
                                                    }.withoutNulls,
                                                  );
                                                },
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    Text(
                                                      valueOrDefault<String>(
                                                        formatNumber(
                                                          columnUsersRecord
                                                              ?.following
                                                              .length,
                                                          formatType: FormatType
                                                              .compact,
                                                        ),
                                                        '0',
                                                      ),
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'Poppins',
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondary,
                                                                fontSize: functions
                                                                    .resizeFontBasedOnScreenSize(
                                                                        MediaQuery.sizeOf(context)
                                                                            .width,
                                                                        17)
                                                                    .toDouble(),
                                                                letterSpacing:
                                                                    0.0,
                                                              ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  2.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Text(
                                                        FFLocalizations.of(
                                                                context)
                                                            .getText(
                                                          'taf8pvzf' /* Following */,
                                                        ),
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'Poppins',
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondary,
                                                                  fontSize: functions
                                                                      .resizeFontBasedOnScreenSize(
                                                                          MediaQuery.sizeOf(context)
                                                                              .width,
                                                                          12)
                                                                      .toDouble(),
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal,
                                                                ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
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
                          );
                        },
                      ),
                    ),
                    Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      height: MediaQuery.sizeOf(context).height * 1.0,
                      child: Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 0.0),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment(0.0, 0),
                              child: TabBar(
                                labelColor:
                                    FlutterFlowTheme.of(context).tertiary,
                                unselectedLabelColor:
                                    FlutterFlowTheme.of(context).accent2,
                                labelStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Poppins',
                                      fontSize: 15.0,
                                      letterSpacing: 0.0,
                                      lineHeight: 0.0,
                                    ),
                                unselectedLabelStyle: TextStyle(),
                                indicatorColor:
                                    FlutterFlowTheme.of(context).primary,
                                indicatorWeight: 2.0,
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    30.0, 0.0, 30.0, 0.0),
                                tabs: [
                                  Tab(
                                    text: FFLocalizations.of(context).getText(
                                      '1ns1kqpw' /* Posts */,
                                    ),
                                    iconMargin: EdgeInsets.all(1.0),
                                  ),
                                  Tab(
                                    text: FFLocalizations.of(context).getText(
                                      'suueoyxj' /* Tagged */,
                                    ),
                                  ),
                                  Tab(
                                    text: FFLocalizations.of(context).getText(
                                      'rbxccos2' /* Workout */,
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
                                  KeepAliveWidgetWrapper(
                                    builder: (context) =>
                                        StreamBuilder<List<UsersRecord>>(
                                      stream: queryUsersRecord(
                                        queryBuilder: (usersRecord) =>
                                            usersRecord.where(
                                          'username',
                                          isEqualTo: widget.username,
                                        ),
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
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        List<UsersRecord>
                                            columnUsersRecordList =
                                            snapshot.data!;
                                        // Return an empty Container when the item does not exist.
                                        if (snapshot.data!.isEmpty) {
                                          return Container();
                                        }
                                        final columnUsersRecord =
                                            columnUsersRecordList.isNotEmpty
                                                ? columnUsersRecordList.first
                                                : null;

                                        return SingleChildScrollView(
                                          primary: false,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        0.0, 0.0, 0.0, 200.0),
                                                child: Container(
                                                  width:
                                                      MediaQuery.sizeOf(context)
                                                              .width *
                                                          0.96,
                                                  constraints: BoxConstraints(
                                                    minHeight: 500.0,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryBackground,
                                                  ),
                                                  child: StreamBuilder<
                                                      List<PostsRecord>>(
                                                    stream: queryPostsRecord(
                                                      queryBuilder: (postsRecord) =>
                                                          postsRecord
                                                              .where(
                                                                'post_user',
                                                                isEqualTo:
                                                                    columnUsersRecord
                                                                        ?.reference,
                                                              )
                                                              .where(
                                                                'deleted',
                                                                isEqualTo:
                                                                    false,
                                                              )
                                                              .orderBy(
                                                                  'time_posted',
                                                                  descending:
                                                                      true),
                                                    ),
                                                    builder:
                                                        (context, snapshot) {
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
                                                      List<PostsRecord>
                                                          profilePhotosPostsRecordList =
                                                          snapshot.data!;

                                                      return GridView.builder(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        gridDelegate:
                                                            SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount: 3,
                                                          crossAxisSpacing: 1.0,
                                                          mainAxisSpacing: 1.0,
                                                          childAspectRatio: 1.0,
                                                        ),
                                                        primary: false,
                                                        shrinkWrap: true,
                                                        scrollDirection:
                                                            Axis.vertical,
                                                        itemCount:
                                                            profilePhotosPostsRecordList
                                                                .length,
                                                        itemBuilder: (context,
                                                            profilePhotosIndex) {
                                                          final profilePhotosPostsRecord =
                                                              profilePhotosPostsRecordList[
                                                                  profilePhotosIndex];
                                                          return Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        10.0,
                                                                        10.0,
                                                                        10.0,
                                                                        10.0),
                                                            child: InkWell(
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
                                                                      profilePhotosPostsRecord
                                                                          .reference,
                                                                      ParamType
                                                                          .DocumentReference,
                                                                    ),
                                                                  }.withoutNulls,
                                                                );
                                                              },
                                                              child: Container(
                                                                width: 100.0,
                                                                height: 100.0,
                                                                constraints:
                                                                    BoxConstraints(
                                                                  minHeight:
                                                                      400.0,
                                                                ),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Color(
                                                                      0xFF111111),
                                                                  image:
                                                                      DecorationImage(
                                                                    fit: BoxFit
                                                                        .cover,
                                                                    image: Image
                                                                        .network(
                                                                      functions.bunnyCDNImagePath(
                                                                          profilePhotosPostsRecord
                                                                              .postPhoto),
                                                                    ).image,
                                                                  ),
                                                                ),
                                                                child:
                                                                    Visibility(
                                                                  visible: profilePhotosPostsRecord
                                                                              .postVideo !=
                                                                          '',
                                                                  child:
                                                                      FlutterFlowVideoPlayer(
                                                                    path: functions
                                                                        .bunnyCDNVideoPath(
                                                                            profilePhotosPostsRecord.postVideo),
                                                                    videoType:
                                                                        VideoType
                                                                            .network,
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
                                                                        false,
                                                                    allowPlaybackSpeedMenu:
                                                                        false,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  KeepAliveWidgetWrapper(
                                    builder: (context) =>
                                        StreamBuilder<List<UsersRecord>>(
                                      stream: queryUsersRecord(
                                        queryBuilder: (usersRecord) =>
                                            usersRecord.where(
                                          'username',
                                          isEqualTo: widget.username,
                                        ),
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
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        List<UsersRecord>
                                            columnUsersRecordList =
                                            snapshot.data!;
                                        // Return an empty Container when the item does not exist.
                                        if (snapshot.data!.isEmpty) {
                                          return Container();
                                        }
                                        final columnUsersRecord =
                                            columnUsersRecordList.isNotEmpty
                                                ? columnUsersRecordList.first
                                                : null;

                                        return SingleChildScrollView(
                                          primary: false,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        0.0, 0.0, 0.0, 150.0),
                                                child: StreamBuilder<
                                                    List<PostsRecord>>(
                                                  stream: queryPostsRecord(
                                                    queryBuilder: (postsRecord) =>
                                                        postsRecord
                                                            .where(
                                                              'tagged_users',
                                                              arrayContains:
                                                                  columnUsersRecord
                                                                      ?.reference,
                                                            )
                                                            .where(
                                                              'deleted',
                                                              isEqualTo: false,
                                                            )
                                                            .orderBy(
                                                                'time_posted',
                                                                descending:
                                                                    true),
                                                  ),
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
                                                    List<PostsRecord>
                                                        taggedPhotosPostsRecordList =
                                                        snapshot.data!;

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
                                                      scrollDirection:
                                                          Axis.vertical,
                                                      itemCount:
                                                          taggedPhotosPostsRecordList
                                                              .length,
                                                      itemBuilder: (context,
                                                          taggedPhotosIndex) {
                                                        final taggedPhotosPostsRecord =
                                                            taggedPhotosPostsRecordList[
                                                                taggedPhotosIndex];
                                                        return Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      10.0,
                                                                      10.0,
                                                                      10.0,
                                                                      10.0),
                                                          child: InkWell(
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
                                                              context.pushNamed(
                                                                PostDetailsWidget
                                                                    .routeName,
                                                                queryParameters:
                                                                    {
                                                                  'post':
                                                                      serializeParam(
                                                                    taggedPhotosPostsRecord
                                                                        .reference,
                                                                    ParamType
                                                                        .DocumentReference,
                                                                  ),
                                                                }.withoutNulls,
                                                              );
                                                            },
                                                            child: Container(
                                                              width: 100.0,
                                                              height: 100.0,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Color(
                                                                    0xFF111111),
                                                                image:
                                                                    DecorationImage(
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  image: Image
                                                                      .network(
                                                                    functions.bunnyCDNImagePath(
                                                                        taggedPhotosPostsRecord
                                                                            .postPhoto),
                                                                  ).image,
                                                                ),
                                                              ),
                                                              child: Visibility(
                                                                visible: taggedPhotosPostsRecord
                                                                            .postVideo !=
                                                                        '',
                                                                child:
                                                                    FlutterFlowVideoPlayer(
                                                                  path: functions
                                                                      .bunnyCDNVideoPath(
                                                                          taggedPhotosPostsRecord
                                                                              .postVideo),
                                                                  videoType:
                                                                      VideoType
                                                                          .network,
                                                                  width: 100.0,
                                                                  height: 100.0,
                                                                  autoPlay:
                                                                      false,
                                                                  looping: true,
                                                                  showControls:
                                                                      false,
                                                                  allowFullScreen:
                                                                      false,
                                                                  allowPlaybackSpeedMenu:
                                                                      false,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  KeepAliveWidgetWrapper(
                                    builder: (context) => Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 10.0, 0.0, 0.0),
                                      child: SingleChildScrollView(
                                        primary: false,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Column(
                                              mainAxisSize: MainAxisSize.max,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          16.0, 0.0, 16.0, 0.0),
                                                  child: StreamBuilder<
                                                      List<UsersRecord>>(
                                                    stream: queryUsersRecord(
                                                      queryBuilder:
                                                          (usersRecord) =>
                                                              usersRecord.where(
                                                        'username',
                                                        isEqualTo:
                                                            widget.username,
                                                      ),
                                                      singleRecord: true,
                                                    ),
                                                    builder:
                                                        (context, snapshot) {
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
                                                      List<UsersRecord>
                                                          columnUsersRecordList =
                                                          snapshot.data!;
                                                      final columnUsersRecord =
                                                          columnUsersRecordList
                                                                  .isNotEmpty
                                                              ? columnUsersRecordList
                                                                  .first
                                                              : null;

                                                      return Column(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        0.0,
                                                                        0.0,
                                                                        150.0),
                                                            child: StreamBuilder<
                                                                List<
                                                                    UserTrainingsRecord>>(
                                                              stream:
                                                                  queryUserTrainingsRecord(
                                                                queryBuilder: (userTrainingsRecord) =>
                                                                    userTrainingsRecord
                                                                        .where(
                                                                          'userTraining',
                                                                          isEqualTo:
                                                                              columnUsersRecord?.reference,
                                                                        )
                                                                        .orderBy(
                                                                            'TrainingDate')
                                                                        .orderBy(
                                                                            'TrainingTime'),
                                                              ),
                                                              builder: (context,
                                                                  snapshot) {
                                                                // Customize what your widget looks like when it's loading.
                                                                if (!snapshot
                                                                    .hasData) {
                                                                  return Center(
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
                                                                          Colors
                                                                              .white,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  );
                                                                }
                                                                List<UserTrainingsRecord>
                                                                    trainingfeedUserTrainingsRecordList =
                                                                    snapshot
                                                                        .data!;

                                                                return ListView
                                                                    .builder(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                  primary:
                                                                      false,
                                                                  shrinkWrap:
                                                                      true,
                                                                  scrollDirection:
                                                                      Axis.vertical,
                                                                  itemCount:
                                                                      trainingfeedUserTrainingsRecordList
                                                                          .length,
                                                                  itemBuilder:
                                                                      (context,
                                                                          trainingfeedIndex) {
                                                                    final trainingfeedUserTrainingsRecord =
                                                                        trainingfeedUserTrainingsRecordList[
                                                                            trainingfeedIndex];
                                                                    return Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          4.0,
                                                                          0.0,
                                                                          8.0),
                                                                      child: StreamBuilder<
                                                                          UsersRecord>(
                                                                        stream:
                                                                            UsersRecord.getDocument(trainingfeedUserTrainingsRecord.userTraining!),
                                                                        builder:
                                                                            (context,
                                                                                snapshot) {
                                                                          // Customize what your widget looks like when it's loading.
                                                                          if (!snapshot
                                                                              .hasData) {
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

                                                                          final trainingListUsersRecord =
                                                                              snapshot.data!;

                                                                          return Container(
                                                                            width:
                                                                                MediaQuery.sizeOf(context).width * 1.0,
                                                                            height:
                                                                                122.0,
                                                                            constraints:
                                                                                BoxConstraints(
                                                                              maxHeight: double.infinity,
                                                                            ),
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: Color(0xFF111111),
                                                                              image: DecorationImage(
                                                                                fit: BoxFit.cover,
                                                                                image: Image.network(
                                                                                  functions.bunnyCDNImagePath(trainingfeedUserTrainingsRecord.trainingBackgroundImage),
                                                                                ).image,
                                                                              ),
                                                                              boxShadow: [
                                                                                BoxShadow(
                                                                                  blurRadius: 4.0,
                                                                                  color: Color(0x32000000),
                                                                                  offset: Offset(
                                                                                    0.0,
                                                                                    2.0,
                                                                                  ),
                                                                                )
                                                                              ],
                                                                              borderRadius: BorderRadius.circular(20.0),
                                                                              border: Border.all(
                                                                                color: Color(0xFF111111),
                                                                              ),
                                                                            ),
                                                                            child:
                                                                                Align(
                                                                              alignment: AlignmentDirectional(0.0, 0.0),
                                                                              child: InkWell(
                                                                                splashColor: Colors.transparent,
                                                                                focusColor: Colors.transparent,
                                                                                hoverColor: Colors.transparent,
                                                                                highlightColor: Colors.transparent,
                                                                                onTap: () async {
                                                                                  context.pushNamed(
                                                                                    TrainingpostDetailsWidget.routeName,
                                                                                    queryParameters: {
                                                                                      'userRecord': serializeParam(
                                                                                        trainingListUsersRecord,
                                                                                        ParamType.Document,
                                                                                      ),
                                                                                      'trainingReference': serializeParam(
                                                                                        trainingfeedUserTrainingsRecord.reference,
                                                                                        ParamType.DocumentReference,
                                                                                      ),
                                                                                    }.withoutNulls,
                                                                                    extra: <String, dynamic>{
                                                                                      'userRecord': trainingListUsersRecord,
                                                                                    },
                                                                                  );
                                                                                },
                                                                                child: Column(
                                                                                  mainAxisSize: MainAxisSize.max,
                                                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                                                  children: [
                                                                                    Align(
                                                                                      alignment: AlignmentDirectional(0.0, 0.0),
                                                                                      child: Column(
                                                                                        mainAxisSize: MainAxisSize.max,
                                                                                        mainAxisAlignment: MainAxisAlignment.end,
                                                                                        children: [
                                                                                          Padding(
                                                                                            padding: EdgeInsetsDirectional.fromSTEB(10.0, 0.0, 0.0, 2.0),
                                                                                            child: Row(
                                                                                              mainAxisSize: MainAxisSize.max,
                                                                                              children: [
                                                                                                Text(
                                                                                                  trainingfeedUserTrainingsRecord.trainingTitle,
                                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                        fontFamily: 'Poppins',
                                                                                                        color: FlutterFlowTheme.of(context).tertiary,
                                                                                                        fontSize: MediaQuery.sizeOf(context).width < 768.0 ? 20.0 : 30.0,
                                                                                                        letterSpacing: 0.0,
                                                                                                      ),
                                                                                                ),
                                                                                              ],
                                                                                            ),
                                                                                          ),
                                                                                          Padding(
                                                                                            padding: EdgeInsetsDirectional.fromSTEB(10.0, 0.0, 10.0, 10.0),
                                                                                            child: Row(
                                                                                              mainAxisSize: MainAxisSize.max,
                                                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                                                              crossAxisAlignment: CrossAxisAlignment.end,
                                                                                              children: [
                                                                                                RichText(
                                                                                                  textScaler: MediaQuery.of(context).textScaler,
                                                                                                  text: TextSpan(
                                                                                                    children: [
                                                                                                      TextSpan(
                                                                                                        text: FFLocalizations.of(context).getText(
                                                                                                          'tkv1vzm1' /* Time:  */,
                                                                                                        ),
                                                                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                              fontFamily: 'Poppins',
                                                                                                              color: FlutterFlowTheme.of(context).tertiary,
                                                                                                              fontSize: MediaQuery.sizeOf(context).width < 768.0 ? 10.0 : 20.0,
                                                                                                              letterSpacing: 0.0,
                                                                                                              fontWeight: FontWeight.bold,
                                                                                                            ),
                                                                                                      ),
                                                                                                      TextSpan(
                                                                                                        text: trainingfeedUserTrainingsRecord.trainingTime,
                                                                                                        style: TextStyle(
                                                                                                          color: Color(0xFF0FF76D),
                                                                                                          fontSize: MediaQuery.sizeOf(context).width < 768.0 ? 10.0 : 20.0,
                                                                                                        ),
                                                                                                      )
                                                                                                    ],
                                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                          fontFamily: 'Poppins',
                                                                                                          fontSize: functions.resizeFontBasedOnScreenSize(MediaQuery.sizeOf(context).width, 10).toDouble(),
                                                                                                          letterSpacing: 0.0,
                                                                                                        ),
                                                                                                  ),
                                                                                                ),
                                                                                                RichText(
                                                                                                  textScaler: MediaQuery.of(context).textScaler,
                                                                                                  text: TextSpan(
                                                                                                    children: [
                                                                                                      TextSpan(
                                                                                                        text: FFLocalizations.of(context).getText(
                                                                                                          'iak9oa9k' /* Date:  */,
                                                                                                        ),
                                                                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                              fontFamily: 'Poppins',
                                                                                                              color: FlutterFlowTheme.of(context).tertiary,
                                                                                                              fontSize: MediaQuery.sizeOf(context).width < 768.0 ? 10.0 : 20.0,
                                                                                                              letterSpacing: 0.0,
                                                                                                              fontWeight: FontWeight.bold,
                                                                                                            ),
                                                                                                      ),
                                                                                                      TextSpan(
                                                                                                        text: trainingfeedUserTrainingsRecord.trainingDate,
                                                                                                        style: TextStyle(
                                                                                                          color: Color(0xFF0FF76D),
                                                                                                          fontSize: MediaQuery.sizeOf(context).width < 768.0 ? 10.0 : 20.0,
                                                                                                        ),
                                                                                                      )
                                                                                                    ],
                                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                          fontFamily: 'Poppins',
                                                                                                          fontSize: functions.resizeFontBasedOnScreenSize(MediaQuery.sizeOf(context).width, 10).toDouble(),
                                                                                                          letterSpacing: 0.0,
                                                                                                        ),
                                                                                                  ),
                                                                                                ),
                                                                                                RichText(
                                                                                                  textScaler: MediaQuery.of(context).textScaler,
                                                                                                  text: TextSpan(
                                                                                                    children: [
                                                                                                      TextSpan(
                                                                                                        text: FFLocalizations.of(context).getText(
                                                                                                          'uv3hr95i' /* Category:  */,
                                                                                                        ),
                                                                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                              fontFamily: 'Poppins',
                                                                                                              color: FlutterFlowTheme.of(context).tertiary,
                                                                                                              fontSize: MediaQuery.sizeOf(context).width < 768.0 ? 10.0 : 20.0,
                                                                                                              letterSpacing: 0.0,
                                                                                                              fontWeight: FontWeight.bold,
                                                                                                            ),
                                                                                                      ),
                                                                                                      TextSpan(
                                                                                                        text: trainingfeedUserTrainingsRecord.trainingCategory,
                                                                                                        style: TextStyle(
                                                                                                          color: Color(0xFF0FF76D),
                                                                                                          fontSize: MediaQuery.sizeOf(context).width < 768.0 ? 10.0 : 20.0,
                                                                                                        ),
                                                                                                      )
                                                                                                    ],
                                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                          fontFamily: 'Poppins',
                                                                                                          fontSize: functions.resizeFontBasedOnScreenSize(MediaQuery.sizeOf(context).width, 10).toDouble(),
                                                                                                          letterSpacing: 0.0,
                                                                                                        ),
                                                                                                  ),
                                                                                                ),
                                                                                              ].divide(SizedBox(width: 10.0)),
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          );
                                                                        },
                                                                      ),
                                                                    );
                                                                  },
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ],
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
                                ],
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
          ),
        ),
      ),
    );
  }
}
