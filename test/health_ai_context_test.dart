import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gym_feed/backend/supabase/repositories/ai_coach_repository.dart';
import 'package:gym_feed/backend/supabase/repositories/coach_plan_actions.dart';
import 'package:gym_feed/backend/supabase/repositories/coach_plan_repository.dart';
import 'package:gym_feed/health/connected_health_controller.dart';
import 'package:gym_feed/health/connected_health_widget.dart';
import 'package:gym_feed/health/health_ai_context.dart';
import 'package:gym_feed/health/health_coach_notice.dart';

final now = DateTime(2026, 10, 14, 12, 30);
final today = DateTime(2026, 10, 14);
final pulseAt = DateTime(2026, 10, 14, 11, 45);

class FakeHealth extends ConnectedHealthGateway {
  HealthAvailability status = HealthAvailability.available;
  int reads = 0;
  int availabilityChecks = 0;
  Completer<HealthAvailability>? availabilityPending;
  Completer<DailyHealthSummary>? pending;
  bool fail = false;
  DailyHealthSummary data = DailyHealthSummary(
      date: today,
      syncedAt: now,
      steps: 6250,
      activeCalories: 320.6,
      heartRate: 75,
      heartRateAt: pulseAt,
      sources: const ['private-device-id']);
  @override
  String get providerName => 'Health Connect';
  @override
  bool get isIOS => false;
  @override
  Future<HealthAvailability> availability() async {
    availabilityChecks++;
    return availabilityPending?.future ?? Future.value(status);
  }

  @override
  Future<DailyHealthSummary> readDay(DateTime date, DateTime now) async {
    reads++;
    expect(date, today);
    if (fail) throw StateError('Do not expose health errors');
    return pending?.future ?? Future.value(data);
  }

  @override
  Future<bool> requestReadAccess() => throw StateError('Chat must not prompt');
  @override
  Future<void> install() async {}
  @override
  Future<bool> openSettings() async => true;
}

const athlete = AiCoachContext(
    profile: {},
    starterPlan: {},
    currentRoutines: [],
    workoutSchedule: {},
    recentWorkouts: [],
    recentMeals: [],
    latestProgress: {});

class NoPendingPlans extends CoachPlanRepository {
  @override
  Future<CoachPlanAction?> latest() async => null;
}

class LocalCoach extends AiCoachRepository {
  LocalCoach(
      {required super.client,
      required super.healthReaderFactory,
      required super.planAssistant,
      required this.rows,
      this.beforeContext})
      : super(plans: NoPendingPlans());
  final List<Map<String, dynamic>> rows;
  final Future<void> Function()? beforeContext;
  @override
  Future<AiCoachContext> loadContext() async {
    await beforeContext?.call();
    return athlete;
  }

