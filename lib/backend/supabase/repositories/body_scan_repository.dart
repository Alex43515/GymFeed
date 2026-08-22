import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import '../ai_service.dart';

typedef BodyScanOpenAiCall = Future<String?> Function(
  String prompt,
  String imageUrl,
);
typedef BodyScanGeminiCall = Future<String?> Function(
  String prompt,
  Uint8List imageBytes,
  String mimeType,
);

class BodyScanProfileData {
  const BodyScanProfileData({
    required this.age,
    required this.heightCm,
    required this.weightKg,
    this.gender = '',
    this.workoutsPerWeek = '',
  });

  final int age;
  final double heightCm;
  final double weightKg;
  final String gender;
  final String workoutsPerWeek;

  bool? get isMale {
    final value = gender.trim().toLowerCase();
    if (value.startsWith('m')) return true;
    if (value.startsWith('f') || value.startsWith('w')) return false;
    return null;
  }
}

class BodyScanResult {
  const BodyScanResult({
    required this.data,
    required this.provider,
    required this.model,
  });

  final Map<String, dynamic> data;
  final String provider;
  final String model;

  Map<String, dynamic> get persistedData => {
        ...data,
        'ai_provider': provider,
        'ai_model': model,
      };
}

/// A scan problem the athlete can correct, such as a cropped photo or missing
/// profile measurements. The UI may safely show this message directly.
class BodyScanInputException implements Exception {
  const BodyScanInputException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Produces the visual estimates and deterministic profile-derived values used
/// by the full Body Scan report. Image estimates are clearly separated from
/// calculations such as BMI, BMR, lean mass index and fat mass index.
class BodyScanRepository {
  BodyScanRepository({
    AiService? aiService,
    BodyScanOpenAiCall? openAiVision,
    BodyScanGeminiCall? geminiVision,
  })  : _ai = aiService ?? AiService(),
        _openAiVision = openAiVision,
        _geminiVision = geminiVision;

  static const openAiModel = 'gpt-5.4-mini';
  static const geminiModel = 'gemini-3.5-flash-lite';

  final AiService _ai;
  final BodyScanOpenAiCall? _openAiVision;
  final BodyScanGeminiCall? _geminiVision;

  Future<BodyScanResult> analyze({
    required Uint8List imageBytes,
    required String imageUrl,
    required BodyScanProfileData profile,
    String mimeType = 'image/jpeg',
  }) async {
    _validateProfile(profile);
    final prompt = buildPrompt(profile);
    Object? openAiError;
    try {
      final raw = await (_openAiVision?.call(prompt, imageUrl) ??
          _ai.openAiTextFromImage(
            prompt,
            imageUrl: imageUrl,
            model: openAiModel,
            detail: 'high',
            maxTokens: 2400,
            reasoningEffort: 'medium',
          ));
      if (raw == null || raw.trim().isEmpty) {
        throw const FormatException('OpenAI returned an empty body scan.');
      }
      return BodyScanResult(
        data: normalize(raw, profile),
        provider: 'openai',
        model: openAiModel,
      );
    } on BodyScanInputException {
      // Another provider cannot repair a cropped photo or missing profile data.
      rethrow;
    } catch (error) {
      openAiError = error;
    }

    try {
      final raw = await (_geminiVision?.call(prompt, imageBytes, mimeType) ??
          _ai.geminiTextFromImage(
            prompt,
            imageBytes: imageBytes,
            mimeType: mimeType,
            model: geminiModel,
            maxTokens: 2400,
            jsonObject: true,
          ));
      if (raw == null || raw.trim().isEmpty) {
        throw const FormatException('Gemini returned an empty body scan.');
      }
      return BodyScanResult(
        data: normalize(raw, profile),
        provider: 'gemini',
        model: geminiModel,
      );
    } on BodyScanInputException {
      rethrow;
    } catch (geminiError) {
      throw StateError(
        'Both body-scan providers failed. OpenAI: $openAiError; '
        'Gemini: $geminiError',
      );
    }
  }

