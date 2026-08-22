import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('notification migration removes legacy producers and guards events', () {
    final sql = File(
      'supabase/migrations/0022_notification_idempotency.sql',
    ).readAsStringSync();

    expect(sql, contains('drop trigger if exists post_likes_notify'));
    expect(sql, contains('drop trigger if exists follows_notify'));
    expect(sql, contains('drop trigger if exists comments_notify'));
    expect(sql, contains("set type = 'like'"));
    expect(sql, contains('ranked.duplicate_number > 1'));
    expect(sql, contains('source_transaction_id'));
    expect(sql, contains('suppress_duplicate_social_notification_insert'));
    expect(sql, contains('on conflict do nothing'));
  });
}
