import 'dart:convert';
import 'dart:typed_data';

import '/backend/supabase/supabase.dart';

/// All AI calls go through the `ai-proxy` Edge Function, which holds the OpenAI
/// and Gemini keys server-side. `functions.invoke` attaches the caller's Supabase
/// JWT automatically, so only signed-in users can spend against the keys.
///
/// Replaces:
///   - lib/backend/gemini/gemini.dart (hardcoded Gemini key, retired 1.5 models)
///   - the OpenAI groups in lib/backend/api_requests/api_calls.dart (hardcoded key)
class AiService {
  static const String _geminiTextModel = 'gemini-3.6-flash';
  // Vision is only the fallback for the Coach scanners. Flash-Lite is the
  // lowest-cost current GA Gemini model and is more than capable of the small
  // structured extraction payloads used here.
  static const String _geminiVisionModel = 'gemini-3.5-flash-lite';
  static const String _openAiChatModel = 'gpt-4o-mini';

  Future<Map<String, dynamic>> _invoke(
      String path, Map<String, dynamic> body) async {
    final res = await supabase.functions.invoke('ai-proxy/$path', body: body);
    final data = res.data;
    if (res.status >= 400) {
      throw Exception('ai-proxy $path failed (${res.status}): $data');
    }
    if (data is Map<String, dynamic>) return data;
    if (data is String && data.isNotEmpty) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return const {};
  }

  // --------------------------------------------------------------- Gemini

  Future<String?> geminiGenerateText(String prompt) async {
    final json = await _invoke(
      'gemini/v1beta/models/$_geminiTextModel:generateContent',
      {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
      },
    );
    return _geminiText(json);
  }

  /// OpenAI-style chat input rendered through Gemini. This is used as the
  /// resilient fallback for long-running premium plan generation.
  Future<String?> geminiChat(
    List<Map<String, dynamic>> messages, {
    String? model,
    int? maxTokens,
    double? temperature,
    bool jsonObject = false,
  }) async {
    final system = messages
        .where((message) => message['role'] == 'system')
        .map((message) => message['content']?.toString() ?? '')
        .where((content) => content.isNotEmpty)
        .join('\n\n');
    final contents = messages
        .where((message) => message['role'] != 'system')
        .map((message) => {
              'role': message['role'] == 'assistant' ? 'model' : 'user',
              'parts': [
                {'text': message['content']?.toString() ?? ''}
              ],
            })
        .toList();
    final json = await _invoke(
      'gemini/v1beta/models/${model ?? _geminiTextModel}:generateContent',
      {
        if (system.isNotEmpty)
          'system_instruction': {
            'parts': [
              {'text': system}
            ]
          },
        'contents': contents,
        'generationConfig': {
          if (maxTokens != null) 'maxOutputTokens': maxTokens,
          if (temperature != null) 'temperature': temperature,
          if (jsonObject) 'responseMimeType': 'application/json',
        },
      },
    );
    return _geminiText(json);
  }

  Future<String?> geminiTextFromImage(
    String prompt, {
    Uint8List? imageBytes,
    String? imageBase64,
    String mimeType = 'image/jpeg',
    String? model,
    int? maxTokens,
    bool jsonObject = false,
  }) async {
    final b64 =
        imageBase64 ?? (imageBytes != null ? base64Encode(imageBytes) : null);
    if (b64 == null) {
      throw ArgumentError(
          'geminiTextFromImage requires imageBytes or imageBase64');
    }
    final json = await _invoke(
      'gemini/v1beta/models/${model ?? _geminiVisionModel}:generateContent',
      {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {'mime_type': mimeType, 'data': b64}
              }
            ]
          }
        ],
        'generationConfig': {
          if (maxTokens != null) 'maxOutputTokens': maxTokens,
          if (jsonObject) 'responseMimeType': 'application/json',
        },
      },
    );
    return _geminiText(json);
  }

  // --------------------------------------------------------------- OpenAI

  /// messages: [{'role': 'user', 'content': '...'}, ...]
  Future<String?> openAiChat(
    List<Map<String, dynamic>> messages, {
    String? model,
    int? maxTokens,
    double? temperature,
    String? reasoningEffort,
    bool jsonObject = false,
  }) async {
    final selectedModel = model ?? _openAiChatModel;
    final usesReasoningParameters = selectedModel.startsWith('gpt-5') ||
        selectedModel.startsWith('o1') ||
        selectedModel.startsWith('o3') ||
        selectedModel.startsWith('o4');
    final json = await _invoke(
      'openai/v1/chat/completions',
      {
        'model': selectedModel,
        'messages': messages,
        if (maxTokens != null && usesReasoningParameters)
          'max_completion_tokens': maxTokens,
        if (maxTokens != null && !usesReasoningParameters)
          'max_tokens': maxTokens,
        // Reasoning models do not accept every sampling parameter supported by
        // GPT-4o models, so keep temperature off those requests.
        if (temperature != null && !usesReasoningParameters)
          'temperature': temperature,
        if (reasoningEffort != null) 'reasoning_effort': reasoningEffort,
        if (jsonObject) 'response_format': const {'type': 'json_object'},
      },
    );
    final choices = json['choices'];
    if (choices is List && choices.isNotEmpty) {
      return choices.first['message']?['content'] as String?;
    }
    return null;
  }

  /// Sends a public image URL to an OpenAI vision-capable chat model. Keeping
  /// this in [AiService] means the mobile client still talks only to the
  /// authenticated `ai-proxy` Edge Function and never receives provider keys.
  Future<String?> openAiTextFromImage(
    String prompt, {
    required String imageUrl,
    String? model,
    String detail = 'auto',
    int maxTokens = 1200,
    String? reasoningEffort,
    bool jsonObject = true,
  }) {
    return openAiChat(
      [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {
              'type': 'image_url',
              'image_url': {'url': imageUrl, 'detail': detail},
            },
          ],
        }
      ],
      model: model ?? _openAiChatModel,
      maxTokens: maxTokens,
      temperature: reasoningEffort == null ? 0.1 : null,
      reasoningEffort: reasoningEffort,
      jsonObject: jsonObject,
    );
  }

  // --------------------------------------------------------------- helpers

  String? _geminiText(Map<String, dynamic> json) {
    final candidates = json['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final parts = candidates.first['content']?['parts'];
      if (parts is List && parts.isNotEmpty) {
        return parts.first['text'] as String?;
      }
    }
    return null;
  }
}
