import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/flutter_flow/flutter_flow_expanded_image_view.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_media_display.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_video_player.dart';
import '/flutter_flow/upload_data.dart';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'individual_message_model.dart';
export 'individual_message_model.dart';

class IndividualMessageWidget extends StatefulWidget {
  const IndividualMessageWidget({
    super.key,
    this.chat,
  });

  final DocumentReference? chat;

  static String routeName = 'IndividualMessage';
  static String routePath = 'individualMessage';

  @override
  State<IndividualMessageWidget> createState() =>
      _IndividualMessageWidgetState();
}

class _IndividualMessageWidgetState extends State<IndividualMessageWidget> {
  late IndividualMessageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => IndividualMessageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await widget.chat!.update({
        ...mapToFirestore(
          {
            'last_message_seen_by':
                FieldValue.arrayUnion([currentUserReference]),
          },
        ),
      });
    });

    _model.messageTextController ??= TextEditingController();
    _model.messageFocusNode ??= FocusNode();

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
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).secondary,
          automaticallyImplyLeading: false,
          title: StreamBuilder<ChatsRecord>(
            stream: ChatsRecord.getDocument(widget.chat!),
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

              final rowChatsRecord = snapshot.data!;

              return Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      context.pushNamed(
                        MessagesWidget.routeName,
                        extra: <String, dynamic>{
                          kTransitionInfoKey: TransitionInfo(
                            hasTransition: true,
                            transitionType: PageTransitionType.leftToRight,
                          ),
                        },
                      );
                    },
                    child: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: FlutterFlowTheme.of(context).tertiary,
                      size: 15.0,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(6.0, 0.0, 0.0, 0.0),
                    child: StreamBuilder<UsersRecord>(
                      stream: UsersRecord.getDocument(
                          rowChatsRecord.userA == currentUserReference
                              ? rowChatsRecord.userB!
                              : rowChatsRecord.userA!),
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

                        final usernameUsersRecord = snapshot.data!;

                        return Text(
                          usernameUsersRecord.username,
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Poppins',
                                    fontSize: 15.0,
                                    letterSpacing: 0.0,
                                  ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 15.0, 0.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [],
              ),
            ),
          ],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: double.infinity,
                height: 0.5,
                decoration: BoxDecoration(
                  color: Color(0xFFDADADA),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  height: 100.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                  ),
                  child: Stack(
                    alignment: AlignmentDirectional(0.0, 1.0),
                    children: [
                      Align(
                        alignment: AlignmentDirectional(0.0, 1.0),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 0.0, 100.0),
                          child: StreamBuilder<List<ChatMessagesRecord>>(
                            stream: queryChatMessagesRecord(
                              queryBuilder: (chatMessagesRecord) =>
                                  chatMessagesRecord
                                      .where(
                                        'chat',
                                        isEqualTo: widget.chat,
                                      )
                                      .orderBy('timestamp', descending: true),
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
                              List<ChatMessagesRecord>
                                  messageChatMessagesRecordList =
                                  snapshot.data!;

                              return ListView.builder(
                                padding: EdgeInsets.zero,
                                reverse: true,
                                shrinkWrap: true,
                                scrollDirection: Axis.vertical,
                                itemCount: messageChatMessagesRecordList.length,
                                itemBuilder: (context, messageIndex) {
                                  final messageChatMessagesRecord =
                                      messageChatMessagesRecordList[
                                          messageIndex];
                                  return Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      if (messageChatMessagesRecord.user ==
                                          currentUserReference)
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  15.0, 0.0, 0.0, 4.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Container(
                                                width:
                                                    MediaQuery.sizeOf(context)
                                                            .width *
                                                        0.75,
                                                decoration: BoxDecoration(),
                                                child: Align(
                                                  alignment:
                                                      AlignmentDirectional(
                                                          1.0, 0.0),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      if ((messageChatMessagesRecord
                                                                  .postRef ==
                                                              null) &&
                                                          (messageChatMessagesRecord
                                                                  .commentRef ==
                                                              null))
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      0.0,
                                                                      10.0,
                                                                      0.0,
                                                                      10.0),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .end,
                                                            children: [
                                                              Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            10.0,
                                                                            0.0),
                                                                    child:
                                                                        Container(
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primary,
                                                                        borderRadius:
                                                                            BorderRadius.only(
                                                                          bottomLeft:
                                                                              Radius.circular(15.0),
                                                                          bottomRight:
                                                                              Radius.circular(0.0),
                                                                          topLeft:
                                                                              Radius.circular(15.0),
                                                                          topRight:
                                                                              Radius.circular(15.0),
                                                                        ),
                                                                      ),
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            16.0,
                                                                            10.0,
                                                                            16.0,
                                                                            10.0),
                                                                        child: SelectionArea(
                                                                            child: Text(
                                                                          messageChatMessagesRecord
                                                                              .text,
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .override(
                                                                                fontFamily: 'Poppins',
                                                                                color: FlutterFlowTheme.of(context).secondary,
                                                                                fontSize: 15.0,
                                                                                letterSpacing: 0.0,
                                                                                fontWeight: FontWeight.normal,
                                                                                lineHeight: 1.5,
                                                                              ),
                                                                        )),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              Padding(
                                                                padding: EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        0.0,
                                                                        10.0,
                                                                        10.0),
                                                                child: Text(
                                                                  dateTimeFormat(
                                                                    "relative",
                                                                    messageChatMessagesRecord
                                                                        .timestamp!,
                                                                    locale: FFLocalizations.of(
                                                                            context)
                                                                        .languageCode,
                                                                  ),
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
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
                                                      if ((messageChatMessagesRecord
                                                                  .postRef !=
                                                              null) &&
                                                          (messageChatMessagesRecord
                                                                  .commentRef !=
                                                              null))
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      0.0,
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
                                                                    messageChatMessagesRecord
                                                                        .postRef,
                                                                    ParamType
                                                                        .DocumentReference,
                                                                  ),
                                                                }.withoutNulls,
                                                              );
                                                            },
                                                            child: Stack(
                                                              alignment:
                                                                  AlignmentDirectional(
                                                                      1.0, 1.0),
                                                              children: [
                                                                Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          20.0),
                                                                  child: StreamBuilder<
                                                                      PostsRecord>(
                                                                    stream: PostsRecord.getDocument(
                                                                        messageChatMessagesRecord
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

                                                                      final postPhotoPostsRecord =
                                                                          snapshot
                                                                              .data!;

                                                                      return ClipRRect(
                                                                        borderRadius:
                                                                            BorderRadius.circular(16.0),
                                                                        child: Image
                                                                            .network(
                                                                          postPhotoPostsRecord
                                                                              .postPhoto,
                                                                          width:
                                                                              200.0,
                                                                          height:
                                                                              200.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          24.0,
                                                                          0.0),
                                                                  child: StreamBuilder<
                                                                      CommentsRecord>(
                                                                    stream: CommentsRecord.getDocument(
                                                                        messageChatMessagesRecord
                                                                            .commentRef!),
                                                                    builder:
                                                                        (context,
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
                                                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                                                Colors.white,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        );
                                                                      }

                                                                      final postCommentCommentsRecord =
                                                                          snapshot
                                                                              .data!;

                                                                      return Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        children: [
                                                                          Container(
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: FlutterFlowTheme.of(context).primary,
                                                                              borderRadius: BorderRadius.circular(16.0),
                                                                            ),
                                                                            child:
                                                                                Align(
                                                                              alignment: AlignmentDirectional(0.0, 0.0),
                                                                              child: Column(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                children: [
                                                                                  Padding(
                                                                                    padding: EdgeInsets.all(8.0),
                                                                                    child: FutureBuilder<UsersRecord>(
                                                                                      future: UsersRecord.getDocumentOnce(postCommentCommentsRecord.postUser!),
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

                                                                                        return Row(
                                                                                          mainAxisSize: MainAxisSize.max,
                                                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                                                          children: [
                                                                                            // ovo mu dodje da radi
                                                                                            Align(
                                                                                              alignment: AlignmentDirectional(0.0, 0.0),
                                                                                              child: Padding(
                                                                                                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 12.0, 0.0),
                                                                                                child: InkWell(
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
                                                                                                  child: Container(
                                                                                                    width: 37.0,
                                                                                                    height: 37.0,
                                                                                                    decoration: BoxDecoration(
                                                                                                      color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                      image: DecorationImage(
                                                                                                        fit: BoxFit.cover,
                                                                                                        image: Image.network(
                                                                                                          valueOrDefault<String>(
                                                                                                            rowUsersRecord.photoUrl,
                                                                                                            'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                                                          ),
                                                                                                        ).image,
                                                                                                      ),
                                                                                                      shape: BoxShape.circle,
                                                                                                      border: Border.all(
                                                                                                        color: FlutterFlowTheme.of(context).primary,
                                                                                                        width: 2.0,
                                                                                                      ),
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            Expanded(
                                                                                              child: Column(
                                                                                                mainAxisSize: MainAxisSize.max,
                                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                                children: [
                                                                                                  Padding(
                                                                                                    padding: EdgeInsetsDirectional.fromSTEB(0.0, 9.0, 0.0, 0.0),
                                                                                                    child: Row(
                                                                                                      mainAxisSize: MainAxisSize.max,
                                                                                                      children: [
                                                                                                        Expanded(
                                                                                                          child: RichText(
                                                                                                            textScaler: MediaQuery.of(context).textScaler,
                                                                                                            text: TextSpan(
                                                                                                              children: [
                                                                                                                TextSpan(
                                                                                                                  text: rowUsersRecord.username,
                                                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                                        fontFamily: 'Poppins',
                                                                                                                        color: FlutterFlowTheme.of(context).secondary,
                                                                                                                        letterSpacing: 0.0,
                                                                                                                        fontWeight: FontWeight.w600,
                                                                                                                      ),
                                                                                                                  mouseCursor: SystemMouseCursors.click,
                                                                                                                  recognizer: TapGestureRecognizer()
                                                                                                                    ..onTap = () async {
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
                                                                                                                ),
                                                                                                                TextSpan(
                                                                                                                  text: FFLocalizations.of(context).getText(
                                                                                                                    '2mcbm88f' /*   */,
                                                                                                                  ),
                                                                                                                  style: TextStyle(),
                                                                                                                ),
                                                                                                                TextSpan(
                                                                                                                  text: postCommentCommentsRecord.comment,
                                                                                                                  style: TextStyle(),
                                                                                                                )
                                                                                                              ],
                                                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                                    fontFamily: 'Poppins',
                                                                                                                    color: FlutterFlowTheme.of(context).secondary,
                                                                                                                    letterSpacing: 0.0,
                                                                                                                    fontWeight: FontWeight.normal,
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
                                                                                          ],
                                                                                        );
                                                                                      },
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
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      if ((messageChatMessagesRecord
                                                                  .postRef !=
                                                              null) &&
                                                          (messageChatMessagesRecord
                                                                  .commentRef ==
                                                              null))
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      0.0,
                                                                      10.0,
                                                                      10.0,
                                                                      10.0),
                                                          child: StreamBuilder<
                                                              PostsRecord>(
                                                            stream: PostsRecord
                                                                .getDocument(
                                                                    messageChatMessagesRecord
                                                                        .postRef!),
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

                                                              final photoSharingPostPostsRecord =
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
                                                                        messageChatMessagesRecord
                                                                            .postRef,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child:
                                                                    Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primary,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            16.0),
                                                                  ),
                                                                  child: FutureBuilder<
                                                                      UsersRecord>(
                                                                    future: UsersRecord.getDocumentOnce(
                                                                        photoSharingPostPostsRecord
                                                                            .postUser!),
                                                                    builder:
                                                                        (context,
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
                                                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                                                Colors.white,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        );
                                                                      }

                                                                      final columnUsersRecord =
                                                                          snapshot
                                                                              .data!;

                                                                      return Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                16.0,
                                                                                8.0,
                                                                                16.0,
                                                                                8.0),
                                                                            child:
                                                                                Row(
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                                              children: [
                                                                                Align(
                                                                                  alignment: AlignmentDirectional(0.0, 0.0),
                                                                                  child: Padding(
                                                                                    padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 12.0, 0.0),
                                                                                    child: Container(
                                                                                      width: 37.0,
                                                                                      height: 37.0,
                                                                                      decoration: BoxDecoration(
                                                                                        color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                        image: DecorationImage(
                                                                                          fit: BoxFit.cover,
                                                                                          image: Image.network(
                                                                                            valueOrDefault<String>(
                                                                                              columnUsersRecord.photoUrl,
                                                                                              'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                                            ),
                                                                                          ).image,
                                                                                        ),
                                                                                        shape: BoxShape.circle,
                                                                                        border: Border.all(
                                                                                          color: FlutterFlowTheme.of(context).primary,
                                                                                          width: 2.0,
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                Text(
                                                                                  columnUsersRecord.username.maybeHandleOverflow(
                                                                                    maxChars: 26,
                                                                                    replacement: '…',
                                                                                  ),
                                                                                  maxLines: 1,
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        fontFamily: 'Poppins',
                                                                                        color: FlutterFlowTheme.of(context).secondary,
                                                                                        letterSpacing: 0.0,
                                                                                      ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          if ((photoSharingPostPostsRecord.postPhoto != '') ||
                                                                              (photoSharingPostPostsRecord.postVideo != ''))
                                                                            Stack(
                                                                              children: [
                                                                                if (photoSharingPostPostsRecord.postPhoto != '')
                                                                                  InkWell(
                                                                                    splashColor: Colors.transparent,
                                                                                    focusColor: Colors.transparent,
                                                                                    hoverColor: Colors.transparent,
                                                                                    highlightColor: Colors.transparent,
                                                                                    onTap: () async {
                                                                                      await Navigator.push(
                                                                                        context,
                                                                                        PageTransition(
                                                                                          type: PageTransitionType.fade,
                                                                                          child: FlutterFlowExpandedImageView(
                                                                                            image: Image.network(
                                                                                              photoSharingPostPostsRecord.postPhoto,
                                                                                              fit: BoxFit.contain,
                                                                                            ),
                                                                                            allowRotation: false,
                                                                                            tag: photoSharingPostPostsRecord.postPhoto,
                                                                                            useHeroAnimation: true,
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                    },
                                                                                    child: Hero(
                                                                                      tag: photoSharingPostPostsRecord.postPhoto,
                                                                                      transitionOnUserGestures: true,
                                                                                      child: Image.network(
                                                                                        photoSharingPostPostsRecord.postPhoto,
                                                                                        width: 250.0,
                                                                                        height: 250.0,
                                                                                        fit: BoxFit.cover,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                if (photoSharingPostPostsRecord.postVideo != '')
                                                                                  FlutterFlowVideoPlayer(
                                                                                    path: photoSharingPostPostsRecord.postVideo,
                                                                                    videoType: VideoType.network,
                                                                                    width: 250.0,
                                                                                    height: 250.0,
                                                                                    autoPlay: false,
                                                                                    looping: true,
                                                                                    showControls: true,
                                                                                    allowFullScreen: true,
                                                                                    allowPlaybackSpeedMenu: false,
                                                                                  ),
                                                                              ],
                                                                            ),
                                                                          Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                16.0,
                                                                                9.0,
                                                                                16.0,
                                                                                12.0),
                                                                            child:
                                                                                Container(
                                                                              width: 218.0,
                                                                              decoration: BoxDecoration(),
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
                                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                  fontFamily: 'Poppins',
                                                                                                  color: FlutterFlowTheme.of(context).secondary,
                                                                                                  letterSpacing: 0.0,
                                                                                                  fontWeight: FontWeight.w600,
                                                                                                ),
                                                                                            mouseCursor: SystemMouseCursors.click,
                                                                                            recognizer: TapGestureRecognizer()
                                                                                              ..onTap = () async {
                                                                                                if (photoSharingPostPostsRecord.postUser == currentUserReference) {
                                                                                                  context.pushNamed(ProfileWidget.routeName);
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
                                                                                              'kb0c8vdh' /*   */,
                                                                                            ),
                                                                                            style: TextStyle(),
                                                                                          ),
                                                                                          TextSpan(
                                                                                            text: photoSharingPostPostsRecord.postCaption,
                                                                                            style: TextStyle(),
                                                                                          )
                                                                                        ],
                                                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                              fontFamily: 'Poppins',
                                                                                              color: FlutterFlowTheme.of(context).secondary,
                                                                                              letterSpacing: 0.0,
                                                                                              fontWeight: FontWeight.normal,
                                                                                            ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                16.0,
                                                                                0.0,
                                                                                0.0,
                                                                                5.0),
                                                                            child:
                                                                                Text(
                                                                              dateTimeFormat(
                                                                                "relative",
                                                                                messageChatMessagesRecord.timestamp!,
                                                                                locale: FFLocalizations.of(context).languageCode,
                                                                              ),
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    fontFamily: 'Poppins',
                                                                                    color: FlutterFlowTheme.of(context).secondary,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FontWeight.normal,
                                                                                  ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      );
                                                                    },
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      if ((messageChatMessagesRecord
                                                                      .image !=
                                                                  '') ||
                                                          (messageChatMessagesRecord
                                                                      .video !=
                                                                  ''))
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      0.0,
                                                                      10.0,
                                                                      10.0,
                                                                      10.0),
                                                          child: Container(
                                                            width: MediaQuery
                                                                        .sizeOf(
                                                                            context)
                                                                    .width *
                                                                0.7,
                                                            height: 300.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .secondaryBackground,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          16.0),
                                                            ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              children: [
                                                                Stack(
                                                                  children: [
                                                                    if (messageChatMessagesRecord.image !=
                                                                            '')
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
                                                                          await Navigator
                                                                              .push(
                                                                            context,
                                                                            PageTransition(
                                                                              type: PageTransitionType.fade,
                                                                              child: FlutterFlowExpandedImageView(
                                                                                image: Image.network(
                                                                                  messageChatMessagesRecord.image,
                                                                                  fit: BoxFit.contain,
                                                                                ),
                                                                                allowRotation: false,
                                                                                tag: messageChatMessagesRecord.image,
                                                                                useHeroAnimation: true,
                                                                              ),
                                                                            ),
                                                                          );
                                                                        },
                                                                        child:
                                                                            Hero(
                                                                          tag: messageChatMessagesRecord
                                                                              .image,
                                                                          transitionOnUserGestures:
                                                                              true,
                                                                          child:
                                                                              ClipRRect(
                                                                            borderRadius:
                                                                                BorderRadius.circular(16.0),
                                                                            child:
                                                                                Image.network(
                                                                              messageChatMessagesRecord.image,
                                                                              width: MediaQuery.sizeOf(context).width * 0.8,
                                                                              height: 300.0,
                                                                              fit: BoxFit.cover,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    if (messageChatMessagesRecord.video !=
                                                                            '')
                                                                      FlutterFlowVideoPlayer(
                                                                        path: messageChatMessagesRecord
                                                                            .video,
                                                                        videoType:
                                                                            VideoType.network,
                                                                        width: MediaQuery.sizeOf(context).width *
                                                                            0.7,
                                                                        height:
                                                                            300.0,
                                                                        autoPlay:
                                                                            false,
                                                                        looping:
                                                                            true,
                                                                        showControls:
                                                                            true,
                                                                        allowFullScreen:
                                                                            true,
                                                                        allowPlaybackSpeedMenu:
                                                                            false,
                                                                      ),
                                                                  ],
                                                                ),
                                                                Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .end,
                                                                  children: [
                                                                    Text(
                                                                      dateTimeFormat(
                                                                        "relative",
                                                                        messageChatMessagesRecord
                                                                            .timestamp!,
                                                                        locale:
                                                                            FFLocalizations.of(context).languageCode,
                                                                      ),
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .override(
                                                                            fontFamily:
                                                                                'Poppins',
                                                                            color:
                                                                                FlutterFlowTheme.of(context).tertiary,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            fontWeight:
                                                                                FontWeight.normal,
                                                                          ),
                                                                    ),
                                                                  ],
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
                                          ),
                                        ),
                                      if (messageChatMessagesRecord.user !=
                                          currentUserReference)
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 15.0, 4.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Container(
                                                width:
                                                    MediaQuery.sizeOf(context)
                                                            .width *
                                                        0.75,
                                                decoration: BoxDecoration(),
                                                child: Align(
                                                  alignment:
                                                      AlignmentDirectional(
                                                          -1.0, 0.0),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      if ((messageChatMessagesRecord
                                                                  .postRef ==
                                                              null) &&
                                                          (messageChatMessagesRecord
                                                                  .commentRef ==
                                                              null))
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      0.0,
                                                                      10.0,
                                                                      0.0,
                                                                      10.0),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            10.0,
                                                                            0.0,
                                                                            0.0,
                                                                            0.0),
                                                                    child:
                                                                        Container(
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Color(
                                                                            0xFFF6F6F6),
                                                                        borderRadius:
                                                                            BorderRadius.only(
                                                                          bottomLeft:
                                                                              Radius.circular(0.0),
                                                                          bottomRight:
                                                                              Radius.circular(15.0),
                                                                          topLeft:
                                                                              Radius.circular(15.0),
                                                                          topRight:
                                                                              Radius.circular(15.0),
                                                                        ),
                                                                      ),
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            16.0,
                                                                            10.0,
                                                                            16.0,
                                                                            10.0),
                                                                        child: SelectionArea(
                                                                            child: Text(
                                                                          messageChatMessagesRecord
                                                                              .text,
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .override(
                                                                                fontFamily: 'Poppins',
                                                                                color: FlutterFlowTheme.of(context).primaryText,
                                                                                fontSize: 15.0,
                                                                                letterSpacing: 0.0,
                                                                                fontWeight: FontWeight.normal,
                                                                                lineHeight: 1.5,
                                                                              ),
                                                                        )),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              Padding(
                                                                padding: EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        10.0,
                                                                        2.0,
                                                                        0.0,
                                                                        10.0),
                                                                child: Text(
                                                                  dateTimeFormat(
                                                                    "relative",
                                                                    messageChatMessagesRecord
                                                                        .timestamp!,
                                                                    locale: FFLocalizations.of(
                                                                            context)
                                                                        .languageCode,
                                                                  ),
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
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
                                                      if ((messageChatMessagesRecord
                                                                  .postRef !=
                                                              null) &&
                                                          (messageChatMessagesRecord
                                                                  .commentRef !=
                                                              null))
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      10.0,
                                                                      10.0,
                                                                      0.0,
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
                                                                    messageChatMessagesRecord
                                                                        .postRef,
                                                                    ParamType
                                                                        .DocumentReference,
                                                                  ),
                                                                }.withoutNulls,
                                                              );
                                                            },
                                                            child: Stack(
                                                              alignment:
                                                                  AlignmentDirectional(
                                                                      -1.0,
                                                                      1.0),
                                                              children: [
                                                                Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          20.0),
                                                                  child: StreamBuilder<
                                                                      PostsRecord>(
                                                                    stream: PostsRecord.getDocument(
                                                                        messageChatMessagesRecord
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

                                                                      final postPhotoPostsRecord =
                                                                          snapshot
                                                                              .data!;

                                                                      return ClipRRect(
                                                                        borderRadius:
                                                                            BorderRadius.circular(16.0),
                                                                        child: Image
                                                                            .network(
                                                                          postPhotoPostsRecord
                                                                              .postPhoto,
                                                                          width:
                                                                              200.0,
                                                                          height:
                                                                              200.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          24.0,
                                                                          0.0,
                                                                          0.0,
                                                                          0.0),
                                                                  child: StreamBuilder<
                                                                      CommentsRecord>(
                                                                    stream: CommentsRecord.getDocument(
                                                                        messageChatMessagesRecord
                                                                            .commentRef!),
                                                                    builder:
                                                                        (context,
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
                                                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                                                Colors.white,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        );
                                                                      }

                                                                      final postCommentCommentsRecord =
                                                                          snapshot
                                                                              .data!;

                                                                      return Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        children: [
                                                                          Container(
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: Color(0xFFF5F5F5),
                                                                              borderRadius: BorderRadius.circular(16.0),
                                                                            ),
                                                                            child:
                                                                                Align(
                                                                              alignment: AlignmentDirectional(0.0, 0.0),
                                                                              child: Column(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                children: [
                                                                                  Padding(
                                                                                    padding: EdgeInsets.all(8.0),
                                                                                    child: FutureBuilder<UsersRecord>(
                                                                                      future: UsersRecord.getDocumentOnce(postCommentCommentsRecord.postUser!),
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

                                                                                        return Row(
                                                                                          mainAxisSize: MainAxisSize.max,
                                                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                                                          children: [
                                                                                            Align(
                                                                                              alignment: AlignmentDirectional(0.0, 0.0),
                                                                                              child: Padding(
                                                                                                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 12.0, 0.0),
                                                                                                child: Container(
                                                                                                  width: 37.0,
                                                                                                  height: 37.0,
                                                                                                  decoration: BoxDecoration(
                                                                                                    color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                    image: DecorationImage(
                                                                                                      fit: BoxFit.cover,
                                                                                                      image: Image.network(
                                                                                                        valueOrDefault<String>(
                                                                                                          rowUsersRecord.photoUrl,
                                                                                                          'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                                                        ),
                                                                                                      ).image,
                                                                                                    ),
                                                                                                    shape: BoxShape.circle,
                                                                                                    border: Border.all(
                                                                                                      color: FlutterFlowTheme.of(context).primary,
                                                                                                      width: 2.0,
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            Expanded(
                                                                                              child: Column(
                                                                                                mainAxisSize: MainAxisSize.max,
                                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                                children: [
                                                                                                  Padding(
                                                                                                    padding: EdgeInsetsDirectional.fromSTEB(0.0, 9.0, 0.0, 0.0),
                                                                                                    child: Row(
                                                                                                      mainAxisSize: MainAxisSize.max,
                                                                                                      children: [
                                                                                                        Expanded(
                                                                                                          child: RichText(
                                                                                                            textScaler: MediaQuery.of(context).textScaler,
                                                                                                            text: TextSpan(
                                                                                                              children: [
                                                                                                                TextSpan(
                                                                                                                  text: rowUsersRecord.username,
                                                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                                        fontFamily: 'Poppins',
                                                                                                                        color: FlutterFlowTheme.of(context).secondary,
                                                                                                                        letterSpacing: 0.0,
                                                                                                                        fontWeight: FontWeight.w600,
                                                                                                                      ),
                                                                                                                  mouseCursor: SystemMouseCursors.click,
                                                                                                                  recognizer: TapGestureRecognizer()
                                                                                                                    ..onTap = () async {
                                                                                                                      if (postCommentCommentsRecord.postUser == currentUserReference) {
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
                                                                                                                ),
                                                                                                                TextSpan(
                                                                                                                  text: FFLocalizations.of(context).getText(
                                                                                                                    'z5jbckj7' /*   */,
                                                                                                                  ),
                                                                                                                  style: TextStyle(),
                                                                                                                ),
                                                                                                                TextSpan(
                                                                                                                  text: postCommentCommentsRecord.comment,
                                                                                                                  style: TextStyle(),
                                                                                                                )
                                                                                                              ],
                                                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                                    fontFamily: 'Poppins',
                                                                                                                    color: FlutterFlowTheme.of(context).secondary,
                                                                                                                    letterSpacing: 0.0,
                                                                                                                    fontWeight: FontWeight.normal,
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
                                                                                          ],
                                                                                        );
                                                                                      },
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
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      if ((messageChatMessagesRecord
                                                                  .postRef !=
                                                              null) &&
                                                          (messageChatMessagesRecord
                                                                  .commentRef ==
                                                              null))
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      10.0,
                                                                      10.0,
                                                                      0.0,
                                                                      10.0),
                                                          child: StreamBuilder<
                                                              PostsRecord>(
                                                            stream: PostsRecord
                                                                .getDocument(
                                                                    messageChatMessagesRecord
                                                                        .postRef!),
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

                                                              final photoSharingPostPostsRecord =
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
                                                                        messageChatMessagesRecord
                                                                            .postRef,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child:
                                                                    Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Color(
                                                                        0xFFF5F5F5),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            16.0),
                                                                  ),
                                                                  child: FutureBuilder<
                                                                      UsersRecord>(
                                                                    future: UsersRecord.getDocumentOnce(
                                                                        photoSharingPostPostsRecord
                                                                            .postUser!),
                                                                    builder:
                                                                        (context,
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
                                                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                                                Colors.white,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        );
                                                                      }

                                                                      final columnUsersRecord =
                                                                          snapshot
                                                                              .data!;

                                                                      return Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                16.0,
                                                                                8.0,
                                                                                16.0,
                                                                                8.0),
                                                                            child:
                                                                                Row(
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                                              children: [
                                                                                Align(
                                                                                  alignment: AlignmentDirectional(0.0, 0.0),
                                                                                  child: Padding(
                                                                                    padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 12.0, 0.0),
                                                                                    child: Container(
                                                                                      width: 37.0,
                                                                                      height: 37.0,
                                                                                      decoration: BoxDecoration(
                                                                                        color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                        image: DecorationImage(
                                                                                          fit: BoxFit.cover,
                                                                                          image: Image.network(
                                                                                            valueOrDefault<String>(
                                                                                              columnUsersRecord.photoUrl,
                                                                                              'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                                            ),
                                                                                          ).image,
                                                                                        ),
                                                                                        shape: BoxShape.circle,
                                                                                        border: Border.all(
                                                                                          color: FlutterFlowTheme.of(context).primary,
                                                                                          width: 2.0,
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                Text(
                                                                                  columnUsersRecord.username.maybeHandleOverflow(
                                                                                    maxChars: 26,
                                                                                    replacement: '…',
                                                                                  ),
                                                                                  maxLines: 1,
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        fontFamily: 'Poppins',
                                                                                        color: FlutterFlowTheme.of(context).secondary,
                                                                                        letterSpacing: 0.0,
                                                                                      ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          if ((photoSharingPostPostsRecord.postPhoto != '') ||
                                                                              (photoSharingPostPostsRecord.postVideo != ''))
                                                                            Stack(
                                                                              children: [
                                                                                if (photoSharingPostPostsRecord.postPhoto != '')
                                                                                  Image.network(
                                                                                    photoSharingPostPostsRecord.postPhoto,
                                                                                    width: 250.0,
                                                                                    height: 250.0,
                                                                                    fit: BoxFit.cover,
                                                                                  ),
                                                                                if (photoSharingPostPostsRecord.postVideo != '')
                                                                                  FlutterFlowVideoPlayer(
                                                                                    path: photoSharingPostPostsRecord.postVideo,
                                                                                    videoType: VideoType.network,
                                                                                    width: 250.0,
                                                                                    height: 250.0,
                                                                                    autoPlay: false,
                                                                                    looping: true,
                                                                                    showControls: true,
                                                                                    allowFullScreen: true,
                                                                                    allowPlaybackSpeedMenu: false,
                                                                                  ),
                                                                              ],
                                                                            ),
                                                                          Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                16.0,
                                                                                9.0,
                                                                                16.0,
                                                                                12.0),
                                                                            child:
                                                                                Container(
                                                                              width: 218.0,
                                                                              decoration: BoxDecoration(),
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
                                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                  fontFamily: 'Poppins',
                                                                                                  color: FlutterFlowTheme.of(context).secondary,
                                                                                                  letterSpacing: 0.0,
                                                                                                  fontWeight: FontWeight.w600,
                                                                                                ),
                                                                                            mouseCursor: SystemMouseCursors.click,
                                                                                            recognizer: TapGestureRecognizer()
                                                                                              ..onTap = () async {
                                                                                                if (photoSharingPostPostsRecord.postUser == currentUserReference) {
                                                                                                  context.pushNamed(ProfileWidget.routeName);
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
                                                                                              'mpxhbf9a' /*   */,
                                                                                            ),
                                                                                            style: TextStyle(),
                                                                                          ),
                                                                                          TextSpan(
                                                                                            text: photoSharingPostPostsRecord.postCaption,
                                                                                            style: TextStyle(),
                                                                                          )
                                                                                        ],
                                                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                              fontFamily: 'Poppins',
                                                                                              color: FlutterFlowTheme.of(context).secondary,
                                                                                              letterSpacing: 0.0,
                                                                                              fontWeight: FontWeight.normal,
                                                                                            ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                17.0,
                                                                                0.0,
                                                                                0.0,
                                                                                0.0),
                                                                            child:
                                                                                Text(
                                                                              dateTimeFormat(
                                                                                "relative",
                                                                                messageChatMessagesRecord.timestamp!,
                                                                                locale: FFLocalizations.of(context).languageCode,
                                                                              ),
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    fontFamily: 'Poppins',
                                                                                    color: FlutterFlowTheme.of(context).secondary,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FontWeight.normal,
                                                                                  ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      );
                                                                    },
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      if ((messageChatMessagesRecord
                                                                      .image !=
                                                                  '') ||
                                                          (messageChatMessagesRecord
                                                                      .video !=
                                                                  ''))
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      10.0,
                                                                      10.0,
                                                                      0.0,
                                                                      10.0),
                                                          child: Container(
                                                            width: MediaQuery
                                                                        .sizeOf(
                                                                            context)
                                                                    .width *
                                                                0.7,
                                                            height: 300.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .secondaryBackground,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          16.0),
                                                            ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              children: [
                                                                Stack(
                                                                  children: [
                                                                    if (messageChatMessagesRecord.image !=
                                                                            '')
                                                                      ClipRRect(
                                                                        borderRadius:
                                                                            BorderRadius.circular(16.0),
                                                                        child: Image
                                                                            .network(
                                                                          messageChatMessagesRecord
                                                                              .image,
                                                                          width:
                                                                              MediaQuery.sizeOf(context).width * 0.8,
                                                                          height:
                                                                              300.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    if (messageChatMessagesRecord.video !=
                                                                            '')
                                                                      FlutterFlowVideoPlayer(
                                                                        path: messageChatMessagesRecord
                                                                            .video,
                                                                        videoType:
                                                                            VideoType.network,
                                                                        width: MediaQuery.sizeOf(context).width *
                                                                            0.7,
                                                                        height:
                                                                            300.0,
                                                                        autoPlay:
                                                                            false,
                                                                        looping:
                                                                            true,
                                                                        showControls:
                                                                            true,
                                                                        allowFullScreen:
                                                                            true,
                                                                        allowPlaybackSpeedMenu:
                                                                            false,
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
                                                                  child: Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    children: [
                                                                      Text(
                                                                        dateTimeFormat(
                                                                          "relative",
                                                                          messageChatMessagesRecord
                                                                              .timestamp!,
                                                                          locale:
                                                                              FFLocalizations.of(context).languageCode,
                                                                        ),
                                                                        style: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .override(
                                                                              fontFamily: 'Poppins',
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
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
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
              ),
              Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  if ((_model.uploadedFileUrl2 != '') ||
                      (_model.uploadedFileUrl1 != ''))
                    Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: Color(0xFF313131),
                      ),
                      child: Visibility(
                        visible: (_model.uploadedFileUrl2 != '') ||
                            (_model.uploadedFileUrl1 != ''),
                        child: Stack(
                          children: [
                            if (_model.uploadedFileUrl2 != '')
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 10.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 12.0, 0.0, 0.0),
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              FlutterFlowMediaDisplay(
                                                path: _model.uploadedFileUrl2,
                                                imageBuilder: (path) =>
                                                    ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                  child: CachedNetworkImage(
                                                    fadeInDuration: Duration(
                                                        milliseconds: 500),
                                                    fadeOutDuration: Duration(
                                                        milliseconds: 500),
                                                    imageUrl: path,
                                                    width: 120.0,
                                                    height: 100.0,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                videoPlayerBuilder: (path) =>
                                                    FlutterFlowVideoPlayer(
                                                  path: path,
                                                  width: 300.0,
                                                  autoPlay: false,
                                                  looping: true,
                                                  showControls: true,
                                                  allowFullScreen: true,
                                                  allowPlaybackSpeedMenu: false,
                                                ),
                                              ),
                                              Align(
                                                alignment: AlignmentDirectional(
                                                    -1.0, -1.0),
                                                child: FlutterFlowIconButton(
                                                  borderColor:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .error,
                                                  borderRadius: 20.0,
                                                  borderWidth: 2.0,
                                                  buttonSize: 40.0,
                                                  fillColor:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .primaryBackground,
                                                  icon: Icon(
                                                    Icons
                                                        .delete_outline_rounded,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .error,
                                                    size: 24.0,
                                                  ),
                                                  onPressed: () async {
                                                    safeSetState(() {
                                                      _model.isDataUploading2 =
                                                          false;
                                                      _model.uploadedLocalFile2 =
                                                          FFUploadedFile(
                                                              bytes: Uint8List
                                                                  .fromList(
                                                                      []));
                                                      _model.uploadedFileUrl2 =
                                                          '';
                                                    });
                                                  },
                                                ),
                                              ),
                                            ]
                                                .divide(SizedBox(width: 8.0))
                                                .addToStart(
                                                    SizedBox(width: 16.0))
                                                .addToEnd(
                                                    SizedBox(width: 16.0)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_model.uploadedFileUrl1 != '')
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 10.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 12.0, 0.0, 0.0),
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              FlutterFlowVideoPlayer(
                                                path: _model.uploadedFileUrl1,
                                                videoType: VideoType.network,
                                                width:
                                                    MediaQuery.sizeOf(context)
                                                            .width *
                                                        0.5,
                                                height: 100.0,
                                                autoPlay: false,
                                                looping: true,
                                                showControls: false,
                                                allowFullScreen: true,
                                                allowPlaybackSpeedMenu: false,
                                              ),
                                              Align(
                                                alignment: AlignmentDirectional(
                                                    -1.0, -1.0),
                                                child: FlutterFlowIconButton(
                                                  borderColor:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .error,
                                                  borderRadius: 20.0,
                                                  borderWidth: 2.0,
                                                  buttonSize: 30.0,
                                                  fillColor:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .primaryBackground,
                                                  icon: Icon(
                                                    Icons
                                                        .delete_outline_rounded,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .error,
                                                    size: 15.0,
                                                  ),
                                                  onPressed: () async {
                                                    safeSetState(() {
                                                      _model.isDataUploading1 =
                                                          false;
                                                      _model.uploadedLocalFile1 =
                                                          FFUploadedFile(
                                                              bytes: Uint8List
                                                                  .fromList(
                                                                      []));
                                                      _model.uploadedFileUrl1 =
                                                          '';
                                                    });
                                                  },
                                                ),
                                              ),
                                            ]
                                                .divide(SizedBox(width: 8.0))
                                                .addToStart(
                                                    SizedBox(width: 16.0))
                                                .addToEnd(
                                                    SizedBox(width: 16.0)),
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
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(5.0, 0.0, 5.0, 10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondary,
                        borderRadius: BorderRadius.circular(15.0),
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).tertiary,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  5.0, 0.0, 0.0, 0.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  _model.pickedVideo =
                                      await actions.pickVideo();
                                  _model.compressedVideo =
                                      await actions.compressVideo(
                                    _model.pickedVideo!,
                                  );
                                  {
                                    safeSetState(
                                        () => _model.isDataUploading1 = true);
                                    var selectedUploadedFiles =
                                        <FFUploadedFile>[];
                                    var selectedMedia = <SelectedFile>[];
                                    var downloadUrls = <String>[];
                                    try {
                                      selectedUploadedFiles = _model
                                              .compressedVideo!
                                              .bytes!
                                              .isNotEmpty
                                          ? [_model.compressedVideo!]
                                          : <FFUploadedFile>[];
                                      selectedMedia =
                                          selectedFilesFromUploadedFiles(
                                        selectedUploadedFiles,
                                      );
                                      downloadUrls = (await Future.wait(
                                        selectedMedia.map(
                                          (m) async => await uploadData(
                                              m.storagePath, m.bytes),
                                        ),
                                      ))
                                          .where((u) => u != null)
                                          .map((u) => u!)
                                          .toList();
                                    } finally {
                                      _model.isDataUploading1 = false;
                                    }
                                    if (selectedUploadedFiles.length ==
                                            selectedMedia.length &&
                                        downloadUrls.length ==
                                            selectedMedia.length) {
                                      safeSetState(() {
                                        _model.uploadedLocalFile1 =
                                            selectedUploadedFiles.first;
                                        _model.uploadedFileUrl1 =
                                            downloadUrls.first;
                                      });
                                    } else {
                                      safeSetState(() {});
                                      return;
                                    }
                                  }

                                  if (_model.uploadedFileUrl1 != '') {
                                    _model.addToVideoUploaded(
                                        _model.uploadedFileUrl1);
                                    safeSetState(() {});
                                  }

                                  safeSetState(() {});
                                },
                                child: Icon(
                                  Icons.video_collection,
                                  color: FlutterFlowTheme.of(context).primary,
                                  size: 24.0,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  5.0, 0.0, 0.0, 0.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  _model.pickedImage =
                                      await actions.pickImage();
                                  _model.compressImage =
                                      await actions.compressImage(
                                    _model.pickedImage!,
                                  );
                                  {
                                    safeSetState(
                                        () => _model.isDataUploading2 = true);
                                    var selectedUploadedFiles =
                                        <FFUploadedFile>[];
                                    var selectedMedia = <SelectedFile>[];
                                    var downloadUrls = <String>[];
                                    try {
                                      selectedUploadedFiles = _model
                                              .compressImage!.bytes!.isNotEmpty
                                          ? [_model.compressImage!]
                                          : <FFUploadedFile>[];
                                      selectedMedia =
                                          selectedFilesFromUploadedFiles(
                                        selectedUploadedFiles,
                                      );
                                      downloadUrls = (await Future.wait(
                                        selectedMedia.map(
                                          (m) async => await uploadData(
                                              m.storagePath, m.bytes),
                                        ),
                                      ))
                                          .where((u) => u != null)
                                          .map((u) => u!)
                                          .toList();
                                    } finally {
                                      _model.isDataUploading2 = false;
                                    }
                                    if (selectedUploadedFiles.length ==
                                            selectedMedia.length &&
                                        downloadUrls.length ==
                                            selectedMedia.length) {
                                      safeSetState(() {
                                        _model.uploadedLocalFile2 =
                                            selectedUploadedFiles.first;
                                        _model.uploadedFileUrl2 =
                                            downloadUrls.first;
                                      });
                                    } else {
                                      safeSetState(() {});
                                      return;
                                    }
                                  }

                                  if (_model.uploadedFileUrl2 != '') {
                                    _model.addToImageUploaded(
                                        _model.uploadedFileUrl2);
                                    safeSetState(() {});
                                  }

                                  safeSetState(() {});
                                },
                                child: Icon(
                                  Icons.image,
                                  color: FlutterFlowTheme.of(context).primary,
                                  size: 24.0,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    12.0, 0.0, 0.0, 0.0),
                                child: Stack(
                                  alignment: AlignmentDirectional(1.0, 1.0),
                                  children: [
                                    TextFormField(
                                      controller: _model.messageTextController,
                                      focusNode: _model.messageFocusNode,
                                      autofocus: false,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      obscureText: false,
                                      decoration: InputDecoration(
                                        labelStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'Poppins',
                                              letterSpacing: 0.0,
                                            ),
                                        hintText:
                                            FFLocalizations.of(context).getText(
                                          'h2kcau4t' /* Message... */,
                                        ),
                                        hintStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'Poppins',
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              fontSize: 15.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.normal,
                                            ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0x00DADADA),
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0x00000000),
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0x00000000),
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0x00000000),
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                        ),
                                        contentPadding:
                                            EdgeInsetsDirectional.fromSTEB(
                                                0.0, 8.0, 55.0, 8.0),
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Poppins',
                                            fontSize: 15.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.normal,
                                            lineHeight: 1.5,
                                          ),
                                      maxLines: 5,
                                      minLines: 1,
                                      cursorColor: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      validator: _model
                                          .messageTextControllerValidator
                                          .asValidator(context),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 16.0, 15.0),
                                      child: StreamBuilder<ChatsRecord>(
                                        stream: ChatsRecord.getDocument(
                                            widget.chat!),
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

                                          final sendChatsRecord =
                                              snapshot.data!;

                                          return InkWell(
                                            splashColor: Colors.transparent,
                                            focusColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            onTap: () async {
                                              if (_model.messageTextController
                                                          .text !=
                                                      '') {
                                                var chatMessagesRecordReference =
                                                    ChatMessagesRecord
                                                        .collection
                                                        .doc();
                                                await chatMessagesRecordReference
                                                    .set(
                                                        createChatMessagesRecordData(
                                                  user: currentUserReference,
                                                  chat: widget.chat,
                                                  text: _model
                                                      .messageTextController
                                                      .text,
                                                  timestamp:
                                                      getCurrentTimestamp,
                                                  image:
                                                      _model.uploadedFileUrl2,
                                                  video:
                                                      _model.uploadedFileUrl1,
                                                ));
                                                _model.message = ChatMessagesRecord
                                                    .getDocumentFromData(
                                                        createChatMessagesRecordData(
                                                          user:
                                                              currentUserReference,
                                                          chat: widget.chat,
                                                          text: _model
                                                              .messageTextController
                                                              .text,
                                                          timestamp:
                                                              getCurrentTimestamp,
                                                          image: _model
                                                              .uploadedFileUrl2,
                                                          video: _model
                                                              .uploadedFileUrl1,
                                                        ),
                                                        chatMessagesRecordReference);

                                                await widget.chat!.update({
                                                  ...createChatsRecordData(
                                                    lastMessage: _model
                                                        .messageTextController
                                                        .text,
                                                    lastMessageTime:
                                                        getCurrentTimestamp,
                                                    lastMessageSentBy:
                                                        currentUserReference,
                                                  ),
                                                  ...mapToFirestore(
                                                    {
                                                      'last_message_seen_by':
                                                          FieldValue
                                                              .arrayRemove([
                                                        sendChatsRecord.userA ==
                                                                currentUserReference
                                                            ? sendChatsRecord
                                                                .userB
                                                            : sendChatsRecord
                                                                .userA
                                                      ]),
                                                    },
                                                  ),
                                                });
                                                safeSetState(() {
                                                  _model.messageTextController
                                                      ?.clear();
                                                });
                                                triggerPushNotification(
                                                  notificationTitle:
                                                      'You have a new message',
                                                  notificationText:
                                                      sendChatsRecord
                                                          .lastMessage,
                                                  notificationSound: 'default',
                                                  userRefs: [
                                                    currentUserReference ==
                                                            sendChatsRecord
                                                                .userA
                                                        ? sendChatsRecord.userB!
                                                        : sendChatsRecord.userA!
                                                  ],
                                                  initialPageName:
                                                      'IndividualMessage',
                                                  parameterData: {
                                                    'chat': widget.chat,
                                                  },
                                                );
                                              }

                                              safeSetState(() {});
                                            },
                                            child: Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                'vityl4ga' /* Send */,
                                              ),
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .bodyMedium
                                                  .override(
                                                    fontFamily: 'Poppins',
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    fontSize: 15.0,
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
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
