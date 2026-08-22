import '/backend/backend.dart';
import '/backend/supabase/supabase.dart';
import '/backend/supabase/repositories/profile_repository.dart';
import '/components/nav_bar/nav_bar_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'explore_page_widget.dart' show ExplorePageWidget;
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class ExplorePageModel extends FlutterFlowModel<ExplorePageWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  List<PostsRecord> simpleSearchResults1 = [];

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  List<PostsRecord> simpleSearchResults2 = [];

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode3;
  TextEditingController? textController3;
  String? Function(BuildContext, String?)? textController3Validator;
  List<UsersRecord> simpleSearchResults3 = [];

  // Paging controllers are STATIC so the loaded grids/list survive navigating
  // away from Explore and back (nav uses goNamed → rebuilds the page). Without
  // this, every return refetched all three lists — the same lag the feed had.
  static PagingController<DateTime?, PostsRecord>? _sharedGrid1;
  static PagingController<DateTime?, PostsRecord>? _sharedGrid3;
  static PagingController<int?, UsersRecord>? _sharedUsers;

  PagingController<DateTime?, PostsRecord>? get gridViewPagingController1 =>
      _sharedGrid1;
  PagingController<DateTime?, PostsRecord>? get gridViewPagingController3 =>
      _sharedGrid3;
  PagingController<int?, UsersRecord>? get listViewPagingController1 =>
      _sharedUsers;

  // Model for NavBar component.
  late NavBarModel navBarModel;

  static const int _pageSize = 25;

  @override
  void initState(BuildContext context) {
    navBarModel = createModel(context, () => NavBarModel());
  }

  @override
  void dispose() {
    tabBarController?.dispose();
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    textFieldFocusNode2?.dispose();
    textController2?.dispose();

    textFieldFocusNode3?.dispose();
    textController3?.dispose();

    // Deliberately NOT disposing the shared paging controllers — they persist
    // for the session so returning to Explore is instant.
    navBarModel.dispose();
  }

  // ── Post grids (discovery) ────────────────────────────────────────────────
  // The `query` argument is accepted for generated-call compatibility but the
  // grids now show recent Supabase posts.

  PagingController<DateTime?, PostsRecord> setGridViewController1(
    Query query, {
    DocumentReference<Object?>? parent,
  }) {
    _sharedGrid1 ??= _createPostsController();
    return _sharedGrid1!;
  }

  PagingController<DateTime?, PostsRecord> setGridViewController3(
    Query query, {
    DocumentReference<Object?>? parent,
  }) {
    _sharedGrid3 ??= _createPostsController();
    return _sharedGrid3!;
  }

  PagingController<DateTime?, PostsRecord> _createPostsController() {
    final controller =
        PagingController<DateTime?, PostsRecord>(firstPageKey: null);
    return controller
      ..addPageRequestListener((pageKey) async {
        try {
          var q = supabase.from('posts').select().eq('deleted', false);
          if (pageKey != null) {
            q = q.lt('created_at', pageKey.toUtc().toIso8601String());
          }
          final rows =
              await q.order('created_at', ascending: false).limit(_pageSize);
          final items = (rows as List)
              .map((r) => PostsRecord.fromSupabase(r as Map<String, dynamic>))
              .toList();
          if (items.length < _pageSize) {
            controller.appendLastPage(items);
          } else {
            controller.appendPage(items, items.last.timePosted);
          }
        } catch (e) {
          controller.error = e;
        }
      });
  }

  // ── User list ─────────────────────────────────────────────────────────────

  PagingController<int?, UsersRecord> setListViewController1(
    Query query, {
    DocumentReference<Object?>? parent,
  }) {
    _sharedUsers ??= _createUsersController();
    return _sharedUsers!;
  }

  PagingController<int?, UsersRecord> _createUsersController() {
    final controller = PagingController<int?, UsersRecord>(firstPageKey: 0);
    return controller
      ..addPageRequestListener((pageKey) async {
        try {
          final offset = pageKey ?? 0;
          final rows = await supabase
              .from('profiles')
              .select('*')
              .range(offset, offset + _pageSize - 1);
          final rawItems = (rows as List)
              .map((r) => UsersRecord.fromSupabase(r as Map<String, dynamic>))
              .toList();
          final visibility = await Future.wait(rawItems.map(
            (profile) =>
                ProfileRepository().canViewAccount(profile.reference.id),
          ));
          final items = <UsersRecord>[
            for (var i = 0; i < rawItems.length; i++)
              if (visibility[i]) rawItems[i],
          ];
          if (rawItems.length < _pageSize) {
            controller.appendLastPage(items);
          } else {
            controller.appendPage(items, offset + rawItems.length);
          }
        } catch (e) {
          controller.error = e;
        }
      });
  }
}
