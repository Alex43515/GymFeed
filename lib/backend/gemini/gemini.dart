// Gemini calls are now routed through the ai-proxy Edge Function.
// The old hardcoded API key has been removed; the key lives in Supabase secrets.

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/supabase/ai_service.dart';

/// Load an image from a URL as bytes (unchanged helper).
Future<Uint8List> loadImageBytesFromUrl(String imageUrl) async {
  final response = await http.get(Uri.parse(imageUrl));
  if (response.statusCode == 200) return response.bodyBytes;
  throw Exception('Failed to load image from $imageUrl');
}

/// Generate text using Gemini via the ai-proxy Edge Function.
Future<String?> geminiGenerateText(
  BuildContext context,
  String prompt,
) async {
  try {
    return await AiService().geminiGenerateText(prompt);
  } catch (e) {
    showSnackbar(context, e.toString());
    return null;
  }
}

/// Alias kept for callers that use the token-count variant — returns null;
/// token counting is not exposed via the proxy for now.
Future<String?> geminiCountTokens(
  BuildContext context,
  String prompt,
) async {
  return null;
}

/// Vision: generate text from an image using Gemini via the ai-proxy.
Future<String?> geminiTextFromImage(
  BuildContext context,
  String prompt, {
  String? imageNetworkUrl = '',
  FFUploadedFile? uploadImageBytes,
}) async {
  assert(
    imageNetworkUrl != null || uploadImageBytes != null,
    'Either imageNetworkUrl or uploadImageBytes must be provided.',
  );

  try {
    if (uploadImageBytes?.bytes != null) {
      return await AiService().geminiTextFromImage(
        prompt,
        imageBytes: uploadImageBytes!.bytes,
      );
    }
    if (imageNetworkUrl != null && imageNetworkUrl.isNotEmpty) {
      final bytes = await loadImageBytesFromUrl(imageNetworkUrl);
      return await AiService().geminiTextFromImage(prompt, imageBytes: bytes);
    }
    return null;
  } catch (e) {
    showSnackbar(context, e.toString());
    return null;
  }
}
