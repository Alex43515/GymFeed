import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gym_feed/auth/supabase_auth/account_deletion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('remote failure never clears device data or signs out', () async {
    var cleared = false, signedOut = false;
    await expectLater(
      deleteAccountAndSignOut(
        deleteRemote: () async => throw Exception('network unavailable'),
        clearLocalData: () async {
          cleared = true;
        },
        signOut: () async {
          signedOut = true;
        },
      ),
      throwsException,
    );
    expect(cleared, isFalse);
    expect(signedOut, isFalse);
  });

  test('a 200 response without explicit deletion proof is not success',
      () async {
    var signedOut = false;
    await expectLater(
      deleteAccountAndSignOut(
        deleteRemote: () async =>
            FunctionResponse(status: 200, data: {'ok': true}),
        clearLocalData: () async {},
        signOut: () async {
          signedOut = true;
        },
      ),
      throwsStateError,
    );
    expect(signedOut, isFalse);
  });

  test('confirmed deletion clears local data before local sign-out', () async {
    final calls = <String>[];
    await deleteAccountAndSignOut(
      deleteRemote: () async {
        calls.add('delete');
        return FunctionResponse(status: 200, data: {'deleted': true});
      },
      clearLocalData: () async {
        calls.add('clear');
      },
      signOut: () async {
        calls.add('sign-out');
      },
    );
    expect(calls, ['delete', 'clear', 'sign-out']);
  });

  test('device cleanup preserves another account and unrelated preferences',
      () async {
    SharedPreferences.setMockInitialValues({
      'gymfeed_routines_v1_owner-a': 'private routines',
      'gymfeed_workout_progress_v1_owner-a_routine': 'private progress',
      'gymfeed_chat_seen_v1_owner-a_chat': 'private marker',
      'gymfeed_routines_v1_owner-b': 'keep',
      'ff_signupEmail': 'private@example.invalid',
      'ff_selectedLanguage': true,
    });
    await clearDeletedAccountPreferences('owner-a');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getKeys(),
        {'gymfeed_routines_v1_owner-b', 'ff_selectedLanguage'});
  });
}
