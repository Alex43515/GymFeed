import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'all_most_done_model.dart';
export 'all_most_done_model.dart';

class AllMostDoneWidget extends StatefulWidget {
  const AllMostDoneWidget({super.key});

  static String routeName = 'AllMostDone';
  static String routePath = 'allMostDone';

  @override
  State<AllMostDoneWidget> createState() => _AllMostDoneWidgetState();
}

class _AllMostDoneWidgetState extends State<AllMostDoneWidget> {
  late AllMostDoneModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AllMostDoneModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.secondary,
      body: SafeArea(
        top: true,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(28.0, 40.0, 28.0, 28.0),
          child: Column(
            children: [
              const SizedBox(height: 40.0),
              Text(
                'Nice one!',
                textAlign: TextAlign.center,
                style: theme.displaySmall.override(
                  fontFamily: 'Poppins',
                  color: theme.tertiary,
                  fontSize: 32.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Few more steps!',
                textAlign: TextAlign.center,
                style: theme.displaySmall.override(
                  fontFamily: 'Poppins',
                  color: theme.tertiary,
                  fontSize: 32.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10.0),
              Text(
                'Continue with creating your new profile',
                textAlign: TextAlign.center,
                style: theme.bodyMedium.override(
                  fontFamily: 'Poppins',
                  color: theme.secondaryText,
                  fontSize: 16.0,
                  letterSpacing: 0.0,
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: 180.0,
                    height: 180.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.primary, width: 7.0),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: theme.primary,
                      size: 96.0,
                    ),
                  ),
                ),
              ),
              FFButtonWidget(
                onPressed: () async {
                  context.pushNamed(ProfilePictureWidget.routeName);
                },
                text: 'Continue',
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 56.0,
                  padding: EdgeInsets.zero,
                  iconPadding: EdgeInsets.zero,
                  color: theme.primary,
                  textStyle: theme.titleSmall.override(
                    fontFamily: 'Poppins',
                    color: theme.secondary,
                    fontSize: 17.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                  ),
                  elevation: 0.0,
                  borderSide:
                      const BorderSide(color: Colors.transparent, width: 1.0),
                  borderRadius: BorderRadius.circular(28.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
