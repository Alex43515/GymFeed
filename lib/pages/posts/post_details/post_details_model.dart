import '/flutter_flow/flutter_flow_util.dart';
import '/pages/posts/post/post_widget.dart';
import '/pages/posts/post_food/post_food_widget.dart';
import 'post_details_widget.dart' show PostDetailsWidget;
import 'package:flutter/material.dart';

class PostDetailsModel extends FlutterFlowModel<PostDetailsWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for post component.
  late PostModel postModel;
  // Model for postFood component.
  late PostFoodModel postFoodModel;

  @override
  void initState(BuildContext context) {
    postModel = createModel(context, () => PostModel());
    postFoodModel = createModel(context, () => PostFoodModel());
  }

  @override
  void dispose() {
    postModel.dispose();
    postFoodModel.dispose();
  }
}
