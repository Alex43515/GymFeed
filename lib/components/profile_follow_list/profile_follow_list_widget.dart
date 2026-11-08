import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/share_links.dart';
import '/backend/supabase/database/profile.dart';
import '/backend/supabase/repositories/profile_repository.dart';
import '/backend/supabase/supabase_records.dart';
import '/components/follower_componant/follower_componant_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class ProfileFollowListWidget extends StatefulWidget {
  const ProfileFollowListWidget({
    super.key,
    required this.userId,
    this.initialTab = 0,
  });

  final String userId;
  final int initialTab;

  @override
  State<ProfileFollowListWidget> createState() =>
      _ProfileFollowListWidgetState();
}

class _ProfileFollowListWidgetState extends State<ProfileFollowListWidget>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late Future<_FollowLists> _lists;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _lists = _load();
  }

  Future<_FollowLists> _load() async {
    if (widget.userId.isEmpty) return const _FollowLists();
    final values = await Future.wait<dynamic>([
      ProfileRepository().getPublicProfile(widget.userId),
      ProfileRepository().followers(widget.userId, limit: 500),
      ProfileRepository().following(widget.userId, limit: 500),
    ]);
    return _FollowLists(
      owner: values[0] as Profile?,
      followers: values[1] as List<Profile>,
      following: values[2] as List<Profile>,
    );
  }

  Future<void> _reload() async {
    if (!mounted) return;
    final lists = _load();
    setState(() {
      _lists = lists;
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        foregroundColor: FlutterFlowTheme.of(context).primaryText,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: FutureBuilder<_FollowLists>(
          future: _lists,
          builder: (context, snapshot) => Text(
            snapshot.data?.owner?.username.isNotEmpty == true
                ? '@${snapshot.data!.owner!.username}'
                : 'Connections',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          labelColor: FlutterFlowTheme.of(context).primaryText,
          unselectedLabelColor: FlutterFlowTheme.of(context).secondaryText,
          indicatorColor: FlutterFlowTheme.of(context).primary,
          tabs: [
            FutureBuilder<_FollowLists>(
              future: _lists,
              builder: (context, snapshot) => Tab(
                text: '${snapshot.data?.followers.length ?? 0} Followers',
              ),
            ),
            FutureBuilder<_FollowLists>(
              future: _lists,
              builder: (context, snapshot) => Tab(
                text: '${snapshot.data?.following.length ?? 0} Following',
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<_FollowLists>(
        future: _lists,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _Status(
              icon: Icons.cloud_off_rounded,
              label: 'Could not load connections',
              action: _reload,
            );
          }
          final data = snapshot.data ?? const _FollowLists();
          final isOwnList =
              widget.userId.isNotEmpty && widget.userId == currentUserUid;
          return TabBarView(
            controller: _tabs,
            children: [
              _ProfileList(
                profiles: data.followers,
                emptyLabel: 'No followers yet',
                onRelationshipChanged: _reload,
                emptyInvite: isOwnList
                    ? _EmptyInvite(username: data.owner?.username ?? '')
                    : null,
              ),
              _ProfileList(
                profiles: data.following,
                emptyLabel: 'Not following anyone yet',
                onRelationshipChanged: _reload,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileList extends StatelessWidget {
  const _ProfileList({
    required this.profiles,
    required this.emptyLabel,
    required this.onRelationshipChanged,
    this.emptyInvite,
  });

  final List<Profile> profiles;
  final String emptyLabel;
  final Future<void> Function() onRelationshipChanged;

  /// Shown instead of [emptyLabel] on your own empty followers list.
  final Widget? emptyInvite;

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) {
      return emptyInvite ??
          _Status(icon: Icons.people_outline_rounded, label: emptyLabel);
    }
    return RefreshIndicator(
      onRefresh: onRelationshipChanged,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          final profile = profiles[index];
          return FollowerComponantWidget(
            key: ValueKey(profile.id),
            users: supaRef('users', profile.id),
            onRelationshipChanged: onRelationshipChanged,
          );
        },
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.icon, required this.label, this.action});

  final IconData icon;
  final String label;
  final Future<void> Function()? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: FlutterFlowTheme.of(context).secondaryText, size: 34),
          const SizedBox(height: 10),
          Text(label,
              style:
                  TextStyle(color: FlutterFlowTheme.of(context).secondaryText)),
          if (action != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: action, child: const Text('Try again')),
          ],
        ],
      ),
    );
  }
}

/// Empty followers list on your own profile: early, not abandoned.
class _EmptyInvite extends StatelessWidget {
  const _EmptyInvite({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          key: const Key('followers-empty-invite'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded,
                color: theme.secondaryText, size: 34),
            const SizedBox(height: 10),
            Text(
              "You're early. Invite your gym partner while Founding spots last.",
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.primaryText, fontSize: 14),
            ),
            const SizedBox(height: 14),
            Builder(
              builder: (buttonContext) => FilledButton.icon(
                key: const Key('followers-empty-invite-button'),
                onPressed: () {
                  final box = buttonContext.findRenderObject() as RenderBox?;
                  shareGymFeedInvite(
                    username: username,
                    sharePositionOrigin: box == null
                        ? null
                        : box.localToGlobal(Offset.zero) & box.size,
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Invite'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowLists {
  const _FollowLists({
    this.owner,
    this.followers = const <Profile>[],
    this.following = const <Profile>[],
  });

  final Profile? owner;
  final List<Profile> followers;
  final List<Profile> following;
}
