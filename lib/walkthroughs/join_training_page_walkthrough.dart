import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '/components/walkthrough_widget/walkthrough_widget_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';

// Focus widget keys for this walkthrough
final tabIlmrpg51 = GlobalKey();
final tabU7idje8g = GlobalKey();
final tabOsdyqgis = GlobalKey();
final iconCps4idz8 = GlobalKey();

/// Join Training Page Walkthrough
///
///
List<TargetFocus> createWalkthroughTargets(BuildContext context) => [
      /// Step 1
      TargetFocus(
        keyTarget: tabIlmrpg51,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        color: Colors.black,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, __) => WalkthroughWidgetWidget(
              walkthroughExplanation: FFLocalizations.of(context).getText(
                'hwgngl7b' /* Workouts that you have joined. */,
              ),
            ),
          ),
        ],
      ),

      /// Step 2
      TargetFocus(
        keyTarget: tabU7idje8g,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        color: Colors.black,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, __) => WalkthroughWidgetWidget(
              walkthroughExplanation: FFLocalizations.of(context).getText(
                'u2dty5mv' /* Workouts that you have created... */,
              ),
            ),
          ),
        ],
      ),

      /// Step 3
      TargetFocus(
        keyTarget: tabOsdyqgis,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        color: Colors.black,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, __) => WalkthroughWidgetWidget(
              walkthroughExplanation: FFLocalizations.of(context).getText(
                'vdvlkmci' /* Create you own custom workout ... */,
              ),
            ),
          ),
        ],
      ),

      /// Step 4
      TargetFocus(
        keyTarget: iconCps4idz8,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        color: Colors.black,
        contents: [
          TargetContent(
            align: ContentAlign.left,
            builder: (context, __) => WalkthroughWidgetWidget(
              walkthroughExplanation: FFLocalizations.of(context).getText(
                'ijn5uj3i' /* Create your new training today... */,
              ),
            ),
          ),
        ],
      ),
    ];
