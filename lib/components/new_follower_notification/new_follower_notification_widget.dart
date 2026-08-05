import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_timer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:flutter/material.dart';
import 'new_follower_notification_model.dart';
export 'new_follower_notification_model.dart';

class NewFollowerNotificationWidget extends StatefulWidget {
  const NewFollowerNotificationWidget({
    super.key,
    this.notification,
  });

  final NotificationsRecord? notification;

  @override
  State<NewFollowerNotificationWidget> createState() =>
      _NewFollowerNotificationWidgetState();
}

class _NewFollowerNotificationWidgetState
    extends State<NewFollowerNotificationWidget> {
  late NewFollowerNotificationModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NewFollowerNotificationModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UsersRecord>(
      stream: UsersRecord.getDocument(widget.notification!.userRef!),
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
            context.pushNamed(
              ProfileOtherWidget.routeName,
              queryParameters: {
                'username': serializeParam(
                  rowUsersRecord.username,
                  ParamType.String,
                ),
              }.withoutNulls,
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 12.0, 0.0),
                child: Container(
                  width: 45.0,
                  height: 45.0,
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
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 6.0, 0.0),
                  child: custom_widgets.Notifications(
                    width: 400.0,
                    height: 38.0,
                    name: valueOrDefault<String>(
                      rowUsersRecord.username,
                      'user',
                    ),
                    notification: 'started following you.',
                    time: dateTimeFormat(
                      "relative",
                      widget.notification!.timeCreated!,
                      locale: FFLocalizations.of(context).languageCode,
                    ),
                  ),
                ),
              ),
              AuthUserStreamWidget(
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
                              (currentUserDocument?.following.toList() ?? [])
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
                                  (currentUserDocument?.following.toList() ??
                                              [])
                                          .contains(rowUsersRecord.reference)
                                      ? 'Following'
                                      : 'Follow',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Poppins',
                                        color: (currentUserDocument?.following
                                                        .toList() ??
                                                    [])
                                                .contains(
                                                    rowUsersRecord.reference)
                                            ? FlutterFlowTheme.of(context)
                                                .secondary
                                            : FlutterFlowTheme.of(context)
                                                .secondary,
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
              FlutterFlowTimer(
                initialTime: _model.timerInitialTimeMs,
                getDisplayTime: (value) =>
                    StopWatchTimer.getDisplayTime(value, milliSecond: false),
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
                  _model.notification = NotificationsRecord.getDocumentFromData(
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
                  triggerPushNotification(
                    notificationTitle: 'Instagram',
                    notificationText:
                        '${valueOrDefault(currentUserDocument?.username, '')} started following you.',
                    notificationImageUrl: currentUserPhoto,
                    notificationSound: 'default',
                    userRefs: [rowUsersRecord.reference],
                    initialPageName: 'ProfileOther',
                    parameterData: {
                      'username':
                          valueOrDefault(currentUserDocument?.username, ''),
                    },
                  );

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
    );
  }
}
