import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/create/create_widget.dart';
import '/components/nav_bar/nav_bar_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/core_pages/story/story_widget.dart';
import '/pages/core_pages/story_upload/story_upload_widget.dart';
import '/pages/posts/post/post_widget.dart';
import '/pages/posts/post_food/post_food_widget.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import 'dart:async';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'feed_model.dart';
export 'feed_model.dart';

class FeedWidget extends StatefulWidget {
  const FeedWidget({
    super.key,
    this.indexNumberHimePage,
  });

  final bool? indexNumberHimePage;

  @override
  State<FeedWidget> createState() => _FeedWidgetState();
}

class _FeedWidgetState extends State<FeedWidget> {
  late FeedModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FeedModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (FFAppState().selectedLanguage == false) {
        setAppLanguage(context, 'en');
      } else {
        setAppLanguage(context, 'sr');
      }
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
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        floatingActionButton: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 90.0),
          child: FloatingActionButton(
            onPressed: () async {
              await showModalBottomSheet(
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                enableDrag: false,
                context: context,
                builder: (context) {
                  return GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: Padding(
                      padding: MediaQuery.viewInsetsOf(context),
                      child: SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.5,
                        child: const CreateWidget(),
                      ),
                    ),
                  );
                },
              ).then((value) => safeSetState(() {}));
            },
            backgroundColor: FlutterFlowTheme.of(context).primary,
            elevation: 8.0,
            child: Icon(
              Icons.add,
              color: FlutterFlowTheme.of(context).secondary,
              size: 40.0,
            ),
          ),
        ),
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 10.0),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      height: MediaQuery.sizeOf(context).height * 0.1,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).tertiary,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20.0),
                          bottomRight: Radius.circular(20.0),
                          topLeft: Radius.circular(0.0),
                          topRight: Radius.circular(0.0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                10.0, 0.0, 0.0, 10.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(13.0),
                                      child: Image.asset(
                                        'assets/images/014.png',
                                        width: valueOrDefault<double>(
                                          () {
                                            if (MediaQuery.sizeOf(context)
                                                    .width <
                                                kBreakpointSmall) {
                                              return 35.0;
                                            } else if (MediaQuery.sizeOf(
                                                        context)
                                                    .width <
                                                kBreakpointMedium) {
                                              return 45.0;
                                            } else if (MediaQuery.sizeOf(
                                                        context)
                                                    .width <
                                                kBreakpointLarge) {
                                              return 55.0;
                                            } else {
                                              return 65.0;
                                            }
                                          }(),
                                          35.0,
                                        ),
                                        height: valueOrDefault<double>(
                                          () {
                                            if (MediaQuery.sizeOf(context)
                                                    .width <
                                                kBreakpointSmall) {
                                              return 35.0;
                                            } else if (MediaQuery.sizeOf(
                                                        context)
                                                    .width <
                                                kBreakpointMedium) {
                                              return 45.0;
                                            } else if (MediaQuery.sizeOf(
                                                        context)
                                                    .width <
                                                kBreakpointLarge) {
                                              return 55.0;
                                            } else {
                                              return 65.0;
                                            }
                                          }(),
                                          35.0,
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsetsDirectional.fromSTEB(
                                          5.0, 0.0, 0.0, 0.0),
                                      child: Text(
                                        FFLocalizations.of(context).getText(
                                          '8hvfxm0f' /* GymFeed */,
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'Poppins',
                                              color: const Color(0xFF0A0A0A),
                                              fontSize: functions
                                                  .resizeFontBasedOnScreenSize(
                                                      MediaQuery.sizeOf(context)
                                                          .width,
                                                      20)
                                                  .toDouble(),
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 10.0, 10.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 15.0, 0.0),
                                      child: Stack(
                                        children: [
                                          AuthUserStreamWidget(
                                            builder: (context) => InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                context
                                                    .pushNamed('Notifications');
                                              },
                                              child: badges.Badge(
                                                badgeContent: Text(
                                                  FFLocalizations.of(context)
                                                      .getText(
                                                    'rcya004l' /*  */,
                                                  ),
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .titleSmall
                                                      .override(
                                                        fontFamily: 'Poppins',
                                                        color: Colors.white,
                                                        fontSize: 12.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                showBadge: (currentUserDocument
                                                                ?.unreadNotifications
                                                                .toList() ??
                                                            []).isNotEmpty,
                                                shape: badges.BadgeShape.circle,
                                                badgeColor: const Color(0xFF5EE543),
                                                elevation: 4.0,
                                                padding: const EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        8.0, 8.0, 8.0, 8.0),
                                                position: badges.BadgePosition
                                                    .topEnd(),
                                                animationType: badges
                                                    .BadgeAnimationType.scale,
                                                toAnimate: true,
                                                child: FlutterFlowIconButton(
                                                  borderColor:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .secondary,
                                                  borderRadius: 10.0,
                                                  borderWidth: 1.0,
                                                  buttonSize: 30.0,
                                                  fillColor:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .secondary,
                                                  icon: FaIcon(
                                                    FontAwesomeIcons.solidBell,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .tertiary,
                                                    size: 15.0,
                                                  ),
                                                  onPressed: () async {
                                                    context.pushNamed(
                                                        'Notifications');
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    StreamBuilder<List<ChatsRecord>>(
                                      stream: queryChatsRecord(
                                        singleRecord: true,
                                      ),
                                      builder: (context, snapshot) {
                                        // Customize what your widget looks like when it's loading.
                                        if (!snapshot.hasData) {
                                          return const Center(
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
                                        List<ChatsRecord> stackChatsRecordList =
                                            snapshot.data!;
                                        final stackChatsRecord =
                                            stackChatsRecordList.isNotEmpty
                                                ? stackChatsRecordList.first
                                                : null;

                                        return Stack(
                                          children: [
                                            badges.Badge(
                                              badgeContent: Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'nbpjjjx7' /*  */,
                                                ),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .override(
                                                          fontFamily: 'Poppins',
                                                          color: Colors.white,
                                                          fontSize: 12.0,
                                                          letterSpacing: 0.0,
                                                        ),
                                              ),
                                              showBadge: !stackChatsRecord!
                                                  .lastMessageSeenBy
                                                  .contains(
                                                      currentUserReference),
                                              shape: badges.BadgeShape.circle,
                                              badgeColor:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              elevation: 4.0,
                                              padding: const EdgeInsetsDirectional
                                                  .fromSTEB(8.0, 8.0, 8.0, 8.0),
                                              position:
                                                  badges.BadgePosition.topEnd(),
                                              animationType: badges
                                                  .BadgeAnimationType.scale,
                                              toAnimate: true,
                                              child: FlutterFlowIconButton(
                                                borderColor: const Color(0xFF0A0A0A),
                                                borderRadius: 10.0,
                                                borderWidth: 1.0,
                                                buttonSize: 30.0,
                                                fillColor: const Color(0xFF0A0A0A),
                                                icon: Icon(
                                                  FFIcons.kandroid96x96B,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primary,
                                                  size: 15.0,
                                                ),
                                                onPressed: () async {
                                                  context.pushNamed('Messages');
                                                },
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                      ),
                      child: RefreshIndicator(
                        onRefresh: () async {},
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsetsDirectional.fromSTEB(
                                          15.0, 0.0, 0.0, 0.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          StreamBuilder<List<StoriesRecord>>(
                                            stream: queryStoriesRecord(
                                              queryBuilder: (storiesRecord) =>
                                                  storiesRecord
                                                      .where(
                                                        'expire_time',
                                                        isGreaterThanOrEqualTo:
                                                            getCurrentTimestamp,
                                                      )
                                                      .where(
                                                        'user',
                                                        isEqualTo:
                                                            currentUserReference,
                                                      )
                                                      .orderBy('expire_time',
                                                          descending: true),
                                              singleRecord: true,
                                            ),
                                            builder: (context, snapshot) {
                                              // Customize what your widget looks like when it's loading.
                                              if (!snapshot.hasData) {
                                                return const Center(
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
                                                  stackStoriesRecordList =
                                                  snapshot.data!;
                                              final stackStoriesRecord =
                                                  stackStoriesRecordList
                                                          .isNotEmpty
                                                      ? stackStoriesRecordList
                                                          .first
                                                      : null;

                                              return Stack(
                                                children: [
                                                  if (!(stackStoriesRecord !=
                                                      null))
                                                    InkWell(
                                                      splashColor:
                                                          Colors.transparent,
                                                      focusColor:
                                                          Colors.transparent,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      onTap: () async {
                                                        await showModalBottomSheet(
                                                          isScrollControlled:
                                                              true,
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                          context: context,
                                                          builder: (context) {
                                                            return GestureDetector(
                                                              onTap: () =>
                                                                  FocusScope.of(
                                                                          context)
                                                                      .unfocus(),
                                                              child: Padding(
                                                                padding: MediaQuery
                                                                    .viewInsetsOf(
                                                                        context),
                                                                child:
                                                                    SizedBox(
                                                                  height: MediaQuery.sizeOf(
                                                                              context)
                                                                          .height *
                                                                      0.4,
                                                                  child:
                                                                      const StoryUploadWidget(),
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ).then((value) =>
                                                            safeSetState(
                                                                () {}));
                                                      },
                                                      child: Stack(
                                                        alignment:
                                                            const AlignmentDirectional(
                                                                1.2, 1.2),
                                                        children: [
                                                          AuthUserStreamWidget(
                                                            builder:
                                                                (context) =>
                                                                    Container(
                                                              width: 60.0,
                                                              height: 60.0,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryBackground,
                                                                image:
                                                                    DecorationImage(
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  image: Image
                                                                      .network(
                                                                    functions.twicPicImagePath(
                                                                        valueOrDefault<String>(
                                                                          currentUserPhoto,
                                                                          'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                        ),
                                                                        '?alt=media&twic=v1/resize=100/cover=1:1'),
                                                                  ).image,
                                                                ),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                            ),
                                                          ),
                                                          Container(
                                                            width: 30.0,
                                                            height: 30.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .secondary,
                                                              shape: BoxShape
                                                                  .circle,
                                                              border:
                                                                  Border.all(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryBackground,
                                                                width: 3.0,
                                                              ),
                                                            ),
                                                            child: const Icon(
                                                              Icons.add_rounded,
                                                              color:
                                                                  Colors.white,
                                                              size: 16.0,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  if (stackStoriesRecord !=
                                                      null)
                                                    Container(
                                                      width: 65.0,
                                                      height: 65.0,
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          colors: [
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primary,
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primary,
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primary
                                                          ],
                                                          stops: const [
                                                            0.0,
                                                            0.5,
                                                            1.0
                                                          ],
                                                          begin:
                                                              const AlignmentDirectional(
                                                                  1.0, -1.0),
                                                          end:
                                                              const AlignmentDirectional(
                                                                  -1.0, 1.0),
                                                        ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Align(
                                                        alignment:
                                                            const AlignmentDirectional(
                                                                0.0, 0.0),
                                                        child:
                                                            AuthUserStreamWidget(
                                                          builder: (context) =>
                                                              InkWell(
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
                                                              showModalBottomSheet(
                                                                isScrollControlled:
                                                                    true,
                                                                backgroundColor:
                                                                    Colors
                                                                        .transparent,
                                                                barrierColor: const Color(
                                                                    0x00000000),
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return GestureDetector(
                                                                    onTap: () =>
                                                                        FocusScope.of(context)
                                                                            .unfocus(),
                                                                    child:
                                                                        Padding(
                                                                      padding: MediaQuery
                                                                          .viewInsetsOf(
                                                                              context),
                                                                      child:
                                                                          StoryWidget(
                                                                        story:
                                                                            stackStoriesRecord,
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                              ).then((value) =>
                                                                  safeSetState(
                                                                      () {}));

                                                              await Future.delayed(
                                                                  const Duration(
                                                                      milliseconds:
                                                                          5000));
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Container(
                                                              width: 60.0,
                                                              height: 60.0,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryBackground,
                                                                image:
                                                                    DecorationImage(
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  image: Image
                                                                      .network(
                                                                    functions.twicPicImagePath(
                                                                        valueOrDefault<String>(
                                                                          currentUserPhoto,
                                                                          'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                        ),
                                                                        '?alt=media&twic=v1/resize=100/cover=1:1'),
                                                                  ).image,
                                                                ),
                                                                shape: BoxShape
                                                                    .circle,
                                                                border:
                                                                    Border.all(
                                                                  color: Colors
                                                                      .white,
                                                                  width: 2.0,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              );
                                            },
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 13.0, 0.0, 0.0),
                                            child: Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                'ri7h4z57' /* Your gym day */,
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Poppins',
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .tertiary,
                                                        fontSize: 10.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsetsDirectional.fromSTEB(
                                          15.0, 0.0, 0.0, 0.0),
                                      child: AuthUserStreamWidget(
                                        builder: (context) =>
                                            StreamBuilder<List<StoriesRecord>>(
                                          stream: queryStoriesRecord(
                                            queryBuilder: (storiesRecord) =>
                                                storiesRecord
                                                    .where(
                                                      'expire_time',
                                                      isGreaterThanOrEqualTo:
                                                          getCurrentTimestamp,
                                                    )
                                                    .whereIn(
                                                        'user',
                                                        (currentUserDocument
                                                                ?.following
                                                                .toList() ??
                                                            []))
                                                    .orderBy('expire_time'),
                                          ),
                                          builder: (context, snapshot) {
                                            // Customize what your widget looks like when it's loading.
                                            if (!snapshot.hasData) {
                                              return const Center(
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
                                                userStoriesStoriesRecordList =
                                                snapshot.data!;

                                            return Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: List.generate(
                                                  userStoriesStoriesRecordList
                                                      .length,
                                                  (userStoriesIndex) {
                                                final userStoriesStoriesRecord =
                                                    userStoriesStoriesRecordList[
                                                        userStoriesIndex];
                                                return Visibility(
                                                  visible:
                                                      userStoriesStoriesRecord
                                                              .user !=
                                                          currentUserReference,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 0.0,
                                                                15.0, 0.0),
                                                    child: FutureBuilder<
                                                        UsersRecord>(
                                                      future: UsersRecord
                                                          .getDocumentOnce(
                                                              userStoriesStoriesRecord
                                                                  .user!),
                                                      builder:
                                                          (context, snapshot) {
                                                        // Customize what your widget looks like when it's loading.
                                                        if (!snapshot.hasData) {
                                                          return const Center(
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

                                                        final columnUsersRecord =
                                                            snapshot.data!;

                                                        return InkWell(
                                                          splashColor: Colors
                                                              .transparent,
                                                          focusColor: Colors
                                                              .transparent,
                                                          hoverColor: Colors
                                                              .transparent,
                                                          highlightColor: Colors
                                                              .transparent,
                                                          onTap: () async {
                                                            showModalBottomSheet(
                                                              isScrollControlled:
                                                                  true,
                                                              backgroundColor:
                                                                  Colors
                                                                      .transparent,
                                                              barrierColor: const Color(
                                                                  0x00000000),
                                                              context: context,
                                                              builder:
                                                                  (context) {
                                                                return GestureDetector(
                                                                  onTap: () =>
                                                                      FocusScope.of(
                                                                              context)
                                                                          .unfocus(),
                                                                  child:
                                                                      Padding(
                                                                    padding: MediaQuery
                                                                        .viewInsetsOf(
                                                                            context),
                                                                    child:
                                                                        StoryWidget(
                                                                      story:
                                                                          userStoriesStoriesRecord,
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ).then((value) =>
                                                                safeSetState(
                                                                    () {}));

                                                            if (!userStoriesStoriesRecord
                                                                .views
                                                                .contains(
                                                                    currentUserReference)) {
                                                              await userStoriesStoriesRecord
                                                                  .reference
                                                                  .update({
                                                                ...mapToFirestore(
                                                                  {
                                                                    'views':
                                                                        FieldValue
                                                                            .arrayUnion([
                                                                      currentUserReference
                                                                    ]),
                                                                  },
                                                                ),
                                                              });
                                                            }
                                                            await Future.delayed(
                                                                const Duration(
                                                                    milliseconds:
                                                                        5000));
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            children: [
                                                              Container(
                                                                width: 65.0,
                                                                height: 65.0,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  gradient:
                                                                      LinearGradient(
                                                                    colors: [
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .primary,
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .primary,
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .primary
                                                                    ],
                                                                    stops: const [
                                                                      0.0,
                                                                      0.5,
                                                                      1.0
                                                                    ],
                                                                    begin:
                                                                        const AlignmentDirectional(
                                                                            1.0,
                                                                            -1.0),
                                                                    end: const AlignmentDirectional(
                                                                        -1.0,
                                                                        1.0),
                                                                  ),
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                                child:
                                                                    Container(
                                                                  width: 65.0,
                                                                  height: 65.0,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: userStoriesStoriesRecord
                                                                            .views
                                                                            .contains(
                                                                                currentUserReference)
                                                                        ? const Color(
                                                                            0xFFDADADA)
                                                                        : const Color(
                                                                            0x00999999),
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                                  child: Align(
                                                                    alignment:
                                                                        const AlignmentDirectional(
                                                                            0.0,
                                                                            0.0),
                                                                    child:
                                                                        Container(
                                                                      width:
                                                                          60.0,
                                                                      height:
                                                                          60.0,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondaryBackground,
                                                                        image:
                                                                            DecorationImage(
                                                                          fit: BoxFit
                                                                              .cover,
                                                                          image:
                                                                              Image.network(
                                                                            functions.twicPicImagePath(
                                                                                valueOrDefault<String>(
                                                                                  columnUsersRecord.photoUrl,
                                                                                  'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                                                                                ),
                                                                                '?alt=media&twic=v1/resize=100/cover=1:1'),
                                                                          ).image,
                                                                        ),
                                                                        shape: BoxShape
                                                                            .circle,
                                                                        border:
                                                                            Border.all(
                                                                          color:
                                                                              Colors.white,
                                                                          width:
                                                                              2.0,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            8.0,
                                                                            0.0,
                                                                            0.0),
                                                                child: Text(
                                                                  valueOrDefault<
                                                                      String>(
                                                                    columnUsersRecord
                                                                        .username,
                                                                    'user',
                                                                  ),
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        fontFamily:
                                                                            'Poppins',
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .tertiary,
                                                                        fontSize:
                                                                            12.0,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.normal,
                                                                      ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                );
                                              }),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0.0, 10.0, 0.0, 10.0),
                                child: Container(
                                  width: double.infinity,
                                  height: 0.5,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDADADA),
                                  ),
                                ),
                              ),
                              AuthUserStreamWidget(
                                builder: (context) =>
                                    FutureBuilder<List<PostsRecord>>(
                                  future: (_model.firestoreRequestCompleter ??=
                                          Completer<List<PostsRecord>>()
                                            ..complete(queryPostsRecordOnce(
                                              queryBuilder: (postsRecord) =>
                                                  postsRecord
                                                      .where(
                                                        'deleted',
                                                        isEqualTo: false,
                                                      )
                                                      .whereIn(
                                                          'post_user',
                                                          (currentUserDocument
                                                                  ?.following
                                                                  .toList() ??
                                                              []))
                                                      .orderBy('time_posted',
                                                          descending: true),
                                            )))
                                      .future,
                                  builder: (context, snapshot) {
                                    // Customize what your widget looks like when it's loading.
                                    if (!snapshot.hasData) {
                                      return const Center(
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
                                    List<PostsRecord> postFeedPostsRecordList =
                                        snapshot.data!;

                                    return RefreshIndicator(
                                      onRefresh: () async {
                                        safeSetState(() => _model
                                            .firestoreRequestCompleter = null);
                                        await _model
                                            .waitForFirestoreRequestCompleted();
                                      },
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        primary: false,
                                        shrinkWrap: true,
                                        scrollDirection: Axis.vertical,
                                        itemCount:
                                            postFeedPostsRecordList.length,
                                        itemBuilder: (context, postFeedIndex) {
                                          final postFeedPostsRecord =
                                              postFeedPostsRecordList[
                                                  postFeedIndex];
                                          return Padding(
                                            padding:
                                                const EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 0.0, 0.0, 50.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Container(
                                                  width:
                                                      MediaQuery.sizeOf(context)
                                                              .width *
                                                          1.0,
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryBackground,
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      if (postFeedPostsRecord
                                                              .foodPost ==
                                                          false)
                                                        SizedBox(
                                                          width:
                                                              MediaQuery.sizeOf(
                                                                          context)
                                                                      .width *
                                                                  1.0,
                                                          child: PostWidget(
                                                            key: Key(
                                                                'Key4ju_${postFeedIndex}_of_${postFeedPostsRecordList.length}'),
                                                            post:
                                                                postFeedPostsRecord,
                                                            detailsPage: true,
                                                          ),
                                                        ),
                                                      if (postFeedPostsRecord
                                                              .foodPost ==
                                                          true)
                                                        Container(
                                                          width:
                                                              MediaQuery.sizeOf(
                                                                          context)
                                                                      .width *
                                                                  1.0,
                                                          decoration:
                                                              const BoxDecoration(),
                                                          child: SizedBox(
                                                            width: MediaQuery
                                                                        .sizeOf(
                                                                            context)
                                                                    .width *
                                                                1.0,
                                                            child:
                                                                PostFoodWidget(
                                                              key: Key(
                                                                  'Keyc98_${postFeedIndex}_of_${postFeedPostsRecordList.length}'),
                                                              postFood:
                                                                  postFeedPostsRecord,
                                                              isHomePage: true,
                                                            ),
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
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              wrapWithModel(
                model: _model.navBarModel,
                updateCallback: () => safeSetState(() {}),
                child: const NavBarWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
