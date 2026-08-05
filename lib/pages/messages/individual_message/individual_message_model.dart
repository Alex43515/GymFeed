import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'individual_message_widget.dart' show IndividualMessageWidget;
import 'package:flutter/material.dart';

class IndividualMessageModel extends FlutterFlowModel<IndividualMessageWidget> {
  ///  Local state fields for this page.

  List<String> imageUploaded = [];
  void addToImageUploaded(String item) => imageUploaded.add(item);
  void removeFromImageUploaded(String item) => imageUploaded.remove(item);
  void removeAtIndexFromImageUploaded(int index) =>
      imageUploaded.removeAt(index);
  void insertAtIndexInImageUploaded(int index, String item) =>
      imageUploaded.insert(index, item);
  void updateImageUploadedAtIndex(int index, Function(String) updateFn) =>
      imageUploaded[index] = updateFn(imageUploaded[index]);

  List<String> videoUploaded = [];
  void addToVideoUploaded(String item) => videoUploaded.add(item);
  void removeFromVideoUploaded(String item) => videoUploaded.remove(item);
  void removeAtIndexFromVideoUploaded(int index) =>
      videoUploaded.removeAt(index);
  void insertAtIndexInVideoUploaded(int index, String item) =>
      videoUploaded.insert(index, item);
  void updateVideoUploadedAtIndex(int index, Function(String) updateFn) =>
      videoUploaded[index] = updateFn(videoUploaded[index]);

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - pickVideo] action in Icon widget.
  String? pickedVideo;
  // Stores action output result for [Custom Action - compressVideo] action in Icon widget.
  FFUploadedFile? compressedVideo;
  bool isDataUploading1 = false;
  FFUploadedFile uploadedLocalFile1 =
      FFUploadedFile(bytes: Uint8List.fromList([]));
  String uploadedFileUrl1 = '';

  // Stores action output result for [Custom Action - pickImage] action in Icon widget.
  String? pickedImage;
  // Stores action output result for [Custom Action - compressImage] action in Icon widget.
  FFUploadedFile? compressImage;
  bool isDataUploading2 = false;
  FFUploadedFile uploadedLocalFile2 =
      FFUploadedFile(bytes: Uint8List.fromList([]));
  String uploadedFileUrl2 = '';

  // State field(s) for Message widget.
  FocusNode? messageFocusNode;
  TextEditingController? messageTextController;
  String? Function(BuildContext, String?)? messageTextControllerValidator;
  // Stores action output result for [Backend Call - Create Document] action in Send widget.
  ChatMessagesRecord? message;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    messageFocusNode?.dispose();
    messageTextController?.dispose();
  }
}
