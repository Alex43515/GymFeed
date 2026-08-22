import 'package:flutter/material.dart';

import '/backend/supabase/supabase.dart';
import '/backend/supabase/database/profile.dart';
import '/backend/supabase/repositories/profile_repository.dart';
import 'supabase_auth_manager.dart';

export 'supabase_auth_manager.dart';

final _authManager = SupabaseAuthManager();
SupabaseAuthManager get authManager => _authManager;

/// The current user's loaded profile row (mirrors the old `currentUserDocument`).
Profile? currentUserProfile;
final ValueNotifier<Profile?> _currentUserProfileNotifier =
    ValueNotifier<Profile?>(null);

void _setCurrentUserProfile(Profile? profile) {
  currentUserProfile = profile;
  _currentUserProfileNotifier.value = profile;
}

/// Reload the current profile and its following IDs after an in-app write.
/// Auth-state streams do not emit when a profile row changes, so callers must
/// explicitly refresh after editing a profile or following another user.
Future<Profile?> refreshCurrentUserProfile() async {
  final profile = await ProfileRepository().getMyProfile();
  _setCurrentUserProfile(profile);
  return profile;
}

String get currentUserEmail =>
    currentUserProfile?.email ?? currentUser?.email ?? '';

String get currentUserUid => currentUser?.uid ?? '';

String get currentUserDisplayName =>
    currentUserProfile?.displayName ?? currentUser?.displayName ?? '';

String get currentUserPhoto =>
    currentUserProfile?.photoUrl ?? currentUser?.photoUrl ?? '';

String get currentPhoneNumber =>
    currentUserProfile?.phoneNumber ?? currentUser?.phoneNumber ?? '';

/// Supabase issues a fresh access token on refresh; read the live one on demand.
String get currentJwtToken => supabase.auth.currentSession?.accessToken ?? '';

bool get currentUserEmailVerified => currentUser?.emailVerified ?? false;

/// Emits whenever auth changes, (re)loading the current user's profile — the
/// direct analogue of the Firebase `authenticatedUserStream`.
final authenticatedUserStream = supabase.auth.onAuthStateChange
    .map((data) => data.session)
    .asyncMap<Profile?>((session) async {
  if (session?.user == null) {
    _setCurrentUserProfile(null);
    return null;
  }
  _setCurrentUserProfile(await ProfileRepository().getMyProfile());
  return currentUserProfile;
}).asBroadcastStream();

class AuthUserStreamWidget extends StatelessWidget {
  const AuthUserStreamWidget({Key? key, required this.builder})
      : super(key: key);

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Profile?>(
        valueListenable: _currentUserProfileNotifier,
        builder: (context, _, __) => builder(context),
      );
}
