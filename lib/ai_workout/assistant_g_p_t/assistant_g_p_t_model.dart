import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'assistant_g_p_t_widget.dart' show AssistantGPTWidget;
import 'package:flutter/material.dart';

class AssistantGPTModel extends FlutterFlowModel<AssistantGPTWidget> {
  ///  Local state fields for this page.

  List<ContentStruct> chatHostpry = [];
  void addToChatHostpry(ContentStruct item) => chatHostpry.add(item);
  void removeFromChatHostpry(ContentStruct item) => chatHostpry.remove(item);
  void removeAtIndexFromChatHostpry(int index) => chatHostpry.removeAt(index);
  void insertAtIndexInChatHostpry(int index, ContentStruct item) =>
      chatHostpry.insert(index, item);
  void updateChatHostpryAtIndex(int index, Function(ContentStruct) updateFn) =>
      chatHostpry[index] = updateFn(chatHostpry[index]);

  String threadId = 'pusiga';

  String runId = 'pusiga';

  String status = 'pusiga';

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (threads)] action in assistantGPT widget.
  ApiCallResponse? apiThreadsResult;
  // State field(s) for ScollingChatColumn widget.
  ScrollController? scollingChatColumn;
  // State field(s) for ChatListView widget.
  ScrollController? chatListView;
  // State field(s) for QuestionTestField widget.
  FocusNode? questionTestFieldFocusNode;
  TextEditingController? questionTestFieldTextController;
  String? Function(BuildContext, String?)?
      questionTestFieldTextControllerValidator;
  // Stores action output result for [Backend Call - API (message)] action in SubmitIconButton widget.
  ApiCallResponse? apiMessageCreateResult;
  // Stores action output result for [Backend Call - API (run)] action in SubmitIconButton widget.
  ApiCallResponse? apiAssistantRunResult;
  // Stores action output result for [Backend Call - API (retrieverun)] action in SubmitIconButton widget.
  ApiCallResponse? apiRetrieveRunResult;
  // Stores action output result for [Backend Call - API (messages)] action in SubmitIconButton widget.
  ApiCallResponse? apiGetMessagesResult;
  // State field(s) for alwayspopulated widget.
  FocusNode? alwayspopulatedFocusNode;
  TextEditingController? alwayspopulatedTextController;
  String? Function(BuildContext, String?)?
      alwayspopulatedTextControllerValidator;

  @override
  void initState(BuildContext context) {
    scollingChatColumn = ScrollController();
    chatListView = ScrollController();
  }

  @override
  void dispose() {
    scollingChatColumn?.dispose();
    chatListView?.dispose();
    questionTestFieldFocusNode?.dispose();
    questionTestFieldTextController?.dispose();

    alwayspopulatedFocusNode?.dispose();
    alwayspopulatedTextController?.dispose();
  }
}
