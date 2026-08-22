import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/upload_progress_screen.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import 'package:flutter/material.dart';
import 'video_compress_copy_model.dart';
export 'video_compress_copy_model.dart';

class VideoCompressCopyWidget extends StatefulWidget {
  const VideoCompressCopyWidget({super.key});

  static String routeName = 'videoCompressCopy';
  static String routePath = 'videoCompressCopy';

  @override
  State<VideoCompressCopyWidget> createState() =>
      _VideoCompressCopyWidgetState();
}

class _VideoCompressCopyWidgetState extends State<VideoCompressCopyWidget> {
  late VideoCompressCopyModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VideoCompressCopyModel());

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
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          title: InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () async {
              context.safePop();
            },
            child: Text(
              FFLocalizations.of(context).getText(
                'ymrg9ucb' /* Page Title */,
              ),
              style: FlutterFlowTheme.of(context).headlineMedium.override(
                    fontFamily: 'Poppins',
                    color: Colors.black,
                    fontSize: 22.0,
                    letterSpacing: 0.0,
                  ),
            ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FFButtonWidget(
                onPressed: () async {
                  final selectedMedia = await selectMediaWithSourceBottomSheet(
                    context: context,
                    allowPhoto: false,
                    allowVideo: true,
                  );
                  if (selectedMedia != null && selectedMedia.isNotEmpty) {
                    final selected = selectedMedia.first;
                    if (!validateFileFormat(selected.storagePath, context) ||
                        selected.filePath == null) {
                      return;
                    }
                    safeSetState(() => _model.isDataUploading = true);
                    try {
                      showUploadMessage(
                        context,
                        'Compressing video...',
                        showLoading: true,
                      );
                      final compressed =
                          await actions.compressVideo(selected.filePath!);
                      if (compressed?.bytes == null ||
                          compressed!.bytes!.isEmpty) {
                        throw StateError('Video compression failed.');
                      }
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      final upload = await showUploadProgress(
                        context,
                        videoBytes: compressed.bytes!,
                        videoTitle: 'GymFeed video',
                      );
                      final url = upload?.videoPlaylistUrl;
                      if (url == null || url.isEmpty) {
                        throw StateError('Video upload failed.');
                      }
                      safeSetState(() {
                        _model.uploadedLocalFile = compressed;
                        _model.uploadedFileUrl = url;
                      });
                      showUploadMessage(context, 'Success!');
                    } catch (error) {
                      if (context.mounted) {
                        showUploadMessage(context, 'Failed to upload video');
                      }
                    } finally {
                      _model.isDataUploading = false;
                    }
                  }
                },
                text: FFLocalizations.of(context).getText(
                  '87nam5hv' /* Button */,
                ),
                options: FFButtonOptions(
                  height: 40.0,
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                  iconPadding:
                      EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                  color: FlutterFlowTheme.of(context).primary,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        letterSpacing: 0.0,
                      ),
                  elevation: 0.0,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
