import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'nav_bar_model.dart';
export 'nav_bar_model.dart';

class NavBarWidget extends StatefulWidget {
  const NavBarWidget({
    super.key,
    int? selectPageIndex,
    bool? hidden,
  })  : selectPageIndex = selectPageIndex ?? 1,
        hidden = hidden ?? false;

  final int selectPageIndex;
  final bool hidden;

  @override
  State<NavBarWidget> createState() => _NavBarWidgetState();
}

class _NavBarWidgetState extends State<NavBarWidget> {
  late NavBarModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NavBarModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const AlignmentDirectional(0.0, 1.0),
      child: Container(
        width: MediaQuery.sizeOf(context).width * 1.0,
        height: 60.0,
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            InkWell(
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () async {
                context.goNamed(
                  'Feed',
                  extra: <String, dynamic>{
                    kTransitionInfoKey: const TransitionInfo(
                      hasTransition: true,
                      transitionType: PageTransitionType.fade,
                      duration: Duration(milliseconds: 0),
                    ),
                  },
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  FlutterFlowIconButton(
                    borderColor: const Color(0xFF111111),
                    borderRadius: 20.0,
                    borderWidth: 0.0,
                    buttonSize: 40.0,
                    fillColor: FlutterFlowTheme.of(context).secondary,
                    icon: Icon(
                      FFIcons.kandroid144x144B,
                      color: widget.selectPageIndex == 1
                          ? FlutterFlowTheme.of(context).primary
                          : FlutterFlowTheme.of(context).tertiary,
                      size: 20.0,
                    ),
                    onPressed: () async {
                      context.goNamed(
                        'Feed',
                        extra: <String, dynamic>{
                          kTransitionInfoKey: const TransitionInfo(
                            hasTransition: true,
                            transitionType: PageTransitionType.fade,
                            duration: Duration(milliseconds: 0),
                          ),
                        },
                      );
                    },
                  ),
                  Text(
                    FFLocalizations.of(context).getText(
                      '5l5hq4lu' /* Home */,
                    ),
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Poppins',
                          color: widget.selectPageIndex == 1
                              ? FlutterFlowTheme.of(context).primary
                              : FlutterFlowTheme.of(context).tertiary,
                          fontSize: 8.0,
                          letterSpacing: 0.0,
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
                context.goNamed(
                  'ExplorePage',
                  extra: <String, dynamic>{
                    kTransitionInfoKey: const TransitionInfo(
                      hasTransition: true,
                      transitionType: PageTransitionType.fade,
                      duration: Duration(milliseconds: 0),
                    ),
                  },
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  FlutterFlowIconButton(
                    borderColor: const Color(0xFF111111),
                    borderRadius: 20.0,
                    borderWidth: 0.0,
                    buttonSize: 40.0,
                    fillColor: const Color(0xFF0A0A0A),
                    icon: Icon(
                      FFIcons.kandroid96x96B4,
                      color: widget.selectPageIndex == 2
                          ? FlutterFlowTheme.of(context).primary
                          : FlutterFlowTheme.of(context).tertiary,
                      size: 20.0,
                    ),
                    onPressed: () async {
                      context.pushNamed('ExplorePage');
                    },
                  ),
                  Text(
                    FFLocalizations.of(context).getText(
                      'x5pwi5zt' /* Explore */,
                    ),
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Poppins',
                          color: widget.selectPageIndex == 2
                              ? FlutterFlowTheme.of(context).primary
                              : FlutterFlowTheme.of(context).tertiary,
                          fontSize: 8.0,
                          letterSpacing: 0.0,
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
                context.goNamed(
                  'trainingHome',
                  extra: <String, dynamic>{
                    kTransitionInfoKey: const TransitionInfo(
                      hasTransition: true,
                      transitionType: PageTransitionType.fade,
                      duration: Duration(milliseconds: 0),
                    ),
                  },
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  FlutterFlowIconButton(
                    borderColor: const Color(0xFF111111),
                    borderRadius: 20.0,
                    borderWidth: 0.0,
                    buttonSize: 40.0,
                    fillColor: const Color(0xFF0A0A0A),
                    icon: Icon(
                      FFIcons.k07,
                      color: widget.selectPageIndex == 3
                          ? FlutterFlowTheme.of(context).primary
                          : FlutterFlowTheme.of(context).tertiary,
                      size: 20.0,
                    ),
                    onPressed: () async {
                      context.goNamed(
                        'trainingHome',
                        extra: <String, dynamic>{
                          kTransitionInfoKey: const TransitionInfo(
                            hasTransition: true,
                            transitionType: PageTransitionType.fade,
                            duration: Duration(milliseconds: 0),
                          ),
                        },
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(5.0, 0.0, 0.0, 0.0),
                    child: Text(
                      FFLocalizations.of(context).getText(
                        'r6zo6wta' /* GymFeed */,
                      ),
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Poppins',
                            color: widget.selectPageIndex == 3
                                ? FlutterFlowTheme.of(context).primary
                                : FlutterFlowTheme.of(context).tertiary,
                            fontSize: 8.0,
                            letterSpacing: 0.0,
                          ),
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
                context.pushNamed('videoReels');
              },
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  FlutterFlowIconButton(
                    borderColor: const Color(0xFF111111),
                    borderRadius: 20.0,
                    borderWidth: 0.0,
                    buttonSize: 40.0,
                    fillColor: const Color(0xFF0A0A0A),
                    icon: Icon(
                      FFIcons.kandroid96x96B111,
                      color: widget.selectPageIndex == 4
                          ? FlutterFlowTheme.of(context).primary
                          : FlutterFlowTheme.of(context).tertiary,
                      size: 20.0,
                    ),
                    onPressed: () async {
                      context.pushNamed('videoReels');
                    },
                  ),
                  Text(
                    FFLocalizations.of(context).getText(
                      'q6dytyut' /* FitClips */,
                    ),
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Poppins',
                          color: widget.selectPageIndex == 4
                              ? FlutterFlowTheme.of(context).primary
                              : FlutterFlowTheme.of(context).tertiary,
                          fontSize: 8.0,
                          letterSpacing: 0.0,
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
                context.goNamed(
                  'Profile',
                  extra: <String, dynamic>{
                    kTransitionInfoKey: const TransitionInfo(
                      hasTransition: true,
                      transitionType: PageTransitionType.fade,
                      duration: Duration(milliseconds: 0),
                    ),
                  },
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  FlutterFlowIconButton(
                    borderColor: const Color(0xFF111111),
                    borderRadius: 20.0,
                    borderWidth: 0.0,
                    buttonSize: 40.0,
                    fillColor: const Color(0xFF0A0A0A),
                    icon: FaIcon(
                      FontAwesomeIcons.user,
                      color: widget.selectPageIndex == 5
                          ? FlutterFlowTheme.of(context).primary
                          : FlutterFlowTheme.of(context).tertiary,
                      size: 20.0,
                    ),
                    onPressed: () async {
                      context.goNamed(
                        'Profile',
                        extra: <String, dynamic>{
                          kTransitionInfoKey: const TransitionInfo(
                            hasTransition: true,
                            transitionType: PageTransitionType.fade,
                            duration: Duration(milliseconds: 0),
                          ),
                        },
                      );
                    },
                  ),
                  Text(
                    FFLocalizations.of(context).getText(
                      'xoc4fmlt' /* Profile */,
                    ),
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Poppins',
                          color: widget.selectPageIndex == 5
                              ? FlutterFlowTheme.of(context).primary
                              : FlutterFlowTheme.of(context).tertiary,
                          fontSize: 8.0,
                          letterSpacing: 0.0,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
