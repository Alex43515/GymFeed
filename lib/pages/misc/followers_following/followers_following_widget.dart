import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/components/profile_follow_list/profile_follow_list_widget.dart';

class FollowersFollowingWidget extends StatelessWidget {
  const FollowersFollowingWidget({
    super.key,
    int? followersTabIndex,
  }) : followersTabIndex = followersTabIndex ?? 0;

  final int followersTabIndex;

  static String routeName = 'FollowersFollowing';
  static String routePath = 'followersFollowing';

  @override
  Widget build(BuildContext context) => ProfileFollowListWidget(
        userId: currentUserUid,
        initialTab: followersTabIndex,
      );
}
