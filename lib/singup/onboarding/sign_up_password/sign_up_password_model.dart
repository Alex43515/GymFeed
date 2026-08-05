import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'sign_up_password_widget.dart' show SignUpPasswordWidget;
import 'package:flutter/material.dart';

class SignUpPasswordModel extends FlutterFlowModel<SignUpPasswordWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for Password widget.
  FocusNode? passwordFocusNode;
  TextEditingController? passwordTextController;
  late bool passwordVisibility;
  String? Function(BuildContext, String?)? passwordTextControllerValidator;
  String? _passwordTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'srvzmhfv' /* Password is required. */,
      );
    }

    return null;
  }

  @override
  void initState(BuildContext context) {
    passwordVisibility = false;
    passwordTextControllerValidator = _passwordTextControllerValidator;
  }

  @override
  void dispose() {
    passwordFocusNode?.dispose();
    passwordTextController?.dispose();
  }
}
