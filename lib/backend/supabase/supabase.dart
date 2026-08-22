import 'package:supabase_flutter/supabase_flutter.dart';

export 'package:supabase_flutter/supabase_flutter.dart'
    show
        Supabase,
        SupabaseClient,
        User,
        Session,
        AuthChangeEvent,
        AuthException,
        UserAttributes,
        OtpType,
        FileOptions,
        CountOption,
        PostgrestException;

/// Central Supabase configuration + client access for GymFeed.
///
/// The URL and publishable key are public by design — Row Level Security is what
/// protects data, not key secrecy. The service-role key is NEVER shipped in the
/// app; privileged work happens in Edge Functions.
class SupaFlow {
  SupaFlow._();

  static const String supabaseUrl = 'https://bzinwojowkxavfzilvat.supabase.co';
  static const String supabaseKey =
      'sb_publishable_iyY6WXUGOBK2pkePZFZurw_ZIStK1ge';

  // Bunny Stream video delivery host (public). Used to build HLS/thumbnail URLs
  // from a stored bunny_video_guid.
  static const String bunnyStreamCdnHost = 'vz-55fc89c2-aab.b-cdn.net';

  static SupaFlow? _instance;
  static SupaFlow get instance => _instance ??= SupaFlow._();

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() => Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
        // Persist the session across launches; refresh happens automatically.
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
}

/// Shorthand for the active client — `supabase.from('posts')...`.
SupabaseClient get supabase => SupaFlow.instance.client;

/// Builds the HLS playlist URL for a Bunny Stream video from its guid.
String bunnyPlaylistUrl(String guid) =>
    'https://${SupaFlow.bunnyStreamCdnHost}/$guid/playlist.m3u8';

/// Builds the thumbnail URL for a Bunny Stream video from its guid.
String bunnyThumbnailUrl(String guid) =>
    'https://${SupaFlow.bunnyStreamCdnHost}/$guid/thumbnail.jpg';
