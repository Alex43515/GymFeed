import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/components/personal_post_options/personal_post_options_widget.dart';
import '/components/send_post/send_post_widget.dart';
import '/components/tagged_users/tagged_users_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_toggle_icon.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_video_player.dart';
import '/pages/posts/post_options/post_options_widget.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'post_model.dart';
export 'post_model.dart';

class PostWidget extends StatefulWidget {
  const PostWidget({
    super.key,
    this.post,
    this.detailsPage,
  });

  final PostsRecord? post;
  final bool? detailsPage;

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> with TickerProviderStateMixin {
  late PostModel _model;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PostModel());

    animationsMap.addAll({
      'iconOnActionTriggerAnimation': AnimationInfo(
        trigger: AnimationTrigger.onActionTrigger,
        applyInitialState: true,
        effectsBuilder: () => [
          VisibilityEffect(duration: 1.ms),
          ScaleEffect(
            curve: Curves.elasticOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.2, 0.2),
            end: Offset(1.0, 1.0),
          ),
          ScaleEffect(
            curve: Curves.easeOut,
            delay: 1000.0.ms,
            duration: 150.0.ms,
            begin: Offset(1.0, 1.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'toggleIconOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ScaleEffect(
            curve: Curves.elasticOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.2, 0.2),
            end: Offset(1.0, 1.0),
          ),
        ],
      ),
      'iconOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ScaleEffect(
            curve: Curves.elasticOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.2, 0.2),
            end: Offset(1.0, 1.0),
          ),
        ],
      ),
    });
    setupAnimations(
      animationsMap.values.where((anim) =>
          anim.trigger == AnimationTrigger.onActionTrigger ||
          !anim.applyInitialState),
      this,
    );

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
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 25.0),
      child: FutureBuilder<UsersRecord>(
        future: UsersRecord.getDocumentOnce(widget.post!.postUser!),
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

          final columnUsersRecord = snapshot.data!;

          return Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(15.0, 0.0, 15.0, 10.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        if (columnUsersRecord.reference ==
                            currentUserReference) {
                          context.pushNamed(ProfileWidget.routeName);
                        } else {
                          if (columnUsersRecord.userBlocked
                              .contains(currentUserReference)) {
                            context.pushNamed(BlockedPageWidget.routeName);
                          } else {
                            context.pushNamed(
                              ProfileOtherWidget.routeName,
                              queryParameters: {
                                'username': serializeParam(
                                  columnUsersRecord.username,
                                  ParamType.String,
                                ),
                              }.withoutNulls,
                            );
                          }
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              if (columnUsersRecord.reference ==
                                  currentUserReference) {
                                context.pushNamed(ProfileWidget.routeName);
                              } else {
                                if (columnUsersRecord.userBlocked
                                    .contains(currentUserReference)) {
                                  context
                                      .pushNamed(BlockedPageWidget.routeName);
                                } else {
                                  context.pushNamed(
                                    ProfileOtherWidget.routeName,
                                    queryParameters: {
                                      'username': serializeParam(
                                        columnUsersRecord.username,
                                        ParamType.String,
                                      ),
                                    }.withoutNulls,
                                  );
                                }
                              }
                            },
                            child: Container(
                              width: 35.0,
                              height: 35.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: Image.network(
                                    functions.bunnyCDNImagePath(
                                        valueOrDefault<String>(
                                      columnUsersRecord.photoUrl,
                                      'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                    )),
                                  ).image,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Color(0xFFDADADA),
                                  width: 0.5,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                12.0, 0.0, 0.0, 0.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    if (columnUsersRecord.reference ==
                                        currentUserReference) {
                                      context
                                          .pushNamed(ProfileWidget.routeName);
                                    } else {
                                      if (columnUsersRecord.userBlocked
                                          .contains(currentUserReference)) {
                                        context.pushNamed(
                                            BlockedPageWidget.routeName);
                                      } else {
                                        context.pushNamed(
                                          ProfileOtherWidget.routeName,
                                          queryParameters: {
                                            'username': serializeParam(
                                              columnUsersRecord.username,
                                              ParamType.String,
                                            ),
                                          }.withoutNulls,
                                        );
                                      }
                                    }
                                  },
                                  child: Text(
                                    valueOrDefault<String>(
                                      columnUsersRecord.username,
                                      'user',
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Poppins',
                                          fontSize:
                                              MediaQuery.sizeOf(context).width <
                                                      768.0
                                                  ? 15.0
                                                  : 20.0,
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                ),
                                if (widget.post?.location != null &&
                                    widget.post?.location != '')
                                  Text(
                                    valueOrDefault<String>(
                                      widget.post?.location,
                                      'no address',
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Poppins',
                                          fontSize:
                                              MediaQuery.sizeOf(context).width <
                                                      768.0
                                                  ? 12.0
                                                  : 17.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        if (widget.post?.postUser == currentUserReference) {
                          await showModalBottomSheet(
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            barrierColor: Color(0x00000000),
                            context: context,
                            builder: (context) {
                              return Padding(
                                padding: MediaQuery.viewInsetsOf(context),
                                child: PersonalPostOptionsWidget(
                                  post: widget.post,
                                ),
                              );
                            },
                          ).then((value) => safeSetState(() {}));
                        } else {
                          await showModalBottomSheet(
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            barrierColor: Color(0x00000000),
                            context: context,
                            builder: (context) {
                              return Padding(
                                padding: MediaQuery.viewInsetsOf(context),
                                child: PostOptionsWidget(
                                  post: widget.post,
                                ),
                              );
                            },
                          ).then((value) => safeSetState(() {}));
                        }
                      },
                      child: Icon(
                        FFIcons.kmore,
                        color: FlutterFlowTheme.of(context).tertiary,
                        size: 24.0,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                height: 0.5,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondary,
                ),
              ),
              Stack(
                children: [
                  Align(
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 0.95,
                      height: 350.0,
                      child: Stack(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        children: [
                          Stack(
                            children: [
                              InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  if (widget.detailsPage != false) {
                                    context.pushNamed(
                                      PostDetailsWidget.routeName,
                                      queryParameters: {
                                        'post': serializeParam(
                                          widget.post?.reference,
                                          ParamType.DocumentReference,
                                        ),
                                      }.withoutNulls,
                                    );
                                  }
                                },
                                onDoubleTap: () async {
                                  if (widget.post!.allowLikes) {
                                    if (widget.post!.likes
                                        .contains(currentUserReference)) {
                                      await widget.post!.reference.update({
                                        ...mapToFirestore(
                                          {
                                            'likes': FieldValue.arrayRemove(
                                                [columnUsersRecord.reference]),
                                          },
                                        ),
                                      });
                                    } else {
                                      if (animationsMap[
                                              'iconOnActionTriggerAnimation'] !=
                                          null) {
                                        animationsMap[
                                                'iconOnActionTriggerAnimation']!
                                            .controller
                                            .forward(from: 0.0);
                                      }

                                      await widget.post!.reference.update({
                                        ...mapToFirestore(
                                          {
                                            'likes': FieldValue.arrayUnion(
                                                [currentUserReference]),
                                          },
                                        ),
                                      });
                                      HapticFeedback.lightImpact();
                                      if (widget.post?.postUser !=
                                          currentUserReference) {
                                        var notificationsRecordReference =
                                            NotificationsRecord.createDoc(
                                                columnUsersRecord.reference);
                                        await notificationsRecordReference
                                            .set(createNotificationsRecordData(
                                          notificationType: 'Post_Like',
                                          userRef: currentUserReference,
                                          postRef: widget.post?.reference,
                                          timeCreated: getCurrentTimestamp,
                                        ));
                                        _model.notification = NotificationsRecord
                                            .getDocumentFromData(
                                                createNotificationsRecordData(
                                                  notificationType: 'Post_Like',
                                                  userRef: currentUserReference,
                                                  postRef:
                                                      widget.post?.reference,
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
                                              '${valueOrDefault(currentUserDocument?.username, '')} liked your photo.',
                                          notificationImageUrl:
                                              widget.post?.postPhoto,
                                          notificationSound: 'default',
                                          userRefs: [
                                            columnUsersRecord.reference
                                          ],
                                          initialPageName: 'PostDetails',
                                          parameterData: {
                                            'post': widget.post?.reference,
                                          },
                                        );
                                      }
                                    }
                                  }

                                  safeSetState(() {});
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: 350.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: Visibility(
                                    visible: widget.post?.postPhoto != null &&
                                        widget.post?.postPhoto != '',
                                    child: Align(
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                        child: Image.network(
                                          functions.bunnyCDNImagePath(
                                              widget.post!.postPhoto),
                                          width: double.infinity,
                                          height: 350.0,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (widget.post?.postVideo != null &&
                                  widget.post?.postVideo != '')
                                Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: FlutterFlowVideoPlayer(
                                    path: functions.bunnyCDNVideoPath(
                                        widget.post!.postVideo),
                                    videoType: VideoType.network,
                                    width:
                                        MediaQuery.sizeOf(context).width * 1.0,
                                    height: 350.0,
                                    autoPlay: false,
                                    looping: true,
                                    showControls: true,
                                    allowFullScreen: true,
                                    allowPlaybackSpeedMenu: false,
                                  ),
                                ),
                            ],
                          ),
                          Align(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Icon(
                              FFIcons.k02012,
                              color: FlutterFlowTheme.of(context).primary,
                              size: 120.0,
                            ).animateOnActionTrigger(
                              animationsMap['iconOnActionTriggerAnimation']!,
                            ),
                          ),
                          if (widget.post?.callToActionEnabled ?? true)
                            Align(
                              alignment: AlignmentDirectional(0.0, 1.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  await launchURL(
                                      widget.post!.callToActionLink);
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: 50.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context).primary,
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(20.0),
                                      bottomRight: Radius.circular(20.0),
                                      topLeft: Radius.circular(0.0),
                                      topRight: Radius.circular(0.0),
                                    ),
                                  ),
                                  child: Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          15.0, 0.0, 15.0, 0.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            valueOrDefault<String>(
                                              widget.post?.callToActionText,
                                              'Learn More',
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  color: Colors.white,
                                                  fontSize: 15.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          Icon(
                                            FFIcons.karrowRight,
                                            color: Colors.white,
                                            size: 24.0,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (widget.post!.taggedUsers.length > 0)
                            Align(
                              alignment: AlignmentDirectional(1.0, -1.0),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 12.0, 12.0, 0.0),
                                child: InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    await showModalBottomSheet(
                                      isScrollControlled: true,
                                      backgroundColor: Color(0x00787676),
                                      barrierColor: Color(0x00000000),
                                      enableDrag: false,
                                      context: context,
                                      builder: (context) {
                                        return Padding(
                                          padding:
                                              MediaQuery.viewInsetsOf(context),
                                          child: TaggedUsersWidget(
                                            post: widget.post,
                                          ),
                                        );
                                      },
                                    ).then((value) => safeSetState(() {}));
                                  },
                                  child: Container(
                                    width: 30.0,
                                    height: 30.0,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .tertiary,
                                      ),
                                    ),
                                    child: Align(
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: Icon(
                                        Icons.person_rounded,
                                        color: Colors.white,
                                        size: 16.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.detailsPage == false)
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(15.0, 12.0, 15.0, 12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          if (widget.post?.allowLikes ?? true)
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 5.0, 0.0),
                              child: StreamBuilder<PostsRecord>(
                                stream: PostsRecord.getDocument(
                                    widget.post!.reference),
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

                                  final toggleIconPostsRecord = snapshot.data!;

                                  return ToggleIcon(
                                    onPressed: () async {
                                      final likesElement = currentUserReference;
                                      final likesUpdate = toggleIconPostsRecord
                                              .likes
                                              .contains(likesElement)
                                          ? FieldValue.arrayRemove(
                                              [likesElement])
                                          : FieldValue.arrayUnion(
                                              [likesElement]);
                                      await toggleIconPostsRecord.reference
                                          .update({
                                        ...mapToFirestore(
                                          {
                                            'likes': likesUpdate,
                                          },
                                        ),
                                      });

                                      var notificationsRecordReference =
                                          NotificationsRecord.createDoc(
                                              columnUsersRecord.reference);
                                      await notificationsRecordReference
                                          .set(createNotificationsRecordData(
                                        notificationType: 'Post_Like',
                                        userRef: currentUserReference,
                                        postRef: widget.post?.reference,
                                        timeCreated: getCurrentTimestamp,
                                      ));
                                      _model.notification1Copy =
                                          NotificationsRecord
                                              .getDocumentFromData(
                                                  createNotificationsRecordData(
                                                    notificationType:
                                                        'Post_Like',
                                                    userRef:
                                                        currentUserReference,
                                                    postRef:
                                                        widget.post?.reference,
                                                    timeCreated:
                                                        getCurrentTimestamp,
                                                  ),
                                                  notificationsRecordReference);

                                      await columnUsersRecord.reference.update({
                                        ...mapToFirestore(
                                          {
                                            'unreadNotifications':
                                                FieldValue.arrayUnion([
                                              _model
                                                  .notification1Copy?.reference
                                            ]),
                                          },
                                        ),
                                      });
                                      triggerPushNotification(
                                        notificationTitle: 'GymFeed',
                                        notificationText:
                                            '${valueOrDefault(currentUserDocument?.username, '')} liked your photo.',
                                        notificationImageUrl:
                                            widget.post?.postPhoto,
                                        notificationSound: 'default',
                                        userRefs: [columnUsersRecord.reference],
                                        initialPageName: 'PostDetails',
                                        parameterData: {
                                          'post': widget.post?.reference,
                                        },
                                      );

                                      safeSetState(() {});
                                    },
                                    value: toggleIconPostsRecord.likes
                                        .contains(currentUserReference),
                                    onIcon: Icon(
                                      FFIcons.k02012,
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      size: MediaQuery.sizeOf(context).width <
                                              768.0
                                          ? 26.0
                                          : 38.0,
                                    ),
                                    offIcon: Icon(
                                      FFIcons.kmuscles,
                                      color:
                                          FlutterFlowTheme.of(context).tertiary,
                                      size: MediaQuery.sizeOf(context).width <
                                              768.0
                                          ? 26.0
                                          : 38.0,
                                    ),
                                  ).animateOnPageLoad(animationsMap[
                                      'toggleIconOnPageLoadAnimation']!);
                                },
                              ),
                            ),
                          if (widget.post?.allowComments ?? true)
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 12.0, 0.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  context.pushNamed(
                                    CommentsWidget.routeName,
                                    queryParameters: {
                                      'post': serializeParam(
                                        widget.post?.reference,
                                        ParamType.DocumentReference,
                                      ),
                                    }.withoutNulls,
                                  );
                                },
                                child: Icon(
                                  FFIcons.kcomment,
                                  color: FlutterFlowTheme.of(context).tertiary,
                                  size: MediaQuery.sizeOf(context).width < 768.0
                                      ? 26.0
                                      : 38.0,
                                ),
                              ),
                            ),
                          InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              await showModalBottomSheet(
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                barrierColor: Color(0x00000000),
                                context: context,
                                builder: (context) {
                                  return Padding(
                                    padding: MediaQuery.viewInsetsOf(context),
                                    child: SendPostWidget(
                                      post: widget.post?.reference,
                                      post2: widget.post,
                                    ),
                                  );
                                },
                              ).then((value) => safeSetState(() {}));
                            },
                            child: Icon(
                              FFIcons.kshare,
                              color: FlutterFlowTheme.of(context).tertiary,
                              size: MediaQuery.sizeOf(context).width < 768.0
                                  ? 26.0
                                  : 38.0,
                            ),
                          ),
                          Builder(
                            builder: (context) => Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  12.0, 0.0, 0.0, 0.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  _model.currentPageLink =
                                      await generateCurrentPageLink(
                                    context,
                                    title: widget.post?.postCaption,
                                    imageUrl: widget.post?.postPhoto,
                                    description:
                                        'Check out this GymFeed post !',
                                    isShortLink: false,
                                  );

                                  _model.linkGenerator = _model.currentPageLink;
                                  safeSetState(() {});
                                  await Share.share(
                                    _model.linkGenerator!,
                                    sharePositionOrigin:
                                        getWidgetBoundingBox(context),
                                  );
                                },
                                child: Icon(
                                  Icons.share,
                                  color: FlutterFlowTheme.of(context).tertiary,
                                  size: MediaQuery.sizeOf(context).width < 768.0
                                      ? 26.0
                                      : 38.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      StreamBuilder<List<BookmarksRecord>>(
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            );
                          }
                          List<BookmarksRecord> stackBookmarksRecordList =
                              snapshot.data!;
                          final stackBookmarksRecord =
                              stackBookmarksRecordList.isNotEmpty
                                  ? stackBookmarksRecordList.first
                                  : null;

                          return Stack(
                            children: [
                              if (!stackBookmarksRecord!.postRefs
                                  .contains(widget.post?.reference))
                                InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    await stackBookmarksRecord.reference
                                        .update({
                                      ...mapToFirestore(
                                        {
                                          'postRefs': FieldValue.arrayUnion(
                                              [widget.post?.reference]),
                                        },
                                      ),
                                    });
                                    HapticFeedback.selectionClick();
                                  },
                                  child: Icon(
                                    FFIcons.kbookmark,
                                    color:
                                        FlutterFlowTheme.of(context).tertiary,
                                    size:
                                        MediaQuery.sizeOf(context).width < 768.0
                                            ? 24.0
                                            : 38.0,
                                  ),
                                ),
                              if (stackBookmarksRecord.postRefs
                                      .contains(widget.post?.reference) ??
                                  true)
                                InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    await stackBookmarksRecord.reference
                                        .update({
                                      ...mapToFirestore(
                                        {
                                          'postRefs': FieldValue.arrayRemove(
                                              [widget.post?.reference]),
                                        },
                                      ),
                                    });
                                  },
                                  child: Icon(
                                    FFIcons.kbookmark1,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size:
                                        MediaQuery.sizeOf(context).width < 768.0
                                            ? 24.0
                                            : 38.0,
                                  ),
                                ).animateOnPageLoad(
                                    animationsMap['iconOnPageLoadAnimation']!),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              if ((widget.post?.foodPost == false) &&
                  (widget.detailsPage == false))
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(15.0, 0.0, 15.0, 0.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.post?.allowLikes ?? true)
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 0.0, 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              if (widget.post!.likes.length > 1)
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 5.0),
                                    child: FutureBuilder<UsersRecord>(
                                      future: UsersRecord.getDocumentOnce(
                                          functions.returnUserFromLikes(
                                              widget.post!.likes.toList())),
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

                                        final likedByUsersRecord =
                                            snapshot.data!;

                                        return custom_widgets.LikedBy(
                                          width: double.infinity,
                                          height: 17.0,
                                          name: valueOrDefault<String>(
                                            likedByUsersRecord.username,
                                            'user',
                                          ),
                                          number: valueOrDefault<String>(
                                            formatNumber(
                                              functions.totalLikes(
                                                  valueOrDefault<int>(
                                                widget.post?.likes.length,
                                                1,
                                              )),
                                              formatType: FormatType.compact,
                                            ),
                                            '0',
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              if (widget.post!.likes.length < 2)
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, 5.0),
                                  child: Text(
                                    '${valueOrDefault<String>(
                                      formatNumber(
                                        widget.post?.likes.length,
                                        formatType: FormatType.compact,
                                      ),
                                      '0',
                                    )}${widget.post?.likes.length == 1 ? ' like' : ' likes'}',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Poppins',
                                          fontSize:
                                              MediaQuery.sizeOf(context).width <
                                                      768.0
                                                  ? 15.0
                                                  : 20.0,
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 5.0, 0.0, 8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: RichText(
                                textScaler: MediaQuery.of(context).textScaler,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: columnUsersRecord.username,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Poppins',
                                            fontSize: MediaQuery.sizeOf(context)
                                                        .width <
                                                    768.0
                                                ? 15.0
                                                : 20.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      mouseCursor: SystemMouseCursors.click,
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () async {
                                          if (columnUsersRecord.reference ==
                                              currentUserReference) {
                                            context.pushNamed(
                                                ProfileWidget.routeName);
                                          } else {
                                            context.pushNamed(
                                              ProfileOtherWidget.routeName,
                                              queryParameters: {
                                                'username': serializeParam(
                                                  columnUsersRecord.username,
                                                  ParamType.String,
                                                ),
                                              }.withoutNulls,
                                            );
                                          }
                                        },
                                    ),
                                    TextSpan(
                                      text: FFLocalizations.of(context).getText(
                                        'jg5jldjk' /*   */,
                                      ),
                                      style: TextStyle(),
                                    ),
                                    TextSpan(
                                      text: widget.post!.postCaption,
                                      style: TextStyle(),
                                    )
                                  ],
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Poppins',
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.normal,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if ((widget.post?.numComments != 0) &&
                          widget.post!.allowComments)
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            if (widget.post!.numComments > 1)
                              StreamBuilder<List<CommentsRecord>>(
                                stream: queryCommentsRecord(
                                  parent: widget.post?.reference,
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
                                  List<CommentsRecord> textCommentsRecordList =
                                      snapshot.data!;

                                  return InkWell(
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () async {
                                      context.pushNamed(
                                        CommentsWidget.routeName,
                                        queryParameters: {
                                          'post': serializeParam(
                                            widget.post?.reference,
                                            ParamType.DocumentReference,
                                          ),
                                        }.withoutNulls,
                                      );
                                    },
                                    child: Text(
                                      'View all ${formatNumber(
                                        textCommentsRecordList.length,
                                        formatType: FormatType.compact,
                                      )} comments',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Poppins',
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            fontSize: MediaQuery.sizeOf(context)
                                                        .width <
                                                    768.0
                                                ? 15.0
                                                : 20.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.normal,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            if (widget.post?.numComments == 1)
                              StreamBuilder<List<CommentsRecord>>(
                                stream: queryCommentsRecord(
                                  parent: widget.post?.reference,
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
                                  List<CommentsRecord> textCommentsRecordList =
                                      snapshot.data!;

                                  return InkWell(
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () async {
                                      context.pushNamed(
                                        CommentsWidget.routeName,
                                        queryParameters: {
                                          'post': serializeParam(
                                            widget.post?.reference,
                                            ParamType.DocumentReference,
                                          ),
                                        }.withoutNulls,
                                      );
                                    },
                                    child: Text(
                                      FFLocalizations.of(context).getText(
                                        'c3h7q1qk' /* View 1 comment */,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Poppins',
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            fontSize: MediaQuery.sizeOf(context)
                                                        .width <
                                                    768.0
                                                ? 15.0
                                                : 20.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.normal,
                                          ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      if (widget.post?.allowComments ?? true)
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 8.0, 0.0, 0.0),
                          child: StreamBuilder<List<CommentsRecord>>(
                            stream: queryCommentsRecord(
                              parent: widget.post?.reference,
                              queryBuilder: (commentsRecord) => commentsRecord
                                  .orderBy('time_posted', descending: true),
                              limit: 2,
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
                              List<CommentsRecord> columnCommentsRecordList =
                                  snapshot.data!;

                              return InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  context.pushNamed(
                                    CommentsWidget.routeName,
                                    queryParameters: {
                                      'post': serializeParam(
                                        widget.post?.reference,
                                        ParamType.DocumentReference,
                                      ),
                                    }.withoutNulls,
                                  );
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: List.generate(
                                      columnCommentsRecordList.length,
                                      (columnIndex) {
                                    final columnCommentsRecord =
                                        columnCommentsRecordList[columnIndex];
                                    return Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 0.0, 8.0),
                                      child: StreamBuilder<UsersRecord>(
                                        stream: UsersRecord.getDocument(
                                            columnCommentsRecord.postUser!),
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

                                          final rowUsersRecord = snapshot.data!;

                                          return Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Expanded(
                                                child: RichText(
                                                  textScaler:
                                                      MediaQuery.of(context)
                                                          .textScaler,
                                                  text: TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text: rowUsersRecord
                                                            .username,
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'Poppins',
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                        mouseCursor:
                                                            SystemMouseCursors
                                                                .click,
                                                        recognizer:
                                                            TapGestureRecognizer()
                                                              ..onTap =
                                                                  () async {
                                                                if (rowUsersRecord
                                                                        .reference ==
                                                                    currentUserReference) {
                                                                  context.pushNamed(
                                                                      ProfileWidget
                                                                          .routeName);
                                                                } else {
                                                                  context
                                                                      .pushNamed(
                                                                    ProfileOtherWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'username':
                                                                          serializeParam(
                                                                        rowUsersRecord
                                                                            .username,
                                                                        ParamType
                                                                            .String,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                }
                                                              },
                                                      ),
                                                      TextSpan(
                                                        text:
                                                            FFLocalizations.of(
                                                                    context)
                                                                .getText(
                                                          '8ah32r9c' /*   */,
                                                        ),
                                                        style: TextStyle(),
                                                      ),
                                                      TextSpan(
                                                        text:
                                                            columnCommentsRecord
                                                                .comment,
                                                        style: TextStyle(),
                                                      )
                                                    ],
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Poppins',
                                                          fontSize: MediaQuery.sizeOf(
                                                                          context)
                                                                      .width <
                                                                  768.0
                                                              ? 15.0
                                                              : 20.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    );
                                  }),
                                ),
                              );
                            },
                          ),
                        ),
                      if (widget.post?.allowComments ?? true)
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 8.0, 0.0, 0.0),
                          child: InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              if (widget.post!.allowComments) {
                                context.pushNamed(
                                  CommentsWidget.routeName,
                                  queryParameters: {
                                    'post': serializeParam(
                                      widget.post?.reference,
                                      ParamType.DocumentReference,
                                    ),
                                  }.withoutNulls,
                                );
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    AuthUserStreamWidget(
                                      builder: (context) => Container(
                                        width: 25.0,
                                        height: 25.0,
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                          image: DecorationImage(
                                            fit: BoxFit.cover,
                                            image: Image.network(
                                              valueOrDefault<String>(
                                                currentUserPhoto,
                                                'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                              ),
                                            ).image,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          10.0, 0.0, 0.0, 0.0),
                                      child: Text(
                                        FFLocalizations.of(context).getText(
                                          'srf8xl01' /* Add a comment... */,
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'Poppins',
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              fontSize:
                                                  MediaQuery.sizeOf(context)
                                                              .width <
                                                          768.0
                                                      ? 15.0
                                                      : 20.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.normal,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 0.0),
                        child: Text(
                          valueOrDefault<String>(
                            dateTimeFormat(
                              "relative",
                              widget.post?.timePosted,
                              locale: FFLocalizations.of(context).languageCode,
                            ),
                            'now',
                          ),
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                fontFamily: 'Poppins',
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                fontSize:
                                    MediaQuery.sizeOf(context).width < 768.0
                                        ? 15.0
                                        : 20.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.normal,
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
  }
}
