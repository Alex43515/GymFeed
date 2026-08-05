import '/backend/backend.dart';
import '/components/nav_bar/nav_bar_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'dart:async';
import 'feed_widget.dart' show FeedWidget;
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class FeedModel extends FlutterFlowModel<FeedWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for PostFeed widget.

  PagingController<DocumentSnapshot?, PostsRecord>? postFeedPagingController;
  Query? postFeedPagingQuery;

  Completer<UsersRecord>? documentRequestCompleter;
  // Model for NavBar component.
  late NavBarModel navBarModel;

  @override
  void initState(BuildContext context) {
    navBarModel = createModel(context, () => NavBarModel());
  }

  @override
  void dispose() {
    postFeedPagingController?.dispose();

    navBarModel.dispose();
  }

  /// Additional helper methods.
  PagingController<DocumentSnapshot?, PostsRecord> setPostFeedController(
    Query query, {
    DocumentReference<Object?>? parent,
  }) {
    postFeedPagingController ??= _createPostFeedController(query, parent);
    if (postFeedPagingQuery != query) {
      postFeedPagingQuery = query;
      postFeedPagingController?.refresh();
    }
    return postFeedPagingController!;
  }

  PagingController<DocumentSnapshot?, PostsRecord> _createPostFeedController(
    Query query,
    DocumentReference<Object?>? parent,
  ) {
    final controller =
        PagingController<DocumentSnapshot?, PostsRecord>(firstPageKey: null);
    return controller
      ..addPageRequestListener(
        (nextPageMarker) => queryPostsRecordPage(
          queryBuilder: (_) => postFeedPagingQuery ??= query,
          nextPageMarker: nextPageMarker,
          controller: controller,
          pageSize: 5,
          isStream: false,
        ),
      );
  }

  Future waitForDocumentRequestCompleted({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = documentRequestCompleter?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
