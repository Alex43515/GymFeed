// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:qr_bar_code/code/code.dart';
import 'package:qr_bar_code/qr/qr.dart';

class GenerateQRCode extends StatefulWidget {
  const GenerateQRCode(
      {Key? key,
      this.width,
      this.height,
      required this.data,
      required this.eyeStyleColor,
      required this.dataStyleColor,
      this.isSquare = true})
      : super(key: key);

  final double? width;
  final double? height;
  final String data;
  final Color eyeStyleColor;
  final Color dataStyleColor;
  final bool isSquare;

  @override
  _GenerateQRCodeState createState() => _GenerateQRCodeState();
}

class _GenerateQRCodeState extends State<GenerateQRCode> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        QRCode(
          data: widget.data,
          eyeStyle: QREyeStyle(
              color: widget.eyeStyleColor,
              eyeShape:
                  widget.isSquare ? QREyeShape.square : QREyeShape.circle),
          dataModuleStyle: QRDataModuleStyle(
              color: widget.dataStyleColor,
              dataModuleShape: widget.isSquare
                  ? QRDataModuleShape.square
                  : QRDataModuleShape.circle),
        ),
      ],
    );
  }
}
