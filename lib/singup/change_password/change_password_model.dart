import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'change_password_widget.dart' show ChangePasswordWidget;
import 'package:flutter/material.dart';

class ChangePasswordModel extends FlutterFlowModel<ChangePasswordWidget> {
  ///  State fields for stateful widgets in this page.

  FocusNode? passwordFocusNode;
  TextEditingController? passwordTextController;
  FocusNode? confirmationFocusNode;
  TextEditingController? confirmationTextController;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    passwordFocusNode?.dispose();
    passwordTextController?.dispose();
    confirmationFocusNode?.dispose();
    confirmationTextController?.dispose();
  }
}
