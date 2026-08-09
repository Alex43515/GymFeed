import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_place_picker.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import '/custom_code/widgets/create_ui.dart';
import '/custom_code/widgets/upload_progress_screen.dart';
import '/backend/supabase/repositories/post_repository.dart';
import 'dart:async';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'new_post_model.dart';
export 'new_post_model.dart';

class NewPostWidget extends StatefulWidget {
  const NewPostWidget({super.key});

  static String routeName = 'NewPost';
  static String routePath = 'newPost';

  @override
  State<NewPostWidget> createState() => _NewPostWidgetState();
}

class _NewPostWidgetState extends State<NewPostWidget>
    with TickerProviderStateMixin {
  late NewPostModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  late StreamSubscription<bool> _keyboardVisibilitySubscription;
  bool _isKeyboardVisible = false;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NewPostModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.apiResulto66 = await ImageTestCall.call(
        image: FFAppState().uploadPhoto,
      );

      if ((_model.apiResulto66?.succeeded ?? true)) {
        FFAppState().imageLabels = functions.listToString(ImageTestCall.labels(
          (_model.apiResulto66?.jsonBody ?? ''),
        )?.toList());
        FFAppState().update(() {});
      }
    });

    if (!isWeb) {
      _keyboardVisibilitySubscription =
          KeyboardVisibilityController().onChange.listen((bool visible) {
        safeSetState(() {
          _isKeyboardVisible = visible;
        });
      });
    }

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    _model.switchValue1 = false;
    _model.switchValue2 = false;
    animationsMap.addAll({
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 1.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 200.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    if (!isWeb) {
      _keyboardVisibilitySubscription.cancel();
    }
    super.dispose();
  }

  // ── Media preview shown beside the caption ─────────────────────────────────
  Widget _captionMediaThumb() {
    final theme = FlutterFlowTheme.of(context);
    final hasPhoto = FFAppState().uploadPhoto != '';
    final hasVideo = FFAppState().uploadVideo != '';
    Widget inner;
    if (hasPhoto) {
      inner = Image.network(
        FFAppState().uploadPhoto,
        width: 64.0,
        height: 64.0,
        fit: BoxFit.cover,
      );
    } else if (hasVideo) {
      inner = Container(
        width: 64.0,
        height: 64.0,
        color: kCreateSurfaceAlt,
        alignment: Alignment.center,
        child: Icon(Icons.play_circle_fill_rounded,
            color: theme.primary, size: 26.0),
      );
    } else {
      inner = Container(
        width: 64.0,
        height: 64.0,
        color: kCreateSurfaceAlt,
        alignment: Alignment.center,
        child: Icon(Icons.image_outlined, color: kCreateHint, size: 24.0),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: SizedBox(width: 64.0, height: 64.0, child: inner),
    );
  }

  // ── Location row (uses the Google place picker, styled as a card row) ───────
  Widget _locationRow() {
    final theme = FlutterFlowTheme.of(context);
    final addr = _model.placePickerValue.address;
    final hasAddr = addr.isNotEmpty;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 6.0, 6.0, 6.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Location',
                  style: theme.bodyMedium.override(
                    fontFamily: 'Poppins',
                    fontSize: 14.5,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (hasAddr)
                  Padding(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(0.0, 3.0, 0.0, 0.0),
                    child: Text(
                      addr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodySmall.override(
                        fontFamily: 'Poppins',
                        color: kCreateHint,
                        fontSize: 12.5,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          FlutterFlowPlacePicker(
            iOSGoogleMapsApiKey: 'AIzaSyAhiNjvBpWvH1VVuoRGU5J3WnjVPFIzkE4',
            androidGoogleMapsApiKey: 'AIzaSyD60h9pruOAaVuyPzjCD5Cg3fxemawEUpg',
            webGoogleMapsApiKey: 'AIzaSyBaAKbRwjQpBxUxfa46HZYGwxPTwpXqy4g',
            onSelect: (place) async {
              safeSetState(() => _model.placePickerValue = place);
            },
            defaultText: hasAddr ? 'Change' : 'Add',
            icon: Icon(Icons.place, color: theme.primary, size: 16.0),
            buttonOptions: FFButtonOptions(
              height: 38.0,
              padding:
                  const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
              color: Colors.transparent,
              textStyle: theme.titleSmall.override(
                fontFamily: 'Poppins',
                color: theme.primary,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w600,
              ),
              elevation: 0.0,
              borderSide: const BorderSide(color: Colors.transparent, width: 1.0),
              borderRadius: BorderRadius.circular(19.0),
            ),
          ),
        ],
      ),
    );
  }

  // ── Add-media tiles ────────────────────────────────────────────────────────
  Widget _mediaTileShell({
    required IconData icon,
    required String label,
    required bool selected,
    required Future<void> Function() onTap,
    VoidCallback? onRemove,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(kCreateFieldRadius),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () async => onTap(),
      child: Container(
        height: 60.0,
        decoration: BoxDecoration(
          color: kCreateSurface,
          borderRadius: BorderRadius.circular(kCreateFieldRadius),
          border: Border.all(
            color: selected ? theme.primary : kCreateStroke,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? Icons.check_circle_rounded : icon,
                    color: theme.primary,
                    size: 20.0,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    label,
                    style: theme.bodyMedium.override(
                      fontFamily: 'Poppins',
                      color: theme.tertiary,
                      fontSize: 14.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onRemove != null)
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: onRemove,
                    child: Icon(Icons.close_rounded,
                        color: theme.error, size: 16.0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _imageTile() {
    final selected = _model.uploadedFileUrl1 != '';
    return _mediaTileShell(
      icon: Icons.image_outlined,
      label: selected ? 'Change image' : 'Image',
      selected: selected,
      onTap: () async {
        _model.pickedImage = await actions.pickImage();
        if (_model.pickedImage == null) {
          return;
        }
        _model.compressImage = await actions.compressImage(_model.pickedImage!);
        // Custom upload progress screen — uploads the photo to Supabase
        // Storage and shows live progress.
        final uploadRes = await showUploadProgress(
          context,
          imageBytes: _model.compressImage!.bytes!,
          imageFileName: 'photo.jpg',
        );
        if (uploadRes?.imageUrl != null) {
          safeSetState(() {
            _model.uploadedLocalFile1 = _model.compressImage!;
            _model.uploadedFileUrl1 = uploadRes!.imageUrl!;
          });
        } else {
          return;
        }
        if (_model.uploadedFileUrl1 != '') {
          FFAppState().uploadPhoto = _model.uploadedFileUrl1;
          safeSetState(() {});
        }
      },
      onRemove: selected
          ? () {
              safeSetState(() {
                _model.isDataUploading1 = false;
                _model.uploadedLocalFile1 =
                    FFUploadedFile(bytes: Uint8List.fromList([]));
                _model.uploadedFileUrl1 = '';
              });
              FFAppState().uploadPhoto = '';
              safeSetState(() {});
            }
          : null,
    );
  }

  Widget _videoTile() {
    final selected = _model.uploadedFileUrl2 != '';
    return _mediaTileShell(
      icon: Icons.videocam_outlined,
      label: selected ? 'Change video' : 'Video',
      selected: selected,
      onTap: () async {
        _model.pickVideo = await actions.pickVideo();
        if (_model.pickVideo == null) {
          return;
        }
        _model.compressVideo = await actions.compressVideo(_model.pickVideo!);
        _model.previewVideo =
            await actions.generate2SecondVideoPreview(_model.compressVideo!);
        // Custom upload progress screen — pushes the video to Bunny Stream
        // (TUS) and stores its HLS URL.
        final uploadRes = await showUploadProgress(
          context,
          videoBytes: _model.compressVideo!.bytes!,
          videoTitle: 'GymFeed video',
        );
        if (uploadRes?.videoPlaylistUrl != null) {
          safeSetState(() {
            _model.uploadedLocalFile2 = _model.compressVideo!;
            _model.uploadedFileUrl2 = uploadRes!.videoPlaylistUrl!;
          });
        } else {
          return;
        }
        if (_model.uploadedFileUrl2 != '') {
          FFAppState().uploadVideo = _model.uploadedFileUrl2;
          FFAppState().update(() {});
        }
      },
      onRemove: selected
          ? () {
              safeSetState(() {
                _model.isDataUploading2 = false;
                _model.uploadedLocalFile2 =
                    FFUploadedFile(bytes: Uint8List.fromList([]));
                _model.uploadedFileUrl2 = '';
              });
              FFAppState().uploadVideo = '';
              safeSetState(() {});
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        appBar: AppBar(
          backgroundColor: theme.secondary,
          automaticallyImplyLeading: false,
          leading: InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () async {
              context.goNamed(FeedWidget.routeName);
            },
            child: Icon(
              Icons.close_rounded,
              color: theme.tertiary,
              size: 24.0,
            ),
          ),
          title: Text(
            'Create post',
            style: theme.titleMedium.override(
              fontFamily: 'Poppins',
              fontSize: 17.0,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 16.0, 0.0),
              child: InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                  if ((_model.uploadedFileUrl1 != '') ||
                      (_model.uploadedFileUrl2 != '')) {
                    {
                      safeSetState(() => _model.isDataUploading3 = true);
                      var selectedUploadedFiles = <FFUploadedFile>[];
                      var selectedMedia = <SelectedFile>[];
                      var downloadUrls = <String>[];
                      try {
                        showUploadMessage(
                          context,
                          'Uploading file...',
                          showLoading: true,
                        );
                        selectedUploadedFiles =
                            _model.previewVideo!.bytes!.isNotEmpty
                                ? [_model.previewVideo!]
                                : <FFUploadedFile>[];
                        selectedMedia = selectedFilesFromUploadedFiles(
                          selectedUploadedFiles,
                        );
                        downloadUrls = (await Future.wait(
                          selectedMedia.map(
                            (m) async =>
                                await uploadData(m.storagePath, m.bytes),
                          ),
                        ))
                            .where((u) => u != null)
                            .map((u) => u!)
                            .toList();
                      } finally {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        _model.isDataUploading3 = false;
                      }
                      if (selectedUploadedFiles.length == selectedMedia.length &&
                          downloadUrls.length == selectedMedia.length) {
                        safeSetState(() {
                          _model.uploadedLocalFile3 =
                              selectedUploadedFiles.first;
                          _model.uploadedFileUrl3 = downloadUrls.first;
                        });
                        showUploadMessage(context, 'Success!');
                      } else {
                        safeSetState(() {});
                        showUploadMessage(context, 'Failed to upload data');
                        return;
                      }
                    }

                    // Create the post in Supabase (photo/video stored as
                    // direct URLs; the feed resolves them via feed_page).
                    await PostRepository().createPost(
                      caption: _model.textController.text,
                      photoUrl: _model.uploadedFileUrl1,
                      videoUrl: _model.uploadedFileUrl2,
                      videoThumbnail: _model.uploadedFileUrl3,
                      allowComments: !_model.switchValue2!,
                      allowLikes: !_model.switchValue1!,
                      location: _model.placePickerValue.address,
                      callToActionEnabled: FFAppState().calltoactionenabled,
                      callToActionText: FFAppState().calltoactiontext,
                      callToActionLink: FFAppState().calltoactionurl,
                      labels: FFAppState().imageLabels,
                      foodPost: false,
                    );

                    context.goNamed(FeedWidget.routeName);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Upload a video or image to create a post',
                          style: GoogleFonts.getFont(
                            'Poppins',
                            color: theme.secondary,
                          ),
                        ),
                        duration: const Duration(milliseconds: 4000),
                        backgroundColor: theme.primary,
                      ),
                    );
                  }

                  safeSetState(() {});
                },
                child: Text(
                  FFLocalizations.of(context).getText(
                    'h38vk44z' /* Share */,
                  ),
                  style: theme.titleMedium.override(
                    fontFamily: 'Poppins',
                    color: theme.primary,
                    fontSize: 15.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          centerTitle: true,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Caption + media preview ──────────────────────────────────
                createCard(
                  context,
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _captionMediaThumb(),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: TextFormField(
                            controller: _model.textController,
                            focusNode: _model.textFieldFocusNode,
                            autofocus: false,
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 3,
                            maxLines: 5,
                            keyboardType: TextInputType.multiline,
                            cursorColor: theme.primary,
                            style: theme.bodyMedium.override(
                              fontFamily: 'Poppins',
                              fontSize: 14.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.normal,
                              lineHeight: 1.5,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: FFLocalizations.of(context).getText(
                                'gfmx68cs' /* Write a caption... */,
                              ),
                              hintStyle: theme.bodyMedium.override(
                                fontFamily: 'Poppins',
                                color: kCreateHint,
                                fontSize: 14.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.normal,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 6.0, horizontal: 0.0),
                            ),
                            validator: _model.textControllerValidator
                                .asValidator(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                // ── Tag people / call to action / location ───────────────────
                createCard(
                  context,
                  child: Column(
                    children: [
                      createChoiceRow(
                        context,
                        label: 'Tag people',
                        value: 'None',
                        onTap: () async {
                          context.pushNamed(
                            TagUsersWidget.routeName,
                            extra: <String, dynamic>{
                              kTransitionInfoKey: TransitionInfo(
                                hasTransition: true,
                                transitionType: PageTransitionType.bottomToTop,
                              ),
                            },
                          );
                        },
                      ),
                      createInnerDivider(),
                      if (FFAppState().calltoactionenabled)
                        createChoiceRow(
                          context,
                          label: FFAppState().calltoactiontext.isEmpty
                              ? 'Call to action'
                              : FFAppState().calltoactiontext,
                          subtitle: FFAppState().calltoactionurl.maybeHandleOverflow(
                                maxChars: 42,
                                replacement: '…',
                              ),
                          onTap: () async {
                            context.pushNamed(
                              CallToActionWidget.routeName,
                              extra: <String, dynamic>{
                                kTransitionInfoKey: TransitionInfo(
                                  hasTransition: true,
                                  transitionType:
                                      PageTransitionType.bottomToTop,
                                ),
                              },
                            );
                          },
                          onClear: () {
                            FFAppState().calltoactionenabled = false;
                            FFAppState().calltoactiontext = '';
                            FFAppState().calltoactionurl = '';
                            FFAppState().update(() {});
                          },
                        )
                      else
                        createChoiceRow(
                          context,
                          label: 'Add call to action',
                          value: 'None',
                          onTap: () async {
                            context.pushNamed(
                              CallToActionWidget.routeName,
                              extra: <String, dynamic>{
                                kTransitionInfoKey: TransitionInfo(
                                  hasTransition: true,
                                  transitionType:
                                      PageTransitionType.bottomToTop,
                                ),
                              },
                            );
                          },
                        ),
                      createInnerDivider(),
                      _locationRow(),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
                // ── Privacy toggles ──────────────────────────────────────────
                createCard(
                  context,
                  child: Column(
                    children: [
                      createToggleRow(
                        context,
                        label: 'Hide like and view counts',
                        subtitle: 'Only you will see totals',
                        value: _model.switchValue1!,
                        onChanged: (v) =>
                            safeSetState(() => _model.switchValue1 = v),
                      ),
                      createInnerDivider(),
                      createToggleRow(
                        context,
                        label: 'Turn off commenting',
                        subtitle: 'You can change this later',
                        value: _model.switchValue2!,
                        onChanged: (v) =>
                            safeSetState(() => _model.switchValue2 = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22.0),
                // ── Add media ────────────────────────────────────────────────
                createSectionLabel(context, 'Add media'),
                Row(
                  children: [
                    Expanded(child: _imageTile()),
                    const SizedBox(width: 12.0),
                    Expanded(child: _videoTile()),
                  ],
                ),
                const SizedBox(height: 12.0),
                Center(
                  child: Text(
                    'Videos over 60 seconds are rejected on upload.',
                    textAlign: TextAlign.center,
                    style: theme.bodySmall.override(
                      fontFamily: 'Poppins',
                      color: kCreateHint,
                      fontSize: 12.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
