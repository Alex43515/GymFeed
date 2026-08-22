// MIGRATION SHIM — do not delete.
//
// Every widget in the app still imports this file as
//   import '/auth/firebase_auth/auth_util.dart';
// This shim re-exports the Supabase auth layer under exactly the same symbol
// names so the widget layer compiles without modification.
//
// Firebase is kept initialised (see main.dart) to prevent compile/runtime
// crashes in the many widget files that still hold Firestore type imports.
// Actual data access goes through Supabase repositories.

import 'package:cloud_firestore/cloud_firestore.dart';

import '/auth/supabase_auth/auth_util.dart' as _supa;
import '/backend/supabase/database/profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Re-export every symbol the widget layer needs from the Supabase layer.
// ─────────────────────────────────────────────────────────────────────────────
export '/auth/supabase_auth/auth_util.dart'
    show
        authManager,
        currentUserEmail,
        currentUserUid,
        currentUserDisplayName,
        currentUserPhoto,
        currentPhoneNumber,
        currentJwtToken,
        currentUserEmailVerified,
        refreshCurrentUserProfile,
        authenticatedUserStream,
        AuthUserStreamWidget;

// Export the Supabase auth manager class (replaces FirebaseAuthManager).
export '/auth/supabase_auth/supabase_auth_manager.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Renamed / aliased symbols
// ─────────────────────────────────────────────────────────────────────────────

/// Drop-in for the old `UsersRecord? currentUserDocument`.
/// [Profile] has all the same getter names as the old UsersRecord so widgets
/// using `currentUserDocument?.gptprompt` etc. continue to work.
Profile? get currentUserDocument => _supa.currentUserProfile;

/// Firestore DocumentReference for auth checks and legacy Firestore writes.
/// Writes go to the empty Firebase project (harmless on clean slate).
/// Returns null when not logged in — same semantics as the Firebase original.
DocumentReference? get currentUserReference {
  final uid = _supa.currentUserUid;
  if (uid.isEmpty) return null;
  return FirebaseFirestore.instance.doc('users/$uid');
}

/// Satisfies `jwtTokenStream.listen((_) {})` in main.dart.
/// Supabase handles access-token refresh automatically; the stream is only
/// needed so the listen call doesn't break compilation.
final Stream<dynamic> jwtTokenStream =
    _supa.authenticatedUserStream.map<dynamic>((_) => null).asBroadcastStream();
