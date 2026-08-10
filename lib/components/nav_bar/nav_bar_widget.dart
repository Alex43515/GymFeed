import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'nav_bar_model.dart';
export 'nav_bar_model.dart';

class NavBarWidget extends StatefulWidget {
  const NavBarWidget({
    super.key,
    int? selectPageIndex,
    bool? hidden,
  })  : this.selectPageIndex = selectPageIndex ?? 1,
        this.hidden = hidden ?? false;

  final int selectPageIndex;
  final bool hidden;

  @override
  State<NavBarWidget> createState() => _NavBarWidgetState();
}

class _NavBarWidgetState extends State<NavBarWidget> {
  late NavBarModel _model;

  // Muted grey for inactive tabs (matches the GymFeed nav design).
  static const Color _inactive = Color(0xFF6E6E6E);

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

  void _go(String routeName) {
    context.goNamed(
      routeName,
      extra: <String, dynamic>{
        kTransitionInfoKey: TransitionInfo(
          hasTransition: true,
          transitionType: PageTransitionType.fade,
          duration: const Duration(milliseconds: 0),
        ),
      },
    );
  }

  Widget _tab({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final color = active ? FlutterFlowTheme.of(context).primary : _inactive;
    return Expanded(
      child: InkWell(
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24.0),
            const SizedBox(height: 4.0),
            Text(
              label,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Poppins',
                    color: color,
                    fontSize: 10.0,
                    letterSpacing: 0.0,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centerTab({required bool active, required VoidCallback onTap}) {
    final theme = FlutterFlowTheme.of(context);
    return Expanded(
      child: InkWell(
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40.0,
              height: 40.0,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.primary.withOpacity(0.35),
                    blurRadius: 12.0,
                    spreadRadius: 1.0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF0A0A0A),
                size: 22.0,
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              'Coach',
              style: theme.bodyMedium.override(
                    fontFamily: 'Poppins',
                    color: active ? theme.primary : _inactive,
                    fontSize: 10.0,
                    letterSpacing: 0.0,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const AlignmentDirectional(0.0, 1.0),
      child: Container(
        width: MediaQuery.sizeOf(context).width * 1.0,
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A),
          border: Border(
            top: BorderSide(color: Color(0xFF1A1A1A), width: 1.0),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62.0,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4.0, 0.0, 4.0, 0.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                _tab(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  active: widget.selectPageIndex == 1,
                  onTap: () => _go(FeedWidget.routeName),
                ),
                _tab(
                  icon: Icons.grid_view_rounded,
                  label: 'Explore',
                  active: widget.selectPageIndex == 2,
                  onTap: () => _go(ExplorePageWidget.routeName),
                ),
                _centerTab(
                  active: widget.selectPageIndex == 3,
                  onTap: () => _go(TrainingHomeWidget.routeName),
                ),
                _tab(
                  icon: Icons.emergency_rounded,
                  label: 'FitClips',
                  active: widget.selectPageIndex == 4,
                  onTap: () =>
                      context.pushNamed(VideoReelsWidget.routeName),
                ),
                _tab(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  active: widget.selectPageIndex == 5,
                  onTap: () => _go(ProfileWidget.routeName),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
