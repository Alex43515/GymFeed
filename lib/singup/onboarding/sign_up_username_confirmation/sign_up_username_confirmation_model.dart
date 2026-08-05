import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'sign_up_username_confirmation_widget.dart'
    show SignUpUsernameConfirmationWidget;
import 'package:flutter/material.dart';

class SignUpUsernameConfirmationModel
    extends FlutterFlowModel<SignUpUsernameConfirmationWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for Email_HIDDEN widget.
  FocusNode? emailHIDDENFocusNode;
  TextEditingController? emailHIDDENTextController;
  String? Function(BuildContext, String?)? emailHIDDENTextControllerValidator;
  // State field(s) for Password_HIDDEN widget.
  FocusNode? passwordHIDDENFocusNode;
  TextEditingController? passwordHIDDENTextController;
  late bool passwordHIDDENVisibility;
  String? Function(BuildContext, String?)?
      passwordHIDDENTextControllerValidator;
  // State field(s) for Checkbox widget.
  bool? checkboxValue;

  @override
  void initState(BuildContext context) {
    passwordHIDDENVisibility = false;
  }

  @override
  void dispose() {
    emailHIDDENFocusNode?.dispose();
    emailHIDDENTextController?.dispose();

    passwordHIDDENFocusNode?.dispose();
    passwordHIDDENTextController?.dispose();
  }
}
