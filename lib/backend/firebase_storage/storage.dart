import 'package:flutter/foundation.dart';
import 'package:mime_type/mime_type.dart';
import 'package:uuid/uuid.dart';

import '/backend/supabase/supabase.dart';

const _uuid = Uuid();

/// Uploads bytes to **Supabase Storage** and returns a public URL.
///
/// This replaces the former Firebase Storage implementation. The app now
/// authenticates with Supabase, so Firebase Storage rejected every write
/// (there is no signed-in Firebase user) — which is why photo uploads broke.
///
/// Storage RLS on the `images` bucket requires the object key to begin with the
/// caller's uid, so the FlutterFlow-generated [path]
/// (e.g. `users/<uid>/uploads/<ts>.jpg`) is used only to derive the file
/// extension; the real object key becomes `<uid>/<uuid>.<ext>`.
Future<String?> uploadData(String path, Uint8List data) async {
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) {
    debugPrint('uploadData: no authenticated Supabase user — cannot upload.');
    return null;
  }

  final ext = _extensionOf(path);
  final contentType = mime(path) ?? _contentTypeForExt(ext);
  final key = '$uid/${_uuid.v4()}.$ext';

  try {
    await supabase.storage.from('images').uploadBinary(
          key,
          data,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return supabase.storage.from('images').getPublicUrl(key);
  } catch (e) {
    // Surface the real reason (missing bucket, RLS denial, size limit, …) so
    // failures are diagnosable instead of a silent "Upload failed".
    debugPrint(
        'uploadData: Supabase Storage upload to "images/$key" failed: $e');
    return null;
  }
}

String _extensionOf(String path) {
  final dot = path.lastIndexOf('.');
  final ext = dot == -1 ? '' : path.substring(dot + 1).toLowerCase();
  return ext.isEmpty ? 'jpg' : ext;
}

String _contentTypeForExt(String ext) {
  switch (ext) {
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'heic':
      return 'image/heic';
    case 'mp4':
      return 'video/mp4';
    case 'jpg':
    case 'jpeg':
    default:
      return 'image/jpeg';
  }
}
