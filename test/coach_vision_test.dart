import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

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
    expect(result.model, 'gpt-4o-mini');
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
    expect(result.model, 'gpt-5.4-mini');
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
