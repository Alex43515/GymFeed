import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gym_feed/backend/supabase/ai_service.dart';

import 'package:gym_feed/backend/supabase/repositories/coach_vision_repository.dart';

void main() {
  const foodJson = '''
  {
    "name":"Chicken rice bowl",
    "portion_size":"380 g bowl",
    "total_weight_g":380,
    "calories":612,
    "protein_g":46,
    "carbs_g":58,
    "fat_g":19,
    "confidence":98,
    "ingredients":[
      {"name":"Chicken breast","grams":150},
      {"name":"Rice","grams":180},
      {"name":"Vegetables","grams":50}
    ]
  }
  ''';

  test('a model edit changes the next scan and preserves request options',
      () async {
    const equipmentJson = '''
    {"name":"Incline chest press","machine_family":"press machine",
    "type":"upper body","category":"plate-loaded machine","confidence":0.9,
    "muscles":["Chest","Triceps"],"steps":["Adjust the seat.","Press with control."]}
    ''';
    var equipmentModel = 'gpt-6-luna';
    final calls = <Map<String, dynamic>>[];
    final client = SupabaseClient(
      'https://gymfeed.test',
      'test-key',
      httpClient: MockClient((request) async {
        if (request.url.path == '/rest/v1/ai_model_settings') {
          final feature = request.url.queryParameters['feature'];
          if (feature == 'eq.equipment_scan') {
            return http.Response(
              jsonEncode([
                {'model': equipmentModel}
              ]),
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }
          expect(feature, 'eq.food_scan');
          return http.Response('{"message":"Settings unavailable"}', 403,
              request: request);
        }

        expect(request.url.path,
            '/functions/v1/ai-proxy/openai/v1/chat/completions');
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        calls.add(payload);
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': calls.length == 3 ? foodJson : equipmentJson
                }
              }
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    final repo = CoachVisionRepository(aiService: AiService(client: client));
    final bytes = Uint8List.fromList([1]);

    final first = await repo.analyzeEquipment(
      imageBytes: bytes,
      imageUrl: 'https://example.com/machine.jpg',
    );
    equipmentModel = 'gpt-5.4-mini';
    final second = await repo.analyzeEquipment(
      imageBytes: bytes,
      imageUrl: 'https://example.com/machine.jpg',
    );
    final food = await repo.analyzeFood(
      imageBytes: bytes,
      imageUrl: 'https://example.com/meal.jpg',
    );

    expect(first.model, 'gpt-6-luna');
    expect(second.model, 'gpt-5.4-mini');
    expect(food.model, 'gpt-6-luna');
    expect(calls.map((call) => call['model']),
        ['gpt-6-luna', 'gpt-5.4-mini', 'gpt-6-luna']);
    expect(calls.map((call) => call['reasoning_effort']),
        ['medium', 'medium', 'none']);
    for (final call in calls) {
      expect(call['max_completion_tokens'], 1800);
      expect(call, isNot(contains('max_tokens')));
      expect(call, isNot(contains('temperature')));
    }
  });

  test('food scan uses OpenAI primary and normalizes editable ingredients',
      () async {
    var geminiCalls = 0;
    final repository = CoachVisionRepository(
      openAiVision: (_, __) async => foodJson,
      geminiVision: (_, __, ___) async {
        geminiCalls += 1;
        return null;
      },
    );

    final result = await repository.analyzeFood(
      imageBytes: Uint8List.fromList([1, 2, 3]),
      imageUrl: 'https://example.com/meal.jpg',
    );

    expect(result.provider, 'openai');
    expect(result.model, 'gpt-6-luna');
    expect(geminiCalls, 0);
    expect(result.data['confidence'], .98);
    expect((result.data['ingredients'] as List), hasLength(3));
    expect(result.persistedData['ai_provider'], 'openai');
  });

  test('invalid OpenAI response falls back to Gemini Flash-Lite', () async {
    final repository = CoachVisionRepository(
      openAiVision: (_, __) async => '{"error":"not sure"}',
      geminiVision: (_, __, ___) async => foodJson,
    );

    final result = await repository.analyzeFood(
      imageBytes: Uint8List.fromList([1]),
      imageUrl: 'https://example.com/meal.jpg',
    );

    expect(result.provider, 'gemini');
    expect(result.model, 'gemini-3.5-flash-lite');
    expect(result.data['name'], 'Chicken rice bowl');
  });

  test('equipment scan requires useful muscles and instructions', () async {
    final repository = CoachVisionRepository(
      openAiVision: (_, __) async => '''
        {"name":"Plate-Loaded Incline Chest Press",
        "machine_family":"press machine","type":"Compound · upper body",
        "category":"plate-loaded machine","confidence":0.97,
        "visual_evidence":["Inclined back pad","Independent lever arms"],
        "alternatives":[],
        "muscles":["Upper chest","Front deltoids","Triceps"],
        "steps":["Adjust the seat.","Load both sides evenly.","Press with control."],
        "safety_notes":["Use collars on every weight horn."]}
      ''',
      geminiVision: (_, __, ___) async => null,
    );

    final result = await repository.analyzeEquipment(
      imageBytes: Uint8List.fromList([1]),
      imageUrl: 'https://example.com/machine.jpg',
    );

    expect(result.provider, 'openai');
    expect(result.model, 'gpt-6-luna');
    expect(result.data['name'], 'Plate-Loaded Incline Chest Press');
    expect(result.data['muscles'], contains('Upper chest'));
    expect(result.data['visual_evidence'], hasLength(2));
    expect((result.data['steps'] as List), hasLength(3));
  });

  test('equipment prompt asks the model to reason from full machine geometry',
      () async {
    late String prompt;
    final repository = CoachVisionRepository(
      openAiVision: (value, _) async {
        prompt = value;
        return '''
          {"name":"Incline Chest Press","type":"Compound · upper body",
          "category":"machine","confidence":0.9,
          "muscles":["Chest","Triceps"],
          "steps":["Adjust the seat.","Press forward with control."]}
        ''';
      },
      geminiVision: (_, __, ___) async => null,
    );

    await repository.analyzeEquipment(
      imageBytes: Uint8List.fromList([1]),
      imageUrl: 'https://example.com/machine.jpg',
    );

    expect(prompt, contains('full mechanical geometry'));
    expect(prompt, contains('leg press vs hack squat'));
  });

  test('both providers rejecting a non-food image surfaces a scan failure',
      () async {
    final repository = CoachVisionRepository(
      openAiVision: (_, __) async => '{"error":"No meal was visible."}',
      geminiVision: (_, __, ___) async => '{"error":"No food found."}',
    );

    expect(
      () => repository.analyzeFood(
        imageBytes: Uint8List.fromList([1]),
        imageUrl: 'https://example.com/not-food.jpg',
      ),
      throwsA(isA<StateError>()),
    );
  });
}
