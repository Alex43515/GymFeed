import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/new_follower_notification/new_follower_notification_widget.dart';
import '/components/todaytomonthnotification_followers/todaytomonthnotification_followers_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'notifications_model.dart';
export 'notifications_model.dart';

class NotificationsWidget extends StatefulWidget {
  const NotificationsWidget({super.key});

  static String routeName = 'Notifications';
  static String routePath = 'notifications';

  @override
  State<NotificationsWidget> createState() => _NotificationsWidgetState();
}

class _NotificationsWidgetState extends State<NotificationsWidget> {
  late NotificationsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NotificationsModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 500));

      await currentUserReference!.update({
        ...mapToFirestore(
          {
            'unreadNotifications': FieldValue.delete(),
          },
        ),
      });
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
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(0.0, 30.0, 0.0, 0.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 30.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                            Icons.arrow_back_ios_rounded,
                            color: FlutterFlowTheme.of(context).tertiary,
                            size: 15.0,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Text(
                            FFLocalizations.of(context).getText(
                              'r2feecfs' /* Notifications */,
                            ),
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Poppins',
                                  fontSize: 15.0,
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: 0.0,
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
                Expanded(
                  child: Container(
                    width: double.infinity,
                    height: 100.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          if ((currentUserDocument?.unreadNotifications
                                          .toList() ??
                                      [])
                                  .length >
                              0)
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 12.0, 0.0, 0.0),
                              child: AuthUserStreamWidget(
                                builder: (context) => Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          15.0, 0.0, 15.0, 18.0),
                                      child: Text(
                                        FFLocalizations.of(context).getText(
                                          'ep50da7k' /* New */,
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .override(
                                              fontFamily: 'Poppins',
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          15.0, 0.0, 15.0, 0.0),
                                      child: Builder(
                                        builder: (context) {
                                          final unreadNotifications = functions
                                                  .reverseList((currentUserDocument
                                                              ?.unreadNotifications
                                                              .toList() ??
                                                          [])
                                                      .toList())
                                                  ?.toList() ??
                                              [];

                                          return Column(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: List.generate(
                                                unreadNotifications.length,
                                                (unreadNotificationsIndex) {
                                              final unreadNotificationsItem =
                                                  unreadNotifications[
                                                      unreadNotificationsIndex];
                                              return Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        0.0, 0.0, 0.0, 12.0),
                                                child: StreamBuilder<
                                                    NotificationsRecord>(
                                                  stream: NotificationsRecord
                                                      .getDocument(
                                                          unreadNotificationsItem),
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

                                                    final columnNotificationsRecord =
                                                        snapshot.data!;

                                                    return Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Follow')
                                                          NewFollowerNotificationWidget(
                                                            key: Key(
                                                                'Keybwt_${unreadNotificationsIndex}_of_${unreadNotifications.length}'),
                                                            notification:
                                                                columnNotificationsRecord,
                                                          ),
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Post_Like')
                                                          StreamBuilder<
                                                              UsersRecord>(
                                                            stream: UsersRecord
                                                                .getDocument(
                                                                    columnNotificationsRecord
                                                                        .userRef!),
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

                                                              final rowUsersRecord =
                                                                  snapshot
                                                                      .data!;

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
                                                                  context
                                                                      .pushNamed(
                                                                    PostDetailsWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'post':
                                                                          serializeParam(
                                                                        columnNotificationsRecord
                                                                            .postRef,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            45.0,
                                                                        height:
                                                                            45.0,
                                                                        clipBehavior:
                                                                            Clip.antiAlias,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: Image
                                                                            .network(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            rowUsersRecord.photoUrl,
                                                                            'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                          ),
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            6.0,
                                                                            0.0),
                                                                        child: custom_widgets
                                                                            .Notifications(
                                                                          width:
                                                                              400.0,
                                                                          height:
                                                                              50.0,
                                                                          name:
                                                                              valueOrDefault<String>(
                                                                            rowUsersRecord.username,
                                                                            'user',
                                                                          ),
                                                                          notification:
                                                                              'liked your post.',
                                                                          time:
                                                                              valueOrDefault<String>(
                                                                            dateTimeFormat(
                                                                              "relative",
                                                                              columnNotificationsRecord.timeCreated,
                                                                              locale: FFLocalizations.of(context).languageCode,
                                                                            ),
                                                                            'now',
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    StreamBuilder<
                                                                        PostsRecord>(
                                                                      stream: PostsRecord.getDocument(
                                                                          columnNotificationsRecord
                                                                              .postRef!),
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

                                                                        final imagePostsRecord =
                                                                            snapshot.data!;

                                                                        return Image
                                                                            .network(
                                                                          imagePostsRecord
                                                                              .postPhoto,
                                                                          width:
                                                                              45.0,
                                                                          height:
                                                                              45.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Comment_Like')
                                                          StreamBuilder<
                                                              UsersRecord>(
                                                            stream: UsersRecord
                                                                .getDocument(
                                                                    columnNotificationsRecord
                                                                        .userRef!),
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

                                                              final rowUsersRecord =
                                                                  snapshot
                                                                      .data!;

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
                                                                  context
                                                                      .pushNamed(
                                                                    CommentsWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'post':
                                                                          serializeParam(
                                                                        columnNotificationsRecord
                                                                            .postRef,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            45.0,
                                                                        height:
                                                                            45.0,
                                                                        clipBehavior:
                                                                            Clip.antiAlias,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: Image
                                                                            .network(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            rowUsersRecord.photoUrl,
                                                                            'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                          ),
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            6.0,
                                                                            0.0),
                                                                        child: StreamBuilder<
                                                                            CommentsRecord>(
                                                                          stream:
                                                                              CommentsRecord.getDocument(columnNotificationsRecord.commentRef!),
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

                                                                            final notificationsCommentsRecord =
                                                                                snapshot.data!;

                                                                            return custom_widgets.Notifications(
                                                                              width: 400.0,
                                                                              height: 50.0,
                                                                              name: valueOrDefault<String>(
                                                                                rowUsersRecord.username,
                                                                                'user',
                                                                              ),
                                                                              notification: 'liked your comment: ${notificationsCommentsRecord.comment}',
                                                                              time: valueOrDefault<String>(
                                                                                dateTimeFormat(
                                                                                  "relative",
                                                                                  columnNotificationsRecord.timeCreated,
                                                                                  locale: FFLocalizations.of(context).languageCode,
                                                                                ),
                                                                                'now',
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    StreamBuilder<
                                                                        PostsRecord>(
                                                                      stream: PostsRecord.getDocument(
                                                                          columnNotificationsRecord
                                                                              .postRef!),
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

                                                                        final imagePostsRecord =
                                                                            snapshot.data!;

                                                                        return Image
                                                                            .network(
                                                                          imagePostsRecord
                                                                              .postPhoto,
                                                                          width:
                                                                              45.0,
                                                                          height:
                                                                              45.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Tagged_Comment')
                                                          StreamBuilder<
                                                              UsersRecord>(
                                                            stream: UsersRecord
                                                                .getDocument(
                                                                    columnNotificationsRecord
                                                                        .userRef!),
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

                                                              final rowUsersRecord =
                                                                  snapshot
                                                                      .data!;

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
                                                                  context
                                                                      .pushNamed(
                                                                    CommentsWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'post':
                                                                          serializeParam(
                                                                        columnNotificationsRecord
                                                                            .postRef,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            45.0,
                                                                        height:
                                                                            45.0,
                                                                        clipBehavior:
                                                                            Clip.antiAlias,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: Image
                                                                            .network(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            rowUsersRecord.photoUrl,
                                                                            'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                          ),
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            6.0,
                                                                            0.0),
                                                                        child: StreamBuilder<
                                                                            CommentsRecord>(
                                                                          stream:
                                                                              CommentsRecord.getDocument(columnNotificationsRecord.commentRef!),
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

                                                                            final notificationsCommentsRecord =
                                                                                snapshot.data!;

                                                                            return custom_widgets.Notifications(
                                                                              width: 400.0,
                                                                              height: 50.0,
                                                                              name: valueOrDefault<String>(
                                                                                rowUsersRecord.username,
                                                                                'user',
                                                                              ),
                                                                              notification: 'commented on a post you are tagged in: ${notificationsCommentsRecord.comment}',
                                                                              time: valueOrDefault<String>(
                                                                                dateTimeFormat(
                                                                                  "relative",
                                                                                  columnNotificationsRecord.timeCreated,
                                                                                  locale: FFLocalizations.of(context).languageCode,
                                                                                ),
                                                                                'now',
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    StreamBuilder<
                                                                        PostsRecord>(
                                                                      stream: PostsRecord.getDocument(
                                                                          columnNotificationsRecord
                                                                              .postRef!),
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

                                                                        final imagePostsRecord =
                                                                            snapshot.data!;

                                                                        return Image
                                                                            .network(
                                                                          imagePostsRecord
                                                                              .postPhoto,
                                                                          width:
                                                                              45.0,
                                                                          height:
                                                                              45.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Post_Comment')
                                                          StreamBuilder<
                                                              UsersRecord>(
                                                            stream: UsersRecord
                                                                .getDocument(
                                                                    columnNotificationsRecord
                                                                        .userRef!),
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

                                                              final rowUsersRecord =
                                                                  snapshot
                                                                      .data!;

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
                                                                  context
                                                                      .pushNamed(
                                                                    CommentsWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'post':
                                                                          serializeParam(
                                                                        columnNotificationsRecord
                                                                            .postRef,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            45.0,
                                                                        height:
                                                                            45.0,
                                                                        clipBehavior:
                                                                            Clip.antiAlias,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: Image
                                                                            .network(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            rowUsersRecord.photoUrl,
                                                                            'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                          ),
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            6.0,
                                                                            0.0),
                                                                        child: StreamBuilder<
                                                                            CommentsRecord>(
                                                                          stream:
                                                                              CommentsRecord.getDocument(columnNotificationsRecord.commentRef!),
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

                                                                            final notificationsCommentsRecord =
                                                                                snapshot.data!;

                                                                            return custom_widgets.Notifications(
                                                                              width: 400.0,
                                                                              height: 50.0,
                                                                              name: valueOrDefault<String>(
                                                                                rowUsersRecord.username,
                                                                                'user',
                                                                              ),
                                                                              notification: 'commented on your post: ${notificationsCommentsRecord.comment}',
                                                                              time: valueOrDefault<String>(
                                                                                dateTimeFormat(
                                                                                  "relative",
                                                                                  columnNotificationsRecord.timeCreated,
                                                                                  locale: FFLocalizations.of(context).languageCode,
                                                                                ),
                                                                                'now',
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    StreamBuilder<
                                                                        PostsRecord>(
                                                                      stream: PostsRecord.getDocument(
                                                                          columnNotificationsRecord
                                                                              .postRef!),
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

                                                                        final imagePostsRecord =
                                                                            snapshot.data!;

                                                                        return Image
                                                                            .network(
                                                                          imagePostsRecord
                                                                              .postPhoto,
                                                                          width:
                                                                              45.0,
                                                                          height:
                                                                              45.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              );
                                            }),
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 12.0, 0.0, 0.0),
                                      child: Container(
                                        width: double.infinity,
                                        height: 0.5,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFDADADA),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 12.0, 0.0, 0.0),
                            child: StreamBuilder<List<NotificationsRecord>>(
                              stream: queryNotificationsRecord(
                                parent: currentUserReference,
                                queryBuilder: (notificationsRecord) =>
                                    notificationsRecord.where(
                                  'time_created',
                                  isGreaterThan: functions
                                      .returnThisMorning(getCurrentTimestamp),
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
                                List<NotificationsRecord>
                                    columnNotificationsRecordList =
                                    snapshot.data!;
                                // Return an empty Container when the item does not exist.
                                if (snapshot.data!.isEmpty) {
                                  return Container();
                                }
                                final columnNotificationsRecord =
                                    columnNotificationsRecordList.isNotEmpty
                                        ? columnNotificationsRecordList.first
                                        : null;

                                return Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          15.0, 0.0, 15.0, 18.0),
                                      child: Text(
                                        FFLocalizations.of(context).getText(
                                          'l3sek4ds' /* Today */,
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .override(
                                              fontFamily: 'Poppins',
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          15.0, 0.0, 15.0, 0.0),
                                      child: StreamBuilder<
                                          List<NotificationsRecord>>(
                                        stream: queryNotificationsRecord(
                                          parent: currentUserReference,
                                          queryBuilder: (notificationsRecord) =>
                                              notificationsRecord
                                                  .where(
                                                    'time_created',
                                                    isGreaterThan: functions
                                                        .returnThisMorning(
                                                            getCurrentTimestamp),
                                                  )
                                                  .orderBy('time_created',
                                                      descending: true),
                                          limit: 10,
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
                                          List<NotificationsRecord>
                                              columnNotificationsRecordList =
                                              snapshot.data!;

                                          return Column(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: List.generate(
                                                columnNotificationsRecordList
                                                    .length, (columnIndex) {
                                              final columnNotificationsRecord =
                                                  columnNotificationsRecordList[
                                                      columnIndex];
                                              return Visibility(
                                                visible: !(currentUserDocument
                                                            ?.unreadNotifications
                                                            .toList() ??
                                                        [])
                                                    .contains(
                                                        columnNotificationsRecord
                                                            .reference),
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 0.0, 0.0, 12.0),
                                                  child: AuthUserStreamWidget(
                                                    builder: (context) =>
                                                        Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Follow')
                                                          TodaytomonthnotificationFollowersWidget(
                                                            key: Key(
                                                                'Keyr8x_${columnIndex}_of_${columnNotificationsRecordList.length}'),
                                                            notification:
                                                                columnNotificationsRecord,
                                                          ),
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Post_Like')
                                                          StreamBuilder<
                                                              UsersRecord>(
                                                            stream: UsersRecord
                                                                .getDocument(
                                                                    columnNotificationsRecord
                                                                        .userRef!),
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

                                                              final rowUsersRecord =
                                                                  snapshot
                                                                      .data!;

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
                                                                  context
                                                                      .pushNamed(
                                                                    PostDetailsWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'post':
                                                                          serializeParam(
                                                                        columnNotificationsRecord
                                                                            .postRef,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            45.0,
                                                                        height:
                                                                            45.0,
                                                                        clipBehavior:
                                                                            Clip.antiAlias,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: Image
                                                                            .network(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            rowUsersRecord.photoUrl,
                                                                            'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                          ),
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            6.0,
                                                                            0.0),
                                                                        child: custom_widgets
                                                                            .Notifications(
                                                                          width:
                                                                              400.0,
                                                                          height:
                                                                              50.0,
                                                                          name:
                                                                              valueOrDefault<String>(
                                                                            rowUsersRecord.username,
                                                                            'user',
                                                                          ),
                                                                          notification:
                                                                              'liked your post.',
                                                                          time:
                                                                              valueOrDefault<String>(
                                                                            dateTimeFormat(
                                                                              "relative",
                                                                              columnNotificationsRecord.timeCreated,
                                                                              locale: FFLocalizations.of(context).languageCode,
                                                                            ),
                                                                            'now',
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    StreamBuilder<
                                                                        PostsRecord>(
                                                                      stream: PostsRecord.getDocument(
                                                                          columnNotificationsRecord
                                                                              .postRef!),
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

                                                                        final imagePostsRecord =
                                                                            snapshot.data!;

                                                                        return Image
                                                                            .network(
                                                                          imagePostsRecord
                                                                              .postPhoto,
                                                                          width:
                                                                              45.0,
                                                                          height:
                                                                              45.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Comment_Like')
                                                          StreamBuilder<
                                                              UsersRecord>(
                                                            stream: UsersRecord
                                                                .getDocument(
                                                                    columnNotificationsRecord
                                                                        .userRef!),
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

                                                              final rowUsersRecord =
                                                                  snapshot
                                                                      .data!;

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
                                                                  context
                                                                      .pushNamed(
                                                                    CommentsWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'post':
                                                                          serializeParam(
                                                                        columnNotificationsRecord
                                                                            .postRef,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            45.0,
                                                                        height:
                                                                            45.0,
                                                                        clipBehavior:
                                                                            Clip.antiAlias,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: Image
                                                                            .network(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            rowUsersRecord.photoUrl,
                                                                            'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                          ),
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            6.0,
                                                                            0.0),
                                                                        child: StreamBuilder<
                                                                            CommentsRecord>(
                                                                          stream:
                                                                              CommentsRecord.getDocument(columnNotificationsRecord.commentRef!),
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

                                                                            final notificationsCommentsRecord =
                                                                                snapshot.data!;

                                                                            return custom_widgets.Notifications(
                                                                              width: 400.0,
                                                                              height: 50.0,
                                                                              name: valueOrDefault<String>(
                                                                                rowUsersRecord.username,
                                                                                'user',
                                                                              ),
                                                                              notification: 'liked your comment: ${notificationsCommentsRecord.comment}',
                                                                              time: valueOrDefault<String>(
                                                                                dateTimeFormat(
                                                                                  "relative",
                                                                                  columnNotificationsRecord.timeCreated,
                                                                                  locale: FFLocalizations.of(context).languageCode,
                                                                                ),
                                                                                'now',
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    StreamBuilder<
                                                                        PostsRecord>(
                                                                      stream: PostsRecord.getDocument(
                                                                          columnNotificationsRecord
                                                                              .postRef!),
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

                                                                        final imagePostsRecord =
                                                                            snapshot.data!;

                                                                        return Image
                                                                            .network(
                                                                          imagePostsRecord
                                                                              .postPhoto,
                                                                          width:
                                                                              45.0,
                                                                          height:
                                                                              45.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Tagged_Comment')
                                                          StreamBuilder<
                                                              UsersRecord>(
                                                            stream: UsersRecord
                                                                .getDocument(
                                                                    columnNotificationsRecord
                                                                        .userRef!),
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

                                                              final rowUsersRecord =
                                                                  snapshot
                                                                      .data!;

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
                                                                  context
                                                                      .pushNamed(
                                                                    CommentsWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'post':
                                                                          serializeParam(
                                                                        columnNotificationsRecord
                                                                            .postRef,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            45.0,
                                                                        height:
                                                                            45.0,
                                                                        clipBehavior:
                                                                            Clip.antiAlias,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: Image
                                                                            .network(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            rowUsersRecord.photoUrl,
                                                                            'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                          ),
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            6.0,
                                                                            0.0),
                                                                        child: StreamBuilder<
                                                                            CommentsRecord>(
                                                                          stream:
                                                                              CommentsRecord.getDocument(columnNotificationsRecord.commentRef!),
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

                                                                            final notificationsCommentsRecord =
                                                                                snapshot.data!;

                                                                            return custom_widgets.Notifications(
                                                                              width: 400.0,
                                                                              height: 50.0,
                                                                              name: valueOrDefault<String>(
                                                                                rowUsersRecord.username,
                                                                                'user',
                                                                              ),
                                                                              notification: 'commented on a post you are tagged in: ${notificationsCommentsRecord.comment}',
                                                                              time: valueOrDefault<String>(
                                                                                dateTimeFormat(
                                                                                  "relative",
                                                                                  columnNotificationsRecord.timeCreated,
                                                                                  locale: FFLocalizations.of(context).languageCode,
                                                                                ),
                                                                                'now',
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    StreamBuilder<
                                                                        PostsRecord>(
                                                                      stream: PostsRecord.getDocument(
                                                                          columnNotificationsRecord
                                                                              .postRef!),
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

                                                                        final imagePostsRecord =
                                                                            snapshot.data!;

                                                                        return Image
                                                                            .network(
                                                                          imagePostsRecord
                                                                              .postPhoto,
                                                                          width:
                                                                              45.0,
                                                                          height:
                                                                              45.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Post_Comment')
                                                          StreamBuilder<
                                                              UsersRecord>(
                                                            stream: UsersRecord
                                                                .getDocument(
                                                                    columnNotificationsRecord
                                                                        .userRef!),
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

                                                              final rowUsersRecord =
                                                                  snapshot
                                                                      .data!;

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
                                                                  context
                                                                      .pushNamed(
                                                                    CommentsWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'post':
                                                                          serializeParam(
                                                                        columnNotificationsRecord
                                                                            .postRef,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            45.0,
                                                                        height:
                                                                            45.0,
                                                                        clipBehavior:
                                                                            Clip.antiAlias,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: Image
                                                                            .network(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            rowUsersRecord.photoUrl,
                                                                            'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                          ),
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            6.0,
                                                                            0.0),
                                                                        child: StreamBuilder<
                                                                            CommentsRecord>(
                                                                          stream:
                                                                              CommentsRecord.getDocument(columnNotificationsRecord.commentRef!),
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

                                                                            final notificationsCommentsRecord =
                                                                                snapshot.data!;

                                                                            return custom_widgets.Notifications(
                                                                              width: 400.0,
                                                                              height: 50.0,
                                                                              name: valueOrDefault<String>(
                                                                                rowUsersRecord.username,
                                                                                'user',
                                                                              ),
                                                                              notification: 'commented on your post: ${notificationsCommentsRecord.comment}',
                                                                              time: valueOrDefault<String>(
                                                                                dateTimeFormat(
                                                                                  "relative",
                                                                                  columnNotificationsRecord.timeCreated,
                                                                                  locale: FFLocalizations.of(context).languageCode,
                                                                                ),
                                                                                'now',
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    StreamBuilder<
                                                                        PostsRecord>(
                                                                      stream: PostsRecord.getDocument(
                                                                          columnNotificationsRecord
                                                                              .postRef!),
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

                                                                        final imagePostsRecord =
                                                                            snapshot.data!;

                                                                        return Image
                                                                            .network(
                                                                          imagePostsRecord
                                                                              .postPhoto,
                                                                          width:
                                                                              45.0,
                                                                          height:
                                                                              45.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 12.0, 0.0, 0.0),
                                      child: Container(
                                        width: double.infinity,
                                        height: 0.5,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFDADADA),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 12.0, 0.0, 0.0),
                            child: StreamBuilder<List<NotificationsRecord>>(
                              stream: queryNotificationsRecord(
                                parent: currentUserReference,
                                queryBuilder: (notificationsRecord) =>
                                    notificationsRecord
                                        .where(
                                          'time_created',
                                          isGreaterThan:
                                              functions.returnThisWeek(
                                                  getCurrentTimestamp),
                                        )
                                        .where(
                                          'time_created',
                                          isLessThan:
                                              functions.returnThisMorning(
                                                  getCurrentTimestamp),
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
                                List<NotificationsRecord>
                                    columnNotificationsRecordList =
                                    snapshot.data!;
                                // Return an empty Container when the item does not exist.
                                if (snapshot.data!.isEmpty) {
                                  return Container();
                                }
                                final columnNotificationsRecord =
                                    columnNotificationsRecordList.isNotEmpty
                                        ? columnNotificationsRecordList.first
                                        : null;

                                return Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          15.0, 0.0, 15.0, 18.0),
                                      child: Text(
                                        FFLocalizations.of(context).getText(
                                          'lu0b9e7b' /* This Week */,
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .override(
                                              fontFamily: 'Poppins',
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          15.0, 0.0, 15.0, 0.0),
                                      child: StreamBuilder<
                                          List<NotificationsRecord>>(
                                        stream: queryNotificationsRecord(
                                          parent: currentUserReference,
                                          queryBuilder: (notificationsRecord) =>
                                              notificationsRecord
                                                  .where(
                                                    'time_created',
                                                    isGreaterThan: functions
                                                        .returnThisWeek(
                                                            getCurrentTimestamp),
                                                  )
                                                  .where(
                                                    'time_created',
                                                    isLessThan: functions
                                                        .returnThisMorning(
                                                            getCurrentTimestamp),
                                                  )
                                                  .orderBy('time_created',
                                                      descending: true),
                                          limit: 10,
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
                                          List<NotificationsRecord>
                                              columnNotificationsRecordList =
                                              snapshot.data!;

                                          return Column(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: List.generate(
                                                columnNotificationsRecordList
                                                    .length, (columnIndex) {
                                              final columnNotificationsRecord =
                                                  columnNotificationsRecordList[
                                                      columnIndex];
                                              return Visibility(
                                                visible: !(currentUserDocument
                                                            ?.unreadNotifications
                                                            .toList() ??
                                                        [])
                                                    .contains(
                                                        columnNotificationsRecord
                                                            .reference),
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 0.0, 0.0, 12.0),
                                                  child: AuthUserStreamWidget(
                                                    builder: (context) =>
                                                        Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Follow')
                                                          TodaytomonthnotificationFollowersWidget(
                                                            key: Key(
                                                                'Key8g8_${columnIndex}_of_${columnNotificationsRecordList.length}'),
                                                            notification:
                                                                columnNotificationsRecord,
                                                          ),
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Post_Like')
                                                          StreamBuilder<
                                                              UsersRecord>(
                                                            stream: UsersRecord
                                                                .getDocument(
                                                                    columnNotificationsRecord
                                                                        .userRef!),
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

                                                              final rowUsersRecord =
                                                                  snapshot
                                                                      .data!;

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
                                                                  context
                                                                      .pushNamed(
                                                                    PostDetailsWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'post':
                                                                          serializeParam(
                                                                        columnNotificationsRecord
                                                                            .postRef,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            45.0,
                                                                        height:
                                                                            45.0,
                                                                        clipBehavior:
                                                                            Clip.antiAlias,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: Image
                                                                            .network(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            rowUsersRecord.photoUrl,
                                                                            'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                          ),
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            6.0,
                                                                            0.0),
                                                                        child: custom_widgets
                                                                            .Notifications(
                                                                          width:
                                                                              400.0,
                                                                          height:
                                                                              50.0,
                                                                          name:
                                                                              valueOrDefault<String>(
                                                                            rowUsersRecord.username,
                                                                            'user',
                                                                          ),
                                                                          notification:
                                                                              'liked your post.',
                                                                          time:
                                                                              valueOrDefault<String>(
                                                                            dateTimeFormat(
                                                                              "relative",
                                                                              columnNotificationsRecord.timeCreated,
                                                                              locale: FFLocalizations.of(context).languageCode,
                                                                            ),
                                                                            'now',
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    StreamBuilder<
                                                                        PostsRecord>(
                                                                      stream: PostsRecord.getDocument(
                                                                          columnNotificationsRecord
                                                                              .postRef!),
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

                                                                        final imagePostsRecord =
                                                                            snapshot.data!;

                                                                        return Image
                                                                            .network(
                                                                          imagePostsRecord
                                                                              .postPhoto,
                                                                          width:
                                                                              45.0,
                                                                          height:
                                                                              45.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Comment_Like')
                                                          StreamBuilder<
                                                              UsersRecord>(
                                                            stream: UsersRecord
                                                                .getDocument(
                                                                    columnNotificationsRecord
                                                                        .userRef!),
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

                                                              final rowUsersRecord =
                                                                  snapshot
                                                                      .data!;

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
                                                                  context
                                                                      .pushNamed(
                                                                    CommentsWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'post':
                                                                          serializeParam(
                                                                        columnNotificationsRecord
                                                                            .postRef,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            45.0,
                                                                        height:
                                                                            45.0,
                                                                        clipBehavior:
                                                                            Clip.antiAlias,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: Image
                                                                            .network(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            rowUsersRecord.photoUrl,
                                                                            'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                          ),
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            6.0,
                                                                            0.0),
                                                                        child: StreamBuilder<
                                                                            CommentsRecord>(
                                                                          stream:
                                                                              CommentsRecord.getDocument(columnNotificationsRecord.commentRef!),
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

                                                                            final notificationsCommentsRecord =
                                                                                snapshot.data!;

                                                                            return custom_widgets.Notifications(
                                                                              width: 400.0,
                                                                              height: 50.0,
                                                                              name: valueOrDefault<String>(
                                                                                rowUsersRecord.username,
                                                                                'user',
                                                                              ),
                                                                              notification: 'liked your comment: ${notificationsCommentsRecord.comment}',
                                                                              time: valueOrDefault<String>(
                                                                                dateTimeFormat(
                                                                                  "relative",
                                                                                  columnNotificationsRecord.timeCreated,
                                                                                  locale: FFLocalizations.of(context).languageCode,
                                                                                ),
                                                                                'now',
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    StreamBuilder<
                                                                        PostsRecord>(
                                                                      stream: PostsRecord.getDocument(
                                                                          columnNotificationsRecord
                                                                              .postRef!),
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

                                                                        final imagePostsRecord =
                                                                            snapshot.data!;

                                                                        return Image
                                                                            .network(
                                                                          imagePostsRecord
                                                                              .postPhoto,
                                                                          width:
                                                                              45.0,
                                                                          height:
                                                                              45.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Tagged_Comment')
                                                          StreamBuilder<
                                                              UsersRecord>(
                                                            stream: UsersRecord
                                                                .getDocument(
                                                                    columnNotificationsRecord
                                                                        .userRef!),
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

                                                              final rowUsersRecord =
                                                                  snapshot
                                                                      .data!;

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
                                                                  context
                                                                      .pushNamed(
                                                                    CommentsWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'post':
                                                                          serializeParam(
                                                                        columnNotificationsRecord
                                                                            .postRef,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            45.0,
                                                                        height:
                                                                            45.0,
                                                                        clipBehavior:
                                                                            Clip.antiAlias,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: Image
                                                                            .network(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            rowUsersRecord.photoUrl,
                                                                            'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                          ),
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            6.0,
                                                                            0.0),
                                                                        child: StreamBuilder<
                                                                            CommentsRecord>(
                                                                          stream:
                                                                              CommentsRecord.getDocument(columnNotificationsRecord.commentRef!),
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

                                                                            final notificationsCommentsRecord =
                                                                                snapshot.data!;

                                                                            return custom_widgets.Notifications(
                                                                              width: 400.0,
                                                                              height: 50.0,
                                                                              name: valueOrDefault<String>(
                                                                                rowUsersRecord.username,
                                                                                'user',
                                                                              ),
                                                                              notification: 'commented on a post you are tagged in: ${notificationsCommentsRecord.comment}',
                                                                              time: valueOrDefault<String>(
                                                                                dateTimeFormat(
                                                                                  "relative",
                                                                                  columnNotificationsRecord.timeCreated,
                                                                                  locale: FFLocalizations.of(context).languageCode,
                                                                                ),
                                                                                'now',
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    StreamBuilder<
                                                                        PostsRecord>(
                                                                      stream: PostsRecord.getDocument(
                                                                          columnNotificationsRecord
                                                                              .postRef!),
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

                                                                        final imagePostsRecord =
                                                                            snapshot.data!;

                                                                        return Image
                                                                            .network(
                                                                          imagePostsRecord
                                                                              .postPhoto,
                                                                          width:
                                                                              45.0,
                                                                          height:
                                                                              45.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Post_Comment')
                                                          StreamBuilder<
                                                              UsersRecord>(
                                                            stream: UsersRecord
                                                                .getDocument(
                                                                    columnNotificationsRecord
                                                                        .userRef!),
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

                                                              final rowUsersRecord =
                                                                  snapshot
                                                                      .data!;

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
                                                                  context
                                                                      .pushNamed(
                                                                    CommentsWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'post':
                                                                          serializeParam(
                                                                        columnNotificationsRecord
                                                                            .postRef,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            45.0,
                                                                        height:
                                                                            45.0,
                                                                        clipBehavior:
                                                                            Clip.antiAlias,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: Image
                                                                            .network(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            rowUsersRecord.photoUrl,
                                                                            'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                          ),
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            6.0,
                                                                            0.0),
                                                                        child: StreamBuilder<
                                                                            CommentsRecord>(
                                                                          stream:
                                                                              CommentsRecord.getDocument(columnNotificationsRecord.commentRef!),
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

                                                                            final notificationsCommentsRecord =
                                                                                snapshot.data!;

                                                                            return custom_widgets.Notifications(
                                                                              width: 400.0,
                                                                              height: 50.0,
                                                                              name: valueOrDefault<String>(
                                                                                rowUsersRecord.username,
                                                                                'user',
                                                                              ),
                                                                              notification: 'commented on your post: ${notificationsCommentsRecord.comment}',
                                                                              time: valueOrDefault<String>(
                                                                                dateTimeFormat(
                                                                                  "relative",
                                                                                  columnNotificationsRecord.timeCreated,
                                                                                  locale: FFLocalizations.of(context).languageCode,
                                                                                ),
                                                                                'now',
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    StreamBuilder<
                                                                        PostsRecord>(
                                                                      stream: PostsRecord.getDocument(
                                                                          columnNotificationsRecord
                                                                              .postRef!),
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

                                                                        final imagePostsRecord =
                                                                            snapshot.data!;

                                                                        return Image
                                                                            .network(
                                                                          imagePostsRecord
                                                                              .postPhoto,
                                                                          width:
                                                                              45.0,
                                                                          height:
                                                                              45.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 12.0, 0.0, 0.0),
                                      child: Container(
                                        width: double.infinity,
                                        height: 0.5,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFDADADA),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 12.0, 0.0, 0.0),
                            child: StreamBuilder<List<NotificationsRecord>>(
                              stream: queryNotificationsRecord(
                                parent: currentUserReference,
                                queryBuilder: (notificationsRecord) =>
                                    notificationsRecord
                                        .where(
                                          'time_created',
                                          isGreaterThan:
                                              functions.returnThisMonth(
                                                  getCurrentTimestamp),
                                        )
                                        .where(
                                          'time_created',
                                          isLessThan: functions.returnThisWeek(
                                              getCurrentTimestamp),
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
                                List<NotificationsRecord>
                                    columnNotificationsRecordList =
                                    snapshot.data!;
                                // Return an empty Container when the item does not exist.
                                if (snapshot.data!.isEmpty) {
                                  return Container();
                                }
                                final columnNotificationsRecord =
                                    columnNotificationsRecordList.isNotEmpty
                                        ? columnNotificationsRecordList.first
                                        : null;

                                return Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          15.0, 0.0, 15.0, 18.0),
                                      child: Text(
                                        FFLocalizations.of(context).getText(
                                          '0dt1z197' /* This Month */,
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .override(
                                              fontFamily: 'Poppins',
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          15.0, 0.0, 15.0, 0.0),
                                      child: StreamBuilder<
                                          List<NotificationsRecord>>(
                                        stream: queryNotificationsRecord(
                                          parent: currentUserReference,
                                          queryBuilder: (notificationsRecord) =>
                                              notificationsRecord
                                                  .where(
                                                    'time_created',
                                                    isGreaterThan: functions
                                                        .returnThisMonth(
                                                            getCurrentTimestamp),
                                                  )
                                                  .where(
                                                    'time_created',
                                                    isLessThan: functions
                                                        .returnThisWeek(
                                                            getCurrentTimestamp),
                                                  )
                                                  .orderBy('time_created',
                                                      descending: true),
                                          limit: 10,
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
                                          List<NotificationsRecord>
                                              columnNotificationsRecordList =
                                              snapshot.data!;

                                          return Column(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: List.generate(
                                                columnNotificationsRecordList
                                                    .length, (columnIndex) {
                                              final columnNotificationsRecord =
                                                  columnNotificationsRecordList[
                                                      columnIndex];
                                              return Visibility(
                                                visible: !(currentUserDocument
                                                            ?.unreadNotifications
                                                            .toList() ??
                                                        [])
                                                    .contains(
                                                        columnNotificationsRecord
                                                            .reference),
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 0.0, 0.0, 12.0),
                                                  child: AuthUserStreamWidget(
                                                    builder: (context) =>
                                                        Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Follow')
                                                          TodaytomonthnotificationFollowersWidget(
                                                            key: Key(
                                                                'Keyudq_${columnIndex}_of_${columnNotificationsRecordList.length}'),
                                                            notification:
                                                                columnNotificationsRecord,
                                                          ),
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Post_Like')
                                                          StreamBuilder<
                                                              UsersRecord>(
                                                            stream: UsersRecord
                                                                .getDocument(
                                                                    columnNotificationsRecord
                                                                        .userRef!),
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

                                                              final rowUsersRecord =
                                                                  snapshot
                                                                      .data!;

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
                                                                  context
                                                                      .pushNamed(
                                                                    PostDetailsWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'post':
                                                                          serializeParam(
                                                                        columnNotificationsRecord
                                                                            .postRef,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            45.0,
                                                                        height:
                                                                            45.0,
                                                                        clipBehavior:
                                                                            Clip.antiAlias,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: Image
                                                                            .network(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            rowUsersRecord.photoUrl,
                                                                            'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                          ),
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            6.0,
                                                                            0.0),
                                                                        child: custom_widgets
                                                                            .Notifications(
                                                                          width:
                                                                              400.0,
                                                                          height:
                                                                              50.0,
                                                                          name:
                                                                              valueOrDefault<String>(
                                                                            rowUsersRecord.username,
                                                                            'user',
                                                                          ),
                                                                          notification:
                                                                              'liked your post.',
                                                                          time:
                                                                              valueOrDefault<String>(
                                                                            dateTimeFormat(
                                                                              "relative",
                                                                              columnNotificationsRecord.timeCreated,
                                                                              locale: FFLocalizations.of(context).languageCode,
                                                                            ),
                                                                            'now',
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    StreamBuilder<
                                                                        PostsRecord>(
                                                                      stream: PostsRecord.getDocument(
                                                                          columnNotificationsRecord
                                                                              .postRef!),
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

                                                                        final imagePostsRecord =
                                                                            snapshot.data!;

                                                                        return Image
                                                                            .network(
                                                                          imagePostsRecord
                                                                              .postPhoto,
                                                                          width:
                                                                              45.0,
                                                                          height:
                                                                              45.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Comment_Like')
                                                          StreamBuilder<
                                                              UsersRecord>(
                                                            stream: UsersRecord
                                                                .getDocument(
                                                                    columnNotificationsRecord
                                                                        .userRef!),
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

                                                              final rowUsersRecord =
                                                                  snapshot
                                                                      .data!;

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
                                                                  context
                                                                      .pushNamed(
                                                                    CommentsWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'post':
                                                                          serializeParam(
                                                                        columnNotificationsRecord
                                                                            .postRef,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            45.0,
                                                                        height:
                                                                            45.0,
                                                                        clipBehavior:
                                                                            Clip.antiAlias,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: Image
                                                                            .network(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            rowUsersRecord.photoUrl,
                                                                            'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                          ),
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            6.0,
                                                                            0.0),
                                                                        child: StreamBuilder<
                                                                            CommentsRecord>(
                                                                          stream:
                                                                              CommentsRecord.getDocument(columnNotificationsRecord.commentRef!),
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

                                                                            final notificationsCommentsRecord =
                                                                                snapshot.data!;

                                                                            return custom_widgets.Notifications(
                                                                              width: 400.0,
                                                                              height: 50.0,
                                                                              name: valueOrDefault<String>(
                                                                                rowUsersRecord.username,
                                                                                'user',
                                                                              ),
                                                                              notification: 'liked your comment: ${notificationsCommentsRecord.comment}',
                                                                              time: valueOrDefault<String>(
                                                                                dateTimeFormat(
                                                                                  "relative",
                                                                                  columnNotificationsRecord.timeCreated,
                                                                                  locale: FFLocalizations.of(context).languageCode,
                                                                                ),
                                                                                'now',
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    StreamBuilder<
                                                                        PostsRecord>(
                                                                      stream: PostsRecord.getDocument(
                                                                          columnNotificationsRecord
                                                                              .postRef!),
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

                                                                        final imagePostsRecord =
                                                                            snapshot.data!;

                                                                        return Image
                                                                            .network(
                                                                          imagePostsRecord
                                                                              .postPhoto,
                                                                          width:
                                                                              45.0,
                                                                          height:
                                                                              45.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Tagged_Comment')
                                                          StreamBuilder<
                                                              UsersRecord>(
                                                            stream: UsersRecord
                                                                .getDocument(
                                                                    columnNotificationsRecord
                                                                        .userRef!),
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

                                                              final rowUsersRecord =
                                                                  snapshot
                                                                      .data!;

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
                                                                  context
                                                                      .pushNamed(
                                                                    CommentsWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'post':
                                                                          serializeParam(
                                                                        columnNotificationsRecord
                                                                            .postRef,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            45.0,
                                                                        height:
                                                                            45.0,
                                                                        clipBehavior:
                                                                            Clip.antiAlias,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: Image
                                                                            .network(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            rowUsersRecord.photoUrl,
                                                                            'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                          ),
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            6.0,
                                                                            0.0),
                                                                        child: StreamBuilder<
                                                                            CommentsRecord>(
                                                                          stream:
                                                                              CommentsRecord.getDocument(columnNotificationsRecord.commentRef!),
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

                                                                            final notificationsCommentsRecord =
                                                                                snapshot.data!;

                                                                            return custom_widgets.Notifications(
                                                                              width: 400.0,
                                                                              height: 50.0,
                                                                              name: valueOrDefault<String>(
                                                                                rowUsersRecord.username,
                                                                                'user',
                                                                              ),
                                                                              notification: 'commented on a post you are tagged in: ${notificationsCommentsRecord.comment}',
                                                                              time: valueOrDefault<String>(
                                                                                dateTimeFormat(
                                                                                  "relative",
                                                                                  columnNotificationsRecord.timeCreated,
                                                                                  locale: FFLocalizations.of(context).languageCode,
                                                                                ),
                                                                                'now',
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    StreamBuilder<
                                                                        PostsRecord>(
                                                                      stream: PostsRecord.getDocument(
                                                                          columnNotificationsRecord
                                                                              .postRef!),
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

                                                                        final imagePostsRecord =
                                                                            snapshot.data!;

                                                                        return Image
                                                                            .network(
                                                                          imagePostsRecord
                                                                              .postPhoto,
                                                                          width:
                                                                              45.0,
                                                                          height:
                                                                              45.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Post_Comment')
                                                          StreamBuilder<
                                                              UsersRecord>(
                                                            stream: UsersRecord
                                                                .getDocument(
                                                                    columnNotificationsRecord
                                                                        .userRef!),
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

                                                              final rowUsersRecord =
                                                                  snapshot
                                                                      .data!;

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
                                                                  context
                                                                      .pushNamed(
                                                                    CommentsWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'post':
                                                                          serializeParam(
                                                                        columnNotificationsRecord
                                                                            .postRef,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            45.0,
                                                                        height:
                                                                            45.0,
                                                                        clipBehavior:
                                                                            Clip.antiAlias,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: Image
                                                                            .network(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            rowUsersRecord.photoUrl,
                                                                            'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                          ),
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            6.0,
                                                                            0.0),
                                                                        child: StreamBuilder<
                                                                            CommentsRecord>(
                                                                          stream:
                                                                              CommentsRecord.getDocument(columnNotificationsRecord.commentRef!),
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

                                                                            final notificationsCommentsRecord =
                                                                                snapshot.data!;

                                                                            return custom_widgets.Notifications(
                                                                              width: 400.0,
                                                                              height: 50.0,
                                                                              name: valueOrDefault<String>(
                                                                                rowUsersRecord.username,
                                                                                'user',
                                                                              ),
                                                                              notification: 'commented on your post: ${notificationsCommentsRecord.comment}',
                                                                              time: valueOrDefault<String>(
                                                                                dateTimeFormat(
                                                                                  "relative",
                                                                                  columnNotificationsRecord.timeCreated,
                                                                                  locale: FFLocalizations.of(context).languageCode,
                                                                                ),
                                                                                'now',
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    StreamBuilder<
                                                                        PostsRecord>(
                                                                      stream: PostsRecord.getDocument(
                                                                          columnNotificationsRecord
                                                                              .postRef!),
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

                                                                        final imagePostsRecord =
                                                                            snapshot.data!;

                                                                        return Image
                                                                            .network(
                                                                          imagePostsRecord
                                                                              .postPhoto,
                                                                          width:
                                                                              45.0,
                                                                          height:
                                                                              45.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 12.0, 0.0, 0.0),
                                      child: Container(
                                        width: double.infinity,
                                        height: 0.5,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFDADADA),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 12.0, 0.0, 0.0),
                            child: StreamBuilder<List<NotificationsRecord>>(
                              stream: queryNotificationsRecord(
                                parent: currentUserReference,
                                queryBuilder: (notificationsRecord) =>
                                    notificationsRecord.where(
                                  'time_created',
                                  isLessThan: functions
                                      .returnThisMonth(getCurrentTimestamp),
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
                                List<NotificationsRecord>
                                    columnNotificationsRecordList =
                                    snapshot.data!;
                                // Return an empty Container when the item does not exist.
                                if (snapshot.data!.isEmpty) {
                                  return Container();
                                }
                                final columnNotificationsRecord =
                                    columnNotificationsRecordList.isNotEmpty
                                        ? columnNotificationsRecordList.first
                                        : null;

                                return Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          15.0, 0.0, 15.0, 18.0),
                                      child: Text(
                                        FFLocalizations.of(context).getText(
                                          'l6qk1j9r' /* Earlier */,
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .override(
                                              fontFamily: 'Poppins',
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          15.0, 0.0, 15.0, 0.0),
                                      child: StreamBuilder<
                                          List<NotificationsRecord>>(
                                        stream: queryNotificationsRecord(
                                          parent: currentUserReference,
                                          queryBuilder: (notificationsRecord) =>
                                              notificationsRecord
                                                  .where(
                                                    'time_created',
                                                    isLessThan: functions
                                                        .returnThisMonth(
                                                            getCurrentTimestamp),
                                                  )
                                                  .orderBy('time_created',
                                                      descending: true),
                                          limit: 10,
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
                                          List<NotificationsRecord>
                                              columnNotificationsRecordList =
                                              snapshot.data!;

                                          return Column(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: List.generate(
                                                columnNotificationsRecordList
                                                    .length, (columnIndex) {
                                              final columnNotificationsRecord =
                                                  columnNotificationsRecordList[
                                                      columnIndex];
                                              return Visibility(
                                                visible: !(currentUserDocument
                                                            ?.unreadNotifications
                                                            .toList() ??
                                                        [])
                                                    .contains(
                                                        columnNotificationsRecord
                                                            .reference),
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 0.0, 0.0, 12.0),
                                                  child: AuthUserStreamWidget(
                                                    builder: (context) =>
                                                        Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Follow')
                                                          TodaytomonthnotificationFollowersWidget(
                                                            key: Key(
                                                                'Keyki4_${columnIndex}_of_${columnNotificationsRecordList.length}'),
                                                            notification:
                                                                columnNotificationsRecord,
                                                          ),
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Post_Like')
                                                          StreamBuilder<
                                                              UsersRecord>(
                                                            stream: UsersRecord
                                                                .getDocument(
                                                                    columnNotificationsRecord
                                                                        .userRef!),
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

                                                              final rowUsersRecord =
                                                                  snapshot
                                                                      .data!;

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
                                                                  context
                                                                      .pushNamed(
                                                                    PostDetailsWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'post':
                                                                          serializeParam(
                                                                        columnNotificationsRecord
                                                                            .postRef,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            45.0,
                                                                        height:
                                                                            45.0,
                                                                        clipBehavior:
                                                                            Clip.antiAlias,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: Image
                                                                            .network(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            rowUsersRecord.photoUrl,
                                                                            'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                          ),
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            6.0,
                                                                            0.0),
                                                                        child: custom_widgets
                                                                            .Notifications(
                                                                          width:
                                                                              400.0,
                                                                          height:
                                                                              50.0,
                                                                          name:
                                                                              valueOrDefault<String>(
                                                                            rowUsersRecord.username,
                                                                            'user',
                                                                          ),
                                                                          notification:
                                                                              'liked your post.',
                                                                          time:
                                                                              valueOrDefault<String>(
                                                                            dateTimeFormat(
                                                                              "relative",
                                                                              columnNotificationsRecord.timeCreated,
                                                                              locale: FFLocalizations.of(context).languageCode,
                                                                            ),
                                                                            'now',
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    StreamBuilder<
                                                                        PostsRecord>(
                                                                      stream: PostsRecord.getDocument(
                                                                          columnNotificationsRecord
                                                                              .postRef!),
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

                                                                        final imagePostsRecord =
                                                                            snapshot.data!;

                                                                        return Image
                                                                            .network(
                                                                          imagePostsRecord
                                                                              .postPhoto,
                                                                          width:
                                                                              45.0,
                                                                          height:
                                                                              45.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Comment_Like')
                                                          StreamBuilder<
                                                              UsersRecord>(
                                                            stream: UsersRecord
                                                                .getDocument(
                                                                    columnNotificationsRecord
                                                                        .userRef!),
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

                                                              final rowUsersRecord =
                                                                  snapshot
                                                                      .data!;

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
                                                                  context
                                                                      .pushNamed(
                                                                    CommentsWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'post':
                                                                          serializeParam(
                                                                        columnNotificationsRecord
                                                                            .postRef,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            45.0,
                                                                        height:
                                                                            45.0,
                                                                        clipBehavior:
                                                                            Clip.antiAlias,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: Image
                                                                            .network(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            rowUsersRecord.photoUrl,
                                                                            'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                          ),
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            6.0,
                                                                            0.0),
                                                                        child: StreamBuilder<
                                                                            CommentsRecord>(
                                                                          stream:
                                                                              CommentsRecord.getDocument(columnNotificationsRecord.commentRef!),
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

                                                                            final notificationsCommentsRecord =
                                                                                snapshot.data!;

                                                                            return custom_widgets.Notifications(
                                                                              width: 400.0,
                                                                              height: 50.0,
                                                                              name: valueOrDefault<String>(
                                                                                rowUsersRecord.username,
                                                                                'user',
                                                                              ),
                                                                              notification: 'liked your comment: ${notificationsCommentsRecord.comment}',
                                                                              time: valueOrDefault<String>(
                                                                                dateTimeFormat(
                                                                                  "relative",
                                                                                  columnNotificationsRecord.timeCreated,
                                                                                  locale: FFLocalizations.of(context).languageCode,
                                                                                ),
                                                                                'now',
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    StreamBuilder<
                                                                        PostsRecord>(
                                                                      stream: PostsRecord.getDocument(
                                                                          columnNotificationsRecord
                                                                              .postRef!),
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

                                                                        final imagePostsRecord =
                                                                            snapshot.data!;

                                                                        return Image
                                                                            .network(
                                                                          imagePostsRecord
                                                                              .postPhoto,
                                                                          width:
                                                                              45.0,
                                                                          height:
                                                                              45.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Tagged_Comment')
                                                          StreamBuilder<
                                                              UsersRecord>(
                                                            stream: UsersRecord
                                                                .getDocument(
                                                                    columnNotificationsRecord
                                                                        .userRef!),
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

                                                              final rowUsersRecord =
                                                                  snapshot
                                                                      .data!;

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
                                                                  context
                                                                      .pushNamed(
                                                                    CommentsWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'post':
                                                                          serializeParam(
                                                                        columnNotificationsRecord
                                                                            .postRef,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            45.0,
                                                                        height:
                                                                            45.0,
                                                                        clipBehavior:
                                                                            Clip.antiAlias,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: Image
                                                                            .network(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            rowUsersRecord.photoUrl,
                                                                            'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                          ),
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            6.0,
                                                                            0.0),
                                                                        child: StreamBuilder<
                                                                            CommentsRecord>(
                                                                          stream:
                                                                              CommentsRecord.getDocument(columnNotificationsRecord.commentRef!),
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

                                                                            final notificationsCommentsRecord =
                                                                                snapshot.data!;

                                                                            return custom_widgets.Notifications(
                                                                              width: 400.0,
                                                                              height: 50.0,
                                                                              name: valueOrDefault<String>(
                                                                                rowUsersRecord.username,
                                                                                'user',
                                                                              ),
                                                                              notification: 'commented on a post you are tagged in: ${notificationsCommentsRecord.comment}',
                                                                              time: valueOrDefault<String>(
                                                                                dateTimeFormat(
                                                                                  "relative",
                                                                                  columnNotificationsRecord.timeCreated,
                                                                                  locale: FFLocalizations.of(context).languageCode,
                                                                                ),
                                                                                'now',
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    StreamBuilder<
                                                                        PostsRecord>(
                                                                      stream: PostsRecord.getDocument(
                                                                          columnNotificationsRecord
                                                                              .postRef!),
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

                                                                        final imagePostsRecord =
                                                                            snapshot.data!;

                                                                        return Image
                                                                            .network(
                                                                          imagePostsRecord
                                                                              .postPhoto,
                                                                          width:
                                                                              45.0,
                                                                          height:
                                                                              45.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        if (columnNotificationsRecord
                                                                .notificationType ==
                                                            'Post_Comment')
                                                          StreamBuilder<
                                                              UsersRecord>(
                                                            stream: UsersRecord
                                                                .getDocument(
                                                                    columnNotificationsRecord
                                                                        .userRef!),
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

                                                              final rowUsersRecord =
                                                                  snapshot
                                                                      .data!;

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
                                                                  context
                                                                      .pushNamed(
                                                                    CommentsWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'post':
                                                                          serializeParam(
                                                                        columnNotificationsRecord
                                                                            .postRef,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            45.0,
                                                                        height:
                                                                            45.0,
                                                                        clipBehavior:
                                                                            Clip.antiAlias,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: Image
                                                                            .network(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            rowUsersRecord.photoUrl,
                                                                            'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                          ),
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            6.0,
                                                                            0.0),
                                                                        child: StreamBuilder<
                                                                            CommentsRecord>(
                                                                          stream:
                                                                              CommentsRecord.getDocument(columnNotificationsRecord.commentRef!),
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

                                                                            final notificationsCommentsRecord =
                                                                                snapshot.data!;

                                                                            return custom_widgets.Notifications(
                                                                              width: 400.0,
                                                                              height: 50.0,
                                                                              name: valueOrDefault<String>(
                                                                                rowUsersRecord.username,
                                                                                'user',
                                                                              ),
                                                                              notification: 'commented on your post: ${notificationsCommentsRecord.comment}',
                                                                              time: valueOrDefault<String>(
                                                                                dateTimeFormat(
                                                                                  "relative",
                                                                                  columnNotificationsRecord.timeCreated,
                                                                                  locale: FFLocalizations.of(context).languageCode,
                                                                                ),
                                                                                'now',
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    StreamBuilder<
                                                                        PostsRecord>(
                                                                      stream: PostsRecord.getDocument(
                                                                          columnNotificationsRecord
                                                                              .postRef!),
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

                                                                        final imagePostsRecord =
                                                                            snapshot.data!;

                                                                        return Image
                                                                            .network(
                                                                          imagePostsRecord
                                                                              .postPhoto,
                                                                          width:
                                                                              45.0,
                                                                          height:
                                                                              45.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 12.0, 0.0, 0.0),
                                      child: Container(
                                        width: double.infinity,
                                        height: 0.5,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFDADADA),
                                        ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