  static String buildPrompt(BodyScanProfileData profile) => '''
Check first that one full person is visible from head to feet. This is a rough,
non-medical fitness composition estimate, not a diagnosis. Profile inputs:
age ${profile.age}, weight ${profile.weightKg.toStringAsFixed(1)} kg, height
${profile.heightCm.toStringAsFixed(1)} cm, gender ${profile.gender.isEmpty ? 'not specified' : profile.gender}.

Return one JSON object only with this exact schema:
{"person_visible":true,"body_fat_percent":18.2,"muscle_mass_kg":58.4,"body_water_percent":57.0,"essential_fat_percent":4.0,"beneficial_fat_percent":11.2,"unbeneficial_fat_percent":3.0,"confidence":0.72,"chest":"Balanced","chest_score":82,"arms":"Balanced","arms_score":78,"core":"Developing","core_score":64,"legs":"Strong","legs_score":86,"visceral_fat_level":6,"visceral_fat_assessment":"Low visual indicators","posture_assessment":"Neutral overall alignment","symmetry_assessment":"Minor left-right difference","segmental_lean":[{"segment":"Left arm","kg":3.6,"score":88,"status":"Balanced"},{"segment":"Right arm","kg":3.7,"score":90,"status":"Balanced"},{"segment":"Trunk","kg":28.4,"score":84,"status":"Strong"},{"segment":"Left leg","kg":9.1,"score":52,"status":"Under"},{"segment":"Right leg","kg":9.3,"score":55,"status":"Under"}],"recommendation":"Concise training and nutrition recommendation"}

The three fat components must add up to body_fat_percent. Base estimates on the
visible person and supplied profile, acknowledge uncertainty through confidence,
and do not infer a disease. If a full person is not visible return
{"error_code":"full_body_not_visible","error":"The full body is not visible from head to feet."}.
Never include markdown or extra text.
''';

