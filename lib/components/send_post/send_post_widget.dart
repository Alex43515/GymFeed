import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'send_post_model.dart';
export 'send_post_model.dart';

class SendPostWidget extends StatefulWidget {
  const SendPostWidget({
    super.key,
    this.post,
    this.comment,
    this.post2,
  });

  final DocumentReference? post;
  final DocumentReference? comment;
  final PostsRecord? post2;

  @override
  State<SendPostWidget> createState() => _SendPostWidgetState();
}

class _SendPostWidgetState extends State<SendPostWidget> {
  late SendPostModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SendPostModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: double.infinity,
          height: 500.0,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(0.0),
              bottomRight: Radius.circular(0.0),
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
            border: Border.all(
              color: FlutterFlowTheme.of(context).tertiary,
            ),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(20.0, 10.0, 20.0, 0.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () async {
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 40.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: Color(0xFFDADADA),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 12.0, 0.0, 0.0),
                          child: StreamBuilder<List<ChatsRecord>>(
                            stream: queryChatsRecord(
                              queryBuilder: (chatsRecord) => chatsRecord
                                  .where(
                                    'users',
                                    arrayContains: currentUserReference,
                                  )
                                  .orderBy('last_message_time',
                                      descending: true),
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
                              List<ChatsRecord> columnChatsRecordList =
                                  snapshot.data!;

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children:
                                    List.generate(columnChatsRecordList.length,
                                        (columnIndex) {
                                  final columnChatsRecord =
                                      columnChatsRecordList[columnIndex];
                                  return Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 12.0),
                                    child: StreamBuilder<UsersRecord>(
                                      stream: UsersRecord.getDocument(
                                          columnChatsRecord.userA ==
                                                  currentUserReference
                                              ? columnChatsRecord.userB!
                                              : columnChatsRecord.userA!),
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

                                        final rowUsersRecord = snapshot.data!;

                                        return InkWell(
                                          splashColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () async {
                                            var chatMessagesRecordReference =
                                                ChatMessagesRecord.collection
                                                    .doc();
                                            await chatMessagesRecordReference
                                                .set(
                                                    createChatMessagesRecordData(
                                              user: currentUserReference,
                                              chat: columnChatsRecord.reference,
                                              text: widget.comment != null
                                                  ? 'Sent a comment.'
                                                  : 'Sent a photo.',
                                              timestamp: getCurrentTimestamp,
                                              postRef: widget.post,
                                              commentRef: widget.comment,
                                            ));
                                            _model.message = ChatMessagesRecord
                                                .getDocumentFromData(
                                                    createChatMessagesRecordData(
                                                      user:
                                                          currentUserReference,
                                                      chat: columnChatsRecord
                                                          .reference,
                                                      text: widget.comment !=
                                                              null
                                                          ? 'Sent a comment.'
                                                          : 'Sent a photo.',
                                                      timestamp:
                                                          getCurrentTimestamp,
                                                      postRef: widget.post,
                                                      commentRef:
                                                          widget.comment,
                                                    ),
                                                    chatMessagesRecordReference);

                                            await columnChatsRecord.reference
                                                .update({
                                              ...createChatsRecordData(
                                                lastMessage:
                                                    _model.message?.text,
                                                lastMessageTime:
                                                    getCurrentTimestamp,
                                                lastMessageSentBy:
                                                    currentUserReference,
                                              ),
                                              ...mapToFirestore(
                                                {
                                                  'last_message_seen_by':
                                                      FieldValue.arrayRemove([
                                                    columnChatsRecord.userA ==
                                                            currentUserReference
                                                        ? columnChatsRecord
                                                            .userB
                                                        : columnChatsRecord
                                                            .userB
                                                  ]),
                                                },
                                              ),
                                            });
                                            Navigator.pop(context);

                                            safeSetState(() {});
                                          },
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Container(
                                                width: 45.0,
                                                height: 45.0,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Image.network(
                                                  functions.bunnyCDNImagePath(
                                                      valueOrDefault<String>(
                                                    rowUsersRecord.photoUrl,
                                                    'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                  )),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Expanded(
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          12.0, 0.0, 0.0, 0.0),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        rowUsersRecord
                                                            .displayName,
                                                        maxLines: 1,
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodyMedium
                                                            .override(
                                                              fontFamily:
                                                                  'Poppins',
                                                              fontSize: 14.0,
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
                                                          rowUsersRecord
                                                              .username,
                                                          maxLines: 1,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodySmall
                                                              .override(
                                                                fontFamily:
                                                                    'Poppins',
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
                                              Icon(
                                                Icons.send,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                size: 20.0,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }),
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
      ],
    );
  }
}
