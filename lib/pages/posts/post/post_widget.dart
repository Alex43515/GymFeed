import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/supabase/repositories/post_repository.dart';
import '/backend/supabase/repositories/bookmark_repository.dart';
import '/components/personal_post_options/personal_post_options_widget.dart';
import '/components/send_post/send_post_widget.dart';
import '/components/tagged_users/tagged_users_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_toggle_icon.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/posts/post_options/post_options_widget.dart';
import '/custom_code/widgets/feed_video_player.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'post_model.dart';
export 'post_model.dart';

class PostWidget extends StatefulWidget {
  const PostWidget({
    super.key,
    this.post,
    this.detailsPage,
    this.onPostChanged,
  });

  final PostsRecord? post;
  final bool? detailsPage;
  final Future<void> Function()? onPostChanged;

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> with TickerProviderStateMixin {
  late PostModel _model;
  late bool _liked;
  late int _likeCount;
  late Future<UsersRecord> _authorFuture;
  UsersRecord? _initialAuthor;
  bool _savingLike = false;
  late bool _allowLikes;
  late bool _allowComments;
  bool _deleted = false;

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
    _readLikeState();
    _readPermissionState();
    _prepareAuthor();

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      safeSetState(() {});
      _syncLikeState();
    });
  }

  @override
  void didUpdateWidget(covariant PostWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post?.reference.id != widget.post?.reference.id) {
      _readLikeState();
      _readPermissionState();
      _syncLikeState();
    } else if (oldWidget.post?.allowLikes != widget.post?.allowLikes ||
        oldWidget.post?.allowComments != widget.post?.allowComments ||
        oldWidget.post?.deleted != widget.post?.deleted) {
      _readPermissionState();
    }
    if (oldWidget.post?.postUser?.id != widget.post?.postUser?.id) {
      _prepareAuthor();
    }
  }

  void _prepareAuthor() {
    final post = widget.post!;
    _initialAuthor = post.feedAuthor;
    _authorFuture = UsersRecord.getDocumentOnce(post.postUser!);
  }

  void _readLikeState() {
    _liked = widget.post?.likes.contains(currentUserReference) ?? false;
    _likeCount = widget.post?.likes.length ?? 0;
  }

  void _readPermissionState() {
    _allowLikes = !widget.post!.hasAllowLikes() || widget.post!.allowLikes;
    _allowComments =
        !widget.post!.hasAllowComments() || widget.post!.allowComments;
    _deleted = widget.post?.deleted ?? false;
  }

  Future<void> _applyOwnerAction(PersonalPostOptionsResult? result) async {
    if (result == null || !mounted) return;
    if (result.editRequested) {
      await context.pushNamed(
        EditPostWidget.routeName,
        queryParameters: {
          'post': serializeParam(widget.post, ParamType.Document),
        }.withoutNulls,
        extra: <String, dynamic>{'post': widget.post},
      );
      await widget.onPostChanged?.call();
      return;
    }
    setState(() {
      if (result.allowLikes != null) _allowLikes = result.allowLikes!;
      if (result.allowComments != null) {
        _allowComments = result.allowComments!;
      }
      if (result.deleted) _deleted = true;
    });
    await widget.onPostChanged?.call();
    if (result.deleted && mounted && widget.detailsPage == false) {
      context.pop();
    }
  }

  Future<void> _syncLikeState() async {
    final postId = widget.post?.reference.id;
    if (postId == null || postId.isEmpty) return;
    try {
      final results = await Future.wait<dynamic>([
        PostRepository().isLiked(postId),
        PostRepository().getById(postId),
      ]);
      if (!mounted || widget.post?.reference.id != postId) return;
      final row = results[1] as Map<String, dynamic>?;
      setState(() {
        _liked = results[0] == true;
        _likeCount = (row?['like_count'] as num?)?.toInt() ?? _likeCount;
      });
    } catch (_) {
      // Feed data remains visible when a refresh cannot be completed.
    }
  }

  Future<void> _toggleLike() async {
    if (_savingLike || !_allowLikes) return;
    final postId = widget.post?.reference.id;
    if (postId == null || postId.isEmpty) return;
    final previousLiked = _liked;
    final previousCount = _likeCount;
    final shouldLike = !_liked;
    setState(() {
      _savingLike = true;
      _liked = shouldLike;
      _likeCount = (_likeCount + (shouldLike ? 1 : -1)).clamp(0, 1 << 31);
    });
    try {
      if (shouldLike) {
        await PostRepository().likePost(postId);
      } else {
        await PostRepository().unlikePost(postId);
      }
      await HapticFeedback.selectionClick();
      await _syncLikeState();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _liked = previousLiked;
        _likeCount = previousCount;
      });
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Could not update this like. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _savingLike = false);
    }
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  void _openAuthorProfile(UsersRecord author) {
    if (author.reference == currentUserReference) {
      context.pushNamed(ProfileWidget.routeName);
      return;
    }
    // ProfileOther resolves the Supabase block relationship before it renders.
    // Keeping that check in one place avoids the obsolete Firestore
    // legacy per-document block list, which is always empty in the Supabase
    // adapter.
    context.pushNamed(
      ProfileOtherWidget.routeName,
      queryParameters: {
        'username': serializeParam(author.username, ParamType.String),
      }.withoutNulls,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_deleted) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 25.0),
      child: FutureBuilder<UsersRecord>(
        initialData: _initialAuthor,
        future: _authorFuture,
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
                        _openAuthorProfile(columnUsersRecord);
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
                              _openAuthorProfile(columnUsersRecord);
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
                                    _openAuthorProfile(columnUsersRecord);
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
                          final result = await showModalBottomSheet<
                              PersonalPostOptionsResult>(
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
                          );
                          await _applyOwnerAction(result);
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
                                onDoubleTap: _toggleLike,
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
                                        child: CachedNetworkImage(
                                          imageUrl: functions.bunnyCDNImagePath(
                                              widget.post!.postPhoto),
                                          width: double.infinity,
                                          height: 350.0,
                                          fit: BoxFit.cover,
                                          fadeInDuration:
                                              const Duration(milliseconds: 150),
                                          placeholder: (_, __) => Container(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                          ),
                                          errorWidget: (_, __, ___) =>
                                              const SizedBox.shrink(),
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
                                  child: SizedBox(
                                    width:
                                        MediaQuery.sizeOf(context).width * 1.0,
                                    height: 350.0,
                                    child: FeedVideoPlayer(
                                      videoUrl: functions.bunnyCDNVideoPath(
                                          widget.post!.postVideo),
                                      thumbnailUrl:
                                          widget.post!.videoThumbnail.isNotEmpty
                                              ? functions.bunnyCDNImagePath(
                                                  widget.post!.videoThumbnail)
                                              : null,
                                      borderRadius: 20.0,
                                      onTap: () {
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
                                    ),
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
                          if (_allowLikes)
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

                                  return ToggleIcon(
                                    onPressed: _toggleLike,
                                    value: _liked,
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
                          if (_allowComments)
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
                                    await BookmarkRepository().add(
                                        widget.post!.reference.id,
                                        BookmarkKind.post);
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
                                  .contains(widget.post?.reference))
                                InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    await BookmarkRepository().remove(
                                        widget.post!.reference.id,
                                        BookmarkKind.post);
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
                      if (_allowLikes)
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 0.0, 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Text(
                                '${formatNumber(_likeCount, formatType: FormatType.compact)}${_likeCount == 1 ? ' like' : ' likes'}',
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
                      if ((widget.post?.numComments != 0) && _allowComments)
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
                                        snapshot.data!.length,
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
                      if (_allowComments)
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 8.0, 0.0, 0.0),
                          child: StreamBuilder<List<CommentsRecord>>(
                            stream: queryCommentsRecord(
                              parent: widget.post?.reference,
                              limit: 2,
                              descending: true,
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
                      if (_allowComments)
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 8.0, 0.0, 0.0),
                          child: InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              if (_allowComments) {
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
                                        'Comment here',
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
