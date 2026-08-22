import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_feed/backend/supabase/repositories/chat_repository.dart';
import 'package:gym_feed/flutter_flow/flutter_flow_util.dart';
import 'package:gym_feed/flutter_flow/upload_data.dart';
import 'package:gym_feed/pages/messages/message_media_pipeline.dart';
import 'package:gym_feed/pages/messages/messaging_shared.dart';

void main() {
  group('Supabase chat message compatibility', () {
    test('reads the deployed chat_messages column names', () {
      final message = ChatMessage({
        'id': 'message-1',
        'chat_id': 'chat-1',
        'user_id': 'user-1',
        'text': 'Strong session today',
        'image_url': 'https://example.com/photo.jpg',
        'video_url': '',
        'created_at': '2026-08-10T18:42:00Z',
      });

      expect(message.id, 'message-1');
      expect(message.chatId, 'chat-1');
      expect(message.senderId, 'user-1');
      expect(message.body, 'Strong session today');
      expect(message.imageUrl, 'https://example.com/photo.jpg');
      expect(message.previewText, 'Strong session today');
    });

    test('recognizes a video attachment and presents a video preview', () {
      final message = ChatMessage({
        'id': 'message-video',
        'video_url': 'https://stream.example.com/video/playlist.m3u8',
      });

      expect(message.videoUrl, endsWith('playlist.m3u8'));
      expect(message.previewText, 'Video');
    });

    test('decodes workout shares without exposing the transport marker', () {
      final message = ChatMessage({
        'text':
            '__gymfeed_share__:{"type":"workout","title":"Push Day A","routine":{"name":"Push Day A","exercises":[]}}',
      });

      expect(message.isShare, isTrue);
      expect(message.sharePayload['type'], 'workout');
      expect(message.sharePayload['title'], 'Push Day A');
      expect(message.previewText, 'Shared a workout');
    });

    test('recognizes hidden reactions and compatibility read receipts', () {
      final reaction = ChatMessage({
        'text': '__gymfeed_reaction__:{"message_id":"message-1","emoji":"❤"}',
      });
      final receipt = ChatMessage({
        'text': '__gymfeed_read__:{"read_at":"2026-08-10T18:42:00Z"}',
      });

      expect(reaction.isReaction, isTrue);
      expect(reaction.reactionPayload['message_id'], 'message-1');
      expect(receipt.isReadReceipt, isTrue);
      expect(receipt.previewText, isEmpty);
    });
  });

  group('Message video compression boundary', () {
    test('always sends the local video path through the compressor', () async {
      String? receivedPath;
      final result = await compressSelectedMessageVideo(
        SelectedFile(
          storagePath: 'messages/chat/video.mp4',
          filePath: '/gallery/original.mov',
          bytes: Uint8List.fromList([9, 9, 9]),
        ),
        compressor: (path) async {
          receivedPath = path;
          return FFUploadedFile(
            name: 'compressed.mp4',
            bytes: Uint8List.fromList([1, 2, 3]),
          );
        },
      );

      expect(receivedPath, '/gallery/original.mov');
      expect(result.name, 'compressed.mp4');
      expect(result.bytes, [1, 2, 3]);
    });

    test('rejects a video that cannot be compressed from a local file', () {
      expect(
        () => compressSelectedMessageVideo(
          SelectedFile(bytes: Uint8List.fromList([1])),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('Messaging presentation helpers', () {
    test('uses display name, then username, then a safe fallback', () {
      expect(messageDisplayName('Coach Mike', 'coach_mike'), 'Coach Mike');
      expect(messageDisplayName('', 'coach_mike'), 'coach_mike');
      expect(messageDisplayName('', ''), 'GymFeed member');
    });

    testWidgets('avatar renders a fallback initial and online marker',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: messageBackground,
            body: MessageAvatar(
              displayName: 'Nina Petrović',
              username: 'nina.lifts',
              photoUrl: '',
              online: true,
            ),
          ),
        ),
      );

      expect(find.text('N'), findsOneWidget);
      expect(find.byType(MessageAvatar), findsOneWidget);
    });
  });
}
