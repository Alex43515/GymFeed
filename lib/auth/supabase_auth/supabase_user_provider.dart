import '/backend/supabase/supabase.dart';
import '../base_auth_user_provider.dart';
import 'email_verification_service.dart';

export '../base_auth_user_provider.dart';

/// Supabase-backed implementation of the app's provider-agnostic auth user.
/// Mirrors GymFeedFirebaseUser so the rest of the app keeps using `currentUser`.
class SupabaseAuthUser extends BaseAuthUser {
  SupabaseAuthUser(this.user, {this.hasSession = true});

  final User? user;
  final bool hasSession;

  @override
  bool get loggedIn => user != null && hasSession;

  @override
  bool get emailVerified => user?.emailConfirmedAt != null;

  @override
  AuthUserInfo get authUserInfo => AuthUserInfo(
        uid: user?.id,
        email: user?.email,
        displayName: (user?.userMetadata?['full_name'] ??
            user?.userMetadata?['display_name']) as String?,
        photoUrl: (user?.userMetadata?['avatar_url'] ??
            user?.userMetadata?['photo_url']) as String?,
        phoneNumber: user?.phone,
      );

  @override
  Future? delete() async {
    // Client cannot delete its own auth row; the delete-account Edge Function
    // (service role) purges DB + storage + Bunny, then we sign out locally.
    try {
      await supabase.functions.invoke('delete-account');
    } catch (_) {
      // Function not deployed yet / offline — fall through to sign-out.
    }
    await supabase.auth.signOut();
  }

  @override
  Future? updateEmail(String email) =>
      supabase.auth.updateUser(UserAttributes(email: email));

  @override
  Future? updatePassword(String newPassword) =>
      supabase.auth.updateUser(UserAttributes(password: newPassword));

  @override
  Future? sendEmailVerification() async {
    final email = user?.email;
    if (email == null) return;
    await supabase.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: emailVerificationRedirectUrl(),
    );
  }

  @override
  Future refreshUser() => supabase.auth.refreshSession();
}

/// Stream that keeps the global `currentUser` in sync with the Supabase session.
/// main.dart listens to this exactly like it did `gymFeedFirebaseUserStream()`.
Stream<BaseAuthUser> gymFeedSupabaseUserStream() {
  // Seed synchronously from any restored session so the first frame is correct.
  currentUser = SupabaseAuthUser(
    supabase.auth.currentUser,
    hasSession: supabase.auth.currentSession != null,
  );
  return supabase.auth.onAuthStateChange.map<BaseAuthUser>((data) {
    currentUser = SupabaseAuthUser(data.session?.user);
    return currentUser!;
  });
}
