import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '/backend/supabase/supabase.dart';

/// A presigned Bunny Stream TUS upload ticket returned by `create-upload`.
/// The caller uploads bytes directly to Bunny with these; our backend never
/// sees the file. Use a TUS client (e.g. `tus_client`) to push [tusEndpoint]
/// with the four Bunny headers.
class UploadTicket {
  UploadTicket(this.raw);
  final Map<String, dynamic> raw;

  String get assetId => raw['assetId'] as String;
  String get videoId => raw['videoId'] as String;
  String get libraryId => raw['libraryId'].toString();
  String get tusEndpoint => raw['tusEndpoint'] as String;
  String get authorizationSignature => raw['authorizationSignature'] as String;
  int get authorizationExpire => (raw['authorizationExpire'] as num).toInt();
  String get playlistUrl => raw['playlistUrl'] as String;
  String get thumbnailUrl => raw['thumbnailUrl'] as String;

  /// Headers a TUS client must send when creating the upload.
  Map<String, String> get tusHeaders => {
        'AuthorizationSignature': authorizationSignature,
        'AuthorizationExpire': authorizationExpire.toString(),
        'LibraryId': libraryId,
        'VideoId': videoId,
      };
}

/// Media upload + status tracking. Videos → Bunny Stream (control-plane via
/// `create-upload`); images → Supabase Storage; status → `media_assets` Realtime.
class MediaRepository {
  SupabaseClient get _db => supabase;
  String? get _uid => _db.auth.currentUser?.id;
  static const _uuid = Uuid();

  /// Ask the backend for a video upload ticket. Throws on quota (429) or auth.
  Future<UploadTicket> requestVideoUpload({String? title}) async {
    final res = await _db.functions.invoke(
      'create-upload',
      body: {if (title != null) 'title': title},
    );
    if (res.status >= 400) {
      throw Exception('create-upload failed (${res.status}): ${res.data}');
    }
    return UploadTicket(res.data as Map<String, dynamic>);
  }

  /// Live status of an asset (pending → uploading → processing → ready/failed).
  /// The reels/feed subscribe to this to swap placeholder → player when ready.
  Stream<Map<String, dynamic>?> watchAsset(String assetId) {
    return _db
        .from('media_assets')
        .stream(primaryKey: ['id'])
        .eq('id', assetId)
        .map((rows) => rows.isEmpty ? null : rows.first);
  }

  Future<Map<String, dynamic>?> getAsset(String assetId) {
    return _db.from('media_assets').select().eq('id', assetId).maybeSingle();
  }

  /// Upload an already-compressed image to the `images` bucket under the caller's
  /// own folder (storage RLS enforces the `<uid>/…` prefix). Returns a public URL.
  Future<String> uploadImage(
    Uint8List bytes, {
    String bucket = 'images',
    String extension = 'jpg',
    String contentType = 'image/jpeg',
  }) async {
    final uid = _requireUid();
    final path = '$uid/${_uuid.v4()}.$extension';
    await _db.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    return _db.storage.from(bucket).getPublicUrl(path);
  }

  String _requireUid() {
    final uid = _uid;
    if (uid == null)
      throw StateError('No authenticated user for a media upload.');
    return uid;
  }
}
