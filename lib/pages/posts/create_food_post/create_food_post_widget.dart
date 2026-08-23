import '/backend/supabase/repositories/post_repository.dart';
import '/backend/firebase_storage/storage.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_video_player.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import '/custom_code/widgets/create_ui.dart';
import '/custom_code/widgets/upload_progress_screen.dart';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'create_food_post_model.dart';
export 'create_food_post_model.dart';

class CreateFoodPostWidget extends StatefulWidget {
  const CreateFoodPostWidget({super.key});

  static String routeName = 'createFoodPost';
  static String routePath = 'createFoodPost';

  @override
  State<CreateFoodPostWidget> createState() => _CreateFoodPostWidgetState();
}

class _CreateFoodPostWidgetState extends State<CreateFoodPostWidget>
    with TickerProviderStateMixin {
  late CreateFoodPostModel _model;
  double? _foodMediaProgress;
  bool _postingFood = false;
  bool _showLegacyFoodMedia = false;
  String? _videoAssetId;
  String? _videoThumbnailUrl;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CreateFoodPostModel());

    _model.tabBarController = TabController(
      vsync: this,
      length: 2,
      initialIndex: 0,
    )..addListener(() => safeSetState(() {}));
    _model.postTitleTextController ??= TextEditingController();
    _model.postTitleFocusNode ??= FocusNode();

    _model.recipeTextController ??= TextEditingController();
    _model.recipeFocusNode ??= FocusNode();

    _model.cookingTimeTextController ??= TextEditingController();
    _model.cookingTimeFocusNode ??= FocusNode();

    _model.nutritionTextController ??= TextEditingController();
    _model.nutritionFocusNode ??= FocusNode();

    _model.caloriesTextController ??= TextEditingController();
    _model.caloriesFocusNode ??= FocusNode();

    _model.proteinTextController ??= TextEditingController();
    _model.proteinFocusNode ??= FocusNode();

    _model.carbsTextController ??= TextEditingController();
    _model.carbsFocusNode ??= FocusNode();

    _model.fatsTextController ??= TextEditingController();
    _model.fatsFocusNode ??= FocusNode();

    _model.switchValue1 = false;
    _model.switchValue2 = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _pickFoodVideo() async {
    if (_foodMediaProgress != null) return;
    setState(() => _foodMediaProgress = .08);
    try {
      final compressed = await actions.pickAndPrepareVideo();
      if (compressed?.bytes == null || compressed!.bytes!.isEmpty) {
        return;
      }
      _model.compressVideo = compressed;
      if (mounted) setState(() => _foodMediaProgress = .35);
      final upload = await showUploadProgress(
        context,
        videoBytes: compressed.bytes!,
        videoTitle: _model.postTitleTextController.text.trim().isEmpty
            ? 'GymFeed food video'
            : _model.postTitleTextController.text.trim(),
        videoFileName: compressed.name ?? 'gymfeed-food-video.mp4',
      );
      final url = upload?.videoPlaylistUrl;
      if (url == null || url.isEmpty || upload?.videoAssetId == null) {
        throw StateError('The video could not be uploaded.');
      }
      if (!mounted) return;
      setState(() {
        _model.uploadedLocalFile1 = compressed;
        _model.uploadedFileUrl1 = url;
        _videoAssetId = upload!.videoAssetId;
        _videoThumbnailUrl = upload.videoThumbnailUrl;
        _foodMediaProgress = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _foodMediaProgress = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video was not added: $error')),
      );
    } finally {
      if (mounted && _foodMediaProgress != null) {
        setState(() => _foodMediaProgress = null);
      }
    }
  }

  Future<void> _pickFoodPhoto() async {
    if (_foodMediaProgress != null) return;
    setState(() => _foodMediaProgress = .08);
    try {
      final path = await actions.pickImage();
      if (path == null || path.isEmpty) return;
      _model.pickImage = path;
      if (mounted) setState(() => _foodMediaProgress = .25);
      final compressed = await actions.compressImage(path);
      if (compressed?.bytes == null || compressed!.bytes!.isEmpty) {
        throw StateError('The photo could not be compressed.');
      }
      _model.compressImage = compressed;
      if (mounted) setState(() => _foodMediaProgress = .62);
      final selected = selectedFilesFromUploadedFiles([compressed]).first;
      final url = await uploadData(selected.storagePath, selected.bytes);
      if (url == null || url.isEmpty) {
        throw StateError('The photo could not be uploaded.');
      }
      if (!mounted) return;
      setState(() {
        _model.uploadedLocalFile2 = compressed;
        _model.uploadedFileUrl2 = url;
        _foodMediaProgress = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _foodMediaProgress = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo was not added: $error')),
      );
    } finally {
      if (mounted && _foodMediaProgress != null) {
        setState(() => _foodMediaProgress = null);
      }
    }
  }

  Future<void> _postFood() async {
    if (_postingFood ||
        (_model.uploadedFileUrl1.isEmpty && _model.uploadedFileUrl2.isEmpty)) {
      return;
    }
    setState(() => _postingFood = true);
    try {
      await PostRepository().createPost(
        caption: _model.postTitleTextController.text,
        photoUrl: _model.uploadedFileUrl2,
        videoUrl: _model.uploadedFileUrl1,
        videoThumbnail: _videoThumbnailUrl,
        videoAssetId: _videoAssetId,
        foodPost: true,
        allowComments: !(_model.switchValue2 ?? false),
        allowLikes: !(_model.switchValue1 ?? false),
        location: FFAppState().location,
        callToActionEnabled: FFAppState().calltoactionenabled,
        callToActionText: FFAppState().calltoactiontext,
        callToActionLink: FFAppState().calltoactionurl,
        labels: FFAppState().imageLabels,
        foodTitle: _model.postTitleTextController.text,
        foodDescription: _model.recipeTextController.text,
        recipe: _model.recipeTextController.text,
        nutritionFacts: _model.nutritionTextController.text,
        cookingTime: _model.cookingTimeTextController.text,
        mealType: _model.mealTypeValue,
        calories: int.tryParse(_model.caloriesTextController.text),
        protein: int.tryParse(_model.proteinTextController.text),
        carbs: _model.carbsTextController.text,
        fats: _model.fatsTextController.text,
        taggedUserIds: FFAppState()
            .taggedUsers
            .map((reference) => reference.id)
            .toList(growable: false),
      );
      FFAppState().taggedUsers = [];
      FFAppState().calltoactionenabled = false;
      FFAppState().calltoactiontext = '';
      FFAppState().calltoactionurl = '';
      if (!mounted) return;
      context.goNamed(FeedWidget.routeName);
    } catch (error) {
      if (!mounted) return;
      setState(() => _postingFood = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Food post was not published: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(0.0, 15.0, 0.0, 0.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(10.0, 15.0, 10.0, 20.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              context.safePop();
                            },
                            child: Icon(
                              Icons.arrow_back_ios_rounded,
                              color: FlutterFlowTheme.of(context).tertiary,
                              size: 15.0,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Align(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  20.0, 0.0, 0.0, 0.0),
                              child: Text(
                                'Create food post',
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Poppins',
                                      color:
                                          FlutterFlowTheme.of(context).tertiary,
                                      fontSize: 15.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.normal,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Opacity(
                            opacity: 0.0,
                            child: Icon(
                              Icons.settings_outlined,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 40.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment(0.0, 0),
                        child: TabBar(
                          labelColor: FlutterFlowTheme.of(context).tertiary,
                          unselectedLabelColor:
                              FlutterFlowTheme.of(context).secondaryText,
                          labelStyle:
                              FlutterFlowTheme.of(context).titleMedium.override(
                                    fontFamily: 'Urbanist',
                                    fontSize: 15.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.normal,
                                  ),
                          unselectedLabelStyle: TextStyle(),
                          indicatorColor: FlutterFlowTheme.of(context).tertiary,
                          padding: EdgeInsetsDirectional.fromSTEB(
                              30.0, 0.0, 30.0, 0.0),
                          tabs: [
                            Tab(
                              text: 'Meal insights',
                            ),
                            Tab(
                              text: 'Photo / video',
                            ),
                          ],
                          controller: _model.tabBarController,
                          onTap: (i) async {
                            [() async {}, () async {}][i]();
                          },
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _model.tabBarController,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 50.0, 0.0, 0.0),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  8.0, 0.0, 0.0, 0.0),
                                          child: Text(
                                            FFLocalizations.of(context).getText(
                                              'kiouc00p' /* Name of the Dish */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .accent1,
                                                  fontSize: 12.0,
                                                  letterSpacing: 0.0,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 0.0, 10.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      8.0, 10.0, 8.0, 0.0),
                                              child: TextFormField(
                                                controller: _model
                                                    .postTitleTextController,
                                                focusNode:
                                                    _model.postTitleFocusNode,
                                                autofocus: false,
                                                obscureText: false,
                                                decoration:
                                                    createInputDecoration(
                                                  context,
                                                  hintText: FFLocalizations.of(
                                                          context)
                                                      .getText(
                                                    '5b6n7a0k' /* Delicious Meal Post... */,
                                                  ),
                                                ),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Poppins',
                                                          letterSpacing: 0.0,
                                                        ),
                                                maxLines: 3,
                                                minLines: 1,
                                                validator: _model
                                                    .postTitleTextControllerValidator
                                                    .asValidator(context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  8.0, 0.0, 0.0, 0.0),
                                          child: Text(
                                            FFLocalizations.of(context).getText(
                                              'mpggvh1u' /* Recipe */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .accent1,
                                                  fontSize: 12.0,
                                                  letterSpacing: 0.0,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 0.0, 10.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      8.0, 10.0, 8.0, 0.0),
                                              child: TextFormField(
                                                controller:
                                                    _model.recipeTextController,
                                                focusNode:
                                                    _model.recipeFocusNode,
                                                autofocus: false,
                                                obscureText: false,
                                                decoration:
                                                    createInputDecoration(
                                                  context,
                                                  hintText: FFLocalizations.of(
                                                          context)
                                                      .getText(
                                                    'i78j1jk0' /* Craft Your Culinary Story... */,
                                                  ),
                                                ),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Poppins',
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .tertiary,
                                                          fontSize: 12.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                        ),
                                                maxLines: null,
                                                minLines: 1,
                                                keyboardType:
                                                    TextInputType.multiline,
                                                validator: _model
                                                    .recipeTextControllerValidator
                                                    .asValidator(context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  8.0, 0.0, 0.0, 0.0),
                                          child: Text(
                                            FFLocalizations.of(context).getText(
                                              'f4jvmnco' /* Preparation Time (minutes) */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .accent1,
                                                  fontSize: 12.0,
                                                  letterSpacing: 0.0,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 0.0, 10.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      8.0, 10.0, 8.0, 0.0),
                                              child: TextFormField(
                                                controller: _model
                                                    .cookingTimeTextController,
                                                focusNode:
                                                    _model.cookingTimeFocusNode,
                                                autofocus: false,
                                                obscureText: false,
                                                decoration:
                                                    createInputDecoration(
                                                  context,
                                                  hintText: FFLocalizations.of(
                                                          context)
                                                      .getText(
                                                    'j3cicxpd' /* From Kitchen to Table in No Ti... */,
                                                  ),
                                                ),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Poppins',
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .tertiary,
                                                          letterSpacing: 0.0,
                                                        ),
                                                maxLines: 5,
                                                minLines: 1,
                                                keyboardType:
                                                    TextInputType.number,
                                                validator: _model
                                                    .cookingTimeTextControllerValidator
                                                    .asValidator(context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  8.0, 0.0, 0.0, 0.0),
                                          child: Text(
                                            FFLocalizations.of(context).getText(
                                              'kyyfbr7b' /* Nutrition */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .accent1,
                                                  fontSize: 12.0,
                                                  letterSpacing: 0.0,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    8.0, 10.0, 8.0, 0.0),
                                            child: TextFormField(
                                              controller: _model
                                                  .nutritionTextController,
                                              focusNode:
                                                  _model.nutritionFocusNode,
                                              autofocus: false,
                                              obscureText: false,
                                              decoration: createInputDecoration(
                                                context,
                                                hintText:
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                  'w2wgrc7c' /* Fuel Your Wellness Journey.. */,
                                                ),
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Poppins',
                                                        letterSpacing: 0.0,
                                                      ),
                                              maxLines: null,
                                              minLines: 1,
                                              keyboardType:
                                                  TextInputType.multiline,
                                              validator: _model
                                                  .nutritionTextControllerValidator
                                                  .asValidator(context),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 10.0, 0.0, 0.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    8.0, 0.0, 0.0, 10.0),
                                            child: Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                '9trtkw2l' /* Meal type */,
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Poppins',
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .accent1,
                                                        fontSize: 12.0,
                                                        letterSpacing: 0.0,
                                                      ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              createSectionLabel(
                                                  context, 'Meal type'),
                                              Wrap(
                                                spacing: 8.0,
                                                runSpacing: 8.0,
                                                children: const [
                                                  'Breakfast',
                                                  'Lunch',
                                                  'Dinner',
                                                  'Snack',
                                                  'Desert',
                                                ]
                                                    .map((c) => createChip(
                                                          context,
                                                          label: c,
                                                          selected: _model
                                                                  .mealTypeValue ==
                                                              c,
                                                          onTap: () =>
                                                              safeSetState(() =>
                                                                  _model.mealTypeValue =
                                                                      c),
                                                        ))
                                                    .toList(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 10.0, 0.0, 0.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    8.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                'dtibfafa' /* Calories */,
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Poppins',
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .accent1,
                                                        fontSize: 12.0,
                                                        letterSpacing: 0.0,
                                                      ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    8.0, 10.0, 8.0, 0.0),
                                            child: TextFormField(
                                              controller:
                                                  _model.caloriesTextController,
                                              focusNode:
                                                  _model.caloriesFocusNode,
                                              autofocus: false,
                                              obscureText: false,
                                              decoration: createInputDecoration(
                                                context,
                                                hintText:
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                  '652h4dg7' /* Calories */,
                                                ),
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
                                                        letterSpacing: 0.0,
                                                      ),
                                              maxLines: null,
                                              minLines: 1,
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: _model
                                                  .caloriesTextControllerValidator
                                                  .asValidator(context),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 10.0, 0.0, 0.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    8.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                'sh1zbhtb' /* Protein in grams */,
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Poppins',
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .accent1,
                                                        fontSize: 12.0,
                                                        letterSpacing: 0.0,
                                                      ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 0.0, 10.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      8.0, 10.0, 8.0, 0.0),
                                              child: TextFormField(
                                                controller: _model
                                                    .proteinTextController,
                                                focusNode:
                                                    _model.proteinFocusNode,
                                                autofocus: false,
                                                obscureText: false,
                                                decoration:
                                                    createInputDecoration(
                                                  context,
                                                  hintText: FFLocalizations.of(
                                                          context)
                                                      .getText(
                                                    'tcfh57cy' /* Protein */,
                                                  ),
                                                ),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Poppins',
                                                          letterSpacing: 0.0,
                                                        ),
                                                maxLines: null,
                                                minLines: 1,
                                                keyboardType:
                                                    TextInputType.number,
                                                validator: _model
                                                    .proteinTextControllerValidator
                                                    .asValidator(context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 10.0, 0.0, 0.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    8.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                'n8zba6ob' /* Carbs */,
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Poppins',
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .accent1,
                                                        fontSize: 12.0,
                                                        letterSpacing: 0.0,
                                                      ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 0.0, 10.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      8.0, 10.0, 8.0, 0.0),
                                              child: TextFormField(
                                                controller:
                                                    _model.carbsTextController,
                                                focusNode:
                                                    _model.carbsFocusNode,
                                                autofocus: false,
                                                obscureText: false,
                                                decoration:
                                                    createInputDecoration(
                                                  context,
                                                  hintText: FFLocalizations.of(
                                                          context)
                                                      .getText(
                                                    'zubavkmg' /* Protein */,
                                                  ),
                                                ),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Poppins',
                                                          letterSpacing: 0.0,
                                                        ),
                                                maxLines: null,
                                                minLines: 1,
                                                keyboardType:
                                                    TextInputType.number,
                                                validator: _model
                                                    .carbsTextControllerValidator
                                                    .asValidator(context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 10.0, 0.0, 0.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    8.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                'jdyvm0u0' /* Fats */,
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Poppins',
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .accent1,
                                                        fontSize: 12.0,
                                                        letterSpacing: 0.0,
                                                      ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 0.0, 10.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      8.0, 10.0, 8.0, 0.0),
                                              child: TextFormField(
                                                controller:
                                                    _model.fatsTextController,
                                                focusNode: _model.fatsFocusNode,
                                                autofocus: false,
                                                obscureText: false,
                                                decoration:
                                                    createInputDecoration(
                                                  context,
                                                  hintText: FFLocalizations.of(
                                                          context)
                                                      .getText(
                                                    'qc76m39r' /* Protein */,
                                                  ),
                                                ),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Poppins',
                                                          letterSpacing: 0.0,
                                                        ),
                                                maxLines: null,
                                                minLines: 1,
                                                keyboardType:
                                                    TextInputType.number,
                                                validator: _model
                                                    .fatsTextControllerValidator
                                                    .asValidator(context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 0.0, 6.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    15.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                'zmql9jte' /* Hide like and view counts on p... */,
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 14.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 0.0, 12.0, 0.0),
                                            child: Switch(
                                              value: _model.switchValue1!,
                                              onChanged: (newValue) async {
                                                safeSetState(() => _model
                                                    .switchValue1 = newValue);
                                              },
                                              activeColor: Colors.white,
                                              activeTrackColor:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              inactiveTrackColor:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              inactiveThumbColor:
                                                  FlutterFlowTheme.of(context)
                                                      .tertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 0.0, 16.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    15.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                'h7t1139t' /* Hide comments on post */,
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 14.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 0.0, 12.0, 0.0),
                                            child: Switch(
                                              value: _model.switchValue2!,
                                              onChanged: (newValue) async {
                                                safeSetState(() => _model
                                                    .switchValue2 = newValue);
                                              },
                                              activeColor: Colors.white,
                                              activeTrackColor:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              inactiveTrackColor:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              inactiveThumbColor: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 0.0, 26.0),
                                      child: Stack(
                                        children: [
                                          if (FFAppState().calltoactionenabled)
                                            InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                context.pushNamed(
                                                  CallToActionWidget.routeName,
                                                  extra: <String, dynamic>{
                                                    kTransitionInfoKey:
                                                        TransitionInfo(
                                                      hasTransition: true,
                                                      transitionType:
                                                          PageTransitionType
                                                              .bottomToTop,
                                                    ),
                                                  },
                                                );
                                              },
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(15.0, 0.0,
                                                                0.0, 0.0),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          FFAppState()
                                                              .calltoactiontext,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'Poppins',
                                                                fontSize: 14.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
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
                                                            FFAppState()
                                                                .calltoactionurl
                                                                .maybeHandleOverflow(
                                                                  maxChars: 48,
                                                                  replacement:
                                                                      '…',
                                                                ),
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'Poppins',
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                                  fontSize:
                                                                      13.0,
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
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 0.0,
                                                                15.0, 0.0),
                                                    child: InkWell(
                                                      splashColor:
                                                          Colors.transparent,
                                                      focusColor:
                                                          Colors.transparent,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      onTap: () async {
                                                        FFAppState()
                                                                .calltoactionenabled =
                                                            false;
                                                        FFAppState()
                                                            .calltoactiontext = '';
                                                        FFAppState()
                                                            .update(() {});
                                                        FFAppState()
                                                            .calltoactionurl = '';
                                                        FFAppState()
                                                            .update(() {});
                                                      },
                                                      child: Icon(
                                                        Icons.close_rounded,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .tertiary,
                                                        size: 18.0,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          if (!FFAppState().calltoactionenabled)
                                            InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                context.pushNamed(
                                                  CallToActionWidget.routeName,
                                                  extra: <String, dynamic>{
                                                    kTransitionInfoKey:
                                                        TransitionInfo(
                                                      hasTransition: true,
                                                      transitionType:
                                                          PageTransitionType
                                                              .bottomToTop,
                                                    ),
                                                  },
                                                );
                                              },
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(15.0, 0.0,
                                                                0.0, 0.0),
                                                    child: Text(
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        '1slcm8sf' /* Add call to action */,
                                                      ),
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            fontFamily:
                                                                'Poppins',
                                                            fontSize: 14.0,
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                          ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 0.0,
                                                                15.0, 0.0),
                                                    child: Icon(
                                                      Icons
                                                          .arrow_forward_ios_rounded,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .tertiary,
                                                      size: 18.0,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 0.0, 70.0),
                                      child: InkWell(
                                        splashColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () async {
                                          context.pushNamed(
                                            TagUsersWidget.routeName,
                                            extra: <String, dynamic>{
                                              kTransitionInfoKey:
                                                  TransitionInfo(
                                                hasTransition: true,
                                                transitionType:
                                                    PageTransitionType
                                                        .bottomToTop,
                                              ),
                                            },
                                          );
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      15.0, 0.0, 0.0, 0.0),
                                              child: Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'uepjqhvq' /* Tag people */,
                                                ),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 14.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                        ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 0.0, 15.0, 0.0),
                                              child: Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .tertiary,
                                                size: 18.0,
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
                            SingleChildScrollView(
                              child: !_showLegacyFoodMedia
                                  ? _FoodMediaPanel(
                                      videoUrl: _model.uploadedFileUrl1,
                                      photoUrl: _model.uploadedFileUrl2,
                                      videoName:
                                          _model.uploadedLocalFile1.name ?? '',
                                      photoName:
                                          _model.uploadedLocalFile2.name ?? '',
                                      videoBytes: _model.uploadedLocalFile1
                                              .bytes?.length ??
                                          0,
                                      photoBytes: _model.uploadedLocalFile2
                                              .bytes?.length ??
                                          0,
                                      progress: _foodMediaProgress,
                                      posting: _postingFood,
                                      onPickPhoto: _pickFoodPhoto,
                                      onPickVideo: _pickFoodVideo,
                                      onPost: _postFood,
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            if ((_model.uploadedFileUrl1 ==
                                                    '') &&
                                                (_model.uploadedFileUrl2 == ''))
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        0.0, 20.0, 0.0, 12.0),
                                                child: Container(
                                                  width:
                                                      MediaQuery.sizeOf(context)
                                                              .width *
                                                          0.9,
                                                  height: 300.0,
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            40.0),
                                                    border: Border.all(
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .tertiary,
                                                      width: 1.0,
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                                10.0,
                                                                50.0,
                                                                10.0,
                                                                50.0),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          30.0,
                                                                          0.0,
                                                                          0.0),
                                                              child: Text(
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  'u23ijxuj' /* Capture Your Culinary Creation... */,
                                                                ),
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .tertiary,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          30.0,
                                                                          0.0,
                                                                          0.0),
                                                              child: Text(
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  'cbo4j5bn' /* Please note that all videos ov... */,
                                                                ),
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .tertiary,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if ((_model.uploadedFileUrl1 !=
                                                    '') ||
                                                (_model.uploadedFileUrl2 != ''))
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        0.0, 20.0, 0.0, 0.0),
                                                child: Container(
                                                  width:
                                                      MediaQuery.sizeOf(context)
                                                              .width *
                                                          0.9,
                                                  height: 300.0,
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryBackground,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.0),
                                                  ),
                                                  child: Align(
                                                    alignment:
                                                        AlignmentDirectional(
                                                            0.0, 0.0),
                                                    child: Container(
                                                      width: MediaQuery.sizeOf(
                                                                  context)
                                                              .width *
                                                          0.9,
                                                      height: 350.0,
                                                      child: Stack(
                                                        alignment:
                                                            AlignmentDirectional(
                                                                0.0, 0.0),
                                                        children: [
                                                          if (_model
                                                                  .uploadedFileUrl1 !=
                                                              '')
                                                            FlutterFlowVideoPlayer(
                                                              path: _model
                                                                  .uploadedFileUrl1,
                                                              videoType:
                                                                  VideoType
                                                                      .network,
                                                              width: MediaQuery
                                                                          .sizeOf(
                                                                              context)
                                                                      .width *
                                                                  1.0,
                                                              autoPlay: false,
                                                              looping: true,
                                                              showControls:
                                                                  true,
                                                              allowFullScreen:
                                                                  true,
                                                              allowPlaybackSpeedMenu:
                                                                  false,
                                                            ),
                                                          if (_model
                                                                  .uploadedFileUrl2 !=
                                                              '')
                                                            SingleChildScrollView(
                                                              scrollDirection:
                                                                  Axis.horizontal,
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                children: [
                                                                  ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            20.0),
                                                                    child: Image
                                                                        .network(
                                                                      _model
                                                                          .uploadedFileUrl2,
                                                                      width: MediaQuery.sizeOf(context)
                                                                              .width *
                                                                          0.9,
                                                                      height:
                                                                          300.0,
                                                                      fit: BoxFit
                                                                          .cover,
                                                                    ),
                                                                  ),
                                                                ],
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
                                        Column(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 0.0, 0.0, 16.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                      'vpx4f0hk' /* Please note that all videos ov... */,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Poppins',
                                                          letterSpacing: 0.0,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 10.0, 0.0, 0.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Stack(
                                                    children: [
                                                      if (_model
                                                              .uploadedFileUrl1 ==
                                                          '')
                                                        FFButtonWidget(
                                                          onPressed: () async {
                                                            _model.pickVideo =
                                                                await actions
                                                                    .pickVideo();
                                                            _model.compressVideo =
                                                                await actions
                                                                    .compressVideo(
                                                              _model.pickVideo!,
                                                            );
                                                            {
                                                              safeSetState(() =>
                                                                  _model.isDataUploading1 =
                                                                      true);
                                                              var selectedUploadedFiles =
                                                                  <FFUploadedFile>[];
                                                              var selectedMedia =
                                                                  <SelectedFile>[];
                                                              var downloadUrls =
                                                                  <String>[];
                                                              try {
                                                                showUploadMessage(
                                                                  context,
                                                                  'Uploading file...',
                                                                  showLoading:
                                                                      true,
                                                                );
                                                                selectedUploadedFiles = _model
                                                                        .compressVideo!
                                                                        .bytes!
                                                                        .isNotEmpty
                                                                    ? [
                                                                        _model
                                                                            .compressVideo!
                                                                      ]
                                                                    : <FFUploadedFile>[];
                                                                selectedMedia =
                                                                    selectedFilesFromUploadedFiles(
                                                                  selectedUploadedFiles,
                                                                );
                                                                downloadUrls = (await Future
                                                                        .wait(
                                                                  selectedMedia
                                                                      .map(
                                                                    (m) async =>
                                                                        await uploadData(
                                                                            m.storagePath,
                                                                            m.bytes),
                                                                  ),
                                                                ))
                                                                    .where((u) =>
                                                                        u !=
                                                                        null)
                                                                    .map((u) =>
                                                                        u!)
                                                                    .toList();
                                                              } finally {
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .hideCurrentSnackBar();
                                                                _model.isDataUploading1 =
                                                                    false;
                                                              }
                                                              if (selectedUploadedFiles
                                                                          .length ==
                                                                      selectedMedia
                                                                          .length &&
                                                                  downloadUrls
                                                                          .length ==
                                                                      selectedMedia
                                                                          .length) {
                                                                safeSetState(
                                                                    () {
                                                                  _model.uploadedLocalFile1 =
                                                                      selectedUploadedFiles
                                                                          .first;
                                                                  _model.uploadedFileUrl1 =
                                                                      downloadUrls
                                                                          .first;
                                                                });
                                                                showUploadMessage(
                                                                    context,
                                                                    'Success!');
                                                              } else {
                                                                safeSetState(
                                                                    () {});
                                                                showUploadMessage(
                                                                    context,
                                                                    'Failed to upload data');
                                                                return;
                                                              }
                                                            }

                                                            safeSetState(() {});
                                                          },
                                                          text: FFLocalizations
                                                                  .of(context)
                                                              .getText(
                                                            'u3wvqhoh' /* Add a video */,
                                                          ),
                                                          options:
                                                              FFButtonOptions(
                                                            width: 150.0,
                                                            height: 40.0,
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        24.0,
                                                                        0.0,
                                                                        24.0,
                                                                        0.0),
                                                            iconPadding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        0.0,
                                                                        0.0,
                                                                        0.0),
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .accent3,
                                                            textStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleSmall
                                                                    .override(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      color: Color(
                                                                          0xFF0A0A0A),
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                            elevation: 3.0,
                                                            borderSide:
                                                                BorderSide(
                                                              color: Colors
                                                                  .transparent,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        40.0),
                                                          ),
                                                        ),
                                                      if (_model
                                                              .uploadedFileUrl1 !=
                                                          '')
                                                        FFButtonWidget(
                                                          onPressed: () async {
                                                            safeSetState(() {
                                                              _model.isDataUploading1 =
                                                                  false;
                                                              _model.uploadedLocalFile1 =
                                                                  FFUploadedFile(
                                                                      bytes: Uint8List
                                                                          .fromList(
                                                                              []));
                                                              _model.uploadedFileUrl1 =
                                                                  '';
                                                            });
                                                          },
                                                          text: FFLocalizations
                                                                  .of(context)
                                                              .getText(
                                                            'jtc66eju' /* Delete video */,
                                                          ),
                                                          options:
                                                              FFButtonOptions(
                                                            width: 150.0,
                                                            height: 40.0,
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        0.0,
                                                                        0.0,
                                                                        0.0),
                                                            iconPadding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        0.0,
                                                                        0.0,
                                                                        0.0),
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .error,
                                                            textStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleSmall
                                                                    .override(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondary,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                            elevation: 3.0,
                                                            borderSide:
                                                                BorderSide(
                                                              color: Colors
                                                                  .transparent,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        40.0),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  Stack(
                                                    children: [
                                                      if (_model
                                                              .uploadedFileUrl2 ==
                                                          '')
                                                        FFButtonWidget(
                                                          onPressed: () async {
                                                            _model.pickImage =
                                                                await actions
                                                                    .pickImage();
                                                            _model.compressImage =
                                                                await actions
                                                                    .compressImage(
                                                              _model.pickImage!,
                                                            );
                                                            {
                                                              safeSetState(() =>
                                                                  _model.isDataUploading2 =
                                                                      true);
                                                              var selectedUploadedFiles =
                                                                  <FFUploadedFile>[];
                                                              var selectedMedia =
                                                                  <SelectedFile>[];
                                                              var downloadUrls =
                                                                  <String>[];
                                                              try {
                                                                selectedUploadedFiles = _model
                                                                        .compressImage!
                                                                        .bytes!
                                                                        .isNotEmpty
                                                                    ? [
                                                                        _model
                                                                            .compressImage!
                                                                      ]
                                                                    : <FFUploadedFile>[];
                                                                selectedMedia =
                                                                    selectedFilesFromUploadedFiles(
                                                                  selectedUploadedFiles,
                                                                );
                                                                downloadUrls = (await Future
                                                                        .wait(
                                                                  selectedMedia
                                                                      .map(
                                                                    (m) async =>
                                                                        await uploadData(
                                                                            m.storagePath,
                                                                            m.bytes),
                                                                  ),
                                                                ))
                                                                    .where((u) =>
                                                                        u !=
                                                                        null)
                                                                    .map((u) =>
                                                                        u!)
                                                                    .toList();
                                                              } finally {
                                                                _model.isDataUploading2 =
                                                                    false;
                                                              }
                                                              if (selectedUploadedFiles
                                                                          .length ==
                                                                      selectedMedia
                                                                          .length &&
                                                                  downloadUrls
                                                                          .length ==
                                                                      selectedMedia
                                                                          .length) {
                                                                safeSetState(
                                                                    () {
                                                                  _model.uploadedLocalFile2 =
                                                                      selectedUploadedFiles
                                                                          .first;
                                                                  _model.uploadedFileUrl2 =
                                                                      downloadUrls
                                                                          .first;
                                                                });
                                                              } else {
                                                                safeSetState(
                                                                    () {});
                                                                return;
                                                              }
                                                            }

                                                            safeSetState(() {});
                                                          },
                                                          text: FFLocalizations
                                                                  .of(context)
                                                              .getText(
                                                            'mt70s486' /* Add a photo */,
                                                          ),
                                                          options:
                                                              FFButtonOptions(
                                                            width: 150.0,
                                                            height: 40.0,
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        24.0,
                                                                        0.0,
                                                                        24.0,
                                                                        0.0),
                                                            iconPadding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        0.0,
                                                                        0.0,
                                                                        0.0),
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .accent3,
                                                            textStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleSmall
                                                                    .override(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      color: Color(
                                                                          0xFF0A0A0A),
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                            elevation: 3.0,
                                                            borderSide:
                                                                BorderSide(
                                                              color: Colors
                                                                  .transparent,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        40.0),
                                                          ),
                                                        ),
                                                      if (_model
                                                              .uploadedFileUrl2 !=
                                                          '')
                                                        FFButtonWidget(
                                                          onPressed: () async {
                                                            safeSetState(() {
                                                              _model.isDataUploading2 =
                                                                  false;
                                                              _model.uploadedLocalFile2 =
                                                                  FFUploadedFile(
                                                                      bytes: Uint8List
                                                                          .fromList(
                                                                              []));
                                                              _model.uploadedFileUrl2 =
                                                                  '';
                                                            });
                                                          },
                                                          text: FFLocalizations
                                                                  .of(context)
                                                              .getText(
                                                            '619xeud9' /* Delete photo */,
                                                          ),
                                                          options:
                                                              FFButtonOptions(
                                                            width: 150.0,
                                                            height: 40.0,
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        24.0,
                                                                        0.0,
                                                                        24.0,
                                                                        0.0),
                                                            iconPadding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        0.0,
                                                                        0.0,
                                                                        0.0),
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .error,
                                                            textStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleSmall
                                                                    .override(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      color: Color(
                                                                          0xFF0A0A0A),
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                            elevation: 3.0,
                                                            borderSide:
                                                                BorderSide(
                                                              color: Colors
                                                                  .transparent,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        40.0),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 50.0, 0.0, 50.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  FFButtonWidget(
                                                    onPressed: () async {
                                                      if ((_model.uploadedFileUrl1 !=
                                                              '') ||
                                                          (_model.uploadedFileUrl2 !=
                                                              '')) {
                                                        // Create the food post in
                                                        // Supabase.
                                                        await PostRepository()
                                                            .createPost(
                                                          caption: _model
                                                              .postTitleTextController
                                                              .text,
                                                          photoUrl: _model
                                                              .uploadedFileUrl2,
                                                          videoUrl: _model
                                                              .uploadedFileUrl1,
                                                          foodPost: true,
                                                          allowComments: !_model
                                                              .switchValue2!,
                                                          allowLikes: !_model
                                                              .switchValue1!,
                                                          location: FFAppState()
                                                              .location,
                                                          callToActionEnabled:
                                                              FFAppState()
                                                                  .calltoactionenabled,
                                                          callToActionText:
                                                              FFAppState()
                                                                  .calltoactiontext,
                                                          callToActionLink:
                                                              FFAppState()
                                                                  .calltoactionurl,
                                                          labels: FFAppState()
                                                              .imageLabels,
                                                          foodTitle: _model
                                                              .postTitleTextController
                                                              .text,
                                                          foodDescription: _model
                                                              .recipeTextController
                                                              .text,
                                                          nutritionFacts: _model
                                                              .nutritionTextController
                                                              .text,
                                                          cookingTime: _model
                                                              .cookingTimeTextController
                                                              .text,
                                                          mealType: _model
                                                              .mealTypeValue,
                                                          calories: int
                                                              .tryParse(_model
                                                                  .caloriesTextController
                                                                  .text),
                                                          protein: int.tryParse(
                                                              _model
                                                                  .proteinTextController
                                                                  .text),
                                                          carbs: _model
                                                              .carbsTextController
                                                              .text,
                                                          fats: _model
                                                              .fatsTextController
                                                              .text,
                                                          taggedUserIds: FFAppState()
                                                              .taggedUsers
                                                              .map(
                                                                  (reference) =>
                                                                      reference
                                                                          .id)
                                                              .toList(
                                                                  growable:
                                                                      false),
                                                        );
                                                        FFAppState()
                                                            .taggedUsers = [];

                                                        context.goNamed(
                                                            FeedWidget
                                                                .routeName);
                                                      } else {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              'Upload video or photo to create the post',
                                                              style: TextStyle(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondary,
                                                              ),
                                                            ),
                                                            duration: Duration(
                                                                milliseconds:
                                                                    4000),
                                                            backgroundColor:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                          ),
                                                        );
                                                      }

                                                      safeSetState(() {});
                                                    },
                                                    text: FFLocalizations.of(
                                                            context)
                                                        .getText(
                                                      '9ajp4qh4' /* Post */,
                                                    ),
                                                    options: FFButtonOptions(
                                                      width: double.infinity,
                                                      height: 54.0,
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  24.0,
                                                                  0.0,
                                                                  24.0,
                                                                  0.0),
                                                      iconPadding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  0.0,
                                                                  0.0,
                                                                  0.0),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      textStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleSmall
                                                              .override(
                                                                fontFamily:
                                                                    'Poppins',
                                                                color: Color(
                                                                    0xFF0A0A0A),
                                                                fontSize: 16.0,
                                                                letterSpacing:
                                                                    0.2,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                      elevation: 3.0,
                                                      borderSide: BorderSide(
                                                        color:
                                                            Colors.transparent,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              28.0),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _FoodMediaPanel extends StatelessWidget {
  const _FoodMediaPanel({
    required this.videoUrl,
    required this.photoUrl,
    required this.videoName,
    required this.photoName,
    required this.videoBytes,
    required this.photoBytes,
    required this.progress,
    required this.posting,
    required this.onPickPhoto,
    required this.onPickVideo,
    required this.onPost,
  });

  static const _green = Color(0xFF15E77D);
  final String videoUrl;
  final String photoUrl;
  final String videoName;
  final String photoName;
  final int videoBytes;
  final int photoBytes;
  final double? progress;
  final bool posting;
  final VoidCallback onPickPhoto;
  final VoidCallback onPickVideo;
  final VoidCallback onPost;

  bool get _hasMedia => videoUrl.isNotEmpty || photoUrl.isNotEmpty;
  bool get _showVideo => videoUrl.isNotEmpty;

  String _sizeLabel(int bytes) {
    if (bytes <= 0) return 'Uploaded';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MediaDropzone(
              progress: progress,
              mediaUrl: _showVideo ? videoUrl : photoUrl,
              video: _showVideo,
              fileName: _showVideo
                  ? (videoName.isEmpty ? 'food-clip.mp4' : videoName)
                  : (photoName.isEmpty ? 'meal-photo.jpg' : photoName),
              detail: _showVideo
                  ? '${_sizeLabel(videoBytes)} · within 60 seconds'
                  : _sizeLabel(photoBytes),
              title: 'Capture your culinary creation',
              description: 'One photo or a clip up to 60 seconds',
              onReplace: _showVideo ? onPickVideo : onPickPhoto,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MediaChoiceButton(
                    icon: Icons.photo_outlined,
                    label: photoUrl.isEmpty ? 'Photo' : 'Replace photo',
                    enabled: progress == null,
                    onTap: onPickPhoto,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MediaChoiceButton(
                    icon: Icons.videocam_outlined,
                    label: videoUrl.isEmpty ? 'Video' : 'Replace video',
                    enabled: progress == null,
                    onTap: onPickVideo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Color(0xFF858A90), size: 16),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Clips over 60 seconds are rejected on upload.',
                    style: TextStyle(
                      color: Color(0xFF858A90),
                      fontFamily: 'Poppins',
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed:
                    !_hasMedia || progress != null || posting ? null : onPost,
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  disabledBackgroundColor: const Color(0xFF252525),
                  foregroundColor: Colors.black,
                  disabledForegroundColor: const Color(0xFF6B6B6B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                ),
                child: posting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Post',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
}

class _MediaDropzone extends StatelessWidget {
  const _MediaDropzone({
    required this.progress,
    required this.mediaUrl,
    required this.video,
    required this.fileName,
    required this.detail,
    required this.title,
    required this.description,
    required this.onReplace,
  });

  final double? progress;
  final String mediaUrl;
  final bool video;
  final String fileName;
  final String detail;
  final String title;
  final String description;
  final VoidCallback onReplace;

  bool get _filled => mediaUrl.isNotEmpty;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _filled
            ? null
            : _DashedBorderPainter(
                color: progress == null
                    ? const Color(0xFF444444)
                    : _FoodMediaPanel._green,
                radius: 22,
              ),
        child: Container(
          width: double.infinity,
          height: 330,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF101010),
            borderRadius: BorderRadius.circular(22),
            border: _filled ? Border.all(color: const Color(0xFF303030)) : null,
          ),
          child: progress != null
              ? _uploading()
              : _filled
                  ? _preview()
                  : _empty(),
        ),
      );

  Widget _empty() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFF0E3422),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.restaurant_menu_rounded,
                color: _FoodMediaPanel._green, size: 27),
          ),
          const SizedBox(height: 17),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF878C92),
              fontFamily: 'Poppins',
              fontSize: 12,
            ),
          ),
        ],
      );

  Widget _uploading() {
    final percent = ((progress ?? 0) * 100).clamp(1, 99).round();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: _FoodMediaPanel._green,
              backgroundColor: Color(0xFF282828),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Uploading… $percent%',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            color: _FoodMediaPanel._green,
            backgroundColor: const Color(0xFF282828),
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _preview() => Stack(
        fit: StackFit.expand,
        children: [
          if (!video)
            Image.network(
              mediaUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFF151515),
                child:
                    Icon(Icons.broken_image_outlined, color: Color(0xFF777777)),
              ),
            )
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF202020), Color(0xFF0A0A0A)],
                ),
              ),
              child: Center(
                child: CircleAvatar(
                  radius: 31,
                  backgroundColor: Color(0xCC000000),
                  child: Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 36),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 11, 9, 11),
              color: const Color(0xDC101010),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          detail,
                          style: const TextStyle(
                            color: Color(0xFF8B9096),
                            fontFamily: 'Poppins',
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onReplace,
                    child: const Text(
                      'Replace',
                      style: TextStyle(
                        color: _FoodMediaPanel._green,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
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

class _MediaChoiceButton extends StatelessWidget {
  const _MediaChoiceButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: OutlinedButton.icon(
          onPressed: enabled ? onTap : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: const Color(0xFF555555),
            side: const BorderSide(color: Color(0xFF323232)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          icon: Icon(icon, color: enabled ? _FoodMediaPanel._green : null),
          label: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(radius),
      ));
    final metric = path.computeMetrics().first;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const dash = 7.0;
    const gap = 5.0;
    for (double distance = 0;
        distance < metric.length;
        distance += dash + gap) {
      canvas.drawPath(
        metric.extractPath(distance, (distance + dash).clamp(0, metric.length)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
