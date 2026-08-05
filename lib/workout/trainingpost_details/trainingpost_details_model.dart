import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'trainingpost_details_widget.dart' show TrainingpostDetailsWidget;
import 'package:flutter/material.dart';

class TrainingpostDetailsModel
    extends FlutterFlowModel<TrainingpostDetailsWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for GoogleMap widget.
  LatLng? googleMapsCenter;
  final googleMapsController = Completer<GoogleMapController>();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
