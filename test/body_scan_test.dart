import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:gym_feed/backend/supabase/repositories/body_scan_repository.dart';

void main() {
  const profile = BodyScanProfileData(
    age: 30,
    heightCm: 180,
    weightKg: 80,
    gender: 'Male',
    workoutsPerWeek: '4 workouts',
  );

  const visualResult = '''
  {
    "person_visible": true,
    "body_fat_percent": 20,
    "muscle_mass_kg": 56,
    "body_water_percent": 58,
    "essential_fat_percent": 4,
    "beneficial_fat_percent": 12,
    "unbeneficial_fat_percent": 4,
    "confidence": 0.82,
    "chest": "Balanced",
    "arms": "Balanced",
    "core": "Developing",
    "legs": "Strong",
    "visceral_fat_assessment": "Low visual indicators",
    "posture_assessment": "Neutral alignment",
    "symmetry_assessment": "Minor difference",
    "recommendation": "Continue progressive resistance training."
  }
  ''';

  test('body scan restores old report metrics and calculates profile values',
      () {
    final data = BodyScanRepository.normalize(visualResult, profile);

    expect(data['bmi'], 24.7);
    expect(data['body_fat'], 20);
    expect(data['fat_mass_kg'], 16);
    expect(data['lean_mass_kg'], 64);
    expect(data['lean_mass_percent'], 80);
    expect(data['lean_mass_index'], 19.8);
    expect(data['fat_mass_index'], 4.9);
    expect(data['resting_metabolic_rate_kcal'], 1780);
    expect(data['tdee_kcal'], 2759);
    expect(data['essential_fat_percent'], 4);
    expect(data['beneficial_fat_percent'], 12);
    expect(data['unbeneficial_fat_percent'], 4);
    expect(data['fitness_score'], inInclusiveRange(1, 100));
    expect(data['protein_mass_kg'], greaterThan(0));
    expect(data['bone_mass_kg'], greaterThan(0));
    expect(data['visceral_fat_level'], inInclusiveRange(1, 20));
    expect((data['segmental_lean'] as List), hasLength(5));

    final compositionTotal = (data['essential_fat_percent'] as num) +
        (data['beneficial_fat_percent'] as num) +
        (data['unbeneficial_fat_percent'] as num) +
        (data['lean_mass_percent'] as num);
    expect(compositionTotal, 100);
  });

  test('body scan uses the stronger OpenAI model and keeps Gemini fallback',
      () async {
    var geminiCalls = 0;
    final repository = BodyScanRepository(
      openAiVision: (_, __) async => visualResult,
      geminiVision: (_, __, ___) async {
        geminiCalls += 1;
        return visualResult;
      },
    );

    final result = await repository.analyze(
      imageBytes: Uint8List.fromList([1, 2, 3]),
      imageUrl: 'https://example.com/body.jpg',
      profile: profile,
    );

    expect(result.provider, 'openai');
    expect(result.model, 'gpt-5.4-mini');
    expect(result.persistedData['ai_provider'], 'openai');
    expect(geminiCalls, 0);
  });

  test('body scan rejects images without a full person', () {
    expect(
      () => BodyScanRepository.normalize(
        '{"person_visible":false}',
        profile,
      ),
      throwsA(
        isA<BodyScanInputException>().having(
          (error) => error.message,
          'message',
          contains('head to feet'),
        ),
      ),
    );
  });

  test('body scan does not retry a second provider for a cropped photo',
      () async {
    var geminiCalls = 0;
    final repository = BodyScanRepository(
      openAiVision: (_, __) async =>
          '{"error":"A full person was not visible. Stand back."}',
      geminiVision: (_, __, ___) async {
        geminiCalls += 1;
        return visualResult;
      },
    );

    await expectLater(
      repository.analyze(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        imageUrl: 'https://example.com/cropped-body.jpg',
        profile: profile,
      ),
      throwsA(isA<BodyScanInputException>()),
    );
    expect(geminiCalls, 0);
  });

  test('body scan checks profile measurements before calling AI', () async {
    var openAiCalls = 0;
    final repository = BodyScanRepository(
      openAiVision: (_, __) async {
        openAiCalls += 1;
        return visualResult;
      },
    );

    await expectLater(
      repository.analyze(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        imageUrl: 'https://example.com/body.jpg',
        profile: const BodyScanProfileData(
          age: 30,
          heightCm: 0,
          weightKg: 80,
        ),
      ),
      throwsA(
        isA<BodyScanInputException>().having(
          (error) => error.message,
          'message',
          contains('Edit profile'),
        ),
      ),
    );
    expect(openAiCalls, 0);
  });

  test('body scan prompt requests every legacy report value', () {
    final prompt = BodyScanRepository.buildPrompt(profile);

    expect(prompt, contains('essential_fat_percent'));
    expect(prompt, contains('beneficial_fat_percent'));
    expect(prompt, contains('unbeneficial_fat_percent'));
    expect(prompt, contains('visceral_fat_assessment'));
    expect(prompt, contains('posture_assessment'));
    expect(prompt, contains('segmental_lean'));
  });

  test('body scan compares the scored report with the previous scan', () {
    final current = BodyScanRepository.normalize(visualResult, profile);
    final compared = BodyScanRepository.withPreviousScan(
      current,
      {
        'fitness_score': (current['fitness_score'] as num) - 4,
        'body_fat': 21.2,
      },
    );

    expect(compared['has_previous_scan'], isTrue);
    expect(compared['fitness_score_change'], 4);
    expect(compared['body_fat_change'], -1.2);
  });
}
