import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/follower_componant/follower_componant_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'followers_following_other_model.dart';
export 'followers_following_other_model.dart';

class FollowersFollowingOtherWidget extends StatefulWidget {
  const FollowersFollowingOtherWidget({
    super.key,
    this.userRef,
  });

  final DocumentReference? userRef;

  static String routeName = 'FollowersFollowingOther';
  static String routePath = 'followersFollowingOther';

  @override
  State<FollowersFollowingOtherWidget> createState() =>
      _FollowersFollowingOtherWidgetState();
}

class _FollowersFollowingOtherWidgetState
    extends State<FollowersFollowingOtherWidget> with TickerProviderStateMixin {
  late FollowersFollowingOtherModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FollowersFollowingOtherModel());

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
                          color: FlutterFlowTheme.of(context).secondaryText,
                          size: 20.0,
                        ),
                      ),
                    ),
                    AuthUserStreamWidget(
                      builder: (context) => Text(
                        currentUserDisplayName,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Poppins',
                              fontSize: 15.0,
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
                StreamBuilder<UsersRecord>(
                  stream: UsersRecord.getDocument(widget.userRef!),
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

                    final containerUsersRecord = snapshot.data!;

                    return Container(
                      width: double.infinity,
                      height: MediaQuery.sizeOf(context).height * 1.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                      ),
                      child: StreamBuilder<List<FollowersRecord>>(
                        stream: queryFollowersRecord(
                          parent: widget.userRef,
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
                                  labelColor:
                                      FlutterFlowTheme.of(context).tertiary,
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
                                          tabBarFollowersRecord
                                              ?.userRefs.length,
                                          formatType: FormatType.compact,
                                        )} Followers',
                                        '0 Followers',
                                      ),
                                    ),
                                    Tab(
                                      text: valueOrDefault<String>(
                                        '${valueOrDefault<String>(
                                          formatNumber(
                                            containerUsersRecord
                                                .following.length,
                                            formatType: FormatType.compact,
                                          ),
                                          '0',
                                        )} Following',
                                        '0 Followers',
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
                                            final followers =
                                                tabBarFollowersRecord?.userRefs
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
                                                return FollowerComponantWidget(
                                                  key: Key(
                                                      'Keyhvt_${followersIndex}_of_${followers.length}'),
                                                  users: followersItem,
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
                                        child: Builder(
                                          builder: (context) {
                                            final following =
                                                containerUsersRecord.following
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
                                                      'Key10t_${followingIndex}_of_${following.length}'),
                                                  users: followingItem,
                                                );
                                              },
                                            );
                                          },
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
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
