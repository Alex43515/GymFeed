import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/backend/supabase/repositories/chat_repository.dart';
import '/backend/supabase/repositories/profile_repository.dart';
import '/backend/supabase/supabase_records.dart';
import '/components/blocked/blocked_widget.dart';
import '/components/content_safety/blocked_account_view.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '../profile/mobile_profile_view.dart';

class ProfileOtherWidget extends StatefulWidget {
  const ProfileOtherWidget({super.key, this.username});

  final String? username;

  static String routeName = 'ProfileOther';
  static String routePath = 'profileOther';

  @override
  State<ProfileOtherWidget> createState() => _ProfileOtherWidgetState();
}

class _ProfileOtherWidgetState extends State<ProfileOtherWidget> {
  late Future<void> _loading;
  UsersRecord? _profile;
  String _targetUserId = '';
  AccountBlockRelationship _blockRelationship = AccountBlockRelationship.none;
  bool _isFollowing = false;
  bool _followBusy = false;
  int _followerCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loading = _load();
  }

  Future<void> _load() async {
    final row = await ProfileRepository()
        .getPublicProfileByUsername(widget.username ?? '');
    if (row == null) return;
    _targetUserId = row.id;
    _profile = UsersRecord.fromSupabase(row.data);
    _blockRelationship =
        await ProfileRepository().blockRelationship(_targetUserId);
    if (_blockRelationship == AccountBlockRelationship.none) {
      final social = await ProfileRepository().socialState(_targetUserId);
      _isFollowing = social.isFollowing;
      _followerCount = social.followerCount;
      _followingCount = social.followingCount;
    }
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _profile = null;
      _blockRelationship = AccountBlockRelationship.none;
      _loading = _load();
    });
  }

  Future<void> _toggleFollow() async {
    if (_targetUserId.isEmpty || _followBusy) return;
    final wasFollowing = _isFollowing;
    setState(() {
      _followBusy = true;
      _isFollowing = !wasFollowing;
      _followerCount =
          (_followerCount + (wasFollowing ? -1 : 1)).clamp(0, 1 << 30);
    });
    try {
      if (wasFollowing) {
        await ProfileRepository().unfollow(_targetUserId);
      } else {
        await ProfileRepository().follow(_targetUserId);
      }
      final fresh = await ProfileRepository().socialState(_targetUserId);
      if (mounted) {
        setState(() {
          _isFollowing = fresh.isFollowing;
          _followerCount = fresh.followerCount;
          _followingCount = fresh.followingCount;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isFollowing = wasFollowing;
          _followerCount =
              (_followerCount + (wasFollowing ? 1 : -1)).clamp(0, 1 << 30);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update follow. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  Future<void> _message() async {
    try {
      final chatId =
          await ChatRepository().getOrCreateDirectChat(_targetUserId);
      if (!mounted) return;
      context.pushNamed(
        IndividualMessageWidget.routeName,
        queryParameters: {
          'chat': serializeParam(
              supaRef('chats', chatId), ParamType.DocumentReference),
        }.withoutNulls,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open messages: $error')),
      );
    }
  }

  Future<void> _showAccountActions() async {
    final profile = _profile;
    if (profile == null) return;
    final blocked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlockedWidget(userDetails: profile),
    );
    if (blocked == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF080808),
            body: Center(
                child: CircularProgressIndicator(color: Color(0xFF0EEA78))),
          );
        }
        if (_blockRelationship != AccountBlockRelationship.none) {
          return BlockedAccountView(
            relationship: _blockRelationship,
            account: _profile,
            onBack: () => context.safePop(),
            onUnblocked: _reload,
          );
        }
        final profile = _profile;
        if (profile == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF080808),
            appBar: AppBar(backgroundColor: const Color(0xFF080808)),
            body: const Center(
              child: Text('Profile not found.',
                  style: TextStyle(color: Color(0xFF999999))),
            ),
          );
        }
        return MobileProfileView(
          profile: profile,
          isSelf: false,
          followerCount: _followerCount,
          followingCount: _followingCount,
          isFollowing: _isFollowing,
          followBusy: _followBusy,
          onFollow: _toggleFollow,
          onMessage: _message,
          onMore: _showAccountActions,
          onBack: () => context.safePop(),
        );
      },
    );
  }
}
