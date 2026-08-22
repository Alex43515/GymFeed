import 'dart:convert';
import 'dart:typed_data';

import '../ai_service.dart';

typedef OpenAiVisionCall = Future<String?> Function(
  String prompt,
  String imageUrl,
);
typedef GeminiVisionCall = Future<String?> Function(
  String prompt,
  Uint8List imageBytes,
  String mimeType,
);

class CoachVisionResult {
  const CoachVisionResult({
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

/// Provider-resilient image analysis for the premium Coach tools. Food uses a
/// cost-conscious model, while equipment uses stronger visual reasoning for
/// fine-grained machine identification. Gemini is the failure fallback.
class CoachVisionRepository {
  CoachVisionRepository({
    AiService? aiService,
    OpenAiVisionCall? openAiVision,
    GeminiVisionCall? geminiVision,
  })  : _ai = aiService ?? AiService(),
        _openAiVision = openAiVision,
        _geminiVision = geminiVision;

  static const foodOpenAiModel = 'gpt-4o-mini';
  static const equipmentOpenAiModel = 'gpt-5.4-mini';
  static const geminiModel = 'gemini-3.5-flash-lite';

  final AiService _ai;
  final OpenAiVisionCall? _openAiVision;
  final GeminiVisionCall? _geminiVision;

  Future<CoachVisionResult> analyzeFood({
    required Uint8List imageBytes,
    required String imageUrl,
    String mimeType = 'image/jpeg',
  }) {
    return _analyze(
      prompt: _foodPrompt,
      imageBytes: imageBytes,
      imageUrl: imageUrl,
      mimeType: mimeType,
      normalize: normalizeFood,
      openAiModel: foodOpenAiModel,
    );
  }

  Future<CoachVisionResult> analyzeEquipment({
    required Uint8List imageBytes,
    required String imageUrl,
    String mimeType = 'image/jpeg',
  }) {
    return _analyze(
      prompt: _equipmentPrompt,
      imageBytes: imageBytes,
      imageUrl: imageUrl,
      mimeType: mimeType,
      normalize: normalizeEquipment,
      openAiModel: equipmentOpenAiModel,
      openAiReasoningEffort: 'medium',
      openAiImageDetail: 'high',
    );
  }

  Future<CoachVisionResult> _analyze({
    required String prompt,
    required Uint8List imageBytes,
    required String imageUrl,
    required String mimeType,
    required Map<String, dynamic> Function(String raw) normalize,
    required String openAiModel,
    String? openAiReasoningEffort,
    String openAiImageDetail = 'auto',
  }) async {
    Object? openAiError;
    try {
      final raw = await (_openAiVision?.call(prompt, imageUrl) ??
          _ai.openAiTextFromImage(
            prompt,
            imageUrl: imageUrl,
            model: openAiModel,
            detail: openAiImageDetail,
            maxTokens: 1800,
            reasoningEffort: openAiReasoningEffort,
          ));
      if (raw == null || raw.trim().isEmpty) {
        throw const FormatException('OpenAI returned an empty scan.');
      }
      return CoachVisionResult(
        data: normalize(raw),
        provider: 'openai',
        model: openAiModel,
      );
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
            maxTokens: 1200,
            jsonObject: true,
          ));
      if (raw == null || raw.trim().isEmpty) {
        throw const FormatException('Gemini returned an empty scan.');
      }
      return CoachVisionResult(
        data: normalize(raw),
        provider: 'gemini',
        model: geminiModel,
      );
    } catch (geminiError) {
      throw StateError(
        'Both vision providers failed. OpenAI: $openAiError; '
        'Gemini: $geminiError',
      );
    }
  }

  static Map<String, dynamic> normalizeFood(String raw) {
    final data = _decodeObject(raw);
    _rejectProviderError(data);
    final name = _requiredText(data['name'], 'meal name');
    final calories = _boundedNumber(data['calories'], 0, 5000);
    final protein = _boundedNumber(data['protein_g'], 0, 1000);
    final carbs = _boundedNumber(data['carbs_g'], 0, 1500);
    final fat = _boundedNumber(data['fat_g'], 0, 1000);
    final totalWeight = _boundedNumber(data['total_weight_g'], 0, 10000);
    final confidence = _confidence(data['confidence']);
    final ingredients = _ingredientList(data['ingredients']);
    if (ingredients.isEmpty) {
      throw const FormatException('No food ingredients were identified.');
    }
    return {
      'name': name,
      'portion_size': _text(data['portion_size']).isEmpty
          ? '${totalWeight.round()} g'
          : _text(data['portion_size']),
      'total_weight_g': totalWeight,
      'calories': calories,
      'protein_g': protein,
      'carbs_g': carbs,
      'fat_g': fat,
      'confidence': confidence,
      'ingredients': ingredients,
    };
  }

  static Map<String, dynamic> normalizeEquipment(String raw) {
    final data = _decodeObject(raw);
    _rejectProviderError(data);
    final name = _requiredText(data['name'], 'equipment name');
    final muscles = _stringList(data['muscles']);
    final steps = _stringList(data['steps']);
    if (muscles.isEmpty || steps.length < 2) {
      throw const FormatException('Incomplete equipment instructions.');
    }
    return {
      'name': name,
      'type': _text(data['type']).isEmpty
          ? 'Exercise equipment'
          : _text(data['type']),
      'category': _text(data['category']),
      'machine_family': _text(data['machine_family']),
      'confidence': _confidence(data['confidence']),
      'visual_evidence': _stringList(data['visual_evidence']).take(5).toList(),
      'alternatives': _stringList(data['alternatives']).take(3).toList(),
      'muscles': muscles.take(5).toList(),
      'steps': steps.take(6).toList(),
      'safety_notes': _stringList(data['safety_notes']).take(4).toList(),
    };
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

  static void _rejectProviderError(Map<String, dynamic> data) {
    final error = _text(data['error']);
    if (error.isNotEmpty) throw FormatException(error);
  }

  static String _requiredText(dynamic value, String label) {
    final result = _text(value);
    if (result.isEmpty) throw FormatException('Missing $label.');
    return result;
  }

  static String _text(dynamic value) => value?.toString().trim() ?? '';

  static double _boundedNumber(dynamic value, double min, double max) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (parsed == null || !parsed.isFinite) return min;
    return parsed.clamp(min, max).toDouble();
  }

  static double _confidence(dynamic value) {
    var parsed = _boundedNumber(value, 0, 100);
    if (parsed > 1) parsed /= 100;
    return parsed.clamp(0, 1).toDouble();
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map(_text).where((item) => item.isNotEmpty).toSet().toList();
  }

  static List<Map<String, dynamic>> _ingredientList(dynamic value) {
    if (value is List) {
      return value
          .map((item) {
            if (item is Map) {
              final name = _text(item['name']);
              if (name.isEmpty) return null;
              return <String, dynamic>{
                'name': name,
                'grams': _boundedNumber(item['grams'], 0, 10000),
              };
            }
            final name = _text(item);
            return name.isEmpty
                ? null
                : <String, dynamic>{'name': name, 'grams': 0.0};
          })
          .whereType<Map<String, dynamic>>()
          .take(12)
          .toList();
    }
    final text = _text(value);
    if (text.isEmpty) return const [];
    return text
        .split(RegExp(r'[,;]'))
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .map((name) => <String, dynamic>{'name': name, 'grams': 0.0})
        .take(12)
        .toList();
  }

  static const _foodPrompt = '''
Analyze only the plated food visible in this image. Estimate the complete meal,
not a generic recipe. Return one JSON object only with this exact schema:
{"name":"short meal name","portion_size":"short serving label","total_weight_g":380,"calories":612,"protein_g":46,"carbs_g":58,"fat_g":19,"confidence":0.98,"ingredients":[{"name":"ingredient","grams":150}]}
Use numeric values for all quantities. Ingredient grams should approximately
sum to total_weight_g and calories/macros must describe that same portion. If
there is no clearly visible food, return {"error":"No meal was visible. Point
the camera at the whole plate and try again."}. Never include markdown.
''';

  static const _equipmentPrompt = '''
Identify the exact gym machine or exercise equipment visible in the image.
Reason from the full mechanical geometry before naming it: inspect the user
position, seat and back-pad angle, handles, lever-arm pivot and direction of
travel, weight horns or stack, foot plates, and where force is applied. Do not
classify from one isolated component. Distinguish visually similar families
such as chest press vs shoulder press, row vs press, and leg press vs hack squat.

Return one JSON object only with this exact schema:
{"name":"specific machine name","machine_family":"press machine","type":"compound · upper body","category":"plate-loaded machine","confidence":0.96,"visual_evidence":["Inclined back pad","Independent forward press arms","Plate-loading horns"],"alternatives":["Flat leverage chest press"],"muscles":["Upper chest","Front deltoids","Triceps"],"steps":["Adjust the seat...","Load both sides evenly...","Press with control..."],"safety_notes":["Use collars on every weight horn."]}

Use the common gym name, not a brand or invented product name. Confidence must
reflect visual ambiguity. Put plausible alternatives in descending order only
when confidence is below 0.85. Keep instructions concise and practical. If no
gym equipment is clearly visible, return {"error":"No gym equipment was
visible. Frame the whole machine and try again."}. Never include markdown.
''';
}