  static Map<String, dynamic> normalize(
    String raw,
    BodyScanProfileData profile,
  ) {
    _validateProfile(profile);
    final source = _decodeObject(raw);
    final error = _text(source['error']);
    if (error.isNotEmpty) {
      throw BodyScanInputException(_photoErrorMessage(source, error));
    }
    if (source['person_visible'] == false) {
      throw const BodyScanInputException(
        'Your full body is not visible. Choose a photo showing one person '
        'from head to feet, including both arms, legs, and feet.',
      );
    }

    final heightM = profile.heightCm / 100;
    final heightSquared = heightM * heightM;
    final bmi = profile.weightKg / heightSquared;
    final bodyFat = _bounded(
      source['body_fat_percent'] ?? source['body_fat'],
      2,
      70,
      fallback: _bodyFatFallback(bmi, profile),
    );
    final fatMassKg = profile.weightKg * bodyFat / 100;
    final leanMassKg = profile.weightKg - fatMassKg;
    final leanMassPercent = 100 - bodyFat;
    final muscleMassKg = _bounded(
      source['muscle_mass_kg'] ?? source['muscle_mass'],
      0,
      leanMassKg,
      fallback: leanMassKg * .72,
    );

    final fatSplit = _normalizedFatSplit(source, profile, bodyFat);
    final bmr = _bmr(profile);
    final tdee = bmr * _activityMultiplier(profile.workoutsPerWeek);
    final bsa = .007184 *
        math.pow(profile.weightKg, .425) *
        math.pow(profile.heightCm, .725);
    final idealWeight = _idealWeight(profile);
    final proteinMassKg = leanMassKg * .197;
    final boneMassKg = leanMassKg * .053;
    final chestScore = _bodyScore(source, 'chest', 75);
    final armsScore = _bodyScore(source, 'arms', 72);
    final coreScore = _bodyScore(source, 'core', 68);
    final legsScore = _bodyScore(source, 'legs', 70);
    final balanceScore = (chestScore + armsScore + coreScore + legsScore) / 4;
    final bodyFatTarget = profile.isMale == true
        ? 15.0
        : profile.isMale == false
            ? 24.0
            : 20.0;
    final bodyFatScore =
        (100 - (bodyFat - bodyFatTarget).abs() * 3).clamp(0, 100).toDouble();
    final bmiScore = (100 - (bmi - 22).abs() * 7).clamp(0, 100).toDouble();
    final fitnessScore =
        (.4 * bodyFatScore + .25 * bmiScore + .35 * balanceScore).round();
    final visceralLevel = _bounded(
      source['visceral_fat_level'],
      1,
      20,
      fallback: (bodyFat / 3).roundToDouble(),
    ).round();
    final metabolicAge =
        (profile.age + (bmi - 22) * .7 + (bodyFat - bodyFatTarget) * .25)
            .round()
            .clamp(16, 90);
    final segmentalLean = _segmentalLean(source, leanMassKg, <String, int>{
      'Left arm': armsScore,
      'Right arm': armsScore,
      'Trunk': coreScore,
      'Left leg': legsScore,
      'Right leg': legsScore,
    });

    return <String, dynamic>{
      'weight_kg': _round(profile.weightKg, 1),
      'height_cm': _round(profile.heightCm, 1),
      'age': profile.age,
      'bmi': _round(bmi, 1),
      'bmi_category': _bmiCategory(bmi),
      'body_fat': _round(bodyFat, 1),
      'body_fat_percent': _round(bodyFat, 1),
      'fat_mass_kg': _round(fatMassKg, 1),
      'lean_mass_kg': _round(leanMassKg, 1),
      'lean_mass_percent': _round(leanMassPercent, 1),
      'muscle_mass': _round(muscleMassKg, 1),
      'muscle_mass_kg': _round(muscleMassKg, 1),
      'water': _round(
        _bounded(
          source['body_water_percent'] ?? source['water'],
          20,
          80,
          fallback: 55,
        ),
        1,
      ),
      'body_water_percent': _round(
        _bounded(
          source['body_water_percent'] ?? source['water'],
          20,
          80,
          fallback: 55,
        ),
        1,
      ),
      ...fatSplit,
      'lean_mass_index': _round(leanMassKg / heightSquared, 1),
      'fat_mass_index': _round(fatMassKg / heightSquared, 1),
      'bmr_kcal': bmr.round(),
      'resting_metabolic_rate_kcal': bmr.round(),
      'tdee_kcal': tdee.round(),
      'body_surface_area_m2': _round(bsa, 2),
      'ideal_body_weight_kg': _round(idealWeight, 1),
      'protein_mass_kg': _round(proteinMassKg, 1),
      'protein_percent': _round(proteinMassKg / profile.weightKg * 100, 1),
      'bone_mass_kg': _round(boneMassKg, 1),
      'metabolic_age': metabolicAge,
      'fitness_score': fitnessScore,
      'fitness_rating': _fitnessRating(fitnessScore),
      'top_percent': math.max(1, 100 - fitnessScore),
      'visceral_fat_level': visceralLevel,
      'visceral_fat_label': visceralLevel < 10
          ? 'Healthy'
          : visceralLevel < 15
              ? 'Elevated'
              : 'High',
      'confidence': _confidence(source['confidence']),
      'chest': _fallbackText(source['chest'], 'Estimated'),
      'chest_score': chestScore,
      'arms': _fallbackText(source['arms'], 'Estimated'),
      'arms_score': armsScore,
      'core': _fallbackText(source['core'], 'Estimated'),
      'core_score': coreScore,
      'legs': _fallbackText(source['legs'], 'Estimated'),
      'legs_score': legsScore,
      'segmental_lean': segmentalLean,
      'visceral_fat_assessment': _fallbackText(
        source['visceral_fat_assessment'],
        'Not enough visual information',
      ),
      'posture_assessment': _fallbackText(
        source['posture_assessment'],
        'No clear concern identified',
      ),
      'symmetry_assessment': _fallbackText(
        source['symmetry_assessment'],
        'No clear imbalance identified',
      ),
      'recommendation': _fallbackText(
        source['recommendation'],
        'Repeat scans under the same conditions to compare trends.',
      ),
      'measurement_note':
          'AI visual estimate. BMI, mass indexes and energy values are calculated from profile data.',
    };
  }

  static void _validateProfile(BodyScanProfileData profile) {
    if (profile.heightCm <= 0 || profile.weightKg <= 0) {
      throw const BodyScanInputException(
        'Add your height and weight in Edit profile before starting a body scan.',
      );
    }
  }

