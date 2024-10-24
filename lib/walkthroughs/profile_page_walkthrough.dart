import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '/components/walkthrough_widget/walkthrough_widget_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';

// Focus widget keys for this walkthrough
final column16p5s599 = GlobalKey();

/// Profile Page Walkthrough
///
///
List<TargetFocus> createWalkthroughTargets(BuildContext context) => [
      /// Step 1
      TargetFocus(
        keyTarget: column16p5s599,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        color: Colors.black,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, __) => WalkthroughWidgetWidget(
              walkthroughExplanation: FFLocalizations.of(context).getText(
                'poletj6s' /* By clicking here you can acces... */,
              ),
            ),
          ),
        ],
      ),
    ];
