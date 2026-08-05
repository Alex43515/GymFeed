import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_timer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:flutter/material.dart';
import 'tagged_users_component_model.dart';
export 'tagged_users_component_model.dart';

class TaggedUsersComponentWidget extends StatefulWidget {
  const TaggedUsersComponentWidget({
    super.key,
    this.user,
  });

  final DocumentReference? user;

  @override
  State<TaggedUsersComponentWidget> createState() =>
      _TaggedUsersComponentWidgetState();
}

class _TaggedUsersComponentWidgetState
    extends State<TaggedUsersComponentWidget> {
  late TaggedUsersComponentModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TaggedUsersComponentModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
      child: StreamBuilder<UsersRecord>(
        stream: UsersRecord.getDocument(widget.user!),
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

          final rowUsersRecord = snapshot.data!;

          return InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () async {
              if (rowUsersRecord.reference == currentUserReference) {
                context.pushNamed(ProfileWidget.routeName);
              } else {
                context.pushNamed(
                  ProfileOtherWidget.routeName,
                  queryParameters: {
                    'username': serializeParam(
                      rowUsersRecord.username,
                      ParamType.String,
                    ),
                  }.withoutNulls,
                );
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  width: 55.0,
                  height: 55.0,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Image.network(
                    valueOrDefault<String>(
                      rowUsersRecord.photoUrl,
                      'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 0.0, 0.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rowUsersRecord.displayName,
                          maxLines: 1,
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Poppins',
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                  ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 2.0, 0.0, 0.0),
                          child: Text(
                            rowUsersRecord.username,
                            maxLines: 1,
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      fontFamily: 'Poppins',
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.normal,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 6.0, 0.0),
                  child: AuthUserStreamWidget(
                    builder: (context) => StreamBuilder<List<FollowersRecord>>(
                      stream: queryFollowersRecord(
                        parent: rowUsersRecord.reference,
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
                        List<FollowersRecord> containerFollowersRecordList =
                            snapshot.data!;
                        final containerFollowersRecord =
                            containerFollowersRecordList.isNotEmpty
                                ? containerFollowersRecordList.first
                                : null;

                        return InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            if ((currentUserDocument?.following.toList() ?? [])
                                .contains(rowUsersRecord.reference)) {
                              await currentUserReference!.update({
                                ...mapToFirestore(
                                  {
                                    'following': FieldValue.arrayRemove(
                                        [rowUsersRecord.reference]),
                                  },
                                ),
                              });

                              await containerFollowersRecord!.reference.update({
                                ...mapToFirestore(
                                  {
                                    'userRefs': FieldValue.arrayRemove(
                                        [currentUserReference]),
                                  },
                                ),
                              });
                              _model.timerController.onResetTimer();
                            } else {
                              await currentUserReference!.update({
                                ...mapToFirestore(
                                  {
                                    'following': FieldValue.arrayUnion(
                                        [rowUsersRecord.reference]),
                                  },
                                ),
                              });

                              await containerFollowersRecord!.reference.update({
                                ...mapToFirestore(
                                  {
                                    'userRefs': FieldValue.arrayUnion(
                                        [currentUserReference]),
                                  },
                                ),
                              });
                              _model.timerController.onStartTimer();
                            }
                          },
                          child: Container(
                            width: 110.0,
                            height: 35.0,
                            decoration: BoxDecoration(
                              color:
                                  (currentUserDocument?.following.toList() ??
                                              [])
                                          .contains(rowUsersRecord.reference)
                                      ? Color(0xFFEFEFEF)
                                      : FlutterFlowTheme.of(context).secondary,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Align(
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    8.0, 6.0, 8.0, 6.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      () {
                                        if (rowUsersRecord.following.contains(
                                                currentUserReference) &&
                                            !(currentUserDocument?.following
                                                        .toList() ??
                                                    [])
                                                .contains(
                                                    rowUsersRecord.reference)) {
                                          return 'Follow back';
                                        } else if (!rowUsersRecord.following
                                                .contains(
                                                    currentUserReference) &&
                                            !(currentUserDocument?.following
                                                        .toList() ??
                                                    [])
                                                .contains(
                                                    rowUsersRecord.reference)) {
                                          return 'Follow';
                                        } else {
                                          return 'Unfollow';
                                        }
                                      }(),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Poppins',
                                            color: (currentUserDocument
                                                            ?.following
                                                            .toList() ??
                                                        [])
                                                    .contains(rowUsersRecord
                                                        .reference)
                                                ? FlutterFlowTheme.of(context)
                                                    .primaryText
                                                : Colors.white,
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
                ),
                FlutterFlowTimer(
                  initialTime: _model.timerInitialTimeMs,
                  getDisplayTime: (value) => StopWatchTimer.getDisplayTime(
                    value,
                    hours: false,
                    minute: false,
                    milliSecond: false,
                  ),
                  controller: _model.timerController,
                  onChanged: (value, displayTime, shouldUpdate) {
                    _model.timerMilliseconds = value;
                    _model.timerValue = displayTime;
                    if (shouldUpdate) safeSetState(() {});
                  },
                  onEnded: () async {
                    var notificationsRecordReference =
                        NotificationsRecord.createDoc(rowUsersRecord.reference);
                    await notificationsRecordReference
                        .set(createNotificationsRecordData(
                      notificationType: 'Follow',
                      userRef: currentUserReference,
                      timeCreated: getCurrentTimestamp,
                    ));
                    _model.notification =
                        NotificationsRecord.getDocumentFromData(
                            createNotificationsRecordData(
                              notificationType: 'Follow',
                              userRef: currentUserReference,
                              timeCreated: getCurrentTimestamp,
                            ),
                            notificationsRecordReference);

                    await rowUsersRecord.reference.update({
                      ...mapToFirestore(
                        {
                          'unreadNotifications': FieldValue.arrayUnion(
                              [_model.notification?.reference]),
                        },
                      ),
                    });

                    safeSetState(() {});
                  },
                  textAlign: TextAlign.start,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Poppins',
                        color: FlutterFlowTheme.of(context).primary,
                        fontSize: 0.0,
                        letterSpacing: 0.0,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
