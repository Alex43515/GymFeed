import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'profile_picture_model.dart';
export 'profile_picture_model.dart';

class ProfilePictureWidget extends StatefulWidget {
  const ProfilePictureWidget({super.key});

  static String routeName = 'ProfilePicture';
  static String routePath = 'profilePicture';

  @override
  State<ProfilePictureWidget> createState() => _ProfilePictureWidgetState();
}

class _ProfilePictureWidgetState extends State<ProfilePictureWidget> {
  late ProfilePictureModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProfilePictureModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final selectedMedia = await selectMediaWithSourceBottomSheet(
      context: context,
      imageQuality: 100,
      allowPhoto: true,
      includeBlurHash: true,
    );
    if (selectedMedia != null &&
        selectedMedia
            .every((m) => validateFileFormat(m.storagePath, context))) {
      final m = selectedMedia.first;
      // Account doesn't exist yet — hold the bytes; upload happens after
      // account creation (see all_done2 / create_account).
      FFAppState().signupProfileBytes = m.bytes;
      safeSetState(() {
        _model.uploadedLocalFile = FFUploadedFile(
          name: m.storagePath.split('/').last,
          bytes: m.bytes,
          height: m.dimensions?.height,
          width: m.dimensions?.width,
          blurHash: m.blurHash,
        );
        _model.uploadedFileUrl = 'selected';
      });
      FFAppState().update(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final theme = FlutterFlowTheme.of(context);
    final bool hasPhoto = _model.uploadedFileUrl.isNotEmpty &&
        (_model.uploadedLocalFile.bytes?.isNotEmpty ?? false);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.secondary,
        body: SafeArea(
          top: true,
          child: Padding(
            padding:
                const EdgeInsetsDirectional.fromSTEB(28.0, 24.0, 28.0, 28.0),
            child: Column(
              children: [
                const SizedBox(height: 24.0),
                Text(
                  'Add Your\nProfile picture',
                  textAlign: TextAlign.center,
                  style: theme.displaySmall.override(
                    fontFamily: 'Poppins',
                    color: theme.tertiary,
                    fontSize: 30.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w700,
                    lineHeight: 1.15,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Complete your details to proceed',
                  textAlign: TextAlign.center,
                  style: theme.bodyMedium.override(
                    fontFamily: 'Poppins',
                    color: theme.secondaryText,
                    fontSize: 16.0,
                    letterSpacing: 0.0,
                  ),
                ),
                const SizedBox(height: 48.0),
                // Avatar with green "+" badge.
                InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: _pickPhoto,
                  child: SizedBox(
                    width: 160.0,
                    height: 160.0,
                    child: Stack(
                      children: [
                        Container(
                          width: 160.0,
                          height: 160.0,
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: hasPhoto
                              ? Image.memory(
                                  _model.uploadedLocalFile.bytes!,
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        Positioned(
                          right: 6.0,
                          bottom: 6.0,
                          child: Container(
                            width: 46.0,
                            height: 46.0,
                            decoration: BoxDecoration(
                              color: theme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: theme.secondary, width: 3.0),
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              color: theme.secondary,
                              size: 26.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                _pageDots(theme, active: 0, count: 6),
                const SizedBox(height: 24.0),
                FFButtonWidget(
                  onPressed: () async {
                    context.pushNamed(Gender2Widget.routeName);
                  },
                  text: 'Next',
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 56.0,
                    padding: EdgeInsets.zero,
                    iconPadding: EdgeInsets.zero,
                    color: hasPhoto ? theme.primary : theme.accent3,
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
      ),
    );
  }

  Widget _pageDots(FlutterFlowTheme theme,
      {required int active, required int count}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3.0),
          width: 7.0,
          height: 7.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i == active ? theme.primary : theme.accent1,
          ),
        );
      }),
    );
  }
}
