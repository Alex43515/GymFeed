import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> clearDeletedAccountPreferences(String userId) async {
  final preferences = await SharedPreferences.getInstance();
  final keys = preferences.getKeys().where((key) =>
      key.startsWith('gymfeed_') &&
      (key.endsWith('_$userId') || key.contains('_${userId}_')));
  for (final key in keys.toList()) {
    if (!await preferences.remove(key)) {
      throw StateError('Could not clear device data.');
    }
  }
  for (final key in [
    'ff_signupEmail',
    'ff_pendingVerificationEmail',
    'ff_signupName',
    'ff_signupUsername',
    'ff_assistantId',
  ]) {
    if (!await preferences.remove(key)) {
      throw StateError('Could not clear device data.');
    }
  }
}

Future<void> deleteAccountAndSignOut({
  required Future<FunctionResponse> Function() deleteRemote,
  required Future<void> Function() clearLocalData,
  required Future<void> Function() signOut,
}) async {
  final response = await deleteRemote();
  if (response.status != 200 ||
      response.data is! Map ||
      response.data['deleted'] != true) {
    throw StateError(
        'Deletion was not confirmed. Your account was not deleted.');
  }
  try {
    await clearLocalData();
  } catch (_) {
    throw StateError('Your account was deleted, but device data could not be '
        'cleared. Clear GymFeed app storage in your device settings.');
  } finally {
    await signOut();
  }
}
