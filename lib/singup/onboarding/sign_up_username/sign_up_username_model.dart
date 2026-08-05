import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'sign_up_username_widget.dart' show SignUpUsernameWidget;
import 'package:flutter/material.dart';

class SignUpUsernameModel extends FlutterFlowModel<SignUpUsernameWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for Username widget.
  FocusNode? usernameFocusNode;
  TextEditingController? usernameTextController;
  String? Function(BuildContext, String?)? usernameTextControllerValidator;
  String? _usernameTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'ygh3r1wx' /* Username is required. */,
      );
    }

    return null;
  }

  @override
  void initState(BuildContext context) {
    usernameTextControllerValidator = _usernameTextControllerValidator;
  }

  @override
  void dispose() {
    usernameFocusNode?.dispose();
    usernameTextController?.dispose();
  }
}
