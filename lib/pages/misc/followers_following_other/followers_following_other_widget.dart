import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/components/profile_follow_list/profile_follow_list_widget.dart';

class FollowersFollowingOtherWidget extends StatelessWidget {
  const FollowersFollowingOtherWidget({
    super.key,
    this.userRef,
    int? followersTabIndex,
  }) : followersTabIndex = followersTabIndex ?? 0;

  final DocumentReference? userRef;
  final int followersTabIndex;

  static String routeName = 'FollowersFollowingOther';
  static String routePath = 'followersFollowingOther';

  @override
  Widget build(BuildContext context) => ProfileFollowListWidget(
        userId: userRef?.id ?? '',
        initialTab: followersTabIndex,
      );
}
