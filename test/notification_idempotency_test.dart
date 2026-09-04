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

  test('durable sources deduplicate social, chat, and device delivery', () {
    final sql = File(
      'supabase/migrations/0029_notification_source_deduplication.sql',
    ).readAsStringSync();
    final client = File(
      'lib/backend/push_notifications/push_notifications_util.dart',
    ).readAsStringSync();

    for (final sourceIndex in [
      'notifications_like_source_unique',
      'notifications_follow_source_unique',
      'notifications_comment_source_unique',
      'notifications_tag_source_unique',
      'push_queue_source_unique',
      'fcm_tokens_token_unique',
    ]) {
      expect(sql, contains(sourceIndex));
    }
    expect(sql, contains("'chat_message',new.id"));
    expect(sql, contains("'notification',new.id"));
    expect(sql, contains('new.comment_id is null'));
    expect(client, contains('_shownForegroundPushes'));
    expect(client, contains('notificationKey.hashCode'));
    expect(client, contains('getAPNSToken'));
    expect(client, contains('_waitForApnsToken'));
  });
}
