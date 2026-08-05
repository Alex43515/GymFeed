import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'username_widget.dart' show UsernameWidget;
import 'package:flutter/material.dart';

class UsernameModel extends FlutterFlowModel<UsernameWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey2 = GlobalKey<FormState>();
  final formKey1 = GlobalKey<FormState>();
  final formKey3 = GlobalKey<FormState>();
  // State field(s) for FirstName widget.
  FocusNode? firstNameFocusNode;
  TextEditingController? firstNameTextController;
  String? Function(BuildContext, String?)? firstNameTextControllerValidator;
  String? _firstNameTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        '2mmf7vl1' /* Field is required */,
      );
    }

    return null;
  }

  // State field(s) for Bio widget.
  FocusNode? bioFocusNode;
  TextEditingController? bioTextController;
  String? Function(BuildContext, String?)? bioTextControllerValidator;
  String? _bioTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        '3ui1u67g' /* Field is required */,
      );
    }

    return null;
  }

  // State field(s) for Username1 widget.
  FocusNode? username1FocusNode;
  TextEditingController? username1TextController;
  String? Function(BuildContext, String?)? username1TextControllerValidator;
  String? _username1TextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        '8ub9aa54' /* Field is required */,
      );
    }

    return null;
  }

  @override
  void initState(BuildContext context) {
    firstNameTextControllerValidator = _firstNameTextControllerValidator;
    bioTextControllerValidator = _bioTextControllerValidator;
    username1TextControllerValidator = _username1TextControllerValidator;
  }

  @override
  void dispose() {
    firstNameFocusNode?.dispose();
    firstNameTextController?.dispose();

    bioFocusNode?.dispose();
    bioTextController?.dispose();

    username1FocusNode?.dispose();
    username1TextController?.dispose();
  }
}