  static String _photoErrorMessage(
    Map<String, dynamic> source,
    String providerMessage,
  ) {
    final code = _text(source['error_code']).toLowerCase();
    final normalized = providerMessage.toLowerCase();
    if (code == 'full_body_not_visible' ||
        normalized.contains('full person') ||
        normalized.contains('full body') ||
        normalized.contains('head to feet')) {
      return 'Your full body is not visible. Choose a photo showing one person '
          'from head to feet, including both arms, legs, and feet.';
    }
    if (code == 'multiple_people' || normalized.contains('multiple people')) {
      return 'Choose a photo containing only one person.';
    }
    return providerMessage;
  }

  static Map<String, dynamic> withPreviousScan(
    Map<String, dynamic> current,
    Map<String, dynamic>? previous,
  ) {
    final previousScore = _number(previous?['fitness_score']);
    final previousBodyFat = _number(
      previous?['body_fat_percent'] ?? previous?['body_fat'],
    );
    return <String, dynamic>{
      ...current,
      'has_previous_scan': previous != null && previous.isNotEmpty,
      'fitness_score_change': previousScore > 0
          ? (_number(current['fitness_score']) - previousScore).round()
          : 0,
      'body_fat_change': previousBodyFat > 0
          ? _round(_number(current['body_fat']) - previousBodyFat, 1)
          : 0.0,
    };
  }

  static int _bodyScore(
    Map<String, dynamic> source,
    String key,
    int fallback,
  ) {
    final numeric = _number(source['${key}_score']);
    if (numeric > 0) return numeric.round().clamp(1, 100);
    final label = _text(source[key]).toLowerCase();
    if (label.contains('strong') || label.contains('excellent')) return 86;
    if (label.contains('balanced') || label.contains('good')) return 75;
    if (label.contains('develop')) return 62;
    if (label.contains('under') || label.contains('need')) return 45;
    return fallback;
  }

  static List<Map<String, dynamic>> _segmentalLean(
    Map<String, dynamic> source,
    double leanMassKg,
    Map<String, int> fallbackScores,
  ) {
    final raw = source['segmental_lean'];
    if (raw is List) {
      final parsed = raw
          .whereType<Map>()
          .map((item) {
            final label = _text(item['segment']);
            final score = _bounded(
              item['score'],
              1,
              100,
              fallback: fallbackScores[label]?.toDouble() ?? 70,
            ).round();
            return <String, dynamic>{
              'segment': label,
              'kg': _round(
                  _bounded(item['kg'], 0, leanMassKg,
                      fallback: _segmentKg(label, leanMassKg)),
                  1),
              'score': score,
              'status': _fallbackText(item['status'], _segmentStatus(score)),
            };
          })
          .where((item) => item['segment'].toString().isNotEmpty)
          .toList();
      if (parsed.length >= 5) return parsed.take(5).toList();
    }
    return fallbackScores.entries
        .map((entry) => <String, dynamic>{
              'segment': entry.key,
              'kg': _round(_segmentKg(entry.key, leanMassKg), 1),
              'score': entry.value,
              'status': _segmentStatus(entry.value),
            })
        .toList();
  }

  static double _segmentKg(String label, double leanMassKg) {
    switch (label.toLowerCase()) {
      case 'left arm':
        return leanMassKg * .056;
      case 'right arm':
        return leanMassKg * .058;
      case 'trunk':
        return leanMassKg * .444;
      case 'left leg':
        return leanMassKg * .142;
      case 'right leg':
        return leanMassKg * .145;
      default:
        return leanMassKg * .1;
    }
  }

  static String _segmentStatus(int score) {
    if (score >= 82) return 'Strong';
    if (score >= 65) return 'Balanced';
    return 'Under';
  }

  static String _fitnessRating(int score) {
    if (score >= 80) return 'Athletic';
    if (score >= 65) return 'Fit';
    if (score >= 50) return 'Developing';
    return 'Starting point';
  }

