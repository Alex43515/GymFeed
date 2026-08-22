import '/backend/backend.dart';
import '/backend/supabase/supabase.dart';
import '/components/nav_bar/nav_bar_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'dart:async';
import 'feed_widget.dart' show FeedWidget;
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class FeedModel extends FlutterFlowModel<FeedWidget> {
  ///  State fields for stateful widgets in this page.

  // Backed by the Supabase feed_page() RPC (relevance-ranked, follow-aware,
  // OFFSET-paginated).
  //
  // The controller is STATIC so the already-loaded feed survives navigating
  // away from Home and back (the bottom nav uses goNamed, which rebuilds the
  // page). Without this, every return to Home refetched page 1 and rebuilt the
  // whole list — the 1–2s "lag then everything loads". Now returning is
  // instant; pull-to-refresh gets fresh content.
  static PagingController<int?, PostsRecord>? _sharedController;
  static String? _controllerUserId;
  static final Set<int> _inFlightOffsets = <int>{};

  PagingController<int?, PostsRecord>? get postFeedPagingController =>
      _sharedController;

  Completer<UsersRecord>? documentRequestCompleter;
  // Model for NavBar component.
  late NavBarModel navBarModel;

  static const int _pageSize = 10;

  @override
  void initState(BuildContext context) {
    navBarModel = createModel(context, () => NavBarModel());
  }

  @override
  void dispose() {
    // Deliberately NOT disposing _sharedController — it lives for the session so
    // returning to Home is instant. Only the per-page NavBar model is disposed.
    navBarModel.dispose();
  }

  /// Additional helper methods.
  ///
  /// The [query] argument is accepted for call-site compatibility with the
  /// generated widget but ignored — the feed now comes from Supabase.
  PagingController<int?, PostsRecord> setPostFeedController(
    Query query, {
    DocumentReference<Object?>? parent,
  }) {
    return _ensurePostFeedController();
  }

  /// Starts loading Home's first page while the branded splash is visible.
  /// Attaching the list later reuses the same controller and data.
  static Future<void> warmUp() async {
    final controller = _ensurePostFeedController();
    if (controller.itemList != null || controller.error != null) return;
    await _loadPage(controller, 0);
  }

  static PagingController<int?, PostsRecord> _ensurePostFeedController() {
    final userId = supabase.auth.currentUser?.id;
    if (_sharedController == null || _controllerUserId != userId) {
      _sharedController?.dispose();
      _inFlightOffsets.clear();
      _controllerUserId = userId;
      _sharedController = _createPostFeedController();
    }
    return _sharedController!;
  }

  static PagingController<int?, PostsRecord> _createPostFeedController() {
    final controller = PagingController<int?, PostsRecord>(firstPageKey: 0);
    return controller
      ..addPageRequestListener((pageKey) => _loadPage(controller, pageKey));
  }

  static Future<void> _loadPage(
    PagingController<int?, PostsRecord> controller,
    int? pageKey,
  ) async {
    final offset = pageKey ?? 0;
    if (!_inFlightOffsets.add(offset)) return;
    try {
      final rows = await supabase.rpc('feed_page', params: {
        'p_offset': offset,
        'p_limit': _pageSize,
      });
      final items = (rows as List)
          .map((r) => PostsRecord.fromFeedRow(r as Map<String, dynamic>))
          .toList();
      if (items.length < _pageSize) {
        controller.appendLastPage(items);
      } else {
        controller.appendPage(items, offset + items.length);
      }
    } catch (e) {
      controller.error = e;
    } finally {
      _inFlightOffsets.remove(offset);
    }
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
