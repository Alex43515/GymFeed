import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/custom_code/widgets/create_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'gpt_vision_model.dart';
export 'gpt_vision_model.dart';

class GptVisionWidget extends StatefulWidget {
  const GptVisionWidget({super.key});

  static String routeName = 'gptVision';
  static String routePath = 'gptVision';

  @override
  State<GptVisionWidget> createState() => _GptVisionWidgetState();
}

class _GptVisionWidgetState extends State<GptVisionWidget> {
  late GptVisionModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => GptVisionModel());

    _model.alwayspopulatedTextController ??= TextEditingController();
    _model.alwayspopulatedFocusNode ??= FocusNode();

    _model.textField2TextController ??= TextEditingController();
    _model.textField2FocusNode ??= FocusNode();

    // The always-populated controller carries the hidden system prompt that is
    // prepended to the user's question when calling the vision model.
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {
          _model.alwayspopulatedTextController?.text =
              FFLocalizations.of(context).getText(
            'ek23amue' /* ***Important: If somebody asks... */,
          );
        }));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  // Pick (gallery or camera) → upload → store as the user's vision image.
  Future<void> _pickImage() async {
    final selectedMedia = await selectMediaWithSourceBottomSheet(
      context: context,
      maxWidth: 300.00,
      maxHeight: 300.00,
      allowPhoto: true,
    );
    if (selectedMedia != null &&
        selectedMedia
            .every((m) => validateFileFormat(m.storagePath, context))) {
      safeSetState(() => _model.isDataUploading = true);
      var selectedUploadedFiles = <FFUploadedFile>[];
      var downloadUrls = <String>[];
      try {
        showUploadMessage(context, 'Uploading file...', showLoading: true);
        selectedUploadedFiles = selectedMedia
            .map((m) => FFUploadedFile(
                  name: m.storagePath.split('/').last,
                  bytes: m.bytes,
                  height: m.dimensions?.height,
                  width: m.dimensions?.width,
                  blurHash: m.blurHash,
                ))
            .toList();
        downloadUrls = (await Future.wait(
          selectedMedia.map(
            (m) async => await uploadData(m.storagePath, m.bytes),
          ),
        ))
            .where((u) => u != null)
            .map((u) => u!)
            .toList();
      } finally {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _model.isDataUploading = false;
      }
      if (selectedUploadedFiles.length == selectedMedia.length &&
          downloadUrls.length == selectedMedia.length) {
        safeSetState(() {
          _model.uploadedLocalFile = selectedUploadedFiles.first;
          _model.uploadedFileUrl = downloadUrls.first;
        });
        showUploadMessage(context, 'Success!');
      } else {
        safeSetState(() {});
        showUploadMessage(context, 'Failed to upload data');
        return;
      }
    }

    await currentUserReference!.update(createUsersRecordData(
      visionURL: _model.uploadedFileUrl,
    ));
  }

  Future<void> _scan() async {
    await currentUserReference!.update({
      ...mapToFirestore({'visionButton': FieldValue.increment(1)}),
    });
    _model.openaiRes = await OpenAIAPIGroup.createChatCompletionCall.call(
      query:
          '${_model.alwayspopulatedTextController.text}${_model.textField2TextController.text}',
      imagePath: valueOrDefault(currentUserDocument?.visionURL, ''),
      assistantId: FFAppState().assistantId,
    );
    if ((_model.openaiRes?.succeeded ?? true)) {
      FFAppState().query = _model.alwayspopulatedTextController.text;
      FFAppState().imageURL = _model.uploadedFileUrl;
      FFAppState().chatHistoryAPP =
          OpenAIAPIGroup.createChatCompletionCall.resText(
        (_model.openaiRes?.jsonBody ?? ''),
      )!;
      FFAppState().assistantVisionID = FFAppState().assistantId;
    }
    safeSetState(() => _model.textField2TextController?.clear());
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
        backgroundColor: theme.secondary,
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(12.0, 12.0, 12.0, 8.0),
                child: Row(
                  children: [
                    InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async => context.safePop(),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: theme.tertiary, size: 22.0),
                    ),
                    Expanded(
                      child: Text(
                        'Machine scanner',
                        textAlign: TextAlign.center,
                        style: theme.headlineMedium.override(
                          fontFamily: 'Poppins',
                          color: theme.tertiary,
                          fontSize: 17.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async => _pickImage(),
                      child: Icon(Icons.add_rounded,
                          color: theme.tertiary, size: 26.0),
                    ),
                  ],
                ),
              ),
              // ── Scrollable body ─────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Custom camera / image preview frame
                      AuthUserStreamWidget(
                        builder: (context) {
                          final url = valueOrDefault(
                              currentUserDocument?.visionURL, '');
                          return GestureDetector(
                            onTap: () async => _pickImage(),
                            child: Container(
                              width: double.infinity,
                              height: 380.0,
                              decoration: BoxDecoration(
                                color: const Color(0xFF141414),
                                borderRadius: BorderRadius.circular(20.0),
                                border: Border.all(
                                    color: kCreateStroke, width: 1.0),
                              ),
                              child: url.isEmpty
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.photo_camera_outlined,
                                            color: kCreateHint, size: 46.0),
                                        const SizedBox(height: 12.0),
                                        Text(
                                          'Tap to add a photo',
                                          style: theme.bodyMedium.override(
                                            fontFamily: 'Poppins',
                                            color: kCreateHint,
                                            fontSize: 14.0,
                                            letterSpacing: 0.0,
                                          ),
                                        ),
                                      ],
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(20.0),
                                      child: Image.network(
                                        url,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16.0),
                      // Question prompt
                      TextFormField(
                        controller: _model.textField2TextController,
                        focusNode: _model.textField2FocusNode,
                        autofocus: false,
                        minLines: 2,
                        maxLines: 4,
                        keyboardType: TextInputType.multiline,
                        cursorColor: theme.primary,
                        style: theme.bodyMedium.override(
                          fontFamily: 'Poppins',
                          color: theme.tertiary,
                          fontSize: 14.0,
                          letterSpacing: 0.0,
                        ),
                        decoration: createInputDecoration(
                          context,
                          hintText:
                              'Tell our scanner what would you like to know about this machine?',
                        ),
                        validator: _model.textField2TextControllerValidator
                            .asValidator(context),
                      ),
                      // Hidden system-prompt field (kept for controller parity).
                      Offstage(
                        offstage: true,
                        child: TextFormField(
                          controller: _model.alwayspopulatedTextController,
                          focusNode: _model.alwayspopulatedFocusNode,
                        ),
                      ),
                      // Result (shown after a scan)
                      if (_model.openaiRes != null) ...[
                        const SizedBox(height: 16.0),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: kCreateSurface,
                            borderRadius: BorderRadius.circular(kCreateRadius),
                            border:
                                Border.all(color: kCreateStroke, width: 1.0),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: SelectionArea(
                            child: Text(
                              valueOrDefault<String>(
                                OpenAIAPIGroup.createChatCompletionCall.resText(
                                  (_model.openaiRes?.jsonBody ?? ''),
                                ),
                                'The result will be shown here',
                              ),
                              style: theme.bodyMedium.override(
                                fontFamily: 'Poppins',
                                color: theme.tertiary,
                                fontSize: 14.0,
                                letterSpacing: 0.0,
                                lineHeight: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8.0),
                    ],
                  ),
                ),
              ),
              // ── Scan button ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(28.0),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () async => _scan(),
                  child: Container(
                    width: double.infinity,
                    height: 54.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.tertiary,
                      borderRadius: BorderRadius.circular(28.0),
                    ),
                    child: Text(
                      'Scan',
                      style: theme.titleSmall.override(
                        fontFamily: 'Poppins',
                        color: const Color(0xFF0A0A0A),
                        fontSize: 16.0,
                        letterSpacing: 0.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
