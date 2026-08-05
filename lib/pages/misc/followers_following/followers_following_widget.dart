import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/components/follower_componant/follower_componant_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'followers_following_model.dart';
export 'followers_following_model.dart';

class FollowersFollowingWidget extends StatefulWidget {
  const FollowersFollowingWidget({
    super.key,
    int? followersTabIndex,
  }) : this.followersTabIndex = followersTabIndex ?? 0;

  final int followersTabIndex;

  static String routeName = 'FollowersFollowing';
  static String routePath = 'followersFollowing';

  @override
  State<FollowersFollowingWidget> createState() =>
      _FollowersFollowingWidgetState();
}

class _FollowersFollowingWidgetState extends State<FollowersFollowingWidget>
    with TickerProviderStateMixin {
  late FollowersFollowingModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FollowersFollowingModel());

    _model.tabBarController = TabController(
      vsync: this,
      length: 2,
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
            padding: EdgeInsetsDirectional.fromSTEB(0.0, 50.0, 0.0, 0.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Opacity(
                      opacity: 0.0,
                      child: Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(10.0, 0.0, 0.0, 0.0),
                        child: Icon(
                          Icons.chevron_left,
                          color: FlutterFlowTheme.of(context).tertiary,
                          size: 20.0,
                        ),
                      ),
                    ),
                    AuthUserStreamWidget(
                      builder: (context) => Text(
                        currentUserDisplayName,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Poppins',
                              fontSize: functions
                                  .resizeFontBasedOnScreenSize(
                                      MediaQuery.sizeOf(context).width, 15)
                                  .toDouble(),
                              letterSpacing: 0.0,
                            ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 10.0, 0.0),
                      child: InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          context.safePop();
                        },
                        child: Icon(
                          Icons.close,
                          color: FlutterFlowTheme.of(context).tertiary,
                          size: 15.0,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: MediaQuery.sizeOf(context).width * 1.0,
                  height: MediaQuery.sizeOf(context).height * 1.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                  ),
                  child: StreamBuilder<List<FollowersRecord>>(
                    stream: queryFollowersRecord(
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        );
                      }
                      List<FollowersRecord> tabBarFollowersRecordList =
                          snapshot.data!;
                      final tabBarFollowersRecord =
                          tabBarFollowersRecordList.isNotEmpty
                              ? tabBarFollowersRecordList.first
                              : null;

                      return Column(
                        children: [
                          Align(
                            alignment: Alignment(0.0, 0),
                            child: TabBar(
                              labelColor: FlutterFlowTheme.of(context).tertiary,
                              unselectedLabelColor:
                                  FlutterFlowTheme.of(context).accent1,
                              labelStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Poppins',
                                    fontSize: 15.0,
                                    letterSpacing: 0.0,
                                  ),
                              unselectedLabelStyle: TextStyle(),
                              indicatorColor:
                                  FlutterFlowTheme.of(context).primary,
                              indicatorWeight: 2.0,
                              tabs: [
                                Tab(
                                  text: valueOrDefault<String>(
                                    '${formatNumber(
                                      tabBarFollowersRecord?.userRefs.length,
                                      formatType: FormatType.compact,
                                    )} Followers',
                                    '0 Followers',
                                  ),
                                ),
                                AuthUserStreamWidget(
                                  builder: (context) => Tab(
                                    text: valueOrDefault<String>(
                                      '${formatNumber(
                                        (currentUserDocument?.following
                                                    .toList() ??
                                                [])
                                            .length,
                                        formatType: FormatType.compact,
                                      )} Following',
                                      '0 Followers',
                                    ),
                                  ),
                                ),
                              ],
                              controller: _model.tabBarController,
                              onTap: (i) async {
                                [() async {}, () async {}][i]();
                              },
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _model.tabBarController,
                              children: [
                                KeepAliveWidgetWrapper(
                                  builder: (context) => Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        15.0, 0.0, 15.0, 0.0),
                                    child: Builder(
                                      builder: (context) {
                                        final followers = tabBarFollowersRecord
                                                ?.userRefs
                                                .toList() ??
                                            [];

                                        return ListView.builder(
                                          padding: EdgeInsets.fromLTRB(
                                            0,
                                            0,
                                            0,
                                            150.0,
                                          ),
                                          shrinkWrap: true,
                                          scrollDirection: Axis.vertical,
                                          itemCount: followers.length,
                                          itemBuilder:
                                              (context, followersIndex) {
                                            final followersItem =
                                                followers[followersIndex];
                                            return Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 12.0, 0.0, 0.0),
                                              child: StreamBuilder<UsersRecord>(
                                                stream: UsersRecord.getDocument(
                                                    followersItem),
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

                                                  final rowUsersRecord =
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
                                                      if (rowUsersRecord
                                                              .reference ==
                                                          currentUserReference) {
                                                        context.pushNamed(
                                                            ProfileWidget
                                                                .routeName);
                                                      } else {
                                                        context.pushNamed(
                                                          ProfileOtherWidget
                                                              .routeName,
                                                          queryParameters: {
                                                            'username':
                                                                serializeParam(
                                                              rowUsersRecord
                                                                  .username,
                                                              ParamType.String,
                                                            ),
                                                          }.withoutNulls,
                                                        );
                                                      }
                                                    },
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Container(
                                                          width: 55.0,
                                                          height: 55.0,
                                                          clipBehavior:
                                                              Clip.antiAlias,
                                                          decoration:
                                                              BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: Image.network(
                                                            valueOrDefault<
                                                                String>(
                                                              rowUsersRecord
                                                                  .photoUrl,
                                                              'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                            ),
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        12.0,
                                                                        0.0,
                                                                        0.0,
                                                                        0.0),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Text(
                                                                      valueOrDefault<
                                                                          String>(
                                                                        rowUsersRecord
                                                                            .username,
                                                                        'user',
                                                                      ).maybeHandleOverflow(
                                                                        maxChars:
                                                                            12,
                                                                        replacement:
                                                                            '…',
                                                                      ),
                                                                      maxLines:
                                                                          1,
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .override(
                                                                            fontFamily:
                                                                                'Poppins',
                                                                            fontSize:
                                                                                14.0,
                                                                            letterSpacing:
                                                                                0.0,
                                                                          ),
                                                                    ),
                                                                    if (!(currentUserDocument?.following.toList() ??
                                                                            [])
                                                                        .contains(
                                                                            rowUsersRecord.reference))
                                                                      AuthUserStreamWidget(
                                                                        builder:
                                                                            (context) =>
                                                                                Text(
                                                                          FFLocalizations.of(context)
                                                                              .getText(
                                                                            'zefbbdnz' /*   •   */,
                                                                          ),
                                                                          maxLines:
                                                                              1,
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .override(
                                                                                fontFamily: 'Poppins',
                                                                                fontSize: 14.0,
                                                                                letterSpacing: 0.0,
                                                                              ),
                                                                        ),
                                                                      ),
                                                                    if (!(currentUserDocument?.following.toList() ??
                                                                            [])
                                                                        .contains(
                                                                            rowUsersRecord.reference))
                                                                      AuthUserStreamWidget(
                                                                        builder:
                                                                            (context) =>
                                                                                StreamBuilder<List<FollowersRecord>>(
                                                                          stream:
                                                                              queryFollowersRecord(
                                                                            parent:
                                                                                rowUsersRecord.reference,
                                                                            singleRecord:
                                                                                true,
                                                                          ),
                                                                          builder:
                                                                              (context, snapshot) {
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
                                                                            List<FollowersRecord>
                                                                                textFollowersRecordList =
                                                                                snapshot.data!;
                                                                            final textFollowersRecord = textFollowersRecordList.isNotEmpty
                                                                                ? textFollowersRecordList.first
                                                                                : null;

                                                                            return InkWell(
                                                                              splashColor: Colors.transparent,
                                                                              focusColor: Colors.transparent,
                                                                              hoverColor: Colors.transparent,
                                                                              highlightColor: Colors.transparent,
                                                                              onTap: () async {
                                                                                await currentUserReference!.update({
                                                                                  ...mapToFirestore(
                                                                                    {
                                                                                      'following': FieldValue.arrayUnion([
                                                                                        rowUsersRecord.reference
                                                                                      ]),
                                                                                    },
                                                                                  ),
                                                                                });

                                                                                await textFollowersRecord!.reference.update({
                                                                                  ...mapToFirestore(
                                                                                    {
                                                                                      'userRefs': FieldValue.arrayUnion([
                                                                                        currentUserReference
                                                                                      ]),
                                                                                    },
                                                                                  ),
                                                                                });
                                                                                triggerPushNotification(
                                                                                  notificationTitle: 'Instagram',
                                                                                  notificationText: '${valueOrDefault(currentUserDocument?.username, '')} started following you.',
                                                                                  notificationImageUrl: currentUserPhoto,
                                                                                  notificationSound: 'default',
                                                                                  userRefs: [
                                                                                    rowUsersRecord.reference
                                                                                  ],
                                                                                  initialPageName: 'ProfileOther',
                                                                                  parameterData: {
                                                                                    'username': valueOrDefault(currentUserDocument?.username, ''),
                                                                                  },
                                                                                );
                                                                              },
                                                                              child: Text(
                                                                                FFLocalizations.of(context).getText(
                                                                                  '9d0w5a7m' /* Follow */,
                                                                                ),
                                                                                maxLines: 1,
                                                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                      fontFamily: 'Poppins',
                                                                                      color: FlutterFlowTheme.of(context).tertiary,
                                                                                      fontSize: 14.0,
                                                                                      letterSpacing: 0.0,
                                                                                      fontWeight: FontWeight.w500,
                                                                                    ),
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                  ],
                                                                ),
                                                                Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          2.0,
                                                                          0.0,
                                                                          0.0),
                                                                  child: Text(
                                                                    rowUsersRecord
                                                                        .displayName,
                                                                    maxLines: 1,
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmall
                                                                        .override(
                                                                          fontFamily:
                                                                              'Poppins',
                                                                          letterSpacing:
                                                                              0.0,
                                                                          fontWeight:
                                                                              FontWeight.normal,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      0.0,
                                                                      0.0,
                                                                      6.0,
                                                                      0.0),
                                                          child: StreamBuilder<
                                                              List<
                                                                  FollowersRecord>>(
                                                            stream:
                                                                queryFollowersRecord(
                                                              parent:
                                                                  rowUsersRecord
                                                                      .reference,
                                                              singleRecord:
                                                                  true,
                                                            ),
                                                            builder: (context,
                                                                snapshot) {
                                                              // Customize what your widget looks like when it's loading.
                                                              if (!snapshot
                                                                  .hasData) {
                                                                return Center(
                                                                  child:
                                                                      SizedBox(
                                                                    width: 12.0,
                                                                    height:
                                                                        12.0,
                                                                    child:
                                                                        CircularProgressIndicator(
                                                                      valueColor:
                                                                          AlwaysStoppedAnimation<
                                                                              Color>(
                                                                        Colors
                                                                            .white,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                              List<FollowersRecord>
                                                                  containerFollowersRecordList =
                                                                  snapshot
                                                                      .data!;
                                                              final containerFollowersRecord =
                                                                  containerFollowersRecordList
                                                                          .isNotEmpty
                                                                      ? containerFollowersRecordList
                                                                          .first
                                                                      : null;

                                                              return InkWell(
                                                                splashColor: Colors
                                                                    .transparent,
                                                                focusColor: Colors
                                                                    .transparent,
                                                                hoverColor: Colors
                                                                    .transparent,
                                                                highlightColor:
                                                                    Colors
                                                                        .transparent,
                                                                onTap:
                                                                    () async {
                                                                  await rowUsersRecord
                                                                      .reference
                                                                      .update({
                                                                    ...mapToFirestore(
                                                                      {
                                                                        'following':
                                                                            FieldValue.arrayRemove([
                                                                          currentUserReference
                                                                        ]),
                                                                      },
                                                                    ),
                                                                  });

                                                                  await tabBarFollowersRecord!
                                                                      .reference
                                                                      .update({
                                                                    ...mapToFirestore(
                                                                      {
                                                                        'userRefs':
                                                                            FieldValue.arrayRemove([
                                                                          rowUsersRecord
                                                                              .reference
                                                                        ]),
                                                                      },
                                                                    ),
                                                                  });
                                                                },
                                                                child:
                                                                    Container(
                                                                  width: 90.0,
                                                                  height: 35.0,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Color(
                                                                        0xFFEFEFEF),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            8.0),
                                                                  ),
                                                                  child: Align(
                                                                    alignment:
                                                                        AlignmentDirectional(
                                                                            0.0,
                                                                            0.0),
                                                                    child:
                                                                        Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          8.0,
                                                                          6.0,
                                                                          8.0,
                                                                          6.0),
                                                                      child:
                                                                          Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          Text(
                                                                            FFLocalizations.of(context).getText(
                                                                              'o5i03spo' /* Remove */,
                                                                            ),
                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                  fontFamily: 'Poppins',
                                                                                  color: FlutterFlowTheme.of(context).secondary,
                                                                                  fontSize: 13.0,
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FontWeight.w600,
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
                                                      ],
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
                                ),
                                KeepAliveWidgetWrapper(
                                  builder: (context) => Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        15.0, 0.0, 15.0, 0.0),
                                    child: AuthUserStreamWidget(
                                      builder: (context) => Builder(
                                        builder: (context) {
                                          final following = (currentUserDocument
                                                      ?.following
                                                      .toList() ??
                                                  [])
                                              .toList();

                                          return ListView.builder(
                                            padding: EdgeInsets.fromLTRB(
                                              0,
                                              0,
                                              0,
                                              150.0,
                                            ),
                                            shrinkWrap: true,
                                            scrollDirection: Axis.vertical,
                                            itemCount: following.length,
                                            itemBuilder:
                                                (context, followingIndex) {
                                              final followingItem =
                                                  following[followingIndex];
                                              return FollowerComponantWidget(
                                                key: Key(
                                                    'Keyu3q_${followingIndex}_of_${following.length}'),
                                                users: followingItem,
                                              );
                                            },
                                          );
                                        },
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
