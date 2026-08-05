import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'profile_picture_widget.dart' show ProfilePictureWidget;
import 'package:flutter/material.dart';

class ProfilePictureModel extends FlutterFlowModel<ProfilePictureWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  bool isDataUploading = false;
  FFUploadedFile uploadedLocalFile =
      FFUploadedFile(bytes: Uint8List.fromList([]));
  String uploadedFileUrl = '';

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
