// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '/backend/supabase/repositories/media_repository.dart';
import '/backend/supabase/supabase.dart';

/// Uploads a (compressed) video's [bytes] straight to Bunny Stream using the
/// TUS resumable protocol, gated through the [MediaRepository] ticket system.
///
/// Returns the [UploadTicket] so the caller has the `assetId` (media_assets
/// row), the HLS `playlistUrl`, and the `thumbnailUrl`. Encoding continues
/// server-side; the media-webhook flips the asset to `ready` when done.
///
/// [onProgress] receives a value in [0.0 … 1.0] during the transfer.
Future<UploadTicket> uploadVideoToBunny(
  Uint8List bytes,
  String title, {
  String fileName = 'gymfeed-video.mp4',
  Future<void> Function(double progress)? onProgress,
}) async {
  // ── 1. Presigned upload ticket from the backend ─────────────────────────
  final ticket = await MediaRepository().requestVideoUpload(title: title);

  // ── 2. Mark the asset as uploading ──────────────────────────────────────
  await supabase
      .from('media_assets')
      .update({'status': 'uploading'}).eq('id', ticket.assetId);

  final fileSize = bytes.length;
  final tusEndpoint = Uri.parse(ticket.tusEndpoint);

  // TUS metadata values are base64-encoded per spec.
  String b64(String s) => base64.encode(utf8.encode(s));
  final extension = fileName.split('.').last.toLowerCase();
  final contentType = switch (extension) {
    'mov' => 'video/quicktime',
    'webm' => 'video/webm',
    'm4v' => 'video/x-m4v',
    _ => 'video/mp4',
  };
  final uploadMetadata =
      'filename ${b64(fileName)},filetype ${b64(contentType)},title ${b64(title.isEmpty ? 'gymfeed-video' : title)}';

  // ── 3. TUS creation request ─────────────────────────────────────────────
  final createResponse = await http.post(
    tusEndpoint,
    headers: {
      'Tus-Resumable': '1.0.0',
      'Upload-Length': fileSize.toString(),
      'Upload-Metadata': uploadMetadata,
      'Content-Length': '0',
      ...ticket
          .tusHeaders, // AuthorizationSignature, Expire, LibraryId, VideoId
    },
  );
  if (createResponse.statusCode != 201) {
    throw Exception(
      'TUS create failed (${createResponse.statusCode}): ${createResponse.body}',
    );
  }
  final locationHeader = createResponse.headers['location'];
  if (locationHeader == null || locationHeader.isEmpty) {
    throw Exception('TUS create response missing Location header.');
  }
  // Bunny returns the upload URL in the Location header, which is often a
  // root-relative path ("/tusupload/<id>"). Resolving it against the TUS
  // endpoint gives it a scheme+host; otherwise http throws
  // "No host specified in URI /tusupload/...". Resolve is a no-op when the
  // header is already an absolute URL.
  final uploadUri = tusEndpoint.resolve(locationHeader);

  // ── 4. Upload the bytes in 5 MB chunks ──────────────────────────────────
  const chunkSize = 5 * 1024 * 1024;
  var offset = 0;
  while (offset < fileSize) {
    final end = (offset + chunkSize < fileSize) ? offset + chunkSize : fileSize;
    final chunk = bytes.sublist(offset, end);

    final patchResponse = await http.patch(
      uploadUri,
      headers: {
        'Tus-Resumable': '1.0.0',
        'Content-Type': 'application/offset+octet-stream',
        'Content-Length': chunk.length.toString(),
        'Upload-Offset': offset.toString(),
        ...ticket.tusHeaders,
      },
      body: chunk,
    );
    if (patchResponse.statusCode != 204) {
      throw Exception(
        'TUS PATCH failed at offset $offset '
        '(${patchResponse.statusCode}): ${patchResponse.body}',
      );
    }

    offset = end;
    if (onProgress != null) {
      await onProgress(fileSize > 0 ? offset / fileSize : 1.0);
    }
  }

  return ticket;
}
