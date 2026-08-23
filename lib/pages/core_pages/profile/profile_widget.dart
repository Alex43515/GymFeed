import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/editsettings/editsettings_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'desktop_profile_view.dart';
import 'mobile_profile_view.dart';

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({super.key, int? tabSelector})
      : tabSelector = tabSelector ?? 0;

  final int tabSelector;

  static String routeName = 'Profile';
  static String routePath = 'profilePage';

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  late Future<UsersRecord?> _profile;

  @override
  void initState() {
    super.initState();
    _profile = _loadProfile();
  }

  Future<UsersRecord?> _loadProfile() async {
    final reference = currentUserReference;
    if (reference == null) return null;
    return UsersRecord.getDocumentOnce(reference);
  }

  void _refreshProfile() {
    if (!mounted) return;
    setState(() => _profile = _loadProfile());
  }

  Future<void> _showSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: MediaQuery.viewInsetsOf(context),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: const EditsettingsWidget(),
        ),
      ),
    );
    _refreshProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && MediaQuery.sizeOf(context).width >= 720) {
      return const DesktopProfileView();
    }
    return FutureBuilder<UsersRecord?>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF080808),
            body: Center(
                child: CircularProgressIndicator(color: Color(0xFF0EEA78))),
          );
        }
        final profile = snapshot.data;
        if (profile == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF080808),
            body: Center(
              child: FilledButton(
                onPressed: () => context.goNamed(LoginWidget.routeName),
                child: const Text('Sign in'),
              ),
            ),
          );
        }
        return MobileProfileView(
          profile: profile,
          isSelf: true,
          initialTab: widget.tabSelector,
          onEdit: () async {
            await context.pushNamed(EditProfileWidget.routeName);
            _refreshProfile();
          },
          onShare: () => Share.share(
            'View @${profile.username} on GymFeed\n'
            'https://gymfeed.io/u/${Uri.encodeComponent(profile.username)}',
            subject: '${profile.displayName} on GymFeed',
          ),
          onMore: _showSettings,
        );
      },
    );
  }
}