  @override
  Future<List<AiCoachMessage>> loadConversation({int limit = 80}) async =>
      rows.map(AiCoachMessage.fromRow).toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late FakeHealth gateway;
  late HealthAiContextReader reader;
  late String currentUid;
  Future<void> consent() async {
    await prefs.setBool(ConnectedHealthController.connectionKey('a'), true);
    await prefs.setBool(ConnectedHealthController.aiConsentKey('a'), true);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    gateway = FakeHealth();
    currentUid = 'a';
    reader = HealthAiContextReader(
        userId: 'a',
        currentUserId: () => currentUid,
        preferences: prefs,
        gateway: gateway,
        clock: () => now);
  });

  test('default is off: no OS availability check, read or permission request',
      () async {
    expect((await reader.readForQuestion()).status, HealthAiStatus.disabled);
    expect(gateway.availabilityChecks, 0);
    expect(gateway.reads, 0);
  });
  test('existing connection does not imply AI consent', () async {
    await prefs.setBool(ConnectedHealthController.connectionKey('a'), true);
    expect((await reader.readForQuestion()).status, HealthAiStatus.disabled);
    expect(gateway.reads, 0);
  });
  test('AI consent without connection cannot read', () async {
    await prefs.setBool(ConnectedHealthController.aiConsentKey('a'), true);
    expect((await reader.readForQuestion()).status, HealthAiStatus.disabled);
    expect(gateway.reads, 0);
  });
  test(
      'fresh minimal daily summary includes units, date and non-live pulse time',
      () async {
    await consent();
    final result = await reader.readForQuestion();
    expect(result.status, HealthAiStatus.ready);
    final json = result.toJson();
    expect(json['local_date'], '2026-10-14');
    expect(json['steps'], 6250);
    expect(json['active_calories_kcal'], 320.6);
    expect(json['latest_heart_rate_bpm'], 75);
    expect(json['heart_rate_recorded_at'], pulseAt.toIso8601String());
    expect(json['heart_rate_is_live'], false);
    expect(jsonEncode(json), isNot(contains('private-device-id')));
    expect(prefs.getKeys(), {
      ConnectedHealthController.connectionKey('a'),
      ConnectedHealthController.aiConsentKey('a')
    });
    expect(prefs.getKeys().every((key) => prefs.get(key) is bool), true);
  });
  test('each question reads again instead of using screen cache', () async {
    await consent();
    expect((await reader.readForQuestion()).summary!.steps, 6250);
    gateway.data = DailyHealthSummary(date: today, syncedAt: now, steps: 7000);
    expect((await reader.readForQuestion()).summary!.steps, 7000);
    expect(gateway.reads, 2);
  });
  test('missing and revoked permissions stay unknown, never fabricated zeroes',
      () async {
    await consent();
    gateway.data = DailyHealthSummary(date: today, syncedAt: now);
    final result = await reader.readForQuestion();
    expect(result.status, HealthAiStatus.noData);
    expect(result.toJson()['steps'], isNull);
    expect(result.toJson()['latest_heart_rate_bpm'], isNull);
  });
  test('valid zero steps/calories stay distinct from unavailable pulse',
      () async {
    await consent();
    gateway.data = DailyHealthSummary(
        date: today, syncedAt: now, steps: 0, activeCalories: 0);
    final result = await reader.readForQuestion();
    expect(result.status, HealthAiStatus.ready);
    expect(result.summary!.steps, 0);
    expect(result.summary!.heartRate, null);
  });
  test('invalid numbers and pulse without a valid timestamp are excluded',
      () async {
    await consent();
    gateway.data = DailyHealthSummary(
        date: today,
        syncedAt: now,
        steps: -1,
        activeCalories: double.nan,
        heartRate: 75);
    final result = await reader.readForQuestion();
    expect(result.status, HealthAiStatus.noData);
    expect(() => jsonEncode(result.toJson()), returnsNormally);
  });
  test('yesterday/future pulse timestamps are not presented as today',
      () async {
    await consent();
    for (final time in [
      today.subtract(const Duration(minutes: 1)),
      now.add(const Duration(minutes: 1))
    ]) {
      gateway.data = DailyHealthSummary(
          date: today, syncedAt: now, heartRate: 75, heartRateAt: time);
      expect((await reader.readForQuestion()).summary!.heartRate, null);
    }
    gateway.data = DailyHealthSummary(
        date: today.subtract(const Duration(days: 1)),
        syncedAt: now,
        steps: 12345);
    expect((await reader.readForQuestion()).summary, null);
  });
  test('account isolation prevents reads using another account consent',
      () async {
    await consent();
    currentUid = 'b';
    expect((await reader.readForQuestion()).status, HealthAiStatus.disabled);
    expect(gateway.reads, 0);
  });
  test('withdrawal while native read is pending discards result', () async {
    await consent();
    gateway.pending = Completer<DailyHealthSummary>();
    final result = reader.readForQuestion();
    await Future<void>.delayed(Duration.zero);
    await prefs.remove(ConnectedHealthController.aiConsentKey('a'));
    gateway.pending!.complete(gateway.data);
    expect((await result).status, HealthAiStatus.disabled);
  });
  test('account change while native read is pending discards result', () async {
    await consent();
    gateway.pending = Completer<DailyHealthSummary>();
    final result = reader.readForQuestion();
    await Future<void>.delayed(Duration.zero);
    currentUid = 'b';
    gateway.pending!.complete(gateway.data);
    expect((await result).status, HealthAiStatus.disabled);
  });
  test('unsupported provider or native error does not block normal chat',
      () async {
    await consent();
    gateway.status = HealthAvailability.unsupported;
    expect((await reader.readForQuestion()).status, HealthAiStatus.unavailable);
    expect(gateway.reads, 0);
    gateway.status = HealthAvailability.available;
    gateway.fail = true;
    expect((await reader.readForQuestion()).status, HealthAiStatus.unavailable);
  });
  test('slow native availability times out without starting a late read',
      () async {
    await consent();
    reader = HealthAiContextReader(
        userId: 'a',
        currentUserId: () => currentUid,
        preferences: prefs,
        gateway: gateway,
        clock: () => now,
        timeout: const Duration(milliseconds: 10));
    gateway.availabilityPending = Completer<HealthAvailability>();
    expect((await reader.readForQuestion()).status, HealthAiStatus.unavailable);
    gateway.availabilityPending!.complete(HealthAvailability.available);
    await Future<void>.delayed(Duration.zero);
    expect(gateway.reads, 0);
  });
  test('disconnect clears AI consent; reconnect never silently restores it',
      () async {
    await consent();
    final controller = ConnectedHealthController(
        gateway: gateway, userId: 'a', preferences: prefs);
    expect(controller.aiSharingEnabled, true);
    await controller.disconnect();
    expect(controller.aiSharingEnabled, false);
    await prefs.setBool(ConnectedHealthController.connectionKey('a'), true);
    expect(controller.aiSharingEnabled, false);
    expect((await reader.readForQuestion()).status, HealthAiStatus.disabled);
    controller.dispose();
  });
  test(
      'health-turn storage marker roundtrips without leaking into displayed text',
      () {
    final message = AiCoachMessage.fromRow({
      'id': 1,
      'role': 'assistant',
      'content': encodeCoachHealthTurn('You walked 6250 steps.',
          healthContextUsed: true)
    });
    expect(message.content, 'You walked 6250 steps.');
    expect(message.healthContextUsed, true);
    expect(message.withPlanAction(null).healthContextUsed, true);
  });
  test('rolling memory excludes health questions and replies deterministically',
      () {
    final messages = [
      for (final role in ['user', 'assistant'])
        AiCoachMessage(
            id: 1,
            role: role,
            content: '6250 steps',
            createdAt: now,
            healthContextUsed: true),
      AiCoachMessage(
          id: 3, role: 'user', content: 'I prefer dumbbells.', createdAt: now),
    ];
    expect(coachMemoryEligibleMessages(messages).single.content,
        'I prefer dumbbells.');
  });
  test(
      'revoked AI consent excludes health-assisted historical turns from prompts',
      () {
    final history = [
      AiCoachMessage(
          id: 1,
          role: 'assistant',
          content: 'You walked 6250 steps.',
          createdAt: now,
          healthContextUsed: true)
    ];
    final messages = buildAiCoachMessages(
        context: athlete, recentHistory: history, question: 'What next?');
    expect(jsonEncode(messages), isNot(contains('6250')));
    expect(messages.first['content'], contains('"status": "disabled"'));
  });
  test(
      'connected health reaches real structured Coach transport without entering saved athlete context',
      () async {
    await consent();
    final health = await reader.readForQuestion();
    final messages = buildAiCoachMessages(
        context: athlete,
        recentHistory: [],
        question: 'How much activity have I done today?',
        healthContext: health);
    final assistant = CoachPlanAssistant(aiCall: (payload) async {
      final prompt = payload.first['content'] as String;
      expect(prompt, contains('6250'));
      expect(prompt, contains('320.6'));
      expect(prompt, contains('2026-10-14T11:45'));
      expect(prompt, contains('"heart_rate_is_live": false'));
      expect(prompt, contains('not total energy expenditure'));
      expect(prompt, contains('NOT live'));
      return jsonEncode({
        'intent': 'chat',
        'assistant_text': 'You have 6250 steps today.',
        'workouts': [],
        'meals': []
      });
    });
    final decision = await assistant.respond(
        systemPrompt: messages.first['content'] as String,
        history: [],
        question: 'How much activity have I done today?',
        now: now);
    expect(decision.text, contains('6250'));
    expect(jsonEncode(athlete.toJson()), isNot(contains('6250')));
  });

  for (final mode in ['on', 'off', 'revoked-before-send']) {
    test('full ask pipeline respects health consent: $mode', () async {
      if (mode != 'off') await consent();
      final saved = <Map<String, dynamic>>[];
      final client = SupabaseClient(
          'https://coach-fixture.invalid', 'public-test-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient((request) async {
        expect(request.url.host, 'coach-fixture.invalid');
        if (request.url.path.endsWith('/ai_coach_threads')) {
          return request.method == 'GET'
              ? http.Response('null', 200,
                  request: request,
                  headers: {'content-type': 'application/json'})
              : http.Response('', 204, request: request);
        }
        if (request.url.path.endsWith('/ai_coach_messages') &&
            request.method == 'POST') {
          final row = Map<String, dynamic>.from(jsonDecode(request.body) as Map)
            ..['id'] = saved.length + 1;
          saved.add(row);
          return row['role'] == 'assistant'
              ? http.Response(jsonEncode(row), 201,
                  request: request,
                  headers: {'content-type': 'application/json'})
              : http.Response('', 204, request: request);
        }
        throw StateError(
            'Unexpected request ${request.method} ${request.url.path}');
      }));
      addTearDown(client.dispose);
      await client.auth.recoverSession(jsonEncode({
        'access_token': 'local-fixture-only',
        'token_type': 'bearer',
        'user': {'id': 'a'},
      }));
      var modelCalls = 0;
      final coach = LocalCoach(
          client: client,
          rows: saved,
          healthReaderFactory: (_) async => reader,
          beforeContext: mode == 'revoked-before-send'
              ? () async {
                  await prefs
                      .remove(ConnectedHealthController.aiConsentKey('a'));
                }
              : null,
          planAssistant: CoachPlanAssistant(aiCall: (payload) async {
            modelCalls++;
            final prompt = payload.first['content'] as String;
            if (mode == 'on') {
              expect(prompt, contains('6250'));
              expect(prompt, contains('320.6'));
              expect(prompt, contains('2026-10-14T11:45'));
            } else {
              expect(prompt, isNot(contains('6250')));
              expect(prompt, contains('"status": "disabled"'));
            }
            return jsonEncode({
              'intent': 'chat',
              'assistant_text': 'Consider your activity alongside your plan.',
              'workouts': [],
              'meals': []
            });
          }));
      final reply =
          await coach.ask('What should I consider for training today?');
      expect(modelCalls, 1);
      expect(gateway.reads, mode == 'off' ? 0 : 1);
      expect(reply.healthContextUsed, mode != 'off');
      expect(saved, hasLength(2));
      expect(saved.every((row) => row['user_id'] == 'a'), true);
      expect(
          saved.every((row) =>
              AiCoachMessage.fromRow(row).healthContextUsed == (mode != 'off')),
          true);
      expect(jsonEncode(saved), isNot(contains('active_calories_kcal')));
      expect(jsonEncode(saved), isNot(contains('private-device-id')));
      // Complete the background memory check before disposing the fake client.
      await Future<void>.delayed(Duration.zero);
    });
  }
  testWidgets(
      'health-sharing switch requires disclosure and explicit acceptance',
      (tester) async {
    await prefs.setBool(ConnectedHealthController.connectionKey('a'), true);
    final controller = ConnectedHealthController(
        gateway: gateway, userId: 'a', preferences: prefs, clock: () => now);
    await tester.pumpWidget(MaterialApp(
        home: ConnectedHealthWidget(userId: 'a', controller: controller)));
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('health-ai-sharing'));
    await tester.scrollUntilVisible(toggle, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text(healthAiConsentText), findsOneWidget);
    expect(controller.aiSharingEnabled, false);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(controller.aiSharingEnabled, false);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Allow AI sharing'));
    await tester.pumpAndSettle();
    expect(controller.aiSharingEnabled, true);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(controller.aiSharingEnabled, false);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
  testWidgets('Coach status reads preferences only, shows sharing on/off',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: HealthCoachNotice(userId: 'a'))));
    await tester.pumpAndSettle();
    expect(find.textContaining('Activity sharing off'), findsOneWidget);
    await consent();
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: HealthCoachNotice(key: ValueKey('new'), userId: 'a'))));
    await tester.pumpAndSettle();
    expect(find.textContaining('Activity sharing on'), findsOneWidget);
    expect(gateway.reads, 0);
  });
}
