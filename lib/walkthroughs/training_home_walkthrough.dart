import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '/components/walkthrough_widget/walkthrough_widget_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';

// Focus widget keys for this walkthrough
final iconButtonUnpkyu5g = GlobalKey();
final floatingActionButtonTftpvdst = GlobalKey();

/// Training Home Walkthrough
///
///
List<TargetFocus> createWalkthroughTargets(BuildContext context) => [
      /// Step 1
      TargetFocus(
        keyTarget: iconButtonUnpkyu5g,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        color: Colors.black,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, __) => WalkthroughWidgetWidget(
              walkthroughExplanation: FFLocalizations.of(context).getText(
                'uoxtqdvp' /* Personal machine scanner, meal... */,
              ),
            ),
          ),
        ],
      ),

      /// Step 2
      TargetFocus(
        keyTarget: floatingActionButtonTftpvdst,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        color: Colors.black,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, __) => WalkthroughWidgetWidget(
              walkthroughExplanation: FFLocalizations.of(context).getText(
                'v2pmtg65' /* Click here to view joined trai... */,
              ),
            ),
          ),
        ],
      ),
    ];
