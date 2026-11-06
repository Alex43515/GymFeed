import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:gym_feed/backend/schema/users_record.dart';
import 'package:gym_feed/components/profile_follow_list/profile_follow_list_widget.dart';
import 'package:gym_feed/pages/core_pages/profile/mobile_profile_view.dart';

class _ProfileReference implements DocumentReference<Map<String, dynamic>> {
  @override
  String get id => 'profile-reference';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _IdleSocket implements WebSocketChannel, WebSocketSink {
  final _incoming = StreamController<dynamic>();

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  WebSocketSink get sink => this;

  @override
  Future<void> get ready => Future.value();

  @override
  void add(dynamic data) {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    unawaited(_incoming.close());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('own and other profiles reopen each tab and both follow lists',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    addTearDown(() => GoogleFonts.config.allowRuntimeFetching = true);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final requests = <Uri>[];
    final app = (await tester.runAsync(() => Supabase.initialize(
          url: 'https://example.test',
          anonKey: 'test-key',
          authOptions: const FlutterAuthClientOptions(
            autoRefreshToken: false,
            detectSessionInUri: false,
            localStorage: EmptyLocalStorage(),
          ),
          realtimeClientOptions: RealtimeClientOptions(
            transport: (_, __) => _IdleSocket(),
            timeout: const Duration(milliseconds: 50),
          ),
          httpClient: MockClient((request) async {
            requests.add(request.url);
            final rows = request.url.path.endsWith('/profiles')
                ? [
                    {'id': 'other', 'username': 'athlete'}
                  ]
                : [];
            return http.Response(jsonEncode(rows), 200,
                request: request,
                headers: {
                  'content-type': 'application/json',
                  'content-range': '*/0',
                });
          }),
        )))!;
    addTearDown(app.dispose);

    for (final isSelf in [false, true]) {
      final userId = isSelf ? 'self' : 'other';
      final profile = UsersRecord.getDocumentFromData(
        {'uid': userId, 'username': userId},
        _ProfileReference(),
      );
      await tester.pumpWidget(MaterialApp(
        home: MobileProfileView(
          profile: profile,
          isSelf: isSelf,
          followerCount: 0,
          followingCount: 0,
        ),
      ));
      await tester.pumpAndSettle();

      for (final (index, emptyLabel) in [
        (1, 'No tagged posts yet'),
        (2, 'No workouts yet'),
        (
          3,
          isSelf
              ? 'Create a plan in Train → Training plans'
              : 'No training plans yet'
        ),
        (0, 'No posts yet'),
        (1, 'No tagged posts yet'),
        (2, 'No workouts yet'),
        (0, 'No posts yet'),
      ]) {
        await tester.tap(find.byKey(Key('profile-tab-$index')));
        await tester.pumpAndSettle();
        expect(find.text(emptyLabel), findsOneWidget,
            reason: '$userId tab $index. Visible labels: '
                '${tester.widgetList<Text>(find.byType(Text)).map((text) => text.data)}. '
                'Requests: $requests');
        expect(tester.takeException(), isNull);
      }

      for (final (label, initialTab, emptyLabel) in [
        ('Followers', 0, 'No followers yet'),
        ('Following', 1, 'Not following anyone yet'),
      ]) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        final list = tester.widget<ProfileFollowListWidget>(
          find.byType(ProfileFollowListWidget),
        );
        expect(list.userId, userId);
        expect(list.initialTab, initialTab);
        expect(find.text(emptyLabel).hitTestable(), findsOneWidget);
        await tester
            .tap(find.byIcon(Icons.arrow_back_ios_new_rounded).hitTestable());
        await tester.pumpAndSettle();
      }

      expect(
          requests.where((uri) =>
              uri.path.endsWith('/posts') &&
              uri.queryParameters['user_id'] == 'eq.$userId'),
          hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    }
  });
}