  static Map<String, dynamic> _normalizedFatSplit(
    Map<String, dynamic> source,
    BodyScanProfileData profile,
    double bodyFat,
  ) {
    var essential = _number(source['essential_fat_percent']);
    var beneficial = _number(source['beneficial_fat_percent']);
    var unbeneficial = _number(source['unbeneficial_fat_percent']);
    final suppliedTotal = essential + beneficial + unbeneficial;

    if (suppliedTotal > 0) {
      final scale = bodyFat / suppliedTotal;
      essential *= scale;
      beneficial *= scale;
      unbeneficial *= scale;
    } else {
      final isMale = profile.isMale;
      final essentialBaseline = isMale == true
          ? 3.0
          : isMale == false
              ? 12.0
              : 7.5;
      final healthyUpper = isMale == true
          ? 20.0
          : isMale == false
              ? 30.0
              : 25.0;
      essential = math.min(bodyFat, essentialBaseline);
      unbeneficial = math.max(0, bodyFat - healthyUpper);
      beneficial = math.max(0, bodyFat - essential - unbeneficial);
    }

    // Round the first two values, then assign the remainder to the final value
    // so the old four-part composition report still totals exactly 100%.
    final roundedEssential = math.min(bodyFat, _round(essential, 1));
    final roundedBeneficial = math.min(
      bodyFat - roundedEssential,
      _round(beneficial, 1),
    );
    final roundedUnbeneficial =
        _round(bodyFat - roundedEssential - roundedBeneficial, 1);
    return {
      'essential_fat_percent': roundedEssential,
      'beneficial_fat_percent': roundedBeneficial,
      'unbeneficial_fat_percent': math.max(0, roundedUnbeneficial),
    };
  }

  static double _bodyFatFallback(double bmi, BodyScanProfileData profile) {
    final sex = profile.isMale == true ? 1 : 0;
    final estimate = 1.2 * bmi + .23 * profile.age - 10.8 * sex - 5.4;
    return estimate.clamp(2, 70).toDouble();
  }

  static double _bmr(BodyScanProfileData profile) {
    final base =
        10 * profile.weightKg + 6.25 * profile.heightCm - 5 * profile.age;
    if (profile.isMale == true) return base + 5;
    if (profile.isMale == false) return base - 161;
    return base - 78;
  }

  static double _activityMultiplier(String value) {
    final match = RegExp(r'\d+').allMatches(value).map((item) {
      return int.tryParse(item.group(0) ?? '') ?? 0;
    }).toList();
    final sessions = match.isEmpty ? 0 : match.reduce(math.max);
    if (sessions >= 6) return 1.725;
    if (sessions >= 4) return 1.55;
    if (sessions >= 2) return 1.375;
    return 1.2;
  }

  static double _idealWeight(BodyScanProfileData profile) {
    final inchesOverFiveFeet = math.max(0, profile.heightCm / 2.54 - 60);
    final base = profile.isMale == true
        ? 50.0
        : profile.isMale == false
            ? 45.5
            : 47.75;
    return base + 2.3 * inchesOverFiveFeet;
  }

  static String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Below standard range';
    if (bmi < 25) return 'Standard range';
    if (bmi < 30) return 'Above standard range';
    return 'High range';
  }

  static Map<String, dynamic> _decodeObject(String source) {
    var cleaned = source.trim();
    cleaned = cleaned.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'\s*```$'), '');
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start >= 0 && end > start) cleaned = cleaned.substring(start, end + 1);
    final decoded = jsonDecode(cleaned);
    if (decoded is! Map) throw const FormatException('Expected JSON object.');
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }

  static String _fallbackText(dynamic value, String fallback) {
    final result = _text(value);
    return result.isEmpty ? fallback : result;
  }

  static String _text(dynamic value) => value?.toString().trim() ?? '';

  static double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _bounded(
    dynamic value,
    double min,
    double max, {
    required double fallback,
  }) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (parsed == null || !parsed.isFinite) return fallback;
    return parsed.clamp(min, max).toDouble();
  }

  static double _confidence(dynamic value) {
    var result = _bounded(value, 0, 100, fallback: .5);
    if (result > 1) result /= 100;
    return result.clamp(0, 1).toDouble();
  }

  static double _round(double value, int decimals) {
    final factor = math.pow(10, decimals).toDouble();
    return (value * factor).round() / factor;
  }
}
