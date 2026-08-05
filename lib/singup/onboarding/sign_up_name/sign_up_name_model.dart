import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'sign_up_name_widget.dart' show SignUpNameWidget;
import 'package:flutter/material.dart';

class SignUpNameModel extends FlutterFlowModel<SignUpNameWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for FullName widget.
  FocusNode? fullNameFocusNode;
  TextEditingController? fullNameTextController;
  String? Function(BuildContext, String?)? fullNameTextControllerValidator;
  // State field(s) for Bio widget.
  FocusNode? bioFocusNode;
  TextEditingController? bioTextController;
  String? Function(BuildContext, String?)? bioTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    fullNameFocusNode?.dispose();
    fullNameTextController?.dispose();

    bioFocusNode?.dispose();
    bioTextController?.dispose();
  }
}
