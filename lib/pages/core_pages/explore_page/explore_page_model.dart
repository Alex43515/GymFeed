import '/backend/backend.dart';
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
  // State field(s) for GridView widget.

  PagingController<DocumentSnapshot?, PostsRecord>? gridViewPagingController1;
  Query? gridViewPagingQuery1;

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  List<PostsRecord> simpleSearchResults2 = [];
  // State field(s) for GridView widget.

  PagingController<DocumentSnapshot?, PostsRecord>? gridViewPagingController3;
  Query? gridViewPagingQuery3;

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode3;
  TextEditingController? textController3;
  String? Function(BuildContext, String?)? textController3Validator;
  List<UsersRecord> simpleSearchResults3 = [];
  // State field(s) for ListView widget.

  PagingController<DocumentSnapshot?, UsersRecord>? listViewPagingController1;
  Query? listViewPagingQuery1;

  // Model for NavBar component.
  late NavBarModel navBarModel;

  @override
  void initState(BuildContext context) {
    navBarModel = createModel(context, () => NavBarModel());
  }

  @override
  void dispose() {
    tabBarController?.dispose();
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    gridViewPagingController1?.dispose();

    textFieldFocusNode2?.dispose();
    textController2?.dispose();

    gridViewPagingController3?.dispose();

    textFieldFocusNode3?.dispose();
    textController3?.dispose();

    listViewPagingController1?.dispose();

    navBarModel.dispose();
  }

  /// Additional helper methods.
  PagingController<DocumentSnapshot?, PostsRecord> setGridViewController1(
    Query query, {
    DocumentReference<Object?>? parent,
  }) {
    gridViewPagingController1 ??= _createGridViewController1(query, parent);
    if (gridViewPagingQuery1 != query) {
      gridViewPagingQuery1 = query;
      gridViewPagingController1?.refresh();
    }
    return gridViewPagingController1!;
  }

  PagingController<DocumentSnapshot?, PostsRecord> _createGridViewController1(
    Query query,
    DocumentReference<Object?>? parent,
  ) {
    final controller =
        PagingController<DocumentSnapshot?, PostsRecord>(firstPageKey: null);
    return controller
      ..addPageRequestListener(
        (nextPageMarker) => queryPostsRecordPage(
          queryBuilder: (_) => gridViewPagingQuery1 ??= query,
          nextPageMarker: nextPageMarker,
          controller: controller,
          pageSize: 5,
          isStream: false,
        ),
      );
  }

  PagingController<DocumentSnapshot?, PostsRecord> setGridViewController3(
    Query query, {
    DocumentReference<Object?>? parent,
  }) {
    gridViewPagingController3 ??= _createGridViewController3(query, parent);
    if (gridViewPagingQuery3 != query) {
      gridViewPagingQuery3 = query;
      gridViewPagingController3?.refresh();
    }
    return gridViewPagingController3!;
  }

  PagingController<DocumentSnapshot?, PostsRecord> _createGridViewController3(
    Query query,
    DocumentReference<Object?>? parent,
  ) {
    final controller =
        PagingController<DocumentSnapshot?, PostsRecord>(firstPageKey: null);
    return controller
      ..addPageRequestListener(
        (nextPageMarker) => queryPostsRecordPage(
          queryBuilder: (_) => gridViewPagingQuery3 ??= query,
          nextPageMarker: nextPageMarker,
          controller: controller,
          pageSize: 5,
          isStream: false,
        ),
      );
  }

  PagingController<DocumentSnapshot?, UsersRecord> setListViewController1(
    Query query, {
    DocumentReference<Object?>? parent,
  }) {
    listViewPagingController1 ??= _createListViewController1(query, parent);
    if (listViewPagingQuery1 != query) {
      listViewPagingQuery1 = query;
      listViewPagingController1?.refresh();
    }
    return listViewPagingController1!;
  }

  PagingController<DocumentSnapshot?, UsersRecord> _createListViewController1(
    Query query,
    DocumentReference<Object?>? parent,
  ) {
    final controller =
        PagingController<DocumentSnapshot?, UsersRecord>(firstPageKey: null);
    return controller
      ..addPageRequestListener(
        (nextPageMarker) => queryUsersRecordPage(
          queryBuilder: (_) => listViewPagingQuery1 ??= query,
          nextPageMarker: nextPageMarker,
          controller: controller,
          pageSize: 5,
          isStream: false,
        ),
      );
  }
}
